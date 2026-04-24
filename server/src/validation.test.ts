import { describe, expect, it } from 'bun:test'
import { ROUTEROS_API_MAX_BYTES } from './shared'
import { validateScriptText } from './validation'

describe('validateScriptText', () => {
	it('passes clean scripts with no diagnostics', async () => {
		const result = await validateScriptText('/ip print', async () => [{ highlight: 'dir,dir,dir,none,cmd,cmd,cmd,cmd,cmd', type: 'highlight' }])
		expect(result.ok).toBe(true)
		expect(result.diagnostics).toHaveLength(0)
		expect(result.message).toBe('Validation passed')
	})

	it('returns diagnostics for highlight error tokens', async () => {
		const result = await validateScriptText('bad', async () => [{ highlight: 'error,error,error', type: 'highlight' }])
		expect(result.ok).toBe(false)
		expect(result.diagnostics).toHaveLength(1)
		expect(result.diagnostics[0]?.code).toBe('token:error')
	})

	it('fails closed when RouterOS returns no highlight data', async () => {
		const result = await validateScriptText('/ip print', async () => undefined)
		expect(result.ok).toBe(false)
		expect(result.diagnostics).toHaveLength(0)
		expect(result.message).toContain('did not return highlight data')
	})

	it('surfaces RouterOS transport errors', async () => {
		const result = await validateScriptText('/ip print', async () => {
			throw new Error('boom')
		})
		expect(result.ok).toBe(false)
		expect(result.error?.message).toBe('boom')
		expect(result.message).toContain('boom')
	})
})

describe('validateScriptText — truncated and checkedBytes', () => {
	it('reports truncated=false and checkedBytes=script.length for short scripts', async () => {
		const script = '/ip print'
		const result = await validateScriptText(script, async () => [{ highlight: 'dir,dir,dir,none,cmd,cmd,cmd,cmd,cmd', type: 'highlight' }])
		expect(result.truncated).toBe(false)
		expect(result.checkedBytes).toBe(script.length)
	})

	it('reports truncated=true and checkedBytes=ROUTEROS_API_MAX_BYTES for over-limit scripts', async () => {
		const longScript = 'x'.repeat(ROUTEROS_API_MAX_BYTES + 100)
		const result = await validateScriptText(longScript, async () => [{ highlight: 'none', type: 'highlight' }])
		expect(result.truncated).toBe(true)
		expect(result.checkedBytes).toBe(ROUTEROS_API_MAX_BYTES)
	})

	it('reports truncated=true and checkedBytes=ROUTEROS_API_MAX_BYTES on transport error for over-limit scripts', async () => {
		const longScript = 'x'.repeat(ROUTEROS_API_MAX_BYTES + 100)
		const result = await validateScriptText(longScript, async () => {
			throw new Error('timeout')
		})
		expect(result.ok).toBe(false)
		expect(result.truncated).toBe(true)
		expect(result.checkedBytes).toBe(ROUTEROS_API_MAX_BYTES)
	})

	it('reports checkedBytes=0 when script is empty and response is undefined', async () => {
		const result = await validateScriptText('', async () => undefined)
		expect(result.checkedBytes).toBe(0)
	})
})
