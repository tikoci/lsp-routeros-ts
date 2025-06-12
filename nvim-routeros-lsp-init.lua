

-- USER SETTINGS --

local lspexec =  { os.getenv("HOME") .. "/.bin/lsp-routeros-server", "--stdio" }

-- alternatively, you can use the GH repo and `node` directly (after "npm install" and "npm run compile")
-- lspexec =  { "node", "/app/lsp-routeros-ts/server/out/server.js", "--stdio" }    

-- ** RouterOS information MUST be valid **
local settings = {
  routeroslsp = {
    -- for TLS, use https:// instead
    baseUrl = "http://192.168.74.1",
    username = "lsp",
    password = "changeme",
    -- enables autocompletion
    hotlock = true,
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
    local ns = 0  -- global namespace
    -- TODO: support background color for errors
    vim.api.nvim_set_hl(ns, "@lsp.type.none", { fg = "#ffffff", ctermfg = 15 })           -- white
    vim.api.nvim_set_hl(ns, "@lsp.type.dir", { fg = "#079B9B", ctermfg = 37 })            -- aqua cyan
    vim.api.nvim_set_hl(ns, "@lsp.type.cmd", { fg = "#9B009B", bold = true, ctermfg = 164 }) -- magenta
    vim.api.nvim_set_hl(ns, "@lsp.type.arg", { fg = "#009C00", ctermfg = 34 })            -- green
    vim.api.nvim_set_hl(ns, "@lsp.type.varname-local", { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-parameter", { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-local", { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-val", { fg = "#ffffff", ctermfg = 15 })
    vim.api.nvim_set_hl(ns, "@lsp.type.varname", { fg = "#079B9B", ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-meta", { fg = "#9B9C00", bold = true, ctermfg = 100 }) -- olive-ish
    vim.api.nvim_set_hl(ns, "@lsp.type.escaped", { fg = "#07009B", ctermfg = 18 })         -- dark blue
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-global", { fg = "#079B9B", bold = true, ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.comment", { fg = "#D0CFCC", italic = true, ctermfg = 252 }) -- light grey
    vim.api.nvim_set_hl(ns, "@lsp.type.obj-inactive", { fg = "#9B0100", italic = true, ctermfg = 124 }) -- red
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-obsolete", { fg = "#9B0100", strikethrough = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.variable-undefined", { fg = "#9B0100", strikethrough = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.ambiguous", { fg = "#9B0100", underline = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-old", { fg = "#9B0100", ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.error", { fg = "#9B0100", underline = true, bold = true, ctermfg = 124 })
    vim.api.nvim_set_hl(ns, "@lsp.type.varname-global", { fg = "#079B9B", bold = true, ctermfg = 37 })
    vim.api.nvim_set_hl(ns, "@lsp.type.syntax-noterm", { fg = "#07009B", strikethrough = true, ctermfg = 18 })

end


-- LSP DEFINITION --

local routeroslsp = {
  name = "routeroslsp",
  cmd = lspexec,
  root_dir = vim.fn.getcwd(),
  filetypes = { "rsc" },
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
  on_init = function(client, results)
      vim.lsp.buf_attach_client(0, client.id)
      set_semantic_colors()
  end,
  on_attach = function(client, bufnr)
    local caps = client.server_capabilities
    if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
      local augroup = vim.api.nvim_create_augroup("SemanticTokens", {})
      vim.api.nvim_create_autocmd("TextChanged", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.semantic_tokens.force_refresh()
        end,
      })
      -- fire it first time on load as well
      vim.lsp.semantic_tokens.start(bufnr, client.id)
      vim.lsp.completion.enable(true, client.id, bufnr, {                                                                                                                            
        autotrigger = settings.hotlock,                                                                                                                                                          
        -- convert = function(item)                                                                                                                                                     
        --  return { abbr = item.label:gsub('%b()', '') }                                                                                                                              
        -- end,                                                                                                                                                                         
      })                 
    end
    print("RouterOS LSP attached via: ", lspexec)
  end,
  handlers = {
    ["workspace/configuration"] = config_handler
  },
}


-- EVENT HANDLERS --

-- Register on BufEnter
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*.rsc",
  callback = function()
    vim.lsp.start(routeroslsp)
  end
})
