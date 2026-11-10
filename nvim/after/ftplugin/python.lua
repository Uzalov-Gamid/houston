-- Python: 4 spaces (PEP 8), <leader>r runs the file.
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true

vim.keymap.set("n", "<leader>r", function()
  -- uses the project's .venv if there is one
  local python = vim.fn.filereadable(".venv/bin/python") == 1 and ".venv/bin/python" or "python3"
  run_in_terminal(python .. " " .. vim.fn.shellescape(vim.fn.expand("%")))
end, { buffer = true, desc = "Запустить (python)" })
