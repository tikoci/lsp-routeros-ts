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
import { type CompletionInspectResponseItem, RouterRestClient } from './routeros'
import { ConnectionLogger, clearConnectionUrl, getDisplayConnectionUrl, isUsingClientCredentials, log, SEMANTIC_TOKEN_REFRESH_DELAY_MS, updateSettings, useConnectionUrl } from './shared'
import { HighlightTokens } from './tokens'

// MARK: LspController

export class LspController {
	#connection: Connection
	#documents: TextDocuments<TextDocument>
	#lspDocuments = new Map<string, LspDocument>()
	#ready: Promise<void>
	#hasConfigurationCapability = false

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
			log.info(
				`<server> {onDidChangeConfiguration} ${e.settings.routeroslsp.baseUrl} user ${e.settings.routeroslsp.username} apiTimeout ${e.settings.routeroslsp.apiTimeout} allowClientProvidedCredentials ${e.settings.routeroslsp.allowClientProvidedCredentials}`,
			)
			if (e.settings.routeroslsp) {
				updateSettings(e.settings.routeroslsp)
				RouterRestClient.default.invalidateClient()
				this.#documents.keys().forEach((k) => {
					this.#lspDocuments.get(k)?.refresh()
				})
				setTimeout(() => connection.languages.semanticTokens.refresh(), SEMANTIC_TOKEN_REFRESH_DELAY_MS)
			} else log.warn('<server> {onDidChangeConfiguration} got no settings, skipping update')
		})

		// Force token refresh after ready — gives RouterOS time to settle
		this.isReady.then(() => setTimeout(() => connection.languages.semanticTokens.refresh(), SEMANTIC_TOKEN_REFRESH_DELAY_MS))

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

		// MARK: Execute commands

		connection.onExecuteCommand(async (e) => {
			// Redact password from logging
			log.info(`<server> {onExecuteCommand} [${e.command}] ${JSON.stringify(e.arguments?.map((a, i) => (e.command === 'routeroslsp.server.useConnectionUrl' && i === 3 ? '***' : a)))}`)
			await this.isReady
			switch (e.command) {
				case 'routeroslsp.server.sendSemanticTokensRefresh':
					return connection.languages.semanticTokens.refresh()
				case 'routeroslsp.server.router.getIdentity': {
					try {
						return await RouterRestClient.default.getIdentity()
					} catch (error) {
						// error is a RouterOSClientError (plain object with code/message/status)
						// — safe to return across JSON-RPC to the client watchdog
						log.error(`ERROR <server> {onExecuteCommand} getIdentity failed: ${error instanceof Error ? error.message : (error as { message?: string }).message || String(error)}`)
						return error
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
					tokenModifiers: [],
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
				builder.push(
					pos.line,
					pos.character,
					document.document.offsetAt(tokenRange.range.end) - document.document.offsetAt(tokenRange.range.start) + 1,
					HighlightTokens.TokenTypes.indexOf(tokenRange.token),
					0,
				)
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
