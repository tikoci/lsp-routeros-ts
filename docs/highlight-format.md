# RouterOS highlight — Format Reference

> Reference for the per-character token stream returned by
> `/console/inspect request=highlight` — the data behind this LSP's semantic
> tokens and diagnostics. Grounded on a 913-script full-corpus sweep against
> CHR **7.23.2** (stable), re-run on **7.24rc2** (testing) and **7.9.2** (the
> earliest plain-HTTP REST branch tested here) for drift, plus 23 targeted probes for rare token
> classes. Capture artifacts:
> `test-data/highlight-summary.v<version>.json` (from
> `scripts/collect-highlight.ts`); the six committed `.rsc.highlight` fixtures
> (pre-7.23, unversioned) remain the offline snapshot-test inputs.
>
> Companion doc: [`parseil-format.md`](parseil-format.md) covers `:parse` IL —
> the *structural* view of a script. Highlight is the *lexical* view: where
> every character belongs. §6 compares the two.

## 1. What highlight is

RouterOS's console classifies every character of console input into a token
class — the same classification that colors text in the CLI terminal. The
`/console/inspect` REST endpoint exposes it verbatim:

```text
POST /rest/console/inspect
{"request": "highlight", "input": ":put 1"}

→ [{"highlight": "dir,cmd,cmd,cmd,none,none", "type": "highlight"}]
```

The `highlight` field is a comma-joined list of token-class names, **exactly
one per input byte** — for ASCII input, one per character (verified across all
913 corpus files). Empty input returns `"highlight": ""`, which represents zero
tokens; guard it before splitting or naïve `"".split(',')` produces a fake
token named `""`. Multi-byte UTF-8 input is accepted but each *byte* gets a token
(`café` in a string → four `none` + one extra for é's second byte), which
desynchronizes token indexes from JS string offsets — see §2. The response
array always contains exactly one item (`type` is always `"highlight"`; zero
multi-item responses across all three sweeps).

Because the classifier is the *live console's own tokenizer*, the result is
version-exact and — important — **stateful**: token classes depend not just on
syntax but on the connected device's command tree, installed packages, and
even runtime object flags (see §4). This is why the LSP has no offline mode,
and why any static re-implementation can only approximate it.

## 2. Request contract

| Field | Value | Notes |
|---|---|---|
| `request` | `"highlight"` | Other values: `completion`, `syntax`, `child` — different response shapes entirely. |
| `input` | The script text | **Send ASCII.** The API *accepts* non-ASCII, but tokens are per **byte**: a multi-byte character gets multiple tokens, so token indexes stop matching string offsets. The LSP replaces every char > 127 with `?` before sending (`replaceNonAscii` in `server/src/routeros.ts`) to guarantee 1 char = 1 byte = 1 token. Either way, a non-ASCII (or `?`) byte in *identifier* position is a hard `error` (§4); inside strings and comments it is harmless. |
| `path` | optional context menu, comma-separated (`"ip,address"`) | Input is classified as if typed at that menu prompt: `print` alone → `cmd`; `add address=…` → `cmd`/`arg`. Root context if omitted. |

Limits (same numbers as the rest of `/console/inspect`):

- Input beyond **32,767 bytes** (`ROUTEROS_API_MAX_BYTES`) is not accepted;
  the LSP truncates before sending and flags the tail with a "Too long"
  warning diagnostic.
- Response time scales with input size *and* syntax complexity. Corpus timing
  on 7.23.2 (CHR under QEMU/HVF, 1 vCPU): mean 79 ms, p50 39 ms, p95 277 ms;
  the three 32 KB files took 2.0–3.4 s. The ~28 KB latency cliff is tracked as
  `[research: 28kb]` in `BACKLOG.md`; `:parse` has no such cliff
  (see `parseil-format.md` §2).

## 3. Token vocabulary

Across 913 corpus files on 7.23.2, **19 token classes** were observed (7.24rc2:
identical vocabulary; 7.9.2: the same minus `arg-scope`/`arg-dot` — dotted
argument names postdate it). Counts below are total characters / files
containing the class on 7.23.2, from `highlight-summary.v7.23.2.json`.

### 3.1 Structure tokens

| Class | Chars | Files | Meaning (observed) |
|---|---:|---:|---|
| `none` | 501,727 | 911 | Everything unclassified: whitespace, literal values (numbers, strings' contents, IPs, times), and **all text after a hard error** (§4). |
| `dir` | 34,982 | 755 | Menu-path segments *including their slashes* (`/ip/address/` is one `dir` run, trailing slash included) — and the `:` sigil of scripting commands (`:put` → `:`=`dir`, `put`=`cmd`). Space-separated path form tokenizes each segment as `dir` with `none` gaps. |
| `cmd` | 55,717 | 710 | Command name (`print`, `add`, `local`, `if`…). |
| `arg` | 29,888 | 529 | Argument name before `=` (`chain`, `do`, `else`, `where`…). |
| `arg-scope` | 171 | 7 | Prefix of a dotted argument: `export` in `export.route-targets=`. |
| `arg-dot` | 20 | 5 | The `.` of a dotted argument (suffix is plain `arg`). |
| `syntax-meta` | 140,002 | 772 | Punctuation with syntactic meaning: `"` quotes, `$` sigil, `=`, `={`, `}`, `(`, `)`, `;`, `[`, `]`, `,`. |
| `escaped` | 20,261 | 208 | Escape sequences inside strings: `\"`, `\$`, `\n`, hex escapes (`\E2\9A\99`), and the line-continuation backslash before a newline. |
| `comment` | 257,581 | 911 | Whole comment including the leading `#`. |

### 3.2 Variable tokens

The console resolves names against lexical scope — with or without the `$`
sigil (the sigil itself is `syntax-meta`; the name carries the class).

| Class | Chars | Files | Meaning (observed) |
|---|---:|---:|---|
| `variable-local` | 62,893 | 374 | Name declared by `:local` — at declaration and every use. Quoted names (`:local "my var"`) carry the class across the quotes. **Also: menu-property names in `where`/filter expressions** (`dst-address` in `print where dst-address=…`) — the console binds the target menu's fields as locals, matching parseIL's `findwhere=$field` dump (`parseil-format.md` §5.2). |
| `variable-global` | 23,224 | 302 | Name declared by `:global`, declaration and uses. |
| `variable-auto` | 3,014 | 162 | Loop-bound names: `:foreach k,v in=…`, `:for i from=…` — declaration and uses. |
| `variable-parameter` | 6,671 | 311 | Function parameters (`$1`, `$0`, named params inside `do={}` bodies) — **and any `$name` reference with no visible declaration**. The console cannot distinguish "undeclared" from "will be supplied as a parameter at call time", so an undeclared `$typo` reads as `variable-parameter`, not an error. |
| `variable-undefined` | 212 | 20 | A **bare identifier in expression position** that resolves to nothing: `(lppp=0)` in an `:if` condition, `$(apikey)` with undeclared `apikey`, a non-field word in a `where` clause. This — not `variable-parameter` — is the "probably a typo" signal. |

### 3.3 State and error tokens

| Class | Chars | Files | Meaning (observed) |
|---|---:|---:|---|
| `obj-inactive` | 3,639 | 243 | A name that doesn't resolve *on this device*: unknown command (`:foobar`, `getall`), unknown argument at this path, unknown/removed menu (`caps-man` on 7.23+), or an **ambiguous prefix** (`a` at `/ip` could be `address`/`arp`/…; unique prefixes like `ad` resolve normally to `dir`). Classification continues after it — it is a soft marker. |
| `obj-disabled` | 7 | 1 | Reference to an existing object whose **disabled flag is set on the live device** (e.g. `www-ssl` in `/ip/service enable www-ssl` while that service is disabled). |
| `obj-dynamic` | 24 | 4 | Reference to an object that is **dynamic on the live device** (e.g. `routing-table=main` — `main` is a dynamic table). |
| `syntax-obsolete` | 3 | 3 | Accepted-but-deprecated syntax, marked on the divergence character: the space in old-style `} else {` (modern form is `else={`). |
| `error` | 333 | 333 | Hard parse error — see §4. Always exactly **one character**. |

## 4. The error model — one char, then silence

`error` marks the **first character the parser cannot proceed past — and only
that character**. Everything after it in the entire input is `none`
(unclassified), even if perfectly valid:

```text
input:  :local x 1\n???\n:put $x
        ::local x 1              → dir,cmd,…,variable-local,none
        ?                        → error        (first ? only)
        ??\n:put $x              → none,none,…  (classification stopped)
```

In the corpus this shows up as *exactly one `error` character per affected
file* — 333 of 913 files on 7.23.2, never two.

Observed `error` triggers, with their measured share of the 333 affected
corpus files (each file's single error char was re-fetched and classified):

- **Descending into an unresolvable path** — the unknown name itself is soft
  (`caps-man` → `obj-inactive`), but the following `/` that tries to enter it
  is the hard `error` (`/caps-man/manager/…` → `error` on the second `/`).
  On this capture device that includes `/caps-man`, `/system/gps`, and
  `/zerotier` (absent package or version churn).
- **Non-script content** — the forum-sourced corpus includes pasted console
  transcripts (`[user@device] > …` prompt lines, `print` output columns, log
  lines, even JavaScript), and the first character the parser chokes on gets
  the `error`. Together with missing menus this accounts for nearly all of the
  329 non-substitution cases.
- A byte that cannot start a token in code position — including the `?` the
  LSP substitutes for non-ASCII (§5) and raw multi-byte characters in
  identifier position (`:local café` → `error` on é's first byte). Only 4 of
  the 333 corpus hits come from `?`-substitution.
- `:set` on an undeclared name (`:set q 1` → `q` is `error`; RouterOS requires
  the variable to exist).

Contrast with the soft markers: `obj-inactive`/`obj-disabled`/`obj-dynamic`/
`syntax-obsolete`/`variable-undefined` do **not** stop classification — the
rest of the script stays fully tokenized.

**Consequences:**

- Highlight yields **at most one hard error position per request** — it does
  *not* mark every error in the script. Multi-error diagnostics would require
  iterative re-requests past each error point. (This corrects the shorthand in
  `parseil-format.md` §4 that highlight "marks every error token and
  continues" — what continues is the 1:1 token stream, not the analysis.)
- Everything *before* the error is still fully classified, and the error
  position is exact — so a single request gives one precise error plus intact
  highlighting up to it. This is exactly how `validation.ts` consumes it:
  error-class tokens become Error diagnostics, and the region after the last
  one gets a "Potential issues due to prior highlight error" warning because
  it is genuinely unchecked.
- `:parse` is the complementary probe: it also stops at the first error but
  returns a *message with line/column* and (for valid scripts) the structural
  IL — while highlight returns positions without messages. Pairing them gives
  message + range.

The LSP's error set (`HighlightTokens.ErrorTokenTypes` in
`server/src/tokens.ts`) treats `error`, `variable-undefined`, `obj-inactive`,
`obj-dynamic`, `obj-disabled`, `syntax-obsolete`, `syntax-old`, and
`ambiguous` as diagnostics-worthy.

That set is an **LSP policy**, not the RouterOS grammar's error taxonomy. Only
`error` is the measured hard parser stop. `obj-disabled` and `obj-dynamic` can
describe perfectly valid references to live objects; `syntax-obsolete` is
accepted syntax; and `obj-inactive` mixes unknown names with version/package
and ambiguity effects. A generic skill or centrs `explain` implementation
should preserve the class and evidence, then let its caller choose warning/error
severity instead of copying `ErrorTokenTypes` as “invalid syntax.”

## 5. Statefulness and encoding gotchas

**The same input tokenizes differently on different devices — or the same
device in a different state.** Observed dependencies:

| Dependency | Example |
|---|---|
| RouterOS version / command tree | `caps-man` resolves pre-wifi-rework, is `obj-inactive` + `error` on 7.23.2. 22 of 913 corpus files changed token sets between 7.23.2 and 7.24rc2, all schema churn (§7). |
| Installed packages | A package's menus vanish from the tree when absent — same effect as version churn. |
| Runtime object flags | `obj-disabled` / `obj-dynamic` reflect the *current* disabled/dynamic state of the referenced object — a `/ip/service enable www-ssl` line changes class when someone enables the service. |
| Declared globals | `:global` names resolve against the running environment as well as the script text. |

Implications: snapshot fixtures must record the capture version (and ideally
device state); caches must invalidate on reconnect; and a "reference" token
stream from one router is only approximately valid for another.

**The `?` substitution can invent errors — but rarely does.** `?` is not a
valid identifier character, so `:local café 1` sent as `:local caf? 1` makes
the `?` a hard `error` that also unclassifies the rest of the script. In
practice this is rare: only 4 of the corpus's 333 error files trace to
substitution, because real-world non-ASCII lives almost entirely inside
strings and comments, where the replacement is harmless. Note the alternative
is no better — sending the é raw also errors (on its first byte) *and* breaks
token/offset alignment (§2), so substitution is the right trade; it just can't
rescue non-ASCII identifiers, which RouterOS itself won't accept over this
API.

## 6. Highlight vs `:parse` — which probe for which job

| Question | Use | Why |
|---|---|---|
| Token class at each character | **highlight** | Only per-character source. |
| Semantic tokens / editor coloring | **highlight** | Direct mapping (see §8). |
| First-error position | either | highlight: exact char, no message. `:parse`: line/column + message stem. Pair them for message + range. |
| All errors in a script | *neither, fully* | Both stop at the first hard error. Highlight additionally gives soft markers (`obj-*`, `variable-undefined`, `syntax-obsolete`) for the region before it. |
| Structure: blocks, scopes, functions | **`:parse`** | IL nests block bodies; highlight is flat per-character. |
| Canonicalisation (`200ms` → `00:00:00.200`) | **`:parse`** | IL shows the evaluated form. |
| Menu-field enumeration for a `where` | either | highlight classes fields as `variable-local`; parseIL dumps them in `findwhere=`. |
| Oversize scripts (> 32 KB) | **`:parse`** | No 32 KB cap (56 KB verified; REST upload caps ~126 KiB). |
| Cheap validity pre-check | **`:parse`** | Flat ~10 ms typical, no 28 KB cliff. |

## 7. Cross-version drift (7.23.2 → 7.24rc2)

The full 913-file corpus re-captured on 7.24rc2:

- **Vocabulary identical** — same 19 classes, nothing new, nothing gone.
- **891/913 files (97.6%) have identical token-class sets**; per-class corpus
  totals move by < 1% (except `obj-inactive`, +7% files).
- The 22 differing files decompose into: 12 gained `obj-inactive` (a name that
  7.23.2 resolved no longer exists), 5 flipped `error` → `obj-inactive` and
  2 flipped `error` → `arg` (schema additions/removals moving the first hard
  stop), 2 lost `variable-undefined`, 1 gained `syntax-meta`.

So drift mirrors parseIL's pattern (`parseil-format.md` §5.1): the *format* is
stable across versions; the *classifications* leak the live command schema.
Version-tag any comparison artifacts.

### 7.1 The 7.9.2 plain-HTTP floor check

A third full sweep against **7.9.2** — from the first release branch where the
REST API can use the plain-HTTP `www` service — extends the measured floor substantially
(`highlight-summary.v7.9.2.json`):

RouterOS REST itself predates 7.9: MikroTik documents its introduction in
[7.1beta4](https://help.mikrotik.com/docs/spaces/ROS/pages/47579162/REST%2BAPI),
when access required `www-ssl`. This study therefore does **not** establish the
highlight format for 7.1–7.8; an HTTPS capture is the remaining historical-floor
check.

- Wire format identical: one token per byte, same response shape, same core
  class names.
- **17 classes observed** — everything from §3 except `arg-scope`/`arg-dot`
  (dotted argument names like `export.route-targets=` did not exist yet).
- Old RouterOS was *harsher*: an unknown argument name is a hard `error` on
  7.9.2 but a soft `obj-inactive` on 7.23.2; the ambiguous root prefix `/i`
  is plain `dir` on 7.9.2 vs `obj-inactive` today. 373 corpus files hit an
  `error` (vs 333) — same one-char-then-`none` model throughout.
- **None of the eight reserved classes appeared on 7.9.2 either** — they are
  not "old tokens that disappeared"; they have never been on the highlight
  wire in the REST era. See §8 for where they actually come from.

## 8. The LSP-side vocabulary — 8 reserved classes and where they came from

`server/src/tokens.ts` maps 27 wire classes, but **8 were never observed** in
any capture — not in the 6 legacy snapshots, not in the 913-file sweeps on
7.9.2 / 7.23.2 / 7.24rc2, not in the targeted probes:

```text
ambiguous, path, varname, varname-local, varname-global,
syntax-val, syntax-old, syntax-noterm
```

**Provenance — solved.** The original token list was hand-crafted before any
corpus existed, on the assumption that the console's *display-style*
vocabulary maps 1:1 onto highlight's *token* vocabulary. It doesn't — the
list conflates three related-but-distinct RouterOS vocabularies:

| Vocabulary | Where it lives | Values |
|---|---|---|
| Highlight tokens | `request=highlight` | The 19 classes of §3 — the only ones that appear on this wire. |
| Terminal styles | `/terminal/style` (see §8.1) | `ambiguous, comment, error, escaped, none, syntax-meta, syntax-noterm, syntax-old, syntax-val, varname, varname-global, varname-local` — 12 values, identical on 7.9.2 and 7.23.2. |
| Tree node types | `request=child` (`node-type` field) | `dir, path, cmd, arg` — see the `routeros-command-tree` skill. |

Seven of the eight ghosts (`ambiguous`, `varname*`, `syntax-val`,
`syntax-old`, `syntax-noterm`) are `/terminal/style` values that highlight
never emits; the eighth (`path`) is a `child` node-type that highlight
flattens to `dir`. The two vocabularies genuinely overlap on only five names
(`comment`, `error`, `escaped`, `none`, `syntax-meta`) — enough to make the
1:1 assumption look right until measured.

Keep the eight mapped (harmless), but don't build features that assume they
fire. If one ever appears in a future capture,
`scripts/collect-highlight.ts` flags it automatically.

### 8.1 `/terminal/style` — the display-side cousin

`/terminal/style <value>` switches the console's current output style so that
subsequent printed text renders in that style's color, typically inside a
block:

```routeros
{ /terminal/style error; :put "this renders in the error style"; /terminal/style none }
```

Style names are the console's *rendering* palette — what color each highlight
token class (and other console output) is drawn in — which is why the two
vocabularies share names without being the same set. The styling is realized
as ANSI escapes only on interactive terminals that pass RouterOS's capability
negotiation (it probes with DECID/DSR at login); `/rest/execute` output
carries no styling. Sibling commands under `/terminal` confirm the
terminal-control nature of this subtree: `cuu` (cursor up) and `el` (erase
line) are named directly after the ANSI control functions, plus `ask` and
`inkey` for interactive input. A future pass could map which style each
highlight token class renders with — useful if the LSP ever wants
RouterOS-authentic theme colors — but that is display trivia, not syntax
data.

The LSP folds the wire classes into its semantic-token legend via
`HighlightTokens.toSemanticToken()`: `path`→`dir`; `arg-scope`/`arg-dot`→`arg`
with a modifier; `obj-*`/`syntax-obsolete`/`error`→`syntax-val` with a
modifier; `variable-undefined`→`varname` with a modifier. Range building is run-length
collapse: adjacent identical classes merge into one `{token, range}` span
(`#getHighlightTokenRange`).

## 9. Capture tooling

- `scripts/collect-highlight.ts` — full-corpus sweep + targeted probes against
  a live CHR (`ROUTEROS_TEST_URL`, default `http://127.0.0.1:9170`). Writes
  `test-data/highlight-summary.v<version>.json`: per-class totals, per-file
  type sets, probe run-lengths, unknown-token flags, an exact selected-corpus
  SHA-256, and the device architecture/package manifest. Re-run on each new
  RouterOS release; only diff summaries with the same corpus SHA. All three
  committed summaries are full captures from this harness (environment
  manifest included; the corpus vocabulary numbers reproduced exactly across
  the re-run). `bun run corpus:db` imports their per-file rows into
  `highlight_results`; `v_highlight_by_version` and `v_highlight_drift` provide
  normalized comparisons without reparsing the 16K-line exports.
- `scripts/capture-snapshots.ts` — regenerates the six committed
  `.rsc.highlight` fixtures used by `tests/server/snapshot.test.ts`. These are
  *unversioned* (pre-7.23 capture); if regenerated, adopt the version-tagged
  naming used by parseIL sidecars.
- `scripts/profile-timing.ts` — size→latency sweeps behind the
  `[research: 28kb]` backlog item.

## 10. Open questions

- **The 28 KB latency cliff** — reproduce and characterize
  (`[research: 28kb]`); decide on a `:parse`-first short-circuit.
- **Trim or keep the 8 reserved classes** — provenance is settled (§8:
  terminal styles + a node-type, never highlight tokens), so the legend
  entries could be dropped in a cleanup release; cheap to keep, mildly
  misleading to future readers of `tokens.ts`. Rounding out the analysis with
  a token-class → `/terminal/style` render-color map is optional follow-on.
- **Non-ASCII identifier handling** — a substitute valid in identifier
  position (e.g. `_`) would suppress the 4-in-333 false-error class (§5), but
  would *mask* the fact that RouterOS itself rejects the raw character there —
  a false negative instead of a false positive. Needs a deliberate decision,
  not a drive-by fix.
- **Iterative multi-error highlighting** — re-request from past the error
  position to recover more diagnostics per document; interacts with the 32 KB
  window and per-request cost.
- **RouterOS 7.1–7.8 HTTPS floor capture** — REST began at 7.1beta4, but the
  oldest sweep here is 7.9.2 because the current harness uses plain HTTP by
  default. Capture an early v7 image over `www-ssl` before claiming whole-REST-era
  wire compatibility.
