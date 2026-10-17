# Corpus evidence contract (schema 5)

`test-data/corpus.sqlite` is a reproducible research index, excluded from the
extension package. Raw committed sources and capture manifests are authoritative;
`bun run corpus:db` rebuilds the index. It is not a validity database.

Schema 5 addresses [#37](https://github.com/tikoci/lsp-routeros-ts/issues/37)
and fixes the independent summary aggregation defect in
[#39](https://github.com/tikoci/lsp-routeros-ts/issues/39).

## Retention and capture workflow

Use a disposable CHR, managed by [quickchr](https://github.com/tikoci/quickchr).
Parse capture writes a uniquely named temporary file, verifies its contents,
parses it, and removes it. Corpus scripts are never executed. The upload and
readback limits are acquisition limits, not syntax results.

```sh
quickchr add --name corpus --version 7.24.5 --arch x86 --add-network user
quickchr start corpus --bg --install-all-packages
centrs retrieve --quickchr corpus /system/package --json
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

The committed `test-data/corpus-policy.json` selects exactly one recorded session
pair for each current channel, plus released historical representatives. The
four endpoint responses and their observation timestamps are retained with the
selection; these are dated labels, not a promise that a channel never moves.
Recapture a channel when its version or the source population changes, then
replace its session IDs in the policy. The builder rejects missing pairs,
version/environment mismatches, slices, and stale or incomplete populations.

Provision current-channel CHRs with `--install-all-packages` on their first
boot, and verify the installed, enabled package list before capturing. This
reduces package-availability failures in the script population; a base-only
CHR is a different environment and must not replace these selected sessions.
The environment snapshot remains authoritative about the packages and
device-mode actually present. Optional packages do not supply physical hardware
or prove that every command, parameter, or runtime requirement is available.

Keep one representative per older minor: currently 7.9.2, 7.20.8 and 7.22.1.
Drop prereleases once that minor has a release, and retire legacy runs when a
recorded session covers the same minor. Historical version sidecars can remain
in git for archival research, but only selected evidence enters the DB and its
fingerprint. Remove superseded session manifests after recording any required
bridge result; their original revisions remain accessible in git history.
Pruning evidence never filters or reorders source files. Required-argument
results remain path-oriented archived research; only sidecars from selected
older-minor versions enter those tables, including the 7.9.2 inspect-shapes
representative. A new parse/highlight session does not establish those other
probes’ behavior.

Keep one committed DB, fetched with a plain raw GET. The policy imposes an
80,000,000-byte budget before atomic replacement; prune older representatives
if the artifact approaches that budget rather than introducing another hosting
scheme. Git compresses objects, so raw file size is not an estimate of history
growth; measure compressed artifacts and repository packs separately.

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
hashes. A corrupt retained manifest fails the build rather than silently disappearing.
Unselected archived captures are not indexed.

## Compact database representation

Manifests preserve full original/submitted texts and raw responses. The DB
stores the same evidence without repeated large values:

- `capture_inputs.input_json` keeps each distinct input descriptor once, keyed
  by its hash; observations reference it through `input_id`. This shares the
  same inputs across channel sessions. Its
  `sourceText` is resolved by captured `source_sha256` from `source_scripts`.
  If that hash no longer exists in current sources, `capture_source_history`
  stores the captured text once. Stale and removed sources therefore remain
  reconstructible. `submittedText` is stored only when its bytes differ from
  that captured source. `v_capture_inputs` resolves `source_text` and
  `submitted_text` for either case; unknown legacy inputs remain NULL.
- `response_encoding='parse-ret-v1'` stores the parser readout once in
  `response_text`. `response_json` keeps other response fields; add `ret` back
  to reconstruct the original object.
- `response_encoding='highlight-rle-v1'` stores each `highlight` field as
  run-length `[class, count]` pairs in `response_json`. All other fields are
  preserved. Expand runs and join with commas to reconstruct the raw CSV.
  Empty streams are `[]`; unexpected or oversized responses can use the
  lossless `raw-json-v1` fallback. The manifest always retains the raw reply.
- `analysis_runs.summary_json` retains run-level metadata, not per-file
  `results` or targeted `probes` arrays already available in raw sidecars and
  normalized tables.

The `encodeResponse`/`decodeResponse` helpers in `scripts/corpus-evidence.ts`
define these encodings. Tests roundtrip retained manifests through the compact
DB, including raw replies, source/submitted hashes and stale/missing inputs.
Consumers must read `response_encoding` rather than assuming that every
`response_json` contains a CSV string. For SQL aggregation:

```sql
SELECT json_extract(run.value, '$[0]') AS class,
       SUM(json_extract(run.value, '$[1]')) AS token_count
FROM capture_observations o, json_each(o.response_json, '$[0].highlight') run
WHERE o.run_id = :highlight_run_id AND o.response_encoding = 'highlight-rle-v1'
  AND o.source_path NOT LIKE 'capture-controls/%'
GROUP BY class;
```

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

Never read a diagnostic's `family` or error wording as its cause. On 7.23.x,
command or parameter resolution failures can surface as `expected end of
command` or `syntax error`, while later builds report `bad command name` or
`bad parameter name` for the same input. The
[base-package cross-channel captures](https://github.com/tikoci/lsp-routeros-ts/tree/2b588d1b5aeb45c213db9892aea52daee8037523/test-data/captures)
preserve examples of that difference; they are superseded by the
package-complete sessions below.

## Queries and downstream migration

The old result tables remain imports of policy-selected archival artifacts. New
manifests enter `capture_environments`, `capture_runs`, and
`capture_observations`; use these for new studies. Multiple sessions with the
same firmware coexist. Recorded UUID run IDs remain stable across pruning; generated `legacy:*` IDs
are local to the pinned DB. Firmware alone is never a comparison key. `capture_channels` binds each dated
channel label to explicit parse/highlight run IDs and a shared environment.

The seven challenge scripts have collection `capture-controls`.
`source_scripts` includes all 955 inputs; use `v_corpus_population` for the
948-source study population. `v_capture_outcomes` and
`v_comparable_capture_pairs` exclude controls by default. Run coverage reports
all `observation_count` rows and `control_count` separately; its remaining
population counts exclude controls. Inspect controls directly in
`capture_observations` when testing the classifier. Generated source IDs are
local row references only: path and captured SHA-256 are the portable identity.
Version retention never changes source membership or ordering.

`v_version_coverage` is a **legacy row census**, now labelled `rows-complete` or
`rows-partial`. It can combine runs of the same firmware and includes failures.
It cannot establish input identity, successful acquisition, full-input coverage,
or shared environment. Use `v_capture_run_coverage` to see those axes separately.

```sql
SELECT * FROM capture_channels ORDER BY channel;
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

The archived legacy 7.24.2 partition was 330 plain diagnostics, 84 embedded-diagnostic
responses, 533 IL responses without recognized diagnostics, and one HTTP 413
acquisition failure over 948 rows. Those are recorded response forms with unknown
input provenance, not acceptance counts. Neither the old “618 accepted” bucket
nor 533 is a runtime-validity denominator.

`v_script_summary` now aggregates independently per source, so adding an artifact
or highlight snapshot cannot multiply parse capture counts. Rebuilds are
restricted to tracked public inputs and use capture timestamps, not import time.

## Historical 7.24.2 bridge

Before retiring the recorded 7.24.2 session, the producer rechecked Claude’s
consumer-side result against DB SHA-256
`2acdcf35a40793e11b56e577795e35216f80e91ed1b91a0583d4cf0a9fb62493`
at commit `bafe12fe6d57cac148969f79748763f92ca3cbf2`: joining the 948
legacy source paths to recorded run
`277bdf1f-50c6-46f6-9380-c5a28ec39a59-parseil` gives 947 identical acquired
readouts and one HTTP 413 (`edge-cases/oversize-32k.rsc`), with no differing
acquired readout. The result and method are retained in
[`corpus-bridge.v7.24.2.json`](../test-data/corpus-bridge.v7.24.2.json).
The raw manifests and database remain accessible at that immutable git revision.
Readout agreement does not supply unknown legacy input/environment provenance,
prove syntax acceptance, or establish runtime validity.

Cause attribution remains evidence-qualified follow-up work. In particular, a
missing root menu cannot attribute a nested command failure without matching
scope and controls. The oversize source still has an explicit acquisition
failure; chunked/SFTP upload is a separate transport improvement.

## Dated current-channel snapshot

The selected builds, session IDs and endpoint observation timestamps are in
[`corpus-policy.json`](../test-data/corpus-policy.json). Each pair captures all
955 inputs on a disposable CHR. Population coverage and exact-input pair counts
are queried per channel/run below; response classes remain observations rather
than runtime-acceptance labels.

All packages from each build's x86 `all_packages` archive are installed and
enabled. Including `routeros`, the environments contain 12 packages on
long-term, 13 on stable and testing, and 14 on development. Package versions
match the selected firmware; the development environment additionally includes
CMR. Installed packages and device-mode remain recorded per environment.

| Channel (checked 2026-10-17 UTC) | Build | Session UUID | Population parse acquired | Population highlight acquired | Exact full-input pairs |
| --- | --- | --- | ---: | ---: | ---: |
| long-term | 7.23.8 | `6f313fad-20d3-48f7-b1ac-68906acbd95c` | 947/948 | 948/948 | 834 |
| stable | 7.24.5 | `b4ecf5e8-711e-4e81-aea3-72ccf850240a` | 947/948 | 948/948 | 834 |
| testing | 7.25rc2 | `b5a9755e-fd18-47e4-8756-e9ed39e64a9a` | 947/948 | 948/948 | 834 |
| development | 7.26beta1 | `c4cd2a11-d944-4f5d-80d1-99d4d686ae2a` | 947/948 | 948/948 | 834 |

Each row additionally records seven controls in both probes. All highlight
responses align with their submitted inputs; three source prefixes are truncated.
The oversized source fails parse acquisition with HTTP 413 on all four builds.
The 834 pairs exclude controls, transformed inputs, truncation and failed
acquisition; they include diagnostic responses and are not an acceptance count.
All 955 generated source IDs stayed unchanged when superseded evidence was
pruned, although paths/hashes remain the required portable identity.

Compared with the base-package 7.24.5 session at `2b588d1`, the selected
package-complete session removes the `bad command name` diagnostic for
`wireless`, `caps-man`, `container`, `veth`, `user-manager` or `iot` from 22 of
the 24 affected population sources. Two historical snippets using
`/tool user-manager` retain that diagnostic with the package enabled. Other
diagnostics can remain or become visible; these counts are not syntax or
runtime acceptance counts.

For centrs's reviewed 7.24.2 70-script highlight slice, submitted inputs still match
exactly, but 11 streams change in the package-complete 7.24.5 environment
(59 remain identical). The consumer migration must regenerate those expected
streams, rather than only changing the fixture's version label.

The compact index is 36,286,464 bytes (34.61 MiB), versus 52,760,576 bytes
(50.32 MiB) for the prior single-session-pair index. It contains 1,910 shared
input descriptors for 7,640 recorded observations. Gzip size measured with
zeroed timestamp is 4,682,883 bytes; git pack growth depends on its own delta
compression. The plain committed SQLite file remains the distribution artifact.
