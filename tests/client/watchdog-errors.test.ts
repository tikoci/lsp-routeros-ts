/**
 * Tests for watchdog error mapping functions.
 * These are pure functions extracted from watchdog.ts — no VSCode dependency.
 */
import { describe, expect, it } from 'bun:test'
import { getTextFromError, toErrorInfo } from '../../client/src/watchdog-errors'

// MARK: toErrorInfo

describe('toErrorInfo', () => {
	it('handles null', () => {
		const info = toErrorInfo(null)
		expect(info.code).toBe('UNKNOWN')
		expect(info.message).toContain('empty')
	})

	it('handles undefined', () => {
		const info = toErrorInfo(undefined)
		expect(info.code).toBe('UNKNOWN')
	})

	it('extracts fields from RouterOSClientError object', () => {
		const info = toErrorInfo({ code: 'ECONNREFUSED', message: 'connection refused', status: undefined })
		expect(info.code).toBe('ECONNREFUSED')
		expect(info.message).toBe('connection refused')
	})

	it('extracts HTTP status number', () => {
		const info = toErrorInfo({ code: 'ERR_BAD_REQUEST', message: 'bad', status: 401 })
		expect(info.status).toBe(401)
	})

	it('converts numeric code to string', () => {
		const info = toErrorInfo({ code: 42, message: 'numeric code' })
		expect(info.code).toBe('42')
	})

	it('handles plain string value', () => {
		const info = toErrorInfo('something broke')
		expect(info.message).toBe('something broke')
		expect(info.code).toBeUndefined()
	})

	it('handles number value', () => {
		const info = toErrorInfo(500)
		expect(info.message).toBe('500')
	})

	it('extracts name field from Error-like object', () => {
		const info = toErrorInfo({ name: 'TypeError', message: 'bad type' })
		expect(info.name).toBe('TypeError')
		expect(info.message).toBe('bad type')
	})

	it('ignores non-string/non-number fields gracefully', () => {
		const info = toErrorInfo({ code: true, message: ['not', 'a', 'string'], status: 'not a number' })
		expect(info.code).toBeUndefined()
		expect(info.message).toBeUndefined()
		expect(info.status).toBeUndefined()
	})
})

// MARK: getTextFromError

describe('getTextFromError', () => {
	const url = 'http://192.168.88.1'

	it('produces ECONNABORTED message', () => {
		const msg = getTextFromError({ code: 'ECONNABORTED', message: 'timeout' }, url, false)
		expect(msg).toContain('No response')
		expect(msg).toContain(url)
		expect(msg).toContain('ECONNABORTED')
	})

	it('produces HOSTDOWN message', () => {
		const msg = getTextFromError({ code: 'HOSTDOWN', message: 'host is down' }, url, false)
		expect(msg).toContain('HOSTDOWN')
		expect(msg).toContain(url)
	})

	it('produces ECONNREFUSED message', () => {
		const msg = getTextFromError({ code: 'ECONNREFUSED', message: 'connect refused' }, url, false)
		expect(msg).toContain('wrong port')
		expect(msg).toContain(url)
	})

	it('produces TLS cert error message', () => {
		const msg = getTextFromError({ code: 'ERR_TLS_CERT_ALTNAME_INVALID', message: 'cert mismatch' }, url, false)
		expect(msg).toContain('Check Certificates')
	})

	it('produces 401 unauthorized message', () => {
		const msg = getTextFromError({ code: 'ERR_BAD_REQUEST', message: 'bad', status: 401 }, url, false)
		expect(msg).toContain('Username or password')
		expect(msg).toContain('401')
	})

	it('produces 404 not found message', () => {
		const msg = getTextFromError({ code: 'ERR_BAD_REQUEST', message: 'not found', status: 404 }, url, false)
		expect(msg).toContain('hostname is wrong')
		expect(msg).toContain('404')
	})

	it('produces generic HTTP status message for other status codes', () => {
		const msg = getTextFromError({ code: 'ERR_BAD_REQUEST', message: 'server error', status: 500 }, url, false)
		expect(msg).toContain('500')
		expect(msg).toContain(url)
	})

	it('produces ERR_BAD_REQUEST without status message', () => {
		const msg = getTextFromError({ code: 'ERR_BAD_REQUEST', message: 'bad request' }, url, false)
		expect(msg).toContain('bad request')
		expect(msg).toContain('ERR_BAD_REQUEST')
	})

	it('produces generic code+message for unknown error codes', () => {
		const msg = getTextFromError({ code: 'ESOMETHING', message: 'weird error' }, url, false)
		expect(msg).toContain('weird error')
		expect(msg).toContain('ESOMETHING')
	})

	it('falls back to message+name when code is absent', () => {
		const msg = getTextFromError({ message: 'oops', name: 'SomeError' }, url, false)
		expect(msg).toContain('oops')
		expect(msg).toContain('SomeError')
	})

	it('uses TikBook prefix when isUsingClientCredentials is true', () => {
		const msg = getTextFromError({ code: 'ECONNREFUSED', message: 'refused' }, url, true)
		expect(msg).toContain('TikBook credentials')
	})

	it('uses default prefix when isUsingClientCredentials is false', () => {
		const msg = getTextFromError({ code: 'ECONNREFUSED', message: 'refused' }, url, false)
		expect(msg).toStartWith('Router LSP not working:')
	})

	it('handles null displayConnectionUrl', () => {
		const msg = getTextFromError({ code: 'ECONNABORTED', message: 'timeout' }, null, false)
		expect(msg).toContain('null')
	})
})
