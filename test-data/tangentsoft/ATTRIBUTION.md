# tangentsoft MikroTik defconf archive

Scripts in this directory were imported from the "MikroTik Solutions" Fossil
repository's default-configuration archive:

https://tangentsoft.com/mikrotik/dir?name=defconf

Thanks to [@tangent](https://tangentsoft.com/mikrotik) for maintaining and sharing this archive, and
for confirming redistribution here directly.

These are 35 genuine `/export show-sensitive terse` device
captures spanning RouterOS 7.15.2-7.18.2. That range is read from each
file's own export banner (35 of 35 carry one),
not asserted — the upstream README's "7.1 through 7.19" describes the
`_common.rsc` version history, which is not imported here.

MACs, serial numbers, timezone, and country-code settings are already redacted
by the maintainer before publishing (see the archive's own README for the exact
redaction policy) — this is **not** a controlled synthetic-canary fixture. The
maintainer also hand-derives some variants from a capture (the
`-router`/`-switch` pairs), so treat the collection as "a device emitted
this, then a human edited it", not as raw device output.

`_common.rsc` (a scripted `/system/default-configuration print` template,
not a flat export) and the `tools/` capture scripts are intentionally
excluded — different genre, out of scope for this collection.

`manifest.json` pins the upstream Fossil check-in and a SHA-256 per file;
re-running the importer with `--checkin <uuid>` reproduces this directory
byte for byte.

Imported with:
`bun run scripts/import-tangentsoft-defconf.ts --out-dir test-data/tangentsoft`
