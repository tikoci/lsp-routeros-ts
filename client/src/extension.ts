import type { ExtensionContext } from 'vscode'

import { LanguageClient, TransportKind } from 'vscode-languageclient/node'
import { getLanguageClientOptions, getPackageInfo } from './client'
import { initializeCommands } from './commands'
import { initializeWatchdog } from './watchdog'

let client: LanguageClient

console.info('RouterOS LSP extension load starting')

export async function activate(context: ExtensionContext) {
	console.log('RouterOS LSP client activate() starting')

	const serverModule = context.asAbsolutePath('./server/dist/server.js')

	client = new LanguageClient(
		...getPackageInfo(context),
		{
			run: { module: serverModule, transport: TransportKind.ipc },
			debug: {
				module: serverModule,
				transport: TransportKind.ipc,
			},
		},
		getLanguageClientOptions(),
	)

	await client.start()
	context.subscriptions.push(client, ...initializeCommands(context, client), initializeWatchdog(context, client, 3000))

	client.info('RouterOS LSP client start() returned, activate() done')
}

export function deactivate(): Thenable<void> | undefined {
	if (!client) {
		return undefined
	}
	client.info('RouterOS LSP extension deactivate() calling stop()')
	return client.stop()
}
