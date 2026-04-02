import { type ExtensionContext, Uri } from 'vscode'
import { LanguageClient } from 'vscode-languageclient/browser'
import { getLanguageClientOptions, getPackageInfo } from './client'
import { initializeCommands } from './commands'
import { initializeWatchdog } from './watchdog'

let client: LanguageClient

console.log('RouterOS LSP extension load starting...')

// this method is called when vs code is activated
export async function activate(context: ExtensionContext) {
	console.log('RouterOS LSP activate() starting')

	const serverMain = Uri.joinPath(context.extensionUri, 'server/dist/server.web.js')
	console.info(`RouterOS LSP using server at ${serverMain.toString(true)}`)
	const worker = new Worker(serverMain.toString(true))
	client = new LanguageClient(...getPackageInfo(context), getLanguageClientOptions(), worker)
	console.log('RouterOS LSP about to start()')

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
