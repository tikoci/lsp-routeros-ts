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
  CompletionParams,
  DocumentDiagnosticParams,
  WorkspaceDiagnosticParams,
  WorkspaceDiagnosticReport,
  WorkspaceDocumentDiagnosticReport,
  TextDocumentChangeEvent,
  TextDocumentSyncOptions,
} from "vscode-languageserver/node";

import { TextDocument } from "vscode-languageserver-textdocument";

import axios = require("axios");

const connection = createConnection(ProposedFeatures.all);
connection.console.info(`RouterOS LSP loading...`);

const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);
connection.console.log(
  `created 'documents' cache: #keys ${documents.keys.length}`
);

// Configuration types
interface LspSettings {
  maxNumberOfProblems: number;
  baseUrl: string; // Base URL for the RouterOS API
  username: string;
  password: string;
  hotlock: boolean;
}

// The global settings, used when the `workspace/configuration` request is not supported by the client.
// Please note that this is not the case when using this server with the client provided in this example
// but could happen with other clients.
const defaultSettings: LspSettings = {
  maxNumberOfProblems: 100,
  baseUrl: "http://192.168.88.1",
  username: "lsp",
  password: "changeme",
  hotlock: true,
};
let globalSettings: LspSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings = new Map<string, Promise<LspSettings>>();

// Cache highlights
const inspectHighlightCache = new Map<string, Promise<string[]>>();

// capabilities of the connected client
let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

// Initialize the server
connection.onInitialize((params: InitializeParams) => {
  // Check client capabilities
  const capabilities = params.capabilities;
  connection.console.log(
    `connection.onInitialize() CLIENT capabilities: ${JSON.stringify(capabilities, null, 2)}`
  );

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
        documentSelector: [
          { language: "routeros" },
          { language: "rsc" },
          { scheme: "file", pattern: "**∕*.rsc" },
          { language: "routeroslsp" },
        ],
      },
      completionProvider: {
        resolveProvider: true,
        triggerCharacters: [":", "=", "/", " "],
      },
      diagnosticProvider: {
        interFileDependencies: false,
        workspaceDiagnostics: false,
      },
      hoverProvider: true,
    },
  };

  // Support workspace folders (maybe?)
  if (hasWorkspaceFolderCapability) {
    result.capabilities.workspace = {
      workspaceFolders: {
        supported: true,
      },
    };
  }

  connection.console.log(
    `connection.onInitialize() SERVER capabilities:  ${JSON.stringify(
      result,
      null,
      2
    )}`
  );

  // Return capabilities to the client
  return result;
});

// After initialization, the server is ready to handle requests
connection.onInitialized(() => {
  connection.console.log(`=> onInitialized() connection fired.`);

  // TODO: should register config cap include an undefined?
  if (hasConfigurationCapability) {
    // Register for all configuration changes
    connection.client.register(DidChangeConfigurationNotification.type, {
      section: "routeroslsp",
    });
  }
  if (hasWorkspaceFolderCapability) {
    connection.workspace.onDidChangeWorkspaceFolders(
      (_event: WorkspaceFoldersChangeEvent) => {
        connection.console.log(
          `=> onDidChangeWorkspaceFolders() fired but unhandled for: ${_event}`
        );
      }
    );
  }
  connection.languages.semanticTokens.refresh();
});

connection.onDidChangeConfiguration((change: DidChangeConfigurationParams) => {
  // TODO: use property type for 'change' not any
  connection.console.log(
    `=> DidChangeConfiguration() fired: ${JSON.stringify(
      change.settings?.routeroslsp
    )}`
  );
  if (hasConfigurationCapability) {
    // Reset all cached document settings
    documentSettings.clear();
  } else {
    globalSettings = change.settings.routeroslsp || defaultSettings;
  }
});

// This handler provides the initial list of completion items
connection.onCompletion(async (params: CompletionParams) => {
  connection.console.log(
    `=> onCompletion() fired for '${params.context?.triggerCharacter}' (kind ${params.context?.triggerKind}) at line ${params.position.line} char ${params.position.character} uri ${params.textDocument.uri}`
  );

  const document = documents.get(params.textDocument.uri);
  if (!document) {
    connection.console.warn(
      `connection.onCompletion('${params.textDocument.uri}'), cannot return any completion.`
    );
    return [];
  }
  const settings = await getDocumentSettings(document.uri);
  const text = document.getText();
  const position = params.position;
  const offset = document.offsetAt(position);

  const completions: CompletionItem[] = [];

  const roscompletion = await fetchInspect(
    "completion",
    text.slice(0, offset),
    settings
  );

  if (roscompletion) {
    roscompletion.forEach((item: any, index: number) => {
      if (item.show === "true") {
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
    });
    connection.console.log(
      `<= onCompletion() finished: #completions ${completions.length} uri ${document.uri}`
    );
    return completions;
  } else {
    connection.console.log(
      `<= onCompletion() finished with no completions for ${document.uri}`
    );
    return completions;
  }
});

// This handler resolves additional information for the item selected in
// the completion list.
connection.onCompletionResolve((item: CompletionItem): CompletionItem => {
  /*if (item.data === 1) {
            item.detail = 'TypeScript details';
            item.documentation = 'TypeScript documentation';
        } else if (item.data === 2) {
            item.detail = 'JavaScript details';
            item.documentation = 'JavaScript documentation';
        }*/
  connection.console.log(
    `=> onCompletionResolve() fired but noop: data #${item.data} label '${item.label}' kind '${item.kind}' detail '${item.detail}' `
  );
  return item;
});

connection.onRequest(
  "textDocument/semanticTokens/full",
  async (params): Promise<SemanticTokens | null> => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      connection.console.warn(
        `semanticTokens/full does not have a document, returning no tokens: ${JSON.stringify(
          params
        )}`
      );
      return null; //{ data: [] };
    }
    if (!document.getText) {
      connection.console.error(
        `semanticTokens/full for (${params.textDocument.uri}) does not have getText()`
      );
      return null; //{ data: [] };
    }

    const builder = new SemanticTokensBuilder();
    const tokens = await getDocumentInspectHighlights(document);
    if (!tokens || tokens.length === 0) {
      connection.console.error(
        `semanticTokens.on() no highlights found: ${document.uri}`
      );
    } else {
      const ranges = getAllTokenRanges(tokens);
      connection.console.log(
        `semanticTokens.on() processing: #tokens ${tokens.length} #ranges ${ranges.length}`
      );
      ranges.forEach((range) => {
        if (range[0] !== "none") {
          const pos = document.positionAt(range[1]);
          builder.push(
            pos.line,
            pos.character,
            range[2] - range[1] + 1,
            tokenTypes.indexOf(range[0]),
            0
          );
        }
      });
    }
    return builder.build();
  }
);

connection.languages.diagnostics.on(
  async (params: DocumentDiagnosticParams) => {
    connection.console.log(
      `=> diagnostics.on() called for uri: ${params.textDocument.uri}`
    );

    const document = documents.get(params.textDocument.uri);
    if (document) {
      return {
        kind: DocumentDiagnosticReportKind.Full,
        items: await validateTextDocument(document),
      } satisfies DocumentDiagnosticReport;
    } else {
      // We don't know the document. We can either try to read it from disk
      // or we don't report problems for it.
      connection.console.warn(
        `diagnostics.on() got no document for ${params.textDocument.uri}.`
      );
      connection.window.showWarningMessage(
        `{$params.textDocument.uri} could not be checked`
      );
      // TODO: likely should report warning or error, instead of empty - there should be a document, i think...
      return {
        kind: DocumentDiagnosticReportKind.Full,
        items: [],
      } satisfies DocumentDiagnosticReport;
    }
  }
);

connection.onHover(
  async (params: TextDocumentPositionParams): Promise<Hover | null> => {
    const pos = params.position;
    const doc = documents.get(params.textDocument.uri);
    if (!doc) {
      connection.console.warn(
        `connection.onHover() does not have a document, returning no hover.`
      );
      return null;
    }
    const offset = doc.offsetAt(pos);

    const tokens = await getDocumentInspectHighlights(doc);
    if (tokens) {
      const groupRange = getTokenRangeFromOffset(tokens, offset);

      //const hoverInfo = `### <kbd>${tokens[offset]}</kbd>\n\`offset ${offset} line ${pos.line} char ${pos.character} grp ${groupRange}\``;
      const hoverInfo = `highlight: \`${tokens[offset]}\` (group ${groupRange})`
      connection.console.log(
        `connection.onHover(): offset ${offset} line ${pos.line} char ${pos.character} grp ${groupRange}`
      );
      return {
        contents: {
          kind: "markdown",
          value: hoverInfo,
        },
        range: {
          start: doc.positionAt(groupRange[0]),
          end: doc.positionAt(groupRange[1] + 1),
        },
      };
    } else {
      connection.console.warn(
        `connection.onHover() got tokens at line ${pos.line} char ${pos.character}`
      );
      return null;
    }
  }
);

// HELPERS

async function fetchInspect(
  request: string,
  text: any,
  settings: LspSettings
): Promise<any> {
  connection.console.log(
    `-> /console/inspect ${request.toUpperCase()} started`
  );

  try {
    const response = await axios.post(
      `${settings.baseUrl}/rest/console/inspect`,
      {
        request: request,
        input: text,
      },
      {
        withCredentials: true,
        auth: {
          username: settings.username || "lsp",
          password: settings.password || "changeme",
        },
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    const resp: any = response.data;
    connection.console.log(
      `<- /console/inspect ${request.toUpperCase()} got: #data ${resp.length}`
    );

    return resp;
  } catch (error: any) {
    // TODO: not sure how to handle these errors - they'd be fatal...
    let errorText: string;
    if (error) {
      errorText = `Error with /console/inspect ${request.toUpperCase()} got: ${error.message
        }`;
      connection.console.error(errorText);
      connection.window.showErrorMessage(errorText);
      if (error.response) {
        errorText = `Error with /console/inspect ${request.toUpperCase()} got: ${error.response.data
          }`;
        connection.console.error(errorText);
        connection.window.showErrorMessage(errorText);
      }
    } else {
      errorText = `Error with /console/inspect ${request.toUpperCase()} got: ${JSON.stringify(
        error,
        null,
        2
      )}`;
      connection.console.error(errorText);
      connection.window.showErrorMessage(errorText);
    }
  }
}

async function getDocumentSettings(resource: string): Promise<LspSettings> {
  connection.console.log(`getDocumentSettings() called for uri: ${resource}`);
  if (!hasConfigurationCapability) {
    return globalSettings;
  }
  let result = documentSettings.get(resource);
  if (!result) {
    result = connection.workspace.getConfiguration({
      scopeUri: resource,
      section: "routeroslsp",
    });
    documentSettings.set(resource, result);
  }
  return result;
}

async function getDocumentInspectHighlights(
  doc: TextDocument
): Promise<string[] | undefined | null> {
  const cached = await inspectHighlightCache.get(doc.uri);
  if (cached) {
    connection.console.log(
      `getDocumentInspectHighlights(${doc.uri}) got from CACHE #${cached.length}`
    );
    return cached;
  }
  const settings = await getDocumentSettings(doc.uri);
  if (!doc.getText)
    connection.console.error(
      `getDocumentInspectHighlights(${doc.uri}) document has not getText()`
    );
  const results = (
    await fetchInspect("highlight", doc.getText(), settings)
  )[0]?.highlight?.split(",");
  if (results) inspectHighlightCache.set(doc.uri, results);
  connection.console.log(
    `getDocumentInspectHighlights(${doc.uri}) got from ROUTER # ${results.length}`
  );
  return results;
}

async function validateTextDocument(
  textDocument: TextDocument
): Promise<Diagnostic[]> {
  connection.console.log(
    `validateTextDocument() with uri: ${textDocument.uri}`
  );
  const settings = await getDocumentSettings(textDocument.uri);
  const diagnostics: Diagnostic[] = [];

  const tokens = await getDocumentInspectHighlights(textDocument);
  if (!tokens || tokens.length === 0) {
    connection.console.error(
      `validateTextDocument() no highlights found: ${textDocument.uri}`
    );
    return diagnostics; // []
  }

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
            end: textDocument.positionAt(tokens.length),
          },
          message: `Invalid syntax found by "highlight"`,
          code: token,
          source: "routeroslsp",
        };
        diagnostics.push(diagnostic);
      }
    }
    lastToken = token;
    lastTokenPosition = textDocument.positionAt(index + 1);
  });

  // Limit the number of problems reported
  const maxProblems = settings.maxNumberOfProblems || 1000;
  const limitedDiagnostics = diagnostics.slice(0, maxProblems);

  connection.console.log(
    `validateTextDocument() completed.  Result: #errors ${limitedDiagnostics.length}`
  );
  return limitedDiagnostics;
}

const badTokenTypes = [
  "variable-undefined",
  "error",
  "obj-inactive",
  "syntax-obsolete",
  "syntax-old",
  "ambiguous",
];
const tokenTypes = [
  "none",
  "dir",
  "cmd",
  "arg",
  "varname-local",
  "variable-parameter",
  "variable-local",
  "syntax-val",
  "varname",
  "syntax-meta",
  "escaped",
  "variable-global",
  "comment",
  "obj-inactive",
  "syntax-obsolete",
  "variable-undefined",
  "ambiguous",
  "syntax-old",
  "error",
  "varname-global",
  "syntax-noterm",
];

function getTokenRangeFromOffset(arr: string[], index: number): number[] {
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

  connection.console.log(
    `findGroupRange() finished for index ${index} with #groups ${result.length}`
  );

  return result;
}

function getAllTokenRanges(arr: string[]): [string, number, number][] {
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

  connection.console.log(
    `findGroupRange() finished with #groups ${result.length}}`
  );
  return result;
}

documents.onDidClose((change: TextDocumentChangeEvent<TextDocument>) => {
  connection.console.log(
    `=> onDidClose() fired for ${change.document.uri}`
  );
  documentSettings.delete(change.document.uri);
  inspectHighlightCache.delete(change.document.uri);
});

documents.onDidChangeContent(async (change) => {
  connection.console.log(
    `=> onDidChangeContent(${change.document.uri}) updating... `
  );
  inspectHighlightCache.delete(change.document.uri);
  /*
  connection.sendDiagnostics({
    uri: change.document.uri,
    diagnostics: await validateTextDocument(change.document),
  });
  */
  getDocumentInspectHighlights(change.document)
  //connection.languages.diagnostics.refresh()
  connection.languages.semanticTokens.refresh()
});

documents.onDidOpen(async (change: TextDocumentChangeEvent<TextDocument>) => {
  connection.console.log(
    `=> onDidOpen() fired for ${change.document.uri}`
  );
  inspectHighlightCache.delete(change.document.uri);
  /*connection.sendDiagnostics({
    uri: change.document.uri,
    diagnostics: await validateTextDocument(change.document),
  });*/
  //connection.languages.diagnostics.refresh()
  connection.languages.semanticTokens.refresh()
});

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen();
