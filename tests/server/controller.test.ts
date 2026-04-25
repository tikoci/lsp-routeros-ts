import { describe, expect, it } from 'bun:test'
import type { InitializeParams } from 'vscode-languageserver'
import { LspController, parseRouterScriptCommandRequest } from '../../server/src/controller'
import { HighlightTokens } from '../../server/src/tokens'

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

	it('includes semanticTokensProvider with TokenTypes and TokenModifiers legends', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		const legend = caps.semanticTokensProvider as { legend: { tokenTypes: string[]; tokenModifiers: string[] } }
		expect(legend.legend.tokenTypes).toEqual(HighlightTokens.TokenTypes)
		expect(legend.legend.tokenModifiers).toEqual(HighlightTokens.TokenModifiers)
	})

	it('includes executeCommandProvider with 8 commands', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toHaveLength(8)
	})

	it('execute commands include sendSemanticTokensRefresh', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toContain('routeroslsp.server.sendSemanticTokensRefresh')
	})

	it('execute commands include router.getIdentity', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		expect(caps.executeCommandProvider?.commands).toContain('routeroslsp.server.router.getIdentity')
	})

	it('execute commands include router.validateScript and router.executeScript', () => {
		const caps = LspController.getServerCapabilities(minimalParams)
		const cmds = caps.executeCommandProvider?.commands
		expect(cmds).toContain('routeroslsp.server.router.validateScript')
		expect(cmds).toContain('routeroslsp.server.router.executeScript')
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

// MARK: parseRouterScriptCommandRequest

const validRequest = {
	baseUrl: 'http://192.168.88.1:8728',
	username: 'admin',
	password: 'secret',
	script: '/ip print',
}

describe('parseRouterScriptCommandRequest — valid input', () => {
	it('returns ok:true for a well-formed request', () => {
		const result = parseRouterScriptCommandRequest(validRequest)
		expect(result.ok).toBe(true)
	})

	it('includes sanitized baseUrl (no credentials) in connection', () => {
		const result = parseRouterScriptCommandRequest(validRequest)
		if (!result.ok) throw new Error('expected ok')
		expect(result.connection.baseUrl).toBe('http://192.168.88.1:8728')
		expect(result.connection.baseUrl).not.toContain('@')
	})

	it('includes username and password in connection', () => {
		const result = parseRouterScriptCommandRequest(validRequest)
		if (!result.ok) throw new Error('expected ok')
		expect(result.connection.username).toBe('admin')
		expect(result.connection.password).toBe('secret')
	})

	it('passes the script through unchanged', () => {
		const result = parseRouterScriptCommandRequest(validRequest)
		if (!result.ok) throw new Error('expected ok')
		expect(result.script).toBe('/ip print')
	})

	it('uses default apiTimeout when not provided', () => {
		const result = parseRouterScriptCommandRequest(validRequest)
		if (!result.ok) throw new Error('expected ok')
		expect(typeof result.connection.apiTimeout).toBe('number')
	})

	it('accepts optional apiTimeout and checkCertificates', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, apiTimeout: 30, checkCertificates: true })
		if (!result.ok) throw new Error('expected ok')
		expect(result.connection.apiTimeout).toBe(30)
		expect(result.connection.checkCertificates).toBe(true)
	})
})

describe('parseRouterScriptCommandRequest — invalid input', () => {
	it('rejects null/undefined', () => {
		expect(parseRouterScriptCommandRequest(null).ok).toBe(false)
		expect(parseRouterScriptCommandRequest(undefined).ok).toBe(false)
	})

	it('rejects an array', () => {
		expect(parseRouterScriptCommandRequest([validRequest]).ok).toBe(false)
	})

	it('rejects missing baseUrl', () => {
		const { baseUrl: _, ...rest } = validRequest
		const result = parseRouterScriptCommandRequest(rest)
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('baseUrl')
	})

	it('rejects missing username', () => {
		const { username: _, ...rest } = validRequest
		const result = parseRouterScriptCommandRequest(rest)
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('username')
	})

	it('rejects empty password', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, password: '' })
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('password')
	})

	it('rejects empty script', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, script: '   ' })
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('script')
	})

	it('rejects URL without explicit port', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, baseUrl: 'http://192.168.88.1' })
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('port')
	})

	it('accepts URL with default HTTP port written explicitly', () => {
		// URL parser strips default port 80, but we check the raw string
		const result = parseRouterScriptCommandRequest({ ...validRequest, baseUrl: 'http://192.168.88.1:80' })
		expect(result.ok).toBe(true)
	})

	it('rejects URL with embedded credentials', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, baseUrl: 'http://admin:pass@192.168.88.1:80' })
		expect(result.ok).toBe(false)
		if (!result.ok) expect(result.message).toContain('credentials')
	})

	it('rejects a non-URL baseUrl string', () => {
		const result = parseRouterScriptCommandRequest({ ...validRequest, baseUrl: 'not-a-url' })
		expect(result.ok).toBe(false)
	})
})
