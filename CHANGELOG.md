# Release Notes

## Known Issues in "latest" 
* Hopefully mitigated, but LSP may not trigger syntax coloring automatically when LSP is first loaded.   
  * _Workarounds if_ correct _colors are missing_:
    * Run command, "Refresh Semantic Tokens (Syntax Colors)" from VS Code Command Palette (<kbd>F1</kbd> or <kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>)
    * Editing the file should trigger coloring
    * Close and re-open file
* VS Code for Web will hang when opening files.  Need further debugging, but seemingly **not** related to CORS or packaging.  Attempted fix in 0.5.2.
* "Walkthrough" (shown after install on VS Code "Welcome" screen) needs to be updated to show commands and more graphics.
* `README.md` is still very much a WIP - so it's more a catalog of notes, than documentation today.
* In VSCode, "Hover" on Code and "Problems" tab present more debug information than nice text – although they do allow to see "token" so remaining for now.  In future, "hover on code" will likely change, or be an option
* "Triggers" characters should be LSP configuration options, currently: <kbd>space</kbd>, <kbd>/</kbd>, <kbd>:</kbd>, and <kbd>=</kbd>.  Space in particular may be "aggressive" as default.
* Tokenizer should detect RouterOS _data_ types like "ip" and "num", but does not. 
* Blue color used for "escaped" types "\12\3A\BC" is too dark in dark mode - other colors could be tweaked more.
* Standalone LSP (i.e. NeoVim) on Windows is untested, and Window ARM64 build does not compile currently. _VS Code for Windows uses JS-based extension, so does **not** standalone LSP_ 

## Changelog

### 0.5.3

### Changes
* Relaxed VS Code minimum version requirements accidentally increased in LSP v0.5.1 that require the very latest stable version.  Version as old as 1.78 (April 2023) should work fine (and was used previously).  However, only version 1.101 (May 2025) has been tested and thus recommended to use the latest version of VS Code.

### Fixes
* Change `engine` for `vscode` to use `^1.78.2` instead of `^1.101` in `package.json`
* Small fix in log message with an `undefined` instead of `username`


### 0.5.2

#### Changes

* Watchdog refinements to cleanup UI
  * removed "withProgress" style notification, too confusing
  * add clear buttons on error state, including "Retry"

#### Fixes
* VS Code for Web, one theory on "hang" in 0.5.1 is watchdog use of `window.withProgress`, as behind the scene it both new in LSP spec and mixed used of Promise and `await`.  Removing the notification with progress bar also cleans up UI.


### 0.5.1

#### Changes
* New "Watchdog" module to test LSP connection. A notification will appear with results, including an error code when run in all cases.  Watchdog currently only runs:
  * on first loading of RouterOS LSP (_i.e._ when opening an `.rsc` file open after VS Code was started) 
  * via new "Test RouterOS Connection" anytime using VS Code Command Pallette (<kbd>F1</kbd> or <kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>) 
  * when VS Code configuration ("Settings") change for LSP change
* Add command support (`workspace/executeCommand`) to LSP, including new commands:
  * Test Connection to RouterOS - verifies LSP has working connection to RouterOS 
  * Refresh Semantic Tokens - forces re-calculation of color for open docs in editor
  * [VS Code] Show Logs (Output) - shows VS Code "Output" window, with "RouterOS LSP" selected
  * [VS Code] Show Settings - shows RouterOS LSP settings, including RouterOS credentials
  * [VS Code] Apply Semantic Colors Overrides to Settings - if applied, allows manual tweaking of colors in "Settings (JSON)"
  * [Internal] Use Client Credentials - used by TikBook to "override" LSP settings and use it's credentials
* [VSCode] commands above are run by LSP Server, but added to the "Command Palette" by this extension LSP client part, to provide quick access to the configuration and troubleshooting tools
* Added `[` as a triggering character for completion
* Support for TikBook notebook format types as documents, and various other tweak to align language detection
* Use MikroTik logo for `.rsc` (or other files with `languageId` of `routeros`), instead of RouterOS LSP icon
* VSCode for Web should work but cannot be E2E tested without publication of build, so at this point unknown if something broke in recent refactoring.

#### Fixes
* Significant refactoring, including more modularization and standardized eslint+stylistic code formatting applied.
* Cleanup of LSP document handling, including better caching logic, including more focused cache invalidation
* Improved logging: better consistency, content with more curated data, normalized levels used, etc 
* Update VS Code engine to 1.101, along with minor updates to various node dependencies
* REST API client support running request with interceptors (to allow capturing raw exception, which is used by Test Connection command)
* Improved settings management internally, allow using updated settings without restart

> 0.4.x was skipped, reserving even number major or minor semver for VS Code builds without `--pre-release`

### 0.3.15

#### Changes
* Add initial "Document Symbol" support - currently `:local` and `:global`.  This is shown in the "outline" view in Explorer's expandable section near bottom.
* "Completion" now uses text help from `/console/inspect` (if RouterOS provides one) and icons based on type of completion.
* Problems now includes warning - since often only the first error is found by `/console/inspect`
* _VSCode Only_ Code folding now using VSCode's default folding mechanism which seems to better capture various blocks - but no changes to LSP to provide "code folding".
* `user-settings.json` is now where the default configuration (and non-VSCode editors) is stored, previously `default-configuration.json`. 


#### Fixes
* Significant refactor into separate files/classes.  More work to do to better separate REST from LSP client requests to avoid extra calls.  Some "queue" is likely needed to avoid "race conditions" (in the sense editors current text got older LSP data since more recent requests took longer) 
* In VSCode _client_ language extension, remove "folding" subsection from `language-configuration.json` from borrowed  [devMike.mikrotik-routeros-script](https://marketplace.visualstudio.com/items?itemName=devMike.mikrotik-routeros-script) extension — the force VSCode to use it's defaults which produces better results for allowing collapsing code blocks ("folding").
* `webpack` now uses "browser" in `mainFields` - perhaps that fix previous problems
* removed extraneous node imports used by `webpack`


### 0.3.14

> _Update_ VSCode for Web was tested and worked in 0.3.14, with CORS Proxy, after publication.  

#### Changes
* More tweaks for vscode.dev/github.dev

#### Fixes
* `webpack` now uses "browser" in `mainFields` - perhaps that fix previous problems
* removed extraneous node imports used by `webpack`

### 0.3.13

#### Changes
* VSCode for Web did not work, see fixes.  CORS errors – from VSCode, not RouterOS – and crashes when starting `server.web.js` from extension.

#### Fixes
* _web only:_ Extension used wrong id and name after refactor, fixed by uses `package.json` to pull `config.shortid` (since `name` was not right in context)
* _web only:_ Path used `./` in path `server.js`,   Not sure this full fix, but matches sample code.

### 0.3.12

#### Changes
* VSCode for Web _should_ work with LSP E2E test

#### Fixes
* Refactored common code between "node"/desktop and "web" into `client.ts` (extension) and `shared.ts` (server) – the `extension[-web].ts` are now minimal stubs (since only startup is really different between node and web, at least from code POV)
* Debug fully setup:  configuration support both web and node, plus `bun run`'s to support `vscode-test` (which is hosted extension mode) and `npx serve` (which can be used to load local code into vscode.dev/github.dev using "Install extension from Location" using https://localhost:7474)  
* Add `default-configuration.json` to externalize the default settings if LSP client does not support configuration (may just load from `package.json` instead in future)
* polyfills for Axios added to `webpack` web build _which would be handled automatically in modern tools, but VSCode Web requires older packaging mechanism for LSP server._


### 0.3.11

_Internal test only - same changes from 0.3.10_


### 0.3.10

#### Changes
* Should work same as previous – for desktop
* More work is required to enable VSCode for Web - currently first build to see if the LSP test that the LSP does not crash using sample code.

#### Fixes
* Fix vscodeserver/client NPM library to use 9.x not 8.x which [hopefully] is why previous attempts in web did not work
* Revamp build system more exactly model MS's samples for a "web LSP extension", including using `webpack` to build for VSCode for Web (`bun` still used for node/"exe")
  > How LSPs function is VSCode for web it complex.  First, the IPC is JavaScript message to a JS `Worker()`.  Second, VSCode Web wants CommonJS - while the world has moved on to ESM modules.  Understanding that took a minute, with clue in the MS sample for a "web LSP" – they use `webpack` to transpile the `server.ts` into a old-school variable – something that is not supported by any modern JS/TS tooling and not documented anywhere than the sample using `webpage`.  
* Other file cleanup to support web/node builds.

### 0.3.10

#### Changes
* Further changes to support VSCode for Web, at least LSP loads in `code serve-web` (with a [CORS proxy](https://forum.mikrotik.com/t/using-caddy-server-as-cors-proxy-for-rest-api/261562)) 

#### Fixes
* Changed all imports to use ESM ("esnext") - still uses CommonJS for desktop for build, but web is "pure" ESM
* Broke startup code in `-web` versions since need slightly different import's


### 0.3.9

_Internal test only - same changes from 0.3.10_


### 0.3.8

#### Changes
* removed "RouterOS Theme" since it prompt when installed, and theme was not useful

#### Fixes
* added logging to client to debug in vscode for web
* remove them "contributes" for theme, theme file still used to "store" semantic token colors that extension code then applies outside theme

### 0.3.8

#### Changes
* Support loading in VSCode for Web for testing
    > RouterOS does not support CORS so browser support only work with a CORS proxy between web and RouterOS that correctly responds to browser's CORS preflight and provides correct CORS headers.

#### Fixes
* Add new build `--target=browser` to `bun` server and client, and `browser` in `package.json` so VSCode for Web uses code compiled for browser
* Add `useCredentials: true` to Axios HTTP client calls so the CORS information is provided to any CORS proxy. 

### 0.3.7

#### Changes
* Use icon in VSCode tabs for RouterOS files

#### Fixes
* Remove `package-lock.json` files to avoid warning in debug, and not used now that everything is packaged by `bun`.
* Re-test publication from GitHub Action to Open-VSX
  * but... should eventually be controllable via `workflow_dispatch`

### 0.3.6

#### Changes

* Add diagnostic trace setting for protocol message debugging (default is off)
* Apply "semantic token" colors for RouterOS code at startup, _based_ on include RouterOS theme.  This allows using _any_ theme to get proper colors. 
* Radical reduction of file size of extension 200+**M** to 200+**K** (see below)

#### Fixes
* Use `bun` to package extension's TypeScript, previous builds include node_modules which are more than necessary - may use bun in future for constancy
* Cache `/console/inspect` highlights if document has not changed.  Helps for hover but more work to optimize calls to REST API.
* Code formatting cleanup


### 0.3.5

_Publication test only - same changes from 0.3.6_

### 0.3.4

#### Changes
* Publish on VSCode Marketplace

#### Fixes
* Metadata cleanup

### 0.3.3

#### Changes
* Moved changelog and known issues to `CHANGES.md` and refactored `README.md`
* NeoVim "improvements"
  * release download includes nvim-routeros-lsp-init.lua
  * proper color support, including on Alpine
  * init script cleanup
* "Hotlock" support to autocomplete on `/`,` `,`:`, and `=`... [NeoVim only]


#### Fixes
* Add `sample.rsc` to have some "stock script" when developing
* Add "hotlock" as configuration setting
* REST failure is now shown as error message, not "informational"


### 0.3.2

#### Changes
* Updated NeoVim example `init.lua` configuration to use semantic tokens and other cleanup
* Logging cleanup to avoid JSON where possible
* Improvements to performance (see fixes) 

#### Fixes
* Use implementation to handle "textDocument/semanticTokens/full" to reduce syntax coloring delay and avoid .refresh() everywhere
* Reduced _some_ extraneous REST requests to improve responsiveness, more work to do
* Rename "RouterOS LSP Server" to just "RouterOS LSP" for consistency
* Using "Text" as kind in completions


### 0.3.1

#### Changes
* Default colors now mostly follow MikroTik CLI colors for syntax
* Semantic tokens use MikroTik "highlights" names to allow one-to-one color matching between RouterOS syntax and editor.  Previously mapped to "standard" semantic tokens, which was lossy.
* Add "color theme" to map _MikroTik highlights_ to specific colors for VSCode - which is customizable by the user.  
* Show "informational" message on REST API failure (and log too) - although still fatal to LSP operation

#### Fixes
* Logging improved to better trace calls.  Previously random and too verbose. Perhaps slower (TBD) – since overall more log entires – just less fluff per log.
* Always refresh semantic tokens when a document changes.  Previously, was done indirectly and at wrong time.


> Ignoring previous 0.1.x versions & skipping 0.2.x since even minor ver is reserved for published builds

## Potential Future Features



### LSP Features
* Completion for selection should including request=syntax descriptions
  * _Potential Fix_ - use `/console/inspect request=syntax` to get more metadata about
* File Open and Save Operations
  * since we have REST connection loading/saving scripts to "Files", /system/script, etc. is possible
    * _downside:_ LSP need "fuller" permissions
  * support using "back-to-home-files" since permissions can be control for that
* Run on router (via REST or SSH configurable)
* "Code Folding" - detect scopes since the control local variable visibility, better error detection (since individual scopes can be checked independent of larger script) and potential "shortcut" to optimization calls to /console/inspect
  * _Note_ require LSP knowing syntax which has been avoided to date since rules are complex/undocumented 
* Support "Signatures" (i.e. like "/ip/route add dst-address=1.1.1.1" _within_ larger text, and perhaps show completions for base part "/ip/route add" etc)
* Support Rename...
  * on global variables (easier since they should be, well, global names)
  * on local variables (harder since need scoping info, and while one level, not all {} are scopes)
* Only `*.rsc` files will trigger LSP by default.  Additional "language detection" is possible to cover cases where file is not a `.rsc` but contain tell-tail clues that it is RouterOS script or config.  For example, the `#` with software-id etc. in `:export` files is possible to detect but not implemented today.
* Links to documentation in various LSP responses
* Context actions on a selection
  * New script from selection (opens new code window with selection)
  * show offset and position
  * show short highlights (c = cmd, d = dir, G = global, L = local, a = attr, ! = error, ? = obj-inactive)

### VSCode Features
> These go beyond an LSP - which does not use any VSCode-isms but can live in extension part of this code.

  * Some "emulation" of hotlock in VSCode
  * Commands
    * RouterOS LSP: Settings
    * RouterOS LSP: Apply RouterOS Colors
    * Goto: RouterOS Scripting Documentation

### Code and Packaging Improvements
* Control publication via GitHub Action dispatch, currently just publishing if build is successful
* Icon `png` should be "built" using `svg`- currently manual process

