import type { Disposable, ExtensionContext } from 'vscode'

import { LanguageClient, TransportKind } from 'vscode-languageclient/node'
import { getLanguageClientOptions, getPackageInfo } from './client'
import { autoApplySemanticTokenColorsOnStartup, initializeCommands } from './commands'
import { initializeWatchdog } from './watchdog'

let client: LanguageClient | undefined
let watchdog: Disposable | undefined

export async function activate(context: ExtensionContext) {
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
	await autoApplySemanticTokenColorsOnStartup(context, client)
	watchdog = initializeWatchdog(context, client, 3000)
	context.subscriptions.push(client, ...initializeCommands(context, client), watchdog)

	client.info('RouterOS LSP client start() returned, activate() done')
}

export async function deactivate(): Promise<void> {
	const activeClient = client
	client = undefined

	watchdog?.dispose()
	watchdog = undefined

	if (!activeClient) return

	activeClient.info('RouterOS LSP extension deactivate() calling stop()')
	await activeClient.stop()
}
