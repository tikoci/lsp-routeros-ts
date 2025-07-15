import { ExecuteCommandParams, RemoteConsole } from 'vscode-languageserver'
import { } from './controller'

export class ConnectionLogger {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  static console: any
  // static trace : any;
  static get log(): RemoteConsole {
    return ConnectionLogger.console || console
  }
}

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
  allowClientProvidedCredentials?: boolean
}

export const defaultSettings: LspSettings = {
  baseUrl: 'http://192.168.88.1',
  username: 'lsp',
  password: 'changeme',
  apiTimeout: 15,
  allowClientProvidedCredentials: true,
}

let currentSettings = defaultSettings
const sessionSettings: LspSettingsUpdate = {}

export function updateSettings(newSettings: LspSettingsUpdate) {
  log.info(`<updateSettings> updating settings ${newSettings.baseUrl} ${newSettings.username} ${newSettings.password ? '***' : 'null'} ${newSettings.apiTimeout}`)
  currentSettings = { ...currentSettings, ...newSettings }
}

export function getSettings() {
  if (currentSettings.allowClientProvidedCredentials) {
    return { ...currentSettings, ...sessionSettings }
  }
  else {
    return currentSettings
  }
}

export function useConnectionUrl(e: ExecuteCommandParams) {
  if (!currentSettings.allowClientProvidedCredentials) {
    log.warn(`[useConnectionUrl] Updates will have no effect with 'allowClientProvidedCredentials=false'`)
  }
  log.debug(`[useConnectionUrl] starting with ${e.arguments?.length} arguments`)
  if (e.arguments) {
    let [baseUrl, username, password] = e.arguments
    if (baseUrl) {
      const url = URL.parse(baseUrl)
      if (url && url.protocol && url.host) {
        baseUrl = `${url.protocol}//${url.host}`
        sessionSettings.baseUrl = baseUrl
        if (sessionSettings.baseUrl === currentSettings.baseUrl) {
          log.debug(`[useConnectionUrl] client provided URL is same as current setting: ${url.protocol}//${url.host}`)
        }
        else {
          log.info(`[useConnectionUrl] client provided different baseURL for ${url.protocol}//${url.host}`)
        }
      }
      if (url && !username && url.username) username = url.username
      if (url && !password && url.password) password = url.password
      if (username) {
        sessionSettings.username = username
        if (sessionSettings.username != currentSettings.username) {
          log.info(`[useConnectionUrl] client provided username: ${username}`)
        }
        else {
          log.debug(`[useConnectionUrl] client provided username is same as current setting: ${username}`)
        }
      }
      if (password) {
        sessionSettings.password = password
        if (sessionSettings.password != currentSettings.password) {
          log.info(`[useConnectionUrl] client provided password`)
        }
      }
    }
  }
  else {
    log.warn(`[useConnectionUrl] failed due to missing 'baseUrl', which is required in args ['baseUrl', 'username', 'password'] (user/passwd are optional)`)
  }
}

export const log = ConnectionLogger.log
