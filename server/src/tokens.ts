import type { Position, Range, TextDocument } from 'vscode-languageserver-textdocument'
import { log } from './shared'

type HighlightToken = string
type HighlightTokenRange = HighlightTokenRangeItem[]
interface HighlightTokenRangeItem {
	token: HighlightToken
	range: Range
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
		// this.tokenRange(this.atPosition(position));
		if (this.#document.offsetAt(position) >= this.#tokens.length) {
			return undefined
		}
		let foundRange: HighlightTokenRangeItem | undefined
		this.tokenRanges.forEach((tokenRange) => {
			if (this.positionInRange(position, tokenRange.range)) {
				foundRange = tokenRange
				return
			}
		})
		if (foundRange === undefined) {
			log.error(`ERROR <tokens> {atPosition} found no token ranges at position`)
		}
		return foundRange
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
		'obj-inactive',
		'syntax-obsolete',
		'variable-undefined',
		'ambiguous',
		'syntax-old',
		'error',
		'varname-global',
		'syntax-noterm',
	]
}
