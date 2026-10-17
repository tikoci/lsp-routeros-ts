import { afterAll, expect, test } from 'bun:test'
import { Database } from 'bun:sqlite'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { createSchema } from '../../scripts/build-corpus-db'
import { createEvidenceSchema } from '../../scripts/corpus-db-evidence'
import { hash } from '../../scripts/corpus-evidence'
import { conformanceCases, conformanceFiles, importConformanceCases, writeConformanceCollection, WIRESAGE_ORACLE, WIRESAGE_REVISION } from '../../scripts/wiresage-conformance'

const root = resolve(import.meta.dir, '../../test-data')
const collection = join(root, 'wiresage-conformance')
const temporary = mkdtempSync(join(tmpdir(), 'wiresage-conformance-'))
afterAll(() => rmSync(temporary, { recursive: true, force: true }))
const upstreamBytes = readFileSync(join(collection, 'upstream-cases.json'))
const licenseBytes = readFileSync(join(collection, 'LICENSE'))

test('case identities retain duplicate upstream IDs across sections and reject unsafe collisions', () => {
	const encode = (value: unknown) => Buffer.from(JSON.stringify(value))
	const row = { id: 'd12', section: '$ forms outside strings', source: '$1', valid: true }
	expect(conformanceCases(encode([row, { ...row, section: 'what makes :set legal' }])).map((entry) => entry.path)).toEqual(['forms-outside-strings/d12.rsc', 'what-makes-set-legal/d12.rsc'])
	for (const value of [[], [row, row], [{ ...row, id: '../escape' }], [{ ...row, section: '!!!' }], [{ ...row, valid: 'false' }]]) expect(() => conformanceCases(encode(value))).toThrow()
	expect(() => conformanceCases(encode([row, { ...row, section: 'forms-outside-strings' }]))).toThrow('Duplicate')
})

test('source bytes survive BOM, CRLF, empty input and missing final newline', () => {
	const files = new Map(['\ufeff:put 1', ':put 1\r\n:put 2', '', ':put 1'].map((text, index) => [`layout/${index}.rsc`, Buffer.from(text)]))
	writeConformanceCollection(temporary, files)
	for (const [path, bytes] of files) expect(readFileSync(join(temporary, path))).toEqual(bytes)
	writeConformanceCollection(temporary, files)
	expect(() => writeConformanceCollection(temporary, new Map())).toThrow('Unexpected case')
})

test('import checks preserve all 875 pinned cases, metadata and MIT license byte-exactly', () => {
	const files = conformanceFiles(upstreamBytes, licenseBytes)
	expect(files.size).toBe(878)
	for (const [path, bytes] of files) expect(readFileSync(join(collection, path))).toEqual(bytes)
	const cases = conformanceCases(upstreamBytes)
	expect(cases.length).toBe(875)
	expect(new Set(cases.map((row) => row.upstream.id)).size).toBe(844)
	expect(cases.filter((row) => row.upstream.valid).length).toBe(542)
	expect(cases.find((row) => row.upstream.id === 'j10')?.upstream.source.startsWith('\ufeff')).toBe(true)
	expect(() => conformanceFiles(Buffer.from('[]'), licenseBytes)).toThrow('checksum')
	expect(() => conformanceFiles(upstreamBytes, Buffer.from('MIT'))).toThrow('checksum')
})

test('third-party observations are indexed separately and verified before import', () => {
	const db = new Database(':memory:')
	db.exec('PRAGMA foreign_keys=ON')
	createSchema(db)
	createEvidenceSchema(db)
	const insert = db.prepare(`INSERT INTO source_scripts
	(path,collection,bytes,chars,line_count,sha256,is_empty,is_oversize_32k,has_cli_prompt,has_comment_header,first_line,text)
	VALUES (?,'wiresage-conformance',?,?,1,?,0,0,0,0,'',CAST(? AS TEXT))`)
	for (const { path, upstream } of conformanceCases(upstreamBytes))
		insert.run(`wiresage-conformance/${path}`, Buffer.byteLength(upstream.source), upstream.source.length, hash(upstream.source), new TextEncoder().encode(upstream.source))
	const files = [...conformanceFiles(upstreamBytes, licenseBytes).keys()].map((path) => join(collection, path))
	expect(() =>
		importConformanceCases(
			db,
			files.filter((file) => file !== join(collection, 'LICENSE')),
			root,
		),
	).toThrow('license')
	expect(() =>
		importConformanceCases(
			db,
			files.filter((file) => file !== join(collection, 'upstream-cases.json')),
			root,
		),
	).toThrow('raw upstream')
	expect(() =>
		importConformanceCases(
			db,
			files.filter((file) => file !== join(collection, 'comments/c1.rsc')),
			root,
		),
	).toThrow('Untracked')
	for (const path of ['derived.rsc', 'comments/minimized.rsc']) {
		expect(() => importConformanceCases(db, [...files, join(collection, path)], root)).toThrow('Unexpected conformance case')
		expect(db.query('SELECT COUNT(*) n FROM third_party_cases').get()).toEqual({ n: 0 })
	}
	importConformanceCases(db, [...files, join(root, 'wiresage-conformance-derived/case.rsc')], root)
	expect(db.query('SELECT COUNT(*) n,SUM(upstream_valid) labelled_true FROM third_party_cases').get()).toEqual({ n: 875, labelled_true: 542 })
	expect(db.query('SELECT DISTINCT upstream_revision,upstream_oracle FROM third_party_cases').all()).toEqual([{ upstream_revision: WIRESAGE_REVISION, upstream_oracle: WIRESAGE_ORACLE }])
	expect(db.query('SELECT COUNT(*) n FROM capture_observations').get()).toEqual({ n: 0 })
	expect(db.query('SELECT COUNT(*) n FROM v_corpus_population').get()).toEqual({ n: 0 })
	db.close()
})

test('auxiliary observations never change default population, outcomes or comparable pairs', () => {
	const db = new Database(':memory:')
	createSchema(db)
	createEvidenceSchema(db)
	for (const [id, collection] of [
		[1, 'root'],
		[2, 'capture-controls'],
		[3, 'wiresage-conformance'],
	] as const)
		db.prepare(`INSERT INTO source_scripts
		(id,path,collection,bytes,chars,line_count,sha256,is_empty,is_oversize_32k,has_cli_prompt,has_comment_header,first_line,text)
		VALUES (?,?,?,0,0,0,'hash',1,0,0,0,'','')`).run(id, `${collection}/case.rsc`, collection)
	db.exec(`INSERT INTO capture_environments VALUES ('env','{}',NULL,'fixture');
	INSERT INTO capture_inputs VALUES ('input','{"rootMenu":"","truncated":false}');`)
	for (const probe of ['parseil', 'highlight']) {
		db.prepare("INSERT INTO capture_runs VALUES (?,?,'7.24.5','env',NULL,NULL,NULL,'fixture')").run(probe, probe)
		for (const id of [1, 2, 3])
			db.prepare(`INSERT INTO capture_observations
		(run_id,script_id,source_path,source_sha256,submitted_sha256,input_id,input_status,acquisition_status,response_class,classifier_version,diagnostics_json,highlight_json)
		VALUES (?,?,?,'hash','hash','input','matched','ok','fixture','fixture','[]','{"aligned":true}')`).run(probe, id, `${id}.rsc`)
	}
	expect(db.query('SELECT COUNT(*) n FROM v_corpus_population').get()).toEqual({ n: 1 })
	expect(db.query('SELECT SUM(observation_count) n FROM v_capture_outcomes').get()).toEqual({ n: 2 })
	expect(db.query('SELECT COUNT(*) n FROM v_comparable_capture_pairs').get()).toEqual({ n: 1 })
	expect(db.query('SELECT COUNT(*) n FROM v_collection_comparable_capture_pairs').get()).toEqual({ n: 3 })
	expect(
		db.query("SELECT observation_count,matched_count,acquired_count,collection_script_count FROM v_collection_capture_coverage WHERE collection='wiresage-conformance' ORDER BY run_id").all(),
	).toEqual([
		{ observation_count: 1, matched_count: 1, acquired_count: 1, collection_script_count: 1 },
		{ observation_count: 1, matched_count: 1, acquired_count: 1, collection_script_count: 1 },
	])
	expect(db.query('SELECT observation_count,current_source_count,corpus_script_count,matched_count FROM v_capture_run_coverage ORDER BY run_id').all()).toEqual([
		{ observation_count: 3, current_source_count: 1, corpus_script_count: 1, matched_count: 1 },
		{ observation_count: 3, current_source_count: 1, corpus_script_count: 1, matched_count: 1 },
	])
	db.close()
})

test('selected channel artifacts cover all conformance inputs without expanding the study population', () => {
	const db = new Database(join(root, 'corpus.sqlite'), { readonly: true })
	expect(db.query('SELECT COUNT(*) n FROM third_party_cases').get()).toEqual({ n: 875 })
	expect(db.query('SELECT COUNT(*) n FROM v_corpus_population').get()).toEqual({ n: 948 })
	const rows = db
		.query(`SELECT v.observation_count,v.collection_script_count,v.matched_count,v.acquired_count,v.full_submitted_count
	FROM capture_channels c JOIN v_collection_capture_coverage v ON v.run_id IN (c.parse_run_id,c.highlight_run_id)
	WHERE v.collection='wiresage-conformance'`)
		.all()
	expect(rows.length).toBe(8)
	for (const row of rows) expect(row).toEqual({ observation_count: 875, collection_script_count: 875, matched_count: 875, acquired_count: 875, full_submitted_count: 875 })
	const pairs = db
		.query(`SELECT c.channel,COUNT(*) n FROM capture_channels c JOIN v_collection_comparable_capture_pairs p
	ON p.parse_run_id=c.parse_run_id AND p.highlight_run_id=c.highlight_run_id WHERE p.collection='wiresage-conformance' GROUP BY c.channel`)
		.all()
	expect(pairs).toEqual(['development', 'long-term', 'stable', 'testing'].map((channel) => ({ channel, n: 861 })))
	expect(db.query('SELECT DISTINCT corpus_script_count FROM v_version_coverage').all()).toEqual([{ corpus_script_count: 948 }])
	db.close()
})
