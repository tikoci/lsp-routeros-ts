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
  checkCertificates: boolean
}

export interface LspSettingsUpdate {
  baseUrl?: string // Base URL for the RouterOS API
  username?: string
  password?: string
  apiTimeout?: number
  checkCertificates?: boolean
}

export const defaultSettings: LspSettings = {
  baseUrl: 'http://192.168.88.1',
  username: 'lsp',
  password: 'changeme',
  apiTimeout: 15,
  allowClientProvidedCredentials: true,
  checkCertificates: false,
}

const routeroslspSettings: LspSettings = defaultSettings
let clientProvidedSettings: LspSettingsUpdate = {}

let _isUsingClientCredentials = false
export function isUsingClientCredentials() {
  if (routeroslspSettings.allowClientProvidedCredentials === false) return false
  return _isUsingClientCredentials
}

let _clientCredentialsProviderId: string | null = null
export function getClientCredentialsProviderId(): string | null {
  if (_isUsingClientCredentials && _clientCredentialsProviderId) return _clientCredentialsProviderId
  else return null
}

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
      checkCertificates: routeroslspSettings.checkCertificates,
    }
  }
  else {
    settings = routeroslspSettings
  }
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
  if (typeof newSettings.checkCertificates === 'boolean') {
    if (newSettings.checkCertificates !== routeroslspSettings.checkCertificates) {
      isDirty = true
      routeroslspSettings.checkCertificates = newSettings.checkCertificates
    }
  }
  const replacedSettings = getSettings()
  if (isDirty) log.info(`<settings> {update} now using ${replacedSettings.baseUrl} ${replacedSettings.username} ${replacedSettings.password ? '***' : 'null'} timeout ${replacedSettings.apiTimeout} allowClientProvidedCredentials ${replacedSettings.allowClientProvidedCredentials} checkCertificates ${replacedSettings.checkCertificates}`)
  return isDirty
}

export function getDisplayConnectionUrl(withUsername = true) {
  const url = getConnectionUrl(withUsername)
  if (url) {
    let userPart = ''
    if (withUsername) {
      userPart = `${url.username}@`
    }
    return `${url.protocol}//${userPart}${url.host}${url.pathname.substring(0, url.pathname.length - 1)}`
  }
  else return null
}

export function getConnectionUrl(withUsername = false): URL | null {
  const settings = getSettings()
  const url = URL.parse(settings.baseUrl)
  if (url) {
    if (withUsername) {
      url.username = settings.username
    }
    if (url.pathname[url.pathname.length - 1] !== '/') {
      url.pathname += '/'
    }
    return url
  }
  else {
    return null
  }
}

export function useConnectionUrl(e: ExecuteCommandParams): boolean {
  let isDirty = false
  if (getSettings().allowClientProvidedCredentials) {
    const newCredentials: LspSettingsUpdate = {}
    if (e.arguments) {
      // eslint-disable-next-line prefer-const
      let [extension, baseUrl, username, password, apiTimeout, checkCertificates] = e.arguments
      if (extension && baseUrl) {
        _clientCredentialsProviderId = extension
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
        if (checkCertificates && typeof checkCertificates === 'boolean') {
          newCredentials.checkCertificates = checkCertificates
          if (newCredentials.checkCertificates !== getSettings().checkCertificates) {
            isDirty = true
            log.info(`[useConnectionUrl] client provided apiTimeout: ${checkCertificates}`)
          }
        }
        clientProvidedSettings = newCredentials
      }
      else {
        log.error(`ERROR [useConnectionUrl] failed due to missing 'baseUrl', which is required in args`)
      }
    }
    else {
      log.error(`ERROR [useConnectionUrl] failed due to no args`)
    }
  }
  else {
    log.warn(`[useConnectionUrl] Use client credentials blocked by 'allowClientProvidedCredentials=false'`)
  }
  if (isDirty) _isUsingClientCredentials = true
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
    log.info('[clearConnectionUrl] removed client authentication cache')
    // LspController.default.connection.window.showInformationMessage(`<useConnectionUrl> use LSP settings: ${getSettings().baseUrl}`)
  }
  else {
    log.debug('[clearConnectionUrl] no client authentication to remove')
  }
  _isUsingClientCredentials = false
  return isDirty
}
