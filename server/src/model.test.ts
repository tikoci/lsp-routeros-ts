/**
 * Unit tests for LspDocument.diagnostics()
 *
 * Mocks RouterRestClient.default.inspectHighlight to return known highlight
 * strings, then verifies the diagnostic pipeline produces correct results.
 */
import { afterAll, beforeAll, beforeEach, describe, expect, it, mock } from 'bun:test'
import { DiagnosticSeverity } from 'vscode-languageserver'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { LspDocument } from './model'
import { RouterRestClient } from './routeros'
import { ROUTEROS_API_MAX_BYTES } from './shared'

// MARK: Mock setup

/** Map from input text (or substring) to the highlight response to return */
const mockHighlightResponses: Map<string, string> = new Map()

// inspectHighlight is an arrow-function property (instance-level, not prototype).
// We must patch the singleton instance directly.
const client = RouterRestClient.default
const originalInspectHighlight = client.inspectHighlight

beforeAll(() => {
	client.inspectHighlight = mock(async (input: string) => {
		// Try exact match first, then try prefixed matches
		for (const [key, highlight] of mockHighlightResponses) {
			if (input === key || input.startsWith(key)) {
				return [{ highlight, type: 'highlight' }]
			}
		}
		// If no mock registered, return undefined (simulates connection failure)
		return undefined
	}) as typeof client.inspectHighlight
})

afterAll(() => {
	client.inspectHighlight = originalInspectHighlight
	mockHighlightResponses.clear()
})

beforeEach(() => {
	mockHighlightResponses.clear()
})

// Helpers

function createDoc(text: string, uri = 'file:///test.rsc'): LspDocument {
	const td = TextDocument.create(uri, 'routeros', 1, text)
	return new LspDocument(td)
}

function setMockHighlight(inputText: string, highlightTokens: string) {
	mockHighlightResponses.set(inputText, highlightTokens)
}

// MARK: Tests

describe('LspDocument.diagnostics() — clean scripts', () => {
	it('produces zero diagnostics for all-none tokens', async () => {
		const text = 'abc'
		setMockHighlight(text, 'none,none,none')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		expect(diags).toHaveLength(0)
	})

	it('produces zero diagnostics for dir+cmd tokens', async () => {
		const text = '/ip print'
		setMockHighlight(text, 'dir,dir,dir,none,cmd,cmd,cmd,cmd,cmd')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		expect(diags).toHaveLength(0)
	})

	it('produces zero diagnostics for comment tokens', async () => {
		const text = '# hello'
		setMockHighlight(text, 'comment,comment,comment,comment,comment,comment,comment')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		expect(diags).toHaveLength(0)
	})
})

describe('LspDocument.diagnostics() — error tokens', () => {
	it('produces Error diagnostic for error tokens', async () => {
		const text = 'bad'
		setMockHighlight(text, 'error,error,error')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		// Should have at least one Error diagnostic
		const errors = diags.filter((d) => d.severity === DiagnosticSeverity.Error)
		expect(errors.length).toBeGreaterThan(0)
		expect(errors[0].code).toBe('token:error')
		expect(errors[0].source).toBe('routeroslsp')
	})

	it('produces Error diagnostic for variable-undefined tokens', async () => {
		const text = '$x'
		setMockHighlight(text, 'none,variable-undefined')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const errors = diags.filter((d) => d.severity === DiagnosticSeverity.Error)
		expect(errors.length).toBeGreaterThan(0)
		expect(errors[0].code).toBe('token:variable-undefined')
	})

	it('produces Error diagnostic for ambiguous tokens', async () => {
		const text = 'foo'
		setMockHighlight(text, 'ambiguous,ambiguous,ambiguous')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const errors = diags.filter((d) => d.severity === DiagnosticSeverity.Error)
		expect(errors.length).toBeGreaterThan(0)
	})

	it('diagnostic range matches error token position', async () => {
		// "ok bad" → none,none,none,error,error,error
		const text = 'ok bad'
		setMockHighlight(text, 'none,none,none,error,error,error')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const errors = diags.filter((d) => d.severity === DiagnosticSeverity.Error)
		expect(errors).toHaveLength(1)
		// Error should start at character 3 ("bad")
		expect(errors[0].range.start.line).toBe(0)
		expect(errors[0].range.start.character).toBe(3)
		// Error should end at character 5
		expect(errors[0].range.end.character).toBe(5)
	})
})

describe('LspDocument.diagnostics() — unchecked region warning', () => {
	it('adds unchecked warning when errors exist and more content follows on later lines', async () => {
		// Error on line 1, content continuing on lines 2-3
		// Unchecked only triggers when nextPosition.line < endPosition.line
		const text = 'bad\ngood\nmore'
		// b,a,d,\n,g,o,o,d,\n,m,o,r,e = 13 chars
		setMockHighlight(text, 'error,error,error,none,none,none,none,none,none,none,none,none,none')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const warnings = diags.filter((d) => d.severity === DiagnosticSeverity.Warning)
		const unchecked = warnings.find((d) => d.code === 'token:unchecked')
		expect(unchecked).toBeDefined()
		expect(unchecked?.message).toContain('Potential issues')
	})

	it('does NOT add unchecked warning when error is at end of document', async () => {
		// All errors, no trailing content — so no "unchecked" warning
		const text = 'bad'
		setMockHighlight(text, 'error,error,error')
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const unchecked = diags.find((d) => d.code === 'token:unchecked')
		expect(unchecked).toBeUndefined()
	})
})

describe('LspDocument.diagnostics() — 32KB truncation warning', () => {
	it('fires truncation warning for text >= 32KB+1', async () => {
		// The threshold is ROUTEROS_API_MAX_BYTES + 1 = 32768
		const size = ROUTEROS_API_MAX_BYTES + 2
		const text = 'a'.repeat(size)
		// Mock only needs to handle the truncated portion
		const truncated = text.substring(0, ROUTEROS_API_MAX_BYTES)
		const highlight = Array(truncated.length).fill('none').join(',')
		setMockHighlight(truncated, highlight)
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const toolong = diags.find((d) => d.code === 'token:toolong')
		expect(toolong).toBeDefined()
		expect(toolong?.severity).toBe(DiagnosticSeverity.Warning)
		expect(toolong?.message).toContain('32K')
	})

	it('does NOT fire truncation warning for text under 32KB', async () => {
		const text = 'a'.repeat(100)
		setMockHighlight(text, Array(100).fill('none').join(','))
		const doc = createDoc(text)
		const diags = await doc.diagnostics()
		const toolong = diags.find((d) => d.code === 'token:toolong')
		expect(toolong).toBeUndefined()
	})
})

describe('LspDocument.diagnostics() — connection failure', () => {
	it('produces zero diagnostics when inspectHighlight returns undefined', async () => {
		// No mock registered for this text → returns undefined
		const doc = createDoc('unmocked content xyz')
		const diags = await doc.diagnostics()
		expect(diags).toHaveLength(0)
	})
})
