 
// Import from Microsoft's vscode-languageserver library
import {
  createConnection,
  ProposedFeatures,
} from "vscode-languageserver/node";

import { startLspServer } from './shared';

const connection = createConnection(ProposedFeatures.all);
connection.console.info(`RouterOS LSP server connection to client created`);

startLspServer(connection);
connection.console.info(`RouterOS LSP server startup completed`);

connection.listen();
connection.console.info(`RouterOS LSP server is listening`);


