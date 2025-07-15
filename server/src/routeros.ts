import { LspController } from './controller'
import { getSettings, log } from './shared'

// const axios = require('axios').default;

// import { type InternalAxiosRequestConfig } from 'axios';
// import { default as axios } from 'axios';
// import { InternalAxiosRequestConfig } from 'axios';
import axios, { AxiosResponse, InternalAxiosRequestConfig, isAxiosError } from 'axios'

export interface WrappedExecuteResponse {
  ret: string
}
export type ExecuteResponse = string

export interface InspectRequest {
  'input'?: string | undefined
  'path'?: string | string[] | undefined
  'request': string
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
  'nested': number | string | undefined
  'nonorm': boolean | string | undefined
  'symbol': string | undefined
  'symbol-type': string | undefined
  'text': string | undefined
  'type': string
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
  'name': string
  'node-type': string
  'type': string
}

interface RouterApiClientInterface {
  inspectCompletion: (input: string, path?: string) => Promise<CompletionInspectResponseItem[]>
  inspectHighligh: (input: string, path?: string) => Promise<HighlightInspectResponseItem[]>
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

  constructor() {
  }

  public dispose() {
    log.info(`<RouterRestClient> {dispose} called`)
    this.#abortOnDispose.abort()
  }

  get rawHttpClient() {
    const settings = getSettings()
    return axios.create({
      baseURL: `${settings.baseUrl}/rest`,
      timeout: settings.apiTimeout * 1000, // in ms, settings uses seconds
      headers: { 'Content-Type': 'application/json' },
      withCredentials: true,
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
      req => this.pipelineRequestSuccess(req),
      error => this.pipelineRequestError(error))

    client.interceptors.response.use(
      resp => this.pipelineResponseSuccess(resp),
      error => this.pipelineResponseError(error),
    )
    return client
  }

  private pipelineRequestSuccess(req: InternalAxiosRequestConfig) {
    log.debug(`<RouterRestClient> |request| incoming ${req.url}`)
    return req
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private pipelineRequestError(error: any) {
    if (isAxiosError(error)) {
      log.warn(`ERROR <RouterRestClient> |req| ${error.config?.url} ${error.code} ${error.message}`)
    }
    // else {
    log.warn(`ERROR <RouterRestClient> |req| error: ${JSON.stringify(error)}`)
    // }
    LspController.default.lspDocuments.clear()
  }

  private pipelineResponseSuccess(resp: AxiosResponse) {
    log.info(`<RouterRestClient> |response| success ${resp.config.url}`)
    return resp
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private pipelineResponseError(error: any) {
    if (isAxiosError(error)) {
      log.warn(`ERROR <RouterRestClient> |response| ${error.config?.url} ${error.code} ${error.message}`)
    }
    else {
      log.warn(`ERROR <RouterRestClient> |response| error: ${JSON.stringify(error)}`)
    }
    LspController.default.lspDocuments.clear()
    return null
  }

  async _execute(cmd: string) {
    log.info(`<RouterRestClient> _execute() called with ${cmd.length} chars}`)
    return await this.httpClient.post<WrappedExecuteResponse>(
      '/execute', {
        'as-string': true,
        'script': cmd,
      }).then(resp => resp?.data?.ret)
  }

  // async execute(cmd: string, wrapperType: "json"|"csv"|"rest"|undefined){}
  async _inspect<T>(request: string, input: string, path?: string) {
    log.info(`<RouterRestClient> _inspect(${request}) called, input len ${input.length}`)
    return await this.httpClient.post<T[]>(
      '/console/inspect', {
        request: request,
        input: input,
        path: path,
      }).then(resp => resp?.data)
  }

  inspectHighligh = (input: string, path?: string) => {
    return this._inspect<HighlightInspectResponseItem>('highlight', (new RouterScriptPreprocessor(input)).unicodeCharReplace('?'), path)
  }

  inspectSyntax = (input: string, path?: string) => {
    return this._inspect<SyntaxInspectResponseItem>('syntax', input, path)
  }

  inspectCompletion(input: string, path?: string) {
    return this._inspect<CompletionInspectResponseItem>('completion', input, path)
  };

  inspectChild = (input: string, path?: string) => {
    return this._inspect<ChildInspectResponseItem>('child', input, path)
  }

  exportConfig = (type?: RouterOSExportType) => {
    return this._execute(`:export ${type || ''}`)
  }

  scriptEnvironment = async () => {
    return this.httpClient.post('/system/script/environment/print', {}).then(resp => resp?.data)
  }

  getIdentity = (): Promise<RouterIdentityResponse> => {
    return this.httpClient.get('/system/identity', {}).then(resp => resp?.data?.name)
  }

  getIdentityRaw = (): Promise<RouterIdentityResponse> => {
    return this.rawHttpClient.get('/system/identity', {}).then(resp => resp?.data?.name)
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
      }
      else {
        result += replace
      }
    }
    return result
  }

  constructor(text: string) {
    this.text = text
  }
}
