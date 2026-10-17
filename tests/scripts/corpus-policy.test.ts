import { afterAll, expect, test } from 'bun:test'
import { Database } from 'bun:sqlite'
import { createSchema } from '../../scripts/build-corpus-db'
import { createEvidenceSchema } from '../../scripts/corpus-db-evidence'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { CHANNELS, insertCaptureChannels, readCorpusPolicy, retainedCorpusFiles, type CorpusPolicy } from '../../scripts/corpus-policy'

const root = mkdtempSync(join(tmpdir(), 'corpus-policy-'))
afterAll(() => rmSync(root, { recursive: true, force: true }))
function policy(): CorpusPolicy {
	const versions = ['7.23.8', '7.24.5', '7.25rc2', '7.26beta1']
	return {
		format: 1,
		maxDatabaseBytes: 80_000_000,
		legacyVersions: ['7.9.2', '7.20.8', '7.22.1'],
		channels: Object.fromEntries(
			CHANNELS.map((channel, index) => [
				channel,
				{
					version: versions[index],
					sessionId: `00000000-0000-4000-8000-00000000000${index}`,
					source: 'https://example.invalid/' + channel,
					response: versions[index] + ' 123',
					resolvedAt: '2026-10-17T00:00:00Z',
				},
			]),
		),
	}
}
function read(value: CorpusPolicy) {
	const path = join(root, 'policy.json')
	writeFileSync(path, JSON.stringify(value))
	return readCorpusPolicy(path)
}
test('retention requires all four channel identities and one released older representative per minor', () => {
	expect(read(policy())).toEqual(policy())
	for (const version of ['7.23rc1', '7.24.2', '7.30.1', '7.20.9']) {
		const invalid = policy()
		invalid.legacyVersions.push(version)
		expect(() => read(invalid)).toThrow('Legacy representatives')
	}
	const absent = policy()
	delete absent.channels.testing
	expect(() => read(absent)).toThrow('all four channels')
	const mismatch = policy()
	mismatch.channels.stable.response = '7.24.6 123'
	expect(() => read(mismatch)).toThrow('Invalid channel identity')
})

test('version pruning keeps source ordering and selects only explicit current sessions and legacy representatives', () => {
	const selected = policy()
	const session = selected.channels.stable.sessionId
	const paths = [
		'capture-controls/apply.rsc',
		'edge-cases/empty.rsc',
		'eworm/global-functions.rsc',
		'edge-cases/empty.rsc.v7.20.8.parseil',
		'edge-cases/empty.rsc.v7.20.8.parseil.meta.json',
		'parseil-summary.v7.22.1.json',
		'highlight-summary.v7.9.2.json',
		'inspect-shapes.v7.9.2.json',
		'parseil-summary.v7.23rc1.json',
		'highlight-summary.v7.24rc2.json',
		'parseil-summary.v7.24.2.json',
		'edge-cases/empty.rsc.v7.24.2.parseil.meta.json',
		'required-args.v7.24.2.meta.json',
		'inspect-shapes.v7.25beta3.json',
		`captures/${session}-parseil.json`,
		`captures/${session}-highlight.json`,
		'captures/277bdf1f-50c6-46f6-9380-c5a28ec39a59-parseil.json',
		'corpus-bridge.v7.24.2.json',
	]
	const keep = retainedCorpusFiles(
		paths.map((path) => join(root, path)),
		root,
		selected,
	).map((path) => path.slice(root.length + 1))
	expect(keep).toEqual([...paths.slice(0, 8), ...paths.slice(14, 16), paths[17]])
	expect(keep.filter((path) => path.endsWith('.rsc'))).toEqual(paths.filter((path) => path.endsWith('.rsc')))
})

function capturedDatabase(value: CorpusPolicy) {
	const db = new Database(':memory:')
	db.exec('PRAGMA foreign_keys=ON')
	createSchema(db)
	createEvidenceSchema(db)
	db.exec(
		"INSERT INTO source_scripts(path,collection,bytes,chars,line_count,sha256,is_empty,is_oversize_32k,has_cli_prompt,has_comment_header,first_line,text) VALUES ('sample.rsc','synthetic',0,0,0,'fixture',1,0,0,0,'','')",
	)
	for (const entry of Object.values(value.channels)) {
		db.prepare("INSERT INTO capture_environments VALUES (?,'{}',NULL,'fixture')").run(entry.sessionId)
		for (const probe of ['parseil', 'highlight']) {
			const id = `${entry.sessionId}-${probe}`
			db.prepare('INSERT INTO capture_runs VALUES (?,?,?,?,NULL,NULL,?,?)').run(
				id,
				probe,
				entry.version,
				entry.sessionId,
				JSON.stringify({ target: null, limit: null }),
				'recorded-session',
			)
			db.prepare(
				"INSERT INTO capture_observations(run_id,script_id,source_path,input_status,acquisition_status,response_class,classifier_version,diagnostics_json) VALUES (?,1,'sample.rsc','matched','ok','fixture','fixture','[]')",
			).run(id)
		}
	}
	return db
}

test('channel labels require complete matched pairs and reject slices or mismatched environments', () => {
	const selected = policy()
	const complete = capturedDatabase(selected)
	insertCaptureChannels(complete, selected)
	expect(complete.query('SELECT COUNT(*) n FROM capture_channels').get()).toEqual({ n: 4 })
	complete.close()
	for (const change of [
		"DELETE FROM capture_observations WHERE run_id LIKE '%-highlight'",
		"UPDATE capture_observations SET input_status='stale' WHERE run_id LIKE '%-parseil'",
		'UPDATE capture_runs SET selection_json=\'{"target":"sample","limit":null}\'',
		"UPDATE capture_runs SET routeros_version='7.1' WHERE probe='highlight'",
		"UPDATE capture_runs SET environment_sha256=(SELECT MAX(sha256) FROM capture_environments) WHERE probe='highlight'",
	]) {
		const incomplete = capturedDatabase(selected)
		incomplete.exec(change)
		expect(() => insertCaptureChannels(incomplete, selected)).toThrow()
		incomplete.close()
	}
})
