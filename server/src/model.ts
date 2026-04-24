import type { Diagnostic } from 'vscode-languageserver'
import type { Position, Range, TextDocument } from 'vscode-languageserver-textdocument'
import { RouterRestClient } from './routeros'
import { log } from './shared'
import type { HighlightTokens } from './tokens'
import { buildDiagnosticsFromTokens, inspectHighlightTokensForDocument } from './validation'

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
		const diagnostics = buildDiagnosticsFromTokens(this.#document, tokens)
		log.info(`<lspdoc> {diagnostics} done, found ${diagnostics.length} for ${this.uri}`)
		return diagnostics
	}

	async #fetchHighlightTokens(range?: Range): Promise<HighlightTokens> {
		log.info(`<lspdoc> {#fetchHighlightTokens} started for ${this.uri}`)

		const { tokens } = await inspectHighlightTokensForDocument(this.#document, RouterRestClient.default.inspectHighlight, range)
		return tokens
	}
}
