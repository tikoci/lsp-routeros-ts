import type { ExecuteCommandParams, RemoteConsole } from 'vscode-languageserver'

// MARK: Constants

/** RouterOS /console/inspect truncates input beyond this byte count */
export const ROUTEROS_API_MAX_BYTES = 32767

/** Delay before requesting semantic token refresh (ms) — gives RouterOS time to settle */
export const SEMANTIC_TOKEN_REFRESH_DELAY_MS = 7000

// MARK: Logging

// biome-ignore lint/complexity/noStaticOnlyClass: singleton pattern — console assigned at connection init, log getter used everywhere
export class ConnectionLogger {
	// biome-ignore lint/suspicious/noExplicitAny: RemoteConsole assigned at runtime, falls back to global console
	static console: any
	static get log(): RemoteConsole {
		return ConnectionLogger.console || console
	}
}

/**
 * Proxy-based log that always delegates to the current ConnectionLogger.console.
 * The previous `export const log = ConnectionLogger.log` captured the getter value
 * at import time (before the connection existed), so all logging went to `console`.
 */
export const log: RemoteConsole = new Proxy({} as RemoteConsole, {
	get(_, prop: string) {
		const target = ConnectionLogger.console || console
		const value = target[prop]
		return typeof value === 'function' ? value.bind(target) : value
	},
})

// MARK: Settings

export interface RouterConnectionSettings {
	baseUrl: string
	username: string
	password: string
	apiTimeout: number
	checkCertificates: boolean
}

export interface LspSettings extends RouterConnectionSettings {
	allowClientProvidedCredentials: boolean
}

export interface RouterConnectionSettingsUpdate {
	baseUrl?: string
	username?: string
	password?: string
	apiTimeout?: number
	checkCertificates?: boolean
}

export interface LspSettingsUpdate extends RouterConnectionSettingsUpdate {
	allowClientProvidedCredentials?: boolean
}

export const defaultSettings: LspSettings = {
	baseUrl: 'http://192.168.88.1',
	username: 'lsp',
	password: 'changeme',
	apiTimeout: 15,
	allowClientProvidedCredentials: true,
	checkCertificates: false,
}

const routeroslspSettings: LspSettings = { ...defaultSettings }
let clientProvidedSettings: RouterConnectionSettingsUpdate = {}

const stringFields = ['baseUrl', 'username', 'password'] as const
const numberFields = ['apiTimeout'] as const
const booleanFields = ['allowClientProvidedCredentials', 'checkCertificates'] as const

let _isUsingClientCredentials = false
export function isUsingClientCredentials() {
	if (routeroslspSettings.allowClientProvidedCredentials === false) return false
	return _isUsingClientCredentials
}

let _clientCredentialsProviderId: string | null = null
export function getClientCredentialsProviderId(): string | null {
	if (_isUsingClientCredentials && _clientCredentialsProviderId) return _clientCredentialsProviderId
	return null
}

export function getSettings(): LspSettings {
	if (routeroslspSettings.allowClientProvidedCredentials) {
		return {
			baseUrl: clientProvidedSettings.baseUrl || routeroslspSettings.baseUrl,
			username: clientProvidedSettings.username || routeroslspSettings.username,
			password: clientProvidedSettings.password || routeroslspSettings.password,
			apiTimeout: clientProvidedSettings.apiTimeout || routeroslspSettings.apiTimeout,
			checkCertificates: typeof clientProvidedSettings.checkCertificates === 'boolean' ? clientProvidedSettings.checkCertificates : routeroslspSettings.checkCertificates,
			allowClientProvidedCredentials: routeroslspSettings.allowClientProvidedCredentials,
		}
	}
	return routeroslspSettings
}

export function getAmbientConnectionSettings(): RouterConnectionSettings {
	const settings = getSettings()
	return {
		baseUrl: settings.baseUrl,
		username: settings.username,
		password: settings.password,
		apiTimeout: settings.apiTimeout,
		checkCertificates: settings.checkCertificates,
	}
}

export function updateSettings(newSettings: LspSettingsUpdate): boolean {
	let isDirty = false

	for (const key of stringFields) {
		const newVal = newSettings[key]
		if (typeof newVal === 'string' && newVal.length > 0 && newVal !== routeroslspSettings[key]) {
			;(routeroslspSettings as unknown as Record<string, unknown>)[key] = newVal
			isDirty = true
		}
	}
	for (const key of numberFields) {
		const newVal = newSettings[key]
		if (typeof newVal === 'number' && Number.isFinite(newVal) && newVal !== routeroslspSettings[key]) {
			;(routeroslspSettings as unknown as Record<string, unknown>)[key] = newVal
			isDirty = true
		}
	}

	// Boolean fields checked separately — `typeof` guard is different
	if (typeof newSettings.allowClientProvidedCredentials === 'boolean' && newSettings.allowClientProvidedCredentials !== routeroslspSettings.allowClientProvidedCredentials) {
		routeroslspSettings.allowClientProvidedCredentials = newSettings.allowClientProvidedCredentials
		isDirty = true
	}
	if (typeof newSettings.checkCertificates === 'boolean' && newSettings.checkCertificates !== routeroslspSettings.checkCertificates) {
		routeroslspSettings.checkCertificates = newSettings.checkCertificates
		isDirty = true
	}

	if (isDirty) {
		const s = getSettings()
		log.info(
			`<settings> {update} now using ${sanitizeBaseUrl(s.baseUrl)} auth ${s.password ? '***' : 'unset'} timeout ${s.apiTimeout} allowClientProvidedCredentials ${s.allowClientProvidedCredentials} checkCertificates ${s.checkCertificates}`,
		)
	}
	return isDirty
}

export function getEnvironmentSettings(env = getProcessEnv()): LspSettingsUpdate {
	if (!env) return {}

	const environmentSettings: LspSettingsUpdate = {}
	for (const key of stringFields) {
		const envValue = env[toEnvVariableName(`routeroslsp.${key}`)]
		if (typeof envValue === 'string' && envValue.length > 0) {
			environmentSettings[key] = envValue
		}
	}
	for (const key of numberFields) {
		const envValue = env[toEnvVariableName(`routeroslsp.${key}`)]
		if (typeof envValue === 'string' && envValue.length > 0) {
			const parsed = Number(envValue)
			if (Number.isFinite(parsed)) environmentSettings[key] = parsed
		}
	}
	for (const key of booleanFields) {
		const envValue = env[toEnvVariableName(`routeroslsp.${key}`)]
		if (typeof envValue === 'string' && envValue.length > 0) {
			const parsed = parseBooleanString(envValue)
			if (typeof parsed === 'boolean') {
				environmentSettings[key] = parsed
			}
		}
	}
	return environmentSettings
}

// MARK: Connection URL

export function getDisplayConnectionUrl(withUsername = true, settings = getAmbientConnectionSettings()): string | null {
	const url = getConnectionUrl(withUsername, settings)
	if (url) {
		const userPart = withUsername ? `${url.username}@` : ''
		return `${url.protocol}//${userPart}${url.host}${url.pathname.substring(0, url.pathname.length - 1)}`
	}
	return null
}

export function getConnectionUrl(withUsername = false, settings = getAmbientConnectionSettings()): URL | null {
	const url = URL.parse(settings.baseUrl)
	if (url?.protocol && url.host) {
		if (withUsername) {
			url.username = settings.username
			url.password = ''
		}
		if (url.pathname[url.pathname.length - 1] !== '/') {
			url.pathname += '/'
		}
		return url
	}
	return null
}

export function sanitizeBaseUrl(baseUrl: string): string {
	const url = URL.parse(baseUrl)
	if (!url?.protocol || !url.host) return baseUrl
	url.username = ''
	url.password = ''
	const path = url.pathname === '/' ? '' : url.pathname.replace(/\/$/, '')
	return `${url.protocol}//${url.host}${path}`
}

// MARK: Client-provided credentials

export function useConnectionUrl(e: ExecuteCommandParams): boolean {
	let isDirty = false
	if (!getSettings().allowClientProvidedCredentials) {
		log.warn(`[useConnectionUrl] Use client credentials blocked by 'allowClientProvidedCredentials=false'`)
		return false
	}
	if (!e.arguments) {
		log.error(`ERROR [useConnectionUrl] failed due to no args`)
		return false
	}

	let [extension, baseUrl, username, password, apiTimeout, checkCertificates] = e.arguments
	if (!extension || !baseUrl) {
		log.error(`ERROR [useConnectionUrl] failed due to missing 'baseUrl', which is required in args`)
		return false
	}

	_clientCredentialsProviderId = extension
	const newCredentials: LspSettingsUpdate = {}

	const url = URL.parse(baseUrl)
	if (url?.protocol && url.host) {
		baseUrl = `${url.protocol}//${url.host}`
		newCredentials.baseUrl = baseUrl
		if (newCredentials.baseUrl !== getSettings().baseUrl) {
			isDirty = true
			log.info(`[useConnectionUrl] client provided new baseURL for ${sanitizeBaseUrl(baseUrl)}`)
		}
	}
	if (url && !username && url.username) username = url.username
	if (url && !password && url.password) password = url.password

	if (username) {
		newCredentials.username = username
		if (newCredentials.username !== getSettings().username) {
			isDirty = true
			log.info('[useConnectionUrl] client provided updated username')
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
	if (typeof checkCertificates === 'boolean') {
		newCredentials.checkCertificates = checkCertificates
		if (newCredentials.checkCertificates !== getSettings().checkCertificates) {
			isDirty = true
			log.info(`[useConnectionUrl] client provided checkCertificates: ${checkCertificates}`)
		}
	}
	clientProvidedSettings = newCredentials

	if (isDirty) _isUsingClientCredentials = true
	return isDirty
}

export function clearConnectionUrl(): boolean {
	if (
		clientProvidedSettings.baseUrl ||
		clientProvidedSettings.username ||
		clientProvidedSettings.password ||
		clientProvidedSettings.apiTimeout ||
		typeof clientProvidedSettings.checkCertificates === 'boolean'
	) {
		clientProvidedSettings = {}
		_isUsingClientCredentials = false
		log.info('[clearConnectionUrl] removed client authentication cache')
		return true
	}
	log.debug('[clearConnectionUrl] no client authentication to remove')
	_isUsingClientCredentials = false
	return false
}

export function toEnvVariableName(settingName: string): string {
	const suffix = settingName.replace(/^routeroslsp\./, '')
	const normalized = suffix
		.replace(/([a-z0-9])([A-Z])/g, '$1_$2')
		.replace(/[^a-zA-Z0-9]+/g, '_')
		.toUpperCase()
	return `ROUTEROSLSP_${normalized}`
}

function parseBooleanString(value: string): boolean | undefined {
	switch (value.trim().toLowerCase()) {
		case '1':
		case 'true':
		case 'yes':
		case 'on':
			return true
		case '0':
		case 'false':
		case 'no':
		case 'off':
			return false
		default:
			return undefined
	}
}

function getProcessEnv(): Record<string, string | undefined> | undefined {
	if (typeof process === 'undefined' || !process?.env) return undefined
	return process.env as Record<string, string | undefined>
}
