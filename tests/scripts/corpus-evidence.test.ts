import { afterAll, describe, expect, test } from 'bun:test'
import { Database } from 'bun:sqlite'
import { mkdirSync, mkdtempSync, rmSync, writeFileSync, readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { createSchema } from '../../scripts/build-corpus-db'
import { createEvidenceSchema, importCaptureRuns, importLegacyEvidence } from '../../scripts/corpus-db-evidence'
import {
	classifyParseResponse,
	decodeSource,
	encodeResponse,
	decodeResponse,
	trackedSourcePaths,
	hash,
	prepareInput,
	validateObservation,
	type CaptureEnvironment,
	type CaptureObservation,
	type CaptureRun,
	type Probe,
	type StoredResponse,
} from '../../scripts/corpus-evidence'

const temp = mkdtempSync(join(tmpdir(), 'routeros-corpus-'))
afterAll(() => rmSync(temp, { recursive: true, force: true }))

describe('response forms are independent of acquisition and root cause', () => {
	test.each([
		[false, '(evl /putmessage=hello)', 'capture-failed'],
		[true, null, 'missing-response'],
		[true, 'syntax error (line 1 column 3)', 'plain-diagnostic'],
		[true, 'missing closing brace (line 2 column 1)', 'plain-diagnostic'],
		[true, 'expected end of command (line 1 column 7)', 'plain-diagnostic'],
		[true, '(evl bad parameter decimator (line 18 column 47) /serialize)', 'embedded-diagnostic'],
		[true, '(<%% bad command name regex (line 1 column 2) regex)', 'embedded-diagnostic'],
		[true, '(evl /putmessage=(<%% 1 2))', 'il-no-recognized-diagnostic'],
		[true, '(evl /putmessage=bad command name regex (line 1 column 2))', 'il-no-recognized-diagnostic'],
		[true, '(evl /putmessage=(<%% bad command name regex (line 1 column 2) regex))', 'ambiguous-diagnostic'],
		[true, '/;(evl /findkey=");(evl (evl bad parameter ... (line 7 column 63) /tool/fetch))', 'embedded-diagnostic'],
		[true, '', 'il-no-recognized-diagnostic'],
		[true, 'new firmware message', 'unknown-response'],
	] as const)('%s / %s -> %s', (ok, text, expected) => {
		expect(classifyParseResponse(ok, text).responseClass).toBe(expected)
	})
	test('keeps all recognized diagnostic positions without attributing absent menus', () => {
		const text = '(evl bad parameter decimator (line 18 column 47));(<%% bad command name bfd (line 20 column 2) bfd)'
		const result = classifyParseResponse(true, text)
		expect(result.diagnostics.map((d) => [d.family, d.line, d.column])).toEqual([
			['parameter-name', 18, 47],
			['command-resolution', 20, 2],
		])
		for (const diagnostic of result.diagnostics) expect(text.slice(diagnostic.responseStart, diagnostic.responseEnd)).toBe(diagnostic.message)
	})
})

function observation(text: string, probe: Probe): CaptureObservation {
	const input = prepareInput('sample.rsc', text, probe)
	return {
		input,
		acquisition: 'ok',
		submission: probe === 'parseil' ? 'file-readback-verified' : 'requested',
		response: probe === 'parseil' ? { ret: '(evl /putmessage=1)' } : [{ highlight: Array(input.submittedBytes).fill('none').join(',') }],
		error: null,
		elapsedMs: 1,
		highlight: probe === 'parseil' ? null : { tokenCount: input.submittedBytes, aligned: true, firstErrorByte: null, types: ['none'] },
	}
}

test('UTF-16 normalization, astral characters, CRLF and truncation are explicit', () => {
	const text = ':put "é😀"\r\n' + 'x'.repeat(32767)
	const input = prepareInput('sample.rsc', text, 'highlight')
	expect(input.submittedText.startsWith(':put "???"\r\n')).toBe(true)
	expect(input.submittedUtf16).toBe(32767)
	expect(input.submittedBytes).toBe(32767)
	expect(input.replacedCodeUnits).toBe(3)
	expect(input.truncated).toBe(true)
	expect(input.submittedSpan).toEqual([0, 32767])
	expect(prepareInput('sample.rsc', text, 'parseil').submittedText).toBe(text)
})

test('equal-length source edits go stale; corrupt identities and mapping fail closed', () => {
	const captured = observation(':put 1', 'parseil')
	expect(validateObservation(captured, hash(':put 1'))).toBe('matched')
	expect(validateObservation(captured, hash(':put 2'))).toBe('stale')
	expect(validateObservation(captured, null)).toBe('source-missing')
	const corrupt = structuredClone(captured)
	corrupt.input.submittedText = ':put 2'
	expect(() => validateObservation(corrupt, hash(':put 1'))).toThrow('hash mismatch')
	corrupt.input = { ...captured.input, submittedSpan: [0, 1] }
	expect(() => validateObservation(corrupt, hash(':put 1'))).toThrow('metadata mismatch')
	const highlight = observation(':put 1', 'highlight')
	if (highlight.highlight) highlight.highlight.aligned = false
	expect(() => validateObservation(highlight, hash(':put 1'))).toThrow('coverage metadata mismatch')
})

test('verified source keeps prefixed diagnostic-looking string literals ambiguous', () => {
	const text = '(evl /putmessage=prefix;(<%% bad command name regex (line 1 column 2) regex))'
	const source = ':put "prefix;(<%% bad command name regex (line 1 column 2) regex)"'
	expect(classifyParseResponse(true, text, source).responseClass).toBe('ambiguous-diagnostic')
})

function database(text = ':put 1'): Database {
	const db = new Database(':memory:')
	db.exec('PRAGMA foreign_keys=ON')
	createSchema(db)
	createEvidenceSchema(db)
	db.prepare(`INSERT INTO source_scripts
	(path,collection,bytes,chars,line_count,sha256,is_empty,is_oversize_32k,has_cli_prompt,has_comment_header,first_line,text)
	VALUES ('sample.rsc','synthetic',?,?,1,?,0,0,0,0,?,CAST(? AS TEXT))`).run(Buffer.byteLength(text), text.length, hash(text), text, new TextEncoder().encode(text))
	return db
}

function environment(sessionId: string): CaptureEnvironment {
	return {
		sessionId,
		version: '7.24.2',
		buildTime: 'fixture',
		architecture: 'x86',
		board: 'CHR',
		packages: [],
		deviceMode: {},
		configuration: { scope: 'synthetic', unrecorded: [] },
		menuInventory: [],
		menuInventorySha256: hash('[]'),
	}
}

function capture(probe: Probe, session = 'a', text = ':put 1'): string {
	const obs = observation(text, probe)
	const env = environment(session)
	const run: CaptureRun = {
		format: 1,
		id: `${session}-${probe}`,
		probe,
		capturedAt: '2026-10-16T00:00:00Z',
		environment: env,
		environmentSha256: hash(JSON.stringify(env)),
		selection: { target: null, limit: null, sourceSetSha256: hash(JSON.stringify([['sample.rsc', obs.input.sourceSha256]])) },
		observations: [obs],
	}
	const dir = join(temp, 'captures')
	mkdirSync(dir, { recursive: true })
	const path = join(dir, `${run.id}.json`)
	writeFileSync(path, JSON.stringify(run))
	return path
}

test('roundtrip retains multiple sessions on one firmware and pairs only exact current inputs', () => {
	const db = database()
	const files = [capture('parseil'), capture('highlight'), capture('parseil', 'b'), capture('highlight', 'c')]
	importCaptureRuns(db, files, temp)
	expect(db.query('SELECT COUNT(*) n FROM capture_runs').get()).toEqual({ n: 4 })
	expect(db.query('SELECT COUNT(*) n FROM v_comparable_capture_pairs').get()).toEqual({ n: 1 })
	expect(db.query('SELECT COUNT(*) n FROM cause_attributions').get()).toEqual({ n: 0 })
	db.close()
	const stale = database(':put 2')
	importCaptureRuns(stale, files, temp)
	expect(stale.query('SELECT COUNT(*) n FROM v_comparable_capture_pairs').get()).toEqual({ n: 0 })
	expect(stale.query("SELECT COUNT(*) n FROM capture_observations WHERE input_status='stale'").get()).toEqual({ n: 4 })
	stale.close()
})

test('transformed or truncated inputs never pair as whole-source observations', () => {
	for (const text of [':put "é"', 'x'.repeat(32768)]) {
		const db = database(text)
		importCaptureRuns(db, [capture('parseil', 'transformed', text), capture('highlight', 'transformed', text)], temp)
		expect(db.query('SELECT COUNT(*) n FROM v_comparable_capture_pairs').get()).toEqual({ n: 0 })
		db.close()
	}
})

test('multiple scoped cause annotations survive a manifest import', async () => {
	const path = capture('parseil', 'annotated')
	const run = (await Bun.file(path).json()) as CaptureRun
	run.observations[0].causes = [
		{ cause: 'unknown', scope: 'whole-script', evidence: { reason: 'first failure may mask later failures' } },
		{ cause: 'parameter-name', scope: 'minimized-control', evidence: { observation: 'fixture-only' } },
	]
	writeFileSync(path, JSON.stringify(run))
	const db = database()
	importCaptureRuns(db, [path], temp)
	expect(db.query('SELECT cause,scope FROM cause_attributions ORDER BY cause').all()).toEqual([
		{ cause: 'parameter-name', scope: 'minimized-control' },
		{ cause: 'unknown', scope: 'whole-script' },
	])
	db.close()
})

test('summary counts survive unrelated artifact multiplication; missing captures remain zero', () => {
	const db = database()
	db.exec(`INSERT INTO analysis_runs(id,analysis_name,routeros_version) VALUES (1,'parseil','fixture');
	INSERT INTO parseil_results(run_id,script_id,routeros_version,ok,status,meta_path,il_text) VALUES (1,1,'fixture',1,'ok','fixture','syntax error (line 1 column 1)');`)
	for (let i = 0; i < 3; i++) {
		db.prepare("INSERT INTO artifact_files(id,script_id,artifact_kind,path,bytes,sha256,content_type) VALUES (?,1,'synthetic',?,0,'x','text/plain')").run(
			i + 1,
			`artifact-${i}`,
		)
		db.prepare(
			"INSERT INTO highlight_snapshots(script_id,artifact_id,token_count,expected_chars,token_count_match,unique_token_types_json,error_token_count) VALUES (1,?,0,0,1,'[]',0)",
		).run(i + 1)
	}
	expect(db.query('SELECT parseil_ok_count,parseil_error_count FROM v_script_summary').get()).toEqual({ parseil_ok_count: 1, parseil_error_count: 0 })
	importLegacyEvidence(db)
	expect(db.query('SELECT input_status,acquisition_status,response_class,source_sha256,submitted_sha256 FROM capture_observations').get()).toEqual({
		input_status: 'unknown',
		acquisition_status: 'ok',
		response_class: 'plain-diagnostic',
		source_sha256: null,
		submitted_sha256: null,
	})
	db.exec('DELETE FROM parseil_results')
	expect(db.query('SELECT parseil_ok_count,parseil_error_count FROM v_script_summary').get()).toEqual({ parseil_ok_count: 0, parseil_error_count: 0 })
	db.close()
})

test('checked-in corpus retains the bridge, selected representatives and honest per-script counts', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	const bridge = JSON.parse(readFileSync(resolve(import.meta.dir, '../../test-data/corpus-bridge.v7.24.2.json'), 'utf8'))
	expect([bridge.joinedSourceCount, bridge.identicalReadouts, bridge.differentReadouts, bridge.failedAcquisitions]).toEqual([
		948,
		947,
		0,
		['edge-cases/oversize-32k.rsc'],
	])
	expect(db.query("SELECT DISTINCT routeros_version FROM capture_runs WHERE provenance='legacy-unknown-input' ORDER BY routeros_version").all()).toEqual([
		{ routeros_version: '7.20.8' },
		{ routeros_version: '7.22.1' },
		{ routeros_version: '7.9.2' },
	])
	expect(
		db
			.query(`SELECT COUNT(*) n FROM v_script_summary v WHERE
	v.parseil_ok_count != (SELECT COUNT(*) FROM parseil_results p WHERE p.script_id=v.id AND p.ok=1) OR
	v.parseil_error_count != (SELECT COUNT(*) FROM parseil_results p WHERE p.script_id=v.id AND p.ok=0)`)
			.get(),
	).toEqual({ n: 0 })
	db.close()
})

// Independent selection and database indexing paths must enumerate the same
// tracked sources, even when the much larger sidecar listing exceeds 1 MiB.
test('collector source selection matches the full indexed census', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	const indexed = db.query('SELECT path,sha256 FROM source_scripts').all() as Array<{ path: string; sha256: string }>
	expect(
		trackedSourcePaths(resolve(import.meta.dir, '../..'))
			.map((path) => path.slice('test-data/'.length))
			.sort(),
	).toEqual(indexed.map((row) => row.path).sort())
	for (const row of indexed) expect(hash(decodeSource(readFileSync(resolve(import.meta.dir, '../../test-data', row.path))))).toBe(row.sha256)
	db.close()
})

test('fresh device controls preserve operator, literal and diagnostic distinctions', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	const rows = db
		.query(`SELECT o.source_path,o.response_class FROM capture_observations o JOIN capture_runs r ON r.id=o.run_id
	WHERE r.id=(SELECT parse_run_id FROM capture_channels WHERE channel='stable') AND o.source_path LIKE 'capture-controls/%' ORDER BY o.source_path`)
		.all()
	expect(rows).toEqual([
		{ source_path: 'capture-controls/apply.rsc', response_class: 'il-no-recognized-diagnostic' },
		{ source_path: 'capture-controls/bad-command.rsc', response_class: 'embedded-diagnostic' },
		{ source_path: 'capture-controls/bad-parameter.rsc', response_class: 'embedded-diagnostic' },
		{ source_path: 'capture-controls/echo-diagnostic.rsc', response_class: 'il-no-recognized-diagnostic' },
		{ source_path: 'capture-controls/echo-node.rsc', response_class: 'ambiguous-diagnostic' },
		{ source_path: 'capture-controls/literal-quote.rsc', response_class: 'embedded-diagnostic' },
		{ source_path: 'capture-controls/missing-brace.rsc', response_class: 'plain-diagnostic' },
	])
	db.close()
})

test('source decoding preserves a UTF-8 BOM and rejects invalid bytes', () => {
	const text = '\ufeff:put 1\r\n'
	expect(decodeSource(Buffer.from(text, 'utf8'))).toBe(text)
	expect(() => decodeSource(Buffer.from([0xc3, 0x28]))).toThrow()
})

test('compact responses roundtrip raw readouts and highlight classes losslessly', () => {
	for (const response of [{ ret: '' }, { ret: '(evl /putmessage=1)', extra: 'preserved' }, null, [], { ret: 42 }, 'unexpected']) {
		expect(decodeResponse(encodeResponse('parseil', response))).toEqual(response)
	}
	for (const response of [
		[{ type: 'highlight', highlight: '' }],
		[{ type: 'highlight', highlight: 'cmd,cmd,none,none,none,error' }],
		null,
		[],
		[{ unexpected: 'retained' }],
		[null],
		['unexpected'],
		[{ highlight: null }],
		{ unexpected: 'object' },
		[{ highlight: Array(32768).fill('none').join(',') }],
	]) {
		expect(decodeResponse(encodeResponse('highlight', response))).toEqual(response)
	}
	const compressed = encodeResponse('highlight', [{ highlight: 'cmd,cmd,none,none,none,error' }])
	expect(JSON.parse(compressed.responseJson)).toEqual([
		{
			highlight: [
				['cmd', 2],
				['none', 3],
				['error', 1],
			],
		},
	])
	expect(encodeResponse('parseil', { ret: 'hello' }).responseJson).toBe('{}')
	expect(() => decodeResponse({ responseText: null, responseJson: '[{"highlight":[["none",0]]}]', encoding: 'highlight-rle-v1' })).toThrow(
		'Invalid highlight run',
	)
})

test.each([
	[':put "é"', ':put "?"'],
	['\ufeff:put 1', '?:put 1'],
])('compact input joins retain %s through matched, stale and missing source states', (text, highlighted) => {
	const session = `stale-${hash(text).slice(0, 8)}`
	const files = [capture('parseil', session, text), capture('highlight', session, text)]
	for (const mode of ['matched', 'stale', 'missing']) {
		const db = database(mode === 'matched' ? text : ':put "z"')
		if (mode === 'missing') db.exec('DELETE FROM source_scripts_fts; DELETE FROM source_scripts')
		importCaptureRuns(db, files, temp)
		const rows = db
			.query(
				'SELECT o.input_status,o.source_sha256,i.input_json,i.source_text,i.submitted_text FROM capture_observations o JOIN v_capture_inputs i ON i.observation_id=o.id ORDER BY o.run_id DESC,o.id',
			)
			.all() as Array<{ input_status: string; source_sha256: string; input_json: string; source_text: string; submitted_text: string }>
		expect(rows.map((row) => row.source_text)).toEqual([text, text])
		expect(rows.map((row) => row.submitted_text)).toEqual([text, highlighted])
		expect(rows.map((row) => row.input_status)).toEqual(Array(2).fill(mode === 'missing' ? 'source-missing' : mode))
		expect(rows.every((row) => !Object.prototype.hasOwnProperty.call(JSON.parse(row.input_json), 'sourceText'))).toBe(true)
		expect(Object.prototype.hasOwnProperty.call(JSON.parse(rows[0].input_json), 'submittedText')).toBe(false)
		expect(db.query('SELECT COUNT(*) n FROM capture_source_history').get()).toEqual({ n: mode === 'matched' ? 0 : 1 })
		db.close()
	}
})

test('a leading BOM in a captured readout survives SQLite text storage', () => {
	const db = database()
	const file = capture('parseil', 'bom-response')
	const run = JSON.parse(readFileSync(file, 'utf8')) as CaptureRun
	run.observations[0].response = { ret: '\ufeffunexpected parser readout' }
	writeFileSync(file, JSON.stringify(run))
	importCaptureRuns(db, [file], temp)
	const row = db.query('SELECT response_text,response_json,response_encoding FROM capture_observations').get() as {
		response_text: string
		response_json: string
		response_encoding: StoredResponse['encoding']
	}
	expect(row.response_text).toBe('\ufeffunexpected parser readout')
	expect(decodeResponse({ responseText: row.response_text, responseJson: row.response_json, encoding: row.response_encoding })).toEqual(run.observations[0].response)
	db.close()
})

test('default outcomes keep source-missing study observations visible', () => {
	const db = database()
	db.exec('DELETE FROM source_scripts_fts; DELETE FROM source_scripts')
	importCaptureRuns(db, [capture('parseil', 'source-missing-outcome')], temp)
	expect(db.query('SELECT input_status,observation_count FROM v_capture_outcomes').all()).toEqual([
		{ input_status: 'source-missing', observation_count: 1 },
	])
	expect(db.query('SELECT COUNT(*) n FROM v_comparable_capture_pairs').get()).toEqual({ n: 0 })
	db.close()
})

test('controls and conformance inputs remain inspectable but excluded from default study views', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	expect(db.query('SELECT COUNT(*) n FROM v_corpus_population').get()).toEqual({ n: 948 })
	expect(db.query("SELECT COUNT(*) n FROM source_scripts WHERE collection='capture-controls'").get()).toEqual({ n: 7 })
	expect(db.query("SELECT COUNT(*) n FROM source_scripts WHERE collection='wiresage-conformance'").get()).toEqual({ n: 875 })
	expect(
		db.query("SELECT COUNT(*) n FROM v_comparable_capture_pairs p JOIN source_scripts s ON s.id=p.script_id WHERE s.collection IN ('capture-controls','wiresage-conformance')").get(),
	).toEqual({ n: 0 })
	const rows = db
		.query(
			"SELECT observation_count,current_source_count,control_count,corpus_script_count,matched_count FROM v_capture_run_coverage WHERE provenance='recorded-session'",
		)
		.all()
	expect(rows.length).toBe(8)
	for (const row of rows)
		expect(row).toEqual({ observation_count: 1830, current_source_count: 948, control_count: 7, corpus_script_count: 948, matched_count: 948 })
	expect(db.query('SELECT COUNT(*) n FROM capture_channels').get()).toEqual({ n: 4 })
	expect(db.query('SELECT COUNT(*) n FROM capture_inputs').get()).toEqual({ n: 3660 })
	expect(
		db
			.query("SELECT COUNT(*) n FROM analysis_runs WHERE json_type(summary_json,'$.results') IS NOT NULL OR json_type(summary_json,'$.probes') IS NOT NULL")
			.get(),
	).toEqual({ n: 0 })
	db.close()
})

test.each(['long-term', 'stable', 'testing', 'development'])('%s selected environment retains enabled optional packages', (channel) => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	const row = db
		.query('SELECT e.environment_json FROM capture_channels c JOIN capture_environments e ON e.sha256=c.environment_sha256 WHERE c.channel=?')
		.get(channel) as { environment_json: string }
	const { packages } = JSON.parse(row.environment_json) as { packages: Array<{ name: string; disabled: string | boolean | null }> }
	const enabled = packages.filter((pkg) => pkg.disabled === false || pkg.disabled === 'false').map((pkg) => pkg.name)
	for (const name of ['routeros', 'wireless', 'container', 'user-manager', 'iot', 'gps', 'ups']) expect(enabled).toContain(name)
	db.close()
})

test.each(
	['long-term', 'stable', 'testing', 'development'].flatMap((channel) => ['parseil', 'highlight'].map((probe) => [channel, probe] as const)),
)('%s %s manifest roundtrips compact inputs and raw responses', (channel, probe) => {
	const root = resolve(import.meta.dir, '../../test-data')
	const db = new Database(join(root, 'corpus.sqlite'), { readonly: true })
	const column = probe === 'parseil' ? 'parse_run_id' : 'highlight_run_id'
	const run = db.query(`SELECT r.id,r.source_path FROM capture_channels c JOIN capture_runs r ON r.id=c.${column} WHERE c.channel=?`).get(channel) as {
		id: string
		source_path: string
	}
	const get = db.query(
		'SELECT o.*,i.source_text,i.submitted_text FROM capture_observations o JOIN v_capture_inputs i ON i.observation_id=o.id WHERE o.run_id=? AND o.source_path=?',
	)
	if (!/^captures\/[a-f0-9-]+-(?:parseil|highlight)\.json$/.test(run.source_path)) throw new Error('Unexpected manifest reference')
	const manifest = JSON.parse(readFileSync(join(root, run.source_path), 'utf8')) as CaptureRun
	for (const original of manifest.observations) {
		const row = get.get(run.id, original.input.sourcePath) as {
			source_text: string
			submitted_text: string
			source_sha256: string
			submitted_sha256: string
			response_text: string | null
			response_json: string
			response_encoding: StoredResponse['encoding']
		}
		expect(row.source_text).toBe(original.input.sourceText)
		expect(row.submitted_text).toBe(original.input.submittedText)
		expect(hash(row.source_text)).toBe(row.source_sha256)
		expect(hash(row.submitted_text)).toBe(row.submitted_sha256)
		expect(decodeResponse({ responseText: row.response_text, responseJson: row.response_json, encoding: row.response_encoding })).toEqual(original.response)
	}
	expect(manifest.observations.length).toBe(1830)
	db.close()
})
