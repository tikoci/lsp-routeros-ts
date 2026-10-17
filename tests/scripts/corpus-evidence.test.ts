import { afterAll, describe, expect, test } from 'bun:test'
import { Database } from 'bun:sqlite'
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { createSchema } from '../../scripts/build-corpus-db'
import { createEvidenceSchema, importCaptureRuns, importLegacyEvidence } from '../../scripts/corpus-db-evidence'
import {
	classifyParseResponse,
	decodeSource,
	trackedSourcePaths,
	hash,
	prepareInput,
	validateObservation,
	type CaptureEnvironment,
	type CaptureObservation,
	type CaptureRun,
	type Probe,
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
	VALUES ('sample.rsc','synthetic',?,?,1,?,0,0,0,0,?,?)`).run(Buffer.byteLength(text), text.length, hash(text), text, text)
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

test('checked-in corpus keeps the historical partition and all per-script counts honest', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	expect(
		db
			.query(`SELECT o.response_class,COUNT(*) n FROM capture_observations o JOIN capture_runs r ON r.id=o.run_id
	WHERE r.probe='parseil' AND r.routeros_version='7.24.2' AND r.provenance='legacy-unknown-input' GROUP BY o.response_class ORDER BY o.response_class`)
			.all(),
	).toEqual([
		{ response_class: 'capture-failed', n: 1 },
		{ response_class: 'embedded-diagnostic', n: 84 },
		{ response_class: 'il-no-recognized-diagnostic', n: 533 },
		{ response_class: 'plain-diagnostic', n: 330 },
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
	const indexed = db.query('SELECT path FROM source_scripts').all() as Array<{ path: string }>
	expect(
		trackedSourcePaths(resolve(import.meta.dir, '../..'))
			.map((path) => path.slice('test-data/'.length))
			.sort(),
	).toEqual(indexed.map((row) => row.path).sort())
	db.close()
})

test('fresh device controls preserve operator, literal and diagnostic distinctions', () => {
	const db = new Database(resolve(import.meta.dir, '../../test-data/corpus.sqlite'), { readonly: true })
	const rows = db
		.query(`SELECT o.source_path,o.response_class FROM capture_observations o JOIN capture_runs r ON r.id=o.run_id
	WHERE r.id='277bdf1f-50c6-46f6-9380-c5a28ec39a59-parseil' AND o.source_path LIKE 'capture-controls/%' ORDER BY o.source_path`)
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
