import { describe, expect, it } from 'bun:test'
import type { InitializeParams } from 'vscode-languageserver'
import { LspController } from './controller'
import { HighlightTokens } from './tokens'

const minimalParams: InitializeParams = {
	processId: null,
	rootUri: null,
	capabilities: {},
}

const fullParams: InitializeParams = {
	processId: null,
	rootUri: null,
	capabilities: {
		workspace: {
			configuration: true,
			workspaceFolders: true,
		},
		textDocument: {
			publishDiagnostics: {
				relatedInformation: true,
			},
		},
		window: {
			showMessage: { messageActionItem: { additionalPropertiesSupport: true } },
		},
	},
}

describe('LspController.shortid', () => {
	it('is routeroslsp', () => {
		expect(LspController.shortid).toBe('routeroslsp')
	})
})

describe('LspController.getServerCapabilities', () => {
	it('includes textDocumentSync Full', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		// TextDocumentSyncKind.Full === 1
		expect(caps.textDocumentSync).toBe(1)
	})

	it('includes hoverProvider', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.hoverProvider).toBe(true)
	})

	it('includes documentSymbolProvider', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.documentSymbolProvider).toBe(true)
	})

	it('includes completionProvider', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.completionProvider).toBeDefined()
	})

	it('includes semanticTokensProvider with TokenTypes legend', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		const legend = caps.semanticTokensProvider as { legend: { tokenTypes: string[] } }
		expect(legend.legend.tokenTypes).toEqual(HighlightTokens.TokenTypes)
	})

	it('includes executeCommandProvider with 6 commands', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toHaveLength(6)
	})

	it('execute commands include sendSemanticTokensRefresh', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toContain('routeroslsp.server.sendSemanticTokensRefresh')
	})

	it('execute commands include router.getIdentity', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toContain('routeroslsp.server.router.getIdentity')
	})

	it('execute commands include useConnectionUrl and clearConnectionUrl', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		const cmds = caps.executeCommandProvider?.commands
		expect(cmds).toContain('routeroslsp.server.useConnectionUrl')
		expect(cmds).toContain('routeroslsp.server.clearConnectionUrl')
	})

	it('diagnosticsProvider is defined', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.diagnosticProvider).toBeDefined()
	})

	it('returns same shape for minimal and full params', () => {
		const min = LspController.getServerCapabilities(minimalParams)
		const full = LspController.getServerCapabilities(fullParams)
		// Core structure should match
		expect(Object.keys(min)).toEqual(Object.keys(full))
	})
})

describe('LspController.hasCapability', () => {
	it('returns false for unknown capability names', () => {
		expect(LspController.hasCapability('nonexistent', minimalParams)).toBe(false)
	})

	it('returns false for configuration when not present in params', () => {
		expect(LspController.hasCapability('configuration', minimalParams)).toBe(false)
	})

	it('returns true for configuration when present in params', () => {
		expect(LspController.hasCapability('configuration', fullParams)).toBe(true)
	})

	it('returns true for workspaceFolders when present in params', () => {
		expect(LspController.hasCapability('workspaceFolders', fullParams)).toBe(true)
	})

	it('returns true for diagnosticsRelatedInformation when present in params', () => {
		expect(LspController.hasCapability('diagnosticsRelatedInformation', fullParams)).toBe(true)
	})
})
