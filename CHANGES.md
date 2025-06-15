## Release Notes

### Known Issues in "latest" 
* Size of VSIX is 200MB, which seem too big
  * _Planned Fix_ - includes more node_modules than needed
* More REST calls are made than strictly needed, resulting is potential sluggish behaviors.
  * _Planned Fix_ - more caching of results is needed to improve responsiveness (i.e. if document is not changed from last request=highlight, no need re-compute tokens)
* Publish to OpenVSX
* In some case, the LSP may not trigger syntax coloring automatically after installing.  
  * _Workarounds if colors are missing_:
    * "Type something" to cause an edit which triggers token parsing 
    * Selecting "RouterOS LSP Default" as the "Color Theme" may help.  To bring up the Theme selector use 
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
* Autocompletion ("hotlock")...
  * On VSCode, being uncheck to disable the dropdown of completions
  * NeoVim 0.11+ is required for autocomplete, LSP will work but may get errors in older versions
* "Triggers" characters should be LSP configuration options, currently: <kbd>space</kbd>, <kbd>/</kbd>, <kbd>:</kbd>, and <kbd>=</kbd>.  Space in particular may be "aggressive" as default. 
  
### Changelog

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
    * _downside:_ LSP need "fuller" permisions
  * support using "back-to-home-files" since permissions can be control for that
* Run on router (via REST or SSH configurable)
* "Code Folding" - detect scopes since the control local variable visibility, better error detection (since individual scopes can be checked independant of larger script) and potential "shortcut" to opmization calls to /console/inspect
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
* Use `CHANGELOG.md` so it appears in VSCode
* Add `vsce` and `ovsx` to CI and "npm run" actions to enable `--prerelease` VSIX publishing on build
  * see https://github.com/EclipseFdn/open-vsx.org/wiki/Publishing-Extensions for OpenVSX `ovsx` part
* Icon `png` should be "built" using `svg`- currently manual process

