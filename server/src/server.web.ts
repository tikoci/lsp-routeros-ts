/* ---------------------------------------------------------------------------------------------
*  Copyright (c) Microsoft Corporation. All rights reserved.
*  Licensed under the MIT License. See License.txt in the project root for license information.
*-------------------------------------------------------------------------------------------- */
import { createConnection, BrowserMessageReader, BrowserMessageWriter } from 'vscode-languageserver/browser'
import { LspController } from './controller'

console.log('RouterOS LSP server worker started')

const messageReader = new BrowserMessageReader(self)
const messageWriter = new BrowserMessageWriter(self)

const connection = createConnection(messageReader, messageWriter)
connection.console.info(`RouterOS LSP server connection to client created`)

LspController.start(connection)
connection.console.info(`RouterOS LSP server startup completed`)

connection.listen()
connection.console.info(`RouterOS LSP server is listening`)
