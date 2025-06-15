
# RouterOS LSP

![LSP running VSCode GIF](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDl4NXg5ZXB0YWd2Z2s5b2t0Z2t6enN6Y3NmbTRsZ2o5dWM3MTJqMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Rm4TUg15fUuUhHVvSx/giphy.gif)

The RouterOS LSP can be installed into most LSP clients.  Specifically, the following LSP capacities are supported:
  * completion ("tab completion")
  * semantic tokens (colorization)
  * diagnostics ("Problems" in VSCode terms)
  * configuration (connection to RouterOS used by LSP)
  * hover (WIP, currently for debugging found tokens)

The "trigger" to load the RouterOS LSP is a file ending in `.rsc`.  In most clients, you can also force the "language" ("syntax") type to be "routeros" or "routeroslsp". 

> [!TIP]
>
> Both "Known Issues" and a per-version "Changelog" (as well as future feature tracking) are now in [`CHANGES.md`](https://github.com/tikoci/lsp-routeros-ts/blob/main/CHANGES.md) which tracks the _current_ state of affairs for `routeros-lsp-ts`.

## Install and Configuration

### Enabling RouterOS REST API 

**For all LSP clients, the REST API must be allowed in RouterOS** and the firewall must allow traffic from the computer running the editor to the router.  

By default on RouterOS, unsecured HTTP access is enabled.  To enable HTTPS, if not already enabled, use:
```
/certificate/enable-ssl-certificate 
/ip/service enable www-ssl
```
_RouterOS LSP defaults to plain HTTP, so LSP configuration needs to change from http:// to https://_ when configuring an editor._

Using a different RouterOS account with lower permissions is recommended.  The LSP default configuration assumes a user named "lsp", that can be created using:
```
/user/group add name=list policy=read,api,rest-api
/user add name=lsp password=changeme group=lsp
```
See "Security Considerations" for more details.


### Editor (_LSP client_) Setup 
Specific steps to install for common LSP clients:

#### Visual Studio Code (VSCode)

The RouterOS LSP "language extension" has not yet been published.  Instead, a `VSIX` file is provided for download via https://github.com/tikoci/lsp-routeros-ts/releases. This will locally install the LSP and VSCode extension needed for RouterOS LSP support.  The VSCode UI does allow for adding the `lsp-routeros-ts-*.vsix`, but the CLI is shown for brevity: 

##### Installing the VSIX

To download the latest VSIX from Terminal, use:
```
wget -N https://github.com/tikoci/lsp-routeros-ts/releases/latest/download/lsp-routeros-ts.vsix
```

After downloading the VSIX, to install use the following command, adjusting the download path and file as needed:
```
code --install-extension lsp-routeros-ts.vsix
```


Configuration is required, specifically **RouterOS credentials must be configured in VSCode settings**...

##### Configuring LSP with Visual Studio Code

Launch VSCode, if not already running. LSP configuration can be done by "Open User Settings":
1. Use <kbd>Ctrl</kbd> + <kbd>,</kbd> (on Mac, <kbd>⌘</kbd> + <kbd>,</kbd>) to show settings
2. Select "Extensions" from left
3. Locate "RouterOS LSP" section in the list of extensions
4. Adjust the "Base URL" with the IP address and protocol needed (_without_ trailing slash or path), and provide username and password with at least `policy=read,api,rest-api` access to RouterOS
5. Close the Settings window. Settings should be picked up automatically.

![img](https://i.ibb.co/6JfjhwKT/Screenshot-2025-06-09-at-10-30-05-AM.png)

In VSCode, settings are also available by hitting the ⚙️ "gear" icon after locating the "RouterOS LSP" in the "Extensions" section in VSCode.
> ![Router-OS-LSP-as-VSIX-loaded-in-VSCode](https://i.ibb.co/1t1y3kLL/Router-OS-LSP-as-VSIX-loaded-in-VSCode.png)

##### Customizing Colors in VSCode

RouterOS LSP provides "semantic tokens" which are used for "colorization" and uses custom "syntax types" to match RouterOS names and style.  By default, the LSP uses RouterOS's color scheme – so syntax _should_ match RouterOS CLI colors.  RouterOS LSP includes a VSCode "Color Theme" that can be used for further color customization if desired.  

> If colors are not shown, or incorrectly match RouterOS CLI, then the  "Color Theme" can be explicitly selected using <kbd>⌘</kbd><kbd>K</kbd> then <kbd>⌘</kbd><kbd>T</kbd>, and picking "RouterOS LSP Default" under the dark or light section.   



##### Troubleshooting VSCode and RouterOS LSP

RouterOS LSP logs most operations, perhaps too many.  If there are problems, logs may offer clues and be needed to provide any fix.

In VSCode, logs go to the "Output" view.  To bring up the "Output" view, use <kbd>Shift</kbd> + <kbd>⌘</kbd> + <kbd>U</kbd> then
select "RouterOS LSP" from the dropdown at top to show the logs. 



##### Removing the VSIX

If you want to remove the VSIX, use:
```
code --uninstall-extension tikoci.lsp-routeros-ts
```

#### NeoVim (`nvim`)

![LSP running in NeoVim](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExZDJiOHV6ZDZsamN6bDJxN21zb3hjZ3I2cm5hNDJzbGpqeWtydXAxMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/reM309KJpRbotDSkL5/giphy.gif)


> **NOTE**  Only limited testing has been done using `nvim` – likely many things could be done for
> a text-mode LSP client like `nvim` (NeoVim).  For example, no testing has been done using common LSP "managers" plugins. 

A Lua file is provided with the needed code to load the RouterOS LSP, [`nvim-routeros-lsp-init.lua`](https://github.com/tikoci/lsp-routeros-ts/blob/main/nvim-routeros-lsp-init.lua).  This uses the low-level built-in LSP for configuration, but in reality only the "settings" Lua code likely needs to be changed (unless bugs ;).
The code is loaded from `init.lua`, which is used by `nvim` on startup.  Since there are many schemes possible, exactly where `init.lua` lives your steps may vary.  The following was tested on Mac with homebrew-installed `nvim`.

1. Create or edit the `init.lua`, typically located in `~/config/nvim/init.lua`.  Consult `nvim` docs for locating your `init.lua`.
1. Download and copy a `lsp-routeros-server-*` for your platform from GitHub to `~/.bin`.  If a different path is used, that will have to be changed in `nvim-routeros-lsp-init.lua`
2. Add the following line to the `init.lua`:
 ```
 dofile(os.getenv('HOME') .. '/.config/nvim/nvim-routeros-lsp-init.lua')
 ```
3. Copy [`nvim-routeros-lsp-init.lua`](https://github.com/tikoci/lsp-routeros-ts/nvim-routeros-lsp-init.lua) to the local `~/config/nvim` with the same name - which be called by the `dofile()` in `init.lua`.  Adjust any paths as needed
4. Adjust settings at top in your copy of `nvim-routeros-lsp-init.lua`.  See "NeoVim Example Configuration" section below for more details – critically the RouterOS information must be correct for the LSP to work & the platform **must** be included in 
5. Launch `nvim` with `*.rsc` file and the LSP should load.  If it loads a message will appear at bottom of `nvim`
6. To trigger completions, the default in `nvim` is <kbd>Ctrl</kbd> + <kbd>Z</kbd> followed by <kbd>Ctrl</kbd> + <kbd>O</kbd> (omni-complete) **while** in `vi` INSERT mode (<kbd>Ctrl</kbd> + <kbd>i</kbd> or <kbd>a</kbd>).  Again, your configuration may vary.

> On macOS, any downloaded file may be flagged and thus not start with a message that it has been "blocked".
> This is because it lacks code signing, as it was built using GitHub.  
> To allow the standalone LSP to run, its "quarantine" flag must removed using:
> ```
> xattr -d com.apple.quarantine ~/.bin/lsp-routeros-server-darwin-x64
> ```
> _Adjust path as needed_


##### NeoVim Example Configuration

The following section in example `nvim-routeros-lsp-init.lua` (_i.e. in ~/.bin/nvim) must be **edited** with **correct** RouterOS host and login details, both http:// and https:// are supported by changing the `baseUrl`:
```lua
local settings = {
 routeroslsp = {
 maxNumberOfProblems = 100,
 baseUrl = "http://192.168.88.1",
 username = "lsp",
 password = "changeme",
 hotlock = true
 }
}
```

> In same file, the **platform** must be included in `local lspexe =...` variable.  The "default" uses just `lsp-routeros-server` – which is what a local build will produce – but if using a packaged or downloaded LSP binary, this needs to include the right platform.  For example, using macOS on Apple Silicon the name of the executable LSP is `lsp-routeros-server-darwin-arm64`, the top line in `nvim-routeros-lsp-init.lua` becomes
> ```lua
> local lspexec =  { os.getenv("HOME") .. "/.bin/lsp-routeros-server-darwin-arm64", "--stdio" }
> ```
> Additionally `lspexec` must use the correct path — so be careful since `lspexec` is a **2** element "array", with `--stdio` argument being the _2nd_ element, while the 1st uses `..` concatenates the user home directory (`os.getenv("HOME")`) with the default path to LSP binary.  But `lspexe` must be an array and `--stdio` must be provided for LSP to function.


#### Other LSP clients

Other LSP clients ("editors") should work, if the LSP client supports the "configuration capacity" API.  LSP configuration may vary substantially between editors – but configuration variables shown above in `LspSettings` **must** be provided somehow to the LSP client editor.  

> The LSP spec's `workspace/configuration` ("configuration capability") is **required** for all LSP clients – since that is how RouterOS connection information is obtained.  Without it, the LSP will use the default configuration and be un-configurable by the user (since defaults are compiled in code).  Both `nvim` and VSCode support `workspace/configuration`, most other editors with LSP do too.


### Security Considerations

RouterOS LSP  does not use "write" or "sensitive" policies.  As such, it is highly recommended to avoid using "full" users in the configuration.  Instead, a new RouterOS user can be used to limit the needed permissions.  To create one, use:
```
/user/group add name=list policy=read,api,rest-api
/user add name=lsp password=changeme group=lsp
```
_The defaults/example configuration uses the above – change as needed._

On the router, either the "www" or "www-ssl" service must be enabled, and accessible to any editor using the LSP server.  Firewall configuration may need to be adjusted, but beyond the scope here. 

When using "https://" (TLS), the certificate chain must be valid from the LSP client editor. So self-signed certificates on REST API may not work out-of-box.
> Also the LSP has **no** "allow unsafe certificates" option, so the router TLS certificate (and/or it's CAs and intermediates) must be installed via OS into the system's "keychain" (certificate store).


## Implementation and Development

The code uses Microsoft's node/TypeScript NPM library [vscode-languageserver-node](https://github.com/microsoft/vscode-languageserver-node), with some implementation coming from Microsoft's VSCode [`lsp-*` extension examples][sample].
While this allows first-class support for Visual Studio Code ("VSCode"), the LSP server also work with other editors - either via `node` or using TypeScript compiled by `bun build --compile` into a standalone executable.

To provide "AST-like" data to the LSP, HTTP/S REST calls to a running RouterOS device to retrieve data from `/console/inspect`, specifically `request=highlight` and `request=completion` operations.  Using `/console/inspect` via REST means the LSP is always matched to a specific RouterOS version's AST — so newer commands and attributes will automatically be available simply by upgrading the connected RouterOS.  But this also means **without a running RouterOS device, the LSP will cannot function.**  

> A virtual machine can be used with the "free" version of RouterOS's "CHR" as the `baseUrl`.  This approach avoids storing any "real" router's password in the LSP configuration.  For Mac, UTM can be used as the host, and tikoci's "mikropkl" has ready-to-use images can bring up RouterOS CHR in a few steps, see [tikoci/mikropkl](https://github.com/tikoci/mikropkl) for details. 

### Building LSP

The LSP can be built using just `node` and `npm` (which can be installed using your OS's package manager).

1. Clone this repo, and `cd` to the root directory of the repo
2. Run `npm install` 
3. Run `npm compile`

After which the LSP server will be generated as `./server/out/server.js`, and can be invoked using `node` to start the server.

### Packaging LSP

The project supports a few packaging methods, mainly one for VSCode and a standalone binary for all other LSP clients.

#### VSCode using `vsix` package
The RouterOS LSP can be built to a `.vsix` file for Visual Studio Code use.  A `vsix` file can be manually install the LSP and associated VSCode language extension.
To built the `lsp-routeros-ts-x.y.z.vsix` file from repo root directory, use:
```
npm run vsix:package
```
The file can be installed using `code --install-extension lsp-routeros-ts-*.vsix`.  Alternatively `npm run vsix:install` which will _both build and install_ the RouterOS LSP.  To remove the LSP/extension use `npm run vsix:remove`.


#### Standalone LSP Server (using `bun build --compile`)
To create a single file executable, `npm run bun:exe` can be used.  This will compile the TypeScript and dependencies into an executable (for current platform/OS).  Additionally, it installs to `~/.bin/lsp-routeros-server`, which matches the example `nvim` configuration file in `nvim-routeros-lsp-init.lua`. `lsp-routeros-server` also support options to control which LSP protocol to listen on:
  * `--node-ipc` - use by VSCode for streaming JSON
  * `--stdio` - user by `nvim` and most LSP clients that exec() it and use stdin and stdout for LSP messages
  * `--socket=<port>` - similar to `--stdio` but listens on TCP socket specified in the option

> `--socket` is untested.  In the future, this _could_ enable the LSP to live in a RouterOS `/container` - so the LSP Server be the same as router with `/console/inspect` API, allowing syntax to always be in-sync.  


#### VSCode Marketplace
_Still in "Alpha" — so not published in Microsoft Extensions catalog currently.  However most of the "underpinnings", like an icon, `.vscodeignore`, `package.json` things, readme, etc... are present since `vsix` package already needed them._


### Developing the LSP using VSCode

To modify the project, VSCode is recommended since it has good debugging tools and other support for LSP development.

1. Change to the project's code directory, and run `code .` to start VSCode:
2. Build the extension (both client and server) with <kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd> (or <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd>)
3. Open the Run and Debug view and press "Launch Client" (or press `F5`). This will open a "[Extension Development Host]" VSCode window.
4. Edits made to your `server.ts` will be rebuilt immediately but you'll need to "Launch Client" again (<kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd>) from the primary VSCode window to see the impact of your changes.
5. Modify code as desired.  And feel free to submit any pull request to [GitHub](https://github.com/tikoci/lsp-routeros-ts).

Additionally, see Microsoft's [debugging instructions][debug] for using VSCode "Extension Development Host" support.


### LSP `workspace/configuration` Options

The supported settings are defined in `./server/server.ts`:
```typescript
interface LspSettings {
 maxNumberOfProblems: number;  // 100
 baseUrl: string;              // "http://192.168.88.1"
 username: string;             // "lsp"
 password: string;             // "changeme",
 hotlock: boolean;             // true
}
```
_Metadata for the settings stored in `./package.json` under "contributes"._


#### Project Structure

The most important files used in the code are below.  Many other files are used,
but most are generated by some tool or mostly boilerplate that does not effect
operation of the LSP itself.


```
.
├── .github
│   └── workflows
│       └── build.yaml      // build script use in GitHub Actions CI
├── .vscode
│   ├── launch.json         // Tells VS Code how to launch our extension
│   └── tasks.json          // Tells VS Code how to build our extension
├── .vscodeignore           // VSIX creator (`vsce`) uses to exclude files
├── .gitignore              // `git` uses to prevent checkin of some files (like binaries)
├── icon.png                // used by VSIX package (manually generated from SVG)
├── icon.svg                // "source" to the `png` icon used by VSIX package
├── LICENSE
├── README.md
├── client
│   ├── language-configuration.json   // define basics of RouterOS to VSCode
│   ├── package.json        // extension client node dependencies
│   └── src
│       └── extension.ts    // "shim" between VSCode and LSP server
├── package.json            // both Makefile and manifest & stores config schema
├── server
│   ├── package.json        // LSP server node dependencies
│   └── src
│       └── server.ts       // LSP server code
└── nvim-routeros-lsp-init.lua    // `init.lua` code to add LSP to `nvim`
```

As a result of various build processes, the following "artifacts" are produced as "outputs":
```
.
├── client
│   └── out
|       ├── extension.js      // compiled TypeScript from `.ts` 
│       └── extension.js.map  // used by debugger/errors to map line# between `js` and `ts`
├── server
│   └── out
|       ├── server.js         // compiled `.ts` - can use to start LSP using `node ./server/out/server.js`
│       └── server.map.js     // used by debugger/errors to map line# between `js` and `ts`
├── lsp-routeros-server                   // always same platform as build system (used for development/locally)
├── lsp-routeros-server-darwin-x64        // macOS "Intel" - static binary of `server.ts`
├── lsp-routeros-server-darwin-arm64      // macOS "Silicon" - static binary of `server.ts` 
├── lsp-routeros-server-linux-x64         // Linux - static binary of `server.ts`
├── lsp-routeros-server-linux-arm64       // Linux (aarch64) - static binary of `server.ts`
├── lsp-routeros-server-linux-x64-musl    // Alpine - static binary of `server.ts`
├── lsp-routeros-server-linux-arm64-musl  // Alpine (aarch64) - static binary of `server.ts`
├── lsp-routeros-server-windows-x64.exe   // Windows - static binary of `server.ts`
├── lsp-routeros-server-windows-arm64.exe // Windows for ARM - static binary of `server.ts`
└── lsp-routeros-ts-0.1.0.vsix            // Packaged and downloadable version of VSCode LSP extension

```

#### `npm run` Scripts

Some "helper scripts" for developers can be run use `npm run <scriptname>`, 
and maintained in the `package.json` in root directory.  The common "user facing" `<scriptname>` being:
  *   `compile`: run TypeScript compiler ("tsc -b") for server and client
  *   `vsix:package`: "npm run postinstall && rm -f *.vsix && vsce package",
  *   `vsix:install`: install the VSIX file locally for `tikoci.lsp-routeros-ts`
  *   `vsix:remove`: removes the VSIX file locally for `tikoci.lsp-routeros-ts`
  *   `bun:exe`: builds `lsp-routeros-server` for local OS/platform
  *   `nvim:install`: for local development use to install (or re-install) into NeoVim (`nvim`)
  *   `bump:patch`: bumps "patch" version of meta `package.json` and both client and server `package.json`s

> The `npm run` scripts are mainly for local development.  The GitHub Action CI generally directly invokes tools.  For example, to cross-compile for various platforms, `build.yaml` will just call `bun --compiler` directly and NOT use `npm run bun:exe`.

#### ID Fields

In many places some "id" field is used, to clarify naming:
* `lsp-routeros-ts` is generally used to refer to the entire project, the `-ts` refers that the LSP is implemented in **T**ype**S**cript – as it possible to implement the LSP in other languages
* `lsp-routeros-server-*` refers to just the actual LSP **server** code or build products
* `vscode-lsp-routeros` refers to the VSCode-specific "language extension" that "binds" the LSP server with VSCode extension ecosystem, but largely "proxies" VSCode requests into the LSP server code.
* `routeroslsp` is used when `-` is cannot be used for name, like configuration ("settings") and also the "server" `package.json` to ensure alignment with configuration.


### Understanding LSP Protocols
There are a few dozen APIs that make up an LSP Server.  The ones implemented by RouterOS LSP are listed at top of page.  For a richer experience (i.e. more "help" from LSP in editor), additional protocols _could_ be implemented.  This section attempts to catalog from LSP protocol to implementation to "real features".

#### LSP Specification

The [official LSP specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#languageFeatures) is what really defines possible language features:


* Go to Declaration
* Go to Definition
* Go to Type Definition
* Go to Implementation
* Find References
* Prepare Call Hierarchy
* Call Hierarchy Incoming Calls
* Call Hierarchy Outgoing Calls
* Prepare Type Hierarchy
* Type Hierarchy Super Types
* Type Hierarchy Sub Types
* Document Highlight
* Document Link
* Document Link Resolve
* Hover
* Code Lens
* Code Lens Refresh
* Folding Range
* Selection Range
* Document Symbols
* Semantic Tokens
* Inline Value
* Inline Value Refresh
* Inlay Hint
* Inlay Hint Resolve
* Inlay Hint Refresh
* Moniker
* Completion Proposals
* Completion Item Resolve
* Publish Diagnostics
* Pull Diagnostics
* Signature Help
* Code Action
* Code Action Resolve
* Document Color
* Color Presentation
* Formatting
* Range Formatting
* On type Formatting
* Rename
* Prepare Rename
* Linked Editing Range

The spec is pretty abstract, since LSP servers support a few transports, so
_how_ to implement them depends on the library – but the list above gives the "full menu" of LSP language features.

#### Microsoft's `vscode-languageserver`

The RouterOS LSP implementation uses Microsoft's `vscode-languageserver` Node library, and the documentation describes many of the LSP protocols and using with the library.  The following tables is from the [VSCode docs on Language Extensions](https://code.visualstudio.com/api/language-extensions/programmatic-language-features#language-features-listing), which gives a sense of the possibilities:

| VS Code API | LSP method |
| --- | --- |
| [`createDiagnosticCollection`](https://code.visualstudio.com/api/references/vscode-api#languages.createDiagnosticCollection) | [PublishDiagnostics](https://microsoft.github.io/language-server-protocol/specification#textDocument_publishDiagnostics) |
| [`registerCompletionItemProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerCompletionItemProvider) | [Completion](https://microsoft.github.io/language-server-protocol/specification#textDocument_completion) & [Completion Resolve](https://microsoft.github.io/language-server-protocol/specification#completionItem_resolve) |
| [`registerHoverProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerHoverProvider) | [Hover](https://microsoft.github.io/language-server-protocol/specification#textDocument_hover) |
| [`registerSignatureHelpProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerSignatureHelpProvider) | [SignatureHelp](https://microsoft.github.io/language-server-protocol/specification#textDocument_signatureHelp) |
| [`registerDefinitionProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDefinitionProvider) | [Definition](https://microsoft.github.io/language-server-protocol/specification#textDocument_definition) |
| [`registerTypeDefinitionProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerTypeDefinitionProvider) | [TypeDefinition](https://microsoft.github.io/language-server-protocol/specification#textDocument_typeDefinition) |
| [`registerImplementationProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerImplementationProvider) | [Implementation](https://microsoft.github.io/language-server-protocol/specification#textDocument_implementation) |
| [`registerReferenceProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerReferenceProvider) | [References](https://microsoft.github.io/language-server-protocol/specification#textDocument_references) |
| [`registerDocumentHighlightProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDocumentHighlightProvider) | [DocumentHighlight](https://microsoft.github.io/language-server-protocol/specification#textDocument_documentHighlight) |
| [`registerDocumentSymbolProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDocumentSymbolProvider) | [DocumentSymbol](https://microsoft.github.io/language-server-protocol/specification#textDocument_documentSymbol) |
| [`registerCodeActionsProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerCodeActionsProvider) | [CodeAction](https://microsoft.github.io/language-server-protocol/specification#textDocument_codeAction) |
| [`registerCodeLensProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerCodeLensProvider) | [CodeLens](https://microsoft.github.io/language-server-protocol/specification#textDocument_codeLens) & [CodeLens Resolve](https://microsoft.github.io/language-server-protocol/specification#codeLens_resolve) |
| [`registerDocumentLinkProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDocumentLinkProvider) | [DocumentLink](https://microsoft.github.io/language-server-protocol/specification#textDocument_documentLink) & [DocumentLink Resolve](https://microsoft.github.io/language-server-protocol/specification#documentLink_resolve) |
| [`registerColorProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerColorProvider) | [DocumentColor](https://microsoft.github.io/language-server-protocol/specification#textDocument_documentColor) & [Color Presentation](https://microsoft.github.io/language-server-protocol/specification#textDocument_colorPresentation) |
| [`registerDocumentFormattingEditProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDocumentFormattingEditProvider) | [Formatting](https://microsoft.github.io/language-server-protocol/specification#textDocument_formatting) |
| [`registerDocumentRangeFormattingEditProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerDocumentRangeFormattingEditProvider) | [RangeFormatting](https://microsoft.github.io/language-server-protocol/specification#textDocument_rangeFormatting) |
| [`registerOnTypeFormattingEditProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerOnTypeFormattingEditProvider) | [OnTypeFormatting](https://microsoft.github.io/language-server-protocol/specification#textDocument_onTypeFormatting) |
| [`registerRenameProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerRenameProvider) | [Rename](https://microsoft.github.io/language-server-protocol/specification#textDocument_rename) & [Prepare Rename](https://microsoft.github.io/language-server-protocol/specification#textDocument_prepareRename) |
| [`registerFoldingRangeProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerFoldingRangeProvider) | [FoldingRange](https://microsoft.github.io/language-server-protocol/specification#textDocument_foldingRange)


#### langserver.org
 https://langserver.org tracks supported protocols against LSPs, with an LSP "declaring" their support ("Implemented", "WIP", "Not implemented", "Not applicable"). Classifying RouterOS LSP in this scheme:
  * ✅ **Implemented** - Code completion - _could be improved but functional_
  * 💡 **WIP*** - Hover - _only shows highlight "syntax" codes but does "something"_
  * 🚫 **Not implemented** - Jump to def - _somewhat possible but need complex multi-step process and still be lossy and error prone_
  * ❓ **WIP** - Workspace symbols - _semantic tokens supported, unsure if same_
  * 🚫 **Not implemented** - Find references - _similar to "Jump to def"_ 
  * ✅ **Implemented** - Diagnostics - _could be improved, but do flag the first error found_

 > #### langserver.org also tracks "Additional capabilities" like:
 > * **Automatic dependency management** - `Not applicable` - _Language servers that support this feature are able to resolve / install a project's 3rd-party dependencies without the need for a user to manually intervene._
 > * **No arbitrary code execution** - `Implemented` - _Language servers that support this feature don't execute arbitrary code (some language servers do this when running build scripts, analyzing the project, etc.)._
 > * **Tree View Protocol** - `Not implemented` - _Language servers that support this feature are able to render tree views. See this link for more information._
 > * **Decoration Protocol** - `Not implemented` - _Language servers that support this feature are able to provide text to be displayed as "non-editable" text in the text editor. See this link for more information._

#### Microsoft Sample LSP Code

See https://github.com/microsoft/vscode-extension-sample, for example "[Code Actions](https://github.com/microsoft/vscode-extension-samples/blob/main/lsp-user-input-sample/server/src/sampleServer.ts)" 

#### Implementation "Tips and Tricks"

Some various notes that are not obvious from docs or specific to RouterOS

##### Position vs Offset

The `vscode-languageserver` library provides a "position" generally, which is line and char position.  But for programmatic use the "index" into an array with code is often more useful, this is called "offset" in the library.  The "offset" is more useful with /console/inspect. To handle this, the `TextDocument` object supports an `offsetAt()` and `positionAt()` to enable conversion from the two forms. 

##### `/console/inspect request=syntax`

Not currently used — but be useful.  It's not used since it requires "tricks" to get useful information for completions and other things.
For example, to get useful data, stuff like a <kbd>space</kbd> or <kbd>=</kbd> may need to be added to `input=` — even though it does not exist in loaded script/config.

For now, just documenting how `/console/inspect` with `request=syntax` works in various cases:

###### "TEXT" in output could provide a "description" to some LSP data for a "dir"
```
> /console/inspect request=syntax input="/ip/route add" 
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL   SYMBOL-TYPE  NESTED  NONORM  TEXT                                                                    
syntax           collection        0  yes                                                                             
syntax  ..       explanation       1  no      go up to ip                                                             
syntax  add      explanation       1  no      Create a new item                                                       
syntax  check    explanation       1  no                                                                              
syntax  comment  explanation       1  no      Set static route comment                                                
syntax  disable  explanation       1  no      Disable route                                                           
syntax  edit     explanation       1  no                                                                              
syntax  enable   explanation       1  no      Enable route                                                            
syntax  export   explanation       1  no      Print or save an export script that can be used to restore configuration
syntax  find     explanation       1  no      Find items by value                                                     
syntax  get      explanation       1  no      Gets value of item's property                                           
syntax  print    explanation       1  no      Print values of item properties                                         
syntax  remove   explanation       1  no      Remove route                                                            
syntax  reset    explanation       1  no                                                                              
syntax  set      explanation       1  no      Change item properties                                                  
syntax  unset    explanation       1  no         
```

###### Adding a fake <kbd>space</kbd> to `input` gets "arg"'s for a "cmd"
```
> /console/inspect request=syntax input="/ip/route add "
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL               SYMBOL-TYPE  N  NON  TEXT                                                                                                            
syntax                       collection   0  yes                                                                                                                  
syntax  blackhole            explanation  1  no                                                                                                                   
syntax  check-gateway        explanation  1  no   Whether all nexthops of this route are checking reachability of gateway by sending arp requests every 10 seconds
syntax  comment              explanation  1  no   Short description of the item                                                                                   
syntax  copy-from            explanation  1  no   Item number                                                                                                     
syntax  disabled             explanation  1  no   Defines whether item is ignored or used                                                                         
syntax  distance             explanation  1  no   Administrative distance of the route                                                                            
syntax  dst-address          explanation  1  no   Destination address                                                                                             
syntax  gateway              explanation  1  no                                                                                                                   
syntax  pref-src             explanation  1  no                                                                                                                   
syntax  routing-table        explanation  1  no                                                                                                                   
syntax  scope                explanation  1  no                                                                                                                   
syntax  suppress-hw-offload  explanation  1  no                                                                                                                   
syntax  target-scope         explanation  1  no                                                                                                                   
syntax  vrf-interface        explanation  1  no                 
```

###### Adding a fake <kbd>=</kbd> to `input` gets some "definition"
```
> /console/inspect request=syntax input="/ip/route add check-gateway="
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL        SYMBOL-TYPE  NESTED  NONORM  TEXT             
syntax  CheckGateway  definition        0  no                       
syntax                definition        1  no      arp | none | ping
```
The issue here being the TEXT is not always well-formed – why `request=completion` is used to retrieve value like above.
Like for num types there is an expression that shows the _range_ allowed:
```
> /console/inspect request=syntax input="/ip/service set port="
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL  SYMBOL-TYPE  NESTED  NONORM  TEXT                        
syntax  Port    definition        0  no      Num                         
syntax  Num     definition        1  no      1..65535    (integer number)
```

Point being the format of TEXT varies a good bit – and requires parsing to make it actionable in LSP - and all without any documentation on `/console/inspect`.





---
[debug]: https://code.visualstudio.com/api/language-extensions/language-server-extension-guide#debugging-both-client-and-server
[sample]: https://github.com/microsoft/vscode-extension-samples/tree/main/lsp-sample
[publish]: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
[vsix]: https://code.visualstudio.com/api/working-with-extensions/publishing-extension#packaging-extensions



> #### Disclaimers
> **Not affiliated, associated, authorized, endorsed by, or in any way officially connected with MikroTik, Apple, nor UTM from Turing Software, LLC.**
> **Any trademarks and/or copyrights remain the property of their respective holders** unless specifically noted otherwise.
> Use of a term in this document should not be regarded as affecting the validity of any trademark or service mark. Naming of particular products or brands should not be seen as endorsements.
> MikroTik is a trademark of Mikrotikls SIA.
> Apple and macOS are trademarks of Apple Inc., registered in the U.S. and other countries and regions. UNIX is a registered trademark of The Open Group. 
> **No liability can be accepted.** No representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information is offered.  Use the concepts, code, examples, and other content at your own risk. There may be errors and inaccuracies, that may of course be damaging to your system. Although this is highly unlikely, you should proceed with caution. The author(s) do not accept any responsibility for any damage incurred. 