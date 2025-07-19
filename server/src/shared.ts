import { ExecuteCommandParams, RemoteConsole } from 'vscode-languageserver'

export class ConnectionLogger {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  static console: any
  static get log(): RemoteConsole {
    return ConnectionLogger.console || console
  }
}

export const log = ConnectionLogger.log

export interface LspSettings {
  baseUrl: string // Base URL for the RouterOS API
  username: string
  password: string
  apiTimeout: number
  allowClientProvidedCredentials: boolean
}

export interface LspSettingsUpdate {
  baseUrl?: string // Base URL for the RouterOS API
  username?: string
  password?: string
  apiTimeout?: number
}

export const defaultSettings: LspSettings = {
  baseUrl: 'http://192.168.88.1',
  username: 'lsp',
  password: 'changeme',
  apiTimeout: 15,
  allowClientProvidedCredentials: true,
}

const routeroslspSettings: LspSettings = defaultSettings
let clientProvidedSettings: LspSettingsUpdate = {}

export function getSettings() {
  let settings: LspSettings
  if (routeroslspSettings.allowClientProvidedCredentials) {
    // settings = { ...routeroslspSettings, ...clientProvidedSettings }
    settings = {
      baseUrl: clientProvidedSettings.baseUrl || routeroslspSettings.baseUrl,
      username: clientProvidedSettings.username || routeroslspSettings.username,
      password: clientProvidedSettings.password || routeroslspSettings.password,
      apiTimeout: clientProvidedSettings.apiTimeout || routeroslspSettings.apiTimeout,
      allowClientProvidedCredentials: routeroslspSettings.allowClientProvidedCredentials,
    }
  }
  else {
    settings = routeroslspSettings
  }
  // log.debug(`${JSON.stringify(settings)}`)
  return settings
}

export function updateSettings(newSettings: LspSettings) {
  let isDirty = false
  if (newSettings.baseUrl && typeof newSettings.baseUrl === 'string') {
    if (newSettings.baseUrl !== routeroslspSettings.baseUrl) {
      isDirty = true
      routeroslspSettings.baseUrl = newSettings.baseUrl
    }
  }
  if (newSettings.username && typeof newSettings.username === 'string') {
    if (newSettings.username !== routeroslspSettings.username) {
      isDirty = true
      routeroslspSettings.username = newSettings.username
    }
  }
  if (newSettings.password && typeof newSettings.password === 'string') {
    if (newSettings.password !== routeroslspSettings.password) {
      isDirty = true
      routeroslspSettings.password = newSettings.password
    }
  }
  if (newSettings.apiTimeout && typeof newSettings.apiTimeout === 'number') {
    if (newSettings.apiTimeout !== routeroslspSettings.apiTimeout) {
      isDirty = true
      routeroslspSettings.apiTimeout = newSettings.apiTimeout
    }
  }
  if (typeof newSettings.allowClientProvidedCredentials === 'boolean') {
    if (newSettings.allowClientProvidedCredentials !== routeroslspSettings.allowClientProvidedCredentials) {
      isDirty = true
      routeroslspSettings.allowClientProvidedCredentials = newSettings.allowClientProvidedCredentials
    }
  }
  const replacedSettings = getSettings()
  if (isDirty) log.info(`<updateSettings> now using ${replacedSettings.baseUrl} ${replacedSettings.username} ${replacedSettings.password ? '***' : 'null'} timeout ${replacedSettings.apiTimeout} allowClientProvidedCredentials ${replacedSettings.allowClientProvidedCredentials}`)
  return isDirty
}

export function useConnectionUrl(e: ExecuteCommandParams): boolean {
  let isDirty = false
  if (getSettings().allowClientProvidedCredentials) {
    const newCredentials: LspSettingsUpdate = {}
    log.debug(`[useConnectionUrl] starting with ${e.arguments?.length} arguments`)
    if (e.arguments) {
      // eslint-disable-next-line prefer-const
      let [baseUrl, username, password, apiTimeout] = e.arguments
      if (baseUrl) {
        const url = URL.parse(baseUrl)
        if (url && url.protocol && url.host) {
          baseUrl = `${url.protocol}//${url.host}`
          newCredentials.baseUrl = baseUrl
          if (newCredentials.baseUrl !== getSettings().baseUrl) {
            isDirty = true
            log.info(`[useConnectionUrl] client provided new baseURL for ${url.protocol}//${url.host}`)
          }
        }
        if (url && !username && url.username) username = url.username
        if (url && !password && url.password) password = url.password
        if (username) {
          newCredentials.username = username
          if (newCredentials.username !== getSettings().username) {
            isDirty = true
            log.info(`[useConnectionUrl] client provided new username: ${username}`)
          }
        }
        if (password) {
          newCredentials.password = password
          if (newCredentials.password !== getSettings().password) {
            isDirty = true
            log.info(`[useConnectionUrl] client provided new password: ***`)
          }
        }
        if (apiTimeout && typeof apiTimeout === 'number') {
          newCredentials.apiTimeout = apiTimeout
          if (newCredentials.apiTimeout !== getSettings().apiTimeout) {
            isDirty = true
            log.info(`[useConnectionUrl] client provided apiTimeout: ${apiTimeout}`)
          }
        }
        clientProvidedSettings = newCredentials
      }
      else {
        log.warn(`[useConnectionUrl] failed due to missing 'baseUrl', which is required in args`)
      }
    }
    else {
      log.warn(`[useConnectionUrl] failed due to no args`)
    }
  }
  else {
    log.warn(`[useConnectionUrl] Use client credentials blocked by 'allowClientProvidedCredentials=false'`)
  }
  return isDirty
}

export function clearConnectionUrl() {
  let isDirty = false
  if ((clientProvidedSettings.baseUrl)
    || (clientProvidedSettings.username)
    || (clientProvidedSettings.password)
    || (clientProvidedSettings.apiTimeout)) {
    delete clientProvidedSettings.baseUrl
    delete clientProvidedSettings.username
    delete clientProvidedSettings.password
    delete clientProvidedSettings.apiTimeout
    isDirty = true
    log.info('<useConnectionUrl> removed client authentication cache')
    // LspController.default.connection.window.showInformationMessage(`<useConnectionUrl> use LSP settings: ${getSettings().baseUrl}`)
  }
  else {
    log.debug('<useConnectionUrl> no client authentication to remove')
  }
  return isDirty
}
