import { afterEach, beforeEach, describe, expect, it } from 'bun:test'
import type { ExecuteCommandParams } from 'vscode-languageserver'
import { clearConnectionUrl, defaultSettings, getConnectionUrl, getEnvironmentSettings, getSettings, isUsingClientCredentials, toEnvVariableName, updateSettings, useConnectionUrl } from './shared'

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

	it('accepts partial settings updates', () => {
		const changed = updateSettings({ baseUrl: 'http://10.0.0.3' })
		expect(changed).toBe(true)
		expect(getSettings().baseUrl).toBe('http://10.0.0.3')
		expect(getSettings().username).toBe(defaultSettings.username)
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

	it('applies checkCertificates boolean updates', () => {
		updateSettings({ checkCertificates: true })
		expect(getSettings().checkCertificates).toBe(true)
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

	it('getSettings reflects client-provided checkCertificates', () => {
		useConnectionUrl({
			command: 'useConnectionUrl',
			arguments: ['tikbook', 'http://10.0.0.1', 'admin', 'pass', 25, true],
		})
		expect(getSettings().checkCertificates).toBe(true)
	})

	it('getSettings applies explicit false for client-provided checkCertificates', () => {
		updateSettings({ checkCertificates: true })
		useConnectionUrl({
			command: 'useConnectionUrl',
			arguments: ['tikbook', 'http://10.0.0.1', 'admin', 'pass', 25, false],
		})
		expect(getSettings().checkCertificates).toBe(false)
	})
})

describe('environment settings', () => {
	it('maps setting names to stable env names', () => {
		expect(toEnvVariableName('routeroslsp.baseUrl')).toBe('ROUTEROSLSP_BASE_URL')
		expect(toEnvVariableName('routeroslsp.allowClientProvidedCredentials')).toBe('ROUTEROSLSP_ALLOW_CLIENT_PROVIDED_CREDENTIALS')
	})

	it('parses string, number, and boolean env values', () => {
		const envSettings = getEnvironmentSettings({
			ROUTEROSLSP_BASE_URL: 'http://10.0.0.2',
			ROUTEROSLSP_USERNAME: 'env-user',
			ROUTEROSLSP_PASSWORD: 'env-pass',
			ROUTEROSLSP_API_TIMEOUT: '30',
			ROUTEROSLSP_ALLOW_CLIENT_PROVIDED_CREDENTIALS: 'false',
			ROUTEROSLSP_CHECK_CERTIFICATES: 'true',
		})
		expect(envSettings).toEqual({
			baseUrl: 'http://10.0.0.2',
			username: 'env-user',
			password: 'env-pass',
			apiTimeout: 30,
			allowClientProvidedCredentials: false,
			checkCertificates: true,
		})
	})

	it('ignores invalid boolean and number env values', () => {
		const envSettings = getEnvironmentSettings({
			ROUTEROSLSP_API_TIMEOUT: 'not-a-number',
			ROUTEROSLSP_CHECK_CERTIFICATES: 'maybe',
		})
		expect(envSettings).toEqual({})
	})
})
