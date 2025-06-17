// Import from Microsoft's vscode-languageserver library
import {
  createConnection,
  ProposedFeatures,
  BrowserMessageWriter,
  BrowserMessageReader,
  TextDocuments,
} from "vscode-languageserver/browser";
import { start } from './common.js';
import { TextDocument } from "vscode-languageserver-textdocument";

const messageReader = new BrowserMessageReader(self as any);
const messageWriter = new BrowserMessageWriter(self as any);
const connection = createConnection(ProposedFeatures.all, messageReader, messageWriter);

const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);
connection.console.log(
  `created 'documents' cache: #keys ${documents.keys.length}`
);

connection.console.info(`RouterOS LSP loading...`);
start(connection, documents)

// Listen on the connection
connection.listen();
