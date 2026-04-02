---
description: "Use when working with RouterOS REST API calls, /console/inspect requests, or HTTP client logic. Covers endpoint formats, request types, response parsing, authentication, encoding, and common gotchas."
applyTo: "server/src/routeros.ts"
---

# RouterOS REST API Patterns

## Endpoint
All LSP data comes from: `POST {baseUrl}/rest/console/inspect`
Auth: HTTP Basic (`username:password` from settings)

## Request Types

### highlight (primary — used for semantic tokens + diagnostics)
```json
{ "request": "highlight", "input": "/ip/route add dst-address=10.0.0.0/8" }
```
Response: Array where each item has a `highlight` field (comma-delimited token types matching each character). Token types: `none`, `dir`, `cmd`, `arg`, `varname-local`, `variable-global`, `syntax-val`, `comment`, `error`, `escaped`, `syntax-obsolete`, etc.

### completion (used for code completion)
```json
{ "request": "completion", "input": "/ip/route " }
```
Response: Array of `{ completion, offset, preference, show, style, text, type }`.

### syntax (NOT yet used — richer metadata)
```json
{ "request": "syntax", "input": "/ip/route add" }
```
Response: Array of `{ type, symbol, symbol-type, nested, nonorm, text }`.
The TEXT field contains descriptions and type definitions but format varies wildly.

### Tricks for richer syntax data
- Append **space** to input → get argument names for a command
- Append **`=`** to input → get value type/enum for an argument
- These aren't in the user's document — they're synthetic probes

### child (NOT yet used — path exploration)
```json
{ "request": "child", "input": "", "path": "/ip/route" }
```
Response: Array of `{ name, node-type, type }`.

## Other Endpoints
- `GET /rest/system/identity` — returns `{ name: "router-name" }` (used by watchdog)
- `POST /rest/execute` with `{ "as-string": true, "script": "..." }` — returns `{ ret: "..." }`

## Encoding Gotchas
- RouterOS uses **Windows-1252** encoding internally
- HTTP transport uses UTF-8
- Non-ASCII characters (code > 127) → replaced with `?` before querying (see `RouterScriptPreprocessor`)
- Character position indexes must be preserved (same-length replacement)
- Documents **>32KB are truncated** by RouterOS

## Error Handling
- Network errors → Axios interceptors clear document cache → next request forces re-fetch
- 401 → credentials wrong (watchdog shows specific message)
- 404 → base URL or path wrong
- ECONNREFUSED → RouterOS REST API not enabled or wrong port
- Timeout → increase `apiTimeout` setting

## Self-signed TLS
- Node.js: `https.Agent({ rejectUnauthorized: false })` when `checkCertificates` is false
- Web: Cannot bypass — requires CORS proxy with valid cert
- VSCode Desktop also needs `http.proxySupport: "fallback"` setting for self-signed to work
