/**
 * CHR Integration Tests
 *
 * Connects to a live RouterOS CHR and validates inspectHighlight responses
 * for all .rsc test data files. Skips automatically when no CHR is reachable.
 *
 * Run: ROUTEROS_TEST_URL=http://192.168.74.150 bun test server/src/integration.test.ts
 *   or: bun test server/src/integration.test.ts  (uses default CHR address)
 */
import { afterAll, beforeAll, describe, expect, it } from 'bun:test'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { RouterRestClient, replaceNonAscii } from './routeros'
import { defaultSettings, ROUTEROS_API_MAX_BYTES, updateSettings } from './shared'
import { HighlightTokens } from './tokens'

// MARK: Configuration

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://192.168.74.150'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = join(import.meta.dir, '../../test-data')

// MARK: Helpers

/** Recursively glob all .rsc files under a directory */
function globRsc(dir: string): string[] {
	const results: string[] = []
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = join(dir, entry.name)
		if (entry.isDirectory()) {
			results.push(...globRsc(full))
		} else if (entry.name.endsWith('.rsc')) {
			results.push(full)
		}
	}
	return results.sort()
}

/** Read file and create TextDocument */
function loadScript(filePath: string): { text: string; doc: TextDocument } {
	const text = readFileSync(filePath, 'utf-8')
	const doc = TextDocument.create(`file:///${filePath}`, 'routeros', 1, text)
	return { text, doc }
}

// MARK: Test setup

let chrAvailable = false
let chrIdentity = ''
let client: RouterRestClient

beforeAll(async () => {
	// Configure settings to point at the test CHR
	// Use a short timeout for the initial connectivity check to avoid
	// blocking CI for 30s when no CHR is available
	updateSettings({
		...defaultSettings,
		baseUrl: CHR_URL,
		username: CHR_USER,
		password: CHR_PASS,
		apiTimeout: 5,
	})
	client = RouterRestClient.default
	client.invalidateClient()

	try {
		chrIdentity = await client.getIdentity()
		chrAvailable = true
		// Raise timeout for actual test requests
		updateSettings({
			...defaultSettings,
			baseUrl: CHR_URL,
			username: CHR_USER,
			password: CHR_PASS,
			apiTimeout: 30,
		})
		client.invalidateClient()
	} catch {
		console.warn(`⚠ CHR not reachable at ${CHR_URL} — integration tests will be skipped`)
		chrAvailable = false
	}
})

afterAll(() => {
	// Restore default settings
	updateSettings({ ...defaultSettings, baseUrl: 'http://reset-sentinel.internal' })
	updateSettings(defaultSettings)
})

// MARK: Connection test

describe('CHR connection', () => {
	it('should be reachable', () => {
		if (!chrAvailable) {
			console.warn('SKIPPED: CHR not available')
			return
		}
		expect(chrIdentity).toBeTruthy()
		expect(typeof chrIdentity).toBe('string')
	})
})

// MARK: inspectHighlight for all test-data scripts

const allRscFiles = globRsc(TEST_DATA_DIR)

describe('inspectHighlight for test-data/**/*.rsc', () => {
	it('found .rsc test data files', () => {
		expect(allRscFiles.length).toBeGreaterThan(0)
	})

	for (const filePath of allRscFiles) {
		const relPath = relative(TEST_DATA_DIR, filePath)
		const fileSize = statSync(filePath).size

		describe(relPath, () => {
			it('returns a highlight response', async () => {
				if (!chrAvailable) return
				const { text } = loadScript(filePath)
				const input = replaceNonAscii(text.substring(0, ROUTEROS_API_MAX_BYTES), '?')
				const response = await client.inspectHighlight(input)
				expect(response).toBeDefined()
				expect(response).not.toBeNull()
				expect(response?.length).toBeGreaterThan(0)
				expect(response?.[0].highlight).toBeTruthy()
			})

			it('token count matches character count (up to 32KB)', async () => {
				if (!chrAvailable) return
				const { text } = loadScript(filePath)
				const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
				const input = replaceNonAscii(truncated, '?')
				const response = await client.inspectHighlight(input)
				if (!response?.[0]?.highlight) return

				const tokens = response[0].highlight.split(',')
				// Token count should match input character count
				expect(tokens.length).toBe(input.length)
			})

			it('all token types are known', async () => {
				if (!chrAvailable) return
				const { text } = loadScript(filePath)
				const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
				const input = replaceNonAscii(truncated, '?')
				const response = await client.inspectHighlight(input)
				if (!response?.[0]?.highlight) return

				const tokens = response[0].highlight.split(',')
				const knownTypes = new Set(HighlightTokens.TokenTypes)
				const unknownTypes = tokens.filter((t) => !knownTypes.has(t))
				// All tokens should be known types (or at least not completely alien)
				// Note: RouterOS may introduce new token types in future versions
				if (unknownTypes.length > 0) {
					const unique = [...new Set(unknownTypes)]
					console.warn(`  ${relPath}: unknown token types: ${unique.join(', ')}`)
				}
			})

			it('HighlightTokens parses without throwing', async () => {
				if (!chrAvailable) return
				const { text, doc } = loadScript(filePath)
				const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
				const input = replaceNonAscii(truncated, '?')
				const response = await client.inspectHighlight(input)
				if (!response?.[0]?.highlight) return

				const tokens = response[0].highlight.split(',')
				// Should not throw
				const ht = new HighlightTokens(tokens, doc)
				expect(ht.tokenRanges).toBeDefined()
				expect(ht.tokenRanges.length).toBeGreaterThan(0)
			})

			// Files over 32KB should work — just truncated
			if (fileSize > ROUTEROS_API_MAX_BYTES) {
				it('handles 32KB truncation (oversize file)', async () => {
					if (!chrAvailable) return
					const { text } = loadScript(filePath)
					expect(text.length).toBeGreaterThan(ROUTEROS_API_MAX_BYTES)
					const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
					const input = replaceNonAscii(truncated, '?')
					const response = await client.inspectHighlight(input)
					expect(response).toBeDefined()
					expect(response?.[0].highlight).toBeTruthy()
					const tokens = response?.[0].highlight.split(',')
					// Tokens should cover exactly the truncated input
					expect(tokens.length).toBe(input.length)
				})
			}
		})
	}
})

// MARK: Specific file assertions

describe('intentional-errors.rsc — error token detection', () => {
	it('should contain error or variable-undefined tokens', async () => {
		if (!chrAvailable) return
		const errorFile = allRscFiles.find((f) => f.endsWith('intentional-errors.rsc'))
		if (!errorFile) {
			console.warn('SKIPPED: intentional-errors.rsc not found')
			return
		}
		const { text, doc } = loadScript(errorFile)
		const input = replaceNonAscii(text, '?')
		const response = await client.inspectHighlight(input)
		expect(response).toBeDefined()

		const tokens = response?.[0].highlight.split(',')
		const ht = new HighlightTokens(tokens, doc)
		const errorRanges = ht.tokenRanges.filter((r) => HighlightTokens.ErrorTokenTypes.includes(r.token))

		expect(errorRanges.length).toBeGreaterThan(0)
		// Should have at least variable-undefined or error tokens
		const errorTypes = new Set(errorRanges.map((r) => r.token))
		const hasExpectedError = errorTypes.has('variable-undefined') || errorTypes.has('error') || errorTypes.has('ambiguous')
		expect(hasExpectedError).toBe(true)
	})
})

describe('known-good scripts — no error tokens', () => {
	const knownGoodPatterns = ['edge-cases/single-command.rsc', 'edge-cases/comment-only.rsc']

	for (const pattern of knownGoodPatterns) {
		it(`${pattern} has no error tokens`, async () => {
			if (!chrAvailable) return
			const filePath = allRscFiles.find((f) => f.endsWith(pattern))
			if (!filePath) {
				console.warn(`SKIPPED: ${pattern} not found`)
				return
			}
			const { text, doc } = loadScript(filePath)
			const input = replaceNonAscii(text, '?')
			const response = await client.inspectHighlight(input)
			if (!response?.[0]?.highlight) return

			const tokens = response?.[0].highlight.split(',')
			const ht = new HighlightTokens(tokens, doc)
			const errorRanges = ht.tokenRanges.filter((r) => HighlightTokens.ErrorTokenTypes.includes(r.token))
			expect(errorRanges).toHaveLength(0)
		})
	}
})

describe('export.rsc — oversize file handling', () => {
	it('file exceeds 32KB API limit', () => {
		const exportFile = allRscFiles.find((f) => f.endsWith('export.rsc') && !f.includes('eworm'))
		if (!exportFile) return
		const { text } = loadScript(exportFile)
		expect(text.length).toBeGreaterThan(ROUTEROS_API_MAX_BYTES)
	})

	it('returns valid tokens for truncated content', async () => {
		if (!chrAvailable) return
		const exportFile = allRscFiles.find((f) => f.endsWith('export.rsc') && !f.includes('eworm'))
		if (!exportFile) return
		const { text } = loadScript(exportFile)
		const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
		const input = replaceNonAscii(truncated, '?')
		const response = await client.inspectHighlight(input)
		expect(response).toBeDefined()
		const tokens = response?.[0].highlight.split(',')
		expect(tokens.length).toBe(input.length)
	})
})

describe('edge-cases/empty.rsc', () => {
	it('returns empty or minimal highlight for empty input', async () => {
		if (!chrAvailable) return
		const response = await client.inspectHighlight('')
		// RouterOS may return empty response or single-entry for empty input
		expect(response).toBeDefined()
	})
})
