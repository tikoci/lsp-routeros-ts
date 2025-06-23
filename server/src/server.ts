 
// Import from Microsoft's vscode-languageserver library
import {
  createConnection,
  ProposedFeatures,
} from "vscode-languageserver/node";

import { LspController } from './controller';

console.log('RouterOS LSP server worker started');

const connection = createConnection(ProposedFeatures.all);
connection.console.info(`RouterOS LSP server connection to client created`);

LspController.start(connection);
connection.console.info(`RouterOS LSP server startup completed`);

connection.listen();
connection.console.info(`RouterOS LSP server is listening`);


