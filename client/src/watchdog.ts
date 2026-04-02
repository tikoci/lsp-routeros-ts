import { commands, type ExtensionContext, window, workspace } from 'vscode'
import { type BaseLanguageClient, type Disposable, type integer, State } from 'vscode-languageclient'
import { getTextFromError as _getTextFromError, toErrorInfo } from './watchdog-errors'

export function initializeWatchdog(context: ExtensionContext, client: BaseLanguageClient, testDelay: integer) {
	return new LspClientWatchdog(context, client, testDelay)
}

class LspClientWatchdog implements Disposable {
	context: ExtensionContext
	client: BaseLanguageClient
	disposables: Disposable[] = []
	scheduledTest: ReturnType<typeof setTimeout> | null = null
	testDelay: integer
	#isDisposed = false

	constructor(context: ExtensionContext, client: BaseLanguageClient, testDelay: integer) {
		this.context = context
		this.client = client
		this.testDelay = testDelay
		this.scheduleTest()

		this.disposables.push(
			this.client.onDidChangeState((e) => {
				if (e.newState === State.Running) {
					this.scheduleTest()
				}
				this.client.info(`<watchdog> LSP client state changed from ${State[e.oldState]} to ${State[e.newState]}`)
			}),
		)

		this.disposables.push(
			workspace.onDidChangeConfiguration((e) => {
				if (e.affectsConfiguration('routeroslsp')) {
					this.scheduleTest()
				}
			}),
		)

		this.disposables.push(commands.registerCommand('routeroslsp.cmd.testConnection', () => this.testCommandHandler()))
	}

	scheduleTest() {
		if (this.scheduledTest) {
			clearTimeout(this.scheduledTest)
		}
		this.scheduledTest = setTimeout(() => {
			this.scheduledTest = null
			this.test()
		}, this.testDelay)
	}

	dispose() {
		if (this.#isDisposed) return
		this.#isDisposed = true

		this.disposables.forEach((e) => {
			e.dispose()
		})
		this.disposables = []

		if (this.scheduledTest) {
			clearTimeout(this.scheduledTest)
			this.scheduledTest = null
		}
	}

	test() {
		this.client.debug('<client.watchdog> running [routeroslsp.cmd.testConnection]')
		commands.executeCommand('routeroslsp.cmd.testConnection')
	}

	async testCommandHandler() {
		const baseUrl = workspace.getConfiguration('routeroslsp').get('baseUrl')
		let isUsingClientCredentials = false
		let textUsingClientCredentials = ''
		let activeBaseUrl = baseUrl
		try {
			isUsingClientCredentials = await commands.executeCommand('routeroslsp.server.isUsingClientCredentials')
			if (isUsingClientCredentials) textUsingClientCredentials = '(using TikBook credentials)'
			activeBaseUrl = await commands.executeCommand('routeroslsp.server.getConnectionUrl')
		} catch {
			this.client.warn('<client.com> [routeroslsp.cmd.testConnection] LSP server command failed while getting connection status')
		}

		if (!activeBaseUrl) {
			showErrorWithOptions(`RouterOS LSP 'Base Url' setting is wrong ${textUsingClientCredentials}`, isUsingClientCredentials)
			return
		}

		commands.executeCommand('routeroslsp.server.router.getIdentity').then(
			(identity) => {
				if (typeof identity === 'string') {
					commands.executeCommand('routeroslsp.server.getConnectionUrl').then(
						(connectionUrl) =>
							commands
								.executeCommand('routeroslsp.server.isUsingClientCredentials')
								.then((isUsingClientCredentials) =>
									window.showInformationMessage(`RouterOS LSP connected to '${identity}' ${isUsingClientCredentials ? 'using TikBook settings' : ''}: ${connectionUrl} `),
								),
						(error) => this.client.warn(`<client.cmd> [routeroslsp.cmd.testConnection]`, error),
					)
					this.client.debug('<client.cmd> [routeroslsp.cmd.testConnection] success', identity)
				} else {
					// identity is a RouterOSClientError {code, message, status?} from the server,
					// or undefined/null if something unexpected happened
					this.client.error('ERROR <client.cmd> [routeroslsp.cmd.testConnection] identity is empty', undefined, false)
					const error = toErrorInfo(identity)
					const errMsg = this.getTextFromError(error, activeBaseUrl as string, isUsingClientCredentials)
					showErrorWithOptions(errMsg, isUsingClientCredentials)
				}
			},
			(error) => {
				this.client.error('ERROR <client.cmd> [routeroslsp.cmd.testConnection] exception caught', undefined, false)
				const errMsg = this.getTextFromError(toErrorInfo(error), activeBaseUrl as string, isUsingClientCredentials)
				showErrorWithOptions(errMsg, isUsingClientCredentials)
			},
		)
	}

	getTextFromError(error: { code?: string; message?: string; name?: string; status?: number }, displayConnectionUrl: string | null, isUsingClientCredentials: boolean) {
		return _getTextFromError(error, displayConnectionUrl, isUsingClientCredentials)
	}
}

function showErrorWithOptions(text: string, _isUsingClientCredentials: boolean) {
	const buttons = ['Settings', 'Show Log', 'Retry', 'Close']
	window.showErrorMessage(text, ...buttons).then((button) => {
		if (button) {
			switch (button) {
				case 'LSP Settings':
				case 'Settings':
					commands.executeCommand('routeroslsp.cmd.settings.show')
					commands.executeCommand('routeroslsp.cmd.testConnection')
					break
				case 'TikBook Settings':
					commands.executeCommand('workbench.action.openSettings', '@ext:TIKOCI.tikbook')
					break
				case 'Show Log':
					commands.executeCommand('routeroslsp.cmd.outputs.show')
					commands.executeCommand('routeroslsp.cmd.testConnection')
					break
				case 'Retry':
					commands.executeCommand('routeroslsp.cmd.testConnection')
					break
				case 'Close':
					break
			}
		}
	})
}
