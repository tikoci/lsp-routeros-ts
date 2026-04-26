# `canonicalize.ts` — pre-vendor hardening audit

> **Status:** Research / Audit — partial fix shipped upstream 2026-04-25
> (see [§ Status of fixes](#status-of-fixes)).
>
> **Subject:** [`tikoci/rosetta:src/canonicalize.ts`](https://github.com/tikoci/rosetta/blob/main/src/canonicalize.ts)
> originally probed at 629 lines / 61 tests; now 645 lines / 98 tests + 9 todo
> after the in-place fixes documented below.
>
> **Goal:** Decide what to test/fix/expand before vendoring this module into the LSP
> (or other tikoci tools). Robust extraction of RouterOS commands from arbitrary text
> is high-value across the org — chat input, MCP-fed text, doc snippets, scheduler
> one-liners, scripts.
>
> **Companion doc:** [`rosetta-alignment.md`](rosetta-alignment.md) explains *why* we'd
> vendor it; this doc explains *what's risky* about doing so today.

## Why a pre-vendor audit

`canonicalize.ts` is a pure module (no DB, no I/O, 61 tests). The existing test suite
covers the **clean CLI input** path well — absolute and relative paths, subshells,
`{ }` blocks, mixed slash/space. That's the path the rosetta TUI/MCP needs.

The LSP and any other consumer that wants to feed it **arbitrary text** (chat messages,
MCP tool input, prose with embedded snippets, markdown fenced blocks) is asking for a
different mode. Today's behaviour against such input is mixed: it never crashes, but
it silently produces wrong (or empty) results often enough to be a footgun.

The audit treats "make it rock-solid for arbitrary text" as a separate mode rather
than a bug fix — the existing strict-CLI behaviour should stay; a new lenient/prose
mode (or extraction-mode flag) should join it.

## Methodology

A 50-input probe harness ([`/tmp/canonicalize-probe`](#reproducer) — see reproducer
section below) was run against the module. Inputs span six categories:

| Category | What it probes |
|----------|---------------|
| Prose contamination | Sentences with embedded `/path/like/this`, leading/trailing words, "then" / "and" connectives |
| Comment / quote | `#` inside strings, `;` inside strings, escaped quotes, unclosed quotes |
| Bracket / brace | Unbalanced `[`, `{`, stray `]`, `{ }` inside quoted strings |
| Scripting constructs | `:foreach`, `:if (cond) do={…}`, `:while`, `:do { } while=`, `:set/:global/:local` |
| Identifier-shaped values | IPv6 with `::`, MAC `AA:BB:…`, CIDR mid-word, `$variable` references |
| Markdown / formatting | Backticks, fenced code blocks, BOM prefix, zero-width space |

**Crashes:** zero across all 50 inputs. The parser is robust as a parser.
**Wrong-but-quiet results:** plenty. Categorized below.

## Findings, by severity

### 🔴 Critical — affects any "extract commands from arbitrary text" use case

**1. Mid-line slash does not restart path context.** Once `inCommand=true`, a `/`
mid-line is treated as a path separator, not a new command boundary. A leading word
becomes a phantom path segment.

| Input | Observed | Expected |
|-------|---------|----------|
| `Run /ip/address/print` | `{path: "/Run/ip/address", verb: "print"}` | `{path: "/ip/address", verb: "print"}` |
| `note /ip/address/print` | `{path: "/note/ip/address/print"}` (no command) | `{path: "/ip/address", verb: "print"}` |
| `/ip/address/print and /ip/route/print` | one command with the second path swallowed as args: `args: ["and", "ip", "route", "print"]` | two commands |
| `First run /ip/address/print and then /ip/route/print to debug.` | one command: `{path: "/First", verb: "run", args: […21 noise tokens…]}` | two commands plus prose discarded |

Root cause: `isAbsolute=true` is only set on the *first* slash; subsequent slashes are
"continue path". For prose extraction, a slash that follows a word boundary (where the
preceding word isn't itself a known path segment) should reset.

**2. `$variable` tokens treated as path segments.** Any reference like `$myAddr` after
a path-shaped run becomes part of the path.

| Input | Observed | Expected |
|-------|---------|----------|
| `:foreach i in=[/ip address find] do={ /ip address remove $i }` | works (`$i` ends up in args) | works |
| `:set x ($a + $b)\n/log/info $x` | `{path: "/log/info", verb: "", args: ["$x"]}` (no verb because `info` not recognized) | `{path: "/log", verb: "info", args: ["$x"]}` |
| `Use $myVar then /ip/address/print` | likely produces `/Use/$myVar/ip/address/print` | one command |

Variables should be a distinct token class so the parser knows "this is never a
path segment, always a value reference."

**3. `:if (cond) do={…}` swallows the entire body.** Parens are not tokenized.

| Input | Observed | Expected |
|-------|---------|----------|
| `:if ($x = 1) do={ /log/info "yes" }` | **zero commands** | one (or zero — the inner is `/log` which is below) |
| `:while ($i < 10) do={ /log/info $i }` | one: `{path: "/log/info", args: ["$i"]}` (not even consistent with `:if`) | one with verb `info` |

The `:if` case is the worse one — the entire script body vanishes. Recommend
recognising `(...)` as expression scope (skip-or-recurse-for-subshells, like `[...]`).
Inconsistency between `:if` and `:while` smells like an order-of-token-arrival accident.

**4. Menu-specific verbs are not recognised.** `GENERAL_COMMANDS` has 13 entries;
`EXTRA_VERBS` adds 14 more. The released DB has ~5,100 `cmd`-type rows. The top 13
verbs cover most usage, but several common ones are missing:

| Missing verb | Where it lives | Status |
|-------------|---------------|--------|
| `unset` | every menu (universal) | ✅ added to `GENERAL_COMMANDS` 2026-04-25 |
| `clear` | universal cmd at the menus that have it | ✅ added 2026-04-25 |
| `reset-counters`, `reset-counters-all` | universal | ✅ added 2026-04-25 |
| `info`, `warning`, `error`, `debug` | **menu-specific** — only at `/log/*` | ❌ **cannot** be added universally — see below |

**The ambiguous-verb case validates the "needs DB-aware resolver" point.** Cross-checking
rosetta's `commands` table revealed:

- `/interface/wireless/info` is a **dir**, not a verb. Adding `info` to the universal
  verb set would mis-resolve `/interface/wireless/info/print` as `path=/interface/wireless`,
  `verb=info`, with `print` orphaned.
- `/error` is itself a top-level **cmd**. Adding `error` would break `/error/print`.
- `info` also appears as an **arg** under `/ip/pool/used/reset/info` and similar.

So the universal hardcoded set genuinely can't grow further without breaking real
paths. The next step is a path-context-aware resolver — see
[§ Two backends, one parser](#two-backends-one-parser) below.

### 🟠 High — affects markdown / prose / mixed input

**5. Backticks are word characters.** ✅ **Fixed 2026-04-25.** Tokenizer now treats
backtick (and U+200B zero-width space) as whitespace both at the top of the outer
loop and inside the word loop. Markdown like `` `/ip/address/print` `` extracts cleanly.

**6. Markdown fence trailing line pollutes paths.** Mostly addressed by #5; the
trailing ` ``` ` is now whitespace and no longer attached to paths.

**7. Pure-navigation paths don't appear in `extractPaths`.** A bare path mention
(no verb) returns no entries from `extractPaths`. For "what does this text reference?"
use cases, `/ip/firewall/filter` should be surfaced even without an attached verb.

| Input | `extractPaths` returns | Should also include |
|-------|----------------------|---------------------|
| `/ip/firewall/filter` | `[]` | `["/ip/firewall/filter"]` |
| `firewall/filter` | `[]` | `["/firewall/filter"]` (or similar) |
| `Look at /ip/firewall/filter for the rules` | `[]` (after fix #1) | `["/ip/firewall/filter"]` |

**8. `source={ /ip/address/print }` extracts the inner script.** RouterOS treats
`source={…}` as a literal value of `/system/script add`; the inner script is **not**
executed at parse time. Today's parser pulls `/ip/address/print` out and **drops** the
outer `add` command.

| Input | Observed | Expected |
|-------|---------|----------|
| `/system/script/add name=foo source={ /ip/address/print }` | one command: `/ip/address/print` (no add!) | one `add` command with `source=…` as an arg |

Fix: when a `{` follows `key=`, treat it as a quoted block-value, not as a scope.
This is subtle and may need the verb-table from #4 to know that `add` doesn't itself
introduce a block.

### 🟡 Medium — cosmetic / trust

**9. BOM and zero-width characters embed into paths.** ✅ **Fixed 2026-04-25.**
Tokenizer strips a leading U+FEFF BOM; treats U+200B as whitespace.

**10. Verb-detection inconsistency between standalone and block contexts.**
`/log/info "hello"` standalone → no command. `do={ /log/info $i }` → one command
with empty verb and `$i` in args. Same input shape, different output shape
depending on outer scope. Hard to predict for downstream consumers.

> **Correction (2026-04-25):** The earlier draft of this audit claimed lines
> 524–528 (`!w.includes('-') && !w.includes('_') && w === w.toLowerCase() &&
> w.length <= 3 && !/^[a-z]/.test(w)`) were unreachable. **They are not.**
> The predicate fires for short, non-alphabetic tokens like `*1` (RouterOS
> internal item IDs) — `*1` is two chars, no `-`/`_`, equals its lowercase
> form (no letters), doesn't start with `[a-z]`. So the branch correctly
> routes ID-like tokens after a path into `args`. Apologies for the earlier
> mischaracterisation. The verb-vs-segment inconsistency in finding #10 stays
> on the books, but it's not because that branch is dead — it's because there
> is no fallback that promotes a trailing menu-specific token (`info`,
> `warning`) into a verb when it isn't in the universal set.

### 🟢 Low — known-quirky-by-design

**11. Single quotes (not RouterOS syntax) break parsing.** RouterOS uses double-quote
only; `'…'` strings come from prose. Today they pollute the tokenizer. Either treat
single quotes as quote characters (lenient mode) or as whitespace (strict mode).

**12. Verb-only-at-root produces `{path: "/", verb: "print"}` from a stray word.**
Reasonable for CLI input (where `print` is valid at any menu); noisy for prose. Add
confidence flag.

## Two backends, one parser

The original audit treated `canonicalize.ts` as one module that needs a fixed,
hardcoded verb table. **This was the wrong frame.** Different consumers have
different access to verb-resolution data, and the parser should accommodate that
without picking a side.

### Three deployment shapes, three resolvers

| Consumer | What it has | Verb-resolution backend |
|----------|-------------|--------------------------|
| **rosetta** (TUI / MCP server) | The full `commands` SQLite table (5,109 cmd rows; 40K total nodes; multi-version) | `SELECT 1 FROM commands WHERE name=? AND parent_path=? AND type='cmd'` — sub-millisecond per call |
| **lsp-routeros-ts** | Live `/console/inspect highlight` API on the connected RouterOS device | Per-character token classification — knows whether each token is a `cmd-name` for the *exact* connected version |
| **tikbook / Copilot tooling / standalone scripts** | Neither — pure-text use case | Static `verbs.json` artifact (or fall back to the universal hardcoded set) |

Each backend has different precision and cost characteristics:

| Backend | Latency | Version awareness | Path-context aware | Available offline |
|---------|---------|-------------------|---------------------|-------------------|
| Rosetta DB | <1 ms | Single primary version (7.22) | ✅ yes (parent_path filter) | ✅ yes |
| LSP live | ~50–200 ms (HTTP) | ✅ exact connected version | ✅ yes (RouterOS parser is path-aware) | ❌ needs device |
| Static `verbs.json` | <1 ms | Single snapshot version | ✅ yes if shipped with parent_path | ✅ yes |
| Hardcoded universal set (today) | 0 | n/a | ❌ no — drops menu-specific verbs | ✅ yes |

**Implication:** the parser shouldn't try to *be* path-context-aware on its own
(no hardcoded set can express "info is a verb under `/log` but a dir under
`/interface/wireless`"). It should expose a hook for the consumer to inject
their resolver, then default to the universal set when no resolver is provided.

### Proposed extension point: `isVerb` callback

```ts
export interface CanonicalizeOptions {
  cwd?: string;
  mode?: 'strict' | 'lenient';
  /** Optional path-context-aware verb classifier. Called when the parser
   *  encounters a token that *could* be either a path segment or a verb,
   *  with the parent path resolved so far. Return true to treat it as a verb.
   *  Falls back to the hardcoded universal set when not provided.
   *  MUST be synchronous — the parser does not await. */
  isVerb?: (token: string, parentPath: string) => boolean;
}
```

Consumer wiring:

- **rosetta** (`src/query.ts` or a new `src/canonicalize-db.ts`):

  ```ts
  const isVerb = (token: string, parentPath: string) =>
    db.prepare("SELECT 1 FROM commands WHERE name=? AND parent_path=? AND type='cmd'")
      .get(token, parentPath) !== undefined;
  canonicalize(input, '/', { isVerb });
  ```

- **lsp-routeros-ts**: load a static `verbs.json` (~20 KB) at startup; optionally
  augment with verbs observed in `/console/inspect highlight` responses as the
  user types (cache to a `Set<string>` keyed by `${parentPath}:${name}`).
- **standalone / no-deps**: omit the option; get the universal set.

This keeps the module pure and dependency-free while letting each consumer choose
its precision/cost tradeoff. **Recommend including the resolver design in any
upstream PR alongside the lenient mode (H1).**

### Why this matters for vendoring

A vendored copy in lsp-routeros-ts would carry the same hook — and we'd wire it
to either rosetta's published `verbs.json` (initially) or to live-cached classifications
from `/console/inspect` (later). Either way, the parser code stays identical to
upstream. Vendor drift is minimised.

---

## Hardenings worth shipping (ranked by impact)

These are concrete proposals, suitable for either a rosetta PR or a vendoring patch.

### H1 — Add a `mode: 'strict' | 'lenient'` parameter

```ts
canonicalize(input, cwd, { mode: 'strict' })   // current behaviour, for clean CLI input
canonicalize(input, cwd, { mode: 'lenient' })  // for prose / chat / MCP text
```

In **lenient** mode:

- A leading word that isn't a `/`-prefixed path is dropped, not promoted to a
  phantom path segment.
- A `/` after non-whitespace, non-path-segment context starts a new command.
- Single-quoted strings are recognised and ignored.
- Backticks are whitespace.
- BOM and zero-width chars are stripped.

This preserves existing tests (strict is the default) and gives consumers an opt-in
to the prose-friendly behaviour. The LSP would always pass `'lenient'`.

### H2 — Variable token (`Tok.Var`)

Add a tokenizer rule: `$identifier` becomes `Tok.Var`. The parser treats `Tok.Var`
as always-an-arg (never a path segment, never a verb). Closes findings #2.

### H3 — Paren expression scope

Tokenize `(` and `)` as `Tok.LParen` / `Tok.RParen`. In the parser, when seen
outside of a `key=…` value, recurse like `[…]` but **don't** emit any commands found
inside (unless they're nested `[…]` subshells). Closes finding #3.

Alternative: parse-and-keep, since `[…]` *inside* `(…)` is a real subshell. The
recursion-then-discard-non-subshell version handles this naturally.

### H4 — Pluggable `isVerb` resolver + optional `verbs.json` artifact

See [§ Two backends, one parser](#two-backends-one-parser) for the full design.
TL;DR:

1. Add an `isVerb(token, parentPath) => boolean` option to `canonicalize()`.
2. Default behaviour (no callback) stays as it is today — universal hardcoded set.
3. rosetta's CI publishes a `verbs.json` `(parent_path, name)` extract from the
   `commands` table (~5,100 cmd rows; estimated 50 KB raw / 10 KB gzipped).
4. Consumers wire whichever backend they have: rosetta → DB query;
   lsp-routeros-ts → static `verbs.json` + live `/console/inspect` augmentation;
   standalone → omit, get the universal set.

Closes finding #4 without forcing every consumer to ship a 200 MB DB.

### H5 — `{` after `key=` is a literal block value

When the tokenizer sees `key=` followed by `{`, consume up to the matching `}` as a
single quoted-block argument value. Don't recurse. Closes finding #8.

### H6 — `extractPaths` includes pure-navigation paths

When the parser ends a command sequence with no verb but a non-root finalPath, emit
a `path`-only entry (with `verb: ''`, `args: []`). Or expose a separate
`extractMentions(input)` function that returns *every* path the text references, not
only those tied to a verb. Closes finding #7.

### H7 — Strip BOM, normalize zero-width spaces

One-liner in `tokenize()`: `input = input.replace(/^﻿/, '').replace(/[​-‍⁠]/g, ' ')`.
Closes finding #9.

### H8 — Confidence flag on results

Each `CanonicalCommand` gets a `confidence: 'high' | 'medium' | 'low'` field:

- **high** — well-formed CLI input (absolute path with known verb)
- **medium** — relative path with cwd, or unknown verb at known dir
- **low** — extracted from prose (lenient mode and the path didn't start at offset 0)

Lets consumers filter (e.g., the LSP could ignore `low` for hover, accept all for
"what's this script doing?" queries).

## Status of fixes

Roadmap tracked at [`tikoci/rosetta#5`](https://github.com/tikoci/rosetta/issues/5).
Three rosetta commits delivered the bulk of the audit:

**2026-04-25 — [`9be870b`](https://github.com/tikoci/rosetta/commit/9be870b)** (safe in-place fixes):

- ✅ **H7 — BOM strip + zero-width as whitespace** (tokenizer; closes finding #9).
- ✅ **Backticks as whitespace** in both outer + word loop (closes finding #5).
- ✅ **Universal verbs expanded** with `unset`, `clear`, `reset-counters`,
  `reset-counters-all` (partially closes finding #4 — the verbs that are *truly*
  universal in the rosetta DB).
- ✅ **Fuzz test suite added** at `src/canonicalize.fuzz.test.ts`.

**2026-04-26 — [`7c3e6fb`](https://github.com/tikoci/rosetta/commit/7c3e6fb)**
(the H4/H6/H8 design from this audit, shipped as one feature commit):

- ✅ **H4 — pluggable `isVerb` resolver.**
  `CanonicalizeOptions { isVerb?: (token, parentPath) => boolean }` threaded
  through `canonicalize()`, `extractPaths()`, `primaryPath()`, and the new
  `extractMentions()`. Path-aware lookup fires both at Word-time and at
  flushCommand-time so `/log/info` and `/system/script/run` resolve correctly.
- ✅ **rosetta wiring for H4** — new `src/canonicalize-resolver.ts` exports
  `makeDbVerbResolver(db)` against `commands` table; threaded through
  `classifyQuery({ isVerb })` so MCP `routeros_search` and TUI `s` benefit
  automatically.
- ✅ **H6 — `extractMentions(input, cwd?, options?)`** returns every distinct
  path the input references, including bare navigation. `ParseResult` also
  gained a `mentions: string[]` field. `extractPaths()` semantics unchanged.
- ✅ **H8 — `confidence: 'high' | 'medium' | 'low'`** on each `CanonicalCommand`.
  `high` for absolute path with directly-identified verb, `medium` for
  relative-with-cwd / pure navigation / blocks, `low` when verb was inferred
  from a trailing path segment at flush time.
- ✅ **DESIGN.md** in rosetta gained a new section *"`canonicalize.ts` —
  vendoring intent and DB-backed verb resolver"* explaining shape parity.

**2026-04-26 — [`e05b508`](https://github.com/tikoci/rosetta/commit/e05b508)**
(important refinement — the universal verb set is **not** displaced by the
resolver; it stays active and the resolver supplements it):

- ✅ `isVerbAt()` now does `isKnownVerb(token) || options.isVerb?.(token, parentPath)`.
  This means downstream consumers (LSP) only need their resolver to add
  *path-specific* verbs — they don't have to enumerate ubiquitous helpers like
  `find`. Important for the LSP's live-`/console/inspect` resolver: a
  highlight response only marks tokens that appear in *that* script, so we'd
  never see `find` if the script doesn't use it. The universal fallback
  prevents that gap.

Test count: rosetta full suite now **546 pass / 5 todo / 0 fail** (was 61 / 0
before the audit). The original tests are unchanged.

Still on the books (not yet shipped):

- ⬜ **H1** — `mode: 'strict' | 'lenient'` parameter. Biggest remaining payoff
  for chat / MCP / prose input. Anchor tests in `canonicalize.fuzz.test.ts`
  document the strict-mode behaviour to preserve.
- ⬜ **H2** — `Tok.Var` for `$identifier`. Today's behaviour is *good enough*
  in args position (most common case). Path-position `$var` is still wrong but
  uncommon.
- ⬜ **H3** — paren `(…)` expression scope. Affects `:if` / `:while` body
  extraction.
- ⬜ **H5** — `{` after `key=` as block-value (closes finding #8 — `source={…}`).

The remaining 5 `test.todo` entries in the fuzz test file mirror this list.

## Suggested test fixtures

Add as fixtures alongside `canonicalize.test.ts`:

- `fixtures/canonicalize/prose.txt` — 50 prose-with-embedded-commands examples,
  each annotated with expected extractions. Use as snapshot input.
- `fixtures/canonicalize/scripts.rsc` — real scripts from `tikoci/lsp-routeros-ts`'s
  `test-data/eworm/` and `test-data/forum/` directories — already 100+ scripts that
  would exercise the parser against community-written code.
- `fixtures/canonicalize/markdown.md` — fenced code blocks, inline backtick paths,
  doc-style mentions.

The existing `test-data/edge-cases/*.rsc` files in lsp-routeros-ts (empty, comment-only,
single-command, oversize, unicode) are a good starting point for stress fixtures.

## Reproducer

The probe was ported into rosetta's test suite at
[`tikoci/rosetta:src/canonicalize.fuzz.test.ts`](https://github.com/tikoci/rosetta/blob/main/src/canonicalize.fuzz.test.ts).
Run it from the rosetta repo:

```bash
cd ~/GitHub/rosetta
bun test src/canonicalize.fuzz.test.ts                  # fuzz tests only
bun test src/canonicalize.test.ts src/canonicalize.fuzz.test.ts   # all canonicalize tests
```

Expected output today: 98 pass, 9 todo, 0 fail (with the H7 + universal-verb +
backtick fixes applied). Each `test.todo` corresponds to a hardening from
[§ Status of fixes](#status-of-fixes); flip them to `test(...)` as the fix lands.

Conventions in the file:

- `test(...)` blocks marked "anchor" document **current behaviour** including
  known-wrong outputs. Update the assertion when an intentional fix changes them.
- `test.todo(...)` blocks describe **target behaviour** for an unshipped hardening.
- `describe('does not crash on malformed input', ...)` is the no-throw probe —
  a safety net. New torture inputs should land here first.

## Path forward

H4/H6/H7/H8 are upstream. The remaining work splits cleanly:

### Upstream-tracked (rosetta will likely ship)

H1 (lenient mode), H2 (`Tok.Var`), H3 (paren scope), H5 (`{` block-value) all
preserve the same `CanonicalizeOptions` shape, so any LSP consumer can pull
them by diff once landed. H1 is the biggest remaining payoff for prose / MCP
input; H3 is the next-most-impactful for script analysis (`:if (…)`/`:while (…)`).

### LSP-side wiring (when we adopt canonicalize)

When the LSP picks this up — either by vendoring or by depending on a future
`@tikoci/canonicalize-routeros` package — wire `isVerb` to the live device:

```ts
// Sketch — not yet implemented in lsp-routeros-ts.
// Cache verb classifications observed in /console/inspect highlight responses.
const verbCache = new Map<string, boolean>(); // key: `${parentPath}\0${name}`
function recordHighlightTokens(tokens: HighlightToken[], parentPath: string) {
  for (const t of tokens) {
    if (t.type === 'cmd-name') verbCache.set(`${parentPath}\0${t.text}`, true);
  }
}
const isVerb = (token: string, parentPath: string) =>
  verbCache.get(`${parentPath}\0${token}`) === true;
canonicalize(input, '/', { isVerb });
```

Two notes on this wiring:

- The universal verb set still fires first (per
  [`e05b508`](https://github.com/tikoci/rosetta/commit/e05b508)), so our
  resolver only needs to *add* device-observed menu-specific verbs — we don't
  need to seed it with `add`/`set`/`get`/etc.
- For tokens we haven't seen in any highlight response yet, the cache
  returns `false` and the universal fallback decides. That's fine — the
  parser is already conservative when no evidence exists.

A future enhancement could optionally consume `routeros-verbs.json` from
rosetta CI ([tikoci/rosetta#4](https://github.com/tikoci/rosetta/issues/4)
neighbour) for cold-start coverage in deployment contexts where there's no
live device yet (e.g., editing a script before `useConnectionUrl` is set).

**Vendoring is no longer required to use canonicalize today.** With H7 + the
expanded verb set, the parser is robust enough for "what RouterOS commands does
this script reference?" against well-formed input (which is what `test-data/`
scripts and most MCP tool input look like). Vendor only when we need the lenient
prose-extraction path (H1).

## Cross-references

- Original alignment doc: [`docs/rosetta-alignment.md`](rosetta-alignment.md) §
  Appendix — canonicalize.ts (rosetta utility applicable to LSP)
- BACKLOG: [`BACKLOG.md`](../BACKLOG.md) → `[research: rosetta-join] P2: Vendor canonicalize.ts`
- Source under audit: [`tikoci/rosetta:src/canonicalize.ts`](https://github.com/tikoci/rosetta/blob/main/src/canonicalize.ts)
- Existing tests: [`tikoci/rosetta:src/canonicalize.test.ts`](https://github.com/tikoci/rosetta/blob/main/src/canonicalize.test.ts)
