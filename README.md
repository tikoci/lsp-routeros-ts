# RouterOS LSP Server

![LSP running VSCode GIF](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDl4NXg5ZXB0YWd2Z2s5b2t0Z2t6enN6Y3NmbTRsZ2o5dWM3MTJqMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Rm4TUg15fUuUhHVvSx/giphy.gif)

## Installing

The RouterOS LSP can be installed into most LSP clients.  Specifically the following LSP capacities are supported:
  * completion ("tab completion")
  * semantic tokens (colorization)
  * diagnostics ("Problems" in VSCode terms)
  * configuration (connection to RouterOS used by LSP)

> `workspace/configuration` ("configuration capacity") is **required** to be supported by an LSP Client – since that is how RouterOS connection information is obtained.  Both `nvim` and VSCode support it.

You may have to restart your editor to ensure the LSP loads.  In most cases, the "trigger" to load the RouterOS LSP is a file ending in `.rsc`.  In most clients, you can also force the type to be "routeros" or "routeroslsp". 

Specific steps to install for common LSP clients:

### Visual Studio Code (VSCode)

The language extension here is not yet published.  Instead a `VSIX` file is provided for download via https://github.com/tikoci/lsp-routeros-ts/releases. This will locally install the LSP and VSCode extension to use it.  The VSCode UI does allow for adding the `lsp-routeros-ts-*.vsix`, but the CLI is shown for brevity: 

#### Install VSIX

To install use the following command, adjust download path and file as needed:
```
code --install-extension ~/Downloads/lsp-routeros-ts.vsix
```

#### Remove VSIX

If you want to remove the VSIX, use:
```
code --uninstall-extension tikoci.lsp-routeros-ts
```

### NeoVim (`nvim`)

![LSP running in NeoVim](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExZDJiOHV6ZDZsamN6bDJxN21zb3hjZ3I2cm5hNDJzbGpqeWtydXAxMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/reM309KJpRbotDSkL5/giphy.gif)


> **NOTE**  Only limited tested has been done using `nvim` – likely many things could be done for
> a text-mode LSP client like `nvim` (NeoVim).  For example, no testing has been done using common LSP "managers" plugins. 

A Lua file is provided with the need script to load the RouterOS LSP, [`nvim-routeros-lsp-init.lua`](https://github.com/tikoci/lsp-routeros-ts/blob/main/nvim-routeros-lsp-init.lua).  This uses the low-level built-in LSP for configuration, but in reality only the "settings" Lua code likely needs to be changed (unless bugs ;).
The code needs to be load from `init.lua` used on `nvim` startup.  Since there are many schemes possible, exactly where `init.lua` lives your steps may vary.  The following was tested on Mac with homebrew-installed `nvim`.

1. Create or edit the `init.lua`, typically located in `~/config/nvim/init.lua`.  Consult `nvim` docs for locating your `init.lua`.
1. Download and copy a `lsp-routeros-server-*` for your platform from GitHub to `~/.bin`.  If you want use use a different path, that will have to be changed in `nvim-routeros-lsp-init.lua`
2. Add the following line to the `init.lua`:
   ```
   dofile(os.getenv('HOME') .. '/.config/nvim/nvim-routeros-lsp-init.lua')
   ```
3. Copy [`nvim-routeros-lsp-init.lua`](https://github.com/tikoci/lsp-routeros-ts/nvim-routeros-lsp-init.lua) to the local `~/config/nvim` with the same name - which be called by the `dofile()` in `init.lua`.  Adjust any paths as needed
4. Adjust settings at top in your copy of `nvim-routeros-lsp-init.lua`.  See "Configuration" section below for more details – critically the RouterOS information must be correct for the LSP to work & the platform **must** be included in 
5. Launch `nvim` with `*.rsc` file and the LSP should load.  If it loads a message will appear at bottom of `nvim`

> To trigger completions, the default in `nvim` is <kbd>Ctrl</kbd> + <kbd>Z</kbd> followed by <kbd>Ctrl</kbd> + <kbd>O</kbd> (omni-complete) **while** in `vi` INSERT mode (<kbd>Ctrl</kbd> + <kbd>i</kbd> or <kbd>a</kbd>).  Again, your configuration may vary.


## Configuration

The RouterOS LSP **requires** a REST API connection to RouterOS device, so the **host and credentials need to be provided**.  

> The LSP does not need "write" or "sensitive" policies – so no need to use credentials for "full" user in the configuration.  Instead, a new RouterOS user can be used to limit the needed permissions.  To create one, use:
> ```
> /user/group add name=list policy=read,api,rest-api
> /user add name=lsp password=changeme group=lsp
> ```

### LSP `workspace/configuration` Options


The supported settings are defined in `./server/server.ts`:
```typescript
interface LspSettings {
    maxNumberOfProblems: number;  // 100
    baseUrl: string;              // "http://192.168.88.1"
    username: string;             // "admin"
    password: string;             // ""
}
```
_Metadata for the settings stored in `./package.json` under "contributes"._

On the router, either the "http" or "https" service must be enabled, and accessible to any editor using the LSP server.

> If you use "https://" (TLS), the certification chain must be valid from the LSP client. So self-signed certificates on REST API may not work out-of-box.
> This is no "allow unsafe certificates" option, so you'll need to add the router's certificate (and/or it's CAs) to the local "keychain" ("keystore" etc).

The specific mechanism to set them varies by LSP client, but all use LSP's `workspace/configuration` API.

#### Visual Studio Code

Assuming the extension with RouterOS LSP is installed, configuration can be done by "Open User Settings":
1. Use <kbd>Ctrl</kbd> + <kbd>,</kbd> (on Mac, <kbd>⌘</kbd> + <kbd>,</kbd>) to show settings
2. Select "Extensions" from left
3. Locate "RouterOS LSP" section in list of extensions
4. Adjust the "Base URL" with IP address and protocol needed (without trailing `/...`), and provide username and password with at least `policy=read,api,rest-api` access to RouterOS
5. Close settings window. Settings should be picked up automatically.  If not, restart VSCode.

![img](https://i.ibb.co/6JfjhwKT/Screenshot-2025-06-09-at-10-30-05-AM.png)

> In VSCode, Setting should also be available by hitting the ⚙️ "gear" icon after locating the "RouterOS LSP" in "Extensions" section in VSCode.
> ![Router-OS-LSP-as-VSIX-loaded-in-VSCode](https://i.ibb.co/1t1y3kLL/Router-OS-LSP-as-VSIX-loaded-in-VSCode.png)


#### NeoVim

The following section in `nvim-routeros-lsp-init.lua` (_i.e. in ~/.bin/nvim) must be **edited** with **correct** RouterOS host and login details, both http:// and https:// are supported by changing the `baseUrl`:
```lua
local settings = {
  routeroslsp = {
    maxNumberOfProblems = 100,
    baseUrl = "http://192.168.88.1",
    username = "lsp",
    password = "changeme",
  }
}
```

Also the **platform** must be included in `lspexe` variable.  The "default" Lua uses just `lsp-routeros-server`  – which is what a local build will produce – but if using a packaged or downloaded LSP binary, this needs to include the right platform.  For example, using macOS on Apple Silcon the name of the executable LSP is `lsp-routeros-server-darwin-arm64`, the top line in `nvim-routeros-lsp-init.lua` becomes
```lua
local lspexec =  { os.getenv("HOME") .. "/.bin/lsp-routeros-server-darwin-arm64", "--stdio" }
```
Additionally `lspexec` must use the correct path.  But be careful since`lspexec` is 2 element "array", so the `--stdio` argument is the 2nd element, while the 1st `..` concatenates the user home directory (`os.getenv("HOME")`) with the default path to LSP binary — it has to be an array and `--stdio` must be provided for LSP to function.

> On macOS, any downloaded file may be flagged and thus not start with a message that it has been "blocked".
> This is because it lacks code signing, as it was built using GitHub.  
> To allow the standalone LSP to run, its "quarantine" flag must removed using:
> ```
> xattr -d com.apple.quarantine ~/.bin/lsp-routeros-server-darwin-x64
> ```
> _adjust path as needed_

### Other LSP clients

Other clients should work, if the LSP client supports the `workspace/configuration` ("configuration capacity") API.  LSP configuration may vary substantially between editors – but configuration variables shown above in `LspSettings` **must** be provided somehow to the LSP client editor.  

## Implementation and Development

The code uses Microsoft's node/TypeScript NPM library [vscode-languageserver-node](https://github.com/microsoft/vscode-languageserver-node), with some implementation coming from Microsoft's VSCode [`lsp-*` extension examples][sample].
While this allows first-class support for Visual Studio Code ("VSCode"), the LSP server does work with other editors with only requirement that `node` be installed.

To provide "AST-like" data to the LSP, HTTP REST calls to a running RouterOS device to retrieve data from `/console/inspect`, specifically `request=highlight` and `request=completion` operations.  _See "Configuration" above on how to provide RouterOS connection details._  Using `/console/inspect` via REST means the LSP is always matched to a specific version's AST, so newer command and attributes will automatically be available simply by upgrading the connected RouterOS to newer (or older) version.  But this also means **without a running RouterOS device, the LSP will not work.**  

> A virtual machine can be used with the "free" version of RouterOS's "CHR" as the `baseUrl`.  This approach avoids storing any "real" router's password in the LSP configuration.  For Mac, UTM can be used as the host, and tikoci's "mikropkl" has ready-to-use images can bring up RouterOS CHR in a few steps, see [tikoci/mikropkl](https://github.com/tikoci/mikropkl) for details. 

### Building LSP

The LSP can be built using just `node` and `npm` (which can be installed using your OS's package manager).

1. Clone this repo, and `cd` to the root directory of the repo
2. Run `npm install` 
3. Run `npm compile`

At the point, the LSP server will be generated as `./server/out/server.js`, which can be invoked using `node` to start the server.

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
To create a single file executable, `npm run bun:exe` can be used.  This will compile the TypeScript and dependencies into a executable (for current platform/OS).  Additionally, it install it to `~/.bin/lsp-routeros-server`, which matches the example `nvim` configuration file in `nvim-routeros-lsp-init.lua`. `lsp-routeros-server` support a option to control which LSP protocol to listen on:
  * `--node-ipc` - use by VSCode for streaming JSON
  * `--stdio` - user by `nvim` and most LSP clients that exec() it and use stdin and stdout for LSP messages
  * `--socket=<port>` - similar to `--stdio` but listens on TCP socket specified in the option

> `--socket` is untested, but potentially useful to create a future LSP container for use as RouterOS `/container` - so the LSP Server live on the same "server" router "hosting" the `/console/inspect` API and thus syntax always be in-sync.  This is not supported today.


#### VSCode Marketplace
_Still in "Alpha" — so not published in Microsoft Extensions catalog currently.  However most of the "underpinnings", like an icon, `.vscodeignore`, `package.json` things, readme, etc... are present since `vsix` package already needed them._


### Developing the LSP using VSCode

To modify the project, it recommended to VSCode since there is debugging and other support for LSP development.

1. Change to the project's code directory, and run `code .` to start VSCode:
2. Build the extension (both client and server) with <kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd> (or <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd>)
3. Open the Run and Debug view and press "Launch Client" (or press `F5`). This will open a "[Extension Development Host]" VSCode window.
4. Edits made to your `server.ts` will be rebuilt immediately but you'll need to "Launch Client" again (<kbd>⌘</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd>) from the primary VSCode window to see the impact of your changes.
5. Modify code as desired.  And feel free to submit any pull request to [GitHub](https://github.com/tikoci/lsp-routeros-ts).

Additionally see Microsoft's [debugging instructions][debug] for using VSCode "Extension Development Host" support.


#### Project Structure
```
.
├── .vscode
│   ├── launch.json         // Tells VS Code how to launch our extension
│   └── tasks.json          // Tells VS Code how to build our extension
├── LICENSE
├── README.md
├── client
│   ├── package-lock.json   // Client dependencies lock file
│   ├── package.json        // Client manifest
│   ├── src
│   │   └── extension.ts    // Code to tell VS Code how to run our language server
│   └── tsconfig.json       // TypeScript config for the client
├── package-lock.json       // Top-level Dependencies lock file
├── package.json            // Top-level manifest
├── server
│   ├── package-lock.json   // Server dependencies lock file
│   ├── package.json        // Server manifest
│   ├── src
│   │   └── server.ts       // Language server code
│   └── tsconfig.json       // TypeScript config for the client
└── tsconfig.json           // Top-level TypeScript config
```

## Open Issues
* This `README` is full of typos and other grammar malfeasance. 
* Error handling for RouterOS connection should be more "visible" - currently errors _should_ be in _some_ LSP client log – but something like a wrong password or invalid protocol should not be "hidden".
* While "configuration capacity" is mandatory, the checks for it are not.
* Some of the completion could be improved or changed:
  * `request=syntax` could be checked to provide descriptions in completion dropdowns
  * more type mapping for completions (e.g. all completion are plain text today) which allows more accurate icons/text in dropdown
* Only `*.rsc` files will trigger LSP by default.  Additional "language detection" is possible to cover cases where file is not a `.rsc` but contain tell-tail clues that it is RouterOS script or config.  For example, the `#` with software-id etc. in `:export` files is possible to detect but not implemented today.
* While "semantic tokens" are generated from RouterOS "highlight" today, there is more work to "use" them.  Including providing better mapping between RouterOS syntax types and LSP API's default syntax types. And, further work to more accurately colorize text to match RouterOS CLI colors.  But if one is familiar with their editor, custom color may be possible by providing mappings from tokens to colors/style.
* RouterOS docs are not currently "indexed" to commands in any regularized way – so while adding documentation links to LSP would be nice, currently it require manual mapping of commands to help pages.
* There may more useful LSP capacities, only the ones that directly mapped to RouterOS /console/inspect "highlight" and "completion" are implemented today.  Similarly more heuristics could be used to add additional data for existing capacities since they are pretty one-to-one to RouterOS info - while some "combo" of lookups or partial `input=` might yet more data.  For example, an non-existent interface is NOT an error – however completion does know what is valid and could compare to create a "warning" about it.
* RouterOS CLI support, it be good of there was a way to "emulate" hotlock in VSCode using the LSP.
* More direct support using a local CHR as the connection, to avoid needing to use a physical router.  
* More direct support running the LSP in a RouterOS container using the "socket" LSP mode.
* Build process needs review, specifically a "clean" target. Ideally a Makefile wrap/replace the currently "npm run" scheme in `package.json` scripts section - which has way too many complex one-liners.
* Once tested more, it could be [Published to VSCode Marketplace][publish] to make it easier to load.

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