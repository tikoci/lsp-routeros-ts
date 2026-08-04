# tangentsoft MikroTik defconf archive

Scripts in this directory were imported from the "MikroTik Solutions" Fossil
repository's default-configuration archive:

https://tangentsoft.com/mikrotik/dir?name=defconf

Thanks to [@tangent](https://tangentsoft.com/mikrotik) for maintaining and sharing this archive, and
for confirming redistribution here directly.

These are genuine `/export show-sensitive terse` captures from 35
real devices spanning RouterOS 7.1-7.19. MACs, serial numbers, timezone, and
country-code settings are already redacted by the maintainer before
publishing (see the archive's own README for the exact redaction policy).
`_common.rsc` (a scripted `/system/default-configuration print` template,
not a flat export) and the `tools/` capture scripts are intentionally
excluded — different genre, out of scope for this collection.

Imported with:
`bun run scripts/import-tangentsoft-defconf.ts --out-dir test-data/tangentsoft`
