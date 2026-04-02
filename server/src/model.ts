import { type Diagnostic, DiagnosticSeverity } from 'vscode-languageserver'
import type { Position, Range, TextDocument } from 'vscode-languageserver-textdocument'
import { RouterRestClient } from './routeros'
import { log, ROUTEROS_API_MAX_BYTES } from './shared'
import { HighlightTokens } from './tokens'

export class LspDocument {
	#document: TextDocument
	#highlightTokens: Promise<HighlightTokens>

	get uri() {
		return this.#document.uri
	}

	get highlightTokens() {
		const start = Date.now()
		log.debug(`<lspdoc> {get highlightTokens} started for ${this.uri}`)
		this.#highlightTokens.then((_) => {
			log.debug(`<lspdoc> {get highlightTokens} done in ${Date.now() - start}ms for ${this.uri}`)
		})
		return this.#highlightTokens
	}

	get document() {
		return this.#document
	}

	offsetAt(position: Position) {
		return this.#document.offsetAt(position)
	}

	positionAt(offset: number) {
		return this.#document.positionAt(offset)
	}

	constructor(document: TextDocument) {
		this.#document = document
		this.#highlightTokens = this.#fetchHighlightTokens()
		log.debug(`<lspdoc> {constructor} finished ${this.uri}`)
	}

	refresh() {
		this.#highlightTokens = this.#fetchHighlightTokens()
	}

	async completion(position: Position) {
		log.debug(`<lspdoc> {completion} called ${this.uri} at ln ${position.line} col ${position.character}`)
		return RouterRestClient.default.inspectCompletion(this.#document.getText().substring(0, this.#document.offsetAt(position)))
	}

	// MARK: diagnostics

	async diagnostics(): Promise<Diagnostic[]> {
		log.debug(`<lspdoc> {diagnostics} called: ${this.uri}`)

		const tokens = await this.highlightTokens
		const tokenRanges = tokens.tokenRanges
		const errors: Diagnostic[] = tokenRanges
			.filter((tokenRange) => HighlightTokens.ErrorTokenTypes.includes(tokenRange.token))
			.map((tokenRange) => {
				return {
					severity: DiagnosticSeverity.Error,
					range: tokenRange.range,
					message: `Script error from highlight '${tokenRange.token}'`,
					code: `token:${tokenRange.token}`,
					source: 'routeroslsp',
				}
			})

		if (errors.length > 0) {
			const lastError = errors[errors.length - 1]
			const nextPosition = this.positionAt(this.offsetAt(lastError.range.end) + 1)
			const endPosition = this.positionAt(tokens.tokens.length - 1)
			if (nextPosition.line >= endPosition.line) {
				return errors
			}
			return [
				...errors,
				{
					severity: DiagnosticSeverity.Warning,
					range: { start: nextPosition, end: endPosition },
					message: 'Potential issues due to prior highlight error',
					code: 'token:unchecked',
					source: 'routeroslsp',
				},
			]
		}

		const text = this.#document.getText()
		if (text.length >= ROUTEROS_API_MAX_BYTES + 1) {
			errors.push({
				severity: DiagnosticSeverity.Warning,
				range: {
					start: this.positionAt(ROUTEROS_API_MAX_BYTES + 1),
					end: this.positionAt(text.length - 2),
				},
				message: 'Too long, only first 32K will be checked',
				code: 'token:toolong',
				source: 'routeroslsp',
			})
		}

		log.info(`<lspdoc> {diagnostics} done, found ${errors.length} for ${this.uri}`)
		return errors
	}

	async #fetchHighlightTokens(range?: Range): Promise<HighlightTokens> {
		log.info(`<lspdoc> {#fetchHighlightTokens} started for ${this.uri}`)

		let text = this.#document.getText()
		if (range) {
			text = text.substring(this.#document.offsetAt(range.start))
		}
		const highlightInspectResponse = await RouterRestClient.default.inspectHighlight(text.substring(0, ROUTEROS_API_MAX_BYTES))
		const parsedToken = highlightInspectResponse?.[0]?.highlight.split(',')
		log.info('<lspdoc> {#fetchHighlightTokens} got new tokens')

		return new HighlightTokens(parsedToken || [], this.#document, range)
	}
}
