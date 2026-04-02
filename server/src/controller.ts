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
import { ConnectionLogger, clearConnectionUrl, getDisplayConnectionUrl, isUsingClientCredentials, log, updateSettings, useConnectionUrl } from './shared'
import { HighlightTokens } from './tokens'

// MARK: LspController

export class LspController {
	#connection: Connection
	#documents: TextDocuments<TextDocument>
	#lspDocuments = new Map<string, LspDocument>()
	#ready: Promise<void>
	#hasConfigurationCapability = false
	#hasShowMessageCapability = false

	get isReady(): Promise<void> {
		return this.#ready
	}

	get connection(): Connection {
		return this.#connection
	}

	get documents() {
		return this.#documents
	}

	get lspDocuments() {
		return this.#lspDocuments
	}

	static shortid = 'routeroslsp'

	static #default: LspController

	static nodeHttpsAllowAllAgent: object | undefined

	static get default() {
		return LspController.#default
	}

	static start(connection: Connection, nodeHttpsAgent?: object) {
		ConnectionLogger.console = connection.console
		if (nodeHttpsAgent) LspController.nodeHttpsAllowAllAgent = nodeHttpsAgent
		log.debug('<server> start()')
		LspController.#default = new LspController(connection)
		return LspController.#default
	}

	private constructor(connection: Connection) {
		this.#connection = connection
		this.#documents = new TextDocuments(TextDocument)

		const readyResolver = Promise.withResolvers<void>()
		this.#ready = readyResolver.promise

		connection.onInitialize((params): InitializeResult => {
			let serverCapabilities = LspController.getServerCapabilities(params)
			if (LspController.hasCapability('workspaceFolders', params)) {
				serverCapabilities = {
					...serverCapabilities,
					...{
						workspace: { workspaceFolders: { supported: true } },
					},
				}
				log.debug(`<server> {onInitialize} workspaceFolders true`)
			}
			this.#hasShowMessageCapability = LspController.hasCapability('showMessage', params)
			log.debug(`<server> {onInitialize} hasShowMessageCapability ${this.#hasShowMessageCapability}`)
			this.#hasConfigurationCapability = !!(params.capabilities.workspace && !!params.capabilities.workspace.configuration)
			log.debug(`<server> {onInitialize} hasConfigurationCapability ${this.#hasConfigurationCapability}`)
			return { capabilities: serverCapabilities }
		})

		connection.onInitialized(() => {
			// connection.client.register(SemanticTokensRegistrationType.type, );
			if (this.#hasConfigurationCapability === true) {
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

		// handle future configuration changes
		connection.onDidChangeConfiguration((e: DidChangeConfigurationParams) => {
			log.info(
				`<server> {onDidChangeConfiguration} ${e.settings.routeroslsp.baseUrl} user ${e.settings.routeroslsp.username} apiTimeout ${e.settings.routeroslsp.apiTimeout} allowClientProvidedCredentials ${e.settings.routeroslsp.allowClientProvidedCredentials}`,
			)
			if (e.settings.routeroslsp) {
				updateSettings(e.settings.routeroslsp)
				this.#documents.keys().forEach((k) => {
					this.#lspDocuments.get(k)?.refresh()
				})
				setTimeout(() => connection.languages.semanticTokens.refresh(), 7 * 1000)
			} else log.warn('<server> {onDidChangeConfiguration} got no settings, skipping update')
		})

		// force token refresh after 10s, after ready
		this.isReady.then(() => setTimeout(() => connection.languages.semanticTokens.refresh(), 7 * 1000))

		this.#documents.onDidOpen((e) => {
			log.debug(`<server> {onDidOpen} ${e.document.uri}`)
			// onDidChangeContent handles open
		})
		// document cache handlers (open is included in onDidChangeContent)
		this.#documents.onDidChangeContent((e) => {
			log.info(`<server> {onDidChangeContent} ${e.document.uri}`)
			this.getLspDocument(e.document.uri, true)
		})
		this.#documents.onDidClose((e) => {
			log.info(`<server> {onDidClose} ${e.document.uri} `)
			this.#lspDocuments.delete(e.document.uri)
		})
		// document cache handlers (open is included in onDidChangeContent)
		this.#documents.onDidSave((e) => {
			log.info(`<server> {onDidSave} ${e.document.uri}`)
			this.getLspDocument(e.document.uri, true)
		})

		// TODO: newer LSP feature, untested, just logging
		connection.notebooks.synchronization.onDidChangeNotebookDocument(async (e) => log.debug(`<server> notebook change< ${JSON.stringify(e)}`))
		connection.notebooks.synchronization.onDidOpenNotebookDocument(async (e) => log.debug(`<server> >notebook open< ${JSON.stringify(e)}`))
		connection.notebooks.synchronization.onDidSaveNotebookDocument(async (e) => log.debug(`<server> >notebook save< ${JSON.stringify(e)}`))
		connection.notebooks.synchronization.onDidCloseNotebookDocument(async (e) => log.debug(`<server> >notebook close< ${JSON.stringify(e)}`))

		// hover
		connection.onHover(this.onHoverHandler(this))

		// "Problems" (diagnostics)
		connection.languages.diagnostics.on(this.handleDiagnostics(this))

		// completion
		connection.onCompletion(this.onCompletionHandler(this))
		connection.onCompletionResolve(this.onCompletionResolveHandler(this))

		// semantic tokens
		connection.onRequest('textDocument/semanticTokens/full', this.generateSemanticTokens(this))

		// symbols (variables)
		connection.onDocumentSymbol(this.onDocumentSymbols(this))

		// execute (commands sent from client/editor to run in LSP)
		connection.onExecuteCommand(async (e) => {
			// redact password from logging for [useConnectionUrl] command param
			log.info(`<server> {onExecuteCommand} [${e.command}] ${JSON.stringify(e.arguments?.map((a, i) => (e.command === 'routeroslsp.server.useConnectionUrl' && i === 3 ? '***' : a)))}`)
			await this.isReady
			switch (e.command) {
				case 'routeroslsp.server.sendSemanticTokensRefresh': {
					return connection.languages.semanticTokens.refresh()
				}
				case 'routeroslsp.server.router.getIdentity': {
					try {
						return await RouterRestClient.default.getIdentityRaw()
					} catch (error) {
						log.error(`ERROR <server> {onExecuteCommand} getIdentity failed: ${error instanceof Error ? error.message : String(error)}`)
						return error
					}
				}
				case 'routeroslsp.server.useConnectionUrl': {
					return useConnectionUrl(e)
				}
				case 'routeroslsp.server.clearConnectionUrl': {
					return clearConnectionUrl()
				}
				case 'routeroslsp.server.isUsingClientCredentials': {
					return isUsingClientCredentials()
				}
				case 'routeroslsp.server.getConnectionUrl': {
					return getDisplayConnectionUrl()
				}
			}
		})

		// listen to document cache
		this.#documents.listen(connection)

		log.debug('<server> {constructor} done')
	}

	async getLspDocument(uri: DocumentUri, refresh = false): Promise<LspDocument | null> {
		let lspdocument: LspDocument | null = null
		await this.isReady
		if (refresh === false) {
			lspdocument = this.#lspDocuments.get(uri) ?? null
			if (lspdocument) {
				log.debug(`<server> {getLspDocument} cache hit: ${uri}`)

				return lspdocument
			}
		} else {
			log.debug(`<server> {getLspDocument} refresh requested, remove cache: ${uri}`)
			this.#lspDocuments.delete(uri)
		}
		// if not, force loading from document cache
		const document = this.#documents.get(uri)
		if (document) {
			log.debug(`<server> {getLspDocument} creating cache: ${uri}`)
			lspdocument = await LspDocument.create(document)
			if (lspdocument) {
				this.#lspDocuments.set(uri, lspdocument)
			} else {
				log.error(`ERROR <server> {getLspDocument} got doc, but failed  LspDocument.create() for: ${uri}`)
			}
			return lspdocument
		}
		const errMsg = `ERROR <server> {getLspDocument} failed to get LspDocument, returning null: ${uri}`
		log.warn(errMsg)
		return null
	}

	static hasCapability(capacity: string, params: InitializeParams): boolean {
		const clientCapabilities = params.capabilities
		switch (capacity) {
			case 'configuration':
				return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.configuration)
			case 'workspaceFolders':
				return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.workspaceFolders)
			case 'diagnosticsRelatedInformation':
				return !!clientCapabilities.textDocument?.publishDiagnostics?.relatedInformation
			case 'showMessage':
				return !!(clientCapabilities.window && !!clientCapabilities.window.showMessage)
			default:
				return false
		}
	}

	// MARK: server caps

	static getServerCapabilities(params: InitializeParams): ServerCapabilities {
		return {
			// inlayHintProvider: true,
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
			/* // future:
        notebookDocumentSync: {
        notebookSelector: [
            { cells: [{ language: "routeros" }] }
        ],
      */
			textDocumentSync: TextDocumentSyncKind.Full,
			semanticTokensProvider: {
				legend: {
					tokenTypes: HighlightTokens.TokenTypes,
					tokenModifiers: [], // optional
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

	// MARK: hover

	onHoverHandler =
		(controller: LspController) =>
		async (params: TextDocumentPositionParams): Promise<Hover | undefined | null> => {
			const lspdoc = await controller.getLspDocument(params.textDocument.uri)
			if (lspdoc) {
				const highlightTokens = await lspdoc.highlightTokens
				const highlightToken = highlightTokens.atPosition(params.position)
				const regexoken = highlightTokens.regexToken[lspdoc.offsetAt(params.position)]
				if (highlightToken) {
					const hoverInfo = `\`${highlightToken.token}\` ${regexoken === ' ' ? `' ` : '**'}${regexoken}${regexoken === ' ' ? `'` : '**'} highlight  <small>from ${lspdoc.offsetAt(highlightToken.range.start)} to ${lspdoc.offsetAt(highlightToken.range.end)}</small>`
					return {
						contents: {
							kind: 'markdown',
							value: hoverInfo,
						},
						range: highlightToken.range,
					}
				} else {
					return undefined
				}
			} else {
				const errMsg = `ERROR <server> {onHoverHandler} failed to get document: ${params.textDocument.uri}`
				log.error(errMsg)
				return undefined
			}
		}

	// MARK: diagnostics

	handleDiagnostics = (controller: LspController) => async (params: DocumentDiagnosticParams) => {
		log.debug(`<server> {handleDiagnostics} for ${params.textDocument.uri}`)

		const document = await controller.getLspDocument(params.textDocument.uri)
		if (document) {
			const diags = await document.diagnostics()
			if (!diags) {
				log.error(`ERROR <server> {handleDiagnostics} failed to get diagnostics() from doc, returning no diags`)
				return {
					kind: DocumentDiagnosticReportKind.Full,
					items: [],
				} satisfies DocumentDiagnosticReport
			}
			return {
				kind: DocumentDiagnosticReportKind.Full,
				items: diags,
			} satisfies DocumentDiagnosticReport
		} else {
			log.error(`ERROR <server> {handleDiagnostics} failed to get doc, returning no diags`)
			return {
				kind: DocumentDiagnosticReportKind.Full,
				items: [],
			} satisfies DocumentDiagnosticReport
		}
	}

	// MARK: completion

	onCompletionResolveHandler =
		(_: LspController) =>
		(item: CompletionItem): CompletionItem => {
			return item
		}

	onCompletionHandler = (controller: LspController) => async (params: CompletionParams) => {
		const startTime = Date.now()
		log.debug(
			`<server> {onCompletionHandler} for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`,
		)

		const document = await controller.getLspDocument(params.textDocument.uri)
		if (!document) {
			log.error(
				`ERROR <server> {onCompletionHandler} failed for '${params.textDocument.uri}' failed to get '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character})`,
			)
			return []
		}
		const results: CompletionItem[] = []
		const completions = await document.completion(params.position)
		if (completions) {
			completions.forEach((item: CompletionInspectResponseItem, index: number) => {
				let kind: CompletionItemKind
				switch (item.style) {
					case 'dir':
						kind = CompletionItemKind.Folder
						break
					case 'cmd':
						kind = CompletionItemKind.Method
						break
					case 'arg':
						kind = CompletionItemKind.Property
						break
					case 'syntax-meta':
						kind = CompletionItemKind.Operator
						break
					case 'variable-global':
						kind = CompletionItemKind.Variable
						break
					case 'variable-local':
						kind = CompletionItemKind.Constant
						break
					default:
						kind = CompletionItemKind.Text
				}
				if (item.show === 'true' && item.completion) {
					results.push({
						label: item.completion,
						// TODO: should map 'kind' to proper tokenType - harder than it might seem since it's prospective
						kind: kind,
						data: index,
						insertText: item.completion,
						insertTextFormat: InsertTextFormat.PlainText,
						detail: `${item.text}`,
						// documentation: `pref ${item.preference} offset ${item.offset} style ${item.style}`
					})
				}
			})
			log.debug(`<server> {onCompletionHandler} done in ${Date.now() - startTime}ms`)
			return results
		} else {
			return results
		}
	}

	// MARK: tokens

	generateSemanticTokens =
		(controller: LspController) =>
		async (params: SemanticTokensParams): Promise<SemanticTokens | null> => {
			const startTime = Date.now()
			const builder = new SemanticTokensBuilder()
			log.debug('<server> {generateSemanticToken} starting')
			// ErrorCodes.ServerCancelled
			const document = await controller.getLspDocument(params.textDocument.uri)
			if (!document) {
				const noDocErrorMsg = `ERROR <server> {generateSemanticToken} found no document, returning no tokens`
				log.error(noDocErrorMsg)
				return builder.build()
			}
			const htokens = await document.highlightTokens
			if (!htokens || htokens.tokens.length === 0) {
				log.error(`ERROR <server> {generateSemanticTokens} no highlightTokens found: ${document.uri}`)
			} else {
				const tokenRanges = htokens.tokenRanges
				log.debug(`<server> {generateSemanticTokens} found #tokens ${htokens.tokens.length} #ranges ${tokenRanges.length}`)
				tokenRanges.forEach((tokenRange) => {
					if (tokenRange.token !== 'none') {
						const pos = tokenRange.range.start
						builder.push(
							pos.line,
							pos.character,
							document.document.offsetAt(tokenRange.range.end) - document.document.offsetAt(tokenRange.range.start) + 1,
							HighlightTokens.TokenTypes.indexOf(tokenRange.token),
							0,
						)
					}
				})
			}
			const packed = builder.build()
			log.info(`<server> {generateSemanticTokens} done in ${Date.now() - startTime}ms`)
			return packed
		}

	// MARK: symbols

	onDocumentSymbols =
		(controller: LspController) =>
		async (params: DocumentSymbolParams): Promise<SymbolInformation[] | DocumentSymbol[] | undefined | null> => {
			log.debug(`<server> {onDocumentSymbols} starting: ${params.textDocument.uri}`)
			const lspdoc = await controller.getLspDocument(params.textDocument.uri)
			if (lspdoc) {
				const highlightTokens = await lspdoc.highlightTokens
				const tokenRanges = highlightTokens.tokenRanges
				// const symbols : DocumentSymbol[] = [];
				const symbolsVariableTree: DocumentSymbol[] = []
				tokenRanges
					.filter((t) => ['variable-global', 'variable-local'].includes(t.token))
					.forEach((f) => {
						const range = f.range
						const vartype = f.token.split('-')[1]
						range.end.character = range.end.character + 1
						const name = lspdoc.document.getText(range)
						const docsym = {
							kind: vartype === 'global' ? SymbolKind.Variable : SymbolKind.Constant,
							name: name,
							range: range,
							selectionRange: range,
							detail: `:${vartype} on line ${range.start.line}`,
							children: [],
						}
						const existing = symbolsVariableTree.filter((i) => i.name === name)
						if (existing.length === 1 && docsym.kind === existing[0].kind) {
							if (existing[0].children) {
								existing[0].children.push(docsym)
							} else {
								existing[0].children = [docsym]
							}
							const replaceIndex = symbolsVariableTree.findIndex((i) => i.name === name)
							symbolsVariableTree[replaceIndex] = existing[0]
						} else {
							symbolsVariableTree.push(docsym)
						}
					})
				log.info(`<server> {onDocumentSymbols} found ${symbolsVariableTree.length} for ${lspdoc.uri}`)
				return [...symbolsVariableTree]
			}
		}
}
