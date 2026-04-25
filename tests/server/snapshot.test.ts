/**
 * Snapshot tests for token parsing.
 *
 * Tests HighlightTokens parsing against saved .rsc.highlight files,
 * validating token ranges and offset calculations without needing a live CHR.
 */
import { describe, expect, it } from 'bun:test'
import { readdirSync, readFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { HighlightTokens } from '../../server/src/tokens'

const TEST_DATA_DIR = join(import.meta.dir, '../../test-data')

/** Recursively find all .rsc files that have a corresponding .highlight snapshot */
function findSnapshotPairs(dir: string): { rsc: string; highlight: string; rel: string }[] {
	const results: { rsc: string; highlight: string; rel: string }[] = []
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = join(dir, entry.name)
		if (entry.isDirectory()) {
			results.push(...findSnapshotPairs(full))
		} else if (entry.name.endsWith('.rsc.highlight')) {
			const rscPath = full.replace(/\.highlight$/, '')
			try {
				readFileSync(rscPath) // verify .rsc exists
				results.push({
					rsc: rscPath,
					highlight: full,
					rel: relative(TEST_DATA_DIR, rscPath),
				})
			} catch {
				// .highlight without matching .rsc — skip
			}
		}
	}
	return results.sort((a, b) => a.rel.localeCompare(b.rel))
}

const pairs = findSnapshotPairs(TEST_DATA_DIR)

describe('Snapshot tests: .rsc + .highlight pairs', () => {
	it('found snapshot pairs', () => {
		expect(pairs.length).toBeGreaterThan(0)
	})

	for (const { rsc, highlight, rel } of pairs) {
		describe(rel, () => {
			const rscText = readFileSync(rsc, 'utf-8')
			const highlightText = readFileSync(highlight, 'utf-8').trim()
			const tokens = highlightText.split(',')
			const doc = TextDocument.create(`file:///${rsc}`, 'routeros', 1, rscText)

			it('token count matches document character count', () => {
				expect(tokens.length).toBe(rscText.length)
			})

			it('all tokens are known types', () => {
				const knownTypes = new Set(HighlightTokens.TokenTypes)
				const unknowns = new Set(tokens.filter((t) => !knownTypes.has(HighlightTokens.toSemanticToken(t).type)))
				expect([...unknowns]).toEqual([])
			})

			it('HighlightTokens parses without error', () => {
				const ht = new HighlightTokens(tokens, doc)
				expect(ht.tokenRanges).toBeDefined()
			})

			it('tokenRanges cover all tokens (no gaps)', () => {
				const ht = new HighlightTokens(tokens, doc)
				if (tokens.length === 0) return

				// Every character position should be covered by exactly one range
				const ranges = ht.tokenRanges
				expect(ranges.length).toBeGreaterThan(0)

				// Check that ranges form a contiguous span
				let coveredCount = 0
				for (const r of ranges) {
					const startOff = doc.offsetAt(r.range.start)
					const endOff = doc.offsetAt(r.range.end)
					// range is [start, end] inclusive
					coveredCount += endOff - startOff + 1
				}
				expect(coveredCount).toBe(tokens.length)
			})

			it('tokenRanges produce correct token types', () => {
				const ht = new HighlightTokens(tokens, doc)
				// Verify first and last token range have the expected token type
				const ranges = ht.tokenRanges
				if (ranges.length === 0) return

				const firstRange = ranges[0]
				const firstOffset = doc.offsetAt(firstRange.range.start)
				expect(firstRange.token).toBe(tokens[firstOffset])

				const lastRange = ranges[ranges.length - 1]
				const lastOffset = doc.offsetAt(lastRange.range.end)
				expect(lastRange.token).toBe(tokens[lastOffset])
			})

			it('atPosition returns correct token for first character', () => {
				if (tokens.length === 0) return
				const ht = new HighlightTokens(tokens, doc)
				const result = ht.atPosition({ line: 0, character: 0 })
				expect(result).toBeDefined()
				expect(result?.token).toBe(tokens[0])
			})

			it('regexToken has same length as token array', () => {
				const ht = new HighlightTokens(tokens, doc)
				expect(ht.regexToken.length).toBe(tokens.length)
			})
		})
	}
})

// MARK: Specific snapshot assertions

describe('edge-cases/single-command.rsc snapshot', () => {
	const pair = pairs.find((p) => p.rel === 'edge-cases/single-command.rsc')
	if (!pair) return

	const rscText = readFileSync(pair.rsc, 'utf-8')
	const tokens = readFileSync(pair.highlight, 'utf-8').trim().split(',')
	const doc = TextDocument.create('file:///single-command.rsc', 'routeros', 1, rscText)

	it('starts with dir tokens for "/ip"', () => {
		expect(tokens[0]).toBe('dir')
		expect(tokens[1]).toBe('dir')
		expect(tokens[2]).toBe('dir')
	})

	it('has none token for space separator', () => {
		expect(tokens[3]).toBe('none')
	})

	it('has dir tokens for "address"', () => {
		for (let i = 4; i <= 10; i++) {
			expect(tokens[i]).toBe('dir')
		}
	})

	it('ends with cmd tokens for "print"', () => {
		expect(tokens[12]).toBe('cmd')
		expect(tokens[13]).toBe('cmd')
		expect(tokens[14]).toBe('cmd')
		expect(tokens[15]).toBe('cmd')
		expect(tokens[16]).toBe('cmd')
	})

	it('tokenRanges produces exactly correct ranges', () => {
		const ht = new HighlightTokens(tokens, doc)
		const ranges = ht.tokenRanges
		// /ip = dir(3), ' ' = none(1), address = dir(7), ' ' = none(1), print = cmd(5), '\n' = none(1)
		// Expect: dir, none, dir, none, cmd, none
		expect(ranges.length).toBe(6)
		expect(ranges[0].token).toBe('dir')
		expect(ranges[1].token).toBe('none')
		expect(ranges[2].token).toBe('dir')
		expect(ranges[3].token).toBe('none')
		expect(ranges[4].token).toBe('cmd')
	})
})

describe('intentional-errors.rsc snapshot', () => {
	const pair = pairs.find((p) => p.rel === 'intentional-errors.rsc')
	if (!pair) return

	const rscText = readFileSync(pair.rsc, 'utf-8')
	const tokens = readFileSync(pair.highlight, 'utf-8').trim().split(',')
	const doc = TextDocument.create('file:///intentional-errors.rsc', 'routeros', 1, rscText)

	it('contains error tokens', () => {
		const errorTokens = tokens.filter((t) => HighlightTokens.ErrorTokenTypes.includes(t))
		expect(errorTokens.length).toBeGreaterThan(0)
	})

	it('HighlightTokens produces error ranges', () => {
		const ht = new HighlightTokens(tokens, doc)
		const errorRanges = ht.tokenRanges.filter((r) => HighlightTokens.ErrorTokenTypes.includes(r.token))
		expect(errorRanges.length).toBeGreaterThan(0)
	})
})

describe('edge-cases/comment-only.rsc snapshot', () => {
	const pair = pairs.find((p) => p.rel === 'edge-cases/comment-only.rsc')
	if (!pair) return

	const tokens = readFileSync(pair.highlight, 'utf-8').trim().split(',')

	it('contains only comment and none tokens', () => {
		const uniqueTypes = new Set(tokens)
		// Comment-only file should only have comment and none tokens
		for (const t of uniqueTypes) {
			expect(['comment', 'none']).toContain(t)
		}
	})

	it('has no error tokens', () => {
		const errorTokens = tokens.filter((t) => HighlightTokens.ErrorTokenTypes.includes(t))
		expect(errorTokens).toHaveLength(0)
	})
})
