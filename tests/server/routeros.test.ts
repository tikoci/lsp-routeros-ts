import { describe, expect, it } from 'bun:test'
import { normalizeError, replaceNonAscii } from '../../server/src/routeros'

describe('replaceNonAscii', () => {
	it('leaves pure ASCII text unchanged', () => {
		expect(replaceNonAscii('hello world')).toBe('hello world')
	})

	it('replaces non-ASCII characters with default underscore', () => {
		expect(replaceNonAscii('caf\u00e9')).toBe('caf_')
	})

	it('replaces non-ASCII with explicit replacement character', () => {
		expect(replaceNonAscii('caf\u00e9', '?')).toBe('caf?')
	})

	it('preserves string length after replacement', () => {
		const input = 'a\u00f8b\u00fccd'
		const result = replaceNonAscii(input, '?')
		expect(result.length).toBe(input.length)
	})

	it('handles empty string', () => {
		expect(replaceNonAscii('')).toBe('')
	})

	it('passes through all printable ASCII characters', () => {
		const ascii = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
		expect(replaceNonAscii(ascii)).toBe(ascii)
	})

	it('handles code point 127 as non-ASCII (DEL)', () => {
		// charCode 127 (DEL) — codes 0..127 pass through, all others replaced
		const withDel = 'a\x7fb'
		// charCode 127 is within range 0–127, so no replacement expected
		expect(replaceNonAscii(withDel)).toBe(withDel)
	})

	it('replaces multi-byte Unicode above 127', () => {
		const emoji = '\u{1F600}' // 😀 — charCode > 127
		const result = replaceNonAscii(emoji, '?')
		// surrogate pair or single codepoint in JS — each code unit > 127 replaced
		for (const ch of result) {
			expect(ch).toBe('?')
		}
	})
})

describe('normalizeError', () => {
	it('handles plain Error objects', () => {
		const err = new Error('connection failed')
		const norm = normalizeError(err)
		expect(norm.message).toBe('connection failed')
		expect(norm.code).toBeTruthy()
	})

	it('extracts code from Error.name when .code is absent', () => {
		const err = new TypeError('bad type')
		const norm = normalizeError(err)
		// name is 'TypeError', code is undefined
		expect(norm.code).toBe('TypeError')
	})

	it('handles non-Error unknown values (string)', () => {
		const norm = normalizeError('something went wrong')
		expect(norm.message).toBe('something went wrong')
		expect(norm.code).toBe('UNKNOWN')
	})

	it('handles non-Error unknown values (number)', () => {
		const norm = normalizeError(42)
		expect(norm.message).toBe('42')
		expect(norm.code).toBe('UNKNOWN')
	})

	it('handles null', () => {
		const norm = normalizeError(null)
		expect(norm.message).toBe('null')
		expect(norm.code).toBe('UNKNOWN')
	})

	it('handles axios-shaped errors (has .isAxiosError)', () => {
		// Construct a minimal object that looks like an AxiosError
		const axiosErr = {
			isAxiosError: true,
			code: 'ECONNREFUSED',
			message: 'connect ECONNREFUSED 127.0.0.1:80',
			response: { status: undefined },
		}
		const norm = normalizeError(axiosErr)
		expect(norm.code).toBe('ECONNREFUSED')
		expect(norm.message).toContain('ECONNREFUSED')
	})

	it('extracts HTTP status from Axios response', () => {
		const axiosErr = {
			isAxiosError: true,
			code: 'ERR_BAD_RESPONSE',
			message: 'Request failed with status 401',
			response: { status: 401 },
		}
		const norm = normalizeError(axiosErr)
		expect(norm.status).toBe(401)
	})

	it('returns a plain object (no circular refs)', () => {
		const err = new Error('test')
		const norm = normalizeError(err)
		// Must be JSON-serializable — no circular reference crash
		expect(() => JSON.stringify(norm)).not.toThrow()
	})
})
