import { commands, ExtensionContext } from 'vscode'
import { Disposable, State } from 'vscode-languageclient'
// import { type LanguageClient } from 'vscode-languageclient/node'
// import { type BaseLanguageClient } from 'vscode-languageclient'

export function initializeWatchdog(context: ExtensionContext, client) {
  return [new (class implements Disposable {
    timeout: 10
    context = context
    client = client
    dispose() { }
    test() {
      commands.executeCommand('routeroslsp.cmd.testConnection')
    }

    constructor() {
      this.client.onDidChangeState((e) => {
        if (e.newState === State.Running) {
          this.test()
        }
        this.client.warn(`<watchdog> LSP client state changed from ${State[e.oldState]} to ${State[e.newState]}`)
      })
      if (client.state === State.Running) {
        this.test()
      }
    }
  })()]
}
