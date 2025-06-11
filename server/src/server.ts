
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
    HandlerResult
} from "vscode-languageserver/node";

import { TextDocument } from "vscode-languageserver-textdocument";

import axios = require('axios');


// Create a connection for the server
const connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

// Only keep settings for open documents
documents.onDidClose((e: { document: { uri: any; }; }) => {
    documentSettings.delete(e.document.uri);
});

// Store capabilities of the server
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
const defaultSettings: LspSettings = { maxNumberOfProblems: 101, baseUrl: 'http://192.168.88.1', username: 'admin', password: '' };
let globalSettings: LspSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings = new Map<string, Thenable<LspSettings>>();


// Initialize the server
connection.onInitialize((params: InitializeParams) => {
    // Check client capabilities
    const capabilities = params.capabilities;


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
            textDocumentSync: TextDocumentSyncKind.Incremental,
            semanticTokensProvider: {
                legend: {
                    tokenTypes: tokenTypes,
                    tokenModifiers: [], // optional
                },
                full: { delta: false },
                range: false,
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

    // Return capabilities to the client
    return result;
});

// After initialization, the server is ready to handle requests
connection.onInitialized(() => {
    if (hasConfigurationCapability) {
        // Register for all configuration changes
        connection.client.register(DidChangeConfigurationNotification.type, undefined);
    }
    if (hasWorkspaceFolderCapability) {
        connection.workspace.onDidChangeWorkspaceFolders((_event: any) => {
            connection.console.log('Workspace folder change event received.');
        });
    }
});

connection.onDidChangeConfiguration((change: any) => {
    if (hasConfigurationCapability) {
        // Reset all cached document settings
        documentSettings.clear();
    } else {
        globalSettings = (
            (change.settings.routeroslsp || defaultSettings)
        );
    }
    connection.languages.diagnostics.refresh();
});


connection.onDidChangeWatchedFiles(_change => {
    // Monitored files have change in VSCode
    connection.console.log('We received a file change event');
});

// This handler provides the initial list of completion items
connection.onCompletion(async (textDocumentPosition: TextDocumentPositionParams) => {
    const document = documents.get(textDocumentPosition.textDocument.uri);
    if (!document) {
        return [];
    }
    const settings = await getDocumentSettings(document.uri);

    const text = document.getText();
    const position = textDocumentPosition.position;
    const offset = document.offsetAt(position);

    const completions: CompletionItem[] = [];

    const roscompletion = await fetchInspect("completion", text.slice(0, offset), settings)

    roscompletion.forEach((item: any, index: number) => {
        if (item.show === 'true') {
            completions.push({
                label: item.completion,
                kind: CompletionItemKind.Text,
                data: index,
                insertText: item.completion,
                insertTextFormat: InsertTextFormat.PlainText,
                // detail: item.toString(),
                // documentation: item.documentation || ''
            });
        }
    })

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
        connection.console.log(`Completion item resolved: #${item.data} ${item.label} `);
        return item;
    }
);

connection.languages.semanticTokens.on(async (params: SemanticTokensParams): Promise<SemanticTokens> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) return { data: [] };

    const builder = new SemanticTokensBuilder();

    const tokens = await lastTokens
    const ranges = groupRanges(tokens)
    connection.console.log(` starting tokenizer with ${ranges}`)
    ranges.forEach((range) => {
        if (range[0] !== "none") {
            const pos = document.positionAt(range[1])
            builder.push(pos.line, pos.character, (range[2] - range[1]) + 1, tokenTypes.indexOf(range[0]), 0);
            connection.console.log(`semantic: ${range[0]} ${pos.line}:${pos.character} ${(range[2] - range[1]) + 1}`);
        }
    })
    /*
    // Example: hardcoded one token at line 1, character 1, length 5
    tokens.forEach((token: any, index: any) => {
        const pos = document.positionAt(index);
        builder.push(pos.line, pos.character, 1, encodeTokenType(token), 0);
    })
    */

    return builder.build();
});

// Diagnostic provider
connection.languages.diagnostics.on(async (params) => {
    const document = documents.get(params.textDocument.uri);
    if (document !== undefined) {
        return {
            kind: DocumentDiagnosticReportKind.Full,
            items: await validateTextDocument(document)
        } satisfies DocumentDiagnosticReport;
    } else {
        // We don't know the document. We can either try to read it from disk
        // or we don't report problems for it.
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
    if (!doc) return null;

    // TODO: consolate into ranges
    const highlights = await fetchInspect("highlight", doc.getText(), settings)
    const tokens = highlights[0].highlight.split(",")
    const offset = doc.offsetAt(pos)
    const groupRange = findGroupRange(tokens, offset)
    const hoverInfo = `### <kbd>${tokens[offset]}</kbd>\n\`offset ${offset} line ${pos.line} char ${pos.character} grp ${groupRange}\``
    connection.languages.semanticTokens.refresh();

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
    try {
        const response = await axios.post(
            `${settings.baseUrl}/rest/console/inspect`,
            {
                request: request,
                input: text
            },
            {
                auth: {
                    username: settings.username || 'admin',
                    password: settings.password || ''
                },
                headers: {
                    'Content-Type': 'application/json',
                },
            }
        );

        const resp: any = response.data;
        return resp;

    } catch (error: any) {
        // TODO: not sure how to handle these errors - they'd be fatal...
        if (error) {
            console.error('Axios error:', error.message);
            if (error.response) {
                console.error('Response body:', error.response.data);
            }
        } else {
            console.error('Unexpected error:', error);
        }
    }
}

function getDocumentSettings(resource: string): Thenable<LspSettings> {
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


async function logLsp(message: string): Promise<void> {
    connection.window.showInformationMessage(message);
}

let lastTokens: any[] = []

async function validateTextDocument(textDocument: TextDocument): Promise<Diagnostic[]> {
    // Get the settings for this document
    const settings = await getDocumentSettings(textDocument.uri);

    const text = textDocument.getText();

    const diagnostics: Diagnostic[] = [];

    connection.languages.semanticTokens.refresh();
    const highlights = await fetchInspect("highlight", text, settings)
    if (!highlights || highlights.length === 0) {
        connection.console.error(`No highlights found for document: ${textDocument.uri}`);
        return diagnostics; // No highlights, no diagnostics
    }
    lastTokens = highlights[0].highlight.split(",")
    const tokens: any[] = lastTokens;

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


    // Simple syntax checking - look for common issues
    const lines = text.split('\n');

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
    }

    // Limit the number of problems reported
    const maxProblems = settings.maxNumberOfProblems || 1000;
    const limitedDiagnostics = diagnostics.slice(0, maxProblems);

    // Send the computed diagnostics to VSCode
    //connection.sendDiagnostics({ uri: textDocument.uri, diagnostics: limitedDiagnostics });
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
    return start === end ? [index, index] : [start, end];
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

    return result;
}

// "Main" - did something change?
documents.onDidChangeContent(async (change) => {
    validateTextDocument(change.document);
});



// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
