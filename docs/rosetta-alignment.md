# rosetta ↔ LSP Alignment Research

> **Status:** Research / Design — no code yet.
>
> **Core constraint:** No runtime dependency on rosetta. The LSP must work without it;
> rosetta enrichment is opt-in via external data files or an optional DB probe.
>
> **Related:** [`BACKLOG.md` → `[research: rosetta-join]`](../BACKLOG.md),
> [`tikoci/rosetta`](https://github.com/tikoci/rosetta), `tikoci-crossref` skill
>
> **Core framing:** The LSP is **online** (it has a live RouterOS device for syntax/structure).
> Rosetta is **offline** (it has the prose docs MikroTik publishes — the human-readable side
> the live API doesn't carry). They overlap on *structure* and complement on *narrative*.
> When in doubt for syntax, the live device wins; when in doubt for descriptions, rosetta wins.
> See [§ Online + offline — who wins for what](#online--offline--who-wins-for-what).
>
> **Re-reviewed 2026-04-25** — numbers re-verified against released DB
> (`tikoci/rosetta@dist/ros-help.db.gz`, 9.1 MB gzipped, schema as of release).
> Several sizing claims and the link-commands analysis were tightened. See
> the [§ Re-review changelog](#re-review-changelog) at the bottom.

## What this document covers

A deep-dive into `tikoci/rosetta`'s database schema and source code to identify where
rosetta data could enrich LSP operations (hover, completion, document links, diagnostics)
without creating a hard dependency. Includes an access-model comparison, a prioritised
action plan, and bugs/gaps found in rosetta during the investigation.

---

## What rosetta contains (schema summary)

rosetta is a ~230 MB SQLite database (`ros-help.db`, 9.1 MB gzipped release artifact) built
from several sources. **Counts below come from the released DB — newer schema work in `main`
may differ; cite the released DB when sizing artifacts.**

| Table | Rows | Source | Relevance to LSP |
|-------|------|--------|-----------------|
| `pages` | 317 | Confluence HTML export (March 2026) | `url` → help.mikrotik.com deep links |
| `properties` | 4,860 | HTML property tables | Arg descriptions, types, defaults |
| `sections` | 2,984 | h1–h3 headings across pages | Section-level deep links |
| `commands` | 40,208 (551 dir, 5,109 cmd, 34,548 arg) | `inspect.json` (7.22 primary) | Path→page linkage, short descriptions |
| `schema_nodes` (newer schema; not in released DB yet) | ~40K | `deep-inspect.json` (dual-arch) | Structured types, enums, ranges, completion data |
| `schema_node_presence` (same) | 1.67M | All 46 versions (7.9–7.23beta2) | Version presence for a command path |
| `command_versions` | 1.67M | inspect.json across versions | Version presence (legacy view) |
| `changelogs` | parsed entries | MikroTik download server | Breaking change flags per category |
| `devices` | 144 | mikrotik.com product matrix | Hardware specs if device is identified |
| `device_test_results` | 2,874 | mikrotik.com product pages | Throughput benchmarks |
| `videos` + `video_segments` | 518 videos | YouTube (yt-dlp transcripts) | Tutorial links by topic |
| `callouts` | 1,034 | Confluence callout macros | Notes/warnings attached to pages |
| `glossary` | seeded | In-DB seed | RouterOS term definitions |

**The key links:**

- `commands.page_id → pages.id → pages.url` — path → docs URL.
- 512 of 551 `dir`-type commands are linked = **92.9 %**. The unlinked ~7 % are mostly
  WiFi/LoRa/scripting (rosetta `BACKLOG.md` notes "agent-assisted linking" as a backlog item).
- `cmd`-type rows (4,114 linked of 5,109) inherit their parent dir's `page_id` — they don't
  add information beyond the parent dir, so the LSP only needs the dir-level rows.
- `arg`-type rows in `commands` carry short type hints (`"string value, max length 255"`) —
  the *full* property prose lives in `properties`, keyed by `(page_id, name)`.

**Caveat about schema_nodes.** The current release DB does **not** include the
`schema_nodes` / `schema_node_presence` tables yet — that work shipped to `main` (see
rosetta `DESIGN.md` § "schema_nodes — multi-arch command tree with enrichment") but the
public release artifact lags. Anything we plan that depends on `schema_nodes` should wait
for the next release, or fall back to `commands` + `command_versions` (which the
extract-schema pipeline regenerates from `schema_nodes` precisely so downstream queries
keep working unchanged).

---

## Alignment matrix — LSP operation → rosetta data

### Tier 1 — High value, low complexity

These are the cases where rosetta adds information the LSP cannot get any other way
(live RouterOS gives syntax structure, not human-readable documentation URLs).

| LSP operation | What the LSP knows today | What rosetta adds | rosetta tables |
|---|---|---|---|
| **Hover on a path token** (`/ip/firewall/filter`) | Token type = `path` | Doc URL, page title, `description` from inspect | `commands JOIN pages` on `page_id` |
| **Hover on a command** (`/ip/firewall/filter add`) | Token type = `cmd-name` | Parent dir's doc URL | same |
| **Completion item `documentation`** | `item.text` from RouterOS (often empty or terse) | Property description: type, default, human prose | `properties` by name + page context |
| **Document Links** (LSP `textDocument/documentLink`) | Nothing today | `/ip/firewall/filter` → deep link | `commands` where type=`dir` |

### Tier 2 — Good value, moderate complexity

Require either path-context resolution or version awareness.

| LSP operation | What rosetta adds | rosetta tables | Complexity note |
|---|---|---|---|
| **Hover arg description** (`chain=`) | Type, default, description, enum values | `properties WHERE name=? + page_id context` | Need to infer page from path context |
| **Completion detail** for arg values | `schema_nodes.desc_raw`, enum list, range bounds | `schema_nodes WHERE path LIKE ?` | Redundant with live device but useful offline |
| **Breaking-change warnings** in diagnostics | `⚠️ Breaking in 7.22: …` banner | `changelogs WHERE is_breaking=1 AND category=?` | Need topic→category mapping; version from `/system/resource` |
| **Callout banners** (Note / Warning) | Page-level notes surfaced on hover | `callouts JOIN pages` on `page_id` | Would be noisy without good filtering |

### Tier 3 — Interesting but speculative

These require more LSP infrastructure that doesn't exist yet.

| Use case | rosetta data | Dependency |
|---|---|---|
| **Device-aware hover** (connected device model) | Specs + benchmarks from `devices` + `device_test_results` | LSP needs to parse `/system/resource` response |
| **Tutorial links** on hover | `video_segments_fts` FTS on command topic | Reliable path→topic mapping needed |
| **Offline fallback completions** | `schema_nodes._attrs.completion` has style/preference | Only valuable if live device is unreachable |

---

## Access models

### Option A — Static JSON artifact (immediate, no runtime dep)

Export a curated JSON file from rosetta and commit it to the LSP repo (or fetch it
from GitHub Pages on first use / at build time).

**Shape:**

```json
[
  {
    "path": "/ip/firewall/filter",
    "url": "https://help.mikrotik.com/docs/spaces/ROS/pages/328229/Filter",
    "title": "Filter",
    "description": null
  }
]
```

**Size — measured, not guessed.** Generated via:

```sql
SELECT json_group_array(json_object('path', c.path, 'url', p.url,
                                    'title', p.title, 'description', c.description))
FROM commands c JOIN pages p ON p.id=c.page_id WHERE c.type='dir';
```

→ **81 KB uncompressed, 6 KB gzipped** for 512 dir entries. (Earlier 66 KB / 18 KB estimate
was off — gzip compresses URL repetition better than expected.) Including `cmd` rows
(4,114 more) ≈ 150 KB / 12 KB gzipped, with no new information vs. just rolling up to the
parent dir at lookup time. Recommendation: **dir-only**, look up commands via parent path.

**Pros:** Zero runtime dependency. Works in VSCode Web (no Node, no native modules).
Works offline. No installs. Simple `Map<path, entry>` in the LSP.

**Cons:** Stale between rosetta releases. Captures only the primary version's tree
(7.22 today). Doesn't help with property descriptions or callouts — only path→URL.

**Verdict:** This is the right first step. Trivially small, web-safe, useful in every
deployment context. See [§ Deployment context × access model](#deployment-context--access-model).

---

### Option B — Probe for a local `ros-help.db` (optional enrichment)

If the user has rosetta installed (`~/.rosetta/ros-help.db` or
`$DB_PATH` env var), open it read-only at LSP startup for richer data.

**What you get over Option A:**

- Full `properties` table (name, type, default, description) per page
- Callouts (page-level notes/warnings)
- `schema_nodes` structured types (enum_values, range_min/max)
- Changelog breaking-change flags

**Cons:**

- DB is 200 MB — not something the LSP bundles
- `better-sqlite3` or Bun's native SQLite needed (adds a dep for the npm package build)
- VSCode Web: **impossible** — no filesystem or native modules
- Must be strictly optional and gracefully absent

**Verdict:** Good medium-term path for the npm package + standalone binary targets.
Guard behind a `settings.rosettaDbPath` (defaults to `~/.rosetta/ros-help.db`).
Never add it to the webpack Web bundle.

---

### Option C — "Lite" database export from rosetta CI

rosetta's CI builds `ros-help.db`. It could also build a `ros-help-lite.db`
(or a structured JSON export) containing only what the LSP needs:

```sql
-- lite schema (~2–4 MB uncompressed, <1 MB gzipped)
pages_lite (id, title, url)              -- 317 rows
commands_lite (path, type, description, page_id)  -- ~5,500 dirs+cmds
properties_lite (name, type, default_val, description, page_id)  -- 4,860 rows
```

This file could be served as a GitHub Release asset and auto-downloaded by the LSP
on first use (like rosetta auto-downloads `ros-help.db`).

**Pros:** Small enough to ship in the VSCode extension if needed (<1 MB gzipped).
Richer than Option A. Easy to update via rosetta's CI.

**Cons:** Requires rosetta to build and publish this artifact. Requires the LSP to
have a download flow. Still doesn't work in VSCode Web (or needs a CDN fetch path).

**Verdict:** Best medium-term option if rosetta adds the lite export. Worth filing
in rosetta's BACKLOG.

---

### Option E — Lite DB + sql.js (web-compatible richness)

Same artifact as Option C, but loaded via [`sql.js`](https://github.com/sql-js/sql.js)
(SQLite compiled to WASM, ~700 KB WASM blob). This is the only way to get richer-than-JSON
queries in **VSCode Web** and other browser contexts, since native sqlite (`better-sqlite3`,
`bun:sqlite`) cannot run there.

**Pros:** Single code path for Node and Web (sql.js works in both). Web users get the same
hover descriptions Node users do. No native build for VSCode Marketplace VSIX (which
otherwise has to ship per-platform binaries — see [§ The sqlite-in-VSCode problem](#the-sqlite-in-vscode-problem)).

**Cons:** sql.js is slower than native sqlite (LSP request paths are not hot, so probably
fine). Whole DB must fit in RAM — a 2–4 MB lite DB is comfortable; the full 230 MB DB is not.
Adds a runtime dep (~700 KB WASM + JS shim) to the LSP bundle.

**Verdict:** **The strategically interesting option.** It collapses three of the six
deployment contexts (VSCode Desktop, VSCode Web, npm package) onto one rosetta access
path. Pair it with a CI-published lite DB (Option C). Skip if rosetta isn't ready to
publish the lite artifact; fall back to Option A in that case.

---

### Option D — Rosetta as a library (not recommended)

Importing rosetta's `query.ts` directly. rosetta is a Bun project with DB-heavy
internals — not currently designed as a library.

**Cons:** The 200 MB DB is still needed. Adds tight coupling. Bun-only (no browser).
Doesn't simplify anything over Option B.

**Verdict:** Skip. Direct SQLite access (Option B/C) is simpler and more portable.

---

## Deployment context × access model

The LSP has **six deployment contexts** (see project `CLAUDE.md` § "Deployment Contexts").
Each access model has a different reach. ✅ = first-class; ⚠️ = works with caveats; ❌ = doesn't work.

| Context | Runtime | A: static JSON | B: local full DB | C: lite DB (native) | E: lite DB (sql.js) |
|--------|--------|:---:|:---:|:---:|:---:|
| 1. VSCode Desktop (Marketplace) | Node | ✅ | ⚠️ user must install rosetta + native dep | ⚠️ download flow + native dep | ✅ |
| 2. VSCode Web (`vscode.dev`) | Web Worker | ✅ | ❌ no FS, no native | ❌ no native | ✅ |
| 3. Standalone binary (`bun build --compile`) | Bun | ✅ | ✅ `bun:sqlite` built-in | ✅ `bun:sqlite` built-in | ✅ overkill, but fine |
| 4. npm package `@tikoci/routeroslsp` | Node | ✅ | ⚠️ `better-sqlite3` is a native build | ⚠️ same | ✅ |
| 5. NeoVim (via 3 or 4) | inherits | inherits | inherits | inherits | inherits |
| 6. Copilot CLI (via 4) | Node | ✅ | ⚠️ same as npm | ⚠️ same | ✅ |

**Reading the matrix:**

- **Option A is the only model that works first-class everywhere.** Ship it first; it's
  one PR and unlocks hover doc links + `textDocument/documentLink` in every context.
- **Option E (sql.js + lite DB)** is the only model that gives *richer* (property
  descriptions, callouts) hover content in **every** context including Web. Worth pursuing
  once rosetta publishes the lite artifact (rosetta issue
  [tikoci/rosetta#4](https://github.com/tikoci/rosetta/issues/4)).
- **Option B (probe a local 230 MB rosetta install)** is most useful for the standalone
  binary on Bun — but its reach is narrow, and it locks rosetta and the LSP into the same
  upgrade cycle. It's also the one rosetta's own `BACKLOG.md` (§ "LSP integration") imagines,
  so coordinate language with that file if we change direction.

### The sqlite-in-VSCode problem

The user's question — *"rosetta depends on `bun:sqlite` while a pure VSCode extension cannot
do that"* — is real and is the architectural fork. Three concrete options for SQLite inside a
VSCode extension running on Node:

| Approach | Where it works | Cost to LSP package | Notes |
|---------|---------------|---------------------|-------|
| `better-sqlite3` | Desktop (Node) only | Native binaries per platform in the VSIX (Linux x64/arm64, macOS x64/arm64, Windows x64/arm64). Bumps VSIX size by 2–5 MB per platform. | What rosetta itself uses on the Bun side it gets `bun:sqlite` for free; an extension consumer would have to add this. |
| `sql.js` (WASM) | Desktop **and** Web | One ~700 KB WASM blob, no per-platform builds. Slower (≈3–5×) on heavy queries; not hot for our request rate. | The portable choice. Pairs with a small (≤4 MB) lite DB. |
| Subprocess `sqlite3` CLI | Desktop only, when user has sqlite installed | Zero runtime install | Adds latency per query; no Web; awkward IPC. Avoid. |

**Recommendation:** **`sql.js` + lite DB** for any path richer than the JSON. Don't touch
`better-sqlite3` — it pulls platform-specific native modules into a Marketplace extension,
which has burned other VSCode extensions (e.g., the prebuild fan-out at install time).

`bun:sqlite` is fine for the standalone binary target (statically linked into the bun
runtime), but it's not a path that helps the desktop or web extension. Don't optimise the
architecture for it.

### Tikbook vs. its own rosetta extension

The user raised the "where does rosetta surface in VSCode" question. Two viable shapes:

1. **Bundle the rosetta data in the LSP itself** (this doc's main recommendation). The LSP
   ships either the static JSON (always) or the lite DB + sql.js (eventually). Rosetta
   doesn't appear in VSCode at all from the LSP's perspective; the LSP just consumes a
   data artifact. Decoupled, no dependency, easiest to release.
2. **Tikbook (or a future rosetta extension) ships the full DB and exposes it as an MCP
   server / language model tool.** The LSP detects this neighbour at runtime and queries
   it for hover. Heavier coupling, but the data is fresh and the LSP doesn't need to ship
   any rosetta artifact. Useful if/when rosetta evolves features the JSON can't capture
   (FTS search of property prose, version-diff checks, callout filtering by topic).

**Best path:** ship (1) now (Option A), and if (2) later becomes natural inside Tikbook,
have the LSP *prefer* a connected rosetta MCP server over its bundled JSON — falling back
gracefully when it's not present. Don't make this a hard dependency. The doc's invariant
("the LSP must work without rosetta") stands.

---

## Versioning — leveraging the live device

The LSP is online — it always knows the connected device's RouterOS version via
`/system/resource`. Rosetta tracks 46 versions in `command_versions` /
`schema_node_presence`. Combining these gives free signals the live API doesn't carry:

- **"This command was added in 7.X"** — query rosetta for the earliest version that
  references the path; surface as informational hover or completion `tag`.
- **"This command was removed in 7.Y"** — paths absent in the connected version's
  `command_versions` row but present in older ones; surface as a deprecation diagnostic.
- **"Breaking change in your subsystem in 7.Z"** — `changelogs WHERE is_breaking=1` joined
  by category. Could be wired into hover or surfaced once-per-document via a code lens.

These are P2/P3 — not blockers — but worth designing the data shape with version awareness
in mind. The lite DB / sql.js path makes them cheap; the static JSON path doesn't (it would
need a separate per-version JSON to avoid bloating the primary artifact).

The `routeros_command_version_check` and `routeros_command_diff` MCP tools already exist on
rosetta's side and answer exactly these questions for an agent — so option (2) above gets
this for free.

---

## Online + offline — who wins for what

| Question | Source of truth | Why |
|---------|---------------|-----|
| Token type at this character | **Live device** (`/console/inspect highlight`) | Rosetta has no per-character data; only the device knows the parser state. |
| Completion at cursor | **Live device** (`/console/inspect completion`) | Same — version-correct, type-correct. |
| Does this command exist? | **Live device** | The connected version is authoritative. Rosetta lags by one HTML export cycle. |
| Hover: what does this command do? | **Rosetta** (page title + description) | Live API gives type, not human prose. |
| Hover: what does this arg accept? | **Rosetta** (`properties` row) > Live (`commands.description` short form) | Properties are full prose; live has terse type strings. |
| Hover: docs URL | **Rosetta only** (`pages.url`) | Live API doesn't carry URLs. |
| "When was this added/removed?" | **Rosetta only** (`command_versions`) | Live API only knows current version. |
| "Is this breaking on upgrade?" | **Rosetta only** (`changelogs`) | Live API has no changelog. |
| Property value enum / range | **Live** (`completion`) > Rosetta (`schema_nodes` or property prose) | Live is version-exact. Rosetta enum data covers the primary version only. |

**Implication for the LSP**: When live and rosetta disagree about a path or arg, **trust the
live device**. Rosetta is the ground truth for prose only. This rule should be in the code
comment on whatever joiner we end up writing.

---

## Priority recommendations

### P0 — Static docs-links JSON (no code in rosetta; pure LSP work)

1. **LSP: add `routeros-docs-links.json`** to the repo, generated from the live
   rosetta DB (run once, commit). Schema: `Array<{path, url, title, description?}>`.
   Update via a `scripts/update-docs-links.ts` script that queries either the local
   DB or the rosetta MCP server.

2. **LSP: use docs links in hover** — when hover lands on a `path` token, append
   `\n\n📚 [Documentation](url)` to the hover markdown. Requires no new dependencies.

3. **LSP: LSP `textDocument/documentLink`** — return doc URL links for every `path`
   token range in the document. Zero network calls; pure table lookup.

These three together are one afternoon of work once the JSON file exists.

### P1 — Completion documentation from `item.text` + properties

The completion handler already has `item.text` from RouterOS but doesn't put it in
`CompletionItem.documentation`. Fix that first (no rosetta needed). Then, if a
local rosetta DB is available, enrich `documentation` with the full property description
from the `properties` table.

### P2 — Optional rosetta DB probe for hover enrichment

Add optional `settings.rosettaDbPath` (Node/standalone targets only). When present,
open the DB and use `properties` + `callouts` for richer hover content.
Guard behind `typeof window === 'undefined'` to exclude from Web bundle.

### P3 — Lite DB CI artifact (requires rosetta change)

File an item in rosetta's BACKLOG to build and publish `ros-help-lite.db` as a
GitHub Release asset. The LSP can then auto-download it (like rosetta does for
its full DB) without asking users to install rosetta.

---

## Issues found in rosetta during this investigation

These should be filed in `tikoci/rosetta` as BACKLOG items or GitHub issues.

### 🐛 `ros-toc.json` — all `section` and `title` fields are empty strings

`ros-html-assessment.json` is 146 KB and `ros-toc.json` has 25 entries, all with
`"section": ""` and `"title": ""`. Every entry is `{"section":"","title":"","page":N,"depth":0,"page_end":M,"page_count":K}`.

The `page` numbers reach 1903 — these look like PDF page numbers, not Confluence
page IDs (which are 5–8 digit integers). This file appears to be a leftover from
an early PDF-extraction phase that predates the current HTML-extraction pipeline.
If `ros-toc.json` is still read anywhere at runtime or in tests, empty strings are
likely causing silent failures. If it's a dead artifact, it should be removed to
avoid confusion.

**Action:** Check whether `ros-toc.json` is imported anywhere in `src/`. If not,
remove it. If yes, either regenerate from the HTML pipeline or fix the extraction.

### 🟡 `link-commands.ts` — page selection takes first candidate; comment promises scoring

In `src/link-commands.ts:153–158`, the comment block describes preferring "the page
whose breadcrumb path is closest to the command path" with a property-count tiebreak.
The implementation directly under it is a one-liner: `const pageId = candidatePageIds[0]`.
For paths that legitimately appear in multiple pages (e.g., `/ip/route` in both "IP
Routing" and "BGP" pages), the link winner depends on insertion order into
`pageToCommandPaths` — which is page-id order from the SELECT, so it's deterministic in
practice but accidentally so. **The 92.9 % link rate hides this:** most paths only have
one candidate page, so the first-candidate shortcut works. The risk is on multi-page
paths where the wrong page becomes the "official" docs URL.

**Action:** Either implement the scoring the comment describes, or delete the comment
and document the actual policy ("first page seen wins; rely on extraction order"). For
LSP purposes the current behaviour is *good enough* — but a wrong link is more annoying
than no link, so either path is better than the current ambiguity.

### 🟡 `schema_nodes._attrs` completion JSON — column promotion pending

The `_attrs` column stores `{"completion": {value: {style, preference, desc?}}}`
as a JSON blob. The `schema_nodes.data_type`, `enum_values`, etc. were promoted
to proper columns, but completion data wasn't. The BACKLOG already tracks this
as `🟡 Completion data column promotion` — flagging here for cross-reference
since the LSP would benefit from queryable completion values (e.g., filtering
by `style='dir'` to separate directory completions from value completions).

### 🟢 `ros-html-assessment.json` — large committed artifact

This 146 KB JSON file appears to be a one-time quality assessment output
(from `src/assess-html.ts`). It should live in `.gitignore` or in `fixtures/`,
not in the repo root, to avoid bloating the repo for non-development users.

### 🟢 Property linking to `schema_nodes` is missing

`properties` rows have `page_id` (links to docs page) but no `command_path` column.
Finding which properties belong to `/ip/firewall/filter` requires:

```sql
SELECT p.* FROM properties p
JOIN commands c ON c.page_id = p.page_id
WHERE c.path = '/ip/firewall/filter'
```

This works but is a two-hop join. For the LSP, it would be cleaner if
`properties` had a `command_path` column denormalized from the join.
Adding it in the extraction pipeline would make property lookups significantly
simpler for downstream consumers.

---

## rosetta changes that would most help the LSP

Ranked by impact (and updated against the verified state of the rosetta repo):

1. **Export `routeros-docs-links.json`** as a GitHub Release asset (filed:
   [tikoci/rosetta#4](https://github.com/tikoci/rosetta/issues/4)). Verified size: **6 KB
   gzipped** for 512 dir entries (the original ~15 KB estimate was conservative). The LSP
   can fetch this without installing rosetta, and fall back to a vendored copy in `docs/`
   if the network isn't available at extension activation.

2. **Build `ros-help-lite.db`** in CI — `pages_lite (id, title, url)`,
   `commands_lite (path, type, description, page_id)`, `properties_lite (name, type,
   default_val, description, page_id, command_path)`. Estimated raw size: ~1 MB
   (pages 31 KB, commands 208 KB, properties 819 KB by string length, pre-overhead).
   Publish as a Release asset alongside `ros-help.db.gz`. **Pair with `sql.js`** in the
   LSP for VSCode Web compatibility — see [§ Option E](#option-e--lite-db--sqljs-web-compatible-richness).

3. **Add `command_path` column to `properties`** — denormalized from
   `commands JOIN pages`. Eliminates the two-hop join and lets the LSP filter properties
   by path with one index hit. Required for the lite DB anyway. Sample SQL in
   tikoci/rosetta#4.

4. **Add a `routeros_lookup_path` MCP tool** — currently `routeros_command_tree` returns
   children at a path but doesn't include `linked_page` or `properties` for the path
   itself; `routeros_search` returns these but as a search result, not a path lookup.
   The LSP-style "give me everything for `/ip/firewall/filter`" doesn't have a dedicated
   tool. Either extend `routeros_command_tree` with `include_page=true` and
   `include_properties=true` flags, or add a new tool. (Cross-ref rosetta `BACKLOG.md`
   § "TUI<>MCP parity gaps" — same north-star concern.)

5. **Fix or remove `ros-toc.json`** (filed:
   [tikoci/rosetta#3](https://github.com/tikoci/rosetta/issues/3)). Low impact for the LSP
   directly, but reduces confusion for any downstream that scans the rosetta repo for data
   files.

6. **Ship the `schema_nodes` work to the released DB.** The current public DB
   (`dist/ros-help.db.gz` from 2026-04-12) doesn't include `schema_nodes` /
   `schema_node_presence` yet, even though `main` has them. Anything that depends on
   per-arch presence or completion enums in the lite DB needs this released first.

7. **Promote completion data to columns** (already in rosetta BACKLOG as 🟡) — enables
   SQL-level filtering for downstream consumers like the LSP. Lower priority for us — the
   live `/console/inspect completion` API gives us version-exact completion data already.
   Useful only as an offline fallback.

---

## Appendix — useful SQL queries for the LSP (if Option B is used)

### Command path → docs URL

```sql
SELECT c.path, p.title, p.url, c.description
FROM commands c
JOIN pages p ON p.id = c.page_id
WHERE c.path = ? AND c.type = 'dir'
LIMIT 1;
```

### Properties for a command path (via page linkage)

```sql
SELECT pr.name, pr.type, pr.default_val, pr.description
FROM properties pr
JOIN commands c ON c.page_id = pr.page_id
WHERE c.path = ?
ORDER BY pr.sort_order;
```

### Properties by arg name (command-agnostic)

```sql
SELECT pr.name, pr.type, pr.default_val, pr.description, p.title, p.url
FROM properties pr
JOIN pages p ON p.id = pr.page_id
WHERE pr.name = ? COLLATE NOCASE
ORDER BY pr.page_id
LIMIT 5;
```

### Callouts for a command path

```sql
SELECT ca.type, ca.content
FROM callouts ca
JOIN commands c ON c.page_id = ca.page_id
WHERE c.path = ?
ORDER BY ca.sort_order
LIMIT 3;
```

### Breaking changelogs for a subsystem category

```sql
SELECT version, description
FROM changelogs
WHERE category = ? AND is_breaking = 1
ORDER BY version DESC
LIMIT 3;
```

### Schema node (structured type data for an arg)

```sql
SELECT path, desc_raw, data_type, enum_values, range_min, range_max, max_length, _attrs
FROM schema_nodes
WHERE path = ? AND type = 'arg';
```

---

## Appendix — canonicalize.ts (rosetta utility applicable to LSP)

rosetta's `src/canonicalize.ts` is a **pure** module (no DB, no I/O) that maps any
RouterOS CLI input form to `{path, verb, args}` tuples. It handles:

- `/ip/firewall/filter` → `{path: '/ip/firewall/filter', verb: null, args: []}`
- `/ip firewall filter add chain=forward` → `{path: '/ip/firewall/filter', verb: 'add', args: [{chain: 'forward'}]}`
- Relative navigation (`..`, `.`), subshells, block constructs

The LSP already infers paths from token context, but `canonicalize.ts` could be
useful for resolving the "current path" during completion (extracting which `/ip/…`
dir the cursor is inside). Verified: zero imports, **61 tests** in
`src/canonicalize.test.ts`. If the LSP needs robust path extraction,
**vendor it rather than depend on rosetta** — it's small (~630 lines) and rosetta
isn't packaged as a library today (see Option D for why "depend on rosetta as a lib"
isn't viable). Vendoring keeps the LSP free of rosetta as a runtime dep while still
benefiting from the parser. Re-vendor on rosetta releases, or convince rosetta to
publish `canonicalize` as its own micro-package on npm — the latter is cleaner if
multiple tikoci tools end up wanting it (tikbook, copilot tooling).

> ✅ **Pre-vendor audit complete + addressed upstream.** See
> [`canonicalize-audit.md`](canonicalize-audit.md) for the 12 findings and 8
> hardenings (H1–H8); the *"two backends, one parser"* design reconciles
> rosetta's DB-backed verb resolution with the LSP's live-inspect path.
>
> **Status (2026-04-26):** rosetta shipped H4 / H6 / H7 / H8 across
> [`9be870b`](https://github.com/tikoci/rosetta/commit/9be870b),
> [`7c3e6fb`](https://github.com/tikoci/rosetta/commit/7c3e6fb), and
> [`e05b508`](https://github.com/tikoci/rosetta/commit/e05b508). The pluggable
> `CanonicalizeOptions { isVerb?: (token, parentPath) => boolean }` is real,
> the universal verb set stays active alongside the resolver (so consumers
> only need to supply menu-specific verbs), and there's now an
> `extractMentions()` plus `confidence` field on each command.
> Rosetta full suite: **546 pass / 5 todo / 0 fail**. Remaining hardenings
> (H1 lenient mode, H2 `Tok.Var`, H3 paren scope, H5 `{` block-value) preserve
> the same options shape so the LSP can pull them by diff. **The LSP can
> adopt canonicalize today** — vendor or wait for an upstream package — and
> wire `isVerb` to live `/console/inspect` highlight observations
> (sketch in the audit's *Path forward* section).

---

## Re-review changelog

**2026-04-25** — third-eye pass against verified rosetta repo state.

| Change | Where | Reason |
|--------|------|--------|
| Sizing: 66 KB / 18 KB → **81 KB / 6 KB** | Option A | Measured against the released DB; gzip on URL-heavy data compresses better than the original estimate. |
| Link rate: ~92 % → **92.9 % (512/551)** | Schema summary | Exact count from released DB. |
| Added: `commands` table actually decomposes into 551 dir / 5,109 cmd / 34,548 arg | Schema summary | The original "~40K" hid that only 551 entries are useful for the docs-link JSON. |
| Added: `schema_nodes` is **not yet in the released DB** | Schema summary, P3 ask | Originally written as if available; in practice rosetta `main` has it but `dist/ros-help.db.gz` doesn't. Pinned this as a release-readiness issue. |
| New section: **Deployment context × access model** | Body | Direct answer to "how does this surface in VSCode Desktop vs. Web vs. npm vs. NeoVim vs. Copilot CLI". |
| New section: **The sqlite-in-VSCode problem** | Body | The user's `bun:sqlite` concern wasn't addressed — added the better-sqlite3 / sql.js / subprocess matrix and recommended sql.js. |
| New section: **Option E — lite DB + sql.js** | Access models | Closes the Web compatibility gap that Options B and C leave open. |
| New section: **Tikbook vs. its own rosetta extension** | Body | The "where does rosetta live in VSCode" architectural question. |
| New section: **Versioning — leveraging the live device** | Body | The original doc treated version-awareness as a tier-2 add-on; clarified it's a free signal because the LSP is online. |
| New section: **Online + offline — who wins for what** | Body | Made the priority rule explicit (live wins for syntax; rosetta wins for prose). |
| Tightened: `link-commands.ts` analysis | Issues found | The original wording said "non-deterministic"; in practice the order is page-id deterministic, just accidentally so — and the 92.9 % rate hides the issue because most paths have one candidate. |
| Tightened: `canonicalize.ts` claim | Appendix | Verified zero imports + 61 tests. Recommend **vendor**, not depend. |
| Added: `routeros_lookup_path` MCP tool ask | rosetta changes | Closest existing tool (`routeros_command_tree`) doesn't return `linked_page` or properties; LSP would benefit from a path-keyed combined query. |
