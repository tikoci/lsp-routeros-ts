import axios, { type AxiosInstance, type AxiosResponse, type InternalAxiosRequestConfig, isAxiosError } from 'axios'
import { getConnectionUrl, getSettings, log } from './shared'

// MARK: Types

export interface WrappedExecuteResponse {
	ret: string
}

export interface InspectRequest {
	input?: string
	path?: string | string[]
	request: string
	'.proplist'?: string | string[] | null
	'.query'?: string[] | null
	'as-value'?: boolean | string | null
	'without-paging'?: boolean | string | null
}

export type InspectResponse = HighlightInspectResponseItem[] | SyntaxInspectResponseItem[] | CompletionInspectResponseItem[] | ChildInspectResponseItem[]

export interface HighlightInspectResponseItem {
	highlight: string
	type: string
}

export interface SyntaxInspectResponseItem {
	nested: number | string | undefined
	nonorm: boolean | string | undefined
	symbol: string | undefined
	'symbol-type': string | undefined
	text: string | undefined
	type: string
}

export type RouterOSExportType = 'compact' | 'verbose' | 'terse' | undefined

export interface CompletionInspectResponseItem {
	completion: string | undefined
	offset: number | string | undefined
	preference: number | string | undefined
	show: boolean | string | undefined
	style: number | string | undefined
	text: string | undefined
	type: string
}

export interface ChildInspectResponseItem {
	name: string
	'node-type': string
	type: string
}

interface RouterApiClientInterface {
	inspectCompletion: (input: string, path?: string) => Promise<CompletionInspectResponseItem[]>
	inspectHighlight: (input: string, path?: string) => Promise<HighlightInspectResponseItem[]>
}

// MARK: RouterRestClient

export class RouterRestClient implements RouterApiClientInterface {
	#abortOnDispose = new AbortController()
	#httpClient: AxiosInstance | null = null

	/**
	 * Called on HTTP errors to let the owner clear caches.
	 * Set by LspController during startup — breaks the circular import
	 * that previously existed (routeros.ts imported controller.ts).
	 */
	static onHttpError: (() => void) | null = null

	/** HTTPS agent for self-signed certs — injected from server.ts (Node only) */
	static nodeHttpsAllowAllAgent: object | undefined

	static #default: RouterRestClient | undefined = undefined
	static get default() {
		if (RouterRestClient.#default) return RouterRestClient.#default
		RouterRestClient.#default = new RouterRestClient()
		return RouterRestClient.#default
	}

	dispose() {
		log.info(`<httpclient> {dispose} called`)
		this.#abortOnDispose.abort()
	}

	/** Raw Axios instance without interceptors — used for getIdentityRaw (watchdog). */
	get rawHttpClient(): AxiosInstance {
		return this.#createAxiosInstance()
	}

	/** Axios instance with logging/error interceptors. Cached; rebuilt on config changes via `invalidateClient()`. */
	get httpClient(): AxiosInstance {
		if (!this.#httpClient) {
			this.#httpClient = this.#createAxiosInstance()
			this.#httpClient.interceptors.request.use(
				(req) => this.#onRequestSuccess(req),
				(error) => this.#onRequestError(error),
			)
			this.#httpClient.interceptors.response.use(
				(resp) => this.#onResponseSuccess(resp),
				(error) => this.#onResponseError(error),
			)
		}
		return this.#httpClient
	}

	/** Drop the cached httpClient so the next access rebuilds with fresh settings. */
	invalidateClient() {
		this.#httpClient = null
	}

	#createAxiosInstance(): AxiosInstance {
		const settings = getSettings()
		const url = getConnectionUrl(false)
		if (!url) log.error('ERROR <httpclient> HTTP client using invalid URL from Settings')
		else url.pathname += 'rest'
		const baseUrlString = url ? url.toString() : settings.baseUrl
		return axios.create({
			baseURL: baseUrlString,
			timeout: settings.apiTimeout * 1000,
			headers: { 'Content-Type': 'application/json' },
			withCredentials: true,
			httpsAgent: settings.checkCertificates ? undefined : RouterRestClient.nodeHttpsAllowAllAgent,
			auth: {
				username: settings.username,
				password: settings.password,
			},
			signal: this.#abortOnDispose.signal,
		})
	}

	#onRequestSuccess(req: InternalAxiosRequestConfig) {
		log.debug(`<httpclient> |request| incoming ${req.url}`)
		return req
	}

	#onRequestError(error: unknown) {
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |req| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${error.config?.baseURL} user ${error.config?.auth?.username}`)
		} else {
			log.error(`ERROR <httpclient> |req| error: ${JSON.stringify(error)}`)
		}
		RouterRestClient.onHttpError?.()
	}

	#onResponseSuccess(resp: AxiosResponse) {
		log.info(`<httpclient> |response| success ${resp.config.url}`)
		return resp
	}

	#onResponseError(error: unknown) {
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |response| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${error.config?.baseURL} user ${error.config?.auth?.username}`)
		} else {
			log.error(`ERROR <httpclient> |response| error: ${JSON.stringify(error)}`)
		}
		RouterRestClient.onHttpError?.()
		return null
	}

	// MARK: API methods

	async _execute(cmd: string) {
		log.info(`<httpclient> _execute() called with ${cmd.length} chars`)
		return await this.httpClient
			.post<WrappedExecuteResponse>('/execute', {
				'as-string': true,
				script: cmd,
			})
			.then((resp) => resp?.data?.ret)
	}

	async _inspect<T>(request: string, input: string, path?: string) {
		log.info(`<httpclient> _inspect(${request}) called, input len ${input.length}`)
		return await this.httpClient
			.post<T[]>('/console/inspect', {
				request: request,
				input: input,
				path: path,
			})
			.then((resp) => resp?.data)
	}

	inspectHighlight = (input: string, path?: string) => {
		return this._inspect<HighlightInspectResponseItem>('highlight', replaceNonAscii(input, '?'), path)
	}

	inspectSyntax = (input: string, path?: string) => {
		return this._inspect<SyntaxInspectResponseItem>('syntax', input, path)
	}

	inspectCompletion(input: string, path?: string) {
		return this._inspect<CompletionInspectResponseItem>('completion', input, path)
	}

	inspectChild = (input: string, path?: string) => {
		return this._inspect<ChildInspectResponseItem>('child', input, path)
	}

	exportConfig = (type?: RouterOSExportType) => {
		return this._execute(`:export ${type || ''}`)
	}

	scriptEnvironment = async () => {
		return this.httpClient.post('/system/script/environment/print', {}).then((resp) => resp?.data)
	}

	getIdentity = (): Promise<string> => {
		return this.httpClient.get('/system/identity', {}).then((resp) => resp?.data?.name)
	}

	getIdentityRaw = (): Promise<string> => {
		return this.rawHttpClient.get('/system/identity', {}).then((resp) => resp?.data?.name)
	}
}

// MARK: Text preprocessing

/**
 * Replace non-ASCII characters (code > 127) with a substitute character.
 * RouterOS uses Windows-1252 encoding; the LSP sends `?` for anything outside ASCII
 * to avoid encoding mismatches while preserving character positions.
 */
export function replaceNonAscii(text: string, replacement = '_'): string {
	let result = ''
	for (let i = 0; i < text.length; i++) {
		const charCode = text.charCodeAt(i)
		result += charCode >= 0 && charCode <= 127 ? text.charAt(i) : replacement
	}
	return result
}
