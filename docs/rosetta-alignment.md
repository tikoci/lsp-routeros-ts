# rosetta ↔ LSP Alignment Research

> **Status:** Research / Design — no code yet.
>
> **Core constraint:** No runtime dependency on rosetta. The LSP must work without it;
> rosetta enrichment is opt-in via external data files or an optional DB probe.
>
> **Related:** [`BACKLOG.md` → `[research: rosetta-join]`](../BACKLOG.md),
> [`tikoci/rosetta`](https://github.com/tikoci/rosetta)

## What this document covers

A deep-dive into `tikoci/rosetta`'s database schema and source code to identify where
rosetta data could enrich LSP operations (hover, completion, document links, diagnostics)
without creating a hard dependency. Includes an access-model comparison, a prioritised
action plan, and bugs/gaps found in rosetta during the investigation.

---

## What rosetta contains (schema summary)

rosetta is a ~200 MB SQLite database (`ros-help.db`) built from several sources:

| Table | Rows | Source | Relevance to LSP |
|-------|------|--------|-----------------|
| `pages` | 317 | Confluence HTML export (March 2026) | `url` → help.mikrotik.com deep links |
| `properties` | 4,860 | HTML property tables | Arg descriptions, types, defaults |
| `sections` | 2,984 | h1–h3 headings across pages | Section-level deep links |
| `commands` | ~40K | `inspect.json` (7.22 primary) | Path→page linkage, descriptions |
| `schema_nodes` | ~40K | `deep-inspect.json` (dual-arch) | Structured types, enums, ranges, completion data |
| `schema_node_presence` | 1.67M | All 46 versions (7.9–7.23beta2) | Version range for a command path |
| `command_versions` | 1.67M | Same | Compat layer for `commands` |
| `changelogs` | parsed entries | MikroTik download server | Breaking change flags per category |
| `devices` | 144 | mikrotik.com product matrix | Hardware specs if device is identified |
| `device_test_results` | 2,874 | mikrotik.com product pages | Throughput benchmarks |
| `videos` + `video_segments` | 518 videos | YouTube (yt-dlp transcripts) | Tutorial links by topic |
| `callouts` | 1,034 | Confluence callout macros | Notes/warnings attached to pages |
| `glossary` | seeded | In-DB seed | RouterOS term definitions |

**The key link:** `commands.page_id → pages.id → pages.url`.
~92% of `dir`-type commands are already linked. `url` is a `help.mikrotik.com/docs/...` URL.

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

**Size estimate:** ~551 `dir`-type commands × ~120 bytes ≈ 66 KB uncompressed,
~18 KB gzipped. Trivially embeddable or fetchable.

**Pros:** Zero runtime dependency. Works in VSCode Web. Works offline. No installs.
Simple `Map<path, entry>` lookup in the LSP.

**Cons:** Stale between rosetta releases. Only captures one version snapshot.

**Verdict:** This is the right first step. The LSP just needs a `path → {url, title}` lookup.

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

### Option D — Rosetta as a library (not recommended)

Importing rosetta's `query.ts` directly. rosetta is a Bun project with DB-heavy
internals — not currently designed as a library.

**Cons:** The 200 MB DB is still needed. Adds tight coupling. Bun-only (no browser).
Doesn't simplify anything over Option B.

**Verdict:** Skip. Direct SQLite access (Option B/C) is simpler and more portable.

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

### 🟡 `link-commands.ts` — page selection is non-deterministic for multi-page commands

When multiple pages reference the same command path, the linker picks
`candidatePageIds[0]` without scoring. The code comment mentions preferring "the
page whose breadcrumb path is closest to the command path" but the scoring logic
is not implemented — it just takes the first candidate. For command paths that
appear in many pages (e.g., `/ip/route` appears in both "IP Routing" and
"BGP" pages), which page wins depends on iteration order.

**Action:** Implement breadcrumb-proximity scoring in `linkDir` or add a tie-breaker
using `properties` count (more property tables → more authoritative page).

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

Ranked by impact:

1. **Export `routeros-docs-links.json`** as a GitHub Release asset — just path + url + title
   for all linked dirs. ~15 KB gzipped. The LSP can fetch this without installing rosetta.

2. **Add `command_path` column to `properties`** table — denormalized from the
   `commands JOIN pages` join. Makes property lookup by path O(1) instead of a two-hop join.

3. **Build `ros-help-lite.db`** in CI — pages (id, title, url) + commands (path, type, description, page_id) + properties (name, type, default_val, description, page_id). ~2–4 MB. Publish as a GitHub Release asset.

4. **Fix or remove `ros-toc.json`** — either regenerate from HTML pipeline with proper titles
   or delete it.

5. **Promote completion data to columns** (already in BACKLOG) — enables SQL-level filtering
   for downstream consumers like the LSP.

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
dir the cursor is inside). It has 61 tests. If the LSP needs robust path extraction,
consider vendoring or depending on this module rather than re-implementing it.
