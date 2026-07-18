/**
 * Highlight collection harness — runs `/console/inspect request=highlight`
 * against every .rsc in test-data/ and records the observed token vocabulary.
 *
 * Usage:   bun run scripts/collect-highlight.ts [--limit N] [--target subpath]
 * Env:     ROUTEROS_TEST_URL, ROUTEROS_TEST_USER, ROUTEROS_TEST_PASS
 *
 * Why this file exists: the parseIL spike captured `:parse` IL for the whole
 * corpus, but highlight was only ever snapshotted for 6 representative files —
 * so the token vocabulary in `server/src/tokens.ts` had never been checked
 * against the full corpus on a current RouterOS. This harness grounds
 * `docs/highlight-format.md`: it tallies every token class seen across the
 * corpus, flags any class unknown to tokens.ts, and runs targeted probes for
 * rare classes the corpus does not naturally elicit (undefined variables,
 * unterminated strings, ambiguous prefixes, disabled-object references, the
 * `path` request parameter).
 *
 * Unlike collect-parseil.ts this does NOT write per-file sidecars — a highlight
 * response is ~6× the source size and the 6 committed `.rsc.highlight` files
 * remain the offline test fixtures. Output is a single version-tagged summary:
 *   test-data/highlight-summary.v<routeros-version>.json
 */

import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { replaceNonAscii } from '../server/src/routeros'
import { ROUTEROS_API_MAX_BYTES } from '../server/src/shared'

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://127.0.0.1:9170'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../test-data')

const args = process.argv.slice(2)
const argLimit = (() => {
	const idx = args.indexOf('--limit')
	return idx >= 0 ? Number.parseInt(args[idx + 1] ?? '0', 10) : 0
})()
const argTarget = (() => {
	const idx = args.indexOf('--target')
	return idx >= 0 ? args[idx + 1] : ''
})()

/** Every token class server/src/tokens.ts knows how to map (raw wire names). */
const KNOWN_TOKENS = new Set([
	'none',
	'dir',
	'path',
	'cmd',
	'arg',
	'arg-scope',
	'arg-dot',
	'variable-parameter',
	'variable-local',
	'variable-global',
	'variable-undefined',
	'variable-auto',
	'varname-local',
	'varname-global',
	'varname',
	'ambiguous',
	'syntax-val',
	'syntax-meta',
	'syntax-old',
	'syntax-obsolete',
	'syntax-noterm',
	'escaped',
	'comment',
	'obj-inactive',
	'obj-dynamic',
	'obj-disabled',
	'error',
])

const auth = `Basic ${Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')}`
const headers = { 'Content-Type': 'application/json', Authorization: auth }

async function rest(path: string, body?: unknown): Promise<unknown> {
	const resp = await fetch(`${CHR_URL}${path}`, {
		method: body === undefined ? 'GET' : 'POST',
		headers,
		body: body === undefined ? undefined : JSON.stringify(body),
		signal: AbortSignal.timeout(120_000),
	})
	if (!resp.ok) throw new Error(`${path} → ${resp.status} ${resp.statusText}`)
	return resp.json()
}

async function chrVersion(): Promise<{ version: string; buildTime: string }> {
	const r = (await rest('/rest/system/resource')) as { version?: string; ['build-time']?: string }
	const raw = (r.version ?? '').trim()
	const version = raw.split(/\s+/)[0] || 'unknown'
	return { version, buildTime: r['build-time'] ?? '' }
}

interface HighlightCapture {
	tokens: string[]
	itemCount: number
	itemKeys: string[]
	ms: number
}

async function fetchHighlight(input: string, path?: string): Promise<HighlightCapture> {
	const t0 = performance.now()
	const body: Record<string, string> = { request: 'highlight', input }
	if (path !== undefined) body.path = path
	const data = (await rest('/rest/console/inspect', body)) as Array<Record<string, string>>
	const ms = Math.round(performance.now() - t0)
	const first = data[0] ?? {}
	return {
		tokens: (first.highlight ?? '').split(','),
		itemCount: data.length,
		itemKeys: Object.keys(first),
		ms,
	}
}

function globRsc(dir: string): string[] {
	const out: string[] = []
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = join(dir, entry.name)
		if (entry.isDirectory()) out.push(...globRsc(full))
		else if (entry.name.endsWith('.rsc')) out.push(full)
	}
	return out.sort()
}

interface FileResult {
	rel: string
	inputChars: number
	tokenCount: number
	tokenCountMatch: boolean
	ms: number
	types: string[]
	error?: string
}

/**
 * Targeted probes for token classes the corpus may not elicit.
 * `setup`/`teardown` are CLI commands run via /rest/execute so highlight can
 * observe live object flags (disabled/dynamic items) — highlight is stateful.
 */
interface Probe {
	name: string
	input: string
	path?: string
	setup?: string[]
	teardown?: string[]
}

const PROBES: Probe[] = [
	{ name: 'undefined-variable', input: ':put $surelyUndefinedVariable' },
	{ name: 'local-variable', input: ':local x 1; :put $x' },
	{ name: 'global-variable', input: ':global gx 2; :put $gx' },
	{ name: 'foreach-counter', input: ':foreach i in=[/ip address find] do={:put $i}' },
	{ name: 'function-parameter', input: ':local f do={:put $1}; [$f "hi"]' },
	{ name: 'full-path-command', input: '/ip/address/print' },
	{ name: 'space-path-command', input: '/ip address print' },
	{ name: 'ambiguous-prefix', input: '/i' },
	{ name: 'ambiguous-prefix-cmd', input: '/in pr' },
	{ name: 'bad-command', input: 'this is not a command' },
	{ name: 'unterminated-string', input: ':put "abc' },
	{ name: 'unterminated-brace', input: ':if (1=1) do={:put yes' },
	{ name: 'escaped-string', input: ':put "a\\nb\\"c"' },
	{ name: 'comment-line', input: '# just a comment' },
	{ name: 'bad-arg-value', input: '/ip/address/add address=notanip interface=ether1' },
	{ name: 'unknown-arg', input: '/ip/address/add bogusarg=1' },
	{
		name: 'ref-disabled-item',
		input: '/ip firewall filter set 0 comment=x',
		setup: ['/ip firewall filter add chain=forward action=accept comment=hlcap-probe disabled=yes'],
		teardown: ['/ip firewall filter remove [find comment=hlcap-probe]'],
	},
	{
		name: 'ref-dynamic-item',
		input: '/ip dns static set 0 comment=x',
	},
	{ name: 'path-context-relative', input: 'add address=10.0.0.1/24 interface=ether1', path: 'ip,address' },
	{ name: 'path-context-bare-cmd', input: 'print', path: 'ip,address' },
	{ name: 'legacy-old-syntax', input: '/ip route add type=blackhole dst-address=10.9.9.0/24' },
	{ name: 'obsolete-syntax', input: '/system routerboard print' },
	{ name: 'oversize-input', input: `:put "x"\n`.repeat(4000) },
]

interface ProbeResult {
	name: string
	input: string
	path?: string
	tokens?: string[]
	pairs?: Array<[string, string]>
	types: string[]
	error?: string
}

/** Pair each character with its token for compact eyeballing: [["/","dir"],…] run-length collapsed. */
function runLength(input: string, tokens: string[]): Array<[string, string]> {
	const out: Array<[string, string]> = []
	let start = 0
	for (let i = 1; i <= tokens.length; i++) {
		if (i === tokens.length || tokens[i] !== tokens[start]) {
			out.push([input.slice(start, i), tokens[start]])
			start = i
		}
	}
	return out
}

async function execCli(cmd: string): Promise<void> {
	await rest('/rest/execute', { script: cmd, 'as-string': 'true' })
}

async function main() {
	const { version, buildTime } = await chrVersion()
	console.log(`CHR ${CHR_URL} → RouterOS ${version} (build ${buildTime})`)

	let files = globRsc(TEST_DATA_DIR)
	if (argTarget) files = files.filter((f) => f.includes(argTarget))
	if (argLimit > 0) files = files.slice(0, argLimit)
	console.log(`Collecting highlight for ${files.length} script(s) …`)

	const tokenTotals = new Map<string, number>()
	const tokenFileCounts = new Map<string, number>()
	const tokenExampleFile = new Map<string, string>()
	const unknownTokens = new Map<string, string[]>() // token → example files
	const results: FileResult[] = []
	let itemKeysSeen: string[] = []
	let multiItemResponses = 0

	let i = 0
	for (const f of files) {
		i++
		const rel = relative(TEST_DATA_DIR, f)
		const text = readFileSync(f, 'utf-8')
		const input = replaceNonAscii(text.substring(0, ROUTEROS_API_MAX_BYTES), '?')
		try {
			const cap = await fetchHighlight(input)
			itemKeysSeen = cap.itemKeys
			if (cap.itemCount > 1) multiItemResponses++
			const types = [...new Set(cap.tokens)].sort()
			for (const t of cap.tokens) tokenTotals.set(t, (tokenTotals.get(t) ?? 0) + 1)
			for (const t of types) {
				tokenFileCounts.set(t, (tokenFileCounts.get(t) ?? 0) + 1)
				if (!tokenExampleFile.has(t)) tokenExampleFile.set(t, rel)
				if (!KNOWN_TOKENS.has(t)) {
					const list = unknownTokens.get(t) ?? []
					if (list.length < 5) list.push(rel)
					unknownTokens.set(t, list)
				}
			}
			results.push({
				rel,
				inputChars: input.length,
				tokenCount: cap.tokens.length,
				tokenCountMatch: cap.tokens.length === input.length,
				ms: cap.ms,
				types,
			})
			if (i % 50 === 0 || i === files.length) console.log(`  [${i}/${files.length}] …`)
		} catch (err) {
			results.push({
				rel,
				inputChars: input.length,
				tokenCount: 0,
				tokenCountMatch: false,
				ms: 0,
				types: [],
				error: err instanceof Error ? err.message : String(err),
			})
			console.log(`  [${i}/${files.length}] ERR ${rel}`)
		}
	}

	console.log('\nRunning targeted probes …')
	const probeResults: ProbeResult[] = []
	for (const probe of PROBES) {
		try {
			for (const cmd of probe.setup ?? []) await execCli(cmd)
			const input = replaceNonAscii(probe.input.substring(0, ROUTEROS_API_MAX_BYTES), '?')
			const cap = await fetchHighlight(input, probe.path)
			const types = [...new Set(cap.tokens)].sort()
			for (const t of types) {
				if (!KNOWN_TOKENS.has(t)) {
					const list = unknownTokens.get(t) ?? []
					list.push(`probe:${probe.name}`)
					unknownTokens.set(t, list)
				}
			}
			const big = input.length > 200
			probeResults.push({
				name: probe.name,
				input: big ? `${input.slice(0, 40)}… (${input.length} chars)` : probe.input,
				path: probe.path,
				pairs: big ? undefined : runLength(input, cap.tokens),
				types,
			})
			console.log(`  ${probe.name}: ${types.join(', ')}`)
		} catch (err) {
			probeResults.push({
				name: probe.name,
				input: probe.input.slice(0, 60),
				path: probe.path,
				types: [],
				error: err instanceof Error ? err.message : String(err),
			})
			console.log(`  ${probe.name}: ERR`)
		} finally {
			for (const cmd of PROBES.find((p) => p.name === probe.name)?.teardown ?? []) {
				await execCli(cmd).catch(() => {})
			}
		}
	}

	const ok = results.filter((r) => !r.error)
	const sortedTotals = Object.fromEntries([...tokenTotals.entries()].sort((a, b) => b[1] - a[1]))
	const vocabulary = [...tokenTotals.keys()].sort().map((t) => ({
		token: t,
		known: KNOWN_TOKENS.has(t),
		chars: tokenTotals.get(t) ?? 0,
		files: tokenFileCounts.get(t) ?? 0,
		firstSeen: tokenExampleFile.get(t) ?? '',
	}))
	const neverObserved = [...KNOWN_TOKENS].filter((t) => !tokenTotals.has(t) && !probeResults.some((p) => p.types.includes(t))).sort()

	console.log('\nVocabulary across corpus:')
	for (const v of vocabulary) console.log(`  ${v.known ? ' ' : '!'} ${v.token.padEnd(20)} chars=${v.chars} files=${v.files}`)
	if (unknownTokens.size) {
		console.log('\nUNKNOWN tokens (not in tokens.ts):')
		for (const [t, where] of unknownTokens) console.log(`  ${t} ← ${where.join(', ')}`)
	}
	console.log(`\nKnown classes never observed (corpus or probes): ${neverObserved.join(', ') || '(none)'}`)
	const mismatches = ok.filter((r) => !r.tokenCountMatch)
	console.log(`Token-count mismatches: ${mismatches.length}/${ok.length}`)
	console.log(`Multi-item responses: ${multiItemResponses}; response item keys: ${itemKeysSeen.join(', ')}`)

	const summaryPath = join(TEST_DATA_DIR, `highlight-summary.v${version}.json`)
	writeFileSync(
		summaryPath,
		`${JSON.stringify(
			{
				routerosVersion: version,
				chrBuildTime: buildTime,
				capturedAt: new Date().toISOString(),
				totalFiles: files.length,
				ok: ok.length,
				failed: results.length - ok.length,
				tokenCountMismatches: mismatches.map((r) => r.rel),
				responseItemKeys: itemKeysSeen,
				multiItemResponses,
				vocabulary,
				tokenTotals: sortedTotals,
				unknownTokens: Object.fromEntries(unknownTokens),
				knownNeverObserved: neverObserved,
				probes: probeResults,
				results,
			},
			null,
			2,
		)}\n`,
		'utf-8',
	)
	console.log(`\nSummary written: ${relative(TEST_DATA_DIR, summaryPath)}`)
}

await main()
