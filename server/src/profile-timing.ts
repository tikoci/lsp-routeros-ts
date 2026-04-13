/**
 * Performance profiling script — tests size→time relationship for RouterOS
 * /console/inspect highlight requests.
 *
 * Hypothesis: response time may be driven by syntax complexity (path lookups,
 * config queries) rather than pure length. This script tests by:
 *
 * 1. Taking real scripts and truncating at various sizes (256B → 32KB)
 * 2. Generating synthetic scripts (pure comments, simple commands, complex scripting)
 * 3. Comparing timing curves across different syntax profiles
 *
 * Usage: bun run server/src/profile-timing.ts
 *
 * Override CHR:
 *   ROUTEROS_TEST_URL=http://... bun run server/src/profile-timing.ts
 */
import { readFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { replaceNonAscii } from './routeros'
import { ConnectionLogger, ROUTEROS_API_MAX_BYTES } from './shared'

// Silence logging
const noop = () => {}
ConnectionLogger.console = { log: noop, info: noop, warn: noop, error: noop, debug: noop }

// MARK: Configuration

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://192.168.74.150'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../../test-data')

const RUNS_PER_SIZE = 3  // repeat each measurement to reduce noise
const WARMUP_RUNS = 2    // warm up the CHR before measuring

// Size steps to test (bytes) — logarithmic-ish spacing
const SIZE_STEPS = [
	128, 256, 512, 1024, 2048, 3072, 4096,
	6144, 8192, 10240, 12288, 16384,
	20480, 24576, 28672, ROUTEROS_API_MAX_BYTES,
]

// MARK: Types

interface TimingPoint {
	sizeBytes: number
	timeMs: number[]       // all runs
	avgMs: number
	medianMs: number
	minMs: number
	maxMs: number
}

interface ProfileResult {
	name: string
	description: string
	syntaxProfile: string  // what kind of syntax dominates
	fullSizeBytes: number
	points: TimingPoint[]
}

// MARK: Helpers

const authHeader = `Basic ${Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')}`

async function fetchHighlightTimed(input: string): Promise<number> {
	const start = performance.now()
	const resp = await fetch(`${CHR_URL}/rest/console/inspect`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', Authorization: authHeader },
		body: JSON.stringify({ request: 'highlight', input }),
		signal: AbortSignal.timeout(60000),
	})
	const timeMs = performance.now() - start
	if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
	await resp.json() // consume body
	return timeMs
}

function median(arr: number[]): number {
	const sorted = [...arr].sort((a, b) => a - b)
	const mid = Math.floor(sorted.length / 2)
	return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
}

// MARK: Synthetic script generators

function generateComments(targetBytes: number): string {
	// Pure comments — minimal parsing, just tokenize as 'comment'
	const lines: string[] = []
	let size = 0
	let i = 0
	while (size < targetBytes) {
		const line = `# This is comment line number ${i++} with some padding text to fill space\n`
		lines.push(line)
		size += line.length
	}
	return lines.join('').substring(0, targetBytes)
}

function generateSimpleCommands(targetBytes: number): string {
	// Repetitive simple commands — path resolution + arg parsing each line
	const lines: string[] = []
	let size = 0
	let i = 0
	while (size < targetBytes) {
		const line = `/ip firewall address-list add list=test-${String(i).padStart(4, '0')} address=10.0.${(i >> 8) & 255}.${i & 255} comment="entry-${i}"\n`
		lines.push(line)
		size += line.length
		i++
	}
	return lines.join('').substring(0, targetBytes)
}

function generateComplexScripting(targetBytes: number): string {
	// Complex scripting — variables, functions, control flow, string ops
	// This exercises the scripting engine's variable tracking and scope resolution
	const block = `:local totalCount 0
:local resultArray [:toarray ""]
:global globalFunc do={
  :local input \$1
  :local output ""
  :for i from=0 to=([:len \$input] - 1) do={
    :local ch [:pick \$input \$i (\$i + 1)]
    :if (\$ch = "a" || \$ch = "e" || \$ch = "i") do={
      :set output (\$output . [:tostr \$i])
    } else={
      :set output (\$output . \$ch)
    }
  }
  :return \$output
}
:foreach item in=[:toarray "alpha,bravo,charlie,delta,echo,foxtrot,golf,hotel"] do={
  :local processed [\$globalFunc \$item]
  :set (\$resultArray->[:len \$resultArray]) \$processed
  :set totalCount (\$totalCount + 1)
  :if (\$totalCount > 100) do={ :set totalCount 0 }
}
:log info "Processed \$totalCount items"
`
	const lines: string[] = []
	let size = 0
	let iteration = 0
	while (size < targetBytes) {
		// Vary the block slightly each time to avoid pure repetition
		const varied = block.replace(/globalFunc/g, `func${iteration}`).replace(/totalCount/g, `count${iteration}`).replace(/resultArray/g, `arr${iteration}`)
		lines.push(varied)
		size += varied.length
		iteration++
	}
	return lines.join('').substring(0, targetBytes)
}

function generateMixedPaths(targetBytes: number): string {
	// Mix of different RouterOS paths — tests path resolution breadth
	const paths = [
		'/ip firewall filter add chain=forward action=accept protocol=tcp dst-port=80',
		'/ip firewall nat add chain=srcnat action=masquerade out-interface=ether1',
		'/ip address add address=192.168.1.1/24 interface=bridge1',
		'/interface bridge add name=bridge1',
		'/interface bridge port add bridge=bridge1 interface=ether2',
		'/ip route add dst-address=0.0.0.0/0 gateway=192.168.1.254',
		'/ip dns set servers=8.8.8.8,8.8.4.4',
		'/system scheduler add name=backup interval=1d on-event="/system backup save"',
		'/queue simple add name=limit1 target=192.168.1.0/24 max-limit=10M/10M',
		'/ip pool add name=dhcp-pool ranges=192.168.1.100-192.168.1.200',
		'/ip dhcp-server add name=dhcp1 interface=bridge1 address-pool=dhcp-pool',
		'/ip dhcp-server network add address=192.168.1.0/24 gateway=192.168.1.1 dns-server=8.8.8.8',
		'/interface wireless set wlan1 mode=ap-bridge ssid=TestAP',
		'/ip service set www port=8080',
		'/user add name=testuser group=full password=testpass',
	]
	const lines: string[] = []
	let size = 0
	let i = 0
	while (size < targetBytes) {
		const line = paths[i % paths.length] + '\n'
		lines.push(line)
		size += line.length
		i++
	}
	return lines.join('').substring(0, targetBytes)
}

// MARK: Run profile for one script

async function profileScript(name: string, description: string, syntaxProfile: string, getText: (size: number) => string): Promise<ProfileResult> {
	const fullText = getText(ROUTEROS_API_MAX_BYTES)
	const fullSizeBytes = fullText.length
	const points: TimingPoint[] = []

	// Determine which size steps apply (skip sizes larger than available text)
	const applicableSteps = SIZE_STEPS.filter(s => s <= fullSizeBytes)

	for (const targetSize of applicableSteps) {
		const text = getText(targetSize)
		const input = replaceNonAscii(text.substring(0, targetSize), '?')

		// Warmup
		for (let w = 0; w < WARMUP_RUNS; w++) {
			await fetchHighlightTimed(input)
		}

		// Measure
		const times: number[] = []
		for (let r = 0; r < RUNS_PER_SIZE; r++) {
			const t = await fetchHighlightTimed(input)
			times.push(t)
		}

		const point: TimingPoint = {
			sizeBytes: input.length,
			timeMs: times,
			avgMs: times.reduce((s, t) => s + t, 0) / times.length,
			medianMs: median(times),
			minMs: Math.min(...times),
			maxMs: Math.max(...times),
		}
		points.push(point)

		const bar = '█'.repeat(Math.max(1, Math.round(point.medianMs / 50)))
		process.stdout.write(`  ${(targetSize / 1024).toFixed(1).padStart(5)}KB  ${point.medianMs.toFixed(0).padStart(5)}ms  ${bar}\n`)
	}

	return { name, description, syntaxProfile, fullSizeBytes, points }
}

async function profileRealFile(filePath: string, description: string, syntaxProfile: string): Promise<ProfileResult> {
	const text = readFileSync(filePath, 'utf-8')
	const relPath = relative(TEST_DATA_DIR, filePath)
	return profileScript(relPath, description, syntaxProfile, (size) => text.substring(0, size))
}

// MARK: Analysis

function analyzeScaling(result: ProfileResult): { slope: number; r2: number; model: string } {
	// Fit both linear and quadratic models, report which fits better
	const points = result.points.filter(p => p.sizeBytes > 0)
	if (points.length < 3) return { slope: 0, r2: 0, model: 'insufficient-data' }

	const xs = points.map(p => p.sizeBytes)
	const ys = points.map(p => p.medianMs)
	const n = xs.length

	// Linear fit: y = a + b*x
	const sumX = xs.reduce((s, x) => s + x, 0)
	const sumY = ys.reduce((s, y) => s + y, 0)
	const sumXY = xs.reduce((s, x, i) => s + x * ys[i], 0)
	const sumX2 = xs.reduce((s, x) => s + x * x, 0)
	const bLinear = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
	const aLinear = (sumY - bLinear * sumX) / n

	// R² for linear
	const yMean = sumY / n
	const ssTot = ys.reduce((s, y) => s + (y - yMean) ** 2, 0)
	const ssResLinear = ys.reduce((s, y, i) => s + (y - (aLinear + bLinear * xs[i])) ** 2, 0)
	const r2Linear = 1 - ssResLinear / ssTot

	// Quadratic fit: y = a + b*x + c*x²  (using least squares normal equations)
	const sumX3 = xs.reduce((s, x) => s + x ** 3, 0)
	const sumX4 = xs.reduce((s, x) => s + x ** 4, 0)
	const sumX2Y = xs.reduce((s, x, i) => s + x ** 2 * ys[i], 0)

	// Solve 3x3 system via Cramer's rule
	const det = n * (sumX2 * sumX4 - sumX3 * sumX3) -
		sumX * (sumX * sumX4 - sumX3 * sumX2) +
		sumX2 * (sumX * sumX3 - sumX2 * sumX2)

	let r2Quadratic = 0
	if (Math.abs(det) > 1e-10) {
		const aQ = (sumY * (sumX2 * sumX4 - sumX3 * sumX3) -
			sumX * (sumXY * sumX4 - sumX2Y * sumX3) +
			sumX2 * (sumXY * sumX3 - sumX2Y * sumX2)) / det
		const bQ = (n * (sumXY * sumX4 - sumX2Y * sumX3) -
			sumY * (sumX * sumX4 - sumX3 * sumX2) +
			sumX2 * (sumX * sumX2Y - sumXY * sumX2)) / det
		const cQ = (n * (sumX2 * sumX2Y - sumX3 * sumXY) -
			sumX * (sumX * sumX2Y - sumXY * sumX2) +
			sumY * (sumX * sumX3 - sumX2 * sumX2)) / det

		const ssResQuad = ys.reduce((s, y, i) => s + (y - (aQ + bQ * xs[i] + cQ * xs[i] ** 2)) ** 2, 0)
		r2Quadratic = 1 - ssResQuad / ssTot
	}

	const isQuadraticBetter = r2Quadratic > r2Linear + 0.05  // need 5% improvement to justify complexity
	return {
		slope: bLinear * 1024, // ms per KB
		r2: isQuadraticBetter ? r2Quadratic : r2Linear,
		model: isQuadraticBetter ? 'quadratic (superlinear)' : 'linear',
	}
}

// MARK: Report

function printReport(results: ProfileResult[]) {
	const hr = '─'.repeat(80)
	console.log(`\n${hr}`)
	console.log(`  RouterOS Highlight API — Performance Profile`)
	console.log(`  CHR: ${CHR_URL}  •  ${RUNS_PER_SIZE} runs/point  •  ${WARMUP_RUNS} warmup runs`)
	console.log(hr)

	// Comparative table
	console.log(`\n## Scaling Analysis`)
	console.log(`  ${'Script'.padEnd(30)} ${'Profile'.padEnd(14)} ${'Model'.padEnd(26)} ${'R²'.padStart(6)} ${'ms/KB'.padStart(7)}`)
	console.log(`  ${'─'.repeat(30)} ${'─'.repeat(14)} ${'─'.repeat(26)} ${'─'.repeat(6)} ${'─'.repeat(7)}`)
	for (const result of results) {
		const analysis = analyzeScaling(result)
		console.log(`  ${result.name.substring(0, 30).padEnd(30)} ${result.syntaxProfile.padEnd(14)} ${analysis.model.padEnd(26)} ${analysis.r2.toFixed(3).padStart(6)} ${analysis.slope.toFixed(1).padStart(7)}`)
	}

	// Detailed curves
	for (const result of results) {
		console.log(`\n## ${result.name}`)
		console.log(`  ${result.description}`)
		console.log(`  Syntax profile: ${result.syntaxProfile}`)
		console.log()
		console.log(`  ${'Size'.padStart(7)} ${'Median'.padStart(8)} ${'Min'.padStart(7)} ${'Max'.padStart(7)} ${'Curve'}`)
		console.log(`  ${'─'.repeat(7)} ${'─'.repeat(8)} ${'─'.repeat(7)} ${'─'.repeat(7)} ${'─'.repeat(30)}`)
		for (const p of result.points) {
			const bar = '█'.repeat(Math.max(1, Math.round(p.medianMs / 50)))
			console.log(`  ${(p.sizeBytes / 1024).toFixed(1).padStart(6)}K ${p.medianMs.toFixed(0).padStart(7)}ms ${p.minMs.toFixed(0).padStart(6)}ms ${p.maxMs.toFixed(0).padStart(6)}ms ${bar}`)
		}
	}

	// Key insights
	console.log(`\n## Key Comparisons`)
	// Compare same-size points across different syntax profiles
	const comparisonSizes = [1024, 4096, 16384, ROUTEROS_API_MAX_BYTES]
	for (const size of comparisonSizes) {
		console.log(`\n  At ${(size / 1024).toFixed(0)}KB:`)
		for (const result of results) {
			const point = result.points.find(p => Math.abs(p.sizeBytes - size) < size * 0.1)
			if (point) {
				console.log(`    ${result.name.substring(0, 30).padEnd(30)}  ${point.medianMs.toFixed(0).padStart(5)}ms  (${result.syntaxProfile})`)
			}
		}
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
		process.exit(1)
	}

	const results: ProfileResult[] = []

	// 1. Synthetic: Pure comments (baseline — minimal parsing)
	console.log(`\n▸ Profiling: synthetic-comments`)
	results.push(await profileScript(
		'synthetic-comments',
		'Pure comment lines — minimal tokenization work',
		'comments',
		generateComments,
	))

	// 2. Synthetic: Simple repetitive commands (path resolution each line)
	console.log(`\n▸ Profiling: synthetic-commands`)
	results.push(await profileScript(
		'synthetic-commands',
		'Repetitive /ip firewall address-list add — same path each line',
		'single-path',
		generateSimpleCommands,
	))

	// 3. Synthetic: Mixed paths (breadth of path resolution)
	console.log(`\n▸ Profiling: synthetic-mixed-paths`)
	results.push(await profileScript(
		'synthetic-mixed-paths',
		'Mix of /ip, /interface, /queue, /system paths — wide path resolution',
		'multi-path',
		generateMixedPaths,
	))

	// 4. Synthetic: Complex scripting (variables, control flow, string ops)
	console.log(`\n▸ Profiling: synthetic-complex`)
	results.push(await profileScript(
		'synthetic-complex',
		'Variables, functions, :for, :foreach, :if — heavy scripting',
		'scripting',
		generateComplexScripting,
	))

	// 5. Real file: eworm/global-functions.rsc (the slowest from assessment, 56KB→truncated to 32KB)
	console.log(`\n▸ Profiling: eworm/global-functions.rsc`)
	results.push(await profileRealFile(
		join(TEST_DATA_DIR, 'eworm/global-functions.rsc'),
		'Eworm global functions library — dense scripting, many globals',
		'scripting',
	))

	// 6. Real file: edge-cases/oversize-32k.rsc (repetitive commands, was also slow)
	console.log(`\n▸ Profiling: edge-cases/oversize-32k.rsc`)
	results.push(await profileRealFile(
		join(TEST_DATA_DIR, 'edge-cases/oversize-32k.rsc'),
		'Auto-generated repetitive address-list commands, >32KB',
		'single-path',
	))

	// 7. Real file: complex/piano.rsc (known complex scripting)
	console.log(`\n▸ Profiling: complex/piano.rsc`)
	results.push(await profileRealFile(
		join(TEST_DATA_DIR, 'complex/piano.rsc'),
		'Piano player script — complex :beep, arrays, timing',
		'scripting',
	))

	printReport(results)
}

main().catch(e => {
	console.error('Fatal error:', e)
	process.exit(1)
})
