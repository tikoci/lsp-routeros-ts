/** Immutable parse/highlight captures. Run only against a disposable CHR. */
import { randomUUID } from 'node:crypto'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, resolve } from 'node:path'
import {
	EVIDENCE_FORMAT,
	decodeSource,
	hash,
	prepareInput,
	trackedSourcePaths,
	type CaptureEnvironment,
	type CaptureObservation,
	type CaptureRun,
	type Probe,
} from './corpus-evidence'

const ROOT = resolve(import.meta.dir, '..')
const DATA = join(ROOT, 'test-data')

export async function collectCorpus(probes: Probe[] = ['parseil', 'highlight']): Promise<void> {
	const args = process.argv.slice(2)
	function option(name: string): string | null {
		const index = args.indexOf(name)
		if (index < 0) return null
		const value = args[index + 1]
		if (!value || value.startsWith('--')) throw new Error(`${name} requires a value`)
		return value
	}
	const target = option('--target')
	const limit = Number(option('--limit') ?? 0)
	if (!Number.isSafeInteger(limit) || limit < 0) throw new Error('--limit must be a nonnegative integer')
	const url = process.env.ROUTEROS_TEST_URL || 'http://127.0.0.1:9170'
	const auth = `Basic ${Buffer.from(`${process.env.ROUTEROS_TEST_USER || 'admin'}:${process.env.ROUTEROS_TEST_PASS || ''}`).toString('base64')}`
	async function rest(path: string, body?: unknown): Promise<unknown> {
		const response = await fetch(`${url}/rest${path}`, {
			method: body === undefined ? 'GET' : 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: auth },
			body: body === undefined ? undefined : JSON.stringify(body),
			signal: AbortSignal.timeout(120_000),
		})
		const text = await response.text()
		if (!response.ok) throw new Error(`${path}: HTTP ${response.status} ${response.statusText}: ${text}`)
		return JSON.parse(text)
	}
	const sessionId = randomUUID()
	const resource = (await rest('/system/resource')) as Record<string, string>
	const packages = (await rest('/system/package')) as Record<string, string>[]
	let deviceMode: unknown
	try {
		deviceMode = await rest('/system/device-mode')
	} catch (error) {
		deviceMode = { unknown: String(error) }
	}
	// Inventory is deliberately bounded and names its scope. Never extrapolate
	// absence of a nested command from the root response or an offline catalog.
	const paths = [...new Set(['', ...(option('--menus')?.split(';') ?? [])])].sort()
	const menuInventory: CaptureEnvironment['menuInventory'] = []
	for (const path of paths) {
		try {
			menuInventory.push({ path, response: await rest('/console/inspect', { request: 'child', path }), error: null })
		} catch (error) {
			menuInventory.push({ path, response: null, error: String(error) })
		}
	}
	const environment: CaptureEnvironment = {
		sessionId,
		version: resource.version?.split(/\s+/)[0] || 'unknown',
		buildTime: resource['build-time'] ?? null,
		architecture: resource['architecture-name'] ?? null,
		board: resource['board-name'] ?? null,
		packages: packages.map((pkg) => ({ name: pkg.name, version: pkg.version, disabled: pkg.disabled ?? null })).sort((a, b) => a.name.localeCompare(b.name)),
		deviceMode,
		menuInventory,
		menuInventorySha256: hash(JSON.stringify(menuInventory)),
		configuration: { scope: 'parse/highlight at root in one disposable-CHR session', unrecorded: ['object state', 'global variables', 'runtime execution'] },
	}
	let sources = trackedSourcePaths(ROOT)
	if (target) sources = sources.filter((path) => path.includes(target))
	if (limit) sources = sources.slice(0, limit)
	if (!sources.length) throw new Error('No tracked source scripts selected')
	// Freeze sources before either probe so concurrent source edits cannot mix inputs.
	const selected = sources.map((path) => ({
		path: path.slice('test-data/'.length),
		text: decodeSource(readFileSync(join(ROOT, path))),
	}))
	const sourceSetSha256 = hash(JSON.stringify(selected.map(({ path, text }) => [path, hash(text)])))
	const output = join(DATA, 'captures')
	mkdirSync(output, { recursive: true })
	console.log(`RouterOS ${environment.version}; session ${sessionId}; ${sources.length} sources`)
	for (const probe of probes) {
		const run: CaptureRun = {
			format: EVIDENCE_FORMAT,
			id: `${sessionId}-${probe}`,
			probe,
			capturedAt: new Date().toISOString(),
			environment,
			environmentSha256: hash(JSON.stringify(environment)),
			selection: { target, limit: limit || null, sourceSetSha256 },
			observations: [],
		}
		const probeFile = `corpus-${sessionId}.rsc`
		for (const { path, text } of selected) {
			const input = prepareInput(path, text, probe)
			const observation: CaptureObservation = {
				input,
				acquisition: 'failed',
				submission: 'requested',
				response: null,
				error: null,
				elapsedMs: 0,
				highlight: null,
			}
			const start = performance.now()
			try {
				if (probe === 'parseil') {
					await rest('/file/add', { name: probeFile, contents: input.submittedText })
					const stored = (await rest('/file/print', { '.proplist': '.id,size', '.query': [`name=${probeFile}`] })) as Array<{ '.id': string; size?: string }>
					if (stored.length !== 1) throw new Error('Uploaded file not uniquely found')
					const readback = (await rest('/file/get', { '.id': stored[0]['.id'], 'value-name': 'contents' })) as { ret?: string }
					if (!(input.submittedText === '' && stored[0].size === '0') && readback.ret !== input.submittedText)
						throw new Error('Uploaded input readback mismatch')
					observation.submission = 'file-readback-verified'
					observation.response = await rest('/execute', { script: `:put [:parse [/file/get ${probeFile} contents]]`, 'as-string': 'true' })
					const ret = (observation.response as { ret?: unknown }).ret
					if (typeof ret !== 'string') throw new Error('Missing string ret in parse response')
				} else {
					observation.response = await rest('/console/inspect', { request: 'highlight', input: input.submittedText, path: input.rootMenu })
					const rows = observation.response as Array<{ highlight?: unknown }>
					if (!Array.isArray(rows) || rows.length !== 1 || typeof rows[0].highlight !== 'string') throw new Error('Unexpected highlight response shape')
					const tokens = rows[0].highlight ? rows[0].highlight.split(',') : []
					const errorIndex = tokens.indexOf('error')
					observation.highlight = {
						tokenCount: tokens.length,
						aligned: tokens.length === input.submittedBytes,
						firstErrorByte: errorIndex < 0 ? null : errorIndex,
						types: [...new Set(tokens)].sort(),
					}
				}
				observation.acquisition = 'ok'
			} catch (error) {
				observation.error = String(error)
			} finally {
				if (probe === 'parseil') {
					// A unique name prevents overwriting an unrelated file. Cleanup
					// failures abort the run rather than accumulating files silently.
					const rows = (await rest('/file/print', { '.proplist': '.id', '.query': [`name=${probeFile}`] })) as Array<{ '.id': string }>
					for (const row of rows) await rest('/file/remove', { numbers: row['.id'] })
				}
			}
			observation.elapsedMs = Math.round(performance.now() - start)
			run.observations.push(observation)
			console.log(`${probe} ${run.observations.length}/${sources.length} ${observation.acquisition} ${path}`)
		}
		const destination = join(output, `${run.id}.json`)
		writeFileSync(destination, `${JSON.stringify(run, null, 2)}\n`, { flag: 'wx' })
		console.log(`Saved ${destination}; acquisition ok=${run.observations.filter((row) => row.acquisition === 'ok').length}; no runtime verdict`)
	}
}

if (import.meta.main) await collectCorpus()
