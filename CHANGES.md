## Releases Notes

### Known Issues in "latest" 
* More REST calls are made than strictly needed, more caching of results is needed to improve responsiveness
* Windows and NeoVim untested, and Window ARM64 build does not compile
* In VSCode, "Hover" on Code and "Problems" tab present more debug information than nice text, and inefficient
* In some case, the LSP may not trigger syntax coloring automatically after installing.  
  * _Workarounds if colors are missing_:
    * "Type something" to cause an edit which triggers token parsing 
    * Selecting "RouterOS LSP Default" as the "Color Theme" may help.  To bring up the Theme selector use 
<kbd>⌘**K**</kbd> then <kbd>⌘**T**</kbd>, then pick RouterOS LSP from list (light or dark).
* Blue color used for "escaped" types "\12\3A\BC" is too dark
* Autocompletion ("hotlock") is not supported on VSCode, and on NeoVim "triggers" should be configurable

### Changelog

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
* "Select and..." - context actions on a selection
  * Test
    * show full completion for selection
    * show offset and position
    * show short highlights (c = cmd, d = dir, G = global, L = local, a = attr, ! = error, ? = obj-inactive)
* "Open from Router" - since we have connection, should be able load either /system/script|schedule or file using existing REST API (or various on-XXXX "event scripts")
* Detect RouterOS _data_ types like "ip" and "num" (parse "none" via regex & mark as new semantic tokens for colorizer)
* Run on router (via REST or SSH configurable)
* Detect scopes for code folding (and internal use) 
* Support "Signatures" (i.e. like "/ip/route add dst-address=1.1.1.1" _within_ larger text, and perhaps show completions for base part "/ip/route add" etc)
* Support Rename...
  * on global variables (easier since they should be, well, global names)
  * on local variables (harder since need scoping info, and while one level, not all {} are scopes)
* New script from selection (opens new code window with selection)
* Only `*.rsc` files will trigger LSP by default.  Additional "language detection" is possible to cover cases where file is not a `.rsc` but contain tell-tail clues that it is RouterOS script or config.  For example, the `#` with software-id etc. in `:export` files is possible to detect but not implemented today.
* Links to documentation in various LSP responses

### VSCode Features
  * Some "emulation" of hotlock in VSCode
  * Notebook support

### Code and Packaging Improvements
* [Publish to VSCode Marketplace][publish] to make it easier to load
* Icon `png` should be "built" using `svg`- currently manual process
* Automate "version bump" on build

