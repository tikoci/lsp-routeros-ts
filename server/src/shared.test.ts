import { afterEach, beforeEach, describe, expect, it } from 'bun:test'
import type { ExecuteCommandParams } from 'vscode-languageserver'
import { clearConnectionUrl, defaultSettings, getConnectionUrl, getSettings, isUsingClientCredentials, updateSettings, useConnectionUrl } from './shared'

function makeUseConnectionUrlParams(extension: string, baseUrl: string, username: string, password: string): ExecuteCommandParams {
	return { command: 'useConnectionUrl', arguments: [extension, baseUrl, username, password] }
}

// Reset module-level state before each test
beforeEach(() => {
	clearConnectionUrl()
	// Restore defaults — only updates fields that differ from current state
	updateSettings({ ...defaultSettings, baseUrl: 'http://reset-sentinel.internal' })
	updateSettings(defaultSettings)
})

afterEach(() => {
	clearConnectionUrl()
})

describe('defaultSettings', () => {
	it('has expected baseUrl', () => {
		expect(defaultSettings.baseUrl).toBe('http://192.168.88.1')
	})

	it('has allowClientProvidedCredentials enabled by default', () => {
		expect(defaultSettings.allowClientProvidedCredentials).toBe(true)
	})

	it('has checkCertificates disabled by default', () => {
		expect(defaultSettings.checkCertificates).toBe(false)
	})
})

describe('getSettings', () => {
	it('returns default baseUrl after reset', () => {
		const s = getSettings()
		expect(s.baseUrl).toBe('http://192.168.88.1')
	})

	it('returns default username', () => {
		expect(getSettings().username).toBe('lsp')
	})

	it('reflects updated baseUrl', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://10.0.0.1' })
		expect(getSettings().baseUrl).toBe('http://10.0.0.1')
	})
})

describe('updateSettings', () => {
	it('returns true when a value changes', () => {
		const changed = updateSettings({ ...defaultSettings, baseUrl: 'http://10.0.0.2' })
		expect(changed).toBe(true)
	})

	it('returns false when all values are the same', () => {
		const unchanged = updateSettings(defaultSettings)
		expect(unchanged).toBe(false)
	})

	it('does not update to an empty string', () => {
		// empty string is falsy — update should be ignored
		const before = getSettings().username
		updateSettings({ ...defaultSettings, username: '' as unknown as string })
		expect(getSettings().username).toBe(before)
	})

	it('does not update baseUrl to the same value', () => {
		const before = getSettings().baseUrl
		updateSettings({ ...defaultSettings, baseUrl: before })
		expect(getSettings().baseUrl).toBe(before)
	})
})

describe('getConnectionUrl', () => {
	it('returns a URL object when baseUrl is valid', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://192.168.1.1' })
		const url = getConnectionUrl()
		expect(url).not.toBeNull()
		expect(url?.hostname).toBe('192.168.1.1')
	})

	it('parses port from baseUrl', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://192.168.1.1:8729' })
		const url = getConnectionUrl()
		expect(url?.port).toBe('8729')
	})

	it('includes username when withUsername is true', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://192.168.1.1', username: 'admin' })
		const url = getConnectionUrl(true)
		expect(url?.username).toBe('admin')
	})

	it('omits username when withUsername is false (default)', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://192.168.1.1', username: 'admin' })
		const url = getConnectionUrl()
		expect(url?.username).toBe('')
	})
})

describe('useConnectionUrl / isUsingClientCredentials / clearConnectionUrl', () => {
	it('isUsingClientCredentials returns false initially', () => {
		expect(isUsingClientCredentials()).toBe(false)
	})

	it('isUsingClientCredentials returns true after useConnectionUrl', () => {
		useConnectionUrl(makeUseConnectionUrlParams('tikbook', 'http://10.0.0.1', 'admin', 'pass'))
		expect(isUsingClientCredentials()).toBe(true)
	})

	it('getSettings reflects client-provided URL', () => {
		useConnectionUrl(makeUseConnectionUrlParams('tikbook', 'http://10.0.0.1', 'admin', 'pass'))
		expect(getSettings().baseUrl).toBe('http://10.0.0.1')
	})

	it('clearConnectionUrl resets client credentials', () => {
		useConnectionUrl(makeUseConnectionUrlParams('tikbook', 'http://10.0.0.1', 'admin', 'pass'))
		clearConnectionUrl()
		expect(isUsingClientCredentials()).toBe(false)
	})

	it('clearConnectionUrl restores base settings URL', () => {
		updateSettings({ ...defaultSettings, baseUrl: 'http://192.168.2.1' })
		useConnectionUrl(makeUseConnectionUrlParams('tikbook', 'http://10.0.0.1', 'admin', 'pass'))
		clearConnectionUrl()
		expect(getSettings().baseUrl).toBe('http://192.168.2.1')
	})
})
