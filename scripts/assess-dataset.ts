/**
 * Dataset assessment script — runs all .rsc files through RouterOS /console/inspect
 * to evaluate highlight response quality, token parsing, and timing.
 *
 * Usage: bun run scripts/assess-dataset.ts
 *
 * Override CHR address:
 *   ROUTEROS_TEST_URL=http://... bun run scripts/assess-dataset.ts
 *
 * Options:
 *   --json          Output results as JSON (for later analysis)
 *   --concurrency=N Number of parallel requests (default: 1 — sequential)
 *
 * This is an exploratory tool, not a formal test. It provides a survey of the
 * test-data corpus: what works, what fails, timing, token distributions, and
 * data quality signals to guide future test development.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { replaceNonAscii } from '../server/src/routeros'
import { ConnectionLogger, ROUTEROS_API_MAX_BYTES } from '../server/src/shared'
import { HighlightTokens } from '../server/src/tokens'

// Silence logging
const noop = () => {}
ConnectionLogger.console = { log: noop, info: noop, warn: noop, error: noop, debug: noop }

// MARK: Configuration

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://192.168.74.150'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../test-data')

const args = process.argv.slice(2)
const jsonOutput = args.includes('--json')
const concurrencyArg = args.find((a) => a.startsWith('--concurrency='))
const CONCURRENCY = concurrencyArg ? parseInt(concurrencyArg.split('=')[1], 10) : 1

// MARK: Types

interface FileResult {
	relPath: string
	collection: string // 'amm0' | 'rextended' | 'eworm' | 'edge-cases' | 'forum-legacy' | 'tikbook' | 'complex' | 'root'
	fileSize: number
	lineCount: number
	truncated: boolean
	requestTimeMs: number
	status: 'ok' | 'error' | 'empty-response' | 'no-tokens' | 'token-mismatch'
	errorMessage?: string
	tokenCount: number
	expectedTokenCount: number
	tokenCountMatch: boolean
	uniqueTokenTypes: string[]
	unknownTokenTypes: string[]
	errorTokenCount: number
	errorTokenTypes: string[]
	hasCliPrompt: boolean // [admin@MikroTik] > style lines
	hasCommentHeader: boolean // starts with # Source: or similar
	tokenRangeCount: number
	parseTimeMs: number // time to construct HighlightTokens + tokenRanges
	diagnosticTokenPct: number // % of chars that are error-like tokens
}

interface SummaryStats {
	totalFiles: number
	totalBytes: number
	totalLines: number
	totalRequestTimeMs: number
	avgRequestTimeMs: number
	medianRequestTimeMs: number
	p95RequestTimeMs: number
	maxRequestTimeMs: number
	statusCounts: Record<string, number>
	collectionCounts: Record<string, number>
	collectionStats: Record<string, { count: number; okCount: number; avgTimeMs: number; errorCount: number }>
	allTokenTypes: Record<string, number> // token type → occurrence count across all files
	unknownTokenTypesGlobal: string[]
	truncatedCount: number
	cliPromptCount: number
	filesWithErrors: number // files where error tokens exist
	totalErrorTokens: number
	avgParseTimeMs: number
	filesOversize: number // files > 32KB
	emptyFiles: number // 0-byte files
	tokenMismatchFiles: string[] // files where token count != char count
	errorFiles: string[] // files where API returned error
	topErrorMessages: Record<string, number>
}

// MARK: Helpers

const authHeader = `Basic ${Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')}`

async function fetchHighlight(input: string): Promise<{ highlight: string | null; timeMs: number; error?: string }> {
	const start = performance.now()
	try {
		const resp = await fetch(`${CHR_URL}/rest/console/inspect`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Authorization: authHeader },
			body: JSON.stringify({ request: 'highlight', input }),
			signal: AbortSignal.timeout(60000),
		})
		const timeMs = performance.now() - start
		if (!resp.ok) {
			const body = await resp.text().catch(() => '')
			return { highlight: null, timeMs, error: `HTTP ${resp.status}: ${body.substring(0, 200)}` }
		}
		const data = (await resp.json()) as Array<{ highlight: string }>
		return { highlight: data?.[0]?.highlight || null, timeMs }
	} catch (e) {
		const timeMs = performance.now() - start
		return { highlight: null, timeMs, error: e instanceof Error ? e.message : String(e) }
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

function classifyCollection(relPath: string): string {
	if (relPath.startsWith('forum/amm0/')) return 'amm0'
	if (relPath.startsWith('forum/rextended/')) return 'rextended'
	if (relPath.startsWith('eworm/')) return 'eworm'
	if (relPath.startsWith('edge-cases/')) return 'edge-cases'
	if (relPath.startsWith('tikbook/')) return 'tikbook'
	if (relPath.startsWith('complex/')) return 'complex'
	if (relPath.startsWith('forum/')) return 'forum-legacy'
	return 'root'
}

function hasCliPromptPattern(text: string): boolean {
	return /\[[\w@]+\]\s*>/.test(text)
}

function percentile(arr: number[], p: number): number {
	if (arr.length === 0) return 0
	const sorted = [...arr].sort((a, b) => a - b)
	const idx = Math.ceil((p / 100) * sorted.length) - 1
	return sorted[Math.max(0, idx)]
}

// MARK: Process a single file

async function processFile(filePath: string): Promise<FileResult> {
	const relPath = relative(TEST_DATA_DIR, filePath)
	const collection = classifyCollection(relPath)
	const text = readFileSync(filePath, 'utf-8')
	const fileSize = Buffer.byteLength(text, 'utf-8')
	const lineCount = text.split('\n').length
	const truncated = fileSize > ROUTEROS_API_MAX_BYTES
	const truncatedText = text.substring(0, ROUTEROS_API_MAX_BYTES)
	const input = replaceNonAscii(truncatedText, '?')
	const expectedTokenCount = input.length
	const hasCliPrompt = hasCliPromptPattern(text)
	const hasCommentHeader = text.startsWith('#')

	// Fetch from CHR
	const { highlight, timeMs: requestTimeMs, error } = await fetchHighlight(input)

	// Base result for error cases
	const base: FileResult = {
		relPath,
		collection,
		fileSize,
		lineCount,
		truncated,
		requestTimeMs,
		status: 'ok',
		tokenCount: 0,
		expectedTokenCount,
		tokenCountMatch: false,
		uniqueTokenTypes: [],
		unknownTokenTypes: [],
		errorTokenCount: 0,
		errorTokenTypes: [],
		hasCliPrompt,
		hasCommentHeader,
		tokenRangeCount: 0,
		parseTimeMs: 0,
		diagnosticTokenPct: 0,
	}

	if (error) {
		return { ...base, status: 'error', errorMessage: error }
	}
	if (!highlight) {
		return { ...base, status: 'empty-response' }
	}

	// Parse tokens
	const tokens = highlight.split(',')
	const tokenCount = tokens.length
	const tokenCountMatch = tokenCount === expectedTokenCount

	if (tokenCount === 0) {
		return { ...base, status: 'no-tokens', tokenCount }
	}

	// Token type analysis
	const typeCounts = new Map<string, number>()
	for (const t of tokens) {
		typeCounts.set(t, (typeCounts.get(t) || 0) + 1)
	}
	const uniqueTokenTypes = [...typeCounts.keys()].sort()

	const knownTypes = new Set([
		...HighlightTokens.TokenTypes,
		...HighlightTokens.ErrorTokenTypes.map((t) => {
			// ErrorTokenTypes are also valid token types
			return t
		}),
	])
	// Add compound types that toSemanticToken handles
	knownTypes.add('arg-scope')
	knownTypes.add('arg-dot')
	knownTypes.add('obj-inactive')
	knownTypes.add('syntax-obsolete')
	knownTypes.add('syntax-old')
	knownTypes.add('variable-undefined')
	knownTypes.add('ambiguous')
	knownTypes.add('error')
	knownTypes.add('path')

	const unknownTokenTypes = uniqueTokenTypes.filter((t) => !knownTypes.has(t))

	// Error token analysis
	const errorTokenSet = new Set(HighlightTokens.ErrorTokenTypes)
	let errorTokenCount = 0
	const errorTokenTypesFound = new Set<string>()
	for (const t of tokens) {
		if (errorTokenSet.has(t)) {
			errorTokenCount++
			errorTokenTypesFound.add(t)
		}
	}
	const diagnosticTokenPct = tokenCount > 0 ? (errorTokenCount / tokenCount) * 100 : 0

	// Parse through HighlightTokens to exercise the same code path as the LSP
	let tokenRangeCount = 0
	let parseTimeMs = 0
	let parseStatus: FileResult['status'] = tokenCountMatch ? 'ok' : 'token-mismatch'
	try {
		const doc = TextDocument.create(`file:///${filePath}`, 'routeros', 1, truncatedText)
		const parseStart = performance.now()
		const ht = new HighlightTokens(tokens, doc)
		tokenRangeCount = ht.tokenRanges.length
		// Also exercise regexToken to check for unknown types (the '?' fallback)
		const regex = ht.regexToken
		const unknownInRegex = regex.filter((r) => r === '?').length
		parseTimeMs = performance.now() - parseStart
		if (unknownInRegex > 0 && unknownTokenTypes.length === 0) {
			// regexToken found unknowns that our known set missed — interesting
		}
	} catch (e) {
		return {
			...base,
			status: 'error',
			errorMessage: `Parse error: ${e instanceof Error ? e.message : String(e)}`,
			tokenCount,
			expectedTokenCount,
			tokenCountMatch,
			uniqueTokenTypes,
			unknownTokenTypes,
			errorTokenCount,
			errorTokenTypes: [...errorTokenTypesFound],
			diagnosticTokenPct,
		}
	}

	return {
		relPath,
		collection,
		fileSize,
		lineCount,
		truncated,
		requestTimeMs,
		status: parseStatus,
		tokenCount,
		expectedTokenCount,
		tokenCountMatch,
		uniqueTokenTypes,
		unknownTokenTypes,
		errorTokenCount,
		errorTokenTypes: [...errorTokenTypesFound],
		hasCliPrompt,
		hasCommentHeader,
		tokenRangeCount,
		parseTimeMs,
		diagnosticTokenPct,
	}
}

// MARK: Summary computation

function computeSummary(results: FileResult[]): SummaryStats {
	const requestTimes = results.map((r) => r.requestTimeMs)

	const statusCounts: Record<string, number> = {}
	const collectionCounts: Record<string, number> = {}
	const collectionDetails: Record<string, { count: number; okCount: number; totalTime: number; errorCount: number }> = {}
	const allTokenTypes: Record<string, number> = {}
	const topErrorMessages: Record<string, number> = {}
	const tokenMismatchFiles: string[] = []
	const errorFiles: string[] = []
	let totalErrorTokens = 0
	let totalParseTime = 0

	for (const r of results) {
		// Status
		statusCounts[r.status] = (statusCounts[r.status] || 0) + 1

		// Collection
		collectionCounts[r.collection] = (collectionCounts[r.collection] || 0) + 1
		if (!collectionDetails[r.collection]) {
			collectionDetails[r.collection] = { count: 0, okCount: 0, totalTime: 0, errorCount: 0 }
		}
		collectionDetails[r.collection].count++
		collectionDetails[r.collection].totalTime += r.requestTimeMs
		if (r.status === 'ok') collectionDetails[r.collection].okCount++
		if (r.status === 'error') collectionDetails[r.collection].errorCount++

		// Token types
		for (const t of r.uniqueTokenTypes) {
			allTokenTypes[t] = (allTokenTypes[t] || 0) + 1
		}

		// Errors
		if (r.status === 'error' && r.errorMessage) {
			// Normalize error messages for grouping
			const key = r.errorMessage.substring(0, 80)
			topErrorMessages[key] = (topErrorMessages[key] || 0) + 1
			errorFiles.push(r.relPath)
		}

		if (!r.tokenCountMatch && r.status !== 'error' && r.status !== 'empty-response') {
			tokenMismatchFiles.push(r.relPath)
		}

		totalErrorTokens += r.errorTokenCount
		totalParseTime += r.parseTimeMs
	}

	// Build collectionStats
	const collectionStats: Record<string, { count: number; okCount: number; avgTimeMs: number; errorCount: number }> = {}
	for (const [col, d] of Object.entries(collectionDetails)) {
		collectionStats[col] = {
			count: d.count,
			okCount: d.okCount,
			avgTimeMs: d.count > 0 ? d.totalTime / d.count : 0,
			errorCount: d.errorCount,
		}
	}

	const unknownTokenTypesGlobal = Object.keys(allTokenTypes).filter((t) => {
		const knownTypes = new Set(HighlightTokens.TokenTypes)
		knownTypes.add('arg-scope')
		knownTypes.add('arg-dot')
		knownTypes.add('obj-inactive')
		knownTypes.add('syntax-obsolete')
		knownTypes.add('syntax-old')
		knownTypes.add('variable-undefined')
		knownTypes.add('ambiguous')
		knownTypes.add('error')
		knownTypes.add('path')
		return !knownTypes.has(t)
	})

	return {
		totalFiles: results.length,
		totalBytes: results.reduce((s, r) => s + r.fileSize, 0),
		totalLines: results.reduce((s, r) => s + r.lineCount, 0),
		totalRequestTimeMs: requestTimes.reduce((s, t) => s + t, 0),
		avgRequestTimeMs: requestTimes.length > 0 ? requestTimes.reduce((s, t) => s + t, 0) / requestTimes.length : 0,
		medianRequestTimeMs: percentile(requestTimes, 50),
		p95RequestTimeMs: percentile(requestTimes, 95),
		maxRequestTimeMs: Math.max(...requestTimes, 0),
		statusCounts,
		collectionCounts,
		collectionStats,
		allTokenTypes,
		unknownTokenTypesGlobal,
		truncatedCount: results.filter((r) => r.truncated).length,
		cliPromptCount: results.filter((r) => r.hasCliPrompt).length,
		filesWithErrors: results.filter((r) => r.errorTokenCount > 0).length,
		totalErrorTokens,
		avgParseTimeMs: results.length > 0 ? totalParseTime / results.length : 0,
		filesOversize: results.filter((r) => r.fileSize > ROUTEROS_API_MAX_BYTES).length,
		emptyFiles: results.filter((r) => r.fileSize === 0).length,
		tokenMismatchFiles,
		errorFiles,
		topErrorMessages,
	}
}

// MARK: Pretty-print report

function printReport(results: FileResult[], summary: SummaryStats) {
	const hr = '─'.repeat(80)
	console.log(`\n${hr}`)
	console.log(`  RouterOS LSP Dataset Assessment`)
	console.log(`  CHR: ${CHR_URL}  •  Files: ${summary.totalFiles}  •  ${(summary.totalBytes / 1024).toFixed(1)} KB`)
	console.log(hr)

	// Overall stats
	console.log(`\n## Summary`)
	console.log(`  Total files:          ${summary.totalFiles}`)
	console.log(`  Total size:           ${(summary.totalBytes / 1024).toFixed(1)} KB (${summary.totalLines} lines)`)
	console.log(`  Oversize (>32KB):     ${summary.filesOversize}`)
	console.log(`  Empty (0 bytes):      ${summary.emptyFiles}`)
	console.log(`  Has CLI prompts:      ${summary.cliPromptCount}`)
	console.log(`  Truncated for API:    ${summary.truncatedCount}`)

	// Timing
	console.log(`\n## Request Timing`)
	console.log(`  Total request time:   ${(summary.totalRequestTimeMs / 1000).toFixed(1)}s`)
	console.log(`  Average:              ${summary.avgRequestTimeMs.toFixed(0)}ms`)
	console.log(`  Median:               ${summary.medianRequestTimeMs.toFixed(0)}ms`)
	console.log(`  P95:                  ${summary.p95RequestTimeMs.toFixed(0)}ms`)
	console.log(`  Max:                  ${summary.maxRequestTimeMs.toFixed(0)}ms`)
	console.log(`  Throughput:           ${(summary.totalFiles / (summary.totalRequestTimeMs / 1000)).toFixed(1)} files/sec`)

	// Status breakdown
	console.log(`\n## Status Breakdown`)
	for (const [status, count] of Object.entries(summary.statusCounts).sort((a, b) => b[1] - a[1])) {
		const pct = ((count / summary.totalFiles) * 100).toFixed(1)
		console.log(`  ${status.padEnd(20)} ${String(count).padStart(5)}  (${pct}%)`)
	}

	// Collection breakdown
	console.log(`\n## By Collection`)
	console.log(`  ${'Collection'.padEnd(16)} ${'Files'.padStart(6)} ${'OK'.padStart(6)} ${'Errors'.padStart(7)} ${'Avg ms'.padStart(8)}`)
	console.log(`  ${'─'.repeat(16)} ${'─'.repeat(6)} ${'─'.repeat(6)} ${'─'.repeat(7)} ${'─'.repeat(8)}`)
	for (const [col, stats] of Object.entries(summary.collectionStats).sort((a, b) => b[1].count - a[1].count)) {
		console.log(`  ${col.padEnd(16)} ${String(stats.count).padStart(6)} ${String(stats.okCount).padStart(6)} ${String(stats.errorCount).padStart(7)} ${stats.avgTimeMs.toFixed(0).padStart(8)}`)
	}

	// Token types
	console.log(`\n## Token Types Found (across all files)`)
	const sortedTypes = Object.entries(summary.allTokenTypes).sort((a, b) => b[1] - a[1])
	for (const [type, count] of sortedTypes) {
		const marker = summary.unknownTokenTypesGlobal.includes(type) ? ' ⚠ UNKNOWN' : ''
		console.log(`  ${type.padEnd(24)} in ${String(count).padStart(5)} files${marker}`)
	}

	// Unknown token types
	if (summary.unknownTokenTypesGlobal.length > 0) {
		console.log(`\n## ⚠ Unknown Token Types`)
		console.log(`  These types are returned by RouterOS but not in HighlightTokens.TokenTypes:`)
		for (const t of summary.unknownTokenTypesGlobal) {
			console.log(`  - ${t} (in ${summary.allTokenTypes[t]} files)`)
		}
	}

	// Error tokens
	console.log(`\n## Error/Diagnostic Tokens`)
	console.log(`  Files with error tokens:  ${summary.filesWithErrors} / ${summary.totalFiles}`)
	console.log(`  Total error token chars:  ${summary.totalErrorTokens}`)

	// Top files by error token percentage
	const errorPctSorted = results
		.filter((r) => r.diagnosticTokenPct > 0)
		.sort((a, b) => b.diagnosticTokenPct - a.diagnosticTokenPct)
		.slice(0, 15)
	if (errorPctSorted.length > 0) {
		console.log(`\n  Top files by error token %:`)
		for (const r of errorPctSorted) {
			console.log(`    ${r.diagnosticTokenPct.toFixed(1).padStart(5)}%  ${r.relPath}  (${r.errorTokenTypes.join(', ')})`)
		}
	}

	// Token mismatches
	if (summary.tokenMismatchFiles.length > 0) {
		console.log(`\n## ⚠ Token Count Mismatches (${summary.tokenMismatchFiles.length} files)`)
		console.log(`  Token count != input character count — may indicate API issues:`)
		for (const f of summary.tokenMismatchFiles.slice(0, 20)) {
			const r = results.find((res) => res.relPath === f)
			if (!r) continue
			console.log(`    ${f}  (got ${r.tokenCount}, expected ${r.expectedTokenCount})`)
		}
		if (summary.tokenMismatchFiles.length > 20) {
			console.log(`    ... and ${summary.tokenMismatchFiles.length - 20} more`)
		}
	}

	// API errors
	if (summary.errorFiles.length > 0) {
		console.log(`\n## ⚠ API Errors (${summary.errorFiles.length} files)`)
		for (const [msg, count] of Object.entries(summary.topErrorMessages).sort((a, b) => b[1] - a[1])) {
			console.log(`  ${String(count).padStart(4)}x  ${msg}`)
		}
		if (summary.errorFiles.length <= 10) {
			for (const f of summary.errorFiles) {
				const r = results.find((res) => res.relPath === f)
				if (!r) continue
				console.log(`    ${f}: ${r.errorMessage}`)
			}
		}
	}

	// Files with CLI prompts (data quality signal)
	if (summary.cliPromptCount > 0) {
		const cliFiles = results.filter((r) => r.hasCliPrompt).slice(0, 10)
		console.log(`\n## CLI Prompt Detection (${summary.cliPromptCount} files)`)
		console.log(`  These files contain [admin@MikroTik] > style prompts (pasted CLI output):`)
		for (const r of cliFiles) {
			console.log(`    ${r.relPath}`)
		}
		if (summary.cliPromptCount > 10) {
			console.log(`    ... and ${summary.cliPromptCount - 10} more`)
		}
	}

	// Slowest files (timing insights for debouncing)
	const slowest = [...results].sort((a, b) => b.requestTimeMs - a.requestTimeMs).slice(0, 10)
	console.log(`\n## Slowest Requests (debouncing/optimization insights)`)
	for (const r of slowest) {
		console.log(`  ${r.requestTimeMs.toFixed(0).padStart(6)}ms  ${(r.fileSize / 1024).toFixed(1).padStart(6)}KB  ${r.relPath}`)
	}

	// Size vs time correlation
	console.log(`\n## Size vs Time (file size buckets)`)
	const buckets = [
		{ label: '< 256B', min: 0, max: 256 },
		{ label: '256B-1KB', min: 256, max: 1024 },
		{ label: '1KB-4KB', min: 1024, max: 4096 },
		{ label: '4KB-16KB', min: 4096, max: 16384 },
		{ label: '16KB-32KB', min: 16384, max: 32768 },
		{ label: '> 32KB', min: 32768, max: Infinity },
	]
	for (const bucket of buckets) {
		const inBucket = results.filter((r) => r.fileSize >= bucket.min && r.fileSize < bucket.max)
		if (inBucket.length === 0) continue
		const avgTime = inBucket.reduce((s, r) => s + r.requestTimeMs, 0) / inBucket.length
		const avgSize = inBucket.reduce((s, r) => s + r.fileSize, 0) / inBucket.length
		console.log(`  ${bucket.label.padEnd(12)} ${String(inBucket.length).padStart(5)} files  avg ${avgTime.toFixed(0).padStart(5)}ms  avg ${(avgSize / 1024).toFixed(1).padStart(5)}KB`)
	}

	// Parse timing (HighlightTokens construction)
	console.log(`\n## Token Parse Timing`)
	console.log(`  Avg parse time:  ${summary.avgParseTimeMs.toFixed(2)}ms`)
	const parseTimes = results.filter((r) => r.parseTimeMs > 0).map((r) => r.parseTimeMs)
	if (parseTimes.length > 0) {
		console.log(`  Median:          ${percentile(parseTimes, 50).toFixed(2)}ms`)
		console.log(`  P95:             ${percentile(parseTimes, 95).toFixed(2)}ms`)
		console.log(`  Max:             ${Math.max(...parseTimes).toFixed(2)}ms`)
	}

	console.log(`\n${hr}`)
}

// MARK: Main

async function main() {
	// Test connectivity
	try {
		const resp = await fetch(`${CHR_URL}/rest/system/identity`, {
			headers: { Authorization: authHeader },
			signal: AbortSignal.timeout(5000),
		})
		const data = (await resp.json()) as { name: string }
		console.log(`Connected to CHR: ${data.name} at ${CHR_URL}`)
	} catch {
		console.error(`Cannot reach CHR at ${CHR_URL}`)
		console.error(`Set ROUTEROS_TEST_URL=http://... to override`)
		process.exit(1)
	}

	const allFiles = globRsc(TEST_DATA_DIR)
	console.log(`Found ${allFiles.length} .rsc files`)
	console.log(`Concurrency: ${CONCURRENCY}`)
	console.log()

	const results: FileResult[] = []
	let completed = 0
	const totalStart = performance.now()

	if (CONCURRENCY <= 1) {
		// Sequential — simplest, no request storms on CHR
		for (const filePath of allFiles) {
			const relPath = relative(TEST_DATA_DIR, filePath)
			const result = await processFile(filePath)
			results.push(result)
			completed++

			// Progress indicator
			const statusIcon = result.status === 'ok' ? '✓' : result.status === 'error' ? '✗' : '⚠'
			const pct = ((completed / allFiles.length) * 100).toFixed(0)
			process.stdout.write(`\r  [${pct.padStart(3)}%] ${statusIcon} ${completed}/${allFiles.length}  ${result.requestTimeMs.toFixed(0).padStart(4)}ms  ${relPath.substring(0, 60).padEnd(60)}`)
		}
	} else {
		// Parallel with limited concurrency
		let idx = 0
		const workers = Array.from({ length: CONCURRENCY }, async () => {
			while (idx < allFiles.length) {
				const i = idx++
				const filePath = allFiles[i]
				const result = await processFile(filePath)
				results.push(result)
				completed++
				const pct = ((completed / allFiles.length) * 100).toFixed(0)
				process.stdout.write(`\r  [${pct.padStart(3)}%] ${completed}/${allFiles.length}`)
			}
		})
		await Promise.all(workers)
	}

	const totalTimeMs = performance.now() - totalStart
	console.log(`\n\nCompleted in ${(totalTimeMs / 1000).toFixed(1)}s`)

	// Sort results by relPath for consistent output
	results.sort((a, b) => a.relPath.localeCompare(b.relPath))

	const summary = computeSummary(results)

	if (jsonOutput) {
		const output = { summary, results, chrUrl: CHR_URL, timestamp: new Date().toISOString(), totalTimeMs }
		const outPath = join(TEST_DATA_DIR, 'assessment-results.json')
		writeFileSync(outPath, JSON.stringify(output, null, 2))
		console.log(`\nJSON results written to ${relative(process.cwd(), outPath)}`)
	}

	printReport(results, summary)
}

main().catch((e) => {
	console.error('Fatal error:', e)
	process.exit(1)
})
