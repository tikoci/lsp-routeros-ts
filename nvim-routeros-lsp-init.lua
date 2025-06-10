

local lspexec =  { os.getenv("HOME") .. "/.bin/lsp-routeros-server", "--stdio" }

local settings = {
  routeroslsp = {
    maxNumberOfProblems = 100,
    baseUrl = "http://192.168.88.1",
    username = "lsp",
    password = "changeme",
  }
}

vim.highlight.priorities.semantic_tokens = 120

if vim.fn.executable(lspexec[1]) ~= 1 then
  print("RouterOS LSP executable not found: " .. lspexec[1])
  return`
end


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

local routeroslsp = {
  name = "routeroslsp",
  cmd = lspexec,
  root_dir = vim.fn.getcwd(),
  filetypes = { "rsc" }, -- use the filetype, not pattern
  on_attach = function(client, bufnr)
    print("Attached to", client.name)
  end,
  handlers = {
    ["workspace/configuration"] = config_handler
  },
  capabilities = {
    workspace = {
      configuration = true -- tell server we support workspace/config
    }
  }
}

-- Register on BufEnter
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*.rsc",
  callback = function()
    vim.lsp.start(routeroslsp)
  end
})
