
// Import from Microsoft's vscode-languageserver library
import {
    createConnection,
    TextDocuments,
    ProposedFeatures,
    InitializeParams,
    TextDocumentSyncKind,
    InitializeResult,
    DidChangeConfigurationNotification,
    CompletionItem,
    CompletionItemKind,
    InsertTextFormat,
    TextDocumentPositionParams,
    DiagnosticSeverity,
    Range,
    WillCreateFilesRequest,
    DocumentDiagnosticReportKind,
    type DocumentDiagnosticReport,
    Diagnostic,
    TextEdit,
    TextDocumentIdentifier,
    SemanticTokensParams,
    SemanticTokens,
    SemanticTokensBuilder,
    Hover,
    HoverParams,
    WorkspaceSymbolParams,
    WorkspaceSymbol,
    HandlerResult,
    DidChangeConfigurationRegistrationOptions,
    DidChangeConfigurationParams,
    WorkspaceFoldersChangeEvent,
    CompletionParams
} from "vscode-languageserver/node";

import { TextDocument } from "vscode-languageserver-textdocument";

import axios = require('axios');


// Create a connection for the server
const connection = createConnection(ProposedFeatures.all);
connection.console.log(`createConnection() called`);


// Create a simple text document manager
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);
connection.console.log(`TextDocuments 'documents' loaded: #keys ${documents.keys.length}`);


// Only keep settings for open documents
documents.onDidClose((e: { document: { uri: any; }; }) => {
    documentSettings.delete(e.document.uri);
});

// Initialize capabilities of the server
let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;


// The example settings
interface LspSettings {
    maxNumberOfProblems: number;
    baseUrl: string; // Base URL for the RouterOS API
    username: string;
    password: string;
}

// The global settings, used when the `workspace/configuration` request is not supported by the client.
// Please note that this is not the case when using this server with the client provided in this example
// but could happen with other clients.
const defaultSettings: LspSettings = { maxNumberOfProblems: 100, baseUrl: 'http://192.168.88.1', username: 'lsp', password: 'changeme' };
let globalSettings: LspSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings = new Map<string, Thenable<LspSettings>>();


// Initialize the server
connection.onInitialize((params: InitializeParams) => {
    // Check client capabilities
    const capabilities = params.capabilities;
    connection.console.log(`connection.onInitialize() CLIENT capabilities: ${JSON.stringify(capabilities, null, 2)}`);

    // TODO: should REQUIRE configuration capacity, and fail GRACEFULLY if not

    // Does the client support the `workspace/configuration` request?
    // If not, we fall back using global settings.
    hasConfigurationCapability = !!(
        capabilities.workspace && !!capabilities.workspace.configuration
    );
    hasWorkspaceFolderCapability = !!(
        capabilities.workspace && !!capabilities.workspace.workspaceFolders
    );
    hasDiagnosticRelatedInformationCapability = !!(
        capabilities.textDocument &&
        capabilities.textDocument.publishDiagnostics &&
        capabilities.textDocument.publishDiagnostics.relatedInformation
    );

    // Set the capabilities of the server
    const result: InitializeResult = {
        capabilities: {
            textDocumentSync: TextDocumentSyncKind.Full,
            semanticTokensProvider: {
                legend: {
                    tokenTypes: tokenTypes,
                    tokenModifiers: [], // optional
                },
                full: { delta: false },
                range: false,
                documentSelector: [{ language: 'routeros' }, { language: 'rsc' }, { scheme: "file", pattern: '**∕*.rsc' }, { language: "routeroslsp" }]
            },
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: [':', '=', '/', ' ']
            },
            diagnosticProvider: {
                interFileDependencies: false,
                workspaceDiagnostics: false
            },
            hoverProvider: true
        },
    };

    // Support workspace folders (maybe?)
    if (hasWorkspaceFolderCapability) {
        result.capabilities.workspace = {
            workspaceFolders: {
                supported: true
            }
        };
    }

    connection.console.log(`connection.onInitialize() SERVER capabilities:  ${JSON.stringify(result, null, 2)}`);

    // Return capabilities to the client
    return result;
});

// After initialization, the server is ready to handle requests
connection.onInitialized(() => {
    connection.console.log(`connection.onInitialized() fired.`);

    // TODO: should register config cap include an undefined?
    if (hasConfigurationCapability) {
        // Register for all configuration changes
        connection.client.register(DidChangeConfigurationNotification.type, { section: "routeroslsp" });
    }
    if (hasWorkspaceFolderCapability) {
        connection.workspace.onDidChangeWorkspaceFolders((_event: WorkspaceFoldersChangeEvent) => {
            connection.console.log(`onDidChangeWorkspaceFolders() fired but unhandled for: ${_event}`);
        });
    }
});

// TODO: this should be cleaned up....
connection.onDidChangeConfiguration((change: DidChangeConfigurationParams) => {
    // TODO: use property type for 'change' not any
    connection.console.log(`onDidChangeConfiguration() fired with change: ${JSON.stringify(change.settings?.routeroslsp)}`);
    if (hasConfigurationCapability) {
        // Reset all cached document settings
        documentSettings.clear();
    } else {
        globalSettings = (
            (change.settings.routeroslsp || defaultSettings)
        );
    }
});

// This handler provides the initial list of completion items
connection.onCompletion(async (params: CompletionParams) => {
    connection.console.log(`connection.onCompletion() fired for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`);

    const document = documents.get(params.textDocument.uri);
    if (!document) {
        connection.console.info(`connection.onCompletion() does not have a document, returning no completion.`)
        return [];
    }
    const settings = await getDocumentSettings(document.uri);

    const text = document.getText();
    const position = params.position;
    const offset = document.offsetAt(position);

    const completions: CompletionItem[] = [];

    const roscompletion = await fetchInspect("completion", text.slice(0, offset), settings)

    roscompletion.forEach((item: any, index: number) => {
        if (item.show === 'true') {
            completions.push({
                label: item.completion,
                // TODO: should map 'kind' to proper tokenType - harder than it might seem since it's prospective
                kind: CompletionItemKind.Text,
                data: index,
                insertText: item.completion,
                insertTextFormat: InsertTextFormat.PlainText,
                // detail: item.toString(),
                // documentation: item.documentation || ''
            });
        }
    })

    connection.console.log(`connection.onCompletion() finished: #completions ${completions.length}`);
    return completions;
});


// This handler resolves additional information for the item selected in
// the completion list.
connection.onCompletionResolve(
    (item: CompletionItem): CompletionItem => {
        /*if (item.data === 1) {
            item.detail = 'TypeScript details';
            item.documentation = 'TypeScript documentation';
        } else if (item.data === 2) {
            item.detail = 'JavaScript details';
            item.documentation = 'JavaScript documentation';
        }*/
        connection.console.log(`onCompletionResolve() fired but unhandled. Got: data #${item.data} label '${item.label}' kind '${item.kind}' detail '${item.detail}' `);
        return item;
    }
);


connection.onRequest("textDocument/semanticTokens/full", async (params) => {
  // Implement your logic to provide semantic tokens for the given document here.
  // You should return the semantic tokens as a response.
 const document = documents.get(params.textDocument.uri);
    if (!document) {
        connection.console.info(`semanticTokens.on() does not have a document, returning no tokens.`)
        return { data: [] };
    }
    const settings = await getDocumentSettings(params.textDocument.uri);


    const builder = new SemanticTokensBuilder();
    const highlights = await fetchInspect("highlight", document.getText(), settings)
    if (!highlights || highlights.length === 0) {
        connection.console.error(`semanticTokens.on() no highlights found: ${document.uri}`);
    }

    const tokens: any[] = highlights[0].highlight.split(",");

    const ranges = groupRanges(tokens)
    connection.console.log(`semanticTokens.on() processing: #tokens ${tokens.length} #ranges ${ranges.length}`)
    ranges.forEach((range) => {
        if (range[0] !== "none") {
            const pos = document.positionAt(range[1])
            builder.push(pos.line, pos.character, (range[2] - range[1]) + 1, tokenTypes.indexOf(range[0]), 0);
        }
    })

    return builder.build();
});

// Diagnostic provider
connection.languages.diagnostics.on(async (params) => {
    connection.console.log(`diagnostics.on() called for uri: ${params.textDocument.uri}`);

    const document = documents.get(params.textDocument.uri);
    if (document !== undefined) {
        return {
            kind: DocumentDiagnosticReportKind.Full,
            items: await validateTextDocument(document)
        } satisfies DocumentDiagnosticReport;
    } else {
        // We don't know the document. We can either try to read it from disk
        // or we don't report problems for it.
        connection.console.info(`diagnostics.on() got no document.`);
        // TODO: likely should report warning or error, instead of empty - there should be a document, i think...
        return {
            kind: DocumentDiagnosticReportKind.Full,
            items: []
        } satisfies DocumentDiagnosticReport;
    }
});


connection.onHover(async (params: TextDocumentPositionParams): Promise<Hover | null> => {
    
    const pos = params.position;
    const doc = documents.get(params.textDocument.uri);
    const settings = await getDocumentSettings(params.textDocument.uri);
    if (!doc) {
        connection.console.info(`connection.onHover() does not have a document, returning no hover.`)
        return null;
    }
    
    const highlights = await fetchInspect("highlight", doc.getText(), settings)
    const tokens = highlights[0].highlight.split(",")
    const offset = doc.offsetAt(pos)
    const groupRange = findGroupRange(tokens, offset)
    const hoverInfo = `### <kbd>${tokens[offset]}</kbd>\n\`offset ${offset} line ${pos.line} char ${pos.character} grp ${groupRange}\``
    
    connection.console.log(`connection.onHover(): offset ${offset} line ${pos.line} char ${pos.character} grp ${groupRange}`);
    return {
        contents: {
            kind: 'markdown',
            value: hoverInfo,
        },
        range: {
            start: doc.positionAt(groupRange[0]),
            end: doc.positionAt(groupRange[1] + 1)
        }
    };
});

// HELPERS

async function fetchInspect(request: string, text: any, settings: LspSettings): Promise<any> {
    connection.console.log(`--> /console/inspect ${request.toUpperCase()} started`);

    try {
        const response = await axios.post(
            `${settings.baseUrl}/rest/console/inspect`,
            {
                request: request,
                input: text
            },
            {
                auth: {
                    username: settings.username || 'lsp',
                    password: settings.password || 'changeme'
                },
                headers: {
                    'Content-Type': 'application/json',
                },
            }
        );

        const resp: any = response.data;
        connection.console.log(`<-- /console/inspect ${request.toUpperCase()} got: #data ${resp.length}`);

        return resp;

    } catch (error: any) {
        // TODO: not sure how to handle these errors - they'd be fatal...
        let errorText: string;
        if (error) {
            errorText = `<-> /console/inspect ${request.toUpperCase()} got: ${error.message}`
            connection.console.error(errorText);
            lspAlert(errorText)
            if (error.response) {
                errorText = `<-> /console/inspect ${request.toUpperCase()} got: ${error.response.data}`
                connection.console.error(errorText);
                lspAlert(errorText)
            }
        } else {
            errorText = `<-> /console/inspect ${request.toUpperCase()} got: ${JSON.stringify(error, null, 2)}`;
            connection.console.error(errorText);
            lspAlert(errorText)
        }
    }
}

function getDocumentSettings(resource: string): Thenable<LspSettings> {
    connection.console.log(`getDocumentSettings() called for uri: ${resource}`);
    if (!hasConfigurationCapability) {
        return Promise.resolve(globalSettings);
    }
    let result = documentSettings.get(resource);
    if (!result) {
        result = connection.workspace.getConfiguration({
            scopeUri: resource,
            section: 'routeroslsp'
        });
        documentSettings.set(resource, result);
    }
    return result;
}


async function lspAlert(message: string): Promise<void> {
    connection.window.showInformationMessage(message);
}

async function validateTextDocument(textDocument: TextDocument): Promise<Diagnostic[]> {
    connection.console.log(`validateTextDocument() with uri: ${textDocument.uri}`);

    // Get the settings for this document
    const settings = await getDocumentSettings(textDocument.uri);

    const text = textDocument.getText();

    const diagnostics: Diagnostic[] = [];

    const highlights = await fetchInspect("highlight", text, settings)
    if (!highlights || highlights.length === 0) {
        connection.console.error(`validateTextDocument() no highlights found: ${textDocument.uri}`);
        // TODO: should inject some error actually, not "nothing"...
        return diagnostics; // No highlights, no diagnostics
    }

    const tokens: any[] = highlights[0].highlight.split(",");

    // Get highlights from router
    let lastToken: any = null;
    let lastTokenPosition: any = null;
    tokens.forEach((token: any, index: any) => {
        // format: [line, char, length, tokenType, tokenModifiers]
        if (lastTokenPosition === null) {
            lastTokenPosition = textDocument.positionAt(index + 1);
        }
        if (lastToken === null) {
            lastToken = token;
        }
        if (lastToken !== token || index === tokens.length - 1) {
            if (badTokenTypes.includes(token)) {
                const diagnostic: Diagnostic = {
                    severity: DiagnosticSeverity.Error,
                    range: {
                        start: lastTokenPosition,
                        end: textDocument.positionAt(tokens.length)
                    },
                    message: token,
                    source: 'routeroslsp'
                };
                /* // adds 2nd line to Problems, not needed
                if (hasDiagnosticRelatedInformationCapability) {
                    diagnostic.relatedInformation = [
                        {
                            location: {
                                uri: textDocument.uri,
                                range: Object.assign({}, diagnostic.range)
                            },
                            message: 'Additional details missing'
                        }
                    ];
                }
                    */
                diagnostics.push(diagnostic);
            }
        }
        lastToken = token;
        lastTokenPosition = textDocument.positionAt(index + 1);
    })

    // Limit the number of problems reported
    const maxProblems = settings.maxNumberOfProblems || 1000;
    const limitedDiagnostics = diagnostics.slice(0, maxProblems);

    // Send the computed diagnostics to VSCode
    // TODO: why is commented out, could be left over or might be needed...
    //connection.sendDiagnostics({ uri: textDocument.uri, diagnostics: limitedDiagnostics });

    connection.console.log(`validateTextDocument() completed.  Result: #errors ${limitedDiagnostics.length}`);
    return limitedDiagnostics
}

const badTokenTypes = ['variable-undefined', 'error', 'obj-inactive', 'syntax-obsolete', 'syntax-old', 'ambiguous'];
const tokenTypes = ["none", "dir", "cmd", "arg", "varname-local", "variable-parameter", "variable-local", "syntax-val", "varname", "syntax-meta", "escaped", "variable-global", "comment", "obj-inactive", "syntax-obsolete", "variable-undefined", "ambiguous", "syntax-old", "error", "varname-global", "syntax-noterm"]

function findGroupRange(arr: string[], index: number): number[] {
    const value = arr[index];
    let start = index;
    let end = index;
    // Expand to the left
    while (start > 0 && arr[start - 1] === value) {
        start--;
    }
    // Expand to the right
    while (end < arr.length - 1 && arr[end + 1] === value) {
        end++;
    }
    // Return [index, index] if no group found
    const result = start === end ? [index, index] : [start, end];

    connection.console.log(`findGroupRange() finished for index ${index} with #groups ${result.length}`);
    
    return result
}

function groupRanges(arr: string[]): [string, number, number][] {
    const result: [string, number, number][] = [];
    let i = 0;

    while (i < arr.length) {
        const value = arr[i];
        let start = i;
        let end = i;

        // Scan ahead while the value stays the same
        while (end + 1 < arr.length && arr[end + 1] === value) {
            end++;
        }

        result.push([value, start, end]);
        i = end + 1; // Move to the next distinct value
    }

    connection.console.log(`findGroupRange() finished with #groups ${result.length}}`);
    return result;
}

// MAIN if open or change, do something
documents.onDidChangeContent(async (change) => {
    connection.console.log(`documents.onDidChangeContent() fired for ${change.document.uri}`);
});

documents.onDidOpen(async (change) => {
    connection.console.log(`documents.onDidOpen() fired for ${change.document.uri} - noop`);
});

connection.onDidChangeWatchedFiles(async (change: any) =>{
    connection.console.log(`connection.onDidChangeWatchedFiles() fired for ${change.document.uri}`);
})

connection.onDidChangeTextDocument(async (change: any) =>{
    connection.console.log(`connection.onDidChangeTextDocument() fired for ${change.document.uri}`);
})


// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
