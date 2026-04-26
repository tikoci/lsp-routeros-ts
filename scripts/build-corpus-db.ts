/**
 * Build the checked-in test corpus SQLite database from test-data/.
 *
 * Usage:
 *   bun run scripts/build-corpus-db.ts
 *   bun run scripts/build-corpus-db.ts --db test-data/corpus.sqlite
 *
 * The database is an analysis/indexing artifact for research harnesses. It is
 * rebuilt from committed .rsc scripts and sidecar captures; it is not runtime
 * code and is excluded from the VSIX by .vscodeignore's test-data/ rule.
 */
import { createHash } from 'node:crypto'
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync } from 'node:fs'
import { dirname, join, relative, resolve } from 'node:path'
import { Database } from 'bun:sqlite'
import { ROUTEROS_API_MAX_BYTES, ConnectionLogger } from '../server/src/shared'
import { HighlightTokens } from '../server/src/tokens'

const noop = () => {}
ConnectionLogger.console = { log: noop, info: noop, warn: noop, error: noop, debug: noop }

const TEST_DATA_DIR = resolve(import.meta.dir, '../test-data')
const REPO_ROOT = resolve(import.meta.dir, '..')
const SCHEMA_VERSION = '2'
const DEFAULT_DB = join(TEST_DATA_DIR, 'corpus.sqlite')

interface ParseIlMeta {
	source?: string
	routerosVersion?: string
	chrBuildTime?: string
	inputBytes?: number
	ilBytes?: number
	parseMs?: number
	ok?: boolean
	error?: string
	capturedAt?: string
}

interface ParseIlSummary {
	routerosVersion?: string
	chrBuildTime?: string
	capturedAt?: string
	totalFiles?: number
	ok?: number
	failed?: number
	inputBytesTotal?: number
	ilBytesTotal?: number
	parseMsMean?: number
	parseMsMax?: number
	results?: unknown[]
}

interface RequiredArgSummaryEntry {
	path?: string
	required?: unknown
	hasAdd?: boolean
	rawError?: string
}

interface RequiredArgMeta {
	routerosVersion?: string
	chrBuildTime?: string
	schemaPath?: string
	schemaSha256?: string
	totalMenus?: number
	requiredMenus?: number
	okCount?: number
	missingValueCount?: number
	customRequiredCount?: number
	badCommandCount?: number
	probeErrorCount?: number
	capturedAt?: string
	target?: string
	limit?: number
}

interface ArtifactInfo {
	artifactKind: string
	routerosVersion: string | null
	scriptPath: string | null
	contentType: string
	capturedAt: string | null
	jsonValid: boolean | null
}

function parseArgs(): { dbPath: string } {
	const args = process.argv.slice(2)
	const dbIdx = args.indexOf('--db')
	if (dbIdx >= 0) {
		const value = args[dbIdx + 1]
		if (!value) throw new Error('--db requires a path')
		return { dbPath: resolve(value) }
	}
	return { dbPath: DEFAULT_DB }
}

function allFiles(dir: string): string[] {
	const out: string[] = []
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = join(dir, entry.name)
		if (entry.isDirectory()) {
			out.push(...allFiles(full))
		} else {
			out.push(full)
		}
	}
	return out.sort((a, b) => relative(TEST_DATA_DIR, a).localeCompare(relative(TEST_DATA_DIR, b)))
}

function sha256(buffer: Buffer | string): string {
	return createHash('sha256')
		.update(typeof buffer === 'string' ? buffer : new Uint8Array(buffer))
		.digest('hex')
}

function rel(filePath: string): string {
	return relative(TEST_DATA_DIR, filePath)
}

function corpusInputSha256(files: string[]): string {
	const hash = createHash('sha256')
	for (const filePath of files) {
		hash.update(rel(filePath))
		hash.update('\0')
		hash.update(new Uint8Array(readFileSync(filePath)))
		hash.update('\0')
	}
	return hash.digest('hex')
}

function readJson<T>(filePath: string): { value: T | null; valid: boolean } {
	try {
		return { value: JSON.parse(readFileSync(filePath, 'utf-8')) as T, valid: true }
	} catch {
		return { value: null, valid: false }
	}
}

function classifyCollection(relPath: string): string {
	if (relPath.startsWith('forum/amm0/')) return 'amm0'
	if (relPath.startsWith('forum/rextended/')) return 'rextended'
	if (relPath.startsWith('eworm/')) return 'eworm'
	if (relPath.startsWith('edge-cases/')) return 'edge-cases'
	if (relPath.startsWith('tikbook/')) return 'tikbook'
	if (relPath.startsWith('complex/')) return 'complex'
	if (relPath.startsWith('forum/')) return 'forum-legacy'
	return 'root'
}

function hasCliPromptPattern(text: string): boolean {
	return /\[[^\]\r\n]+@[^\]\r\n]+\]\s*>/.test(text) || /\[[^\]\r\n]+\]\s*>/.test(text)
}

function lineCount(text: string): number {
	if (text.length === 0) return 0
	return text.split('\n').length
}

function firstLine(text: string): string {
	return text.split(/\r?\n/, 1)[0] ?? ''
}

function parseVersionedParseIlPath(relPath: string): { scriptPath: string; version: string } | null {
	const m = relPath.match(/^(.*\.rsc)\.v([^/]+)\.parseil(?:\.meta\.json)?$/)
	if (!m) return null
	return { scriptPath: m[1], version: m[2] }
}

function parseSummaryVersion(relPath: string): string | null {
	return relPath.match(/^parseil-summary\.v(.+)\.json$/)?.[1] ?? null
}

function parseRequiredArgsVersion(relPath: string): string | null {
	return relPath.match(/^required-args\.v(.+?)\.(?:meta\.)?json$/)?.[1] ?? null
}

function analysisRunKey(analysisName: string, version: string): string {
	return `${analysisName}\0${version}`
}

function classifyRequiredArgError(hasAdd: boolean, requiredCount: number, rawError: string): string {
	if (!hasAdd) return 'bad-command'
	if (!rawError) return 'ok'
	if (rawError.includes('missing value(s) of argument(s)')) return 'missing-values'
	if (requiredCount > 0) return 'custom-required'
	if (rawError.includes('contact MikroTik support')) return 'routeros-bug'
	return 'probe-error'
}

function artifactInfo(filePath: string): ArtifactInfo {
	const relPath = rel(filePath)
	const parsedParseIl = parseVersionedParseIlPath(relPath)

	if (relPath.endsWith('.rsc.highlight')) {
		return {
			artifactKind: 'highlight_snapshot',
			routerosVersion: null,
			scriptPath: relPath.replace(/\.highlight$/, ''),
			contentType: 'text/csv',
			capturedAt: null,
			jsonValid: null,
		}
	}

	if (relPath.endsWith('.parseil.meta.json') && parsedParseIl) {
		const { value, valid } = readJson<ParseIlMeta>(filePath)
		return {
			artifactKind: 'parseil_meta',
			routerosVersion: value?.routerosVersion ?? parsedParseIl.version,
			scriptPath: value?.source ?? parsedParseIl.scriptPath,
			contentType: 'application/json',
			capturedAt: value?.capturedAt ?? null,
			jsonValid: valid,
		}
	}

	if (relPath.endsWith('.parseil') && parsedParseIl) {
		return {
			artifactKind: 'parseil_il',
			routerosVersion: parsedParseIl.version,
			scriptPath: parsedParseIl.scriptPath,
			contentType: 'text/plain',
			capturedAt: null,
			jsonValid: null,
		}
	}

	const summaryVersion = parseSummaryVersion(relPath)
	if (summaryVersion) {
		const { value, valid } = readJson<ParseIlSummary>(filePath)
		return {
			artifactKind: 'parseil_summary',
			routerosVersion: value?.routerosVersion ?? summaryVersion,
			scriptPath: null,
			contentType: 'application/json',
			capturedAt: value?.capturedAt ?? null,
			jsonValid: valid,
		}
	}

	const requiredArgsVersion = parseRequiredArgsVersion(relPath)
	if (requiredArgsVersion && relPath.endsWith('.meta.json')) {
		const { value, valid } = readJson<RequiredArgMeta>(filePath)
		return {
			artifactKind: 'required_args_meta',
			routerosVersion: value?.routerosVersion ?? requiredArgsVersion,
			scriptPath: null,
			contentType: 'application/json',
			capturedAt: value?.capturedAt ?? null,
			jsonValid: valid,
		}
	}

	if (requiredArgsVersion) {
		const { valid } = readJson<RequiredArgSummaryEntry[]>(filePath)
		return {
			artifactKind: 'required_args_summary',
			routerosVersion: requiredArgsVersion,
			scriptPath: null,
			contentType: 'application/json',
			capturedAt: null,
			jsonValid: valid,
		}
	}

	if (relPath.endsWith('.tikbook')) {
		return {
			artifactKind: 'tikbook_notebook',
			routerosVersion: null,
			scriptPath: null,
			contentType: 'application/json',
			capturedAt: null,
			jsonValid: readJson<unknown>(filePath).valid,
		}
	}

	if (relPath.endsWith('.json')) {
		const { valid } = readJson<unknown>(filePath)
		return {
			artifactKind: 'json_sidecar',
			routerosVersion: null,
			scriptPath: null,
			contentType: 'application/json',
			capturedAt: null,
			jsonValid: valid,
		}
	}

	return {
		artifactKind: 'sidecar',
		routerosVersion: null,
		scriptPath: null,
		contentType: 'application/octet-stream',
		capturedAt: null,
		jsonValid: null,
	}
}

function sourceScriptPathForMeta(metaPath: string, meta: ParseIlMeta | null): string | null {
	if (meta?.source) return meta.source
	return parseVersionedParseIlPath(rel(metaPath))?.scriptPath ?? null
}

function createSchema(db: Database): void {
	db.exec(`
CREATE TABLE corpus_metadata (
key TEXT PRIMARY KEY,
value TEXT NOT NULL
);

CREATE TABLE source_scripts (
id INTEGER PRIMARY KEY,
path TEXT NOT NULL UNIQUE,
collection TEXT NOT NULL,
bytes INTEGER NOT NULL,
chars INTEGER NOT NULL,
line_count INTEGER NOT NULL,
sha256 TEXT NOT NULL,
is_empty INTEGER NOT NULL,
is_oversize_32k INTEGER NOT NULL,
has_cli_prompt INTEGER NOT NULL,
has_comment_header INTEGER NOT NULL,
first_line TEXT NOT NULL,
text TEXT NOT NULL
);

CREATE VIRTUAL TABLE source_scripts_fts USING fts5(
path,
collection,
text,
content='source_scripts',
content_rowid='id'
);

CREATE TABLE artifact_files (
id INTEGER PRIMARY KEY,
script_id INTEGER REFERENCES source_scripts(id) ON DELETE SET NULL,
artifact_kind TEXT NOT NULL,
routeros_version TEXT,
path TEXT NOT NULL UNIQUE,
bytes INTEGER NOT NULL,
sha256 TEXT NOT NULL,
content_type TEXT NOT NULL,
json_valid INTEGER,
captured_at TEXT
);

CREATE TABLE analysis_runs (
id INTEGER PRIMARY KEY,
analysis_name TEXT NOT NULL,
routeros_version TEXT,
chr_build_time TEXT,
source_path TEXT,
captured_at TEXT,
summary_json TEXT,
UNIQUE(analysis_name, routeros_version, source_path)
);

CREATE TABLE parseil_results (
run_id INTEGER NOT NULL REFERENCES analysis_runs(id) ON DELETE CASCADE,
script_id INTEGER NOT NULL REFERENCES source_scripts(id) ON DELETE CASCADE,
routeros_version TEXT NOT NULL,
ok INTEGER NOT NULL,
status TEXT NOT NULL,
input_bytes INTEGER,
il_bytes INTEGER,
parse_ms INTEGER,
error TEXT,
il_path TEXT,
il_sha256 TEXT,
meta_path TEXT NOT NULL,
captured_at TEXT,
il_text TEXT,
PRIMARY KEY (run_id, script_id)
);

CREATE TABLE highlight_snapshots (
script_id INTEGER NOT NULL REFERENCES source_scripts(id) ON DELETE CASCADE,
artifact_id INTEGER NOT NULL REFERENCES artifact_files(id) ON DELETE CASCADE,
routeros_version TEXT,
token_count INTEGER NOT NULL,
expected_chars INTEGER NOT NULL,
token_count_match INTEGER NOT NULL,
unique_token_types_json TEXT NOT NULL,
error_token_count INTEGER NOT NULL,
captured_at TEXT,
PRIMARY KEY (script_id, artifact_id)
);

CREATE TABLE inspect_responses (
id INTEGER PRIMARY KEY,
run_id INTEGER REFERENCES analysis_runs(id) ON DELETE SET NULL,
script_id INTEGER REFERENCES source_scripts(id) ON DELETE SET NULL,
routeros_version TEXT,
request_type TEXT NOT NULL CHECK (request_type IN ('highlight', 'completion', 'syntax', 'child')),
cursor_offset INTEGER,
input_variant TEXT,
input_sha256 TEXT,
response_path TEXT,
response_sha256 TEXT,
response_json TEXT,
json_valid INTEGER,
ok INTEGER,
error TEXT,
captured_at TEXT
);

CREATE TABLE completion_trick_results (
id INTEGER PRIMARY KEY,
run_id INTEGER REFERENCES analysis_runs(id) ON DELETE SET NULL,
script_id INTEGER REFERENCES source_scripts(id) ON DELETE SET NULL,
routeros_version TEXT,
cursor_offset INTEGER,
context_kind TEXT,
trick TEXT NOT NULL,
baseline_count INTEGER,
trick_count INTEGER,
result_delta INTEGER,
changed INTEGER,
error TEXT,
response_json TEXT,
captured_at TEXT
);

CREATE TABLE required_arg_results (
run_id INTEGER NOT NULL REFERENCES analysis_runs(id) ON DELETE CASCADE,
routeros_version TEXT NOT NULL,
path TEXT NOT NULL,
has_add INTEGER NOT NULL,
required_json TEXT NOT NULL,
required_count INTEGER NOT NULL,
raw_error TEXT NOT NULL,
error_kind TEXT NOT NULL,
captured_at TEXT,
PRIMARY KEY (run_id, path)
);

CREATE INDEX idx_source_scripts_collection ON source_scripts(collection);
CREATE INDEX idx_artifact_files_script ON artifact_files(script_id);
CREATE INDEX idx_artifact_files_kind ON artifact_files(artifact_kind);
CREATE INDEX idx_parseil_results_version ON parseil_results(routeros_version);
CREATE INDEX idx_highlight_snapshots_script ON highlight_snapshots(script_id);
CREATE INDEX idx_inspect_responses_request ON inspect_responses(request_type);
CREATE INDEX idx_completion_trick_results_trick ON completion_trick_results(trick);
CREATE INDEX idx_required_arg_results_version ON required_arg_results(routeros_version);

CREATE VIEW v_script_summary AS
SELECT
s.id,
s.path,
s.collection,
s.bytes,
s.chars,
s.line_count,
s.is_empty,
s.is_oversize_32k,
s.has_cli_prompt,
s.has_comment_header,
COUNT(DISTINCT a.id) AS artifact_count,
COUNT(DISTINCT h.artifact_id) AS highlight_snapshot_count,
COUNT(DISTINCT p.routeros_version) AS parseil_version_count,
SUM(CASE WHEN p.ok = 1 THEN 1 ELSE 0 END) AS parseil_ok_count,
SUM(CASE WHEN p.ok = 0 THEN 1 ELSE 0 END) AS parseil_error_count
FROM source_scripts s
LEFT JOIN artifact_files a ON a.script_id = s.id
LEFT JOIN highlight_snapshots h ON h.script_id = s.id
LEFT JOIN parseil_results p ON p.script_id = s.id
GROUP BY s.id;

CREATE VIEW v_parseil_by_version AS
SELECT
routeros_version,
COUNT(*) AS result_count,
SUM(CASE WHEN ok = 1 THEN 1 ELSE 0 END) AS ok_count,
SUM(CASE WHEN ok = 0 THEN 1 ELSE 0 END) AS error_count,
ROUND(AVG(parse_ms), 2) AS avg_parse_ms,
MAX(parse_ms) AS max_parse_ms,
SUM(input_bytes) AS input_bytes_total,
SUM(il_bytes) AS il_bytes_total
FROM parseil_results
GROUP BY routeros_version;

CREATE VIEW v_parseil_drift AS
SELECT
s.path,
COUNT(p.routeros_version) AS versions,
COUNT(DISTINCT COALESCE(p.il_sha256, p.status || ':' || COALESCE(p.error, ''))) AS distinct_results,
GROUP_CONCAT(p.routeros_version || ':' || p.status, ', ') AS version_statuses
FROM source_scripts s
JOIN parseil_results p ON p.script_id = s.id
GROUP BY s.id
HAVING distinct_results > 1;

CREATE VIEW v_analysis_overview AS
SELECT
a.id,
a.analysis_name,
a.routeros_version,
a.source_path,
a.captured_at,
CASE
WHEN a.analysis_name = 'parseil' THEN (SELECT COUNT(*) FROM parseil_results p WHERE p.run_id = a.id)
WHEN a.analysis_name = 'required-args' THEN (SELECT COUNT(*) FROM required_arg_results r WHERE r.run_id = a.id)
WHEN a.analysis_name = 'inspect-shapes' THEN (SELECT COUNT(*) FROM inspect_responses i WHERE i.run_id = a.id)
WHEN a.analysis_name = 'completion-tricks' THEN (SELECT COUNT(*) FROM completion_trick_results c WHERE c.run_id = a.id)
ELSE 0
END AS result_count
FROM analysis_runs a;

CREATE VIEW v_required_args_by_version AS
SELECT
routeros_version,
COUNT(*) AS result_count,
SUM(CASE WHEN has_add = 1 THEN 1 ELSE 0 END) AS has_add_count,
SUM(CASE WHEN required_count > 0 THEN 1 ELSE 0 END) AS required_path_count,
SUM(CASE WHEN error_kind = 'probe-error' THEN 1 ELSE 0 END) AS probe_error_count,
SUM(CASE WHEN error_kind = 'routeros-bug' THEN 1 ELSE 0 END) AS routeros_bug_count
FROM required_arg_results
GROUP BY routeros_version;

CREATE VIEW v_required_arg_drift AS
SELECT
path,
COUNT(routeros_version) AS versions,
COUNT(DISTINCT (CASE WHEN has_add = 1 THEN '1' ELSE '0' END) || ':' || required_json) AS distinct_results,
GROUP_CONCAT(routeros_version || ':' || (CASE WHEN has_add = 1 THEN 'add' ELSE 'no-add' END) || ':' || required_json, ', ') AS version_signatures
FROM required_arg_results
GROUP BY path
HAVING distinct_results > 1;
	`)
}

function insertMetadata(db: Database, dbPath: string, files: string[]): void {
	const insert = db.prepare('INSERT INTO corpus_metadata (key, value) VALUES (?, ?)')
	const values: [string, string][] = [
		['schema_version', SCHEMA_VERSION],
		['generator', 'scripts/build-corpus-db.ts'],
		['corpus_sha256', corpusInputSha256(files)],
		['db_path', relative(REPO_ROOT, dbPath)],
		['test_data_dir', 'test-data'],
		['routeros_api_max_bytes', String(ROUTEROS_API_MAX_BYTES)],
		['highlight_error_token_types', JSON.stringify(HighlightTokens.ErrorTokenTypes)],
	]
	for (const [key, value] of values) insert.run(key, value)
}

function insertSourceScripts(db: Database, files: string[]): Map<string, number> {
	const insertScript = db.prepare(`
INSERT INTO source_scripts (
path, collection, bytes, chars, line_count, sha256, is_empty, is_oversize_32k,
has_cli_prompt, has_comment_header, first_line, text
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`)
	const insertFts = db.prepare('INSERT INTO source_scripts_fts (rowid, path, collection, text) VALUES (?, ?, ?, ?)')
	const byPath = new Map<string, number>()

	for (const filePath of files.filter((f) => f.endsWith('.rsc'))) {
		const relPath = rel(filePath)
		const text = readFileSync(filePath, 'utf-8')
		const bytes = Buffer.byteLength(text, 'utf-8')
		const collection = classifyCollection(relPath)
		const info = insertScript.run(
			relPath,
			collection,
			bytes,
			text.length,
			lineCount(text),
			sha256(text),
			text.length === 0 ? 1 : 0,
			bytes > ROUTEROS_API_MAX_BYTES ? 1 : 0,
			hasCliPromptPattern(text) ? 1 : 0,
			firstLine(text).trimStart().startsWith('#') ? 1 : 0,
			firstLine(text),
			text,
		)
		const id = Number(info.lastInsertRowid)
		byPath.set(relPath, id)
		insertFts.run(id, relPath, collection, text)
	}

	return byPath
}

function insertArtifacts(db: Database, files: string[], scriptIds: Map<string, number>): Map<string, number> {
	const insert = db.prepare(`
INSERT INTO artifact_files (
script_id, artifact_kind, routeros_version, path, bytes, sha256,
content_type, json_valid, captured_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`)
	const byPath = new Map<string, number>()

	for (const filePath of files) {
		const relPath = rel(filePath)
		if (relPath.startsWith('corpus.sqlite') || relPath.endsWith('.rsc')) continue

		const bytes = readFileSync(filePath)
		const info = artifactInfo(filePath)
		const result = insert.run(
			info.scriptPath ? (scriptIds.get(info.scriptPath) ?? null) : null,
			info.artifactKind,
			info.routerosVersion,
			relPath,
			bytes.length,
			sha256(bytes),
			info.contentType,
			info.jsonValid === null ? null : info.jsonValid ? 1 : 0,
			info.capturedAt,
		)
		byPath.set(relPath, Number(result.lastInsertRowid))
	}

	return byPath
}

function insertAnalysisRuns(db: Database, files: string[]): Map<string, number> {
	const insert = db.prepare(`
INSERT INTO analysis_runs (
analysis_name, routeros_version, chr_build_time, source_path, captured_at, summary_json
) VALUES (?, ?, ?, ?, ?, ?)
`)
	const byKey = new Map<string, number>()

	const summaryFiles = files.filter((f) => parseSummaryVersion(rel(f))).sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const filePath of summaryFiles) {
		const relPath = rel(filePath)
		const { value } = readJson<ParseIlSummary>(filePath)
		const fallbackVersion = parseSummaryVersion(relPath)
		const version = value?.routerosVersion ?? fallbackVersion ?? 'unknown'
		const summaryJson = readFileSync(filePath, 'utf-8')
		const result = insert.run('parseil', version, value?.chrBuildTime ?? null, relPath, value?.capturedAt ?? null, summaryJson)
		byKey.set(analysisRunKey('parseil', version), Number(result.lastInsertRowid))
	}

	const metaFiles = files.filter((f) => f.endsWith('.parseil.meta.json')).sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const filePath of metaFiles) {
		const parsedPath = parseVersionedParseIlPath(rel(filePath))
		const { value } = readJson<ParseIlMeta>(filePath)
		const version = value?.routerosVersion ?? parsedPath?.version ?? 'unknown'
		const key = analysisRunKey('parseil', version)
		if (byKey.has(key)) continue

		const result = insert.run('parseil', version, value?.chrBuildTime ?? null, null, value?.capturedAt ?? null, null)
		byKey.set(key, Number(result.lastInsertRowid))
	}

	const requiredMetaFiles = files.filter((f) => rel(f).endsWith('.meta.json') && parseRequiredArgsVersion(rel(f))).sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const filePath of requiredMetaFiles) {
		const relPath = rel(filePath)
		const { value } = readJson<RequiredArgMeta>(filePath)
		const version = value?.routerosVersion ?? parseRequiredArgsVersion(relPath) ?? 'unknown'
		const key = analysisRunKey('required-args', version)
		if (byKey.has(key)) continue

		const summaryPath = `required-args.v${version}.json`
		const sourcePath = files.some((candidate) => rel(candidate) === summaryPath) ? summaryPath : relPath
		const result = insert.run('required-args', version, value?.chrBuildTime ?? null, sourcePath, value?.capturedAt ?? null, readFileSync(filePath, 'utf-8'))
		byKey.set(key, Number(result.lastInsertRowid))
	}

	const requiredSummaryFiles = files
		.filter((f) => {
			const relPath = rel(f)
			return parseRequiredArgsVersion(relPath) !== null && !relPath.endsWith('.meta.json')
		})
		.sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const filePath of requiredSummaryFiles) {
		const relPath = rel(filePath)
		const version = parseRequiredArgsVersion(relPath) ?? 'unknown'
		const key = analysisRunKey('required-args', version)
		if (byKey.has(key)) continue

		const result = insert.run('required-args', version, null, relPath, null, null)
		byKey.set(key, Number(result.lastInsertRowid))
	}

	return byKey
}

function insertParseIlResults(db: Database, files: string[], scriptIds: Map<string, number>, runIds: Map<string, number>): void {
	const insert = db.prepare(`
INSERT OR REPLACE INTO parseil_results (
run_id, script_id, routeros_version, ok, status, input_bytes, il_bytes, parse_ms,
error, il_path, il_sha256, meta_path, captured_at, il_text
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`)

	const metaFiles = files.filter((f) => f.endsWith('.parseil.meta.json')).sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const metaPath of metaFiles) {
		const relMetaPath = rel(metaPath)
		const { value: meta, valid } = readJson<ParseIlMeta>(metaPath)
		if (!valid) continue

		const parsedPath = parseVersionedParseIlPath(relMetaPath)
		const scriptPath = sourceScriptPathForMeta(metaPath, meta)
		if (!scriptPath) continue
		const scriptId = scriptIds.get(scriptPath)
		if (!scriptId) continue

		const version = meta?.routerosVersion ?? parsedPath?.version ?? 'unknown'
		const runId = runIds.get(analysisRunKey('parseil', version))
		if (!runId) continue

		const ilRelPath = parsedPath ? `${parsedPath.scriptPath}.v${version}.parseil` : relMetaPath.replace(/\.meta\.json$/, '')
		const ilFullPath = join(TEST_DATA_DIR, ilRelPath)
		const ilText = existsSync(ilFullPath) ? readFileSync(ilFullPath, 'utf-8') : null
		const ok = typeof meta?.ok === 'boolean' ? meta.ok : !meta?.error
		const status = ok ? (ilText === null ? 'missing-il' : 'ok') : 'error'
		insert.run(
			runId,
			scriptId,
			version,
			ok ? 1 : 0,
			status,
			meta?.inputBytes ?? null,
			meta?.ilBytes ?? null,
			meta?.parseMs ?? null,
			meta?.error ?? null,
			ilText === null ? null : ilRelPath,
			ilText === null ? null : sha256(ilText),
			relMetaPath,
			meta?.capturedAt ?? null,
			ilText,
		)
	}
}

function insertHighlightSnapshots(db: Database, files: string[], scriptIds: Map<string, number>, artifactIds: Map<string, number>): void {
	const insert = db.prepare(`
INSERT INTO highlight_snapshots (
script_id, artifact_id, routeros_version, token_count, expected_chars,
token_count_match, unique_token_types_json, error_token_count, captured_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`)
	const errorTokenTypes = new Set(HighlightTokens.ErrorTokenTypes)

	const highlightFiles = files.filter((f) => f.endsWith('.rsc.highlight')).sort((a, b) => rel(a).localeCompare(rel(b)))
	for (const filePath of highlightFiles) {
		const relPath = rel(filePath)
		const scriptPath = relPath.replace(/\.highlight$/, '')
		const scriptId = scriptIds.get(scriptPath)
		const artifactId = artifactIds.get(relPath)
		if (!scriptId || !artifactId) continue

		const scriptText = readFileSync(join(TEST_DATA_DIR, scriptPath), 'utf-8')
		const raw = readFileSync(filePath, 'utf-8').trim()
		const tokens = raw.length ? raw.split(',') : []
		const uniqueTokenTypes = [...new Set(tokens)].sort()
		const errorTokenCount = tokens.filter((token) => errorTokenTypes.has(token)).length
		insert.run(scriptId, artifactId, null, tokens.length, scriptText.length, tokens.length === scriptText.length ? 1 : 0, JSON.stringify(uniqueTokenTypes), errorTokenCount, null)
	}
}

function insertRequiredArgResults(db: Database, files: string[], runIds: Map<string, number>): void {
	const insert = db.prepare(`
INSERT OR REPLACE INTO required_arg_results (
run_id, routeros_version, path, has_add, required_json, required_count, raw_error, error_kind, captured_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`)

	const summaryFiles = files
		.filter((f) => {
			const relPath = rel(f)
			return parseRequiredArgsVersion(relPath) !== null && !relPath.endsWith('.meta.json')
		})
		.sort((a, b) => rel(a).localeCompare(rel(b)))

	for (const filePath of summaryFiles) {
		const relPath = rel(filePath)
		const version = parseRequiredArgsVersion(relPath)
		if (!version) continue

		const runId = runIds.get(analysisRunKey('required-args', version))
		if (!runId) continue

		const metaPath = join(TEST_DATA_DIR, `required-args.v${version}.meta.json`)
		const metaRead = existsSync(metaPath) ? readJson<RequiredArgMeta>(metaPath) : { value: null }
		const meta = metaRead.value
		const { value, valid } = readJson<RequiredArgSummaryEntry[]>(filePath)
		if (!valid || !Array.isArray(value)) continue

		for (const row of value) {
			if (!row || typeof row.path !== 'string') continue
			const required = Array.isArray(row.required) ? row.required.filter((item): item is string => typeof item === 'string') : []
			const hasAdd = typeof row.hasAdd === 'boolean' ? row.hasAdd : true
			const rawError = typeof row.rawError === 'string' ? row.rawError : ''
			insert.run(
				runId,
				version,
				row.path,
				hasAdd ? 1 : 0,
				JSON.stringify(required),
				required.length,
				rawError,
				classifyRequiredArgError(hasAdd, required.length, rawError),
				meta?.capturedAt ?? null,
			)
		}
	}
}

function printSummary(db: Database, dbPath: string): void {
	const row = db
		.query(
			`
SELECT
(SELECT COUNT(*) FROM source_scripts) AS source_scripts,
(SELECT COUNT(*) FROM artifact_files) AS artifacts,
(SELECT COUNT(*) FROM analysis_runs) AS analysis_runs,
(SELECT COUNT(*) FROM parseil_results) AS parseil_results,
(SELECT COUNT(*) FROM highlight_snapshots) AS highlight_snapshots,
(SELECT COUNT(*) FROM required_arg_results) AS required_arg_results,
(SELECT COUNT(*) FROM inspect_responses) AS inspect_responses,
(SELECT COUNT(*) FROM completion_trick_results) AS completion_trick_results
 `,
		)
		.get() as Record<string, number>

	console.log(`Wrote ${relative(REPO_ROOT, dbPath)}`)
	console.log(
		[
			`scripts=${row.source_scripts}`,
			`artifacts=${row.artifacts}`,
			`analysis_runs=${row.analysis_runs}`,
			`parseil=${row.parseil_results}`,
			`highlights=${row.highlight_snapshots}`,
			`required_args=${row.required_arg_results}`,
			`inspect=${row.inspect_responses}`,
			`completion_tricks=${row.completion_trick_results}`,
		].join('  '),
	)
	db.close()
}

function main(): void {
	const { dbPath } = parseArgs()
	if (!dbPath.startsWith(`${REPO_ROOT}/`)) throw new Error(`Refusing to write outside repository: ${dbPath}`)
	mkdirSync(dirname(dbPath), { recursive: true })
	if (existsSync(dbPath)) rmSync(dbPath)

	const files = allFiles(TEST_DATA_DIR).filter((filePath) => resolve(filePath) !== dbPath)
	const db = new Database(dbPath)
	db.exec('PRAGMA journal_mode = DELETE')
	db.exec('PRAGMA foreign_keys = ON')

	const tx = db.transaction(() => {
		createSchema(db)
		insertMetadata(db, dbPath, files)
		const scriptIds = insertSourceScripts(db, files)
		const artifactIds = insertArtifacts(db, files, scriptIds)
		const runIds = insertAnalysisRuns(db, files)
		insertParseIlResults(db, files, scriptIds, runIds)
		insertHighlightSnapshots(db, files, scriptIds, artifactIds)
		insertRequiredArgResults(db, files, runIds)
	})

	tx()
	db.close()

	printSummary(new Database(dbPath, { readonly: true }), dbPath)
}

main()
