// Import from Microsoft's vscode-languageserver library
import {
  createConnection,
  ProposedFeatures,
} from 'vscode-languageserver/node'

import { LspController } from './controller'
import { } from './shared'
import * as https from 'https'
const httpAllowAllAgent = new https.Agent({
  rejectUnauthorized: false,
})

console.log('RouterOS LSP server worker loaded')

const connection = createConnection(ProposedFeatures.all)
connection.console.info('RouterOS LSP server connection to client created')

LspController.start(connection, httpAllowAllAgent)
connection.console.info('RouterOS LSP server startup completed')

connection.listen()
connection.console.info('RouterOS LSP server is listening')
