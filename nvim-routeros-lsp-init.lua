

-- USER SETTINGS --

local lspexec =  { os.getenv("HOME") .. "/.bin/lsp-routeros-server", "--stdio" }

-- ** RouterOS information MUST be valid **
local settings = {
  routeroslsp = {
    -- for TLS, use https:// instead
    baseUrl = "http://192.168.74.1",
    username = "lsp",
    password = "changeme",
    -- unused on neovim
    maxNumberOfProblems = 100
  }
}


-- PLUGIN LOGIC --

-- Check LSP binary is valid
if vim.fn.executable(lspexec[1]) ~= 1 then
  print("RouterOS LSP executable not found: " .. lspexec[1])
  return
end


-- Load configuration into NeoVim "table"
-- TODO: does the default just handle this?
local function config_handler(_, params, _)
  local items = {}

  for _, item in ipairs(params.items) do
    local section = item.section
    if section == "routeroslsp" then
      table.insert(items, settings.routeroslsp)
    else
      table.insert(items, vim.empty_dict())
    end
  end

  return items
end


-- Define a highlight
local function set_semantic_colors()
    -- prioritize LSP colors
    vim.highlight.priorities.semantic_tokens = 120
    -- color mapping
    local set = vim.api.nvim_set_hl
    local ns = 0  -- global namespace
    set(ns, "@lsp.type.none", { fg = "#ffffff" })
    set(ns, "@lsp.type.dir", { fg = "#079B9B" })
    set(ns, "@lsp.type.cmd", { fg = "#9B009B", bold = true })
    set(ns, "@lsp.type.arg", { fg = "#009C00" })
    set(ns, "@lsp.type.varname-local", { fg = "#079B9B" })
    set(ns, "@lsp.type.variable-parameter", { fg = "#079B9B" })
    set(ns, "@lsp.type.variable-local", { fg = "#079B9B" })
    set(ns, "@lsp.type.syntax-val", { fg = "#ffffff" })
    set(ns, "@lsp.type.varname", { fg = "#079B9B" })
    set(ns, "@lsp.type.syntax-meta", { fg = "#9B9C00", bold = true })
    set(ns, "@lsp.type.escaped", { fg = "#07009B" })
    set(ns, "@lsp.type.variable-global", { fg = "#079B9B", bold = true })
    set(ns, "@lsp.type.comment", { fg = "#D0CFCC", italic = true })
    set(ns, "@lsp.type.obj-inactive", { fg = "#9B0100", italic = true })
    set(ns, "@lsp.type.syntax-obsolete", { fg = "#9B0100", strikethrough = true })
    set(ns, "@lsp.type.variable-undefined", { fg = "#9B0100", strikethrough = true })
    set(ns, "@lsp.type.ambiguous", { fg = "#9B0100", underline = true })
    set(ns, "@lsp.type.syntax-old", { fg = "#9B0100" })
    set(ns, "@lsp.type.error", { fg = "#9B0100", underline = true, bold = true })
    set(ns, "@lsp.type.varname-global", { fg = "#079B9B", bold = true })
    set(ns, "@lsp.type.syntax-noterm", { fg = "#07009B", strikethrough = true })
end


-- LSP DEFINITION --

local routeroslsp = {
  name = "routeroslsp",
  cmd = lspexec,
  root_dir = vim.fn.getcwd(),
  filetypes = { "rsc" }, -- use the filetype, not pattern
  capabilities = vim.tbl_deep_extend('force', 
    vim.lsp.protocol.make_client_capabilities(),
    {
      workspace = {
        configuration = true,
      },
      textDocument = {
        semanticTokens = {
          requests = {
            range = false,
            full = {
              delta = false
            }
          },
          tokenTypes = { "none", "dir", "cmd", "arg", "varname-local", "variable-parameter", "variable-local", "syntax-val", "varname", "syntax-meta", "escaped", "variable-global", "comment", "obj-inactive", "syntax-obsolete", "variable-undefined", "ambiguous", "syntax-old", "error", "varname-global", "syntax-noterm"},
          tokenModifiers = {},
          multilineTokenSupport = true
        }
      }
    }
  ),
  on_attach = function(client, bufnr)
    if client.server_capabilities.semanticTokensProvider then
      vim.lsp.semantic_tokens.start(bufnr, client.id)
    end
    print("RouterOS LSP attached to", client.name)
  end,
  handlers = {
    ["workspace/configuration"] = config_handler
  }
}

-- EVENT HANDLERS --

-- Register on BufEnter
-- TODO: Probably should review this, since there is an LspStart etc
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*.rsc",
  callback = function()
    vim.lsp.start(routeroslsp)
    set_semantic_colors()
  end
})
