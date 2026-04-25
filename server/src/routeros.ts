import axios, { type AxiosInstance, type AxiosResponse, type InternalAxiosRequestConfig, isAxiosError } from 'axios'
import { getAmbientConnectionSettings, getConnectionUrl, log, type RouterConnectionSettings, sanitizeBaseUrl } from './shared'

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
	inspectCompletion: (input: string, path?: string) => Promise<CompletionInspectResponseItem[] | undefined>
	inspectHighlight: (input: string, path?: string) => Promise<HighlightInspectResponseItem[] | undefined>
}

/**
 * Normalized error that crosses the LSP protocol boundary.
 *
 * Axios errors have circular references, non-standard shapes, and internal fields
 * (config, request, response objects) that don't survive JSON-RPC serialization.
 * This type contains only the fields the client watchdog actually uses to produce
 * user-facing error messages (see watchdog.ts `getTextFromError`).
 *
 * All HTTP errors from RouterRestClient are converted to this shape before leaving
 * routeros.ts, so no Axios types leak into controller.ts or across the wire.
 */
export interface RouterOSClientError {
	code: string
	message: string
	status?: number
}

export type NodeHttpsAgentFactory = (checkCertificates: boolean) => object | undefined

// MARK: RouterRestClient

export class RouterRestClient implements RouterApiClientInterface {
	#abortOnDispose = new AbortController()
	#connectionSettings?: RouterConnectionSettings
	#httpClient: AxiosInstance | null = null

	/**
	 * Called on HTTP errors to let the owner clear caches.
	 * Set by LspController during startup — breaks the circular import
	 * that previously existed (routeros.ts imported controller.ts).
	 */
	static onHttpError: (() => void) | null = null

	/** Node-only HTTPS agent factory; web builds leave this unset because browsers enforce TLS. */
	static nodeHttpsAgentFactory: NodeHttpsAgentFactory | undefined

	static #default: RouterRestClient | undefined = undefined
	static get default() {
		if (RouterRestClient.#default) return RouterRestClient.#default
		RouterRestClient.#default = new RouterRestClient()
		return RouterRestClient.#default
	}

	static forConnection(connectionSettings: RouterConnectionSettings) {
		return new RouterRestClient(connectionSettings)
	}

	constructor(connectionSettings?: RouterConnectionSettings) {
		this.#connectionSettings = connectionSettings
	}

	dispose() {
		log.info(`<httpclient> {dispose} called`)
		this.#abortOnDispose.abort()
	}

	/**
	 * Axios instance with logging/error interceptors.
	 * Cached; rebuilt on config changes via `invalidateClient()`.
	 *
	 * The response error interceptor logs and fires onHttpError, then re-throws
	 * as a normalized RouterOSClientError. Callers that want graceful degradation
	 * (inspect/execute) catch and return empty results. Callers that want the error
	 * (getIdentity for watchdog) let it propagate.
	 */
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
		const settings = this.#connectionSettings || getAmbientConnectionSettings()
		const url = getConnectionUrl(false, settings)
		if (!url) log.error('ERROR <httpclient> HTTP client using invalid URL from Settings')
		else url.pathname += 'rest'
		const baseUrlString = url ? url.toString() : settings.baseUrl
		const httpsAgent = RouterRestClient.nodeHttpsAgentFactory?.(settings.checkCertificates)
		return axios.create({
			baseURL: baseUrlString,
			timeout: settings.apiTimeout * 1000,
			headers: { 'Content-Type': 'application/json' },
			withCredentials: true,
			httpsAgent,
			auth: {
				username: settings.username,
				password: settings.password,
			},
			signal: this.#abortOnDispose.signal,
		})
	}

	// MARK: Interceptors

	#onRequestSuccess(req: InternalAxiosRequestConfig) {
		log.debug(`<httpclient> |request| incoming ${req.url}`)
		return req
	}

	#onRequestError(error: unknown): never {
		const normalized = normalizeError(error)
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |req| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${sanitizeBaseUrl(error.config?.baseURL || '')}`)
		} else {
			log.error(`ERROR <httpclient> |req| error: ${normalized.code} ${normalized.message}`)
		}
		// Only fire cache-clearing callback for the ambient singleton — not for explicit forConnection() clients
		if (!this.#connectionSettings) RouterRestClient.onHttpError?.()
		throw normalized
	}

	#onResponseSuccess(resp: AxiosResponse) {
		log.info(`<httpclient> |response| success ${resp.config.url}`)
		return resp
	}

	/**
	 * Response error interceptor. Logs the error, fires the cache-clearing callback,
	 * then re-throws as a plain RouterOSClientError.
	 *
	 * Previously this returned `null`, which resolved the promise and caused all
	 * callers to silently get `undefined` data. Now callers must catch explicitly —
	 * the inspect/execute methods catch and return empty results (graceful degradation),
	 * while getIdentity lets the error propagate to the watchdog.
	 */
	#onResponseError(error: unknown): never {
		const normalized = normalizeError(error)
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |response| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${sanitizeBaseUrl(error.config?.baseURL || '')}`)
		} else {
			log.error(`ERROR <httpclient> |response| error: ${normalized.code} ${normalized.message}`)
		}
		// Only fire cache-clearing callback for the ambient singleton — not for explicit forConnection() clients
		if (!this.#connectionSettings) RouterRestClient.onHttpError?.()
		throw normalized
	}

	// MARK: API methods

	/**
	 * Execute a RouterOS script via REST. Returns the script output string,
	 * or undefined if the request fails (graceful degradation).
	 */
	async #execute(cmd: string, strict = false): Promise<string | undefined> {
		log.info(`<httpclient> _execute() called with ${cmd.length} chars`)
		try {
			const resp = await this.httpClient.post<WrappedExecuteResponse>('/execute', {
				'as-string': true,
				script: cmd,
			})
			return resp.data?.ret
		} catch (error) {
			if (strict) throw error
			return undefined
		}
	}

	/**
	 * Query /console/inspect. Returns the response array,
	 * or undefined if the request fails (graceful degradation).
	 * Errors are already logged and caches cleared by the interceptor.
	 */
	async #inspect<T>(request: string, input: string, path?: string, strict = false): Promise<T[] | undefined> {
		log.info(`<httpclient> _inspect(${request}) called, input len ${input.length}`)
		try {
			const resp = await this.httpClient.post<T[]>('/console/inspect', {
				request: request,
				input: input,
				path: path,
			})
			return resp.data
		} catch (error) {
			if (strict) throw error
			return undefined
		}
	}

	inspectHighlight = (input: string, path?: string) => {
		return this.#inspect<HighlightInspectResponseItem>('highlight', replaceNonAscii(input, '?'), path)
	}

	inspectHighlightStrict = (input: string, path?: string) => {
		return this.#inspect<HighlightInspectResponseItem>('highlight', replaceNonAscii(input, '?'), path, true) as Promise<HighlightInspectResponseItem[]>
	}

	inspectSyntax = (input: string, path?: string) => {
		return this.#inspect<SyntaxInspectResponseItem>('syntax', input, path)
	}

	inspectCompletion(input: string, path?: string) {
		return this.#inspect<CompletionInspectResponseItem>('completion', input, path)
	}

	inspectChild = (input: string, path?: string) => {
		return this.#inspect<ChildInspectResponseItem>('child', input, path)
	}

	exportConfig = (type?: RouterOSExportType) => {
		return this.#execute(`:export ${type || ''}`)
	}

	executeScript = (cmd: string) => {
		return this.#execute(cmd)
	}

	executeScriptStrict = (cmd: string) => {
		return this.#execute(cmd, true) as Promise<string | undefined>
	}

	scriptEnvironment = async () => {
		try {
			const resp = await this.httpClient.post('/system/script/environment/print', {})
			return resp?.data
		} catch {
			return undefined
		}
	}

	/**
	 * Get the router's identity name. Used by the watchdog for connection testing.
	 * Throws RouterOSClientError on failure — the watchdog needs the error details
	 * to show user-friendly messages (see watchdog.ts `getTextFromError`).
	 */
	getIdentity = async (): Promise<string> => {
		return (await this.httpClient.get('/system/identity', {}))?.data?.name
	}
}

// MARK: Error normalization

/**
 * Convert any error (typically AxiosError) into a plain RouterOSClientError.
 *
 * AxiosError objects contain circular references (config.headers → AxiosHeaders),
 * axios-internal fields, and the full request/response bodies. These don't serialize
 * across JSON-RPC and cause confusing behavior when the client tries to read `.code`
 * or `.status` from the deserialized object.
 *
 * This function extracts only the fields the client watchdog needs and produces a
 * plain object that survives JSON serialization cleanly.
 */
export function normalizeError(error: unknown): RouterOSClientError {
	if (isAxiosError(error)) {
		return {
			code: error.code || 'UNKNOWN',
			message: error.message,
			status: error.response?.status,
		}
	}
	if (error instanceof Error) {
		return {
			code: (error as Error & { code?: string }).code || error.name || 'UNKNOWN',
			message: error.message,
		}
	}
	return {
		code: 'UNKNOWN',
		message: String(error),
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
