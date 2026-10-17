/** Shared, offline capture contract. This module never connects to a router. */
import { createHash } from 'node:crypto'
import { spawnSync } from 'node:child_process'

export const EVIDENCE_FORMAT = 1
export const CLASSIFIER_VERSION = 'parse-response-v1'
export const HIGHLIGHT_LIMIT = 32767

/** Preserve BOM and reject invalid UTF-8 rather than hashing replacement text. */
export function decodeSource(bytes: ArrayLike<number>): string {
	return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(Uint8Array.from(bytes))
}

export function hash(text: string): string {
	return createHash('sha256').update(text, 'utf8').digest('hex')
}

export interface Diagnostic {
	message: string
	responseStart: number
	responseEnd: number
	line: number
	column: number
	/** A diagnostic names a command; it does not prove the menu was absent. */
	family: 'syntax' | 'command-resolution' | 'parameter-name' | 'unknown'
}

export interface ParseClassification {
	responseClass:
		| 'capture-failed'
		| 'missing-response'
		| 'plain-diagnostic'
		| 'embedded-diagnostic'
		| 'il-no-recognized-diagnostic'
		| 'unknown-response'
		| 'ambiguous-diagnostic'
	diagnostics: Diagnostic[]
}

export function classifyParseResponse(acquired: boolean, text: string | null, verifiedSource?: string): ParseClassification {
	if (!acquired) return { responseClass: 'capture-failed', diagnostics: [] }
	if (text === null) return { responseClass: 'missing-response', diagnostics: [] }
	const diagnostics: Diagnostic[] = []
	const plain =
		/^(?:syntax error|expected\b[^\r\n]*?|missing\b[^\r\n]*?|bad command name\b[^\r\n]*?|bad parameter\b[^\r\n]*?)\s*\(line (\d+) column (\d+)\)/.exec(
			text.trimStart(),
		)
	if (plain) {
		const responseStart = text.length - text.trimStart().length
		diagnostics.push(diagnostic(plain[0], responseStart, Number(plain[1]), Number(plain[2])))
		return { responseClass: 'plain-diagnostic', diagnostics }
	}
	let ambiguous = false
	const pattern = /\((?:<%%|evl)\s+(bad command name\s+[^\s()]+|bad parameter\s+[^\s()]+)\s+\(line (\d+) column (\d+)\)/g
	for (const match of text.matchAll(pattern)) {
		// IL emits string values without quoting/escaping. A node-shaped string
		// immediately after '=' is ambiguous; do not turn it into a diagnostic.
		if (text[(match.index ?? 0) - 1] === '=' || verifiedSource?.includes(match[0]) || verifiedSource?.includes(match[0].slice(match[0].indexOf(match[1])))) {
			ambiguous = true
			continue
		}
		const start = (match.index ?? 0) + match[0].indexOf(match[1])
		diagnostics.push(diagnostic(text.slice(start, (match.index ?? 0) + match[0].length), start, Number(match[2]), Number(match[3])))
	}
	if (diagnostics.length) return { responseClass: 'embedded-diagnostic', diagnostics }
	if (ambiguous) return { responseClass: 'ambiguous-diagnostic', diagnostics }
	// This is a response-form classifier, not an IL grammar or a validity oracle.
	const looksLikeIL = text.trim() === '' || /^(?:\/;?|\((?:evl|<%%|>|\$|&|\||!|~|[+*\/=-])|\$)/.test(text.trimStart())
	return { responseClass: looksLikeIL ? 'il-no-recognized-diagnostic' : 'unknown-response', diagnostics }
}

function diagnostic(message: string, responseStart: number, line: number, column: number): Diagnostic {
	return {
		message,
		responseStart,
		responseEnd: responseStart + message.length,
		line,
		column,
		family: message.startsWith('bad command name')
			? 'command-resolution'
			: message.startsWith('bad parameter')
				? 'parameter-name'
				: /^(syntax error|expected |missing )/.test(message)
					? 'syntax'
					: 'unknown',
	}
}

export type Probe = 'parseil' | 'highlight'
export interface CaptureInput {
	sourcePath: string
	sourceText: string
	sourceSha256: string
	submittedText: string
	submittedSha256: string
	variant: 'original' | 'highlight-ascii-prefix'
	transformation: 'identity-utf8-v1' | 'utf16-prefix-32767-ascii-code-unit-v1'
	sourceBytes: number
	submittedBytes: number
	sourceUtf16: number
	submittedUtf16: number
	truncated: boolean
	replacedCodeUnits: number
	submittedSpan: [number, number]
	coordinateMapping: string
	rootMenu: string
}

export function prepareInput(sourcePath: string, sourceText: string, probe: Probe): CaptureInput {
	const prefix = probe === 'highlight' ? sourceText.substring(0, HIGHLIGHT_LIMIT) : sourceText
	// Deliberately operates on UTF-16 code units, matching replaceNonAscii().
	const submittedText = probe === 'highlight' ? prefix.replace(/[^\x00-\x7f]/g, '?') : prefix
	return {
		sourcePath,
		sourceText,
		sourceSha256: hash(sourceText),
		submittedText,
		submittedSha256: hash(submittedText),
		variant: probe === 'highlight' ? 'highlight-ascii-prefix' : 'original',
		transformation: probe === 'highlight' ? 'utf16-prefix-32767-ascii-code-unit-v1' : 'identity-utf8-v1',
		sourceBytes: Buffer.byteLength(sourceText),
		submittedBytes: Buffer.byteLength(submittedText),
		sourceUtf16: sourceText.length,
		submittedUtf16: submittedText.length,
		truncated: prefix.length !== sourceText.length,
		replacedCodeUnits: probe === 'highlight' ? (prefix.match(/[^\x00-\x7f]/g)?.length ?? 0) : 0,
		submittedSpan: [0, prefix.length],
		rootMenu: '',
		coordinateMapping:
			probe === 'highlight'
				? 'submitted ASCII byte i -> source UTF-16 code unit i in [0, submittedUtf16); source UTF-8 byte offset = byteLength(sourceText.slice(0,i)); suffix unsubmitted'
				: 'identity UTF-8 bytes; device line/column retained verbatim, unit unverified; do not treat as editor offsets',
	}
}

export interface CaptureEnvironment {
	sessionId: string
	version: string
	buildTime: string | null
	architecture: string | null
	board: string | null
	packages: unknown
	deviceMode: unknown
	/** Config details intentionally bounded; unknown state cannot support runtime claims. */
	configuration: { scope: string; unrecorded: string[] }
	menuInventory: { path: string; response: unknown; error: string | null }[]
	menuInventorySha256: string
}

export interface CaptureObservation {
	input: CaptureInput
	acquisition: 'ok' | 'failed'
	submission: 'requested' | 'file-readback-verified'
	response: unknown
	error: string | null
	elapsedMs: number
	/** Only highlight has a known byte-to-source mapping. */
	highlight: { tokenCount: number; aligned: boolean; firstErrorByte: number | null; types: string[] } | null
	causes?: Array<{ cause: 'syntax' | 'unavailable-menu-or-command' | 'parameter-name' | 'unknown' | 'mixed'; scope: string; evidence: unknown }>
}

export interface CaptureRun {
	format: number
	id: string
	probe: Probe
	capturedAt: string
	environment: CaptureEnvironment
	environmentSha256: string
	selection: { target: string | null; limit: number | null; sourceSetSha256: string }
	observations: CaptureObservation[]
}

export function capturedResponseText(probe: Probe, response: unknown): string | null {
	if (probe === 'parseil') {
		const ret = (response as { ret?: unknown } | null)?.ret
		return typeof ret === 'string' ? ret : null
	}
	if (!Array.isArray(response) || response.length !== 1 || typeof response[0]?.highlight !== 'string') return null
	return response[0].highlight
}

/** Reject corrupted identities; report equal-length source changes as stale. */
export function validateObservation(observation: CaptureObservation, currentSourceHash: string | null): 'matched' | 'stale' | 'source-missing' {
	const input = observation.input
	if (!['ok', 'failed'].includes(observation.acquisition) || !['requested', 'file-readback-verified'].includes(observation.submission))
		throw new Error('Invalid acquisition/submission status')
	if (hash(input.sourceText) !== input.sourceSha256 || hash(input.submittedText) !== input.submittedSha256) throw new Error('Capture input hash mismatch')
	const expected = prepareInput(input.sourcePath, input.sourceText, input.variant === 'original' ? 'parseil' : 'highlight')
	if (Object.keys(expected).some((key) => JSON.stringify(expected[key as keyof CaptureInput]) !== JSON.stringify(input[key as keyof CaptureInput])))
		throw new Error('Capture transformation/coordinate metadata mismatch')
	if (observation.acquisition === 'ok') {
		const text = capturedResponseText(input.variant === 'original' ? 'parseil' : 'highlight', observation.response)
		if (input.variant === 'original') {
			if (observation.submission !== 'file-readback-verified' || text === null) throw new Error('Unverified parse response')
		} else {
			const rows = observation.response as Array<{ highlight?: unknown }>
			if (!Array.isArray(rows) || rows.length !== 1 || typeof rows[0].highlight !== 'string') throw new Error('Unverified highlight response')
			const tokens = rows[0].highlight ? rows[0].highlight.split(',') : []
			const index = tokens.indexOf('error')
			const expectedHighlight = {
				tokenCount: tokens.length,
				aligned: tokens.length === input.submittedBytes,
				firstErrorByte: index < 0 ? null : index,
				types: [...new Set(tokens)].sort(),
			}
			if (
				Object.keys(expectedHighlight).some(
					(key) =>
						JSON.stringify(expectedHighlight[key as keyof typeof expectedHighlight]) !==
						JSON.stringify(observation.highlight?.[key as keyof typeof expectedHighlight]),
				)
			)
				throw new Error('Highlight coverage metadata mismatch')
		}
	}
	return currentSourceHash === null ? 'source-missing' : currentSourceHash === input.sourceSha256 ? 'matched' : 'stale'
}

export function trackedSourcePaths(root: string): string[] {
	// All sidecars together exceed spawnSync's default output buffer. Truncating
	// this listing once silently selected only 748 of 955 sources under Bun.
	const listed = spawnSync('git', ['ls-files', '-z', '--', 'test-data'], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
	if (listed.status !== 0 || listed.error) throw new Error(`git ls-files: ${listed.error?.message ?? listed.stderr}`)
	if (listed.stdout && !listed.stdout.endsWith('\0')) throw new Error('Incomplete git file listing')
	return listed.stdout
		.split('\0')
		.filter((path) => path.endsWith('.rsc'))
		.sort()
}
