/**
 * Snapshot capture utility — run against a live CHR to save highlight responses.
 *
 * Usage: bun run server/src/capture-snapshots.ts
 *
 * Saves .highlight files alongside .rsc files in test-data/ for offline testing.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { replaceNonAscii } from './routeros'
import { ConnectionLogger, ROUTEROS_API_MAX_BYTES } from './shared'

// Silence logging — must be set before any module imports that use log
const noop = () => {}
ConnectionLogger.console = { log: noop, info: noop, warn: noop, error: noop, debug: noop }

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://192.168.74.150'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../../test-data')

/** Direct HTTP highlight request — avoids RouterRestClient singleton issues */
async function fetchHighlight(input: string): Promise<string | null> {
	const auth = Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')
	try {
		const resp = await fetch(`${CHR_URL}/rest/console/inspect`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: `Basic ${auth}` },
			body: JSON.stringify({ request: 'highlight', input }),
			signal: AbortSignal.timeout(30000),
		})
		if (!resp.ok) return null
		const data = (await resp.json()) as Array<{ highlight: string }>
		return data?.[0]?.highlight || null
	} catch {
		return null
	}
}

function globRsc(dir: string): string[] {
	const results: string[] = []
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = join(dir, entry.name)
		if (entry.isDirectory()) results.push(...globRsc(full))
		else if (entry.name.endsWith('.rsc')) results.push(full)
	}
	return results.sort()
}

async function main() {
	// Test connectivity directly
	const auth = Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')
	try {
		const resp = await fetch(`${CHR_URL}/rest/system/identity`, {
			headers: { Authorization: `Basic ${auth}` },
			signal: AbortSignal.timeout(5000),
		})
		const data = (await resp.json()) as { name: string }
		console.log(`Connected to CHR: ${data.name}`)
	} catch {
		console.error(`Cannot reach CHR at ${CHR_URL}`)
		process.exit(1)
	}

	// Only capture snapshots for a representative subset (small files)
	const snapshotTargets = ['/sample.rsc', '/global-wait.rsc', '/intentional-errors.rsc', 'edge-cases/comment-only.rsc', 'edge-cases/single-command.rsc', '/test.rsc']

	const allFiles = globRsc(TEST_DATA_DIR)
	let captured = 0

	for (const target of snapshotTargets) {
		const filePath = allFiles.find((f) => f.endsWith(target))
		if (!filePath) {
			console.warn(`  SKIP: ${target} not found`)
			continue
		}

		const text = readFileSync(filePath, 'utf-8')
		const input = replaceNonAscii(text.substring(0, ROUTEROS_API_MAX_BYTES), '?')
		const highlight = await fetchHighlight(input)
		if (!highlight) {
			console.warn(`  SKIP: no response for ${target}`)
			continue
		}

		const highlightPath = `${filePath}.highlight`
		writeFileSync(highlightPath, highlight, 'utf-8')
		const rel = relative(TEST_DATA_DIR, highlightPath)
		console.log(`  OK: ${rel} (${highlight.split(',').length} tokens)`)
		captured++
	}

	console.log(`\nCaptured ${captured} snapshots`)
}

main()
