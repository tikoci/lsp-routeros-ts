-- ============================================================
-- RouterOS LSP — NeoVim configuration
-- Requires NeoVim 0.10+  |  https://github.com/tikoci/lsp-routeros-ts
-- ============================================================

-- USER SETTINGS — edit these to match your router --

-- LSP server binary.
-- Option 1 (recommended): npm install -g @tikoci/routeroslsp
local lspexec = {"routeroslsp", "--stdio"}

-- Option 2: standalone binary downloaded from GitHub Releases to ~/.bin/
-- Uncomment and adjust the filename for your platform:
--   darwin-arm64  darwin-x64  linux-arm64  linux-x64  windows-x64.exe
-- local lspexec = {os.getenv("HOME") .. "/.bin/lsp-routeros-server-darwin-arm64", "--stdio"}

-- Option 3: run from source after `bun install && bun run compile`
-- local lspexec = {"node", "/path/to/lsp-routeros-ts/server/dist/server.js", "--stdio"}

-- ** RouterOS connection — these MUST be valid for the LSP to work **
local settings = {
    routeroslsp = {
        baseUrl = "http://192.168.88.1",  -- change to your router IP, or https://
        username = "lsp",                  -- RouterOS user with read,api,rest-api policy
        password = "changeme",             -- RouterOS user password
        apiTimeout = 15                    -- seconds to wait for RouterOS responses
    }
}

-- END OF USER SETTINGS — you should not need to edit below this line --

-- ============================================================
-- PLUGIN LOGIC
-- ============================================================

-- Check LSP binary is available
if vim.fn.executable(lspexec[1]) ~= 1 then
    vim.notify("RouterOS LSP: binary not found: " .. lspexec[1] ..
        "\nInstall with: npm install -g @tikoci/routeroslsp", vim.log.levels.WARN)
    return
end

-- workspace/configuration handler — delivers routeroslsp.* settings to the server
local function config_handler(_, params, _)
    local items = {}
    for _, item in ipairs(params.items) do
        if item.section == "routeroslsp" then
            table.insert(items, settings.routeroslsp)
        else
            table.insert(items, vim.empty_dict())
        end
    end
    return items
end

-- Apply RouterOS CLI-matching semantic token highlight colors.
-- Called once at load time (not per-server-init).
local function set_semantic_colors()
    -- Give LSP semantic tokens higher priority than treesitter
    -- vim.hl is the modern name (0.11+); fall back to vim.highlight for 0.10
    local hl = vim.hl or vim.highlight
    hl.priorities.semantic_tokens = 120

    local ns = 0 -- global namespace
    vim.api.nvim_set_hl(ns, "@lsp.type.none",             { fg = "#ffffff", ctermfg = 15 })
    vim.api.nvim_set_hl(ns, "@lsp.type.dir",              { fg = "#079B9B", ctermfg = 37 })           -- aqua cyan
    vim.api.nvim_set_hl(ns, "@lsp.type.cmd",              { fg = "#9B009B", bold = true, ctermfg = 164 }) -- magenta
    vim.api.nvim_set_hl(ns, "@lsp.type.arg",              { fg = "#009C00", ctermfg = 34 })           -- green
    vim.api.nvim_set_hl(ns, "@lsp.type.varname-local",    { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-parameter", { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-local",   { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-val",       { fg = "#ffffff", ctermfg = 15 })
    vim.api.nvim_set_hl(ns, "@lsp.type.varname",          { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-meta",      { fg = "#9B9C00", bold = true, ctermfg = 100 }) -- olive
    vim.api.nvim_set_hl(ns, "@lsp.type.escaped",          { fg = "#07009B", ctermfg = 18 })           -- dark blue
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-global",  { fg = "#079B9B", bold = true, ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.comment",          { fg = "#D0CFCC", italic = true, ctermfg = 252 }) -- light grey
    vim.api.nvim_set_hl(ns, "@lsp.type.obj-inactive",     { fg = "#9B0100", italic = true, ctermfg = 124 }) -- red
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-obsolete",  { fg = "#9B0100", strikethrough = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-undefined", { fg = "#9B0100", strikethrough = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.ambiguous",        { fg = "#9B0100", underline = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-old",       { fg = "#9B0100", ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.error",            { fg = "#9B0100", underline = true, bold = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.varname-global",   { fg = "#079B9B", bold = true, ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-noterm",    { fg = "#07009B", strikethrough = true, ctermfg = 18 })
end

-- Apply colors at load time
set_semantic_colors()

-- ============================================================
-- LSP CLIENT DEFINITION
-- ============================================================

local routeroslsp = {
    name = "routeroslsp",
    cmd = lspexec,
    -- Use project root (.git dir) when available, otherwise cwd
    root_dir = vim.fs.root and vim.fs.root(0, {".git"}) or vim.fn.getcwd(),
    filetypes = {"rsc"},
    capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
        workspace = {
            configuration = true
        },
        textDocument = {
            semanticTokens = {
                requests = {
                    range = false,
                    full = { delta = false }
                },
                tokenTypes = {
                    "none", "dir", "cmd", "arg",
                    "varname-local", "variable-parameter", "variable-local",
                    "syntax-val", "varname", "syntax-meta", "escaped",
                    "variable-global", "comment", "obj-inactive",
                    "syntax-obsolete", "variable-undefined", "ambiguous",
                    "syntax-old", "error", "varname-global", "syntax-noterm"
                },
                tokenModifiers = {},
                multilineTokenSupport = true
            }
        }
    }),
    on_attach = function(client, bufnr)
        -- Refresh semantic tokens when text changes (RouterOS server has no incremental sync).
        -- Debounced to avoid flooding the RouterOS API on every keystroke.
        -- TextChangedI fires during insert mode so diagnostics update while typing.
        local caps = client.server_capabilities
        if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
            local augroup = vim.api.nvim_create_augroup("RouterOSSemanticTokens_" .. bufnr, { clear = true })
            local refresh_pending = false
            local function debounced_refresh()
                if not refresh_pending then
                    refresh_pending = true
                    vim.defer_fn(function()
                        refresh_pending = false
                        vim.lsp.semantic_tokens.force_refresh(bufnr)
                    end, 400)
                end
            end
            vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
                group = augroup,
                buffer = bufnr,
                callback = debounced_refresh
            })
        end
        -- Enable LSP-driven completion (vim.lsp.completion is NeoVim 0.11+).
        -- autotrigger=true shows completions automatically; use nvim-cmp / blink.cmp for richer UX.
        if vim.lsp.completion then
            vim.lsp.completion.enable(true, client.id, bufnr, {
                autotrigger = true,
                convert = function(item)
                    -- Strip trailing "()" from label for cleaner menu display
                    return { abbr = item.label:gsub("%b()", "") }
                end
            })
        end
        vim.notify("RouterOS LSP attached (" .. lspexec[1] .. ")", vim.log.levels.INFO)
    end,
    handlers = {
        ["workspace/configuration"] = config_handler
    }
}

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

-- Start LSP when a .rsc file is opened (vim.lsp.start deduplicates — safe to call multiple times)
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
    pattern = "*.rsc",
    callback = function()
        vim.lsp.start(routeroslsp)
    end
})

-- Also start for the current buffer if it's already a .rsc file.
-- Handles the case where this module loads after BufEnter has already fired
-- (e.g. lazy.nvim ft/event deferred loading, or :source while in a .rsc buffer).
vim.schedule(function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("%.rsc$") then
        vim.lsp.start(routeroslsp)
    end
end)
