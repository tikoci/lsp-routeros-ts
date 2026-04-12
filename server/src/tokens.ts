import type { Position, Range, TextDocument } from 'vscode-languageserver-textdocument'
import { log } from './shared'

type HighlightToken = string
type HighlightTokenRange = HighlightTokenRangeItem[]
interface HighlightTokenRangeItem {
	token: HighlightToken
	range: Range
}

interface SemanticTokenLegendItem {
	type: string
	modifiers: string[]
}

export class HighlightTokens {
	#tokens: HighlightToken[]
	#document: TextDocument
	#tokenRanges: HighlightTokenRange
	#startOffset = 0
	get document() {
		return this.#document
	}
	get tokens() {
		return this.#tokens
	}
	get tokenRanges() {
		return this.#tokenRanges
	}
	get regexToken(): string[] {
		log.debug(`<HighlightToken> regexToken() called`)

		const text = this.document.getText()
		return this.tokens.map((t, i, a) => {
			switch (true) {
				case text[i] === '\n':
					return "'"
				case text[i] === '\t':
					return '|'
				case t === 'dir':
					return '/'
				case t === 'path':
					return '/'
				case t === 'none' && a[i - 1] === 'dir':
					return '/'
				case t === 'none' && text[i] === ' ':
					return ' '
				case t === 'none' && text[i - 1] === ' ' && text[i] === ' ':
					return '+'
				case t === 'none':
					return '_'
				case t === 'syntax-meta':
					return text[i]
				case t === 'cmd':
					return 'C'
				case t === 'arg':
					return 'A'
				case t === 'arg-scope':
					return 'A'
				case t === 'arg-dot':
					return '.'
				case t === 'variable-parameter':
					return 'a'
				case t === 'variable-local':
					return 'v'
				case t === 'variable-global':
					return 'V'
				case t === 'variable-undefined':
					return 'u'
				case t === 'varname-local':
					return 'n'
				case t === 'varname-global':
					return 'N'
				case t === 'varname':
					return 'M'
				case t === 'ambiguous':
					return '*'
				case t === 'syntax-val':
					return 's'
				case t === 'syntax-obsolete':
					return 'O'
				case t === 'syntax-old':
					return 'o'
				case t === 'syntax-noterm':
					return '`'
				case t === 'escaped':
					return '\\'
				case t === 'comment':
					return '#'
				case t === 'obj-inactive':
					return 'I'
				case t === 'error':
					return 'E'
				default:
					return '?'
			}
		})
	}

	constructor(tokens: HighlightToken[], document: TextDocument, range?: Range) {
		log.info(`<HighlightToken> constructor() called ${document.uri}`)

		this.#tokens = tokens
		this.#document = document
		this.#tokenRanges = this.#getHighlightTokenRange()
		if (range) this.#startOffset = document.offsetAt(range?.start)
	}

	atPosition(position: Position): HighlightTokenRangeItem | undefined {
		if (this.#document.offsetAt(position) >= this.#tokens.length) {
			return undefined
		}
		const found = this.tokenRanges.find((tokenRange) => this.positionInRange(position, tokenRange.range))
		if (!found) {
			log.error(`ERROR <tokens> {atPosition} found no token ranges at position`)
		}
		return found
	}

	positionInRange(pos: Position, range: Range): boolean {
		const compare = (a: Position, b: Position): number => {
			if (a.line < b.line) return -1
			if (a.line > b.line) return 1
			if (a.character < b.character) return -1
			if (a.character > b.character) return 1
			return 0
		}
		return compare(pos, range.start) >= 0 && compare(pos, range.end) <= 0
	}

	#getHighlightTokenRange(): HighlightTokenRange {
		const result: HighlightTokenRange = []
		let i = 0 // + this.#startOffset;
		while (i < this.#tokens.length) {
			let end = i
			while (end + 1 < this.#tokens.length && this.#tokens[end + 1] === this.#tokens[i]) {
				end++
			}
			const item = {
				token: this.#tokens[i],
				range: { start: this.#document.positionAt(i + this.#startOffset), end: this.#document.positionAt(end + this.#startOffset) },
			}
			i = end + 1 // Move to the next distinct value
			result.push(item)
		}
		return result
	}

	// MARK: define token types
	static ErrorTokenTypes = ['variable-undefined', 'error', 'obj-inactive', 'syntax-obsolete', 'syntax-old', 'ambiguous']

	static TokenTypes = [
		'none',
		'dir',
		'cmd',
		'arg',
		'varname-local',
		'variable-parameter',
		'variable-local',
		'syntax-val',
		'varname',
		'syntax-meta',
		'escaped',
		'variable-global',
		'comment',
		'varname-global',
		'syntax-noterm',
	]

	static TokenModifiers = ['scope', 'dot', 'inactive', 'obsolete', 'undefined', 'ambiguous', 'legacy', 'error']

	static toSemanticToken(token: string): SemanticTokenLegendItem {
		switch (token) {
			case 'arg-scope':
				return { type: 'arg', modifiers: ['scope'] }
			case 'arg-dot':
				return { type: 'arg', modifiers: ['dot'] }
			case 'obj-inactive':
				return { type: 'syntax-val', modifiers: ['inactive'] }
			case 'syntax-obsolete':
				return { type: 'syntax-val', modifiers: ['obsolete'] }
			case 'variable-undefined':
				return { type: 'varname', modifiers: ['undefined'] }
			case 'ambiguous':
				return { type: 'syntax-val', modifiers: ['ambiguous'] }
			case 'syntax-old':
				return { type: 'syntax-val', modifiers: ['legacy'] }
			case 'error':
				return { type: 'syntax-val', modifiers: ['error'] }
			default:
				return { type: token, modifiers: [] }
		}
	}

	static getTokenTypeIndex(token: string): number {
		const semantic = HighlightTokens.toSemanticToken(token)
		return HighlightTokens.TokenTypes.indexOf(semantic.type)
	}

	static getTokenModifierMask(token: string): number {
		const semantic = HighlightTokens.toSemanticToken(token)
		let mask = 0
		for (const modifier of semantic.modifiers) {
			const index = HighlightTokens.TokenModifiers.indexOf(modifier)
			if (index >= 0) {
				mask = mask | (1 << index)
			}
		}
		return mask
	}
}
