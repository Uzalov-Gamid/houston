-- Language servers: they check the code and answer questions about it,
-- but never type for you — no autocompletion is enabled.
--
-- Each server is one file in lsp/ (command, file types, project root).
-- A server whose program is not installed is skipped silently.
--
--   K          what is this (hover)          gd   go to definition
--   grr        where it is used              grn  rename everywhere
--   gra        code action (fix / import)    gO   symbols of the file
--   ]d  [d     next / previous problem       <leader>d  the problem in full
--   <leader>F  format the file (C formats itself on save)
local servers = {
  "pyright", "clangd", "bashls", "yamlls", "jsonls", "dockerls", "compose", "nginx",
  "lua_ls", "postgres", "terraformls", "helm_ls", "ansiblels", "taplo", "html", "cssls",
}

local enabled = {}
for _, name in ipairs(servers) do
  local cfg = vim.lsp.config[name]
  if cfg and cfg.cmd and vim.fn.executable(cfg.cmd[1]) == 1 then
    enabled[#enabled + 1] = name
  end
end
vim.lsp.enable(enabled)

-- Problems: a dot in the sign column, a wavy underline, and the message
-- only on the line the cursor is on — the rest of the screen stays quiet.
local dot = "\u{25cf}"
vim.diagnostic.config({
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  virtual_text = { current_line = true, prefix = dot, spacing = 2 },
  signs = { text = {
    [vim.diagnostic.severity.ERROR] = dot,
    [vim.diagnostic.severity.WARN] = dot,
    [vim.diagnostic.severity.INFO] = dot,
    [vim.diagnostic.severity.HINT] = "\u{00b7}",
  } },
  float = { border = "rounded", source = "if_many", header = "", prefix = "" },
  jump = { float = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("<leader>d", vim.diagnostic.open_float, "Show the problem in full")
    map("<leader>F", function() vim.lsp.buf.format({ async = true }) end, "Format the file")
    -- the server's colours would fight the palette: keep tree-sitter's
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- :LspInfo-like summary: which servers run in this file
vim.api.nvim_create_user_command("Lsp", function()
  local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
  print(#names > 0 and ("\u{25cf} " .. table.concat(names, " · ")) or "в этом файле серверов нет")
end, { desc = "Language servers of this file" })
