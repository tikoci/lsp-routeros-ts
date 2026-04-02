---
applyTo: "server/src/**"
description: "Use when editing LSP server files. Covers server architecture, RouterOS API patterns, handler conventions, and the three build targets."
---

# LSP Server Development

## Architecture
- `controller.ts` is the core — all LSP handlers live here as private `async #method()` members
- `routeros.ts` wraps Axios for all RouterOS HTTP calls — never make raw HTTP calls elsewhere
- `model.ts` provides `LspDocument` with lazy async token caching — use `.highlightTokens` Promise
- `tokens.ts` parses `/console/inspect` highlight responses — modify here for token interpretation
- `shared.ts` manages settings and logging — use `log.debug/info/warn/error`, never `console.log`

## Handler Pattern
All LSP handlers are private async methods on `LspController`:
```typescript
async #handlerName(params: SomeParams): Promise<Result> {
    await this.isReady
    // ... handler logic
}
```
Register them in `registerLspHandlers()` using `this.#handlerName.bind(this)`.

## Singleton Access
- `LspController.default` — the controller instance
- `RouterRestClient.default` — the HTTP client instance
- Don't create additional instances

## RouterOS API Calls
- Always go through `RouterRestClient` methods (`inspect`, `execute`)
- The API is at `POST {baseUrl}/rest/console/inspect` with Basic Auth
- Request body: `{ request: 'highlight'|'completion'|'syntax'|'child', input: string }`
- Non-ASCII chars must go through `RouterScriptPreprocessor.unicodeCharReplace('?')` before sending
- Documents >32KB are truncated — RouterOS API limitation

## Three Build Targets
Server code must work in:
1. **Node.js** (desktop VSCode + standalone binary) — file system, https module available
2. **Web Worker** (VSCode Web) — no Node.js APIs, no `https`, fetch-only

When adding Node.js-specific features, guard with runtime checks. The webpack config nullifies `fs`, `https`, `http`, `stream`, etc. for the web build.

## Error Handling
- HTTP interceptors in `routeros.ts` clear document cache on errors — don't duplicate this
- Errors are normalized to `RouterOSClientError` (`code`, `message`, `status`) via `normalizeError()` before crossing the LSP protocol boundary — avoids circular-reference JSON serialization crashes
- `inspect*` and `execute` methods return `undefined` on error (graceful degradation)
- `getIdentity` propagates the error as `RouterOSClientError` — the watchdog needs the details
- Never let an unhandled error crash the LSP server — it kills the user's editing experience

## Adding New LSP Features
1. Declare capability in `getServerCapabilities()` in `controller.ts`
2. Register handler in `registerLspHandlers()` in same file
3. Use the arrow-function-on-controller pattern
4. Gate on `await controller.isReady`
5. Test with F5 Extension Development Host
