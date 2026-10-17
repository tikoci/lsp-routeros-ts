# WireSage conformance inputs

875 synthetic grammar cases imported from
[`wiresage/routeros-lsp`, `tests/conformance/cases.json`](https://github.com/wiresage/routeros-lsp/blob/a3a646fa3e7fb07f3a2733405cfb84f75871f7bb/tests/conformance/cases.json)
at revision `a3a646fa3e7fb07f3a2733405cfb84f75871f7bb`. Only case data is
imported; no upstream code or schema data is included. The upstream MIT
license is reproduced byte-exactly in [LICENSE](LICENSE).

Regenerate the pinned import from the repository root:

```sh
bun run corpus:import:wiresage
git add test-data/wiresage-conformance
```

The importer checks pinned SHA-256 digests for both upstream files before
writing. [upstream-cases.json](upstream-cases.json) retains the original JSON
bytes, including all section/note/diagnostic metadata. Each `.rsc` contains
the UTF-8 bytes of exactly one `source` value: no comments, newline, trimming,
or BOM removal. Git line-ending conversion is disabled for this collection.
The collection is identified by `path` plus source SHA-256, like other inputs.
Regeneration refuses unrecognized `.rsc` files instead of deleting derived
research.

Upstream IDs are not globally unique: 31 IDs are reused, giving 844 distinct
IDs across 875 cases. Files therefore use `<section-slug>/<id>.rsc`.
[manifest.json](manifest.json) maps each path to the original section, ID,
zero-based upstream row index, source hash/byte count, and `upstreamValid`.
Section plus ID is unique at this revision. For example, `d12` exists in both
`forms-outside-strings/` and `what-makes-set-legal/`. Derived or minimized
variants must use separate names and preserve the original cases.

`upstreamValid` is a **third-party observation** reported for RouterOS 7.21.4
using `/import ... verbose=yes dry-run`. That context compiles per line and
is distinct from whole-script `:parse` and plain import. These labels are not
our oracle and do not establish current syntax or runtime acceptance. Raw
parse/highlight captures from this repository retain their own inputs,
transformations, environment identities and response classifications. No
import execution probe is included. See the [corpus contract](../../docs/corpus.md)
and [centrs#507](https://github.com/tikoci/centrs/issues/507).

This auxiliary collection is excluded from `v_corpus_population` and the
default outcome/comparison views. The existing study remains 948 scripts.
Use `third_party_cases`, `v_collection_capture_coverage` and
`v_collection_comparable_capture_pairs` to opt into this collection by name,
with explicit channel/run IDs. Seven `capture-controls` inputs remain a
separate collection. See [#41](https://github.com/tikoci/lsp-routeros-ts/issues/41).
