import {
  ExtensionContext,
} from 'vscode'

import {
  LanguageClient,
  TransportKind,
} from 'vscode-languageclient/node'
import { packageJsonInfo, getLanguageClientOptions } from './client'
import { initializeCommands } from './commands'
import { initializeWatchdog } from './watchdog'

let client: LanguageClient

console.info('RouterOS LSP extension load starting')

export function activate(context: ExtensionContext) {
  console.log('RouterOS LSP activate() starting')

  const serverModule = context.asAbsolutePath('./server/dist/server.js')

  client = new LanguageClient(
    ...packageJsonInfo(context),
    {
      run: { module: serverModule, transport: TransportKind.ipc },
      debug: {
        module: serverModule,
        transport: TransportKind.ipc,
      },
    },
    getLanguageClientOptions(),
  )

  context.subscriptions.push(
    client,
    ...initializeCommands(context, client),
    ...initializeWatchdog(context, client),
  )

  // Start the client. This will also launch the server
  client.start()

  console.log('RouterOS LSP client.start() called')
}

export function deactivate() {
  console.log('RouterOS LSP extension deactivate() invoked')
}
