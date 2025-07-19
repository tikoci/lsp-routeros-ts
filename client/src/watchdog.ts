import { commands, ExtensionContext, workspace } from 'vscode'
import { Disposable, integer, State, type BaseLanguageClient } from 'vscode-languageclient'
// import { type LanguageClient } from 'vscode-languageclient/node'
// import { type BaseLanguageClient } from 'vscode-languageclient'

export function initializeWatchdog(context: ExtensionContext, client: BaseLanguageClient, testDelay: integer) {
  return new LspClientWatchdog(context, client, testDelay)
}

class LspClientWatchdog implements Disposable {
  context: ExtensionContext
  client: BaseLanguageClient
  scheduledTest

  constructor(context: ExtensionContext, client: BaseLanguageClient, testDelay: integer) {
    this.scheduledTest = setTimeout(() => this.test(), testDelay)
    this.context = context
    this.client = client

    this.client.onDidChangeState((e) => {
      if (e.newState === State.Running) {
        this.scheduledTest.refresh()
      }
      this.client.info(`<watchdog> LSP client state changed from ${State[e.oldState]} to ${State[e.newState]}`)
    })

    workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('routeroslsp')) {
        this.scheduledTest.refresh()
      }
    })
  }

  dispose() { }

  test() {
    this.client.debug('<client.watchdog> running [routeroslsp.cmd.testConnection]')
    commands.executeCommand('routeroslsp.cmd.testConnection')
  }
}
