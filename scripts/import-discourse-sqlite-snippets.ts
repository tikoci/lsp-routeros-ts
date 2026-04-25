/**
 * Import script-like snippets from a local mcp-discourse SQLite archive.
 *
 * Usage:
 * bun run scripts/import-discourse-sqlite-snippets.ts \
 *   --db-path /Users/amm0/Lab/mcp-discourse/discourse.sqlite \
 *   --source-name amm0 \
 *   --out-dir test-data/forum/amm0
 */

import { spawnSync } from 'node:child_process'
import { mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { join, resolve } from 'node:path'

type CliOptions = {
	dbPath: string
	sourceName: string
	outDir: string
	dryRun: boolean
}

type DbPost = {
	id: number
	topic_id: number
	post_number: number
	topic_title: string
	url: string
	created_at: string
	cooked: string
}

type ExtractedSnippet = {
	topicId: number
	topicTitle: string
	postId: number
	postNumber: number
	url: string
	createdAt: string
	sourceKind: 'code-block'
	snippetIndex: number
	content: string
}

const DEFAULT_DB_PATH = '/Users/amm0/Lab/mcp-discourse/discourse.sqlite'
const DEFAULT_SOURCE_NAME = 'amm0'
const DEFAULT_OUT_DIR = 'test-data/forum/amm0'

function parseArgs(args: string[]): CliOptions {
	const opts: CliOptions = {
		dbPath: DEFAULT_DB_PATH,
		sourceName: DEFAULT_SOURCE_NAME,
		outDir: DEFAULT_OUT_DIR,
		dryRun: false,
	}

	for (let i = 0; i < args.length; i++) {
		const arg = args[i]
		if (arg === '--db-path') opts.dbPath = args[++i] || opts.dbPath
		else if (arg === '--source-name') opts.sourceName = args[++i] || opts.sourceName
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
	console.log(`Import snippets from a local mcp-discourse SQLite archive.

Options:
  --db-path <path>       SQLite database path (default: /Users/amm0/Lab/mcp-discourse/discourse.sqlite)
  --source-name <name>   source_exports.source_name filter (default: amm0)
  --out-dir <path>       Output directory (default: test-data/forum/amm0)
  --dry-run              Show filenames without writing
  --help, -h             Show this help
`)
}

function decodeHtmlEntities(input: string): string {
	const named: Record<string, string> = {
		'&amp;': '&',
		'&lt;': '<',
		'&gt;': '>',
		'&quot;': '"',
		'&#39;': "'",
		'&nbsp;': ' ',
	}

	return input
		.replace(/&(amp|lt|gt|quot|nbsp);|&#39;/g, (m) => named[m] || m)
		.replace(/&#x([0-9a-fA-F]+);/g, (_, hex: string) => String.fromCodePoint(Number.parseInt(hex, 16)))
		.replace(/&#(\d+);/g, (_, dec: string) => String.fromCodePoint(Number.parseInt(dec, 10)))
}

function normalizeSnippet(snippet: string): string {
	const normalized = decodeHtmlEntities(snippet).replace(/\r\n?/g, '\n').trim()
	return `${normalized}\n`
}

function looksLikeRouterScript(text: string): boolean {
	if (text.length < 30) return false
	const lines = text
		.split('\n')
		.map((line) => line.trim())
		.filter(Boolean)
	if (lines.length < 3) return false

	const joined = lines.join('\n')
	const markers = [/:(local|global|set|if|for|foreach|while|return|put|log)\b/, /\/[a-z]+\/[a-z]+/i, /\$[a-zA-Z_]/, /\[find\b|\[:/]
	return markers.some((regex) => regex.test(joined))
}

function isRouterSnippet(attrText: string, normalizedCode: string): boolean {
	if (/routeros|lang-rsc|language-rsc|lang-routeros/i.test(attrText)) return true
	return looksLikeRouterScript(normalizedCode)
}

function extractCodeBlocks(cookedHtml: string): string[] {
	const snippets: string[] = []
	const codeBlockRegex = /<pre\b[^>]*>\s*<code\b([^>]*)>([\s\S]*?)<\/code>\s*<\/pre>/gi
	for (const match of cookedHtml.matchAll(codeBlockRegex)) {
		const attrs = match[1] || ''
		const raw = match[2] || ''
		const normalized = normalizeSnippet(raw)
		if (!normalized.trim()) continue
		if (!isRouterSnippet(attrs, normalized)) continue
		snippets.push(normalized)
	}
	return snippets
}

function slugify(input: string): string {
	const ascii = input.normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
	const stripped = ascii
		.replace(/[^a-zA-Z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.toLowerCase()
	return stripped || 'untitled'
}

function escapeSqlString(value: string): string {
	return value.replace(/'/g, "''")
}

function queryPosts(dbPath: string, sourceName: string): DbPost[] {
	const escapedSourceName = escapeSqlString(sourceName)
	const sql = `
SELECT
	p.id,
	p.topic_id,
	p.post_number,
	p.topic_title,
	p.url,
	p.created_at,
	p.cooked
FROM posts p
JOIN post_sources ps ON ps.post_id = p.id
JOIN source_exports se ON se.id = ps.source_export_id
WHERE lower(se.source_name) = lower('${escapedSourceName}')
ORDER BY p.topic_id, p.post_number;
`.trim()

	const result = spawnSync('sqlite3', ['-json', dbPath, sql], {
		encoding: 'utf-8',
		maxBuffer: 256 * 1024 * 1024,
	})
	if (result.error) {
		throw new Error(`sqlite3 query failed: ${result.error.message}`)
	}
	if (result.status !== 0) {
		throw new Error(`sqlite3 query failed: ${result.stderr || result.stdout}`)
	}
	const text = result.stdout.trim()
	if (!text) return []
	return JSON.parse(text) as DbPost[]
}

function buildTopicDirName(topicId: number, topicTitle: string): string {
	return `topic-${topicId}-${slugify(topicTitle).slice(0, 80)}`
}

function buildFileName(postNumber: number, snippetIndex: number): string {
	const post = String(postNumber).padStart(4, '0')
	const snippet = String(snippetIndex).padStart(2, '0')
	return `post-${post}-snippet-${snippet}.rsc`
}

function buildHeader(item: ExtractedSnippet): string {
	return [`# Source: ${item.url}`, `# Topic: ${item.topicTitle}`, `# Source archive: mcp-discourse SQLite (source_name=amm0)`, `# Extracted from: ${item.sourceKind}`, ''].join('\n')
}

function writeManifest(outDirAbs: string, sourceName: string, dbPath: string, snippets: ExtractedSnippet[]) {
	const topics = new Map<number, string>()
	for (const item of snippets) topics.set(item.topicId, item.topicTitle)

	const manifest = {
		sourceName,
		dbPath,
		topicCount: topics.size,
		snippetCount: snippets.length,
		generatedAt: new Date().toISOString(),
		topics: [...topics.entries()].map(([id, title]) => ({ id, title })),
		snippets: snippets.map((item) => ({
			topicId: item.topicId,
			topicTitle: item.topicTitle,
			postId: item.postId,
			postNumber: item.postNumber,
			createdAt: item.createdAt,
			fileName: `${buildTopicDirName(item.topicId, item.topicTitle)}/${buildFileName(item.postNumber, item.snippetIndex)}`,
			url: item.url,
		})),
	}

	writeFileSync(join(outDirAbs, 'manifest.json'), `${JSON.stringify(manifest, null, '\t')}\n`, 'utf-8')
}

async function main() {
	const opts = parseArgs(process.argv.slice(2))
	const outDirAbs = resolve(process.cwd(), opts.outDir)
	const posts = queryPosts(opts.dbPath, opts.sourceName)

	const snippets: ExtractedSnippet[] = []
	for (const post of posts) {
		let snippetCounter = 0
		for (const code of extractCodeBlocks(post.cooked || '')) {
			snippetCounter += 1
			snippets.push({
				topicId: post.topic_id,
				topicTitle: post.topic_title,
				postId: post.id,
				postNumber: post.post_number,
				url: post.url,
				createdAt: post.created_at,
				sourceKind: 'code-block',
				snippetIndex: snippetCounter,
				content: code,
			})
		}
	}

	if (snippets.length === 0) {
		console.warn('No RouterOS-like snippets found in the selected archive source.')
		return
	}

	if (!opts.dryRun) {
		rmSync(outDirAbs, { recursive: true, force: true })
		mkdirSync(outDirAbs, { recursive: true })
	}

	for (const item of snippets) {
		const topicDir = buildTopicDirName(item.topicId, item.topicTitle)
		const fileName = buildFileName(item.postNumber, item.snippetIndex)
		const targetPath = join(outDirAbs, topicDir, fileName)
		if (opts.dryRun) {
			console.log(`[dry-run] ${topicDir}/${fileName}`)
			continue
		}
		mkdirSync(join(outDirAbs, topicDir), { recursive: true })
		writeFileSync(targetPath, `${buildHeader(item)}\n${item.content}`, 'utf-8')
	}

	if (!opts.dryRun) {
		writeManifest(outDirAbs, opts.sourceName, opts.dbPath, snippets)
		const readme = `# Forum Snippet Import (SQLite)\n\nSource archive: mcp-discourse SQLite\nSource name: ${opts.sourceName}\nDatabase: ${opts.dbPath}\n\nFiles are grouped by topic ID and title to preserve topic context.\n`
		writeFileSync(join(outDirAbs, 'README.md'), readme, 'utf-8')
	}

	const postCount = new Set(snippets.map((item) => item.postId)).size
	const topicCount = new Set(snippets.map((item) => item.topicId)).size
	console.log(`Extracted ${snippets.length} snippets from ${postCount} posts across ${topicCount} topics into ${opts.outDir}`)
}

main().catch((error: unknown) => {
	console.error(error)
	process.exit(1)
})
