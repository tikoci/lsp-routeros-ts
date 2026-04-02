import axios, { type AxiosResponse, type InternalAxiosRequestConfig, isAxiosError } from 'axios'
import { LspController } from './controller'
import { getConnectionUrl, getSettings, log } from './shared'

export interface WrappedExecuteResponse {
	ret: string
}
export type ExecuteResponse = string

export interface InspectRequest {
	input?: string | undefined
	path?: string | string[] | undefined
	request: string
	// not useful but present
	'.proplist'?: string | string[] | undefined | null
	'.query'?: string[] | undefined | null
	'as-value'?: boolean | string | undefined | null
	'without-paging'?: boolean | string | undefined | null
}

export type InspectResponse = HighlightInspectResponseItem[] | SyntaxInspectResponseItem[] | CompletionInspectResponseItem[] | ChildInspectResponseItem[]

export interface HighlightInspectResponseItem {
	highlight: string
	type: string
}

export type HighlightInspectResults = string[]

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

interface RouterIdentityResponse {
	name: string
}

export class RouterRestClient implements RouterApiClientInterface {
	#abortOnDispose = new AbortController()

	static #default: RouterRestClient | undefined = undefined
	static get default() {
		if (RouterRestClient.#default) return RouterRestClient.#default
		else {
			RouterRestClient.#default = new RouterRestClient()
			return RouterRestClient.#default
		}
	}

	public dispose() {
		log.info(`<httpclient> {dispose} called`)
		this.#abortOnDispose.abort()
	}

	get rawHttpClient() {
		const settings = getSettings()
		const url = getConnectionUrl(false)
		if (!url) log.error('ERROR <httpclient> {rawHttpClient} HTTP client using invalid URL from Settings')
		else url.pathname += 'rest'
		const baseUrlString = url ? url.toString() : settings.baseUrl
		return axios.create({
			baseURL: baseUrlString,
			timeout: settings.apiTimeout * 1000, // in ms, settings uses seconds
			headers: { 'Content-Type': 'application/json' },
			withCredentials: true,
			httpsAgent: settings.checkCertificates ? undefined : LspController.nodeHttpsAllowAllAgent,
			auth: {
				username: settings.username,
				password: settings.password,
			},
			signal: this.#abortOnDispose.signal,
		})
	}

	get httpClient() {
		const client = this.rawHttpClient
		client.interceptors.request.use(
			(req) => this.pipelineRequestSuccess(req),
			(error) => this.pipelineRequestError(error),
		)

		client.interceptors.response.use(
			(resp) => this.pipelineResponseSuccess(resp),
			(error) => this.pipelineResponseError(error),
		)
		return client
	}

	private pipelineRequestSuccess(req: InternalAxiosRequestConfig) {
		log.debug(`<httpclient> |request| incoming ${req.url}`)
		return req
	}

	private pipelineRequestError(error: unknown) {
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |req| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${error.config?.baseURL} user ${error.config?.auth?.username}`)
		} else {
			log.error(`ERROR <httpclient> |req| error: ${JSON.stringify(error)}`)
		}
		LspController.default.lspDocuments.clear()
	}

	private pipelineResponseSuccess(resp: AxiosResponse) {
		log.info(`<httpclient> |response| success ${resp.config.url}`)
		return resp
	}

	private pipelineResponseError(error: unknown) {
		if (isAxiosError(error)) {
			log.error(`ERROR <httpclient> |response| ${error.config?.url} ${error.code} '${error.message}' baseUrl ${error.config?.baseURL} user ${error.config?.auth?.username}`)
		} else {
			log.error(`ERROR <httpclient> |response| error: ${JSON.stringify(error)}`)
		}
		LspController.default.lspDocuments.clear()
		return null
	}

	async _execute(cmd: string) {
		log.info(`<httpclient> _execute() called with ${cmd.length} chars}`)
		return await this.httpClient
			.post<WrappedExecuteResponse>('/execute', {
				'as-string': true,
				script: cmd,
			})
			.then((resp) => resp?.data?.ret)
	}

	// async execute(cmd: string, wrapperType: "json"|"csv"|"rest"|undefined){}
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
		return this._inspect<HighlightInspectResponseItem>('highlight', new RouterScriptPreprocessor(input).unicodeCharReplace('?'), path)
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

	getIdentity = (): Promise<RouterIdentityResponse> => {
		return this.httpClient.get('/system/identity', {}).then((resp) => resp?.data?.name)
	}

	getIdentityRaw = (): Promise<RouterIdentityResponse> => {
		return this.rawHttpClient.get('/system/identity', {}).then((resp) => resp?.data?.name)
	}
}

export class RouterScriptPreprocessor {
	text = ''

	unicodeCharReplace(replace = '_'): string {
		let result = ''
		for (let i = 0; i < this.text.length; i++) {
			const charCode = this.text.charCodeAt(i)
			if (charCode >= 0 && charCode <= 127) {
				result += this.text.charAt(i)
			} else {
				result += replace
			}
		}
		return result
	}

	constructor(text: string) {
		this.text = text
	}
}
