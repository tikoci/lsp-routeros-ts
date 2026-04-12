import { describe, expect, it } from 'bun:test'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { HighlightTokens } from './tokens'

// helpers
function doc(text: string) {
	return TextDocument.create('file:///test.rsc', 'routeros', 1, text)
}

function makeTokens(text: string, highlight: string) {
	// highlight is a comma-separated string like RouterOS returns
	const rawTokens = highlight.split(',')
	// constructor signature: (tokens, document)
	return new HighlightTokens(rawTokens, doc(text))
}

describe('HighlightTokens.TokenTypes', () => {
	it('has exactly 15 entries', () => {
		expect(HighlightTokens.TokenTypes).toHaveLength(15)
	})

	it('starts with none and dir', () => {
		expect(HighlightTokens.TokenTypes[0]).toBe('none')
		expect(HighlightTokens.TokenTypes[1]).toBe('dir')
	})

	it('contains error', () => {
		expect(HighlightTokens.TokenTypes).toContain('syntax-val')
	})

	it('contains variable-local and variable-global', () => {
		expect(HighlightTokens.TokenTypes).toContain('variable-local')
		expect(HighlightTokens.TokenTypes).toContain('variable-global')
	})
})

describe('HighlightTokens.ErrorTokenTypes', () => {
	it('has exactly 6 entries', () => {
		expect(HighlightTokens.ErrorTokenTypes).toHaveLength(6)
	})

	it('contains variable-undefined and error', () => {
		expect(HighlightTokens.ErrorTokenTypes).toContain('variable-undefined')
		expect(HighlightTokens.ErrorTokenTypes).toContain('error')
	})

	it('maps raw error tokens into semantic types and modifiers', () => {
		expect(HighlightTokens.toSemanticToken('variable-undefined')).toEqual({ type: 'varname', modifiers: ['undefined'] })
		expect(HighlightTokens.toSemanticToken('error')).toEqual({ type: 'syntax-val', modifiers: ['error'] })
		expect(HighlightTokens.toSemanticToken('syntax-obsolete')).toEqual({ type: 'syntax-val', modifiers: ['obsolete'] })
	})

	it('is a subset of TokenTypes', () => {
		for (const t of HighlightTokens.ErrorTokenTypes) {
			expect(HighlightTokens.getTokenTypeIndex(t)).toBeGreaterThanOrEqual(0)
		}
	})
})

describe('HighlightTokens.TokenModifiers', () => {
	it('has exactly 8 entries', () => {
		expect(HighlightTokens.TokenModifiers).toHaveLength(8)
	})

	it('creates non-zero modifier mask for raw mapped tokens', () => {
		expect(HighlightTokens.getTokenModifierMask('error')).toBeGreaterThan(0)
		expect(HighlightTokens.getTokenModifierMask('arg-scope')).toBeGreaterThan(0)
		expect(HighlightTokens.getTokenModifierMask('arg-dot')).toBeGreaterThan(0)
	})
})

describe('HighlightTokens constructor and tokenRanges', () => {
	it('produces a token range for each run of same-type characters', () => {
		// "ip" → dir,dir  " " → none  "add" → cmd,cmd,cmd
		const text = '/ip add'
		const highlight = 'dir,dir,none,cmd,cmd,cmd'
		const ht = makeTokens(text, highlight)
		const ranges = ht.tokenRanges
		// Three distinct runs: dir, none, cmd
		expect(ranges.length).toBe(3)
	})

	it('consolidates consecutive same-token characters into one range', () => {
		const text = 'abc'
		const highlight = 'cmd,cmd,cmd'
		const ht = makeTokens(text, highlight)
		expect(ht.tokenRanges).toHaveLength(1)
		expect(ht.tokenRanges[0]?.token).toBe('cmd')
	})

	it('handles single-character documents', () => {
		const ht = makeTokens('/', 'dir')
		expect(ht.tokenRanges).toHaveLength(1)
		expect(ht.tokenRanges[0]?.token).toBe('dir')
	})

	it('handles empty token array', () => {
		const ht = new HighlightTokens([], doc(''))
		expect(ht.tokenRanges).toHaveLength(0)
	})

	it('records correct start line for multi-line text', () => {
		const text = 'a\nb'
		const highlight = 'cmd,none,cmd'
		const ht = makeTokens(text, highlight)
		const ranges = ht.tokenRanges
		// 'a' → line 0, '\n' → line 0, 'b' → line 1
		expect(ranges.find((r) => r.token === 'cmd' && r.range.start.line === 1)).toBeTruthy()
	})
})

describe('HighlightTokens.atPosition', () => {
	const text = '/ip'
	const highlight = 'dir,dir,dir'
	const ht = makeTokens(text, highlight)

	it('returns the token type at a valid position', () => {
		const result = ht.atPosition({ line: 0, character: 0 })
		expect(result?.token).toBe('dir')
	})

	it('returns undefined beyond the token array', () => {
		const result = ht.atPosition({ line: 0, character: 99 })
		expect(result).toBeUndefined()
	})

	it('returns token at last character', () => {
		const result = ht.atPosition({ line: 0, character: 2 })
		expect(result?.token).toBe('dir')
	})
})

describe('HighlightTokens.regexToken', () => {
	it('produces C for cmd tokens', () => {
		const ht = makeTokens('add', 'cmd,cmd,cmd')
		expect(ht.regexToken.join('')).toBe('CCC')
	})

	it('produces / for dir tokens', () => {
		const ht = makeTokens('/ip', 'dir,dir')
		expect(ht.regexToken.join('')).toBe('//')
	})

	it('produces A for arg tokens', () => {
		const ht = makeTokens('dst', 'arg,arg,arg')
		expect(ht.regexToken.join('')).toBe('AAA')
	})

	it('produces V for variable-global tokens', () => {
		const ht = makeTokens('$x', 'none,variable-global')
		// $ is none (not space, not after dir) → _, x is variable-global → V
		expect(ht.regexToken.join('')).toBe('_V')
	})

	it('produces v for variable-local tokens', () => {
		const ht = makeTokens('$x', 'none,variable-local')
		expect(ht.regexToken.join('')).toBe('_v')
	})

	it('produces E for error tokens', () => {
		const ht = makeTokens('??', 'error,error')
		expect(ht.regexToken.join('')).toBe('EE')
	})

	it("produces ' for newline characters regardless of token type", () => {
		const ht = makeTokens('/\n', 'dir,none')
		expect(ht.regexToken.join('')).toBe("/'")
	})

	it('produces | for tab characters', () => {
		const ht = makeTokens('\t', 'none')
		expect(ht.regexToken.join('')).toBe('|')
	})

	it('produces space for none+space', () => {
		const ht = makeTokens(' ', 'none')
		expect(ht.regexToken.join('')).toBe(' ')
	})
})

describe('HighlightTokens.positionInRange', () => {
	it('returns true for position inside range', () => {
		const ht = makeTokens('abc', 'cmd,cmd,cmd')
		const range = ht.tokenRanges[0]?.range
		expect(ht.positionInRange({ line: 0, character: 1 }, range)).toBe(true)
	})

	it('returns true at range start boundary', () => {
		const ht = makeTokens('abc', 'cmd,cmd,cmd')
		const range = ht.tokenRanges[0]?.range
		expect(ht.positionInRange(range.start, range)).toBe(true)
	})

	it('returns true at range end boundary', () => {
		const ht = makeTokens('abc', 'cmd,cmd,cmd')
		const range = ht.tokenRanges[0]?.range
		expect(ht.positionInRange(range.end, range)).toBe(true)
	})

	it('returns false for position before range', () => {
		const ht = makeTokens(' abc', 'none,cmd,cmd,cmd')
		const cmdRange = ht.tokenRanges[1]?.range
		expect(ht.positionInRange({ line: 0, character: 0 }, cmdRange)).toBe(false)
	})
})
