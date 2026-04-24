import {
	type CompletionItem,
	CompletionItemKind,
	type CompletionParams,
	type Connection,
	DidChangeConfigurationNotification,
	type DidChangeConfigurationParams,
	type DocumentDiagnosticParams,
	type DocumentDiagnosticReport,
	DocumentDiagnosticReportKind,
	type DocumentSymbol,
	type DocumentSymbolParams,
	type Hover,
	type InitializeParams,
	type InitializeResult,
	InsertTextFormat,
	type PublishDiagnosticsParams,
	type SemanticTokens,
	SemanticTokensBuilder,
	type SemanticTokensParams,
	type ServerCapabilities,
	type SymbolInformation,
	SymbolKind,
	type TextDocumentPositionParams,
	TextDocumentSyncKind,
	TextDocuments,
} from 'vscode-languageserver'
import { type DocumentUri, TextDocument } from 'vscode-languageserver-textdocument'
import { LspDocument } from './model'
import { type CompletionInspectResponseItem, normalizeError, type RouterOSClientError, RouterRestClient } from './routeros'
import {
	ConnectionLogger,
	clearConnectionUrl,
	defaultSettings,
	getDisplayConnectionUrl,
	getEnvironmentSettings,
	isUsingClientCredentials,
	type LspSettingsUpdate,
	log,
	ROUTEROS_API_MAX_BYTES,
	type RouterConnectionSettings,
	SEMANTIC_TOKEN_REFRESH_DELAY_MS,
	sanitizeBaseUrl,
	updateSettings,
	useConnectionUrl,
} from './shared'
import { HighlightTokens } from './tokens'
import { type RouterScriptValidationResult, validateScriptText } from './validation'

// MARK: LspController

export class LspController {
	#connection: Connection
	#documents: TextDocuments<TextDocument>
	#lspDocuments = new Map<string, LspDocument>()
	#ready: Promise<void>
	#hasConfigurationCapability = false
	#pendingSemanticRefreshTimers = new Set<ReturnType<typeof setTimeout>>()
	#isDisposed = false

	get isReady(): Promise<void> {
		return this.#ready
	}

	get connection(): Connection {
		return this.#connection
	}

	static shortid = 'routeroslsp'

	static #default: LspController

	static get default() {
		return LspController.#default
	}

	static start(connection: Connection, nodeHttpsAgent?: object) {
		ConnectionLogger.console = connection.console
		if (nodeHttpsAgent) RouterRestClient.nodeHttpsAllowAllAgent = nodeHttpsAgent
		log.debug('<server> start()')
		LspController.#default = new LspController(connection)
		return LspController.#default
	}

	dispose() {
		if (this.#isDisposed) return
		this.#isDisposed = true

		for (const timer of this.#pendingSemanticRefreshTimers) {
			clearTimeout(timer)
		}
		this.#pendingSemanticRefreshTimers.clear()

		this.#lspDocuments.clear()
		RouterRestClient.onHttpError = null
		RouterRestClient.default.dispose()
		log.info('<server> {dispose} completed')
	}

	#scheduleSemanticTokensRefresh() {
		if (this.#isDisposed) return

		const timer = setTimeout(() => {
			this.#pendingSemanticRefreshTimers.delete(timer)
			if (this.#isDisposed) return

			try {
				this.#connection.languages.semanticTokens.refresh()
			} catch (error: unknown) {
				const normalized = normalizeError(error)
				log.warn(`WARN <server> {semanticTokens.refresh} failed: ${normalized.code} ${normalized.message}`)
			}
		}, SEMANTIC_TOKEN_REFRESH_DELAY_MS)

		this.#pendingSemanticRefreshTimers.add(timer)
	}

	private constructor(connection: Connection) {
		this.#connection = connection
		this.#documents = new TextDocuments(TextDocument)

		const readyResolver = Promise.withResolvers<void>()
		this.#ready = readyResolver.promise

		// Wire up HTTP error callback — clears document cache so stale tokens are re-fetched
		RouterRestClient.onHttpError = () => this.#lspDocuments.clear()

		connection.onInitialize((params): InitializeResult => {
			let serverCapabilities = LspController.getServerCapabilities(params)
			if (LspController.hasCapability('workspaceFolders', params)) {
				serverCapabilities = {
					...serverCapabilities,
					workspace: { workspaceFolders: { supported: true } },
				}
				log.debug(`<server> {onInitialize} workspaceFolders true`)
			}
			this.#hasConfigurationCapability = !!(params.capabilities.workspace && !!params.capabilities.workspace.configuration)
			log.debug(`<server> {onInitialize} hasConfigurationCapability ${this.#hasConfigurationCapability}`)

			const envSettings = getEnvironmentSettings()
			if (Object.keys(envSettings).length > 0) {
				updateSettings(envSettings)
				RouterRestClient.default.invalidateClient()
				log.info(`<server> {onInitialize} applied settings from environment`)
			}

			// Apply settings from initializationOptions for non-VSCode clients (Copilot CLI, NeoVim, etc.)
			// that pass credentials via `initializationOptions.routeroslsp.*` in their LSP config.
			const initOpts = params.initializationOptions?.[LspController.shortid]
			if (initOpts) {
				updateSettings(initOpts as LspSettingsUpdate)
				RouterRestClient.default.invalidateClient()
				log.info(`<server> {onInitialize} applied settings from initializationOptions`)
			}

			return { capabilities: serverCapabilities }
		})

		connection.onInitialized(() => {
			if (this.#hasConfigurationCapability) {
				connection.client.register(DidChangeConfigurationNotification.type, { section: 'routeroslsp' })
				log.debug(`<server> {onInitialized} refresh configuration`)
				connection.workspace.getConfiguration(LspController.shortid).then((e) => {
					updateSettings(e)
					readyResolver.resolve()
				})
			} else {
				readyResolver.resolve()
			}
		})

		connection.onDidChangeConfiguration((e: DidChangeConfigurationParams) => {
			const cfg = e.settings?.routeroslsp
			log.info(
				`<server> {onDidChangeConfiguration} ${cfg?.baseUrl ? sanitizeBaseUrl(cfg.baseUrl) : '<unset>'} apiTimeout ${cfg?.apiTimeout ?? '<unset>'} allowClientProvidedCredentials ${cfg?.allowClientProvidedCredentials ?? '<unset>'} checkCertificates ${cfg?.checkCertificates ?? '<unset>'}`,
			)
			if (cfg) {
				updateSettings(cfg)
				RouterRestClient.default.invalidateClient()
				this.#documents.keys().forEach((k) => {
					this.#lspDocuments.get(k)?.refresh()
				})
				this.#scheduleSemanticTokensRefresh()
			} else log.warn('<server> {onDidChangeConfiguration} got no settings, skipping update')
		})

		// Force token refresh after ready — gives RouterOS time to settle
		this.isReady.then(() => this.#scheduleSemanticTokensRefresh())

		// MARK: Document lifecycle

		this.#documents.onDidOpen((e) => {
			log.debug(`<server> {onDidOpen} ${e.document.uri}`)
		})
		this.#documents.onDidChangeContent((e) => {
			log.info(`<server> {onDidChangeContent} ${e.document.uri}`)
			this.getLspDocument(e.document.uri, true)
		})
		this.#documents.onDidClose((e) => {
			log.info(`<server> {onDidClose} ${e.document.uri}`)
			this.#lspDocuments.delete(e.document.uri)
		})
		this.#documents.onDidSave((e) => {
			log.info(`<server> {onDidSave} ${e.document.uri}`)
			this.getLspDocument(e.document.uri, true)
		})

		// MARK: LSP feature handlers

		connection.onHover(async (params) => this.#onHover(params))
		connection.languages.diagnostics.on(async (params) => this.#handleDiagnostics(params))
		connection.onCompletion(async (params) => this.#onCompletion(params))
		connection.onCompletionResolve((item) => item)
		connection.onRequest('textDocument/semanticTokens/full', async (params) => this.#generateSemanticTokens(params))
		connection.onDocumentSymbol(async (params) => this.#onDocumentSymbols(params))
		connection.onShutdown(() => this.dispose())
		connection.onExit(() => this.dispose())

		// MARK: Execute commands

		connection.onExecuteCommand(async (e) => {
			log.info(`<server> {onExecuteCommand} [${e.command}] ${summarizeExecuteCommand(e)}`)
			await this.isReady
			switch (e.command) {
				case 'routeroslsp.server.sendSemanticTokensRefresh':
					return connection.languages.semanticTokens.refresh()
				case 'routeroslsp.server.router.getIdentity': {
					try {
						return await RouterRestClient.default.getIdentity()
					} catch (error) {
						// Re-normalize at the boundary — interceptors produce RouterOSClientError,
						// but anything else in the call chain could throw a raw Error.
						const normalized: RouterOSClientError = normalizeError(error)
						log.error(`ERROR <server> {onExecuteCommand} getIdentity failed: ${normalized.code} ${normalized.message}`)
						return normalized
					}
				}
				case 'routeroslsp.server.useConnectionUrl': {
					const changed = useConnectionUrl(e)
					if (changed) RouterRestClient.default.invalidateClient()
					return changed
				}
				case 'routeroslsp.server.clearConnectionUrl': {
					const changed = clearConnectionUrl()
					if (changed) RouterRestClient.default.invalidateClient()
					return changed
				}
				case 'routeroslsp.server.isUsingClientCredentials':
					return isUsingClientCredentials()
				case 'routeroslsp.server.getConnectionUrl':
					return getDisplayConnectionUrl()
				case 'routeroslsp.server.router.validateScript':
					return await this.#validateScriptCommand(e)
				case 'routeroslsp.server.router.executeScript':
					return await this.#executeScriptCommand(e)
			}
		})

		this.#documents.listen(connection)
		log.debug('<server> {constructor} done')
	}

	// MARK: Document cache

	async getLspDocument(uri: DocumentUri, refresh = false): Promise<LspDocument | null> {
		await this.isReady

		if (!refresh) {
			const cached = this.#lspDocuments.get(uri)
			if (cached) {
				log.debug(`<server> {getLspDocument} cache hit: ${uri}`)
				return cached
			}
		} else {
			log.debug(`<server> {getLspDocument} refresh requested, remove cache: ${uri}`)
			this.#lspDocuments.delete(uri)
		}

		const document = this.#documents.get(uri)
		if (!document) {
			log.warn(`ERROR <server> {getLspDocument} failed to get LspDocument, returning null: ${uri}`)
			return null
		}

		log.debug(`<server> {getLspDocument} creating cache: ${uri}`)
		const lspdocument = new LspDocument(document)
		this.#lspDocuments.set(uri, lspdocument)
		return lspdocument
	}

	// MARK: Capabilities

	static hasCapability(capacity: string, params: InitializeParams): boolean {
		const caps = params.capabilities
		switch (capacity) {
			case 'configuration':
				return !!caps.workspace?.configuration
			case 'workspaceFolders':
				return !!caps.workspace?.workspaceFolders
			case 'diagnosticsRelatedInformation':
				return !!caps.textDocument?.publishDiagnostics?.relatedInformation
			case 'showMessage':
				return !!caps.window?.showMessage
			default:
				return false
		}
	}

	static getServerCapabilities(params: InitializeParams): ServerCapabilities {
		return {
			executeCommandProvider: {
				commands: [
					'routeroslsp.server.sendSemanticTokensRefresh',
					'routeroslsp.server.router.getIdentity',
					'routeroslsp.server.router.validateScript',
					'routeroslsp.server.router.executeScript',
					'routeroslsp.server.useConnectionUrl',
					'routeroslsp.server.getConnectionUrl',
					'routeroslsp.server.isUsingClientCredentials',
					'routeroslsp.server.clearConnectionUrl',
				],
			},
			textDocumentSync: TextDocumentSyncKind.Full,
			semanticTokensProvider: {
				legend: {
					tokenTypes: HighlightTokens.TokenTypes,
					tokenModifiers: HighlightTokens.TokenModifiers,
				},
				full: { delta: false },
				range: false,
				workDoneProgress: false,
				documentSelector: [
					{ scheme: 'vscode-notebook-cell', language: 'routeros' },
					{ language: 'routeros' },
					{ language: 'rsc' },
					{ scheme: 'file', pattern: '**∕*.rsc' },
					{ scheme: 'file', pattern: '**∕*.tikbook' },
					{ scheme: 'file', pattern: '**∕*.md.rsc' },
					{ scheme: 'rscena', pattern: '**/*.rsc' },
					{ scheme: 'rscena', pattern: '**/*.md.rsc' },
					{ scheme: 'rscena', pattern: '**/*.tikbook' },
					{ language: 'routeroslsp' },
					{ scheme: 'vscode', language: 'routeros' },
				],
			},
			completionProvider: {
				resolveProvider: true,
				triggerCharacters: [':', '=', '/', ' ', '$', '['],
			},
			diagnosticProvider: {
				interFileDependencies: false,
				workspaceDiagnostics: false,
			},
			hoverProvider: true,
			workspace: {
				workspaceFolders: {
					supported: LspController.hasCapability('workspaceFolders', params),
				},
			},
			documentSymbolProvider: true,
		}
	}

	sendDiagnostics = (diagnostics: PublishDiagnosticsParams) => {
		log.info(`<server> {sendDiagnostics} ${diagnostics.uri} len ${diagnostics.diagnostics.length}`)
		this.connection.sendDiagnostics(diagnostics)
	}

	// MARK: Hover

	async #onHover(params: TextDocumentPositionParams): Promise<Hover | undefined | null> {
		const lspdoc = await this.getLspDocument(params.textDocument.uri)
		if (!lspdoc) {
			log.error(`ERROR <server> {onHoverHandler} failed to get document: ${params.textDocument.uri}`)
			return undefined
		}
		const highlightTokens = await lspdoc.highlightTokens
		const highlightToken = highlightTokens.atPosition(params.position)
		if (!highlightToken) return undefined

		const regexToken = highlightTokens.regexToken[lspdoc.offsetAt(params.position)]
		const hoverInfo = `\`${highlightToken.token}\` ${regexToken === ' ' ? `' ` : '**'}${regexToken}${regexToken === ' ' ? `'` : '**'} highlight  <small>from ${lspdoc.offsetAt(highlightToken.range.start)} to ${lspdoc.offsetAt(highlightToken.range.end)}</small>`
		return {
			contents: { kind: 'markdown', value: hoverInfo },
			range: highlightToken.range,
		}
	}

	// MARK: Diagnostics

	async #handleDiagnostics(params: DocumentDiagnosticParams): Promise<DocumentDiagnosticReport> {
		log.debug(`<server> {handleDiagnostics} for ${params.textDocument.uri}`)
		const emptyReport: DocumentDiagnosticReport = { kind: DocumentDiagnosticReportKind.Full, items: [] }

		const document = await this.getLspDocument(params.textDocument.uri)
		if (!document) {
			log.error(`ERROR <server> {handleDiagnostics} failed to get doc, returning no diags`)
			return emptyReport
		}
		const diags = await document.diagnostics()
		if (!diags) {
			log.error(`ERROR <server> {handleDiagnostics} failed to get diagnostics() from doc, returning no diags`)
			return emptyReport
		}
		return { kind: DocumentDiagnosticReportKind.Full, items: diags }
	}

	// MARK: Completion

	async #onCompletion(params: CompletionParams): Promise<CompletionItem[]> {
		const startTime = Date.now()
		log.debug(
			`<server> {onCompletionHandler} for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`,
		)

		const document = await this.getLspDocument(params.textDocument.uri)
		if (!document) {
			log.error(
				`ERROR <server> {onCompletionHandler} failed for '${params.textDocument.uri}' failed to get '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character})`,
			)
			return []
		}

		const completions = await document.completion(params.position)
		if (!completions) return []

		const results: CompletionItem[] = []
		for (const item of completions) {
			if (item.show !== 'true' || !item.completion) continue

			const kind = completionStyleToKind(item.style)
			results.push({
				label: item.completion,
				kind: kind,
				data: results.length,
				insertText: item.completion,
				insertTextFormat: InsertTextFormat.PlainText,
				detail: `${item.text}`,
			})
		}

		log.debug(`<server> {onCompletionHandler} done in ${Date.now() - startTime}ms`)
		return results
	}

	// MARK: Semantic tokens

	async #generateSemanticTokens(params: SemanticTokensParams): Promise<SemanticTokens | null> {
		const startTime = Date.now()
		const builder = new SemanticTokensBuilder()
		log.debug('<server> {generateSemanticToken} starting')

		const document = await this.getLspDocument(params.textDocument.uri)
		if (!document) {
			log.error(`ERROR <server> {generateSemanticToken} found no document, returning no tokens`)
			return builder.build()
		}

		const htokens = await document.highlightTokens
		if (!htokens || htokens.tokens.length === 0) {
			log.error(`ERROR <server> {generateSemanticTokens} no highlightTokens found: ${document.uri}`)
		} else {
			for (const tokenRange of htokens.tokenRanges) {
				if (tokenRange.token === 'none') continue
				const pos = tokenRange.range.start
				const tokenTypeIndex = HighlightTokens.getTokenTypeIndex(tokenRange.token)
				if (tokenTypeIndex < 0) {
					log.warn(`<server> {generateSemanticTokens} unknown semantic token type '${tokenRange.token}'`)
					continue
				}
				const modifierMask = HighlightTokens.getTokenModifierMask(tokenRange.token)
				builder.push(pos.line, pos.character, document.document.offsetAt(tokenRange.range.end) - document.document.offsetAt(tokenRange.range.start) + 1, tokenTypeIndex, modifierMask)
			}
		}

		const packed = builder.build()
		log.info(`<server> {generateSemanticTokens} done in ${Date.now() - startTime}ms`)
		return packed
	}

	// MARK: Document symbols

	async #onDocumentSymbols(params: DocumentSymbolParams): Promise<SymbolInformation[] | DocumentSymbol[] | undefined | null> {
		log.debug(`<server> {onDocumentSymbols} starting: ${params.textDocument.uri}`)
		const lspdoc = await this.getLspDocument(params.textDocument.uri)
		if (!lspdoc) return undefined

		const highlightTokens = await lspdoc.highlightTokens
		const tokenRanges = highlightTokens.tokenRanges
		const symbolsVariableTree: DocumentSymbol[] = []

		for (const f of tokenRanges.filter((t) => ['variable-global', 'variable-local'].includes(t.token))) {
			const range = f.range
			const vartype = f.token.split('-')[1]
			range.end.character = range.end.character + 1
			const name = lspdoc.document.getText(range)
			const docsym: DocumentSymbol = {
				kind: vartype === 'global' ? SymbolKind.Variable : SymbolKind.Constant,
				name: name,
				range: range,
				selectionRange: range,
				detail: `:${vartype} on line ${range.start.line}`,
				children: [],
			}

			const existing = symbolsVariableTree.find((i) => i.name === name && i.kind === docsym.kind)
			if (existing) {
				existing.children ??= []
				existing.children.push(docsym)
			} else {
				symbolsVariableTree.push(docsym)
			}
		}

		log.info(`<server> {onDocumentSymbols} found ${symbolsVariableTree.length} for ${lspdoc.uri}`)
		return symbolsVariableTree
	}

	async #validateScriptCommand(e: { arguments?: unknown[] }): Promise<RouterScriptValidationResult> {
		const parsed = parseRouterScriptCommandRequest(e.arguments?.[0])
		if (!parsed.ok) {
			return {
				ok: false,
				message: parsed.message,
				diagnostics: [],
				truncated: false,
				checkedBytes: 0,
			}
		}

		const client = RouterRestClient.forConnection(parsed.connection)
		try {
			return await validateScriptText(parsed.script, client.inspectHighlightStrict)
		} finally {
			client.dispose()
		}
	}

	async #executeScriptCommand(e: { arguments?: unknown[] }): Promise<RouterScriptExecutionResult> {
		const parsed = parseRouterScriptCommandRequest(e.arguments?.[0])
		if (!parsed.ok) {
			return {
				ok: false,
				message: parsed.message,
				diagnostics: [],
				truncated: false,
				checkedBytes: 0,
				executed: false,
			}
		}

		const client = RouterRestClient.forConnection(parsed.connection)
		try {
			const validation = await validateScriptText(parsed.script, client.inspectHighlightStrict, 'routeroslsp://command/execute.rsc')
			if (!validation.ok) {
				return {
					...validation,
					executed: false,
				}
			}

			const output = await client.executeScriptStrict(parsed.script)
			return {
				...validation,
				message: 'Script executed successfully',
				output,
				executed: true,
			}
		} catch (error) {
			const normalized = normalizeError(error)
			return {
				ok: false,
				message: `Execution failed: ${normalized.message}`,
				diagnostics: [],
				truncated: parsed.script.length > ROUTEROS_API_MAX_BYTES,
				checkedBytes: Math.min(parsed.script.length, ROUTEROS_API_MAX_BYTES),
				error: normalized,
				executed: false,
			}
		} finally {
			client.dispose()
		}
	}
}

// MARK: Helpers

function completionStyleToKind(style: CompletionInspectResponseItem['style']): CompletionItemKind {
	switch (style) {
		case 'dir':
			return CompletionItemKind.Folder
		case 'cmd':
			return CompletionItemKind.Method
		case 'arg':
			return CompletionItemKind.Property
		case 'syntax-meta':
			return CompletionItemKind.Operator
		case 'variable-global':
			return CompletionItemKind.Variable
		case 'variable-local':
			return CompletionItemKind.Constant
		default:
			return CompletionItemKind.Text
	}
}

interface RouterScriptCommandRequest {
	baseUrl: string
	username: string
	password: string
	script: string
	apiTimeout?: number
	checkCertificates?: boolean
}

interface RouterScriptExecutionResult extends RouterScriptValidationResult {
	executed: boolean
	output?: string
}

export function parseRouterScriptCommandRequest(input: unknown): { ok: true; connection: RouterConnectionSettings; script: string } | { ok: false; message: string } {
	if (!input || typeof input !== 'object' || Array.isArray(input)) {
		return { ok: false, message: 'Execute command requires a single object argument with baseUrl, username, password, and script.' }
	}

	const request = input as Partial<RouterScriptCommandRequest>
	if (typeof request.script !== 'string' || request.script.trim().length === 0) {
		return { ok: false, message: 'Execute command requires a non-empty script string.' }
	}
	if (typeof request.baseUrl !== 'string' || request.baseUrl.trim().length === 0) {
		return { ok: false, message: 'Execute command requires a baseUrl.' }
	}
	if (typeof request.username !== 'string' || request.username.trim().length === 0) {
		return { ok: false, message: 'Execute command requires a username.' }
	}
	if (typeof request.password !== 'string' || request.password.length === 0) {
		return { ok: false, message: 'Execute command requires a password.' }
	}

	const url = URL.parse(request.baseUrl)
	if (!url?.protocol || !url.host) {
		return { ok: false, message: 'Execute command requires a valid baseUrl with protocol, host, and port.' }
	}
	if (url.username || url.password) {
		return { ok: false, message: 'Execute command baseUrl must not embed credentials. Pass username and password as separate fields.' }
	}
	// url.port is empty for default ports (http→80, https→443) — check the original string too
	const hasExplicitPort = url.port !== '' || /\/\/[^/]*:\d+/.test(request.baseUrl)
	if (!hasExplicitPort) {
		return { ok: false, message: 'Execute command requires an explicit RouterOS port in baseUrl.' }
	}

	const normalizedBaseUrl = sanitizeBaseUrl(request.baseUrl)
	return {
		ok: true,
		connection: {
			baseUrl: normalizedBaseUrl,
			username: request.username,
			password: request.password,
			apiTimeout: typeof request.apiTimeout === 'number' && Number.isFinite(request.apiTimeout) ? request.apiTimeout : defaultSettings.apiTimeout,
			checkCertificates: typeof request.checkCertificates === 'boolean' ? request.checkCertificates : defaultSettings.checkCertificates,
		},
		script: request.script,
	}
}

function summarizeExecuteCommand(e: { command: string; arguments?: unknown[] }): string {
	switch (e.command) {
		case 'routeroslsp.server.useConnectionUrl':
			return JSON.stringify(
				e.arguments?.map((arg, index) => {
					if (index === 1 && typeof arg === 'string') return sanitizeBaseUrl(arg)
					if (index >= 2) return '***'
					return arg
				}) || [],
			)
		case 'routeroslsp.server.router.validateScript':
		case 'routeroslsp.server.router.executeScript': {
			const arg = e.arguments?.[0]
			if (!arg || typeof arg !== 'object' || Array.isArray(arg)) return '[invalid arguments]'
			const request = arg as Partial<RouterScriptCommandRequest>
			return JSON.stringify([
				{
					baseUrl: typeof request.baseUrl === 'string' ? sanitizeBaseUrl(request.baseUrl) : '<invalid>',
					scriptLength: typeof request.script === 'string' ? request.script.length : 0,
					apiTimeout: typeof request.apiTimeout === 'number' ? request.apiTimeout : '<default>',
					checkCertificates: typeof request.checkCertificates === 'boolean' ? request.checkCertificates : '<default>',
					username: '***',
					password: '***',
				},
			])
		}
		default:
			return JSON.stringify(e.arguments || [])
	}
}
