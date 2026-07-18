# RouterOS syntax inspection — probe selection map

> A compact decision layer over this repository's research. Use this before
> choosing a live RouterOS probe or an offline parser. The detailed wire-format
> references remain the source of truth; this page is the extraction boundary
> for a future `routeros-syntax-inspection` skill and for consumers such as a
> future centrs `explain` command.

## 1. Do not treat “parse RouterOS” as one operation

RouterOS tooling answers several different questions that happen to look like
syntax parsing:

| Question | Primary source | What it cannot establish |
|---|---|---|
| Which source span is a command, argument, variable, comment, or live-state marker? | Live `/console/inspect` `request=highlight` | Nested structure, value validity, required arguments, or errors after the first hard stop. |
| Is the whole script structurally valid, and what blocks/expressions did RouterOS build? | Live `:parse` IL | Source ranges, partial IL on error, required arguments, or an unambiguous path/argument split without command-schema data. |
| What is valid at this cursor or synthetic input boundary? | Live `/console/inspect` `request=completion` | Requiredness; all arguments currently have equivalent completion priority. Synthetic space/`=` tricks remain research, not a stable contract. |
| What paths, commands, and arguments exist on this device? | Live `/console/inspect` `request=child`; `request=syntax` for terse descriptions | Runtime preconditions, required arguments, rich documentation, historical availability. |
| Which arguments are required by an `add` command? | Versioned execute-error probe | Conditional requirements beyond the first discriminator and menus with custom/erroring behavior. This probe can mutate state unless its add/remove wrapper is proven safe. |
| Where are RouterOS CLI paths in arbitrary text or a static `.rsc` file? | `@tikoci/canonicalize-routeros` / rosetta canonicalization | Semantic validity or live device state. This is tolerant segmentation and path normalization, not RouterOS's parser. |
| What does a path/property mean, when did it change, and what REST surface maps to it? | rosetta/restraml snapshots plus docs/changelog data | Exact behavior of a differently versioned or differently packaged live device. |

The key design rule is to preserve these provenance boundaries. A merged
“explanation” may combine them, but must not present a static inference as a
live parser fact or a device-specific result as universal RouterOS grammar.

## 2. Minimum live explanation pipeline

For a target-aware syntax explanation, use the smallest probes that answer the
requested question:

1. **Segment input without executing it.** Use the static canonicalizer to find
   likely RouterOS paths and command boundaries in prose or source. Preserve the
   original offsets; treat malformed-input recovery as heuristic.
2. **Ask the target for lexical spans.** Send ASCII-normalized input to
   `request=highlight`. Keep the RouterOS version, package manifest, current
   menu `path`, and truncation state with the result.
3. **Ask `:parse` only when structure or a parser message is needed.** For valid
   input it supplies nested IL; for invalid input it supplies the first-error
   message and line/column. Align that error with highlight's exact error byte
   when possible.
4. **Resolve the command schema.** Use `child`/`syntax` or a same-version
   restraml snapshot to split parseIL's fused path/argument forms and to
   enumerate commands and arguments.
5. **Enrich, do not override.** Add rosetta prose, URLs, changelog history, and
   static CLI-to-REST mapping. When live schema and a static snapshot disagree,
   the target wins for existence and accepted values; static sources win only
   for the prose/history they uniquely provide.
6. **Run execution probes only on explicit request and an appropriate target.**
   `:parse`, highlight, completion, child, and syntax are inspection surfaces.
   Required-argument discovery and arbitrary `/rest/execute` calls cross into
   runtime behavior and need the caller's mutation policy.

This pipeline is deliberately additive. A lightweight `explain` can stop after
steps 1–2; block/scope analysis needs step 3; rich command help needs steps 4–5.

## 3. Result contract for agents and tools

Every derived fact should retain enough metadata to answer “how do we know?”:

```typescript
interface RouterOsSyntaxEvidence {
	source: 'highlight' | 'parseil' | 'completion' | 'child' | 'syntax' | 'execute-error' | 'static-schema' | 'docs'
	claim: string
	confidence: 'live' | 'versioned-snapshot' | 'heuristic'
	routerosVersion?: string
	architecture?: string
	packages?: Array<{ name: string; version: string }>
	pathContext?: string
	inputSha256?: string
	corpusSha256?: string
	truncated?: boolean
}
```

Do not collapse these distinctions:

- `none` means unclassified, not “valid literal.” Highlight accepts obviously
  bad values such as an invalid IP as `none`; runtime or schema-aware validation
  is a separate layer.
- `obj-inactive`, `obj-disabled`, and `obj-dynamic` are live-state/schema
  classifications, not grammar productions. Their diagnostic severity is a
  product decision.
- `$undeclared` commonly becomes `variable-parameter`, not an error, because it
  may be supplied at function invocation. `variable-undefined` is a different
  bare-expression signal.
- Both highlight and `:parse` stop analysis at the first hard error. Highlight
  retains exact spans and soft markers before that point; `:parse` retains an
  error message but no partial IL.
- The 32,767-byte highlight window and JavaScript source offsets align only
  after one-byte ASCII substitution. Record truncation rather than implying the
  unchecked tail passed.

## 4. Current evidence and remaining gates

| Surface | Grounded reference | Status |
|---|---|---|
| Highlight wire classes, byte alignment, hard-error behavior, statefulness | [`highlight-format.md`](highlight-format.md) | Full-corpus captures on 7.9.2, 7.23.2, and 7.24rc2. Early HTTPS-only v7 remains untested. |
| `:parse` IL grammar, structure, errors, and drift | [`parseil-format.md`](parseil-format.md) | Full-corpus captures on 7.20.8, 7.22.1, and 7.23rc1. |
| Required arguments | [`required-args.md`](required-args.md) | Versioned execute-error dataset with explicit unresolved cases. |
| Live versus rosetta ownership | [`rosetta-alignment.md`](rosetta-alignment.md) | Decision matrix and join rules exist. |
| Static path slicing/canonicalization | [`canonicalize-audit.md`](canonicalize-audit.md) | Reusable package exists; deep block/scope parsing is not solved by it. |
| `completion`, `syntax`, and `child` response shapes | [`BACKLOG.md`](../BACKLOG.md) `[research: inspect-shapes]` | Still a blocker. Capture representative cursor/path contexts before promising a stable generic schema. |
| Synthetic trailing-space / trailing-`=` completion probes | [`BACKLOG.md`](../BACKLOG.md) `[research: completion-tricks]` | Still a blocker. Do not encode as a skill recipe yet. |
| CLI-to-REST/API conversion | rosetta/restraml command schema | Keep separate from source parsing; validate mappings per command family and version. |

## 5. Skill extraction boundary

A future public skill should copy the decision rules and compact request/result
contracts, then link to or adapt the format references. It should not copy this
LSP's controller/model architecture or private cross-project plans.

Suggested package:

```text
routeros-syntax-inspection/
  SKILL.md                         # selection matrix, safety, provenance rules
  references/highlight.md          # compact form of highlight-format.md
  references/parseil.md            # compact form of parseil-format.md
  references/command-schema.md     # child/syntax/completion after research lands
  references/validation.md         # required-args and live/static layering
```

The skill is ready to draft from the first two references now, but it should
label `inspect-shapes`, `completion-tricks`, early-v7 highlight compatibility,
and CLI-to-REST conversion as open evidence rather than filling those gaps with
inference.
