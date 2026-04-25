/**
 * parseIL collection harness — runs `:parse` against every .rsc in test-data/
 * and saves the resulting RouterOS intermediate representation (IL) as a
 * version-tagged sibling snapshot.
 *
 * Usage:   bun run scripts/collect-parseil.ts [--limit N] [--target subpath]
 * Env:     ROUTEROS_TEST_URL, ROUTEROS_TEST_USER, ROUTEROS_TEST_PASS
 *
 * Why this file exists: see BACKLOG.md "[research: parseil]". The IL is what
 * RouterOS's scripting engine actually executes; capturing it across the corpus
 * gives us a second, independent grounding for the language beyond the
 * /console/inspect highlight stream we use today.
 *
 * Snapshot path layout: alongside `foo.rsc` we write
 *   foo.v<routeros-version>.parseil   — the IL string, exactly as RouterOS
 *                                        returned it (one logical line, no
 *                                        wrapper).
 *   foo.v<routeros-version>.parseil.meta.json — input bytes, IL bytes, parse
 *                                        wall-time, CHR build-time, success
 *                                        flag, and any error string. Written
 *                                        for both successful and failed captures.
 *
 * The version suffix (e.g. `.v7.22.1.parseil`) lets multiple RouterOS versions
 * coexist in the corpus so IL grammar drift across releases stays diffable.
 */

import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://127.0.0.1:9170'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../test-data')
const PROBE_FILE_NAME = 'parseil-probe.rsc'

const args = process.argv.slice(2)
const argLimit = (() => {
	const idx = args.indexOf('--limit')
	return idx >= 0 ? Number.parseInt(args[idx + 1] ?? '0', 10) : 0
})()
const argTarget = (() => {
	const idx = args.indexOf('--target')
	return idx >= 0 ? args[idx + 1] : ''
})()

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
	const raw = (r.version ?? '').trim() // e.g. "7.22.1 (stable)"
	const version = raw.split(/\s+/)[0] || 'unknown'
	return { version, buildTime: r['build-time'] ?? '' }
}

async function uploadProbe(contents: string): Promise<void> {
	// /file/remove tolerates a missing file (returns []), so just ensure clean.
	await fetch(`${CHR_URL}/rest/file/remove`, {
		method: 'POST',
		headers,
		body: JSON.stringify({ numbers: PROBE_FILE_NAME }),
	}).catch(() => {})
	await rest('/rest/file/add', { name: PROBE_FILE_NAME, contents })
}

async function fetchIL(): Promise<string> {
	// `:put` is the only readout path that stringifies a `code` value into the
	// real IL form; `:tostr` returns the literal "(code)" placeholder. Confirmed
	// in Phase 1 of the parseIL spike (see BACKLOG "[research: parseil]").
	const body = {
		script: `:put [:parse [/file/get ${PROBE_FILE_NAME} contents]]`,
		'as-string': 'true',
	}
	const r = (await rest('/rest/execute', body)) as { ret?: string }
	return r.ret ?? ''
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

interface CollectResult {
	rel: string
	inputBytes: number
	ilBytes: number
	parseMs: number
	ok: boolean
	error?: string
}

function writeMeta(filePath: string, version: string, buildTime: string, result: CollectResult): void {
	const ilPath = `${filePath}.v${version}.parseil`
	const metaPath = `${ilPath}.meta.json`
	writeFileSync(
		metaPath,
		`${JSON.stringify(
			{
				source: result.rel,
				routerosVersion: version,
				chrBuildTime: buildTime,
				inputBytes: result.inputBytes,
				ilBytes: result.ilBytes,
				parseMs: result.parseMs,
				ok: result.ok,
				error: result.error,
				capturedAt: new Date().toISOString(),
			},
			null,
			2,
		)}\n`,
		'utf-8',
	)
}

async function collectOne(filePath: string, version: string, buildTime: string): Promise<CollectResult> {
	const rel = relative(TEST_DATA_DIR, filePath)
	const text = readFileSync(filePath, 'utf-8')
	const inputBytes = Buffer.byteLength(text, 'utf-8')

	const result: CollectResult = { rel, inputBytes, ilBytes: 0, parseMs: 0, ok: false }
	try {
		await uploadProbe(text)
		const t0 = performance.now()
		const il = await fetchIL()
		result.parseMs = Math.round(performance.now() - t0)
		result.ilBytes = Buffer.byteLength(il, 'utf-8')
		result.ok = true

		const ilPath = `${filePath}.v${version}.parseil`
		writeFileSync(ilPath, il, 'utf-8')
	} catch (err) {
		result.error = err instanceof Error ? err.message : String(err)
	}
	writeMeta(filePath, version, buildTime, result)
	return result
}

async function main() {
	const { version, buildTime } = await chrVersion()
	console.log(`CHR ${CHR_URL} → RouterOS ${version} (build ${buildTime})`)

	let files = globRsc(TEST_DATA_DIR)
	if (argTarget) files = files.filter((f) => f.includes(argTarget))
	if (argLimit > 0) files = files.slice(0, argLimit)
	console.log(`Collecting parseIL for ${files.length} script(s) …`)

	const results: CollectResult[] = []
	let i = 0
	for (const f of files) {
		i++
		const r = await collectOne(f, version, buildTime)
		results.push(r)
		const tag = r.ok ? 'OK' : 'ERR'
		const detail = r.ok ? `${r.parseMs}ms  in=${r.inputBytes}B  IL=${r.ilBytes}B` : r.error
		console.log(`  [${i}/${files.length}] ${tag}  ${r.rel}  (${detail})`)
	}

	const ok = results.filter((r) => r.ok)
	const failed = results.filter((r) => !r.ok)
	const inputTotal = results.reduce((s, r) => s + r.inputBytes, 0)
	const ilTotal = ok.reduce((s, r) => s + r.ilBytes, 0)
	const meanMs = ok.length ? Math.round(ok.reduce((s, r) => s + r.parseMs, 0) / ok.length) : 0
	const maxMs = ok.length ? Math.max(...ok.map((r) => r.parseMs)) : 0

	console.log('')
	console.log(`Summary: ${ok.length}/${files.length} OK, ${failed.length} failed`)
	console.log(`  input bytes: ${inputTotal}    IL bytes: ${ilTotal}    ratio: ${inputTotal ? (ilTotal / inputTotal).toFixed(2) : '0'}x`)
	console.log(`  parse time:  mean ${meanMs}ms, max ${maxMs}ms`)
	if (failed.length) {
		console.log('  failures:')
		for (const f of failed) console.log(`    ${f.rel}: ${f.error}`)
	}

	const summaryPath = join(TEST_DATA_DIR, `parseil-summary.v${version}.json`)
	writeFileSync(
		summaryPath,
		`${JSON.stringify(
			{
				routerosVersion: version,
				chrBuildTime: buildTime,
				capturedAt: new Date().toISOString(),
				totalFiles: files.length,
				ok: ok.length,
				failed: failed.length,
				inputBytesTotal: inputTotal,
				ilBytesTotal: ilTotal,
				parseMsMean: meanMs,
				parseMsMax: maxMs,
				results,
			},
			null,
			2,
		)}\n`,
		'utf-8',
	)
	console.log(`\nSummary written: ${relative(TEST_DATA_DIR, summaryPath)}`)
	void statSync(summaryPath) // existence check; throws if missing
}

await main()
