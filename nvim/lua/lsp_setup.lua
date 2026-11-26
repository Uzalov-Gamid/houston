-- Language servers: they check the code and answer questions about it,
-- but never type for you — no autocompletion, except in SQL (see LspAttach).
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
    map("gd", vim.lsp.buf.definition, "Перейти к определению")
    map("gD", vim.lsp.buf.declaration, "Перейти к объявлению")
    map("<leader>d", vim.diagnostic.open_float, "Ошибка целиком")
    map("<leader>F", function() vim.lsp.buf.format({ async = true }) end, "Отформатировать файл")
    -- the server's colours would fight the palette: keep tree-sitter's
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
      -- the one exception to "no autocompletion": SQL tables and columns
      -- come from the live database and are not worth memorising. The menu
      -- opens only while a word is being typed (not on space) with the first
      -- suggestion already picked, as in VS Code: Enter accepts it,
      -- Ctrl-j / Ctrl-k move to another. <leader>a turns it off and on.
      if client.name == "postgres" then
        -- a syntax error is reported on the first line of the whole query,
        -- not where it is: keep its message visible wherever the cursor is
        vim.diagnostic.config({
          virtual_text = { current_line = false, prefix = dot, spacing = 2 },
        }, vim.lsp.diagnostic.get_namespace(client.id))
        vim.lsp.completion.enable(true, client.id, buf, { autotrigger = false })
        vim.bo[buf].completeopt = "menuone,noinsert,fuzzy,popup"
        vim.opt.shortmess:append("c")
        -- accepting inserts a word, which must not reopen the menu at once
        local accepted = false
        vim.api.nvim_create_autocmd("CompleteDone", {
          buffer = buf,
          callback = function() accepted = vim.v.completed_item.word ~= nil end,
        })
        vim.api.nvim_create_autocmd("TextChangedI", {
          buffer = buf,
          callback = function()
            if accepted then accepted = false return end
            if vim.g.sql_autocomplete == false or vim.fn.pumvisible() == 1 then return end
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = vim.api.nvim_get_current_line():sub(col, col)
            if before:match("[%w_]") then vim.lsp.completion.get() end
          end,
        })
        local pum = function(key, otherwise)
          return function() return vim.fn.pumvisible() == 1 and key or otherwise end
        end
        local imap = function(lhs, rhs, desc)
          vim.keymap.set("i", lhs, rhs, { buffer = buf, expr = true, desc = desc })
        end
        imap("<C-j>", pum("<C-n>", "<C-j>"), "Подсказка ниже")
        imap("<C-k>", pum("<C-p>", "<C-k>"), "Подсказка выше")
        imap("<CR>", function()
          if vim.fn.pumvisible() == 0 then return "<CR>" end
          local info = vim.fn.complete_info({ "selected" })
          return info.selected ~= -1 and "<C-y>" or "<C-e><CR>"
        end, "Вставить подсказку")
        map("<leader>a", function()
          vim.g.sql_autocomplete = vim.g.sql_autocomplete == false
          print(vim.g.sql_autocomplete and "\u{25cf} автодополнение SQL включено"
            or "\u{25cb} автодополнение SQL выключено")
        end, "Автодополнение SQL вкл/выкл")
      end
    end
  end,
})

-- :LspInfo-like summary: which servers run in this file
vim.api.nvim_create_user_command("Lsp", function()
  local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
  print(#names > 0 and ("\u{25cf} " .. table.concat(names, " · ")) or "в этом файле серверов нет")
end, { desc = "Язык-серверы этого файла" })
