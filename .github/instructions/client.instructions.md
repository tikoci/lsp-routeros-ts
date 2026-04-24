---
applyTo: "client/src/**"
description: "Use when editing VSCode extension client files. Covers client architecture, transport differences, command registration, watchdog, and TikBook integration."
---

# VSCode Extension Client Development

## Role
The client is a **thin VSCode binding**. It creates the LanguageClient, registers VSCode commands, and monitors connection health. **Do not** implement LSP features here — those belong in `server/`.

## Key Files
- `extension.ts` — Desktop entry point: IPC transport, activates LanguageClient
- `extension.web.ts` — Web entry point: Web Worker transport, same activation flow
- `client.ts` — Shared document selectors and package info (used by both entry points)
- `commands.ts` — VSCode Command Palette actions (settings, logs, theme colors, new file)
- `watchdog.ts` — Periodic health check via `getIdentity()` with error-specific messages

## Command Pattern
Client commands call server-side logic via `executeCommand`:
```typescript
// Client registers the command for VSCode UI
vscode.commands.registerCommand('routeroslsp.cmd.foo', async () => {
    // Call server via LSP executeCommand
    const result = await client.sendRequest(ExecuteCommandRequest.type, {
        command: 'routeroslsp.server.foo',
        arguments: []
    })
})
```
Server commands are declared in `controller.ts` `getServerCapabilities()`.
Client-only commands (settings navigation, output panel) don't need server support.

## Adding New Commands
1. Add command entry to `package.json` `contributes.commands`
2. If server-side: add handler in `server/src/controller.ts` `onExecuteCommand`
3. Register in `commands.ts` (or `extension.ts` activate function)
4. Set `enablement` in `package.json` if the command should be hidden from palette

## Desktop vs Web
Both entry points share `client.ts` and `commands.ts`. Differences:
- **Desktop**: `TransportKind.ipc`, loads `server/dist/server.js`
- **Web**: Web Worker, loads `server/dist/server.web.js` via `Uri.joinPath()`

## TikBook Integration
- `allowClientProvidedCredentials` setting controls whether TikBook can override credentials
- TikBook calls `routeroslsp.server.useConnectionUrl` to set ambient read-only credentials
- Watchdog uses `routeroslsp.server.isUsingClientCredentials` to adjust error messages
- Explicit write commands (`routeroslsp.server.router.validateScript` / `routeroslsp.server.router.executeScript`) must keep carrying their own credentials per call — they do not use the ambient TikBook override
- Document selectors include `rscena` scheme and tikbook patterns for cross-extension support

## Rules
- No `console.log` — use `client.outputChannel` if logging needed from client
- Keep the client minimal — if logic could live in the server, put it there
- Test both desktop and web after changes (F5 for desktop, "Run Web Extension" for web)
- Don't import Node.js modules directly — the web entry point runs in a browser context

## Watchdog Lifecycle
- `ConnectionWatchdog` tracks subscriptions in a `disposables` array — always push registrations there
- `dispose()` is idempotent via `#isDisposed` guard — safe to call multiple times
- Use `clearTimeout` + `setTimeout` for scheduling, **not** `Timeout.refresh()` — Node's `.refresh()` is not available in a Web Worker
- `deactivate()` in both entry points is `async`; it disposes the watchdog before stopping the `LanguageClient`
- The web entry point additionally terminates the Worker on deactivate
