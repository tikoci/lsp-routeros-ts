/**
 * Import MikroTik default-configuration `/export` captures from tangentsoft's
 * Fossil repo (https://tangentsoft.com/mikrotik), directory `defconf/`.
 *
 * These are genuine `/export show-sensitive terse` captures from real
 * devices (per the directory's own README), spanning RouterOS 7.1-7.19
 * across ~35 device models — a second, independent real-`/export` source
 * alongside the forum corpus, with MACs/serials/timezone/country-code
 * already redacted by the maintainer before publishing.
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
 *   --out-dir <path>  Output directory (default: test-data/tangentsoft)
 *   --dry-run         List files without writing
 */

import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'

type CliOptions = {
	repoPath: string | null
	url: string
	outDir: string
	dryRun: boolean
}

const DEFAULT_URL = 'https://tangentsoft.com/mikrotik'
const DEFAULT_OUT_DIR = 'test-data/tangentsoft'
const SEED_URL = 'https://tangentsoft.com/mikrotik/dir?name=defconf'
const EXCLUDED = new Set(['defconf/_common.rsc'])

function parseArgs(args: string[]): CliOptions {
	const opts: CliOptions = { repoPath: null, url: DEFAULT_URL, outDir: DEFAULT_OUT_DIR, dryRun: false }
	for (let i = 0; i < args.length; i++) {
		const arg = args[i]
		if (arg === '--repo') opts.repoPath = args[++i] || opts.repoPath
		else if (arg === '--url') opts.url = args[++i] || opts.url
		else if (arg === '--out-dir') opts.outDir = args[++i] || opts.outDir
		else if (arg === '--dry-run') opts.dryRun = true
		else if (arg === '--help' || arg === '-h') {
			printHelp()
			process.exit(0)
		}
	}
	return opts
}

function printHelp() {
	console.log(`Import defconf/*.rsc device exports from tangentsoft's MikroTik Fossil repo.

Options:
  --repo <path>     Reuse an existing local .fossil clone instead of cloning fresh
  --url <url>       Fossil repo URL (default: ${DEFAULT_URL})
  --out-dir <path>  Output directory (default: ${DEFAULT_OUT_DIR})
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
		console.log(`Pulling latest into existing clone: ${opts.repoPath}`)
		run('fossil', ['pull', '-R', opts.repoPath])
		return opts.repoPath
	}
	const repoPath = join(tmpdir(), 'tangentsoft-mikrotik.fossil')
	if (existsSync(repoPath)) {
		console.log(`Pulling latest into cached clone: ${repoPath}`)
		run('fossil', ['pull', '-R', repoPath])
	} else {
		console.log(`Cloning ${opts.url} -> ${repoPath}`)
		run('fossil', ['clone', opts.url, repoPath])
	}
	return repoPath
}

function listDeviceFiles(repoPath: string): string[] {
	const listing = run('fossil', ['ls', '-R', repoPath, '-r', 'trunk'])
	return listing
		.split('\n')
		.map((line) => line.trim())
		.filter((relPath) => /^defconf\/[^/]+\.rsc$/.test(relPath))
		.filter((relPath) => !EXCLUDED.has(relPath))
		.sort()
}

function catFile(repoPath: string, relPath: string): string {
	return run('fossil', ['cat', relPath, '-R', repoPath])
}

function writeAttribution(outDirAbs: string, url: string, fileCount: number) {
	const body = `# tangentsoft MikroTik defconf archive

Scripts in this directory were imported from the "MikroTik Solutions" Fossil
repository's default-configuration archive:

${SEED_URL}

Thanks to [@tangent](${url}) for maintaining and sharing this archive, and
for confirming redistribution here directly.

These are genuine \`/export show-sensitive terse\` captures from ${fileCount}
real devices spanning RouterOS 7.1-7.19. MACs, serial numbers, timezone, and
country-code settings are already redacted by the maintainer before
publishing (see the archive's own README for the exact redaction policy).
\`_common.rsc\` (a scripted \`/system/default-configuration print\` template,
not a flat export) and the \`tools/\` capture scripts are intentionally
excluded — different genre, out of scope for this collection.

Imported with:
\`bun run scripts/import-tangentsoft-defconf.ts --out-dir test-data/tangentsoft\`
`
	writeFileSync(join(outDirAbs, 'ATTRIBUTION.md'), body, 'utf-8')
}

function writeManifest(outDirAbs: string, url: string, files: { relPath: string; fileName: string }[]) {
	const manifest = {
		source: SEED_URL,
		repoUrl: url,
		fileCount: files.length,
		generatedAt: new Date().toISOString(),
		files: files.map((f) => ({ sourcePath: f.relPath, fileName: f.fileName })),
	}
	writeFileSync(join(outDirAbs, 'manifest.json'), `${JSON.stringify(manifest, null, '\t')}\n`, 'utf-8')
}

function main() {
	const opts = parseArgs(process.argv.slice(2))
	const outDirAbs = resolve(process.cwd(), opts.outDir)
	const repoPath = ensureRepo(opts)
	const deviceFiles = listDeviceFiles(repoPath)

	if (deviceFiles.length === 0) {
		console.warn('No defconf/*.rsc device files found.')
		return
	}

	if (opts.dryRun) {
		for (const relPath of deviceFiles) console.log(`[dry-run] ${relPath}`)
		console.log(`${deviceFiles.length} device files would be imported into ${opts.outDir}`)
		return
	}

	rmSync(outDirAbs, { recursive: true, force: true })
	mkdirSync(outDirAbs, { recursive: true })

	const written: { relPath: string; fileName: string }[] = []
	for (const relPath of deviceFiles) {
		const fileName = relPath.replace(/^defconf\//, '')
		const content = catFile(repoPath, relPath)
		writeFileSync(join(outDirAbs, fileName), content, 'utf-8')
		written.push({ relPath, fileName })
	}

	writeAttribution(outDirAbs, opts.url, written.length)
	writeManifest(outDirAbs, opts.url, written)
	console.log(`Imported ${written.length} device export scripts into ${opts.outDir}`)
}

main()
