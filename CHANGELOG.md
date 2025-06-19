## Release Notes

- matching lsp-web-extension
- theme to JSON, cmd to apply it
- semantic token notification
- language config to support tikbook types?

- [tikbook] new notebook cmd

### Known Issues in "latest" 
* VSCode for Web is for E2E testing at this point - but will appear as Extension for limited testing purposes but does 
* A connection error is handled very poorly – the Output via for "RouterOS LSP" will show errors but they are largely hidden otherwise.
* More REST calls are made than strictly needed, resulting is potential sluggish behaviors.
  * _Inprogress_ - more work to avoid overlapping calls that avoid cache of highlights
* In some case, the LSP may not trigger syntax coloring automatically after installing — or at least takes a while when first loading LSP, sometimes.  
  * _Workarounds if_ correct _colors are missing_:
    * "Type something" to cause an edit which triggers token parsing 
    * Change tabs
    * Close and re-open file
<kbd>⌘**K**</kbd> then <kbd>⌘**T**</kbd>, then pick RouterOS LSP from list (light or dark).
* Tokenizer should detect RouterOS _data_ types like "ip" and "num" 
  * _Planned Fix_ - parse "none" token via regex & mark with new semantic tokens for routeros datatypes — since script is serialized to string internally all types likely can be inferred correctly 
* Windows untested, and Window ARM64 build does not compile
  * _Needs Research_ - `bun` gets an error with ARM64 and not focused on testing with Windows either 
* In VSCode, "Hover" on Code and "Problems" tab present more debug information than nice text, and inefficient
  * _Planned Fix_ - allow it to be disabled via settings
    * needed for dev as easy way to "see" current "semantic tokens" as detected by editor
* Blue color used for "escaped" types "\12\3A\BC" is too dark in dark mode
  * _Planned Fix_ - dark needs to change, but currently using same theme for both light/dark internally 
* "Triggers" characters should be LSP configuration options, currently: <kbd>space</kbd>, <kbd>/</kbd>, <kbd>:</kbd>, and <kbd>=</kbd>.  Space in particular may be "aggressive" as default. 
  
### Changelog

#### 0.3.10

##### Changes
* Should work same as previous – for desktop
* More work is required to enable VSCode for Web - currently first build to see if the LSP test that the LSP does not crash using sample code.

##### Fixes
* Fix vscodeserver/client NPM library to use 9.x not 8.x which [hopefully] is why previous attempts in web did not work
* Revamp build system more exactly model MS's samples for a "web LSP extension", including using `webpack` to build for VSCode for Web (`bun` still used for node/"exe")
  > How LSPs function is VSCode for web it complex.  First, the IPC is JavaScript message to a JS `Worker()`.  Second, VSCode Web wants CommonJS - while the world has moved on to ESM modules.  Understanding that took a minute, with clue in the MS sample for a "web LSP" – they use `webpack` to transpile the `server.ts` into a old-school variable – something that is not supported by any modern JS/TS tooling and not documented anywhere than the sample using `webpage`.  
* Other file cleanup to support web/node builds.

#### 0.3.10

##### Changes
* Further changes to support VSCode for Web, at least LSP loads in `code serve-web` (with a [CORS proxy](https://forum.mikrotik.com/t/using-caddy-server-as-cors-proxy-for-rest-api/261562)) 

##### Fixes
* Changed all imports to use ESM ("esnext") - still uses CommonJS for desktop for build, but web is "pure" ESM
* Broke startup code in `-web` versions since need slightly different import's


#### 0.3.9

_Internal test only - same changes from 0.3.6_


#### 0.3.8

##### Changes
* removed "RouterOS Theme" since it prompt when installed, and theme was not useful

##### Fixes
* added logging to client to debug in vscode for web
* remove them "contributes" for theme, theme file still used to "store" semantic token colors that extension code then applies outside theme

#### 0.3.8

##### Changes
* Support loading in VSCode for Web for testing
    > RouterOS does not support CORS so browser support only work with a CORS proxy between web and RouterOS that correctly responds to browser's CORS preflight and provides correct CORS headers.

##### Fixes
* Add new build `--target=browser` to `bun` server and client, and `browser` in `package.json` so VSCode for Web uses code compiled for browser
* Add `useCredentials: true` to Axios HTTP client calls so the CORS information is provided to any CORS proxy. 

#### 0.3.7

##### Changes
* Use icon in VSCode tabs for RouterOS files

##### Fixes
* Remove `package-lock.json` files to avoid warning in debug, and not used now that everything is packaged by `bun`.
* Re-test publication from GitHub Action to Open-VSX
  * but... should eventually be controllable via `workflow_dispatch`

#### 0.3.6

##### Changes

* Add diagnostic trace setting for protocol message debugging (default is off)
* Apply "semantic token" colors for RouterOS code at startup, _based_ on include RouterOS theme.  This allows using _any_ theme to get proper colors. 
* Radical reduction of file size of extension 200+**M** to 200+**K** (see below)

##### Fixes
* Use `bun` to package extension's TypeScript, previous builds include node_modules which are more than necessary - may use bun in future for constancy
* Cache `/console/inspect` highlights if document has not changed.  Helps for hover but more work to optimize calls to REST API.
* Code formatting cleanup


#### 0.3.5

_Publication test only - same changes from 0.3.6_

#### 0.3.4

##### Changes
* Publish on VSCode Marketplace

##### Fixes
* Metadata cleanup

#### 0.3.3

##### Changes
* Moved changelog and known issues to `CHANGES.md` and refactored `README.md`
* NeoVim "improvements"
  * release download includes nvim-routeros-lsp-init.lua
  * proper color support, including on Alpine
  * init script cleanup
* "Hotlock" support to autocomplete on `/`,` `,`:`, and `=`... [NeoVim only]


##### Fixes
* Add `sample.rsc` to have some "stock script" when developing
* Add "hotlock" as configuration setting
* REST failure is now shown as error message, not "informational"


#### 0.3.2

##### Changes
* Updated NeoVim example `init.lua` configuration to use semantic tokens and other cleanup
* Logging cleanup to avoid JSON where possible
* Improvements to performance (see fixes) 

##### Fixes
* Use implementation to handle "textDocument/semanticTokens/full" to reduce syntax coloring delay and avoid .refresh() everywhere
* Reduced _some_ extraneous REST requests to improve responsiveness, more work to do
* Rename "RouterOS LSP Server" to just "RouterOS LSP" for consistency
* Using "Text" as kind in completions


#### 0.3.1

##### Changes
* Default colors now mostly follow MikroTik CLI colors for syntax
* Semantic tokens use MikroTik "highlights" names to allow one-to-one color matching between RouterOS syntax and editor.  Previously mapped to "standard" semantic tokens, which was lossy.
* Add "color theme" to map _MikroTik highlights_ to specific colors for VSCode - which is customizable by the user.  
* Show "informational" message on REST API failure (and log too) - although still fatal to LSP operation

##### Fixes
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

> These go beyond an LSP and only work with VSCode
  * Some "emulation" of hotlock in VSCode
  * Notebook support
  * File system support (i.e. router is a directory tree in VSCode "Files" view)

### Code and Packaging Improvements
* Migrate to `CHANGELOG.md` so it appears in VSCode, currently just link
* Control publication via GitHub Action dispatch, currently just publishing if build is successful
* Icon `png` should be "built" using `svg`- currently manual process

