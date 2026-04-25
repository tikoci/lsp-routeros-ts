import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process'
import { once } from 'node:events'
import { existsSync } from 'node:fs'
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http'
import { type AddressInfo } from 'node:net'
import { basename, resolve } from 'node:path'
import { setTimeout as delay } from 'node:timers/promises'
import { fileURLToPath } from 'node:url'

const moduleDir = fileURLToPath(new URL('.', import.meta.url))

interface SmokeTarget {
	label: string
	command: string
	args: string[]
}

interface JsonRpcMessage {
	jsonrpc: '2.0'
	id?: number | string
	method?: string
	params?: unknown
	result?: unknown
	error?: unknown
}

interface PendingRequest {
	resolve: (message: JsonRpcMessage) => void
	reject: (error: Error) => void
	timer: number | NodeJS.Timeout
}

const smokeDocumentText = '/ip address print\n'
const smokeDocumentUri = 'file:///routeroslsp-smoke.rsc'

async function main() {
	const targets = parseTargets(process.argv.slice(2))
	const mockRouter = createMockRouterServer()
	await new Promise<void>((resolveListen) => mockRouter.listen(0, '127.0.0.1', resolveListen))
	const address = mockRouter.address() as AddressInfo
	const baseUrl = `http://127.0.0.1:${address.port}`

	try {
		for (const target of targets) {
			await runSmokeTarget(target, baseUrl)
			console.log(`PASS stdio smoke: ${target.label}`)
		}
	} finally {
		mockRouter.close()
	}
}

function parseTargets(args: string[]): SmokeTarget[] {
	const targets: SmokeTarget[] = []
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]
		if (arg === '--node') {
			const serverPath = requireNextArg(args, ++i, '--node')
			targets.push({ label: `node:${basename(serverPath)}`, command: 'node', args: [serverPath, '--stdio'] })
		} else if (arg === '--standalone') {
			const serverPath = requireNextArg(args, ++i, '--standalone')
			targets.push({ label: `standalone:${basename(serverPath)}`, command: serverPath, args: ['--stdio'] })
		} else {
			throw new Error(`Unknown argument: ${arg}`)
		}
	}

	if (targets.length === 0) {
		targets.push(
			{ label: 'node:server.js', command: 'node', args: ['server/dist/server.js', '--stdio'] },
			{ label: 'standalone:lsp-routeros-server', command: './lsp-routeros-server', args: ['--stdio'] },
		)
	}

	for (const target of targets) {
		const executablePath = target.command === 'node' ? target.args[0] : target.command
		if (!existsSync(resolve(executablePath))) {
			throw new Error(`Smoke target is missing: ${executablePath}. Run bun run compile first.`)
		}
	}
	return targets
}

function requireNextArg(args: string[], index: number, flag: string): string {
	const value = args[index]
	if (!value) throw new Error(`${flag} requires a path argument`)
	return value
}

async function runSmokeTarget(target: SmokeTarget, baseUrl: string) {
	const child = spawn(target.command, target.args, {
		cwd: resolve(moduleDir, '../..'),
		stdio: ['pipe', 'pipe', 'pipe'],
		env: { ...process.env, ROUTEROSLSP_API_TIMEOUT: '1' },
	})
	const peer = new JsonRpcPeer(child, target.label)
	let stderr = ''
	child.stderr.on('data', (chunk: Buffer) => {
		stderr += chunk.toString('utf8')
	})

	try {
		const initialize = await peer.request('initialize', {
			processId: process.pid,
			rootUri: null,
			capabilities: {},
			initializationOptions: {
				routeroslsp: {
					baseUrl,
					username: 'admin',
					password: 'smoke-password',
					apiTimeout: 1,
					checkCertificates: false,
				},
			},
		})
		const capabilities = (initialize.result as { capabilities?: Record<string, unknown> }).capabilities
		assert(capabilities?.semanticTokensProvider, 'initialize response is missing semanticTokensProvider')
		assert(capabilities?.completionProvider, 'initialize response is missing completionProvider')
		assert(capabilities?.diagnosticProvider, 'initialize response is missing diagnosticProvider')

		peer.notify('initialized', {})
		peer.notify('textDocument/didOpen', {
			textDocument: {
				uri: smokeDocumentUri,
				languageId: 'routeros',
				version: 1,
				text: smokeDocumentText,
			},
		})

		const semanticTokens = await peer.request('textDocument/semanticTokens/full', {
			textDocument: { uri: smokeDocumentUri },
		})
		const semanticData = (semanticTokens.result as { data?: number[] }).data
		assert(Array.isArray(semanticData), 'semantic tokens response did not include a data array')
		assert(semanticData.length > 0, 'semantic tokens response was empty')

		const diagnostics = await peer.request('textDocument/diagnostic', {
			textDocument: { uri: smokeDocumentUri },
		})
		const diagnosticItems = (diagnostics.result as { items?: unknown[] }).items
		assert(Array.isArray(diagnosticItems), 'diagnostic response did not include items')
		assert(diagnosticItems.length === 0, 'smoke document should not produce diagnostics')

		const completions = await peer.request('textDocument/completion', {
			textDocument: { uri: smokeDocumentUri },
			position: { line: 0, character: 4 },
			context: { triggerKind: 1 },
		})
		const completionItems = completions.result as Array<{ label?: string }>
		assert(Array.isArray(completionItems), 'completion response was not an array')
		assert(completionItems.some((item) => item.label === 'address'), 'completion response did not include mocked address item')

		await peer.request('shutdown', null)
		peer.notify('exit', null)
		await Promise.race([once(child, 'exit'), delay(2000)])
	} finally {
		peer.dispose()
		if (!child.killed && child.exitCode === null) child.kill()
	}

	if (stderr.trim()) {
		console.warn(`stderr from ${target.label}:\n${stderr.trim()}`)
	}
}

class JsonRpcPeer {
	#child: ChildProcessWithoutNullStreams
	#label: string
	#buffer = Buffer.alloc(0)
	#nextId = 1
	#pending = new Map<number | string, PendingRequest>()
	#failed = false

	constructor(child: ChildProcessWithoutNullStreams, label: string) {
		this.#child = child
		this.#label = label
		child.stdout.on('data', (chunk: Buffer) => this.#onData(chunk))
		child.on('exit', (code, signal) => {
			if (this.#pending.size > 0) {
				this.#fail(new Error(`${this.#label} exited before responding (code=${code ?? 'null'}, signal=${signal ?? 'null'})`))
			}
		})
		child.on('error', (error) => this.#fail(error))
	}

	request(method: string, params: unknown): Promise<JsonRpcMessage> {
		const id = this.#nextId++
		return new Promise<JsonRpcMessage>((resolve, reject) => {
			const timer = setTimeout(() => {
				this.#pending.delete(id)
				reject(new Error(`${this.#label} timed out waiting for ${method}`))
			}, 5000)
			this.#pending.set(id, { resolve, reject, timer })
			this.#send({ jsonrpc: '2.0', id, method, params })
		})
	}

	notify(method: string, params: unknown) {
		this.#send({ jsonrpc: '2.0', method, params })
	}

	dispose() {
		for (const pending of this.#pending.values()) {
			clearTimeout(pending.timer)
		}
		this.#pending.clear()
	}

	#send(message: JsonRpcMessage) {
		const body = Buffer.from(JSON.stringify(message), 'utf8')
		this.#child.stdin.write(`Content-Length: ${body.byteLength}\r\n\r\n`)
		this.#child.stdin.write(body)
	}

	#onData(chunk: Buffer) {
		if (this.#failed) return
		this.#buffer = Buffer.concat([this.#buffer, chunk])
		while (this.#buffer.length > 0) {
			const headerEnd = this.#buffer.indexOf('\r\n\r\n')
			if (headerEnd < 0) {
				this.#assertCleanHeaderPrefix()
				return
			}

			const header = this.#buffer.subarray(0, headerEnd).toString('ascii')
			if (!header.toLowerCase().startsWith('content-length:')) {
				this.#fail(new Error(`${this.#label} wrote non-LSP bytes to stdout before a Content-Length header: ${JSON.stringify(header)}`))
				return
			}

			const lengthMatch = /content-length:\s*(\d+)/i.exec(header)
			if (!lengthMatch) {
				this.#fail(new Error(`${this.#label} wrote an invalid LSP header: ${JSON.stringify(header)}`))
				return
			}

			const contentLength = Number(lengthMatch[1])
			const bodyStart = headerEnd + 4
			const bodyEnd = bodyStart + contentLength
			if (this.#buffer.length < bodyEnd) return

			const rawBody = this.#buffer.subarray(bodyStart, bodyEnd).toString('utf8')
			this.#buffer = this.#buffer.subarray(bodyEnd)
			const message = JSON.parse(rawBody) as JsonRpcMessage
			this.#handleMessage(message)
		}
	}

	#assertCleanHeaderPrefix() {
		const text = this.#buffer.toString('utf8')
		const prefix = 'Content-Length:'
		if (text !== prefix.slice(0, text.length)) {
			this.#fail(new Error(`${this.#label} wrote non-LSP bytes to stdout: ${JSON.stringify(text)}`))
		}
	}

	#handleMessage(message: JsonRpcMessage) {
		if (message.id !== undefined && message.method) {
			this.#send({ jsonrpc: '2.0', id: message.id, result: null })
			return
		}

		if (message.id === undefined) return

		const pending = this.#pending.get(message.id)
		if (!pending) return
		this.#pending.delete(message.id)
		clearTimeout(pending.timer)
		if (message.error) {
			pending.reject(new Error(`${this.#label} returned JSON-RPC error for id ${message.id}: ${JSON.stringify(message.error)}`))
		} else {
			pending.resolve(message)
		}
	}

	#fail(error: Error) {
		this.#failed = true
		for (const [id, pending] of this.#pending) {
			clearTimeout(pending.timer)
			pending.reject(error)
			this.#pending.delete(id)
		}
	}
}

function createMockRouterServer() {
	return createServer(async (req, res) => {
		try {
			if (req.method === 'GET' && req.url === '/rest/system/identity') {
				writeJson(res, { name: 'routeroslsp-smoke' })
				return
			}

			if (req.method === 'POST' && req.url === '/rest/console/inspect') {
				const body = (await readJson(req)) as { request?: string; input?: string }
				if (body.request === 'highlight') {
					const input = body.input || ''
					writeJson(res, [{ type: 'highlight', highlight: highlightFor(input).join(',') }])
					return
				}
				if (body.request === 'completion') {
					writeJson(res, [
						{
							completion: 'address',
							offset: 4,
							preference: 1,
							show: 'true',
							style: 'dir',
							text: 'address',
							type: 'completion',
						},
					])
					return
				}
				writeJson(res, [])
				return
			}

			res.writeHead(404, { 'Content-Type': 'application/json' })
			res.end(JSON.stringify({ error: 'not found' }))
		} catch (error) {
			res.writeHead(500, { 'Content-Type': 'application/json' })
			res.end(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }))
		}
	})
}

async function readJson(req: IncomingMessage): Promise<unknown> {
	let body = ''
	for await (const chunk of req) {
		body += Buffer.isBuffer(chunk) ? chunk.toString('utf8') : String(chunk)
	}
	return body ? JSON.parse(body) : {}
}

function writeJson(res: ServerResponse, value: unknown) {
	res.writeHead(200, { 'Content-Type': 'application/json' })
	res.end(JSON.stringify(value))
}

function highlightFor(input: string): string[] {
	const tokens = Array<string>(input.length).fill('none')
	for (const match of input.matchAll(/\S+/g)) {
		const word = match[0]
		const start = match.index
		if (start === undefined) continue
		const token = word === 'print' ? 'cmd' : word.startsWith('/') || word === 'address' ? 'dir' : 'arg'
		for (let i = start; i < start + word.length; i++) {
			tokens[i] = token
		}
	}
	return tokens
}

function assert(condition: unknown, message: string): asserts condition {
	if (!condition) throw new Error(message)
}

main().catch((error) => {
	console.error(error instanceof Error ? error.message : error)
	process.exitCode = 1
})
