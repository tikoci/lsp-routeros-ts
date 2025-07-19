import {
  CompletionItem,
  CompletionItemKind,
  CompletionParams,
  Connection,
  DidChangeConfigurationNotification,
  DidChangeConfigurationParams,
  DocumentDiagnosticParams,
  DocumentDiagnosticReportKind,
  DocumentSymbol,
  DocumentSymbolParams,
  Hover,
  InitializeParams,
  InitializeResult,
  InsertTextFormat,
  PublishDiagnosticsParams,
  SemanticTokens, SemanticTokensBuilder,
  SemanticTokensParams,
  ServerCapabilities,
  SymbolInformation,
  SymbolKind,
  TextDocumentPositionParams,
  TextDocuments,
  TextDocumentSyncKind,
  type DocumentDiagnosticReport,
} from 'vscode-languageserver'
import { DocumentUri, TextDocument } from 'vscode-languageserver-textdocument'
import { CompletionInspectResponseItem, RouterRestClient } from './routeros'
import { clearConnectionUrl, ConnectionLogger, getSettings, log, updateSettings, useConnectionUrl } from './shared'
import { LspDocument } from './model'
import { HighlightTokens } from './tokens'
// import { AxiosError } from 'axios'

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

  static get default() {
    return LspController.#default
  }

  static start(connection: Connection) {
    ConnectionLogger.console = connection.console
    log.debug('<LspController> start()')
    return LspController.#default = new LspController(connection)
  }

  private constructor(connection: Connection) {
    this.#connection = connection
    this.#documents = new TextDocuments(TextDocument)

    const readyResolver = Promise.withResolvers<void>()
    this.#ready = readyResolver.promise

    connection.onInitialize((params): InitializeResult => {
      let serverCapabilities = LspController.getServerCapabilities(params)
      if (LspController.hasCapability(
        'workspaceFolders',
        params,
      )) {
        serverCapabilities = {
          ...serverCapabilities,
          ...{
            workspace: { workspaceFolders: { supported: true } },
          },
        }
        log.debug(`<LspController> {onInitialize} workspaceFolders true`)
      }
      this.#hasShowMessageCapability = LspController.hasCapability('showMessage', params)
      log.debug(`<LspController> {onInitialize} hasShowMessageCapability ${this.#hasShowMessageCapability}`)
      this.#hasConfigurationCapability = !!(
        params.capabilities.workspace && !!params.capabilities.workspace.configuration
      )
      log.debug(`<LspController> {onInitialize} hasConfigurationCapability ${this.#hasConfigurationCapability}`)
      return { capabilities: serverCapabilities }
    })

    connection.onInitialized(() => {
      // connection.client.register(SemanticTokensRegistrationType.type, );
      if (this.#hasConfigurationCapability === true) {
        connection.client.register(DidChangeConfigurationNotification.type, { section: 'routeroslsp' })
        log.debug(`<LspController> {onInitialized} refresh configuration`)
        connection.workspace.getConfiguration(LspController.shortid).then((e) => {
          updateSettings(e)
          readyResolver.resolve()
        })
      }
      else {
        readyResolver.resolve()
      }
    })

    // handle future configuration changes
    connection.onDidChangeConfiguration((e: DidChangeConfigurationParams) => {
      log.info(`<LspController> {onDidChangeConfiguration} ${e.settings.routeroslsp.baseUrl} user ${e.settings.routeroslsp.username} apiTimeout ${e.settings.routeroslsp.apiTimeout} allowClientProvidedCredentials ${e.settings.routeroslsp.allowClientProvidedCredentials}`)
      if (e.settings.routeroslsp) {
        updateSettings(e.settings.routeroslsp)
        this.#documents.keys().forEach((k) => {
          this.#lspDocuments.get(k)?.refresh()
        })
        setTimeout(() => connection.languages.semanticTokens.refresh(), 10 * 1000)
      }
      else log.warn('{onDidChangeConfiguration} got no settings, skipping update')
    })

    // force token refresh after 10s, after ready
    this.isReady.then(() => setTimeout(() => connection.languages.semanticTokens.refresh(), 10 * 1000))

    this.#documents.onDidOpen((e) => {
      log.info(`<LspController> {onDidOpen} ${e.document.uri}`)
      // this.lspDocuments.delete(e.document.uri)
    })
    // document cache handlers (open is included in onDidChangeContent)
    this.#documents.onDidChangeContent(async (e) => {
      log.info(`<LspController> {onDidChangeContent} ${e.document.uri}`)
      await this.getLspDocument(e.document.uri, true)
    })
    this.#documents.onDidClose((e) => {
      log.info(`<LspController> {onDidClose} ${e.document.uri} `)
      this.#lspDocuments.delete(e.document.uri)
    })
    // document cache handlers (open is included in onDidChangeContent)
    this.#documents.onDidSave(async (e) => {
      log.info(`<LspController> {onDidSave} ${e.document.uri}`)
      await this.getLspDocument(e.document.uri, true)
    })

    // TODO: newer LSP feature, untested, just logging
    connection.notebooks.synchronization.onDidChangeNotebookDocument(async e => log.debug(`<LspController> notebook change< ${JSON.stringify(e)}`))
    connection.notebooks.synchronization.onDidOpenNotebookDocument(async e => log.debug(`<LspController> >notebook open< ${JSON.stringify(e)}`))
    connection.notebooks.synchronization.onDidSaveNotebookDocument(async e => log.debug(`<LspController> >notebook save< ${JSON.stringify(e)}`))
    connection.notebooks.synchronization.onDidCloseNotebookDocument(async e => log.debug(`<LspController> >notebook close< ${JSON.stringify(e)}`))

    // hover
    connection.onHover(this.onHoverHandler(this))

    // "Problems" (diagnostics)
    connection.languages.diagnostics.on(this.handleDiagnostics(this))

    // completion
    connection.onCompletion(this.onCompletionHandler(this))
    connection.onCompletionResolve(this.onCompletionResolveHandler(this))

    // semantic tokens
    connection.onRequest(
      'textDocument/semanticTokens/full',
      this.generateSemanticTokens(this),
    )

    // symbols (variables)
    connection.onDocumentSymbol(this.onDocumentSymbols(this))

    // execute (commands sent from client/editor to run in LSP)
    connection.onExecuteCommand(async (e) => {
      log.info(
        `<LspController> {onExecuteCommand} [${e.command}] ${JSON.stringify(
          e.arguments?.map((a, i) => e.command === 'routeroslsp.server.useConnectionUrl' && i === 2 ? '***' : a))}`)
      await this.isReady
      switch (e.command) {
        case 'routeroslsp.server.sendSemanticTokensRefresh': {
          return connection.languages.semanticTokens.refresh()
        }
        case 'routeroslsp.server.useConnectionUrl': {
          return useConnectionUrl(e)
        }
        case 'routeroslsp.server.clearConnectionUrl': {
          return clearConnectionUrl()
        }
        case 'routeroslsp.server.router.getIdentity': {
          try {
            return await RouterRestClient.default.getIdentityRaw()
          }
          catch (error) { return error }
        }
        case 'routeroslsp.server.getConnectionUrl': {
          const settings = getSettings()
          const url = URL.parse(settings.baseUrl)
          if (url !== null) {
            url.username = settings.username
            return url.toString()
          }
          else {
            return null
          }
        }
      }
    })

    // listen to document cache
    this.#documents.listen(connection)

    log.debug('<LspController> {constructor} done')
  }

  /*
  get settings() {
    if (this.#hasConfigurationCapability === null) {
      return this.connection.workspace.getConfiguration(LspController.shortid).then((e) => {
        updateSettings(e)
        log.info(JSON.stringify(getSettings()))
        return getSettings()
      })
    }
    else {
      return Promise.resolve(getSettings())
    }
  }
    */

  async getLspDocument(uri: DocumentUri, refresh = false): Promise<LspDocument> {
    let lspdocument
    await this.isReady
    if (refresh == false) {
      lspdocument = this.#lspDocuments.get(uri)
      if (lspdocument) {
        log.debug(`<LspController> {getLspDocument} cache hit: ${uri}`)

        return lspdocument
      }
    }
    else {
      log.debug(`<LspController> {getLspDocument} refresh requested, remove cache: ${uri}`)
      this.#lspDocuments.delete(uri)
    }
    // if not, force loading from document cache
    const document = this.#documents.get(uri)
    if (document) {
      log.debug(`<LspController> {getLspDocument} creating cache: ${uri}`)
      lspdocument = await LspDocument.create(document)
      this.#lspDocuments.set(
        uri,
        lspdocument,
      )
      return lspdocument
    }
    const errMsg = `ERROR <LspController> {getLspDocument} failed to get LspDocument, throwing: ${uri}`
    log.warn(errMsg)
    throw new Error(errMsg)
  }

  static hasCapability(capacity: string, params: InitializeParams): boolean {
    const clientCapabilities = params.capabilities
    switch (capacity) {
      case 'configuration': return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.configuration)
      case 'workspaceFolders': return !!(clientCapabilities.workspace && !!clientCapabilities.workspace.workspaceFolders)
      case 'diagnosticsRelatedInformation': return !!(
        clientCapabilities.textDocument
        && clientCapabilities.textDocument.publishDiagnostics
        && clientCapabilities.textDocument.publishDiagnostics.relatedInformation
      )
      case 'showMessage': return !!(clientCapabilities.window && !!clientCapabilities.window.showMessage)
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
          'routeroslsp.server.useConnectionUrl',
          'routeroslsp.server.clearConnectionUrl',
          'routeroslsp.server.router.getIdentity',
          'routeroslsp.server.getConnectionUrl',
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
        triggerCharacters: [
          ':',
          '=',
          '/',
          ' ',
          '$',
          '[',
        ],
      },
      diagnosticProvider: {
        interFileDependencies: false,
        workspaceDiagnostics: false,
      },
      hoverProvider: true,
      workspace: {
        workspaceFolders: {
          supported: LspController.hasCapability(
            'workspaceFolders',
            params,
          ),
        },
      },
      documentSymbolProvider: true,
    }
  }

  sendDiagnostics = (diagnostics: PublishDiagnosticsParams) => {
    log.info(`<LspController> {sendDiagnostics} ${diagnostics.uri} len ${diagnostics.diagnostics.length}`)
    this.connection.sendDiagnostics(diagnostics)
  }

  // MARK: hover

  onHoverHandler = (controller: LspController) => async (params: TextDocumentPositionParams): Promise<Hover | undefined> => {
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
      }
      else {
        return undefined
      }
    }
    else {
      const errMsg = `<onHoverHandler> {onHoverHandler} failed to get document: ${params.textDocument.uri}`
      log.warn(errMsg)
      throw new Error(errMsg)
    }
  }

  // MARK: diagnostics

  handleDiagnostics = (controller: LspController) => async (params: DocumentDiagnosticParams) => {
    log.debug(`<LspController> {handleDiagnostics} for ${params.textDocument.uri}`)

    const document = await controller.getLspDocument(params.textDocument.uri)
    if (document) {
      const diags = await document.diagnostics()
      if (!diags) {
        throw new Error('bad document in handleDiagnostics()')
      }
      return {
        kind: DocumentDiagnosticReportKind.Full,
        items: diags,
      } satisfies DocumentDiagnosticReport
    }
    else {
      throw new Error('handleDiagnostics failed, no document')
    }
  }

  // MARK: completion

  onCompletionResolveHandler = (_: LspController) => (item: CompletionItem): CompletionItem => {
    return item
  }

  onCompletionHandler = (controller: LspController) => async (params: CompletionParams) => {
    const startTime = Date.now()
    log.debug(`<LspController> {onCompletionHandler} for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`)

    const document = await controller.getLspDocument(params.textDocument.uri)
    if (!document) {
      log.warn(`<LspController> {onCompletionHandler} failed for '${params.textDocument.uri}' failed to get '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character})`)
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
      log.debug(`<LspController> {onCompletionHandler} done in ${(Date.now() - startTime)}ms`)
      return results
    }
    else {
      return results
    }
  }

  // MARK: tokens

  generateSemanticTokens = (controller: LspController) => async (params: SemanticTokensParams): Promise<SemanticTokens | null> => {
    const startTime = Date.now()
    log.debug('<LspController> {generateSemanticToken} starting')
    // ErrorCodes.ServerCancelled
    const document = await controller.getLspDocument(params.textDocument.uri)
    if (!document) {
      const noDocErrorMsg = `<LspController> {generateSemanticToken} found no document, throwing`
      log.warn(noDocErrorMsg)
      throw new Error(noDocErrorMsg)
    }
    const builder = new SemanticTokensBuilder()
    const htokens = await document.highlightTokens
    if (!htokens || htokens.tokens.length === 0) {
      log.warn(`<LspController> {generateSemanticTokens} no higlightTokens found: ${document.uri}`)
    }
    else {
      const tokenRanges = htokens.tokenRanges
      log.debug(`<LspController> {generateSemanticTokens} found #tokens ${htokens.tokens.length} #ranges ${tokenRanges.length}`)
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
    log.debug(`<LspController> {generateSemanticTokens} done in ${(Date.now() - startTime)}ms`)
    return packed
  }

  // MARK: symbols

  onDocumentSymbols = (controller: LspController) => async (params: DocumentSymbolParams): Promise<SymbolInformation[] | DocumentSymbol[] | undefined | null> => {
    log.debug('<LspController> {onDocumentSymbols} starting: ${params.textDocument.uri}')
    const lspdoc = await controller.getLspDocument(params.textDocument.uri)
    const highlightTokens = await lspdoc.highlightTokens
    const tokenRanges = highlightTokens.tokenRanges
    // const symbols : DocumentSymbol[] = [];
    const symbolsVariableTree: DocumentSymbol[] = []
    tokenRanges.filter(t => [
      'variable-global',
      'variable-local',
    ].includes(t.token)).forEach((f) => {
      const range = f.range
      const vartype = f.token.split('-')[1]
      range.end.character = range.end.character + 1
      const name = lspdoc.document.getText(range)
      const docsym = {
        kind: vartype === 'global'
          ? SymbolKind.Variable
          : SymbolKind.Constant,
        name: name,
        range: range,
        selectionRange: range,
        detail: `:${vartype} on line ${range.start.line}`,
        children: [],
      }
      const existing = symbolsVariableTree.filter(i => i.name == name)
      if (existing.length === 1 && docsym.kind === existing[0].kind) {
        if (existing[0].children) {
          existing[0].children.push(docsym)
        }
        else {
          existing[0].children = [docsym]
        }
        const replaceIndex = symbolsVariableTree.findIndex(i => i.name == name)
        symbolsVariableTree[replaceIndex] = existing[0]
      }
      else {
        symbolsVariableTree.push(docsym)
      }
    })

    log.info(`<LspController> {onDocumentSymbols} found ${symbolsVariableTree.length} for ${lspdoc.uri}`)
    return [...symbolsVariableTree]
  }
}
