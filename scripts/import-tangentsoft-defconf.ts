/**
 * Import MikroTik default-configuration `/export` captures from tangentsoft's
 * Fossil repo (https://tangentsoft.com/mikrotik), directory `defconf/`.
 *
 * These are genuine `/export show-sensitive terse` captures from real
 * devices (per the directory's own README) across ~35 device models — a
 * second, independent real-`/export` source alongside the forum corpus, with
 * MACs/serials/timezone/country-code already redacted by the maintainer
 * before publishing.
 *
 * Provenance is measured, not asserted: the importer verifies the clone's
 * Fossil project code before writing tangentsoft attribution, the manifest
 * pins the upstream check-in UUID and a SHA-256 per file, and each file's
 * RouterOS version is read from its own `/export` banner. The output
 * directory is staged and swapped, so a failed run cannot leave a partial
 * collection behind a stale manifest. Note that the upstream README's
 * "7.1 through 7.19" range describes the `_common.rsc` version history — the
 * one file this importer excludes — not these captures, whose banners span a
 * narrower band. Note too that the archive's `-switch`/`-router` pairs are
 * maintainer-modified variants of one capture, so this collection is L1
 * ("a device emitted this, then a human edited it"), not raw device output.
 *
 * The web UI gates file downloads behind a JS proof-of-work anti-bot check
 * that blocks scripted HTTP fetches (curl/WebFetch get a "Browser
 * Verification" challenge page instead of file content). Fossil's native
 * sync protocol is unaffected, so this shells out to the `fossil` CLI
 * (`fossil clone`/`fossil cat`) instead of scraping HTML.
 *
 * Only top-level `defconf/*.rsc` device files are imported. `_common.rsc`
 * is deliberately excluded: per the site's own docs it is a *scripted*
 * `/system/default-configuration print` template (heavy on `:global`,
 * conditionals, loops), a different genre from a flat device export, and
 * would misclassify under a "genuine export" collection. `tools/` and
 * `README.md` are not RouterOS scripts.
 *
 * Usage:
 *   bun run scripts/import-tangentsoft-defconf.ts --out-dir test-data/tangentsoft
 *
 * Options:
 *   --repo <path>     Reuse an existing local .fossil clone instead of cloning fresh
 *   --url <url>       Fossil repo URL (default: https://tangentsoft.com/mikrotik)
 *   --out-dir <path>  Output directory (default: test-data/tangentsoft); must
 *                     be under test-data/, since the importer clears it first
 *   --checkin <ref>   Check-in to import (default: trunk); pass the UUID from
 *                     manifest.json to reproduce a past import exactly
 *   --dry-run         List files without writing
 *   --help, -h        Show this help
 */

import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { existsSync, mkdirSync, renameSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { isAbsolute, join, relative, resolve } from 'node:path'

type CliOptions = {
	repoPath: string | null
	url: string
	outDir: string
	checkin: string
	dryRun: boolean
}

const DEFAULT_URL = 'https://tangentsoft.com/mikrotik'
const DEFAULT_OUT_DIR = 'test-data/tangentsoft'
const DEFAULT_CHECKIN = 'trunk'
const SEED_URL = 'https://tangentsoft.com/mikrotik/dir?name=defconf'
const EXCLUDED = new Set(['defconf/_common.rsc'])

/**
 * Fossil's per-repository project code — stable across clones and mirrors, and
 * independent of the URL used to reach them. `--repo`/`--url` can point at any
 * Fossil database, but this importer writes tangentsoft attribution, so it
 * verifies it is actually reading that archive rather than trusting the URL.
 */
const EXPECTED_PROJECT_CODE = 'fb4000be731786c3866e5e4b8cec262d836de66e'

function parseArgs(args: string[]): CliOptions {
	const opts: CliOptions = {
		repoPath: null,
		url: DEFAULT_URL,
		outDir: DEFAULT_OUT_DIR,
		checkin: DEFAULT_CHECKIN,
		dryRun: false,
	}
	// A flag that swallows the next flag is worse than a hard failure here:
	// `--repo --dry-run` would silently write, and `--checkin --dry-run` would
	// silently fall back to mutable `trunk` instead of the pinned check-in.
	const value = (flag: string, index: number): string => {
		const next = args[index + 1]
		if (next === undefined || next.startsWith('-')) throw new Error(`${flag} requires a value`)
		return next
	}
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]
		if (arg === '--repo') opts.repoPath = value(arg, i++)
		else if (arg === '--url') opts.url = value(arg, i++)
		else if (arg === '--out-dir') opts.outDir = value(arg, i++)
		else if (arg === '--checkin') opts.checkin = value(arg, i++)
		else if (arg === '--dry-run') opts.dryRun = true
		else if (arg === '--help' || arg === '-h') {
			printHelp()
			process.exit(0)
		} else throw new Error(`unknown option: ${arg}`)
	}
	return opts
}

function printHelp() {
	console.log(`Import defconf/*.rsc device exports from tangentsoft's MikroTik Fossil repo.

Options:
  --repo <path>     Reuse an existing local .fossil clone instead of cloning fresh
  --url <url>       Fossil repo URL (default: ${DEFAULT_URL})
  --out-dir <path>  Output directory (default: ${DEFAULT_OUT_DIR}); must be
                    under test-data/, since the importer clears it first
  --checkin <ref>   Check-in to import (default: ${DEFAULT_CHECKIN}); pass the
                    UUID recorded in manifest.json to reproduce a past import
  --dry-run         List files without writing
  --help, -h        Show this help
`)
}

function run(cmd: string, args: string[]): string {
	const result = spawnSync(cmd, args, { encoding: 'utf-8', maxBuffer: 64 * 1024 * 1024 })
	if (result.error) throw new Error(`${cmd} ${args.join(' ')} failed: ${result.error.message}`)
	if (result.status !== 0) throw new Error(`${cmd} ${args.join(' ')} failed:\n${result.stderr || result.stdout}`)
	return result.stdout
}

function ensureRepo(opts: CliOptions): string {
	if (opts.repoPath) {
		if (!existsSync(opts.repoPath)) throw new Error(`--repo path does not exist: ${opts.repoPath}`)
		// Identity before network: a caller-supplied clone is checked before we
		// pull into it, so pointing at the wrong repo fails on the wrong repo
		// rather than on some unrelated fossil error.
		assertExpectedRepo(opts.repoPath)
		console.log(`Pulling latest into existing clone: ${opts.repoPath}`)
		run('fossil', ['pull', '-R', opts.repoPath])
		return opts.repoPath
	}
	const repoPath = join(tmpdir(), 'tangentsoft-mikrotik.fossil')
	if (existsSync(repoPath)) {
		assertExpectedRepo(repoPath)
		console.log(`Pulling latest into cached clone: ${repoPath}`)
		run('fossil', ['pull', '-R', repoPath])
	} else {
		console.log(`Cloning ${opts.url} -> ${repoPath}`)
		run('fossil', ['clone', opts.url, repoPath])
		assertExpectedRepo(repoPath)
	}
	return repoPath
}

/**
 * Resolve a ref (`trunk`, a tag, a prefix) to the full check-in UUID, so the
 * listing, every `cat`, and the manifest all name the same immutable version.
 * Importing against a bare `trunk` would silently drift as upstream commits.
 */
/**
 * The importer clears its output directory before writing, so `--out-dir .` or
 * `--out-dir ..` would wipe the checkout. Confine it to `test-data/`, which is
 * the only place a corpus collection belongs anyway.
 */
function assertSafeOutDir(outDirAbs: string) {
	const testDataRoot = resolve(process.cwd(), 'test-data')
	// `path.relative` rather than a string prefix: hardcoding `/` rejects every
	// legitimate destination on Windows, where resolved paths use `\`. A path
	// is inside the root when the relative step neither escapes (`..`) nor is
	// absolute (different drive), and is non-empty (the root itself).
	const step = relative(testDataRoot, outDirAbs)
	const isInsideTestData =
		step !== '' && !step.startsWith('..') && !isAbsolute(step)
	if (!isInsideTestData) {
		throw new Error(
			`refusing to clear ${outDirAbs}: --out-dir must be a subdirectory of ${testDataRoot}`,
		)
	}
}

/**
 * Confirm the clone really is tangentsoft's archive before writing attribution
 * that says so. The check-in UUID and file hashes pin *which snapshot* was
 * imported; this pins *whose repository* it came from.
 */
function assertExpectedRepo(repoPath: string) {
	const info = run('fossil', ['info', '-R', repoPath])
	const projectCode = info.match(/^project-code:\s+(\S+)/m)?.[1]
	if (projectCode !== EXPECTED_PROJECT_CODE) {
		throw new Error(
			`${repoPath} is not the tangentsoft MikroTik archive ` +
				`(project-code ${projectCode ?? 'unknown'}, expected ${EXPECTED_PROJECT_CODE}). ` +
				'This importer writes tangentsoft attribution, so it refuses other repositories.',
		)
	}
}

function resolveCheckin(repoPath: string, ref: string): string {
	const info = run('fossil', ['info', ref, '-R', repoPath])
	const match = info.match(/^hash:\s+([0-9a-f]{40,})/m)
	if (!match?.[1]) throw new Error(`could not resolve check-in "${ref}" in ${repoPath}`)
	return match[1]
}

function listDeviceFiles(repoPath: string, checkin: string): string[] {
	const listing = run('fossil', ['ls', '-R', repoPath, '-r', checkin])
	return listing
		.split('\n')
		.map((line) => line.trim())
		.filter((relPath) => /^defconf\/[^/]+\.rsc$/.test(relPath))
		.filter((relPath) => !EXCLUDED.has(relPath))
		.sort()
}

function catFile(repoPath: string, checkin: string, relPath: string): string {
	return run('fossil', ['cat', relPath, '-r', checkin, '-R', repoPath])
}

function sha256(content: string): string {
	return createHash('sha256').update(content, 'utf-8').digest('hex')
}

/**
 * RouterOS version from the file's own `/export` banner
 * (`# <date> by RouterOS <version>`). This is the capture's environment, read
 * from what the device wrote rather than asserted in prose.
 */
function bannerVersion(content: string): string | null {
	return content.match(/^#\s.*\bby RouterOS\s+(\S+)/m)?.[1] ?? null
}

function compareVersions(a: string, b: string): number {
	const parts = (v: string) => v.split('.').map((p) => [Number.parseInt(p, 10) || 0, p] as const)
	const [pa, pb] = [parts(a), parts(b)]
	for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
		const [na, sa] = pa[i] ?? [0, '']
		const [nb, sb] = pb[i] ?? [0, '']
		if (na !== nb) return na - nb
		if (sa !== sb) return sa < sb ? -1 : 1
	}
	return 0
}

function versionRange(versions: string[]): string {
	const sorted = [...new Set(versions)].sort(compareVersions)
	if (sorted.length === 0) return 'an unknown RouterOS version'
	if (sorted.length === 1) return `RouterOS ${sorted[0]}`
	return `RouterOS ${sorted[0]}-${sorted[sorted.length - 1]}`
}

type ImportedFile = {
	sourcePath: string
	fileName: string
	sha256: string
	routerosVersion: string | null
}

function writeAttribution(outDirAbs: string, url: string, files: ImportedFile[]) {
	const versions = files.map((f) => f.routerosVersion).filter((v): v is string => v !== null)
	const body = `# tangentsoft MikroTik defconf archive

Scripts in this directory were imported from the "MikroTik Solutions" Fossil
repository's default-configuration archive:

${SEED_URL}

Thanks to [@tangent](${url}) for maintaining and sharing this archive, and
for confirming redistribution here directly.

These are ${files.length} genuine \`/export show-sensitive terse\` device
captures spanning ${versionRange(versions)}. That range is read from each
file's own export banner (${versions.length} of ${files.length} carry one),
not asserted — the upstream README's "7.1 through 7.19" describes the
\`_common.rsc\` version history, which is not imported here.

MACs, serial numbers, timezone, and country-code settings are already redacted
by the maintainer before publishing (see the archive's own README for the exact
redaction policy) — this is **not** a controlled synthetic-canary fixture. The
maintainer also hand-derives some variants from a capture (the
\`-router\`/\`-switch\` pairs), so treat the collection as "a device emitted
this, then a human edited it", not as raw device output.

\`_common.rsc\` (a scripted \`/system/default-configuration print\` template,
not a flat export) and the \`tools/\` capture scripts are intentionally
excluded — different genre, out of scope for this collection.

\`manifest.json\` pins the upstream Fossil check-in and a SHA-256 per file;
re-running the importer with \`--checkin <uuid>\` reproduces this directory
byte for byte.

Imported with:
\`bun run scripts/import-tangentsoft-defconf.ts --out-dir test-data/tangentsoft\`
`
	writeFileSync(join(outDirAbs, 'ATTRIBUTION.md'), body, 'utf-8')
}

function writeManifest(outDirAbs: string, url: string, checkin: string, files: ImportedFile[]) {
	const manifest = {
		source: SEED_URL,
		repoUrl: url,
		// The immutable upstream version this directory was cut from. Re-run with
		// `--checkin <this>` to reproduce it; the per-file hashes verify the result.
		checkin,
		fileCount: files.length,
		files,
	}
	writeFileSync(join(outDirAbs, 'manifest.json'), `${JSON.stringify(manifest, null, '\t')}\n`, 'utf-8')
}

function importDefconf(opts: CliOptions): ImportedFile[] | null {
	const outDirAbs = resolve(process.cwd(), opts.outDir)
	if (!opts.dryRun) assertSafeOutDir(outDirAbs)
	const repoPath = ensureRepo(opts)
	const checkin = resolveCheckin(repoPath, opts.checkin)
	console.log(`Importing from check-in ${checkin}`)
	const deviceFiles = listDeviceFiles(repoPath, checkin)

	if (deviceFiles.length === 0) {
		console.warn('No defconf/*.rsc device files found.')
		return null
	}

	if (opts.dryRun) {
		for (const relPath of deviceFiles) console.log(`[dry-run] ${relPath}`)
		console.log(`${deviceFiles.length} device files would be imported into ${opts.outDir}`)
		return null
	}

	// Stage into a sibling directory and swap only once every file, the
	// attribution, and the manifest are written. A `fossil cat` that fails
	// half-way must not leave a partial collection behind a stale manifest.
	const stageDir = `${outDirAbs}.staging`
	rmSync(stageDir, { recursive: true, force: true })
	mkdirSync(stageDir, { recursive: true })

	try {
		const written: ImportedFile[] = []
		for (const relPath of deviceFiles) {
			const fileName = relPath.replace(/^defconf\//, '')
			const content = catFile(repoPath, checkin, relPath)
			writeFileSync(join(stageDir, fileName), content, 'utf-8')
			written.push({
				sourcePath: relPath,
				fileName,
				sha256: sha256(content),
				routerosVersion: bannerVersion(content),
			})
		}

		writeAttribution(stageDir, opts.url, written)
		writeManifest(stageDir, opts.url, checkin, written)

		rmSync(outDirAbs, { recursive: true, force: true })
		renameSync(stageDir, outDirAbs)
		return written
	} catch (error) {
		rmSync(stageDir, { recursive: true, force: true })
		throw error
	}
}

function main() {
	const opts = parseArgs(process.argv.slice(2))
	const written = importDefconf(opts)
	if (!written) return
	const unbannered = written.filter((f) => f.routerosVersion === null).length
	console.log(
		`Imported ${written.length} device export scripts into ${opts.outDir}` +
			(unbannered > 0 ? ` (${unbannered} without an export banner)` : ''),
	)
}

try {
	main()
} catch (error) {
	const message = error instanceof Error ? error.message : String(error)
	console.error(`import-tangentsoft-defconf: ${message}`)
	process.exit(1)
}
