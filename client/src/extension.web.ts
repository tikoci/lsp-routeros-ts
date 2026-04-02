import { type Disposable, type ExtensionContext, Uri } from 'vscode'
import { LanguageClient } from 'vscode-languageclient/browser'
import { getLanguageClientOptions, getPackageInfo } from './client'
import { initializeCommands } from './commands'
import { initializeWatchdog } from './watchdog'

let client: LanguageClient | undefined
let worker: Worker | undefined
let watchdog: Disposable | undefined

console.log('RouterOS LSP extension load starting...')

// this method is called when vs code is activated
export async function activate(context: ExtensionContext) {
	console.log('RouterOS LSP activate() starting')

	const serverMain = Uri.joinPath(context.extensionUri, 'server/dist/server.web.js')
	console.info(`RouterOS LSP using server at ${serverMain.toString(true)}`)
	worker = new Worker(serverMain.toString(true))
	client = new LanguageClient(...getPackageInfo(context), getLanguageClientOptions(), worker)
	console.log('RouterOS LSP about to start()')

	await client.start()
	watchdog = initializeWatchdog(context, client, 3000)
	context.subscriptions.push(client, ...initializeCommands(context, client), watchdog)

	client.info('RouterOS LSP client start() returned, activate() done')
}

export async function deactivate(): Promise<void> {
	const activeClient = client
	const activeWorker = worker
	client = undefined
	worker = undefined

	watchdog?.dispose()
	watchdog = undefined

	if (!activeClient) {
		activeWorker?.terminate()
		return
	}

	activeClient.info('RouterOS LSP extension deactivate() calling stop()')
	try {
		await activeClient.stop()
	} finally {
		activeWorker?.terminate()
	}
}
