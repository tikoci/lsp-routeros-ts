/**
 * Collect a version-tagged required-argument map by probing `{menu} add`
 * against a live CHR and parsing the resulting execute-time errors.
 *
 * Usage:
 *   bun run scripts/collect-required-args.ts
 *   bun run scripts/collect-required-args.ts --schema ../restraml/docs/7.22.1/deep-inspect.json
 *   bun run scripts/collect-required-args.ts --target /ip/firewall --limit 25
 *
 * Env:
 *   ROUTEROS_TEST_URL, ROUTEROS_TEST_USER, ROUTEROS_TEST_PASS
 *
 * Artifacts written to test-data/:
 *   required-args.v<routeros-version>.json
 *   required-args.v<routeros-version>.meta.json
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { createHash } from 'node:crypto'
import { join, relative, resolve } from 'node:path'

const CHR_URL = process.env.ROUTEROS_TEST_URL || 'http://127.0.0.1:9170'
const CHR_USER = process.env.ROUTEROS_TEST_USER || 'admin'
const CHR_PASS = process.env.ROUTEROS_TEST_PASS || ''
const TEST_DATA_DIR = resolve(import.meta.dir, '../test-data')
const REPO_ROOT = resolve(import.meta.dir, '..')
const DEFAULT_SCHEMA_ROOT = resolve(import.meta.dir, '../../restraml/docs')

interface CliArgs {
	limit: number
	target: string
	schemaPath: string
}

interface DeepInspectNode {
	[key: string]: DeepInspectNode | string | number | boolean | null | undefined
}

interface MenuProbe {
	path: string
	addArgNames: string[]
}

interface RequiredArgResult {
	path: string
	required: string[]
	hasAdd: boolean
	rawError: string
}

interface RequiredArgMeta {
	routerosVersion: string
	chrBuildTime: string
	schemaPath: string
	schemaSha256: string
	totalMenus: number
	requiredMenus: number
	okCount: number
	missingValueCount: number
	customRequiredCount: number
	badCommandCount: number
	probeErrorCount: number
	capturedAt: string
	target: string
	limit: number
}

type Classification = 'ok' | 'missing-values' | 'custom-required' | 'bad-command' | 'probe-error'

const auth = `Basic ${Buffer.from(`${CHR_USER}:${CHR_PASS}`).toString('base64')}`
const headers = { 'Content-Type': 'application/json', Authorization: auth }

function parseArgs(): CliArgs {
	const args = process.argv.slice(2)
	const limitIdx = args.indexOf('--limit')
	const targetIdx = args.indexOf('--target')
	const schemaIdx = args.indexOf('--schema')

	return {
		limit: limitIdx >= 0 ? Number.parseInt(args[limitIdx + 1] ?? '0', 10) : 0,
		target: targetIdx >= 0 ? (args[targetIdx + 1] ?? '') : '',
		schemaPath: schemaIdx >= 0 ? resolve(args[schemaIdx + 1] ?? '') : '',
	}
}

function sha256(text: string): string {
	return createHash('sha256').update(text).digest('hex')
}

function sortUnique(values: string[]): string[] {
	return [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b))
}

function stripExecutionContext(message: string): string {
	return message.replace(/\s+\([^)]*line \d+[^)]*\)\s*$/, '').trim()
}

function allMenusWithAdd(node: DeepInspectNode, path = '', out: MenuProbe[] = []): MenuProbe[] {
	if (!node || typeof node !== 'object' || Array.isArray(node)) return out
	const addNode = node.add
	if (addNode && typeof addNode === 'object' && !Array.isArray(addNode)) {
		out.push({
			path: path || '/',
			addArgNames: Object.keys(addNode).filter((key) => !key.startsWith('_')),
		})
	}

	for (const [key, value] of Object.entries(node)) {
		if (key.startsWith('_')) continue
		if (value && typeof value === 'object' && !Array.isArray(value)) {
			allMenusWithAdd(value as DeepInspectNode, `${path}/${key}`.replace(/\/+/g, '/'), out)
		}
	}

	return out
}

async function rest(path: string, body?: unknown): Promise<unknown> {
	const resp = await fetch(`${CHR_URL}${path}`, {
		method: body === undefined ? 'GET' : 'POST',
		headers,
		body: body === undefined ? undefined : JSON.stringify(body),
		signal: AbortSignal.timeout(120_000),
	})
	if (!resp.ok) throw new Error(`${path} → ${resp.status} ${resp.statusText}`)
	return resp.json()
}

async function chrVersion(): Promise<{ version: string; buildTime: string }> {
	const r = (await rest('/rest/system/resource')) as { version?: string; ['build-time']?: string }
	const version = (r.version ?? '').trim().split(/\s+/)[0] || 'unknown'
	return { version, buildTime: r['build-time'] ?? '' }
}

function defaultSchemaPath(routerosVersion: string): string {
	return resolve(DEFAULT_SCHEMA_ROOT, routerosVersion, 'deep-inspect.json')
}

function resolveSchemaPath(argSchemaPath: string, routerosVersion: string): string {
	const schemaPath = argSchemaPath || defaultSchemaPath(routerosVersion)
	if (!schemaPath || !existsSync(schemaPath)) {
		throw new Error(
			`deep-inspect.json not found for ${routerosVersion}; pass --schema <path> or add ${relative(REPO_ROOT, defaultSchemaPath(routerosVersion))}`,
		)
	}
	return schemaPath
}

function matchesExplicitArgName(message: string, argName: string): boolean {
	const text = stripExecutionContext(message)
	const tokenPattern = argName
		.split(/[.-]/)
		.map((part) => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
		.join('[-\\s]*')
	return new RegExp(`(^|[^a-z0-9-])${tokenPattern}($|[^a-z0-9-])`, 'i').test(text)
}

function extractMentionedArgs(message: string, addArgNames: string[]): string[] {
	const specialAliases = new Map<string, string[]>([
		['need at least one slave interface', ['slaves']],
		['no interfaces provided', ['interface']],
		['parent not found', ['interface']],
		['error adding adlist source', ['file', 'url']],
	])

	for (const [needle, candidates] of specialAliases) {
		if (!message.toLowerCase().includes(needle)) continue
		return addArgNames.filter((arg) => candidates.includes(arg))
	}

	return addArgNames.filter((arg) => matchesExplicitArgName(message, arg))
}

function parseCustomRequiredArgs(message: string, addArgNames: string[]): string[] {
	if (!message) return []
	const text = stripExecutionContext(message)
	if (/contact MikroTik support/i.test(text)) return []
	if (/already exists/i.test(text)) return []
	if (/not found/i.test(text) && !/must|need|required|empty|not set/i.test(text)) return []
	if (/invalid /i.test(text) && !/required|must|not set/i.test(text)) return []

	if (/At least one field specifying certificate name must be set!/i.test(text)) {
		return addArgNames.includes('name') ? ['name'] : []
	}

	const requirementish =
		/must specify exactly one of|must set either|must be present|is required|required|must be specified|must be configured|cannot be empty|is empty|not set|not specified|no .* provided|need at least one/i
	if (!requirementish.test(text)) return []

	return sortUnique(extractMentionedArgs(text, addArgNames))
}

function classifyResponse(ret: string, addArgNames: string[]): { required: string[]; hasAdd: boolean; kind: Classification } {
	if (/^\*/.test(ret)) return { required: [], hasAdd: true, kind: 'ok' }
	const stripped = stripExecutionContext(ret)
	const missingMatch = stripped.match(/missing value\(s\) of argument\(s\)\s+(.+)$/i)
	if (missingMatch) {
		return {
			required: sortUnique(missingMatch[1].trim().split(/\s+/)),
			hasAdd: true,
			kind: 'missing-values',
		}
	}
	if (/bad command name add/i.test(ret)) return { required: [], hasAdd: false, kind: 'bad-command' }

	const required = parseCustomRequiredArgs(ret, addArgNames)
	if (required.length > 0) return { required, hasAdd: true, kind: 'custom-required' }
	return { required: [], hasAdd: true, kind: 'probe-error' }
}

function probeScript(path: string): string {
	return `:local id [${path} add]; :put $id; ${path} remove $id`
}

async function probeMenu(menu: MenuProbe): Promise<{ result: RequiredArgResult; kind: Classification }> {
	const response = (await rest('/rest/execute', {
		script: probeScript(menu.path),
		'as-string': 'true',
	})) as { ret?: string }

	const rawError = String(response.ret ?? '')
	const classified = classifyResponse(rawError, menu.addArgNames)

	return {
		kind: classified.kind,
		result: {
			path: menu.path,
			required: classified.required,
			hasAdd: classified.hasAdd,
			rawError: classified.kind === 'ok' ? '' : rawError,
		},
	}
}

async function main() {
	const args = parseArgs()
	const { version, buildTime } = await chrVersion()
	const schemaPath = resolveSchemaPath(args.schemaPath, version)
	const schemaText = readFileSync(schemaPath, 'utf-8')
	const schema = JSON.parse(schemaText) as DeepInspectNode

	let menus = allMenusWithAdd(schema)
	if (args.target) menus = menus.filter((menu) => menu.path.includes(args.target))
	if (args.limit > 0) menus = menus.slice(0, args.limit)

	console.log(`CHR ${CHR_URL} → RouterOS ${version} (build ${buildTime})`)
	console.log(`Schema: ${relative(REPO_ROOT, schemaPath)}`)
	console.log(`Probing ${menus.length} add-capable menu path(s) …`)

	const results: RequiredArgResult[] = []
	const counts: Record<Classification, number> = {
		ok: 0,
		'missing-values': 0,
		'custom-required': 0,
		'bad-command': 0,
		'probe-error': 0,
	}

	for (const [index, menu] of menus.entries()) {
		const { result, kind } = await probeMenu(menu)
		results.push(result)
		counts[kind]++
		const detail =
			kind === 'ok'
				? 'no required args'
				: result.required.length > 0
					? result.required.join(', ')
					: result.rawError
		console.log(`  [${index + 1}/${menus.length}] ${kind.padEnd(15)} ${menu.path}  (${detail})`)
	}

	results.sort((a, b) => a.path.localeCompare(b.path))
	const capturedAt = new Date().toISOString()
	const summaryPath = join(TEST_DATA_DIR, `required-args.v${version}.json`)
	const metaPath = join(TEST_DATA_DIR, `required-args.v${version}.meta.json`)
	const summaryJson = `${JSON.stringify(results, null, 2)}\n`
	const meta: RequiredArgMeta = {
		routerosVersion: version,
		chrBuildTime: buildTime,
		schemaPath: relative(REPO_ROOT, schemaPath),
		schemaSha256: sha256(schemaText),
		totalMenus: menus.length,
		requiredMenus: results.filter((row) => row.required.length > 0).length,
		okCount: counts.ok,
		missingValueCount: counts['missing-values'],
		customRequiredCount: counts['custom-required'],
		badCommandCount: counts['bad-command'],
		probeErrorCount: counts['probe-error'],
		capturedAt,
		target: args.target,
		limit: args.limit,
	}

	writeFileSync(summaryPath, summaryJson, 'utf-8')
	writeFileSync(metaPath, `${JSON.stringify(meta, null, 2)}\n`, 'utf-8')

	console.log('')
	console.log(`Summary: ${results.length} menus`)
	console.log(`  ok=${counts.ok}  missing-values=${counts['missing-values']}  custom-required=${counts['custom-required']}`)
	console.log(`  bad-command=${counts['bad-command']}  probe-error=${counts['probe-error']}`)
	console.log(`  required paths=${meta.requiredMenus}`)
	console.log(`Artifacts written: ${relative(REPO_ROOT, summaryPath)}, ${relative(REPO_ROOT, metaPath)}`)
}

await main()
