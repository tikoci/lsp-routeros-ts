/** Schema-v5 evidence imports, including explicitly unknown legacy provenance. */
import { readFileSync } from 'node:fs'
import { relative } from 'node:path'
import type { Database } from 'bun:sqlite'
import { CLASSIFIER_VERSION, capturedResponseText, EVIDENCE_FORMAT, classifyParseResponse, hash, validateObservation, type CaptureRun } from './corpus-evidence'

export function createEvidenceSchema(db: Database): void {
	db.exec(`
CREATE TABLE capture_environments (
 sha256 TEXT PRIMARY KEY, environment_json TEXT NOT NULL,
 menu_inventory_sha256 TEXT, provenance TEXT NOT NULL
);
CREATE TABLE capture_runs (
 id TEXT PRIMARY KEY, probe TEXT NOT NULL, routeros_version TEXT,
 environment_sha256 TEXT REFERENCES capture_environments(sha256),
 source_path TEXT, captured_at TEXT, selection_json TEXT, provenance TEXT NOT NULL
);
CREATE TABLE capture_observations (
 id INTEGER PRIMARY KEY, run_id TEXT NOT NULL REFERENCES capture_runs(id),
 script_id INTEGER REFERENCES source_scripts(id), source_path TEXT NOT NULL,
 source_sha256 TEXT, submitted_sha256 TEXT, input_json TEXT,
 input_status TEXT NOT NULL, acquisition_status TEXT NOT NULL,
 response_class TEXT NOT NULL, classifier_version TEXT NOT NULL,
 response_text TEXT, response_json TEXT, diagnostics_json TEXT NOT NULL,
 error TEXT, submission TEXT, elapsed_ms INTEGER, highlight_json TEXT,
 UNIQUE(run_id, source_path)
);
-- Root cause needs an evidence-qualified annotation. Diagnostic wording alone
-- cannot distinguish absent menus from spelling errors or rule out later errors.
CREATE TABLE cause_attributions (
 observation_id INTEGER NOT NULL REFERENCES capture_observations(id),
 cause TEXT NOT NULL CHECK(cause IN ('syntax','unavailable-menu-or-command','parameter-name','unknown','mixed')),
 scope TEXT NOT NULL, evidence_json TEXT NOT NULL,
 PRIMARY KEY(observation_id, cause, scope)
);
CREATE INDEX idx_capture_observations_script ON capture_observations(script_id);
CREATE VIEW v_capture_outcomes AS
 SELECT r.id AS run_id, r.probe, r.routeros_version, r.environment_sha256,
 r.provenance, o.input_status, o.acquisition_status, o.response_class, COUNT(*) AS observation_count
 FROM capture_runs r JOIN capture_observations o ON o.run_id=r.id
 GROUP BY r.id,o.input_status,o.acquisition_status,o.response_class;
-- Version-level coverage is a census. This run-level view exposes failures,
-- unknown identities and submitted suffixes separately.
CREATE VIEW v_capture_run_coverage AS
 SELECT r.id AS run_id,r.probe,r.routeros_version,r.environment_sha256,r.provenance,
 COUNT(o.id) AS observation_count,
 COUNT(DISTINCT o.script_id) AS current_source_count,
 (SELECT COUNT(*) FROM source_scripts) AS corpus_script_count,
 SUM(CASE WHEN o.acquisition_status='ok' THEN 1 ELSE 0 END) AS acquired_count,
 SUM(CASE WHEN o.input_status='matched' THEN 1 ELSE 0 END) AS matched_count,
 SUM(CASE WHEN o.input_status='stale' THEN 1 ELSE 0 END) AS stale_count,
 SUM(CASE WHEN o.input_status='unknown' THEN 1 ELSE 0 END) AS unknown_input_count,
 SUM(CASE WHEN o.input_status='matched' AND o.acquisition_status='ok'
 AND json_extract(o.input_json,'$.truncated')=0 THEN 1 ELSE 0 END) AS full_submitted_count
 FROM capture_runs r LEFT JOIN capture_observations o ON o.run_id=r.id GROUP BY r.id;
-- Only exact, current, full inputs within a shared capture session can pair.
-- Both response forms remain visible: this is never an acceptance denominator.
CREATE VIEW v_comparable_capture_pairs AS
 SELECT p.id AS parse_observation_id,h.id AS highlight_observation_id,p.script_id,
 pr.id AS parse_run_id,hr.id AS highlight_run_id,pr.routeros_version,
 pr.environment_sha256,p.submitted_sha256,p.response_class AS parse_response_class,
 h.response_class AS highlight_response_class
 FROM capture_observations p JOIN capture_runs pr ON pr.id=p.run_id AND pr.probe='parseil'
 JOIN capture_observations h ON h.script_id=p.script_id
 JOIN capture_runs hr ON hr.id=h.run_id AND hr.probe='highlight'
 WHERE pr.environment_sha256=hr.environment_sha256
 AND p.input_status='matched' AND h.input_status='matched'
 AND p.acquisition_status='ok' AND h.acquisition_status='ok'
 AND p.source_sha256=h.source_sha256 AND p.submitted_sha256=h.submitted_sha256
 AND json_extract(p.input_json,'$.rootMenu')=json_extract(h.input_json,'$.rootMenu')
 AND json_extract(p.input_json,'$.truncated')=0 AND json_extract(h.input_json,'$.truncated')=0
 AND json_extract(h.highlight_json,'$.aligned')=1;
`)
}

interface LegacyParse {
	run_id: number
	script_id: number
	path: string
	routeros_version: string
	ok: number
	status: string
	il_text: string | null
	error: string | null
	parse_ms: number | null
}

export function importLegacyEvidence(db: Database): void {
	const runs = db.query("SELECT * FROM analysis_runs WHERE analysis_name IN ('parseil','highlight') ORDER BY id").all() as Array<{
		id: number
		analysis_name: string
		routeros_version: string
		source_path: string | null
		captured_at: string | null
		summary_json: string | null
	}>
	const insertRun = db.prepare('INSERT INTO capture_runs VALUES (?,?,?,?,?,?,?,?)')
	for (const run of runs) {
		// A legacy highlight summary may describe its own environment. Retain it
		// without manufacturing a same-environment relation to a parse run.
		let environmentSha: string | null = null
		const summary = run.summary_json ? JSON.parse(run.summary_json) : null
		if (summary?.environment) {
			const environment = { legacyRun: run.id, recorded: summary.environment, unknown: ['device-mode', 'menu inventory', 'capture session', 'object state'] }
			const json = JSON.stringify(environment)
			environmentSha = hash(json)
			db.prepare('INSERT OR IGNORE INTO capture_environments VALUES (?,?,NULL,?)').run(environmentSha, json, 'partial-legacy')
		}
		insertRun.run(`legacy:${run.id}`, run.analysis_name, run.routeros_version, environmentSha, run.source_path, run.captured_at, null, 'legacy-unknown-input')
	}
	const insert = db.prepare(`INSERT INTO capture_observations
 (run_id,script_id,source_path,input_status,acquisition_status,response_class,classifier_version,response_text,diagnostics_json,error,elapsed_ms)
 VALUES (?,?,?,'unknown',?,?,?,?,?,?,?)`)
	const rows = db
		.query(`SELECT p.*,s.path FROM parseil_results p JOIN source_scripts s ON s.id=p.script_id ORDER BY p.run_id,p.script_id`)
		.all() as LegacyParse[]
	for (const row of rows) {
		const acquired = row.ok === 1 && row.status !== 'missing-il'
		const classification = classifyParseResponse(row.ok === 1, row.il_text)
		insert.run(
			`legacy:${row.run_id}`,
			row.script_id,
			row.path,
			acquired ? 'ok' : row.status === 'missing-il' ? 'missing' : 'failed',
			classification.responseClass,
			CLASSIFIER_VERSION,
			row.il_text,
			JSON.stringify(classification.diagnostics),
			row.error,
			row.parse_ms,
		)
	}
	const highlights = db
		.query(`SELECT h.*,s.path FROM highlight_results h JOIN source_scripts s ON s.id=h.script_id ORDER BY h.run_id,h.script_id`)
		.all() as Array<{
		run_id: number
		script_id: number
		path: string
		error: string | null
		elapsed_ms: number
	}>
	for (const row of highlights) {
		insert.run(
			`legacy:${row.run_id}`,
			row.script_id,
			row.path,
			row.error === null ? 'ok' : 'failed',
			row.error === null ? 'summary-only' : 'capture-failed',
			CLASSIFIER_VERSION,
			null,
			'[]',
			row.error,
			row.elapsed_ms,
		)
	}
}

export function importCaptureRuns(db: Database, files: string[], dataDir: string): void {
	const insert = db.prepare(`INSERT INTO capture_observations
 (run_id,script_id,source_path,source_sha256,submitted_sha256,input_json,input_status,acquisition_status,response_class,classifier_version,
 response_text,response_json,diagnostics_json,error,submission,elapsed_ms,highlight_json)
 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
	for (const path of files.filter((file) => /^captures\/[^/]+\.json$/.test(relative(dataDir, file))).sort()) {
		const run = JSON.parse(readFileSync(path, 'utf8')) as CaptureRun
		if (run.format !== EVIDENCE_FORMAT || !['parseil', 'highlight'].includes(run.probe)) throw new Error(`Unsupported capture format: ${path}`)
		if (
			hash(JSON.stringify(run.environment)) !== run.environmentSha256 ||
			hash(JSON.stringify(run.environment.menuInventory)) !== run.environment.menuInventorySha256
		)
			throw new Error(`Environment hash mismatch: ${path}`)
		db.prepare('INSERT OR IGNORE INTO capture_environments VALUES (?,?,?,?)').run(
			run.environmentSha256,
			JSON.stringify(run.environment),
			run.environment.menuInventorySha256,
			'recorded-session',
		)
		db.prepare('INSERT INTO capture_runs VALUES (?,?,?,?,?,?,?,?)').run(
			run.id,
			run.probe,
			run.environment.version,
			run.environmentSha256,
			relative(dataDir, path),
			run.capturedAt,
			JSON.stringify(run.selection),
			'recorded-session',
		)
		const identities: Array<[string, string]> = []
		for (const observation of run.observations) {
			const input = observation.input
			if ((run.probe === 'parseil') !== (input.variant === 'original')) throw new Error(`Probe/input variant mismatch: ${path}`)
			const source = db.query('SELECT id,sha256 FROM source_scripts WHERE path=?').get(input.sourcePath) as { id: number; sha256: string } | null
			const status = validateObservation(observation, source?.sha256 ?? null)
			identities.push([input.sourcePath, input.sourceSha256])
			const classification =
				run.probe === 'parseil'
					? classifyParseResponse(observation.acquisition === 'ok', capturedResponseText('parseil', observation.response), input.sourceText)
					: {
							responseClass:
								observation.acquisition !== 'ok'
									? 'capture-failed'
									: observation.highlight?.aligned !== true
										? 'highlight-misaligned'
										: observation.highlight.firstErrorByte === null
											? 'highlight-no-hard-error'
											: 'highlight-error',
							diagnostics: [],
						}
			const inserted = insert.run(
				run.id,
				source?.id ?? null,
				input.sourcePath,
				input.sourceSha256,
				input.submittedSha256,
				JSON.stringify(input),
				status,
				observation.acquisition,
				classification.responseClass,
				CLASSIFIER_VERSION,
				run.probe === 'parseil' ? capturedResponseText('parseil', observation.response) : null,
				JSON.stringify(observation.response),
				JSON.stringify(classification.diagnostics),
				observation.error,
				observation.submission,
				observation.elapsedMs,
				observation.highlight === null ? null : JSON.stringify(observation.highlight),
			)
			for (const attribution of observation.causes ?? []) {
				if (!attribution.scope || attribution.evidence == null) throw new Error('Cause attribution requires scope and evidence')
				db.prepare('INSERT INTO cause_attributions VALUES (?,?,?,?)').run(
					Number(inserted.lastInsertRowid),
					attribution.cause,
					attribution.scope,
					JSON.stringify(attribution.evidence),
				)
			}
		}
		if (hash(JSON.stringify(identities)) !== run.selection.sourceSetSha256) throw new Error(`Selected source-set hash mismatch: ${path}`)
	}
}
