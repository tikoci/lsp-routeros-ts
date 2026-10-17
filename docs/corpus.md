# Corpus evidence contract (schema 5)

`test-data/corpus.sqlite` is a reproducible research index, excluded from the
extension package. Raw committed sources and capture manifests are authoritative;
`bun run corpus:db` rebuilds the index. It is not a validity database.

Schema 5 addresses [#37](https://github.com/tikoci/lsp-routeros-ts/issues/37)
and fixes the independent summary aggregation defect in
[#39](https://github.com/tikoci/lsp-routeros-ts/issues/39).

## Capture and storage

Use a disposable CHR, managed by [quickchr](https://github.com/tikoci/quickchr).
Parse capture writes a uniquely named temporary file, verifies its contents,
parses it, and removes it. Corpus scripts are never executed. The upload and
readback limits are acquisition limits, not syntax results.

```sh
quickchr add --name corpus --version 7.24.2 --arch x86 --add-network user
quickchr start corpus --bg
# Use the REST endpoint printed by quickchr (the port below is an example).
ROUTEROS_TEST_URL=http://127.0.0.1:9170 bun run corpus:capture \
  --menus 'ip,address;container;zerotier'
git add test-data/captures test-data/capture-controls
bun run corpus:db
quickchr stop corpus
quickchr remove corpus
```

Choose the maintained version for each release channel at capture time; the
example version is a reproducible historical baseline, not a claim about the
current channel. Do not overwrite historical captures or recapture EOL builds
just to fill a coverage grid. `--target <substring>` and `--limit <count>` select
explicit slices. Only git-tracked `.rsc` files enter a capture or rebuild: stage
new public fixtures first. Do not stage private inputs.

`corpus:capture` freezes the selected source texts and runs parseIL and highlight
against the same target in one session. The existing `collect-parseil.ts` and
`collect-highlight.ts` commands still work for individual investigations, but
separate invocations have separate environment identities and do not pair.
`collect-inspect-shapes.ts` and `collect-required-args.ts` remain separate legacy
research tools; the latter executes commands and needs its own safe disposable
lab. Neither supplies missing provenance for a parse/highlight capture.

New output is `test-data/captures/<session-uuid>-<probe>.json`, written with
exclusive creation. It does not replace the old version-named sidecars or
summaries. Raw highlight streams are now retained, rather than only vocabulary
summaries; vocabulary is queryable from `highlight_json.types` and raw streams.
Historical targeted probe results remain in their original highlight summaries.
The checked-in `capture-controls/` sources exercise operators, plain/embedded
diagnostics, literal quotes, and echoed diagnostic-looking strings.

Each format-1 manifest records:

- A run ID, probe, timestamp, selected source-set fingerprint, and selection.
- An immutable environment snapshot and hash: firmware/build, architecture,
  board, installed/disabled packages, device-mode response (or explicit unknown),
  and a menu inventory with its own hash. Inventory paths are comma-separated
  inspect paths; `--menus` separates multiple paths with semicolons. The root is
  always inventoried. Inventory scope is explicit; a root listing cannot prove
  absence of a nested command. An error is retained separately from `[]`.
- A capture-session identity shared only by the two probes in that invocation.
  Mutable object state and global variables are explicitly unrecorded. Run in a
  dedicated lab without concurrent changes. The snapshot establishes recorded
  parse/highlight context, not complete runtime/configuration equivalence.
- Every original source text/hash and the exact submitted text/hash, variant,
  versioned transformation, UTF-8 byte and UTF-16 code-unit lengths, submitted
  source span, truncation and replacement counts, and root-menu context.
- Acquisition status, submission/readback status, raw response, raw error,
  timing, and highlight alignment/first-hard-error position.

Inputs and environment hashes are checked during import. Captured source hashes
are compared with current `source_scripts.sha256`: `matched`, `stale`, or
`source-missing`. Equal-length edits are stale too. Historical captures have
`input_status='unknown'`; current sources cannot establish historical submitted
hashes. A corrupt manifest fails the build rather than silently disappearing.

## Coordinates and transformations

Parse capture uploads the original UTF-8 text and verifies readback before
`:parse`. Device line/column values remain verbatim, with an **unverified unit**;
do not silently reinterpret them as editor UTF-16 offsets. Diagnostic response
spans use zero-based, half-open UTF-16 offsets in the raw response.

Highlight mirrors the LSP's existing transformation: take the first 32,767
UTF-16 code units, then replace each non-ASCII code unit with `?`. An astral
character becomes two question marks. The result is ASCII: submitted byte `i`
maps to source UTF-16 code unit `i` in the submitted prefix. To recover its
source UTF-8 byte offset, measure `sourceText.slice(0,i)` in UTF-8. No mapping
claims coverage of the unsubmitted suffix. Token count/alignment and the first
hard-error byte are stored independently; aligned `none` tokens after an error
are not evidence that the suffix was checked.

## Outcomes and causes

`ok` in the legacy tables means acquisition succeeded. A device diagnostic can
be successfully acquired. New `capture_observations` expose acquisition and
response class separately, using the versioned `parse-response-v1` classifier:

| Response class | Meaning |
| --- | --- |
| `capture-failed` / `missing-response` | No usable parser response; exclude from parser denominators. |
| `plain-diagnostic` | Recognized leading diagnostic with device line/column. |
| `embedded-diagnostic` | Recognized diagnostic node structure within IL. |
| `il-no-recognized-diagnostic` | IL-shaped response without a recognized diagnostic; **no runtime validity claim**. |
| `ambiguous-diagnostic` | Node-shaped text at a literal/value boundary; cannot safely classify as a diagnostic. |
| `unknown-response` | Unrecognized response; preserve and investigate. |

Highlight has separate classes: `highlight-error`, `highlight-no-hard-error`,
`highlight-misaligned`, `capture-failed`; legacy summaries use `summary-only`.
None proves runtime acceptance. `highlight-no-hard-error` says nothing about
unsubmitted text or value validity.

The classifier matches diagnostic structure and coordinates, not the `<%%`
operator alone or arbitrary occurrences of “bad parameter.” IL can emit strings
without escaping quotes or node-looking text. Ambiguous literal boundaries stay
ambiguous; this is a conservative response classifier, not a complete IL parser.
Keep the operator, echoed-message and literal-quote controls when changing it.
Unknown future diagnostic forms must not silently become accepted inputs.

`diagnostics_json` keeps messages, raw positions and message families. These
families describe wording, not root cause. `cause_attributions` can hold multiple
annotations (`syntax`, `unavailable-menu-or-command`, `parameter-name`, `unknown`,
`mixed`), each with scope and evidence. It is initially empty: unannotated means
unknown. Durable annotations belong in the observation manifest’s optional
`causes` array (`cause`, `scope`, `evidence`) so rebuilds retain them. An unavailable menu requires attributable inventory/control evidence;
an offline catalog miss is insufficient. Removing a menu-related first failure
does not establish the rest of a script as valid. Minimize and capture controls
before turning a whole-script observation into a language rule.

## Queries and downstream migration

The old result tables remain archival imports of version-named artifacts. New
manifests enter `capture_environments`, `capture_runs`, and
`capture_observations`; use these for new studies. Multiple sessions with the
same firmware coexist. Firmware alone is never a comparison key.

`v_version_coverage` is a **legacy row census**, now labelled `rows-complete` or
`rows-partial`. It can combine runs of the same firmware and includes failures.
It cannot establish input identity, successful acquisition, full-input coverage,
or shared environment. Use `v_capture_run_coverage` to see those axes separately.

```sql
SELECT * FROM v_capture_run_coverage ORDER BY run_id;

-- One response partition for a selected run, including failures and exclusions.
SELECT * FROM v_capture_outcomes WHERE run_id = :run_id;

-- Matched full-source ASCII inputs in the same recorded capture session.
SELECT * FROM v_comparable_capture_pairs
WHERE parse_run_id = :parse_run_id AND highlight_run_id = :highlight_run_id;
```

The pair view requires current source hashes, identical submitted hashes and
root context, successful acquisition, full submitted spans and aligned
highlight. Transformed non-ASCII and truncated sources are excluded even when
both rows exist. Filter explicit run IDs: multiple sessions must not multiply a
study's denominator. Comparable pairs still include diagnostic responses; the
view is not an acceptance set. Inspect both response classes and raw evidence.

For a published result, pin the repository revision **and SHA-256 of the DB**,
schema/classifier versions, explicit run/environment IDs, source/input variants,
collection/genre selection, denominator and every exclusion. Report acquisition,
response forms and evidence-qualified causes separately. Do not publish a
blended “syntax recall” score from device-availability and genre failures.
Downstream consumers such as centrs must deliberately update their DB pin and
queries; replacing only the checksum is insufficient. Script row IDs can shift
when sources are added; identify sources by path and hash, not a historical row ID.

The legacy 7.24.2 partition is 330 plain diagnostics, 84 embedded-diagnostic
responses, 533 IL responses without recognized diagnostics, and one HTTP 413
acquisition failure over 948 rows. Those are recorded response forms with unknown
input provenance, not acceptance counts. Neither the old “618 accepted” bucket
nor 533 is a runtime-validity denominator.

`v_script_summary` now aggregates independently per source, so adding an artifact
or highlight snapshot cannot multiply parse capture counts. Rebuilds are
restricted to tracked public inputs and use capture timestamps, not import time.

## Checked-in schema-5 baseline

Session `277bdf1f-50c6-46f6-9380-c5a28ec39a59` captured RouterOS 7.24.2
against all 955 tracked sources (948 archival sources plus seven new controls).
Both runs share environment hash
`8a376a72151bdd8a2c422af33543a731549c99179044bf66f16e13805b3d93ef`.
Parse acquisition succeeded for 954 sources; the 126 KiB upload failed with
HTTP 413. All 955 highlight responses aligned with their submitted inputs;
three inputs were truncated. The pair view contains 841 exact full-input pairs,
with non-ASCII transformations/truncation/failure excluded. This is a comparison
set, not a count of accepted scripts. Inspect raw highlight through
`json_extract(response_json, '$[0].highlight')`; `response_text` holds parse
readouts without duplicating the large highlight stream.

The parse response partition for the new 955-source run is 331 plain
diagnostics, 87 embedded-diagnostic responses, 535 IL responses without recognized
diagnostics, one ambiguous echoed node, and one failed acquisition. Root-cause
annotations remain unknown. These are a frozen baseline, not channel-current
results or evidence that runtime execution succeeded.
