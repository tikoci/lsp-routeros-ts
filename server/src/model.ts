import { type Diagnostic, DiagnosticSeverity, type Range } from 'vscode-languageserver'
import type { Position, TextDocument } from 'vscode-languageserver-textdocument'
import { LspController } from './controller'
import { RouterRestClient } from './routeros'
import { log } from './shared'
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
		// this.#text = this.#document.getText()
		// LspController.default.connection.languages.semanticTokens.refresh()
		log.debug(`<lspdoc> {constructor} finished ${this.uri}`)
	}

	dispose() {}

	refresh() {
		this.#highlightTokens = this.#fetchHighlightTokens()
	}

	static async create(document: TextDocument) {
		log.debug(`<lspdoc> {{create}} called ${document.uri}`)
		// const settings = await LspController.default.connection.workspace.getConfiguration({ section: LspController.shortid, scopeUri: document.uri })
		const cachedDoc = LspController.default.documents.get(document.uri)
		if (cachedDoc) {
			return new LspDocument(cachedDoc)
		} else {
			log.error(`ERROR <lspdoc> {create} found no document for ${document.uri}`)
			return null
		}
	}

	async completion(position: Position) {
		log.debug(`<lspdoc> {completion} called ${this.uri} at ln ${position.line} col ${position.character}`)

		return RouterRestClient.default.inspectCompletion(this.#document.getText().substring(0, this.#document.offsetAt(position)))
	}

	// MARK: diagnostics provider

	// TODO: should take diagnostic "type", refactor HighlightTokens = mess
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
			const endPostition = this.positionAt(tokens.tokens.length - 1)
			if (nextPosition.line >= endPostition.line) {
				return errors
			}
			return [
				...errors,
				{
					severity: DiagnosticSeverity.Warning,
					range: {
						start: nextPosition,
						end: endPostition,
					},
					message: 'Potential issues due to prior highlight error',
					code: 'token:unchecked',
					source: 'routeroslsp',
				},
			]
		}
		const text = this.#document.getText()
		if (text.length >= 32768) {
			errors.push({
				severity: DiagnosticSeverity.Warning,
				range: {
					start: this.positionAt(32768),
					end: this.positionAt(text.length - 2),
				},
				message: 'Too long, only first 32K will be checked',
				code: 'token:toolong',
				source: 'routeroslsp',
			})
		}
		/*
    // RegEx tokens as Hint at col 1 ln 1... not that useful other than example of hints
    // Token are shown onHover if interested
    if (tokens.regexToken) {
      errors.push({
        severity: DiagnosticSeverity.Hint,
        range: {
          start: this.positionAt(0),
          end: this.positionAt(1),
        },
        message: `Found ${tokens.regexToken.join('').length} "regex tokens".  See add'l info.`,
        code: 'token:regex:all}',
        source: 'routeroslsp',
        data: tokens.regexToken.join(''),
      })
    }
    */
		log.info(`<lspdoc> {diagnostics} done, found ${errors.length} for ${this.uri}`)
		return errors
	}

	async #fetchHighlightTokens(range?: Range): Promise<HighlightTokens> {
		log.info(`<lspdoc> {#fetchHighlightTokens} started for ${this.uri}`)

		let text = this.#document.getText()
		if (range) {
			text = text.substring(this.#document.offsetAt(range.start))
		}
		const highlightInspectResponse = await RouterRestClient.default.inspectHighlight(text.substring(0, 32767))
		const parsedToken = highlightInspectResponse?.[0]?.highlight.split(',')
		log.info('<lspdoc> {#fetchHighlightTokens} got new tokens')

		return new HighlightTokens(parsedToken || [], this.#document, range)
	}
}
