import { commands, ExtensionContext, window, workspace } from 'vscode'
import { Disposable, integer, State, type BaseLanguageClient } from 'vscode-languageclient'
// import { type LanguageClient } from 'vscode-languageclient/node'
// import { type BaseLanguageClient } from 'vscode-languageclient'

export function initializeWatchdog(context: ExtensionContext, client: BaseLanguageClient, testDelay: integer) {
  return new LspClientWatchdog(context, client, testDelay)
}

class LspClientWatchdog implements Disposable {
  context: ExtensionContext
  client: BaseLanguageClient
  disposables: Disposable[] = []
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

    this.disposables.push(commands.registerCommand('routeroslsp.cmd.testConnection', () => this.testCommandHandler()))
  }

  dispose() {
    this.disposables.forEach(e => e.dispose())
    clearTimeout(this.scheduledTest)
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
    }
    catch { this.client.warn('<client.com> [routeroslsp.cmd.testConnection] LSP server command failed while getting connection status') }

    if (!activeBaseUrl) {
      showErrorWithOptions(`RouterOS LSP 'Base Url' setting is wrong ${textUsingClientCredentials}`, isUsingClientCredentials)
      return
    }

    commands.executeCommand('routeroslsp.server.router.getIdentity').then(
      (identity) => {
        if (typeof identity === 'string') {
          commands.executeCommand('routeroslsp.server.getConnectionUrl')
            .then(
              connectionUrl =>
                commands.executeCommand('routeroslsp.server.isUsingClientCredentials').then(isUsingClientCredentials => window.showInformationMessage(`RouterOS LSP connected to '${identity}' ${isUsingClientCredentials ? 'using TikBook settings' : ''}: ${connectionUrl} `)),
              error => this.client.warn(`<client.cmd> [routeroslsp.cmd.testConnection]`, error))
          this.client.debug('<client.cmd> [routeroslsp.cmd.testConnection] success', identity)
        }
        else {
          const error = identity as (Error & { code?: string })
          this.client.error('ERROR <client.cmd> [routeroslsp.cmd.testConnection] identity is empty', undefined, false)
          const errMsg = this.getTextFromError(error, activeBaseUrl, isUsingClientCredentials) // `RouterOS LSP not working: ${error.code || ''} ${error.message ? error.message : error.name ? error.name : JSON.stringify(error)}`
          showErrorWithOptions(errMsg, isUsingClientCredentials)
        }
      },
      (error) => {
        {
          this.client.error('ERROR <client.cmd> [routeroslsp.cmd.testConnection] exception caught:', JSON.stringify(error), false)
          const errMsg = this.getTextFromError(error, activeBaseUrl, isUsingClientCredentials) // `RouterOS LSP exception raised: ${error.code || ''} ${error.message ? error.message : error.name ? error.name : JSON.stringify(error)}`
          showErrorWithOptions(errMsg, isUsingClientCredentials)
        }
      },
    )
  }

  getTextFromError(error, displayConnectionUrl, isUsingClientCredentials: boolean) {
    let errText = 'Router LSP not working: '
    if (isUsingClientCredentials) {
      errText = 'RouterOS LSP not working using TikBook credentials: '
    }
    if (error.code && error.message) {
      switch (error.code) {
        case 'ECONNABORTED': {
          errText += `No response, check Base Url '${displayConnectionUrl}' (${error.code} ${error.message})`
          break
        }
        case 'HOSTDOWN': {
          errText += `${error.code}, check Base Url '${displayConnectionUrl}' (${error.message})`
          break
        }
        case 'ECONNREFUSED': {
          errText += `Perhaps wrong port number or firewall blocking, check Base Url '${displayConnectionUrl}' (${error.message})`
          break
        }
        case 'ERR_TLS_CERT_ALTNAME_INVALID': {
          errText += `Perhaps disable 'Check Certificates' in Settings. (${error.message})`
          break
        }
        case 'ERR_BAD_REQUEST': {
          if (error.status) {
            switch (error.status) {
              case 401: {
                errText += `Username or password are wrong using ${displayConnectionUrl} (HTTP status ${error.status})`
                break
              }
              case 404: {
                errText += `Either hostname is wrong or an additional path is bad. ${displayConnectionUrl} (HTTP status ${error.status})`
                break
              }
              default:
                errText += `${error.message} ${displayConnectionUrl} (HTTP status ${error.status})`
                break
            }
            break
          }
        }
        default:
          errText += `${error.message} (${error.code})`
      }
    }
    else if (error.message) {
      errText += `${error.message} ${error.name ? `(${error.name})` : ''}`
    }
    else {
      errText += error.toString()
    }
    return errText
  }
}

function showErrorWithOptions(text, _isUsingClientCredentials: boolean) {
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
