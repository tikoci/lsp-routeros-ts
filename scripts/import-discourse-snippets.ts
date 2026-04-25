/**
 * Import RouterOS snippets from a Discourse topic page JSON endpoint.
 *
 * Usage:
 * bun run server/src/import-discourse-snippets.ts \
 *   --url 'https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/20?page=6' \
 *   --author rextended \
 *   --out-dir test-data/forum/rextended
 *
 * Optional:
 *   --include-blockquotes   Also extract script-like text from blockquotes
 *   --follow-linked-pages   Follow one-level topic links found in seed posts
 *   --all-authors           Do not filter by author
 *   --dry-run               Print what would be written without creating files
 */
import { mkdirSync, writeFileSync } from 'node:fs'
import { join, resolve } from 'node:path'

type DiscoursePost = {
	id: number
	post_number: number
	username: string
	created_at: string
	cooked: string
}

type TopicChunk = {
	id: number
	title: string
	slug: string
	post_stream: {
		stream?: number[]
		posts: DiscoursePost[]
	}
}

type TopicSource = {
	topicId: number
	topicBaseUrl: string
	topicTitle: string
}

type ExtractedSnippet = TopicSource & {
	postId: number
	postNumber: number
	author: string
	createdAt: string
	sourceKind: 'code-block' | 'blockquote'
	snippetIndex: number
	content: string
}

type CliOptions = {
	url: string
	author?: string
	outDir: string
	includeBlockquotes: boolean
	followLinkedPages: boolean
	allAuthors: boolean
	dryRun: boolean
}

type ParsedTopicUrl = {
	origin: string
	jsonUrl: string
	topicBaseUrl: string
	topicId: number
	hasExplicitPost: boolean
}

const DEFAULT_URL = 'https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/20?page=6'
const DEFAULT_AUTHOR = 'rextended'
const DEFAULT_OUT_DIR = 'test-data/forum/rextended'

function parseArgs(args: string[]): CliOptions {
	const opts: CliOptions = {
		url: DEFAULT_URL,
		author: DEFAULT_AUTHOR,
		outDir: DEFAULT_OUT_DIR,
		includeBlockquotes: false,
		followLinkedPages: false,
		allAuthors: false,
		dryRun: false,
	}

	for (let i = 0; i < args.length; i++) {
		const arg = args[i]
		if (arg === '--url') opts.url = args[++i] || opts.url
		else if (arg === '--author') opts.author = args[++i] || opts.author
		else if (arg === '--out-dir') opts.outDir = args[++i] || opts.outDir
		else if (arg === '--include-blockquotes') opts.includeBlockquotes = true
		else if (arg === '--follow-linked-pages') opts.followLinkedPages = true
		else if (arg === '--all-authors') opts.allAuthors = true
		else if (arg === '--dry-run') opts.dryRun = true
		else if (arg === '--help' || arg === '-h') {
			printHelp()
			process.exit(0)
		}
	}

	if (opts.allAuthors) opts.author = undefined
	return opts
}

function printHelp() {
	console.log(`Import RouterOS snippets from a Discourse topic page.

Options:
  --url <url>                 Discourse topic URL with optional page query
  --author <username>         Filter posts by author (default: rextended)
  --all-authors               Include posts from all authors
  --out-dir <path>            Output directory (default: test-data/forum/rextended)
  --include-blockquotes       Extract script-like plain text from blockquotes too
  --follow-linked-pages       Follow one-level Discourse topic links from seed posts
  --dry-run                   Show outputs without writing files
  --help, -h                  Show this help
`)
}

function parseDiscourseTopicUrl(sourceUrl: string): ParsedTopicUrl {
	const parsed = new URL(sourceUrl)
	const pathMatch = parsed.pathname.match(/\/t\/[^/]+\/(\d+)(?:\/(\d+))?/) || parsed.pathname.match(/\/t\/(\d+)(?:\/(\d+))?/)
	if (!pathMatch) throw new Error(`Unsupported Discourse topic URL: ${sourceUrl}`)

	const topicId = pathMatch[1]
	const hasExplicitPost = Boolean(pathMatch[2])
	const postNumber = pathMatch[2] || '1'
	const page = parsed.searchParams.get('page')
	const segments = parsed.pathname.split('/').filter(Boolean)
	const topicBasePath = segments[0] === 't' ? (/^\d+$/.test(segments[1] || '') ? `/t/${segments[1]}` : `/t/${segments[1]}/${segments[2]}`) : `/t/${topicId}`

	const jsonUrl = `${parsed.origin}/t/${topicId}/${postNumber}.json${page ? `?page=${page}` : ''}`
	const topicBaseUrl = `${parsed.origin}${topicBasePath}`
	return {
		origin: parsed.origin,
		jsonUrl,
		topicBaseUrl,
		topicId: Number.parseInt(topicId, 10),
		hasExplicitPost,
	}
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

function extractCodeBlocks(cookedHtml: string): string[] {
	const snippets: string[] = []
	const codeBlockRegex = /<pre\b[^>]*>\s*<code\b[^>]*>([\s\S]*?)<\/code>\s*<\/pre>/gi
	for (const match of cookedHtml.matchAll(codeBlockRegex)) {
		const raw = match[1]
		const normalized = normalizeSnippet(raw)
		if (normalized.trim().length > 0) snippets.push(normalized)
	}
	return snippets
}

function stripHtmlToText(html: string): string {
	return decodeHtmlEntities(
		html
			.replace(/<br\s*\/?\s*>/gi, '\n')
			.replace(/<\/p>/gi, '\n')
			.replace(/<[^>]+>/g, ''),
	)
		.replace(/\r\n?/g, '\n')
		.trim()
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

function extractScriptLikeBlockQuotes(cookedHtml: string): string[] {
	const snippets: string[] = []
	const blockQuoteRegex = /<blockquote\b[^>]*>([\s\S]*?)<\/blockquote>/gi
	for (const match of cookedHtml.matchAll(blockQuoteRegex)) {
		const text = stripHtmlToText(match[1])
		if (!looksLikeRouterScript(text)) continue
		snippets.push(`${text}\n`)
	}
	return snippets
}

function extractTopicLinks(cookedHtml: string, baseUrl: string): string[] {
	const base = new URL(baseUrl)
	const links = new Set<string>()
	const hrefRegex = /<a\b[^>]*href=["']([^"']+)["'][^>]*>/gi

	for (const match of cookedHtml.matchAll(hrefRegex)) {
		const href = decodeHtmlEntities(match[1]).trim()
		if (!href || href.startsWith('#')) continue

		let resolved: URL
		try {
			resolved = new URL(href, base)
		} catch {
			continue
		}

		if (resolved.host !== base.host) continue
		if (!resolved.pathname.startsWith('/t/')) continue
		if (resolved.protocol !== base.protocol) resolved.protocol = base.protocol
		links.add(resolved.toString())
	}

	return [...links]
}

function toOutputName(topicId: number, postNumber: number, snippetIndex: number, includeTopic: boolean): string {
	const topic = String(topicId)
	const post = String(postNumber).padStart(4, '0')
	const snippet = String(snippetIndex).padStart(2, '0')
	if (includeTopic) return `topic-${topic}-post-${post}-snippet-${snippet}.rsc`
	return `post-${post}-snippet-${snippet}.rsc`
}

function toPostUrl(topicBaseUrl: string, postNumber: number): string {
	return `${topicBaseUrl.replace(/\/$/, '')}/${postNumber}`
}

async function fetchTopicChunk(jsonUrl: string): Promise<TopicChunk> {
	const resp = await fetch(jsonUrl)
	if (!resp.ok) throw new Error(`Failed to fetch ${jsonUrl}: HTTP ${resp.status}`)
	return (await resp.json()) as TopicChunk
}

async function fetchTopicPostsByIds(origin: string, topicId: number, postIds: number[]): Promise<DiscoursePost[]> {
	const query = postIds.map((id) => `post_ids[]=${id}`).join('&')
	const url = `${origin}/t/${topicId}/posts.json?${query}`
	const resp = await fetch(url)
	if (!resp.ok) throw new Error(`Failed to fetch ${url}: HTTP ${resp.status}`)
	const data = (await resp.json()) as { post_stream: { posts: DiscoursePost[] } }
	return data.post_stream.posts || []
}

function chunkIds(ids: number[], size: number): number[][] {
	const chunks: number[][] = []
	for (let i = 0; i < ids.length; i += size) chunks.push(ids.slice(i, i + size))
	return chunks
}

async function maybeExpandToFullTopic(parsed: ParsedTopicUrl, chunk: TopicChunk, expand: boolean): Promise<TopicChunk> {
	if (!expand) return chunk
	const stream = chunk.post_stream.stream || []
	if (stream.length === 0) return chunk

	const allPosts: DiscoursePost[] = []
	for (const batch of chunkIds(stream, 50)) {
		const posts = await fetchTopicPostsByIds(parsed.origin, parsed.topicId, batch)
		allPosts.push(...posts)
	}

	allPosts.sort((a, b) => a.post_number - b.post_number)
	return {
		...chunk,
		post_stream: {
			stream,
			posts: allPosts,
		},
	}
}

function buildSnippetHeader(post: DiscoursePost, postUrl: string, sourceKind: ExtractedSnippet['sourceKind']): string {
	return `# Source: ${postUrl}\n# Post author: @${post.username}\n# Extracted from: ${sourceKind}\n\n`
}

function writeManifest(outDirAbs: string, sourceUrl: string, seedChunk: TopicChunk, snippets: ExtractedSnippet[]) {
	const manifestPath = join(outDirAbs, 'manifest.json')
	const topics = new Map<number, { title: string; url: string }>()
	for (const snippet of snippets) {
		topics.set(snippet.topicId, { title: snippet.topicTitle, url: snippet.topicBaseUrl })
	}
	const includeTopicInFileName = topics.size > 1

	const manifest = {
		sourceUrl,
		topicId: seedChunk.id,
		topicTitle: seedChunk.title,
		sourceTopics: [...topics.entries()].map(([id, info]) => ({ id, title: info.title, url: info.url })),
		snippetCount: snippets.length,
		generatedAt: new Date().toISOString(),
		snippets: snippets.map((entry) => ({
			topicId: entry.topicId,
			topicTitle: entry.topicTitle,
			postId: entry.postId,
			postNumber: entry.postNumber,
			author: entry.author,
			createdAt: entry.createdAt,
			sourceKind: entry.sourceKind,
			fileName: toOutputName(entry.topicId, entry.postNumber, entry.snippetIndex, includeTopicInFileName),
		})),
	}
	writeFileSync(manifestPath, `${JSON.stringify(manifest, null, '\t')}\n`, 'utf-8')
}

function collectSnippets(chunk: TopicChunk, topicBaseUrl: string, opts: CliOptions): { snippets: ExtractedSnippet[]; outboundLinks: string[]; postCountUsed: number } {
	const posts = chunk.post_stream.posts.filter((post) => (opts.author ? post.username.toLowerCase() === opts.author.toLowerCase() : true)).sort((a, b) => a.post_number - b.post_number)

	const snippets: ExtractedSnippet[] = []
	const outboundLinks = new Set<string>()

	for (const post of posts) {
		let snippetCounter = 0
		for (const code of extractCodeBlocks(post.cooked)) {
			snippetCounter += 1
			snippets.push({
				topicId: chunk.id,
				topicTitle: chunk.title,
				topicBaseUrl,
				postId: post.id,
				postNumber: post.post_number,
				author: post.username,
				createdAt: post.created_at,
				sourceKind: 'code-block',
				snippetIndex: snippetCounter,
				content: code,
			})
		}

		if (opts.includeBlockquotes) {
			for (const blockQuoteText of extractScriptLikeBlockQuotes(post.cooked)) {
				snippetCounter += 1
				snippets.push({
					topicId: chunk.id,
					topicTitle: chunk.title,
					topicBaseUrl,
					postId: post.id,
					postNumber: post.post_number,
					author: post.username,
					createdAt: post.created_at,
					sourceKind: 'blockquote',
					snippetIndex: snippetCounter,
					content: blockQuoteText,
				})
			}
		}

		for (const link of extractTopicLinks(post.cooked, topicBaseUrl)) outboundLinks.add(link)
	}

	return { snippets, outboundLinks: [...outboundLinks], postCountUsed: posts.length }
}

async function main() {
	const opts = parseArgs(process.argv.slice(2))
	const seed = parseDiscourseTopicUrl(opts.url)
	const outDirAbs = resolve(process.cwd(), opts.outDir)

	console.log(`Fetching: ${seed.jsonUrl}`)
	const seedChunkRaw = await fetchTopicChunk(seed.jsonUrl)
	const seedChunk = await maybeExpandToFullTopic(seed, seedChunkRaw, !seed.hasExplicitPost)

	const seedResult = collectSnippets(seedChunk, seed.topicBaseUrl, opts)
	const allSnippets: ExtractedSnippet[] = [...seedResult.snippets]
	let fetchedTopicCount = 1
	let usedPostCount = seedResult.postCountUsed

	if (opts.followLinkedPages) {
		const seenTopicIds = new Set<number>([seed.topicId])
		const candidateLinks = seedResult.outboundLinks
			.map((link) => {
				try {
					return parseDiscourseTopicUrl(link)
				} catch {
					return undefined
				}
			})
			.filter((entry): entry is ParsedTopicUrl => Boolean(entry))
			.filter((entry) => {
				if (seenTopicIds.has(entry.topicId)) return false
				seenTopicIds.add(entry.topicId)
				return true
			})

		const seenJsonUrls = new Set<string>()
		for (const linked of candidateLinks) {
			if (seenJsonUrls.has(linked.jsonUrl)) continue
			seenJsonUrls.add(linked.jsonUrl)

			console.log(`Following link: ${linked.jsonUrl}`)
			try {
				const linkedChunkRaw = await fetchTopicChunk(linked.jsonUrl)
				const linkedChunk = await maybeExpandToFullTopic(linked, linkedChunkRaw, true)
				const linkedResult = collectSnippets(linkedChunk, linked.topicBaseUrl, opts)
				allSnippets.push(...linkedResult.snippets)
				fetchedTopicCount += 1
				usedPostCount += linkedResult.postCountUsed
			} catch (error: unknown) {
				console.warn(`Skipping linked page ${linked.jsonUrl}: ${String(error)}`)
			}
		}
	}

	if (allSnippets.length === 0) {
		console.warn('No snippets extracted. Try --all-authors, --include-blockquotes, or --follow-linked-pages.')
		return
	}

	const topicCount = new Set(allSnippets.map((item) => item.topicId)).size
	const includeTopicInFileName = topicCount > 1

	if (!opts.dryRun) mkdirSync(outDirAbs, { recursive: true })
	for (const snippet of allSnippets) {
		const fileName = toOutputName(snippet.topicId, snippet.postNumber, snippet.snippetIndex, includeTopicInFileName)
		const filePath = join(outDirAbs, fileName)
		const postUrl = toPostUrl(snippet.topicBaseUrl, snippet.postNumber)
		const sourceHeader = buildSnippetHeader(
			{
				id: snippet.postId,
				post_number: snippet.postNumber,
				username: snippet.author,
				created_at: snippet.createdAt,
				cooked: '',
			},
			postUrl,
			snippet.sourceKind,
		)
		const body = `${sourceHeader}${snippet.content}`
		if (opts.dryRun) console.log(`[dry-run] ${fileName}`)
		else writeFileSync(filePath, body, 'utf-8')
	}

	if (!opts.dryRun) {
		writeManifest(outDirAbs, opts.url, seedChunk, allSnippets)
		const readme = `# Discourse Snippet Import\n\nSource page: ${opts.url}\nSeed topic: ${seed.topicBaseUrl}\nOne-level topic link following: ${opts.followLinkedPages ? 'enabled' : 'disabled'}\n\nGenerated files in this directory were extracted from Discourse post code blocks.\nUse server/src/import-discourse-snippets.ts to refresh or import another page.\n`
		writeFileSync(join(outDirAbs, 'README.md'), readme, 'utf-8')
	}

	const postsCovered = new Set(allSnippets.map((item) => `${item.topicId}/${item.postNumber}`))
	console.log(
		`Extracted ${allSnippets.length} snippets from ${postsCovered.size} posts across ${fetchedTopicCount} fetched topic chunks into ${opts.outDir} (used ${usedPostCount} posts after filters)`,
	)
}

main().catch((error: unknown) => {
	console.error(error)
	process.exit(1)
})
