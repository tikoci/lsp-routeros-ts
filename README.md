
# RouterOS LSP

![LSP running VSCode GIF](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDl4NXg5ZXB0YWd2Z2s5b2t0Z2t6enN6Y3NmbTRsZ2o5dWM3MTJqMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Rm4TUg15fUuUhHVvSx/giphy.gif)

RouterOS LSP is a language server that provides syntax highlighting, code completion, diagnostics, and other intelligent language features for RouterOS scripts (.rsc files) in most LSP-capable editors. By querying a live RouterOS device via the REST API, the LSP ensures syntax always matches your RouterOS version.

## Supported Features

RouterOS LSP supports:

- **Completion** — code suggestions and tab completion
- **Diagnostics** — real-time syntax error reporting
- **Semantic Tokens** — syntax highlighting that matches RouterOS CLI colors
- **Hover Information** — help and variable inspection (Work in Progress)
- **Document Symbols** — navigate variables and commands (Work in Progress)
- **References** — find usages
- **Definition Lookup** — jump to definitions
- **VSCode Commands** — additional actions via Command Palette (VSCode only)
- **Walkthrough** — guided setup wizard (VSCode only)

The LSP activates automatically for `.rsc` files or when language is set to `routeros`. In most editors, you can manually set the file language to `routeros` to enable LSP features.

> ✅ RouterOS LSP **requires a HTTP/REST connection** to a RouterOS device. The LSP obtains all syntax data and command definitions by querying RouterOS's `/console/inspect` API.

> ⚠️ **Without** a RouterOS connection, the **LSP cannot function**.  Credentials can be provided in editor's LSP configuration, see [Configuration](#configuration) section.

> 𝌡 For known issues, changelog, and feature tracking, see [CHANGELOG.md](https://github.com/tikoci/lsp-routeros-ts/blob/main/CHANGELOG.md).

## Installation

### Visual Studio Code (VSCode)

#### [Install](https://marketplace.visualstudio.com/items?itemName=TIKOCI.lsp-routeros-ts) RouterOS LSP from VSCode Marketplace

By selecting the "Install" button, you will be prompted by your browser to install the extension.

> ❤️ Also check out [TikBook](https://marketplace.visualstudio.com/items?itemName=TIKOCI.tikbook), which integrates with RouterOS LSP and adds a notebook interface for RouterOS scripts.  Installing TikBook will automatically install RouterOS LSP, if missing.

>#### Alternative VSCode Installation Methods
>
> ##### Install from within VSCode
>
> 1. Open VSCode and go to **Extensions** (or press <kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd> on Mac, <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd> on Windows/Linux)
> 2. Search for "TIKOCI", and select "RouterOS LSP"
> 3. Click **Install**
>
> ##### Install via VSIX File
>
> If you prefer not to use the Marketplace, you can install from a VSIX file from [GitHub Releases](<https://github.com/tikoci/>> lsp-routeros-ts/releases) and `code --install-extension lsp-routeros-ts-*.vsix` from Terminal.  _To remove, `code --uninstall-extension tikoci.lsp-routeros-ts`_

### Other Editors and LSP Clients

For editors other than VSCode, RouterOS LSP provides a standalone language server. The recommended install is via npm (no Gatekeeper/quarantine issues on macOS, works on all platforms with Node.js):

![LSP running in NeoVim](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExZDJiOHV6ZDZsamN6bDJxN21zb3hjZ3I2cm5hNDJzbGpqeWtydXAxMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/reM309KJpRbotDSkL5/giphy.gif)

### NeoVim Install

**Step 1 — Install the LSP server** (pick one):

```bash
# Option A: npm (recommended — no platform-specific filenames, no quarantine issues on macOS)
npm install -g @tikoci/routeroslsp

# Option B: standalone binary from GitHub Releases (no Node.js required)
# Download lsp-routeros-server-<platform>.zip from https://github.com/tikoci/lsp-routeros-ts/releases
# Unzip and place in ~/.bin/ — see platform names below
```

**Step 2 — Download the NeoVim config** to `~/.config/nvim/lua/routeroslsp.lua`:

```bash
mkdir -p ~/.config/nvim/lua
curl -o ~/.config/nvim/lua/routeroslsp.lua \
  https://raw.githubusercontent.com/tikoci/lsp-routeros-ts/main/nvim-routeros-lsp-init.lua
```

**Step 3 — Edit credentials** at the top of `~/.config/nvim/lua/routeroslsp.lua`:

```lua
local settings = {
  routeroslsp = {
    baseUrl = "http://192.168.88.1",  -- change to your router IP, or https://
    username = "lsp",                  -- RouterOS user with read,api,rest-api policy
    password = "changeme",             -- RouterOS user password
  }
}
```

**Step 4 — Load in NeoVim.** Add one line to `~/.config/nvim/init.lua`:

```lua
require('routeroslsp')
```

Open a `.rsc` file — you'll see "RouterOS LSP attached" in the status line. Completion works in insert mode with `<C-x><C-o>` (or automatically if you have a completion plugin).

#### lazy.nvim setup

If you use [lazy.nvim](https://lazy.folke.io/), add this to your plugin specs instead of the `require` above:

```lua
{
  -- points to your own nvim config dir — no git clone needed
  dir = vim.fn.stdpath("config"),
  name = "routeroslsp",
  -- BufReadPre fires before BufEnter, ensuring our autocmd is registered in time
  event = "BufReadPre *.rsc",
  config = function()
    require("routeroslsp")
  end,
}
```

> **Note:** If you put this in a dedicated spec file (e.g. `lua/plugins/routeroslsp.lua`), wrap it in `return { ... }` so lazy.nvim can load it.

#### Standalone binary platform names

If using the GitHub Releases binary (Option B), the filename suffix matches your platform:

| Platform | Filename suffix |
|---|---|
| macOS Apple Silicon | `darwin-arm64` |
| macOS Intel | `darwin-x64` |
| Linux x64 | `linux-x64` |
| Linux ARM64 | `linux-arm64` |
| Windows x64 | `windows-x64.exe` |
| Windows ARM64 | `windows-arm64.exe` |

Place the binary in `~/.bin/` (or any directory in your `$PATH`). When using the binary instead of npm, set `lspexec` at the top of `routeroslsp.lua`:

```lua
-- Option B: standalone binary
local lspexec = {os.getenv("HOME") .. "/.bin/lsp-routeros-server-darwin-arm64", "--stdio"}
```

#### Other LSP clients (Helix, Emacs, etc.)

Any editor supporting the `workspace/configuration` LSP capability works. The server binary is `routeroslsp --stdio` (npm) or `lsp-routeros-server-<platform> --stdio` (GitHub Releases). Configure your editor to pass `routeroslsp.*` settings via `workspace/configuration` — see your editor's LSP documentation for the exact format.

## Configuration

All RouterOS LSP configuration is controlled through the LSP `workspace/configuration` capability. The following settings are available:

### Properties

```typescript
interface LspSettings {
  baseUrl: string;                              // "http://192.168.88.1" or "https://router.lan"
  username: string;                             // RouterOS user name
  password: string;                             // RouterOS user password
  apiTimeout: number;                           // Seconds to wait for RouterOS (default: 15)
  allowClientProvidedCredentials: boolean;      // Allow other extensions to override credentials (default: true)
  checkCertificates: boolean;                   // Verify HTTPS certificates (default: false, ignored in VSCode Web)
}
```

### RouterOS Connection Setup

For the LSP to function, the REST API **must** be enabled in your RouterOS device and accessible from your editor's computer.  A valid RouterOS account **must** be provided to the RouterOS LSP as well (see [Configuration](#configuration) section) .

_Theoretically_, you may not need any setup in RouterOS...as by default, HTTP is enabled on port 80, and reachable from default LAN; and, any RouterOS account (with sufficient rights, like `admin` with `full` rights) can be used in RouterOS LSP for login via REST API.

_However_, it recommended to use HTTPS with valid certificate, and an account with more limited rights to RouterOS configurations.  For example, `write` policy is not required for core LSP operations since only `/console/inspect` data is read.

#### Enabling HTTPS with Let's Encrypt certificate

```routeros
/certificate/enable-ssl-certificate
/ip/service enable www-ssl
```

> 🔐 When using HTTPS, your RouterOS's TLS certificate should be trusted by your system (installed in the system keychain/certificate store). Self-signed certificates are not _directly_ supported by the LSP.  Although in some editors, you can disable certificate checking, but this often complex and not recommended._

#### Creating a Limited RouterOS User

It's recommended to create a dedicated RouterOS user with minimal permissions for the LSP, rather than using a full admin account:

```routeros
/user/group add name=lsp policy=read,api,rest-api
/user add name=lsp password=<strong-password> group=lsp
```

### VS Code Settings

After installing, configure your RouterOS connection:

1. Open **Settings** (press <kbd>⌘</kbd> + <kbd>,</kbd> on Mac or <kbd>Ctrl</kbd> + <kbd>,</kbd> on Windows/Linux)
2. Go to **Extensions > RouterOS LSP**
3. Set the following required fields:
   - **Base URL**: Protocol and host (e.g., `http://192.168.88.1` or `https://my-router.local`) — _without trailing slash_
   - **Username**: RouterOS user with `read`, `api`, and `rest-api` policy access
   - **Password**: RouterOS user password
   - **API Timeout**: How long (in seconds) to wait for RouterOS responses (default: 15 seconds)

![VSCode Settings Example](https://i.ibb.co/6JfjhwKT/Screenshot-2025-06-09-at-10-30-05-AM.png)

Alternatively, use the **Command Palette** (<kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> on Mac or <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> on Windows/Linux), search for "RouterOS LSP: Show Settings", and select it. In VS Code's `settings.json`, all setting uses the `routeroslsp.*` prefix.  

### Other LSP Clients

Other LSP clients should work if they support the **`workspace/configuration`** capability. See the [Other LSP clients](#other-lsp-clients-helix-emacs-etc) section above.

## Troubleshooting

### VS Code

#### Syntax Highlighting (Semantic Tokens)

RouterOS LSP uses **semantic tokens** for syntax highlighting that matches RouterOS CLI colors by default. If colors don't appear or seem incorrect:

1. Open the **Command Palette** and search for **"Refresh Semantic Tokens"**
2. Select **RouterOS LSP: Refresh Semantic Tokens (Syntax Colors)**

To customize token colors, use the **Command Palette** and select **"Apply Semantic Color Overrides to Settings"** to add token color mappings to your `settings.json`.

#### Check Output Logs

If the LSP doesn't work:

1. Open the **Output** view: <kbd>Shift</kbd> + <kbd>⌘</kbd> + <kbd>U</kbd> (Mac) or <kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>U</kbd> (Windows/Linux)
2. Select **"RouterOS LSP"** from the dropdown to view detailed logs
3. Check that your RouterOS credentials are correct and the device is accessible
4. Use the **Command Palette** and select **"RouterOS LSP: Test RouterOS Connection"** to verify connectivity

### Unicode and Character Encoding

For proper syntax checking and colorization, RouterOS LSP converts non-ASCII characters to underscores when querying RouterOS's `/console/inspect` API. This keeps character indexes aligned between RouterOS (Windows1252 encoding) and VSCode (UTF-16 internally), despite HTTP using UTF-8.

**Important:** Non-ASCII characters cannot appear in syntax elements (commands, paths, attributes); they can only appear in comments and strings. The LSP safely replaces them with underscores during syntax analysis without affecting the actual file content. Your script files preserve all encoding and are never modified by the LSP.

If syntax highlighting becomes misaligned with these characters, use **"Refresh Semantic Tokens"** command. If issues persist, please [report them](https://github.com/tikoci/lsp-routeros-ts/issues) with the problematic script attached.

## Visual Studio Code Specific Features

![VSCodeLspCommands](https://i.ibb.co/d4C7x7xy/VS-Code-LSP-Commands.png)

RouterOS LSP provides several commands accessible via the Command Palette (<kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> on Mac or <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> on Windows/Linux):

- **Test RouterOS Connection** — Verifies the LSP can successfully connect to RouterOS with current credentials
- **Refresh Semantic Tokens (Syntax Colors)** — Forces recalculation of semantic tokens for open documents
- **Show Logs (Output)** — Opens the Output pane and selects the RouterOS LSP log channel
- **Show Settings** — Opens RouterOS LSP extension settings
- **Apply Semantic Color Overrides to Settings** — Adds custom semantic token color mappings to `settings.json` for further customization

## Implementation and Development

The RouterOS LSP is built with [Microsoft's vscode-languageserver-node](https://github.com/microsoft/vscode-languageserver-node) library and can run on VSCode, NeoVim, or any LSP-capable editor.

**Key Design:** The LSP communicates with a running RouterOS device via its `/console/inspect` REST API. This means:

- Syntax definitions always match the connected RouterOS version
- New commands and attributes are available immediately after a RouterOS upgrade
- The LSP requires a live RouterOS device; it cannot work offline

### Building from Source

All builds use [Bun](https://bun.sh):

1. Clone the repository: `git clone https://github.com/tikoci/lsp-routeros-ts.git`
2. Install dependencies: `bun install`
3. Build: `bun run compile`

The compiled LSP server is available at `./server/dist/server.js` and can be executed with Node.

### Packaging Options

**VSCode Extension (VSIX):**

```bash
bun run vsix:package    # Creates lsp-routeros-ts-*.vsix
code --install-extension lsp-routeros-ts-*.vsix
```

**Standalone Server (for NeoVim and other editors):**

```bash
bun run bun:exe    # Creates lsp-routeros-server binary for your platform
cp ./lsp-routeros-server ~/.bin/
```

The standalone server supports these transport options:

- `--stdio` — Standard input/output (used by NeoVim and most LSP clients)
- `--node-ipc` — Node IPC (used by VSCode)
- `--socket=<port>` — TCP socket (experimental)

### Developing with VSCode

1. Clone and open the repository in VSCode
2. Run `bun run watch:node` in a terminal to rebuild on changes
3. Press <kbd>F5</kbd> to launch the "Extension Development Host"
4. Open a `.rsc` file and test LSP features

For detailed extension debugging, see the [VSCode Extension Debugging Guide](https://code.visualstudio.com/api/get-started/extension-anatomy#extension-files-structure).

### Project Structure

**Source:**

```bash
client/src/          — VSCode extension client code
server/src/          — LSP server implementation
  controller.ts      — LSP protocol handler  
  server.ts          — Main LSP entry point
  model.ts           — RouterOS data model
  routeros.ts        — RouterOS HTTP API client
```

**Build Outputs:**

```bash
client/dist/         — Compiled VSCode extension
server/dist/         — Compiled LSP server
lsp-routeros-server* — Standalone binaries (various platforms)
*.vsix               — VSCode extension package
```

### Developer Scripts

The LSP uses `bun run` scripts defined in `package.json`:

- `compile` — Build all components
- `watch:node` — Rebuild server on file changes
- `vsix:package` — Package VSCode extension
- `bun:exe` — Build standalone server binary
- `lint` — Run ESLint on code

For new LSP features, add handlers to `server/src/controller.ts`. Refer to the [LSP Protocol Specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/) for complete details.

#### ID Fields

In many places some "id" field is used, to clarify naming:

- `lsp-routeros-ts` is generally used to refer to the entire project, the `-ts` refers that the LSP is implemented in **T**ype**S**cript – as it possible to implement the LSP in other languages

- `lsp-routeros-server-*` refers to just the actual LSP **server** code or build products

- `vscode-lsp-routeros` refers to the VSCode-specific "language extension" that "binds" the LSP server with VSCode extension ecosystem, but largely "proxies" VSCode requests into the LSP server code.

- `routeroslsp` is used when `-` is cannot be used for name, like configuration ("settings") and also the "server" `package.json` to ensure alignment with configuration.

### Understanding LSP Protocol

There are a few dozen APIs that make up an LSP Server.  The ones implemented by RouterOS LSP are listed at top of page.  For a richer experience (i.e. more "help" from LSP in editor), additional protocols _could_ be implemented.  This section attempts to catalog from LSP protocol to implementation to "real features".

#### LSP Specification

The [official LSP specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#languageFeatures) is what really defines possible language features:

- Go to Declaration
- Go to Definition
- Go to Type Definition
- Go to Implementation
- Find References
- Prepare Call Hierarchy
- Call Hierarchy Incoming Calls
- Call Hierarchy Outgoing Calls
- Prepare Type Hierarchy
- Type Hierarchy Super Types
- Type Hierarchy Sub Types
- Document Highlight
- Document Link
- Document Link Resolve
- Hover
- Code Lens
- Code Lens Refresh
- Folding Range
- Selection Range
- Document Symbols
- Semantic Tokens
- Inline Value
- Inline Value Refresh
- Inlay Hint
- Inlay Hint Resolve
- Inlay Hint Refresh
- Moniker
- Completion Proposals
- Completion Item Resolve
- Publish Diagnostics
- Pull Diagnostics
- Signature Help
- Code Action
- Code Action Resolve
- Document Color
- Color Presentation
- Formatting
- Range Formatting
- On type Formatting
- Rename
- Prepare Rename
- Linked Editing Range

The spec is pretty abstract, since LSP servers support a few transports, so
_how_ to implement them depends on the library – but the list above gives the "full menu" of LSP language features.

#### langserver.org

 <https://langserver.org> tracks supported protocols against LSPs, with an LSP "declaring" their support ("Implemented", "WIP", "Not implemented", "Not applicable"). Classifying RouterOS LSP in this scheme:

- ✅ **Implemented** - Code completion - _could be improved but functional_
- 💡 **WIP*** - Hover - _only shows highlight "syntax" codes but does "something"_
- 🚫 **Not implemented** - Jump to def - _somewhat possible but need complex multi-step process and still be lossy and error prone_
- ❓ **WIP** - Workspace symbols - _semantic tokens supported, unsure if same_
- 🚫 **Not implemented** - Find references - _similar to "Jump to def"_
- ✅ **Implemented** - Diagnostics - _could be improved, but do flag the first error found_

> #### langserver.org also tracks "Additional capabilities" like
 >
 > - **Automatic dependency management** - `Not applicable` - _Language servers that support this feature are able to resolve / install a project's 3rd-party dependencies without the need for a user to manually intervene._
 > - **No arbitrary code execution** - `Implemented` - _Language servers that support this feature don't execute arbitrary code (some language servers do this when running build scripts, analyzing the project, etc.)._
 > - **Tree View Protocol** - `Not implemented` - _Language servers that support this feature are able to render tree views. See this link for more information._
 > - **Decoration Protocol** - `Not implemented` - _Language servers that support this feature are able to provide text to be displayed as "non-editable" text in the text editor. See this link for more information._

### Microsoft's `vscode-languageserver`

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
| [`registerFoldingRangeProvider`](https://code.visualstudio.com/api/references/vscode-api#languages.registerFoldingRangeProvider) | [FoldingRange](https://microsoft.github.io/language-server-protocol/specification#textDocument_foldingRange) |

#### Microsoft Sample LSP Code

See <https://github.com/microsoft/vscode-extension-sample>, for example "[Code Actions](https://github.com/microsoft/vscode-extension-samples/blob/main/lsp-user-input-sample/server/src/sampleServer.ts)"

### Implementation "Tips and Tricks"

Some various notes that are not obvious from docs or specific to RouterOS

#### Position vs Offset

The `vscode-languageserver` library provides a "position" generally, which is line and char position.  But for programmatic use the "index" into an array with code is often more useful, this is called "offset" in the library.  The "offset" is more useful with /console/inspect. To handle this, the `TextDocument` object supports an `offsetAt()` and `positionAt()` to enable conversion from the two forms.

#### `/console/inspect request=syntax`

Not currently used — but be useful.  It's not used since it requires "tricks" to get useful information for completions and other things.
For example, to get useful data, stuff like a <kbd>space</kbd> or <kbd>=</kbd> may need to be added to `input=` — even though it does not exist in loaded script/config.

For now, just documenting how `/console/inspect` with `request=syntax` works in various cases:

##### "TEXT" in output could provide a "description" to some LSP data for a "dir"

```text
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

```text
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

```text
> /console/inspect request=syntax input="/ip/route add check-gateway="
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL        SYMBOL-TYPE  NESTED  NONORM  TEXT             
syntax  CheckGateway  definition        0  no                       
syntax                definition        1  no      arp | none | ping
```

The issue here being the TEXT is not always well-formed – why `request=completion` is used to retrieve value like above.
Like for num types there is an expression that shows the _range_ allowed:

```text
> /console/inspect request=syntax input="/ip/service set port="
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL  SYMBOL-TYPE  NESTED  NONORM  TEXT                        
syntax  Port    definition        0  no      Num                         
syntax  Num     definition        1  no      1..65535    (integer number)
```

Point being the format of TEXT varies a good bit – and requires parsing to make it actionable in LSP - and all without any documentation on `/console/inspect`.

---

> ### Disclaimers
>
> **Not affiliated, associated, authorized, endorsed by, or in any way officially connected with MikroTik**
> **Any trademarks and/or copyrights remain the property of their respective holders** unless specifically noted otherwise.
> Use of a term in this document should not be regarded as affecting the validity of any trademark or service mark. Naming of particular products or brands should not be seen as endorsements.
> MikroTik is a trademark of Mikrotikls SIA.
> Apple and macOS are trademarks of Apple Inc., registered in the U.S. and other countries and regions. UNIX is a registered trademark of The Open Group.
> **No liability can be accepted.** No representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information is offered.  Use the concepts, code, examples, and other content at your own risk. There may be errors and inaccuracies, that may of course be damaging to your system. Although this is highly unlikely, you should proceed with caution. The author(s) do not accept any responsibility for any damage incurred.
