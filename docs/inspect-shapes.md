# RouterOS `/console/inspect` — completion, syntax, child response shapes

> Reference for the three non-highlight request types of `/console/inspect`,
> grounded on a curated 37-context probe catalog captured verbatim against CHR
> **7.23.2** (stable), **7.24rc2** (testing), and **7.9.2** (plain-HTTP floor).
> Artifacts: `test-data/inspect-shapes.v<version>.json` from
> `scripts/collect-inspect-shapes.ts`. This lands the `completion`/`syntax`/
> `child` share of `[research: inspect-shapes]`; the corpus-position sweep and
> the synthetic-probe rules (`[research: completion-tricks]`) remain open.
>
> Companions: [`highlight-format.md`](highlight-format.md) for
> `request=highlight`; the `routeros-command-tree` skill for tree-walking
> recipes built on `child`/`syntax`.

## 1. Shared request contract

```text
POST /rest/console/inspect
{"request": "completion" | "syntax" | "child" | "highlight",
 "input": "<console input>",     // optional
 "path":  "ip,address,add"}      // optional, comma-separated context
```

Every successful response observed here is a JSON array of flat objects whose
values are all strings, and every item carries a `type` field naming its
request type. An empty array and a timeout are materially different results;
preserve transport status and timing alongside the array. Beyond that the
three shapes share nothing — treat them as three different APIs behind one
endpoint.

| Request | Item fields (observed) | Items per response |
|---|---|---|
| `child` | `name`, `node-type`, `type` | 0…79 (root) |
| `syntax` | `symbol`, `symbol-type`, `text`, `nested`, `nonorm`, `type` | 0…78 |
| `completion` | `completion`, `offset`, `preference`, `show`, `style`, `text`, `type` | 0…86 |

## 2. `request=child` — node enumeration

Items are `{name, node-type: "dir"|"path"|"cmd"|"arg", type: "self"|"child"}`.

- **`type:"self"` describes the addressed node itself**; `type:"child"` rows
  are its children. A leaf `arg` returns just its own `self` row. A name that
  is *both* a command and an argument returns two rows — `/terminal/style`
  yields `{name:"style", node-type:"cmd", type:"self"}` **and**
  `{name:"style", node-type:"arg", type:"child"}`.
- Root (`path:""`) lists every top-level menu and scripting command
  (79 entries on 7.23.2).
- **A nonexistent path returns an empty array, not an error** — absence is the
  only "not found" signal.
- **`input` is ignored**: `{path:"ip", input:"add"}` returns byte-identical
  results to `{path:"ip"}`. Filtering is the caller's job.

This is the surface `restraml`'s tree walker and the `routeros-command-tree`
skill are built on; see that skill for traversal recipes. Treat its
"dangerous paths" list as a conservative crawler skip policy, not a timeless
six-path crash invariant: newer restraml live research isolated the confirmed
deadlock to bare `path:"do"` with `syntax`/`completion` on 7.20.8 and found it
fixed by 7.21.4. Use per-request timeouts on old or unknown versions.

## 3. `request=syntax` — structured help, not just a description string

The commonly documented shape `[{type:"syntax", text:"IP address"}]` is a
special case. The full item is:

```json
{"symbol": "Address", "symbol-type": "definition", "text": "A.B.C.D    (IP address)",
 "nested": "0", "nonorm": "false", "type": "syntax"}
```

- **`symbol-type` is the discriminator** — observed values:
  - `definition` — the addressed node's own entry. For a value-typed `arg`,
    `text` carries the **value-type notation** (`A.B.C.D    (IP address)` for
    `/ip/address/add address`) — the closest thing the API has to a type
    grammar. For enum-valued args (e.g. `…filter/add action`) the definition
    is *empty*: enums live in `completion`, not `syntax` (§4).
  - `explanation` — one row per member when the addressed node is a
    container: querying a **cmd** returns a `collection` row plus an
    `explanation` row for *every argument* (`symbol` = arg name, `text` = its
    description; positional script params render as `<message>`).
  - `collection` — the container row itself (`nested:"0"`, empty
    symbol/text).
- **`nested` behaves like row depth** in the captured responses (`"0"`
  container, `"1"` members). Deeper values were not exercised, so retain the
  raw field rather than promising a general tree-depth contract.
- `nonorm` — observed `"true"` on `collection` rows and `"false"` elsewhere;
  meaning unconfirmed. Record it, don't interpret it.
- On 7.23.2 and 7.24rc2, one `syntax` call on a *cmd* returned all of its args'
  descriptions at once — potentially N× cheaper than the per-arg lookups
  `restraml`'s walker does today. **Do not use that as an unconditional fast
  path:** on 7.9.2 the same command-level lookup stalled for about 60 seconds
  and returned no usable result (one run timed out; another returned `[]`).
  Feature-detect it with a short timeout and fall back to per-arg lookups.
  **Safety is also version-sensitive for scripting-keyword paths.** The
  long-standing conservative skip set is `where`, `do`, `else`, `rule`,
  `command`, `on-error`, but current restraml evidence confirms the deadlock
  specifically for bare `do` with `syntax`/`completion` on 7.20.8 and confirms
  it fixed by 7.21.4. This catalog did not re-probe that matrix. Keep a timeout
  and skip/fallback policy for old or unknown targets rather than claiming all
  six paths always crash.
- **Do not combine `input` with `syntax`.** On 7.23.2/7.24rc2 it changes the
  response to a lone empty `definition` row (semantics unclear); on **7.9.2
  the request hangs until timeout** (60 s in the capture, with knock-on
  slowness on other REST calls while it was stuck). Query `syntax` by `path`
  only.

## 4. `request=completion` — candidates, enums, and a validity signal

Each item proposes text that could continue (or repair) the input:

| Field | Meaning (observed) |
|---|---|
| `completion` | The candidate text. Empty string on sentinel rows (see below). |
| `offset` | **Byte offset into `input`, as received on the wire, where replacement begins.** RouterOS strings are single-byte data — the console has no Unicode awareness — so it counts the raw bytes the REST transport delivered (JSON is UTF-8 on the wire, so a non-ASCII character occupies 2+ bytes). End-of-input offset means "append"; a smaller offset replaces the partial word — `/ip/ad` (6 ASCII bytes) offers `address` at `offset:4`. A targeted `é` probe returned offsets one greater than JavaScript UTF-16 indexes, matching UTF-8 byte counts. Same model as highlight's per-byte tokens (`highlight-format.md` §1/§5): ASCII-normalize (the LSP's one-byte `?` substitution) before mapping offsets into JS/LSP positions. |
| `preference` | An observed ranking weight, not a documented stable enum. Typical captures: `96` names (with exceptions), `95` separators (`/`, `=`), `80`/`64` whitespace, `75` expression openers (`[`, `(`, `$`, `"`), `40` statement glue (`{`, `;`), `-1` hidden whitespace/id-prefix/`<value>` placeholders, `-10` obsolete-syntax markers, `-20` unknown-name sentinels. Preserve it for ordering; do not assign semantics from the number alone. |
| `show` | `"true"` = display as a candidate; `"false"` = machine-facing row not meant for the candidate menu (syntactic connectives, placeholders, and sentinels). It does not mean the row is valid. |
| `style` | **Highlight-vocabulary classification associated with the candidate** — `dir`, `cmd`, `arg`, `none`, `syntax-meta`, `variable-local`, `variable-global`, `variable-auto`, `obj-inactive` observed. A third surface sharing the highlight vocabulary (with `/terminal/style`'s display palette; see `highlight-format.md` §8). |
| `text` | Human description (menu blurb, arg description, or the sentinel's reason). |

Grounded uses:

- **Enum-candidate discovery.** `input:"/ip/firewall/filter/add action="`
  returns an enum-looking candidate set (`accept`, `drop`, `jump`, …) as
  `show:"true"` rows. This
  is what `restraml` enriches `deep-inspect.json` with, and the only API
  source observed here for enum values (`syntax` returns nothing for them).
  Completion is a suggestion surface, however; the captures do not prove that
  every returned set is exhaustive. Preserve an `observed-candidates`
  provenance unless runtime or independent schema evidence proves closure.
- **Live-object values.** `interface=` completions list the device's actual
  interfaces (`ether1`, `lo`) — stateful, like highlight's `obj-*` classes.
- **`where`-clause fields** complete with `style:"variable-local"` —
  consistent with highlight classifying filter fields as `variable-local` and
  parseIL's `findwhere=$field` dump. Three independent surfaces, one model.
- **Declared variables** complete after `$` with their scope class
  (`variable-global` etc.) when declared earlier in the same `input`.
- **Generic value-position grammar.** After an argument-like word followed by
  `=` — even an unknown argument — the response can contain a placeholder row:
  `completion:"<value>"`, `preference:"-1"`, with `text` describing the
  generic literal character grammar ("literal value that consists only of digits,
  letters and characters `-.,:<>/|+_*&^%#@!~`"). A cursor-position value-type
  hint, distinct from `syntax`'s definition text and not proof that the
  preceding argument or a particular value is valid.
- **Unknown-name sentinels — read them only for the word at the probe
  cursor.** Rows with
  empty `completion`, `preference:"-20"`, `style:"obj-inactive"`, and
  `text:"unknown command"`/`"unknown parameter"` classify **the word starting
  at `offset`**, and they also appear *prospectively* at the empty
  end-of-input position of perfectly valid commands — presence alone is not
  an error verdict. Probe with the cursor immediately after the word, before
  `=`, whitespace, or another token: once the input advances, completion may
  describe only the new position and forget the earlier invalid word. The
  measured decision rule for "is this current typed word valid" on 7.23.2+
  is:
  - sentinel at the word's offset **and** no `show:"true"` candidate
    completing it → unknown name (`bogusarg` case);
  - sentinel **plus** candidates at the same offset → ambiguous prefix
    (`/i` → `if`/`import`/`interface`/`ip`/`ipv6` all at `offset:1`, plus an
    `unknown command` sentinel);
  - candidates only → valid partial;
  - sentinel at end-of-input (offset ≥ the last word start, empty word) →
    prospective, ignore.
  An unresolvable *path* (`/foo/bar`) instead returns an **empty array** —
  same absence signal as `child`. This is the grounded mechanics behind
  "use `request=completion` to validate before executing"
  (`tikoci-crossref`). Two caveats: on **7.9.2 an unknown command still has a
  sentinel, but an unknown typed argument returns `[]`**
  (`/ip/address/add bogusarg`), so the argument rule must be
  version/feature-detected — and the inspect-vs-runtime gap still applies:
  passing this check is necessary, not sufficient
  (`bench-routeros-tools`' `blackhole=yes` case).
- **Obsolete-syntax advertisement.** A partial arg word can carry a
  `completion:" "`, `preference:"-10"`, `style:"syntax-obsolete"`,
  `text:"old syntax"` row — the completion-side twin of highlight's
  `syntax-obsolete` marker for space-separated legacy forms.

## 5. Cross-version notes

Shapes were captured on 7.9.2, 7.23.2, and 7.24rc2. Field sets are identical
across all three (verified per-request-type from the artifacts); item counts
differ with the command tree (menus added/removed), and candidate/enum
contents are version- and state-specific by design. Several behavioral
differences surfaced: command-level `syntax` and `syntax`+`input` can each
stall for about 60 seconds on 7.9.2 (§3), and unknown-argument sentinels differ
(§4). As with highlight, the observed *fields* are stable while content and
behavior remain version- and device-specific. Diff artifacts only when their
`probeSha256` and `requestTimeoutMs` match; each artifact also records
architecture, board, and installed-package manifest.

## 6. Open questions

- **`[research: completion-tricks]`** — synthetic trailing space / `=` probes
  (LSP-side input surgery to expose arg/value completions mid-document) are
  deliberately *not* covered here; the API calls are ordinary, but the rules
  for when synthetic input changes or breaks results are unmeasured.
- **Corpus-position sweep** — this catalog is curated contexts, not the
  representative corpus-position capture the BACKLOG item envisions for
  `inspect_responses` in `corpus.sqlite`.
- **`nonorm` semantics**, **`syntax`+`input` semantics**, and the exact
  version boundary/scope of scripting-keyword hangs — all
  observed-but-unexplained or maintained in restraml's separate live matrix;
  flagged inline above.
