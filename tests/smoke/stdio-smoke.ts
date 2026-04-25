import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process'
import { once } from 'node:events'
import { existsSync } from 'node:fs'
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http'
import { type AddressInfo } from 'node:net'
import { basename, resolve } from 'node:path'
import { setTimeout as delay } from 'node:timers/promises'
import { fileURLToPath } from 'node:url'

const moduleDir = fileURLToPath(new URL('.', import.meta.url))

const REQUEST_TIMEOUT_MS = 5000
const SHUTDOWN_GRACE_MS = 2000
const TEST_ROUTEROS_USERNAME = process.env.TEST_ROUTEROS_USERNAME ?? 'TEST_ADMIN'
const TEST_ROUTEROS_PASSWORD = process.env.TEST_ROUTEROS_PASSWORD ?? 'TEST_SMOKE_PASSWORD'
// Deliberately small: fast-fail any unintended external network call in the
// smoke tests, while still tolerating minor CI/JIT startup variability.
const ROUTEROS_LSP_API_TIMEOUT_MS = 10

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
	timer: NodeJS.Timeout
}

interface CompletionItemLike {
	label?: string
}

type HighlightToken = 'none' | 'cmd' | 'dir' | 'arg'

const smokeDocumentText = '/ip address print\n'
const smokeDocumentUri = 'file:///routeroslsp-smoke.rsc'

async function main() {
	const targets = parseTargets(process.argv.slice(2))
	const mockRouter = createMockRouterServer()
	await new Promise<void>((resolveListen) => mockRouter.listen(0, '127.0.0.1', resolveListen))
	const address = mockRouter.address()
	assert(isAddressInfo(address), 'mock router did not bind to a TCP address')
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

	const repoRoot = resolve(moduleDir, '../..')
	for (const target of targets) {
		const executablePath = target.command === 'node' ? target.args[0] : target.command
		if (!existsSync(resolve(repoRoot, executablePath))) {
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
		// ROUTEROSLSP_API_TIMEOUT bounds any HTTP call the server might make at the
		// transport layer ("fail fast"). It guards against the smoke test accidentally
		// talking to anything other than the in-process mock router on 127.0.0.1, even
		// before the LSP `initialize` settings have applied. The per-setting transport
		// is then exercised via initializationOptions below.
		//
		// 10ms (not 1ms) is chosen as a deliberate floor: still well under any real
		// network round-trip so a leaked external request fails immediately, but
		// generous enough that loaded CI runners or cold-start JIT compilation don't
		// cause false negatives against the in-process mock.
		env: { ...process.env, ROUTEROSLSP_API_TIMEOUT: String(ROUTEROS_LSP_API_TIMEOUT_MS) },
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
				// apiTimeout intentionally omitted — the env var above already pins it.
				// Re-adding it here would duplicate state without exercising new code paths.
				routeroslsp: {
					baseUrl,
					username: TEST_ROUTEROS_USERNAME,
					password: TEST_ROUTEROS_PASSWORD,
					checkCertificates: false,
				},
			},
		})
		const initializeResult = requireRecord(initialize.result, 'initialize response result was not an object')
		const capabilities = requireRecord(initializeResult.capabilities, 'initialize response is missing capabilities')
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
		const semanticTokensResult = requireRecord(semanticTokens.result, 'semantic tokens response result was not an object')
		const semanticData = semanticTokensResult.data
		assert(isNumberArray(semanticData), 'semantic tokens response did not include a numeric data array')
		assert(semanticData.length > 0, 'semantic tokens response was empty')

		const diagnostics = await peer.request('textDocument/diagnostic', {
			textDocument: { uri: smokeDocumentUri },
		})
		const diagnosticsResult = requireRecord(diagnostics.result, 'diagnostic response result was not an object')
		const diagnosticItems = diagnosticsResult.items
		assert(Array.isArray(diagnosticItems), 'diagnostic response did not include items')
		assert(diagnosticItems.length === 0, 'smoke document should not produce diagnostics')

		const completions = await peer.request('textDocument/completion', {
			textDocument: { uri: smokeDocumentUri },
			position: { line: 0, character: 4 },
			context: { triggerKind: 1 },
		})
		const completionResult = completions.result
		assert(Array.isArray(completionResult), 'completion response was not an array')
		const completionItems = completionResult.filter(isCompletionItemLike)
		assert(
			completionItems.length === completionResult.length,
			'completion response items had unexpected shape',
		)
		assert(completionItems.some((item) => item.label === 'address'), 'completion response did not include mocked address item')

		await peer.request('shutdown', null)
		peer.notify('exit', null)
		const exitOrTimeout = await Promise.race([
			once(child, 'exit').then(() => 'exit' as const),
			delay(SHUTDOWN_GRACE_MS).then(() => 'timeout' as const),
		])
		if (exitOrTimeout === 'timeout') {
			if (!child.killed && child.exitCode === null) child.kill()
			throw new Error(`${target.label} did not exit within ${SHUTDOWN_GRACE_MS}ms after shutdown/exit`)
		}
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
	#buffer: Buffer = Buffer.alloc(0)
	#nextId = 1
	#pending = new Map<number | string, PendingRequest>()
	#failed = false

	constructor(child: ChildProcessWithoutNullStreams, label: string) {
		this.#child = child
		this.#label = label
		child.stdout.on('data', (chunk: Buffer) => this.#onData(chunk))
		child.on('exit', (code, signal) => {
			if (!this.#failed && this.#pending.size > 0) {
				this.#fail(new Error(`${this.#label} exited before responding (code=${code ?? 'null'}, signal=${signal ?? 'null'})`))
			}
		})
		child.on('error', (error) => {
			if (!this.#failed) {
				this.#fail(error)
			}
		})
	}

	request(method: string, params: unknown): Promise<JsonRpcMessage> {
		const id = this.#nextId++
		return new Promise<JsonRpcMessage>((resolve, reject) => {
			const timer = setTimeout(() => {
				if (!this.#pending.delete(id)) return
				reject(new Error(`${this.#label} timed out waiting for ${method}`))
			}, REQUEST_TIMEOUT_MS)
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

		if (this.#buffer.length === 0) {
			this.#buffer = chunk
		} else {
			this.#buffer = Buffer.concat([this.#buffer, chunk])
		}

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
			const message: unknown = JSON.parse(rawBody)
			if (!isJsonRpcMessage(message)) {
				this.#fail(new Error(`${this.#label} wrote an invalid JSON-RPC message: ${rawBody}`))
				return
			}
			this.#handleMessage(message)
		}
	}

	// Called when the buffer holds bytes but no `\r\n\r\n` header terminator yet — i.e.
	// we're partway through reading the first LSP frame the server has emitted. Two
	// shapes are valid at this point (LSP header field names are case-insensitive per
	// the JSON-RPC base protocol spec):
	//
	//   1. A strict prefix of "Content-Length:" — e.g. "", "Content-", "content-length"
	//   2. The full "Content-Length:" header followed by an optional partial value:
	//      whitespace, digits, optional `\r`, optional `\n` — e.g. "Content-Length: 123\r\n"
	//
	// Anything else means the server wrote non-LSP bytes (a stray console.log, a stack
	// trace, etc.) to stdout before the first frame, which would corrupt the LSP stream.
	// Failing fast here surfaces packaging/transport regressions that unit tests miss.
	#assertCleanHeaderPrefix() {
		const text = this.#buffer.toString('utf8')
		const prefix = 'Content-Length:'
		const prefixLower = prefix.toLowerCase()
		const textLower = text.toLowerCase()

		// Case 1: still receiving the header name itself.
		if (this.#isPartialHeaderName(textLower, prefixLower)) return
		// Case 2: header name complete, partway through the value line.
		if (this.#isPartialContentLengthValue(text, textLower, prefix, prefixLower)) return

		this.#fail(new Error(`${this.#label} wrote non-LSP bytes to stdout: ${JSON.stringify(text)}`))
	}

	#isPartialHeaderName(textLower: string, prefixLower: string) {
		return textLower.length > 0 && textLower.length <= prefixLower.length && prefixLower.startsWith(textLower)
	}

	#isPartialContentLengthValue(text: string, textLower: string, prefix: string, prefixLower: string) {
		if (!textLower.startsWith(prefixLower)) return false
		// Value portion while streaming. Enumerate the valid intermediate states
		// rather than collapsing them into a single permissive regex — the previous
		// `/^[ \t]*\d*\r?\n?$/` accidentally matched `\r\n` with no digits, which
		// would correspond to an invalid `Content-Length: \r\n` line.
		// The no-terminator state intentionally allows whitespace with zero or more
		// digits while chunks are still arriving; once any line terminator appears,
		// at least one digit is required before it:
		//   - whitespace + optional digits, no terminator yet (chunk landed mid-value)
		//   - digits + `\r` only (waiting for `\n`)
		//   - digits + `\n` only (waiting for next header line / end-of-headers)
		//   - digits + `\r\n` complete (waiting for next header or end-of-headers)
		// This is stricter than the LSP spec (which allows extra header lines like
		// Content-Type) but matches what vscode-languageserver actually emits.
		const tail = text.slice(prefix.length)
		return (
			/^[ \t]*\d*$/.test(tail) ||
			/^[ \t]*\d+\r$/.test(tail) ||
			/^[ \t]*\d+\n$/.test(tail) ||
			/^[ \t]*\d+\r\n$/.test(tail)
		)
	}

	#handleMessage(message: JsonRpcMessage) {
		if (message.id !== undefined && message.method) {
			switch (message.method) {
				case 'window/workDoneProgress/create':
				case 'workspace/configuration':
					this.#send({ jsonrpc: '2.0', id: message.id, result: null })
					break
				default:
					this.#send({
						jsonrpc: '2.0',
						id: message.id,
						error: {
							code: -32601,
							message: `${this.#label} does not handle server request: ${message.method}`,
						},
					})
					break
			}
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
		if (this.#failed) return
		this.#failed = true
		for (const [id, pending] of this.#pending.entries()) {
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
				const body = requireRecord(await readJson(req), 'mock inspect request body was not an object')
				if (body.request === 'highlight') {
					const input = typeof body.input === 'string' ? body.input : ''
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
			console.error(error instanceof Error ? error.message : String(error))
			res.writeHead(500, { 'Content-Type': 'application/json' })
			res.end(JSON.stringify({ error: 'mock router request failed' }))
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

function highlightFor(input: string): HighlightToken[] {
	const chars = Array.from(input)
	const tokens = Array<HighlightToken>(chars.length).fill('none')

	// Map UTF-16 code unit offsets to Unicode character indices.
	const codeUnitToCharIndex: number[] = []
	let codeUnitOffset = 0
	for (let i = 0; i < chars.length; i++) {
		codeUnitToCharIndex[codeUnitOffset] = i
		codeUnitOffset += chars[i].length
	}
	codeUnitToCharIndex[codeUnitOffset] = chars.length

	for (const match of input.matchAll(/\S+/g)) {
		const word = match[0]
		const start = match.index
		if (start === undefined) continue

		let token: HighlightToken = 'arg'
		if (word === 'print') {
			token = 'cmd'
		} else if (word.startsWith('/') || word === 'address') {
			token = 'dir'
		}

		const startChar = codeUnitToCharIndex[start] ?? chars.length
		const endCodeUnit = start + word.length
		const endChar = codeUnitToCharIndex[endCodeUnit] ?? chars.length

		for (let i = startChar; i < endChar; i++) {
			tokens[i] = token
		}
	}
	return tokens
}

function requireRecord(value: unknown, message: string): Record<string, unknown> {
	assert(isRecord(value), message)
	return value
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isNumberArray(value: unknown): value is number[] {
	return Array.isArray(value) && value.every((item) => typeof item === 'number')
}

function isAddressInfo(value: unknown): value is AddressInfo {
	return (
		isRecord(value) &&
		typeof value.address === 'string' &&
		typeof value.family === 'string' &&
		typeof value.port === 'number'
	)
}

function isJsonRpcMessage(value: unknown): value is JsonRpcMessage {
	if (!isRecord(value) || value.jsonrpc !== '2.0') return false
	if (value.id !== undefined && typeof value.id !== 'number' && typeof value.id !== 'string') return false
	if (value.method !== undefined && typeof value.method !== 'string') return false
	return true
}

function isCompletionItemLike(value: unknown): value is CompletionItemLike {
	if (!isRecord(value)) return false
	const label = value.label
	return label === undefined || typeof label === 'string'
}

function assert(condition: unknown, message: string): asserts condition {
	if (!condition) throw new Error(message)
}

main().catch((error) => {
	console.error(error instanceof Error ? error.message : error)
	process.exitCode = 1
})
