/**
 * inspect-shapes collection harness — captures verbatim `/console/inspect`
 * responses for the `completion`, `syntax`, and `child` request types across a
 * curated set of representative contexts.
 *
 * Usage:   bun run scripts/collect-inspect-shapes.ts
 * Env:     ROUTEROS_TEST_URL, ROUTEROS_TEST_USER, ROUTEROS_TEST_PASS,
 *          ROUTEROS_INSPECT_TIMEOUT_MS
 *
 * Why this file exists: `[research: inspect-shapes]` (BACKLOG P0). The
 * highlight quarter of that item is grounded by scripts/collect-highlight.ts +
 * docs/highlight-format.md; this harness grounds the other three request
 * types for docs/inspect-shapes.md. Contexts are curated rather than swept
 * from the corpus: the goal is schema coverage (every field, every node type,
 * value-enum vs object-reference completions), not exhaustiveness.
 *
 * Safety: old RouterOS versions have deadlocked REST on scripting-keyword
 * paths (confirmed for bare `do` with syntax/completion on 7.20.8; fixed by
 * 7.21.4 in restraml's live matrix). No probe below touches those, and every
 * request has a timeout.
 *
 * Output: test-data/inspect-shapes.v<routeros-version>.json — verbatim
 * responses plus request bodies, timing, and a field-inventory rollup.
 */

import { createHash } from 'node:crypto'
import { writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://127.0.0.1:9170'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const REQUEST_TIMEOUT_MS = Number(process.env.ROUTEROS_INSPECT_TIMEOUT_MS ?? 60_000)
const TEST_DATA_DIR = join(import.meta.dir, '../test-data')

const auth = `Basic ${Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')}`
const headers = { 'Content-Type': 'application/json', Authorization: auth }

async function rest(path: string, body?: unknown): Promise<unknown> {
	const resp = await fetch(`${CHR_URL}${path}`, {
		method: body === undefined ? 'GET' : 'POST',
		headers,
		body: body === undefined ? undefined : JSON.stringify(body),
		signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
	})
	if (!resp.ok) throw new Error(`${path} → ${resp.status} ${resp.statusText}`)
	return resp.json()
}

async function chrVersion(): Promise<{ version: string; buildTime: string }> {
	const r = (await rest('/rest/system/resource')) as { version?: string; ['build-time']?: string }
	const version = ((r.version ?? '').trim().split(/\s+/)[0] || 'unknown') as string
	return { version, buildTime: r['build-time'] ?? '' }
}

async function captureEnvironment(): Promise<{
	architecture?: string
	boardName?: string
	packages: Array<{ name: string; version: string }>
}> {
	const [resourceRaw, packagesRaw] = await Promise.all([
		rest('/rest/system/resource'),
		rest('/rest/system/package'),
	])
	const resource = (Array.isArray(resourceRaw) ? resourceRaw[0] : resourceRaw) as Record<string, string> | undefined
	const packages = (Array.isArray(packagesRaw) ? packagesRaw : []) as Array<Record<string, string>>
	return {
		architecture: resource?.['architecture-name'],
		boardName: resource?.['board-name'],
		packages: packages
			.map((pkg) => ({ name: pkg.name ?? '', version: pkg.version ?? '' }))
			.filter((pkg) => pkg.name.length > 0)
			.sort((a, b) => a.name.localeCompare(b.name)),
	}
}

interface ShapeProbe {
	name: string
	/** What this context is meant to demonstrate — copied into the artifact. */
	demonstrates: string
	request: 'completion' | 'syntax' | 'child'
	input?: string
	path?: string
}

const PROBES: ShapeProbe[] = [
	// ── child: node enumeration ────────────────────────────────────────────
	{ name: 'child-root', demonstrates: 'root menu listing; node-type mix', request: 'child', path: '' },
	{ name: 'child-dir', demonstrates: 'children of a dir node', request: 'child', path: 'ip' },
	{ name: 'child-path-node', demonstrates: 'children of a path node: cmds + args', request: 'child', path: 'ip,address' },
	{ name: 'child-cmd-node', demonstrates: 'children of a cmd node: its args', request: 'child', path: 'ip,address,add' },
	{ name: 'child-arg-node', demonstrates: 'children of an arg node (leaf?)', request: 'child', path: 'ip,address,add,address' },
	{ name: 'child-self-entry', demonstrates: 'type=self entry when node is both cmd and arg', request: 'child', path: 'terminal,style' },
	{ name: 'child-scripting-cmd', demonstrates: 'root-level scripting command node', request: 'child', path: 'put' },
	{ name: 'child-with-input', demonstrates: 'whether the input field filters child results', request: 'child', path: 'ip', input: 'add' },
	{ name: 'child-bogus-path', demonstrates: 'error shape for a nonexistent path', request: 'child', path: 'nonexistent' },

	// ── syntax: descriptions ───────────────────────────────────────────────
	{ name: 'syntax-root', demonstrates: 'syntax at root', request: 'syntax', path: '' },
	{ name: 'syntax-dir', demonstrates: 'syntax of a dir node', request: 'syntax', path: 'ip' },
	{ name: 'syntax-path-node', demonstrates: 'syntax of a path node', request: 'syntax', path: 'ip,address' },
	{ name: 'syntax-cmd', demonstrates: 'syntax of a cmd node', request: 'syntax', path: 'ip,address,add' },
	{ name: 'syntax-arg', demonstrates: 'syntax of an arg node — the classic description', request: 'syntax', path: 'ip,address,add,address' },
	{ name: 'syntax-arg-enum', demonstrates: 'syntax of an enum-valued arg', request: 'syntax', path: 'ip,firewall,filter,add,action' },
	{ name: 'syntax-scripting-cmd', demonstrates: 'syntax of a scripting command', request: 'syntax', path: 'put' },
	{ name: 'syntax-with-input', demonstrates: 'whether input affects syntax response', request: 'syntax', path: 'ip,address,add', input: 'address=' },
	{ name: 'syntax-bogus-path', demonstrates: 'response for a nonexistent syntax path', request: 'syntax', path: 'nonexistent' },

	// ── completion: candidates at an input boundary ────────────────────────
	{ name: 'completion-empty-root', demonstrates: 'completions for empty input at root', request: 'completion', input: '' },
	{ name: 'completion-slash', demonstrates: 'completions right after /', request: 'completion', input: '/' },
	{ name: 'completion-ambiguous-prefix', demonstrates: 'candidate set for an ambiguous prefix', request: 'completion', input: '/i' },
	{ name: 'completion-unique-prefix', demonstrates: 'offset semantics for a mid-word completion', request: 'completion', input: '/ip/ad' },
	{ name: 'completion-valid-command', demonstrates: 'sentinels at an exact valid command boundary', request: 'completion', input: '/ip/address/print' },
	{ name: 'completion-unknown-command', demonstrates: 'sentinels for an unknown command word', request: 'completion', input: '/ip/address/not-a-command' },
	{ name: 'completion-after-cmd-space', demonstrates: 'argument candidates after command + space', request: 'completion', input: '/ip/firewall/filter/add ' },
	{ name: 'completion-valid-arg', demonstrates: 'sentinels at an exact valid argument word', request: 'completion', input: '/ip/address/add address' },
	{ name: 'completion-unknown-arg', demonstrates: 'sentinels for an unknown argument word', request: 'completion', input: '/ip/address/add bogusarg' },
	{ name: 'completion-arg-value-enum', demonstrates: 'enum-looking candidates after arg=', request: 'completion', input: '/ip/firewall/filter/add action=' },
	{ name: 'completion-arg-value-mixed', demonstrates: 'enum + free-form values after chain=', request: 'completion', input: '/ip/firewall/filter/add chain=' },
	{ name: 'completion-arg-value-object-ref', demonstrates: 'live object references (interfaces) after interface=', request: 'completion', input: '/ip/address/add interface=' },
	{ name: 'completion-where-fields', demonstrates: 'menu fields offered inside a where clause', request: 'completion', input: '/ip/route/print where ' },
	{ name: 'completion-scripting-prefix', demonstrates: 'scripting command prefix after colon', request: 'completion', input: ':pu' },
	{ name: 'completion-nested-bracket', demonstrates: 'completion inside [ ] command substitution', request: 'completion', input: ':put [/ip/ad' },
	{ name: 'completion-path-context', demonstrates: 'path parameter sets the menu context', request: 'completion', input: 'add address=', path: 'ip,address' },
	{ name: 'completion-terminal-style', demonstrates: '12 terminal-style candidates', request: 'completion', input: '/terminal/style ' },
	{ name: 'completion-variable', demonstrates: 'completion after $ (declared globals?)', request: 'completion', input: ':global shapesProbe 1; :put $' },
	{ name: 'completion-nonascii-offset', demonstrates: 'whether offsets count UTF-8 bytes or JavaScript UTF-16 units', request: 'completion', input: ':put "é"; /ip/ad' },
]

interface ProbeResult {
	name: string
	demonstrates: string
	body: Record<string, string>
	ms: number
	itemCount?: number
	response?: unknown
	error?: string
}

async function main() {
	const { version, buildTime } = await chrVersion()
	const environment = await captureEnvironment()
	console.log(`CHR ${CHR_URL} → RouterOS ${version} (build ${buildTime})`)

	const results: ProbeResult[] = []
	// field inventory: request type → field name → set of observed values (capped)
	const fieldValues = new Map<string, Map<string, Set<string>>>()

	for (const probe of PROBES) {
		const body: Record<string, string> = { request: probe.request }
		if (probe.input !== undefined) body.input = probe.input
		if (probe.path !== undefined) body.path = probe.path
		const t0 = performance.now()
		try {
			const response = (await rest('/rest/console/inspect', body)) as Array<Record<string, string>>
			const ms = Math.round(performance.now() - t0)
			for (const item of response) {
				const perReq = fieldValues.get(probe.request) ?? new Map<string, Set<string>>()
				fieldValues.set(probe.request, perReq)
				for (const [k, v] of Object.entries(item)) {
					const vals = perReq.get(k) ?? new Set<string>()
					perReq.set(k, vals)
					if (vals.size < 40) vals.add(String(v))
				}
			}
			results.push({ name: probe.name, demonstrates: probe.demonstrates, body, ms, itemCount: response.length, response })
			console.log(`  ${probe.name}: ${response.length} item(s), ${ms}ms`)
		} catch (err) {
			const ms = Math.round(performance.now() - t0)
			results.push({ name: probe.name, demonstrates: probe.demonstrates, body, ms, error: err instanceof Error ? err.message : String(err) })
			console.log(`  ${probe.name}: ERR ${err instanceof Error ? err.message : err}`)
		}
	}

	const fieldInventory = Object.fromEntries(
		[...fieldValues.entries()].map(([req, fields]) => [
			req,
			Object.fromEntries([...fields.entries()].map(([k, vals]) => [k, { distinctValues: vals.size, sample: [...vals].slice(0, 12) }])),
		]),
	)

	console.log('\nField inventory:')
	for (const [req, fields] of Object.entries(fieldInventory)) {
		console.log(`  ${req}: ${Object.keys(fields).join(', ')}`)
	}

	const outPath = join(TEST_DATA_DIR, `inspect-shapes.v${version}.json`)
	const probeSha256 = createHash('sha256').update(JSON.stringify(PROBES)).digest('hex')
	writeFileSync(
		outPath,
		`${JSON.stringify(
			{
				routerosVersion: version,
				chrBuildTime: buildTime,
				environment,
				capturedAt: new Date().toISOString(),
				probeCount: PROBES.length,
				probeSha256,
				requestTimeoutMs: REQUEST_TIMEOUT_MS,
				fieldInventory,
				results,
			},
			null,
			2,
		)}\n`,
		'utf-8',
	)
	console.log(`\nArtifact written: ${relative(TEST_DATA_DIR, outPath)}`)
}

await main()
