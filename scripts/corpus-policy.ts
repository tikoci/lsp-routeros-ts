import { readFileSync } from 'node:fs'
import { relative } from 'node:path'
import type { Database } from 'bun:sqlite'

export const CHANNELS = ['long-term', 'stable', 'testing', 'development'] as const
export interface CorpusPolicy {
	format: 1
	maxDatabaseBytes: number
	legacyVersions: string[]
	channels: Record<string, { version: string; sessionId: string; source: string; response: string; resolvedAt: string }>
}

export function readCorpusPolicy(path: string): CorpusPolicy {
	const policy = JSON.parse(readFileSync(path, 'utf8')) as CorpusPolicy
	if (policy.format !== 1 || !Number.isSafeInteger(policy.maxDatabaseBytes) || policy.maxDatabaseBytes <= 0) throw new Error('Unsupported corpus policy')
	if (Object.keys(policy.channels).sort().join(',') !== [...CHANNELS].sort().join(',')) throw new Error('Corpus policy requires all four channels')
	const minors = new Set<string>()
	const currentMinors = new Set(CHANNELS.map((channel) => policy.channels[channel].version.match(/^7\.\d+/)?.[0]))
	for (const channel of CHANNELS) {
		const entry = policy.channels[channel]
		if (!/^7\.\d+(?:\.\d+|rc\d+|beta\d+)?$/.test(entry.version) || !/^[a-f0-9-]{36}$/.test(entry.sessionId) || entry.response.split(/\s+/)[0] !== entry.version)
			throw new Error(`Invalid channel identity: ${channel}`)
	}
	for (const version of policy.legacyVersions) {
		const minor = version.match(/^(7\.\d+)(?:\.\d+)?$/)?.[1]
		if (
			!minor ||
			minors.has(minor) ||
			currentMinors.has(minor) ||
			Number(minor.split('.')[1]) >= Math.max(...[...currentMinors].map((value) => Number(value?.split('.')[1])))
		)
			throw new Error('Legacy representatives must be distinct, released older minors')
		minors.add(minor)
	}
	return policy
}

/** Select the indexed evidence; archived raw sidecars remain in git history/files. */
export function retainedCorpusFiles(files: string[], dataDir: string, policy: CorpusPolicy): string[] {
	const sessions = new Set(Object.values(policy.channels).map((entry) => entry.sessionId))
	const versions = new Set(policy.legacyVersions)
	return files.filter((file) => {
		const path = relative(dataDir, file)
		const capture = path.match(/^captures\/([^/]+)-(?:parseil|highlight)\.json$/)
		if (path.startsWith('captures/')) return capture !== null && sessions.has(capture[1])
		const version =
			path.match(/\.rsc\.v([^/]+)\.parseil(?:\.meta\.json)?$/)?.[1] ??
			path.match(/^(?:parseil-summary|highlight-summary|inspect-shapes|required-args)\.v(.+?)(?:\.meta)?\.json$/)?.[1]
		return version === undefined || versions.has(version)
	})
}

/** Bind labels to the exact retained run pair, never to firmware alone. */
export function insertCaptureChannels(db: Database, policy: CorpusPolicy): void {
	const sourceCount = (db.query('SELECT COUNT(*) n FROM source_scripts').get() as { n: number }).n
	for (const channel of CHANNELS) {
		const entry = policy.channels[channel]
		const parseId = `${entry.sessionId}-parseil`
		const highlightId = `${entry.sessionId}-highlight`
		const rows = db
			.query('SELECT probe,routeros_version,environment_sha256 FROM capture_runs WHERE id IN (?,?) ORDER BY probe')
			.all(parseId, highlightId) as Array<{ probe: string; routeros_version: string; environment_sha256: string }>
		if (
			rows.length !== 2 ||
			rows[0].probe !== 'highlight' ||
			rows[1].probe !== 'parseil' ||
			rows.some((row) => row.routeros_version !== entry.version) ||
			rows[0].environment_sha256 !== rows[1].environment_sha256
		)
			throw new Error(`Missing/mismatched capture pair for ${channel}`)
		const coverage = db
			.query('SELECT current_source_count,matched_count,corpus_script_count FROM v_capture_run_coverage WHERE run_id IN (?,?)')
			.all(parseId, highlightId) as Array<{ current_source_count: number; matched_count: number; corpus_script_count: number }>
		const selected = db.query('SELECT selection_json FROM capture_runs WHERE id IN (?,?)').all(parseId, highlightId) as Array<{ selection_json: string }>
		const allSources = db
			.query(`SELECT COUNT(DISTINCT CASE WHEN o.input_status='matched' THEN o.script_id END) AS matched_count
		 FROM capture_runs r LEFT JOIN capture_observations o ON o.run_id=r.id WHERE r.id IN (?,?) GROUP BY r.id`)
			.all(parseId, highlightId) as Array<{ matched_count: number }>
		if (
			allSources.some((row) => row.matched_count !== sourceCount) ||
			coverage.some((row) => row.current_source_count !== row.corpus_script_count || row.matched_count !== row.corpus_script_count) ||
			selected.some((row) => {
				const selection = JSON.parse(row.selection_json)
				return selection.target !== null || selection.limit !== null
			})
		)
			throw new Error(`Channel requires current full-population captures: ${channel}`)
		db.prepare('INSERT INTO capture_channels VALUES (?,?,?,?,?,?,?,?)').run(
			channel,
			entry.version,
			parseId,
			highlightId,
			rows[0].environment_sha256,
			entry.source,
			entry.response,
			entry.resolvedAt,
		)
	}
}
