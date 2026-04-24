import { type Diagnostic, DiagnosticSeverity } from 'vscode-languageserver'
import { type Range, TextDocument } from 'vscode-languageserver-textdocument'
import { type HighlightInspectResponseItem, normalizeError, type RouterOSClientError } from './routeros'
import { log, ROUTEROS_API_MAX_BYTES } from './shared'
import { HighlightTokens } from './tokens'

type HighlightInspector = (input: string, path?: string) => Promise<HighlightInspectResponseItem[] | undefined>

export interface RouterScriptValidationResult {
	ok: boolean
	message: string
	diagnostics: Diagnostic[]
	truncated: boolean
	checkedBytes: number
	error?: RouterOSClientError
}

export async function inspectHighlightTokensForDocument(
	document: TextDocument,
	inspectHighlight: HighlightInspector,
	range?: Range,
): Promise<{ response?: HighlightInspectResponseItem[]; tokens: HighlightTokens }> {
	log.info(`<validation> {inspectHighlightTokensForDocument} started for ${document.uri}`)

	let text = document.getText()
	if (range) {
		text = text.substring(document.offsetAt(range.start))
	}
	const response = await inspectHighlight(text.substring(0, ROUTEROS_API_MAX_BYTES))
	const parsedTokens = response?.[0]?.highlight.split(',')
	log.info('<validation> {inspectHighlightTokensForDocument} got new tokens')

	return {
		response,
		tokens: new HighlightTokens(parsedTokens || [], document, range),
	}
}

export function buildDiagnosticsFromTokens(document: TextDocument, tokens: HighlightTokens): Diagnostic[] {
	const tokenRanges = tokens.tokenRanges
	const diagnostics: Diagnostic[] = tokenRanges
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

	if (diagnostics.length > 0) {
		const lastError = diagnostics[diagnostics.length - 1]
		const nextPosition = document.positionAt(document.offsetAt(lastError.range.end) + 1)
		const endPosition = document.positionAt(tokens.tokens.length - 1)
		if (nextPosition.line < endPosition.line) {
			diagnostics.push({
				severity: DiagnosticSeverity.Warning,
				range: { start: nextPosition, end: endPosition },
				message: 'Potential issues due to prior highlight error',
				code: 'token:unchecked',
				source: 'routeroslsp',
			})
		}
	}

	const text = document.getText()
	if (text.length >= ROUTEROS_API_MAX_BYTES + 1) {
		diagnostics.push({
			severity: DiagnosticSeverity.Warning,
			range: {
				start: document.positionAt(ROUTEROS_API_MAX_BYTES + 1),
				end: document.positionAt(text.length - 2),
			},
			message: 'Too long, only first 32K will be checked',
			code: 'token:toolong',
			source: 'routeroslsp',
		})
	}

	return diagnostics
}

export async function validateScriptText(script: string, inspectHighlight: HighlightInspector, uri = 'routeroslsp://command/validate.rsc'): Promise<RouterScriptValidationResult> {
	const document = TextDocument.create(uri, 'routeros', 1, script)
	try {
		const { response, tokens } = await inspectHighlightTokensForDocument(document, inspectHighlight)
		if (!response) {
			return {
				ok: false,
				message: 'Validation failed: RouterOS did not return highlight data',
				diagnostics: [],
				truncated: script.length > ROUTEROS_API_MAX_BYTES,
				checkedBytes: Math.min(script.length, ROUTEROS_API_MAX_BYTES),
			}
		}

		const diagnostics = buildDiagnosticsFromTokens(document, tokens)
		return {
			ok: diagnostics.length === 0,
			message: diagnostics.length === 0 ? 'Validation passed' : `Validation failed with ${diagnostics.length} diagnostic(s)`,
			diagnostics,
			truncated: script.length > ROUTEROS_API_MAX_BYTES,
			checkedBytes: Math.min(script.length, ROUTEROS_API_MAX_BYTES),
		}
	} catch (error) {
		const normalized = normalizeError(error)
		return {
			ok: false,
			message: `Validation failed: ${normalized.message}`,
			diagnostics: [],
			truncated: script.length > ROUTEROS_API_MAX_BYTES,
			checkedBytes: Math.min(script.length, ROUTEROS_API_MAX_BYTES),
			error: normalized,
		}
	}
}
