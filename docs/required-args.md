# RouterOS required arguments — execute-time probe

> Reference for the `[research: required-args]` spike. Artifacts live in
> `test-data/required-args.v<version>.json` and
> `test-data/required-args.v<version>.meta.json`; normalized rows are imported
> into `test-data/corpus.sqlite` as `required_arg_results`.

## 1. Method

The probe walks every menu path in `restraml/docs/<version>/deep-inspect.json`
that exposes an `add` command, then executes this script against a live CHR:

```routeros
:local id [/some/menu add]; :put $id; /some/menu remove $id
```

Why this shape:

- If `add` is missing required args, RouterOS aborts before the `remove`.
- If `add` succeeds with no required args, the created row is immediately
  removed, so the probe does not pollute later menus.
- The returned `ret` string is enough to classify the path.

Captured versions:

| RouterOS | Add-capable paths | Required paths | No required args | Exact `missing value(s)` | Custom required text | Other probe errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 7.20.8 | 230 | 166 | 52 | 146 | 20 | 12 |
| 7.22.1 | 233 | 169 | 53 | 149 | 20 | 11 |
| 7.23rc1 | 234 | 170 | 54 | 149 | 21 | 10 |

The exact-pattern case is the high-confidence core:

```text
Script Error: missing value(s) of argument(s) <arg1> <arg2> …
```

Custom messages still expose useful structure, but the `required[]` list is a
set of **candidate args extracted from the human text**, not a stronger signal
than the raw message. Examples:

- `/interface/wifi` → `must specify exactly one of radio-mac, master-interface or mld-name`
- `/ip/hotspot/ip-binding` → `address or mac-address is required`
- `/routing/bgp/vpls` → `must set either site-id or cisco-id`

For those cases, `rawError` remains the source of truth for the exact rule.

## 2. Artifact format

`required-args.v<version>.json` is the stable reviewer-facing export:

```json
[
  {
    "path": "/ip/firewall/filter",
    "required": ["chain"],
    "hasAdd": true,
    "rawError": "Script Error: missing value(s) of argument(s) chain (/ip/firewall/filter/add; line 1)"
  }
]
```

`required-args.v<version>.meta.json` carries run metadata:

```json
{
  "routerosVersion": "7.22.1",
  "chrBuildTime": "2026-03-23 14:35:15",
  "schemaPath": "../restraml/docs/7.22.1/deep-inspect.json",
  "schemaSha256": "…",
  "totalMenus": 233,
  "requiredMenus": 169,
  "okCount": 53,
  "missingValueCount": 149,
  "customRequiredCount": 20,
  "probeErrorCount": 11,
  "capturedAt": "2026-04-26T…Z"
}
```

`scripts/build-corpus-db.ts` imports these into:

- `required_arg_results`
- `v_required_args_by_version`
- `v_required_arg_drift`

## 3. Stable unresolved / follow-up cases

These menus did **not** yield a clean required-arg signal and should be treated
as follow-up work, not silently promoted into diagnostics:

- **RouterOS bug / read-only weirdness:** `/interface/dot1x/server/active`,
  `/ip/ipsec/active-peers`, `/ip/proxy/cache-contents`, `/user/active`
  (and `/ip/hotspot/active` on 7.20.8)
- **Stateful / validation-heavy:** `/interface/macvlan`, `/ip/dns/adlist`,
  `/ipv6/nd`, `/user/group`, `/user/ssh-keys`
- **Version-specific quirks:** `/ip/reverse-proxy` on 7.22.1+,
  `/system/package/local-update/update-package-source` on 7.20.8

The `required[]` field is intentionally empty for these rows; only `rawError`
is preserved.

## 4. Cross-version drift

Only six existing paths changed their required-arg result across
7.20.8/7.22.1/7.23rc1:

| Path | 7.20.8 | 7.22.1 | 7.23rc1 |
| --- | --- | --- | --- |
| `/interface/macsec/profile` | `name` | `name` | `ciphers`, `name` |
| `/interface/wifi` | `master-interface`, `radio-mac` | `master-interface`, `mld-name`, `radio-mac` | same as 7.22.1 |
| `/ip/dhcp-server/lease` | `client-id`, `mac-address` | `agent-circuit-id`, `agent-remote-id`, `client-id`, `mac-address` | same as 7.22.1 |
| `/ipv6/pool` | `name`, `prefix`, `prefix-length` | `name`, `prefix-length` | same as 7.22.1 |
| `/routing/bgp/connection` | `instance`, `local.role`, `name`, `remote.address` | `instance`, `local.role`, `name` | same as 7.22.1 |
| `/system/package/local-update/update-package-source` | unresolved interactive prompt | `address`, `password`, `user` | same as 7.22.1 |

### `findwhere=` cross-check

For the five row-store menus above that support `find where`, synthesizing parseIL
with `:put [:parse "[<path> find where …]"]` showed the `findwhere=` field dump
changed in the same version step as the required-arg set:

- `/interface/macsec/profile` — `ciphers` appears in both required args and
  `findwhere=` on 7.23rc1
- `/interface/wifi` — `mld-name` appears in both required args and `findwhere=`
  on 7.22.1+
- `/ip/dhcp-server/lease` — `agent-circuit-id` / `agent-remote-id` appear in
  both required args and `findwhere=` on 7.22.1+
- `/ipv6/pool` — `prefix` stops being required at the same point the
  `findwhere=` field set changes substantially between 7.20.8 and 7.22.1
- `/routing/bgp/connection` — `remote.address` stops being required when the
  `findwhere=` field set shifts from legacy `add-path-out` to
  `input.add-path` / `output.add-path`

`/system/package/local-update/update-package-source` is excluded from that
cross-check: 7.20.8 returns `this command requires user input`, so it does not
behave like the normal row-store `find where` cases.

## 5. What this enables

The spike confirms there is a usable **offline, version-tagged required-arg
signal** for future LSP diagnostics.

Safe first use:

- exact `missing value(s)` paths
- version-aware lookups keyed by menu path + RouterOS version

Use with care:

- custom-message rows that encode **one-of** or **conditional** requirements
- unresolved probe-error rows
- deeper conditional cases such as `/disk add type=iscsi …`, which need a
  second-stage discriminator-aware probe
