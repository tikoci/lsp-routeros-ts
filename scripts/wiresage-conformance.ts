/** Import only the pinned, MIT-licensed conformance inputs and observations. */
import { mkdirSync, readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs'
import { dirname, join, relative, sep } from 'node:path'
import { createHash } from 'node:crypto'
import type { Database } from 'bun:sqlite'
import { hash } from './corpus-evidence'

export const WIRESAGE_REVISION = 'a3a646fa3e7fb07f3a2733405cfb84f75871f7bb'
export const WIRESAGE_COLLECTION = 'wiresage-conformance'
export const WIRESAGE_ORACLE = 'RouterOS 7.21.4 /import verbose=yes dry-run (upstream-reported, not reproduced here)'
export const WIRESAGE_CASES_SHA256 = '10b14030dcc02c18295e0b3f4e797017822f45dc47195d5b18d0486f92819be8'
export const WIRESAGE_LICENSE_SHA256 = '9bfd50e99e94d5907f0426e3ac29054b8240ef82e5e0690df57f815a3bc50774'
export const WIRESAGE_RAW_BASE = `https://raw.githubusercontent.com/wiresage/routeros-lsp/${WIRESAGE_REVISION}`

function checksum(bytes: ArrayLike<number>): string {
	return createHash('sha256').update(Uint8Array.from(bytes)).digest('hex')
}

export interface WiresageCase {
	id: string
	section: string
	source: string
	valid: boolean
	[key: string]: unknown
}

/** Section + ID is the upstream identity: 31 IDs occur in different sections. */
export function conformanceCases(bytes: ArrayLike<number>): Array<{ path: string; index: number; upstream: WiresageCase }> {
	const value: unknown = JSON.parse(Buffer.from(Uint8Array.from(bytes)).toString('utf8'))
	if (!Array.isArray(value) || value.length === 0) throw new Error('Expected a nonempty conformance array')
	const paths = new Set<string>()
	return value.map((row: unknown, index) => {
		if (!row || typeof row !== 'object' || Array.isArray(row)) throw new Error(`Invalid conformance case at ${index}`)
		const item = row as WiresageCase
		if (typeof item.id !== 'string' || !/^[a-z0-9_-]+$/.test(item.id) || typeof item.section !== 'string' || typeof item.source !== 'string' || typeof item.valid !== 'boolean')
			throw new Error(`Invalid conformance fields at ${index}`)
		const section = item.section
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, '-')
			.replace(/^-|-$/g, '')
		const path = `${section}/${item.id}.rsc`
		if (!section || paths.has(path)) throw new Error(`Duplicate or unsafe conformance path: ${path}`)
		paths.add(path)
		return { path, index, upstream: item }
	})
}

export function conformanceFiles(casesBytes: ArrayLike<number>, licenseBytes: ArrayLike<number>): Map<string, Buffer> {
	if (checksum(casesBytes) !== WIRESAGE_CASES_SHA256 || checksum(licenseBytes) !== WIRESAGE_LICENSE_SHA256) throw new Error('Pinned upstream conformance/license checksum mismatch')
	const rows = conformanceCases(casesBytes)
	const files = new Map<string, Buffer>([
		['upstream-cases.json', Buffer.from(Uint8Array.from(casesBytes))],
		['LICENSE', Buffer.from(Uint8Array.from(licenseBytes))],
	])
	const cases: Record<string, unknown> = {}
	for (const { path, index, upstream } of rows) {
		const source = Buffer.from(upstream.source, 'utf8')
		files.set(path, source)
		cases[path] = { upstreamId: upstream.id, upstreamSection: upstream.section, upstreamIndex: index, upstreamValid: upstream.valid, sourceSha256: checksum(source), sourceBytes: source.length }
	}
	files.set(
		'manifest.json',
		Buffer.from(
			`${JSON.stringify(
				{
					format: 1,
					collection: WIRESAGE_COLLECTION,
					upstreamRepository: 'https://github.com/wiresage/routeros-lsp',
					upstreamRevision: WIRESAGE_REVISION,
					upstreamSource: `${WIRESAGE_RAW_BASE}/tests/conformance/cases.json`,
					upstreamCasesSha256: WIRESAGE_CASES_SHA256,
					upstreamLicenseSha256: WIRESAGE_LICENSE_SHA256,
					upstreamOracle: WIRESAGE_ORACLE,
					labelSemantics: 'Third-party observation in a different execution context; never a local acceptance oracle.',
					cases,
				},
				null,
				2,
			)}\n`,
		),
	)
	return files
}

export function writeConformanceCollection(destination: string, files: Map<string, Buffer>): void {
	// Refuse unexpected cases rather than silently deleting derived research.
	function check(directory: string): void {
		if (!existsSync(directory)) return
		for (const entry of readdirSync(directory, { withFileTypes: true })) {
			const path = join(directory, entry.name)
			if (entry.isDirectory()) check(path)
			else if (entry.name.endsWith('.rsc') && !files.has(relative(destination, path).split(sep).join('/'))) throw new Error(`Unexpected case: ${path}`)
		}
	}
	check(destination)
	for (const [path, bytes] of files) {
		const output = join(destination, path)
		mkdirSync(dirname(output), { recursive: true })
		writeFileSync(output, Uint8Array.from(bytes))
	}
}

/** Verify tracked byte-exact inputs before indexing the third-party labels. */
export function importConformanceCases(db: Database, files: string[], dataDir: string): void {
	const directory = join(dataDir, WIRESAGE_COLLECTION)
	const tracked = new Set(files)
	const casesPath = join(directory, 'upstream-cases.json')
	if (!tracked.has(casesPath)) {
		if (files.some((path) => path.startsWith(`${directory}${sep}`))) throw new Error('Stage the raw upstream conformance cases')
		return
	}
	const casesBytes = readFileSync(casesPath)
	const licensePath = join(directory, 'LICENSE')
	if (!tracked.has(licensePath)) throw new Error('Stage the conformance license')
	const expected = conformanceFiles(casesBytes, readFileSync(licensePath))
	const expectedPaths = new Set([...expected.keys()].map((path) => join(directory, path)))
	for (const file of files) {
		if (file.startsWith(`${directory}${sep}`) && file.endsWith('.rsc') && !expectedPaths.has(file)) throw new Error(`Unexpected conformance case: ${file}`)
	}
	for (const [path, bytes] of expected) {
		const file = join(directory, path)
		if (!tracked.has(file) || !readFileSync(file).equals(Uint8Array.from(bytes))) throw new Error(`Untracked or modified conformance input: ${path}`)
	}
	const insert = db.prepare(`INSERT INTO third_party_cases
	(script_id,upstream_id,upstream_section,upstream_index,upstream_revision,upstream_source,upstream_oracle,upstream_valid,source_sha256,upstream_metadata_json)
	VALUES (?,?,?,?,?,?,?,?,?,?)`)
	for (const { path, index, upstream } of conformanceCases(casesBytes)) {
		const source = db.query('SELECT id,sha256,text FROM source_scripts WHERE path=?').get(`${WIRESAGE_COLLECTION}/${path}`) as { id: number; sha256: string; text: string }
		if (!source || source.sha256 !== hash(upstream.source) || source.text !== upstream.source) throw new Error(`Conformance source identity mismatch: ${path}`)
		const { source: _source, ...metadata } = upstream
		insert.run(
			source.id,
			upstream.id,
			upstream.section,
			index,
			WIRESAGE_REVISION,
			`${WIRESAGE_RAW_BASE}/tests/conformance/cases.json`,
			WIRESAGE_ORACLE,
			upstream.valid ? 1 : 0,
			source.sha256,
			JSON.stringify(metadata),
		)
	}
}
