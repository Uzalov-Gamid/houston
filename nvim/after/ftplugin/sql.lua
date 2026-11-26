-- sql: 2 spaces.
-- <leader>r: run the whole file (or the selected lines) with psql in the
-- database vim.g.db (lua/plugins.lua); the result opens as a table below,
-- the cursor moves into it: q / Enter or leaving the window closes it.
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

vim.keymap.set("n", "<leader>r", function()
  run_sql(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end, { buffer = true, desc = "Выполнить файл в базе" })

vim.keymap.set("x", "<leader>r", function()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  vim.cmd("normal! \27")
  run_sql(table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n"))
end, { buffer = true, desc = "Выполнить выделенное в базе" })

-- Format with sqlfluff on save (rules: sqlfluff.cfg next to init.lua; only
-- line breaks, indents and keyword case). Skipped silently if sqlfluff is
-- missing or the code does not parse.
if vim.fn.executable("sqlfluff") == 1 then
  local config = vim.fn.stdpath("config") .. "/sqlfluff.cfg"
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    callback = function(args)
      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
      local res = vim.system({ "sqlfluff", "fix", "--config", config, "-" }, {
        stdin = table.concat(lines, "\n") .. "\n",
      }):wait()
      if res.code ~= 0 then
        return
      end
      local formatted = vim.split(res.stdout, "\n", { trimempty = false })
      if formatted[#formatted] == "" then
        table.remove(formatted)
      end
      if not vim.deep_equal(lines, formatted) then
        local view = vim.fn.winsaveview()
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, formatted)
        vim.fn.winrestview(view)
      end
    end,
  })
end
