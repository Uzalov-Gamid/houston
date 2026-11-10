-- Makefile: recipes MUST be indented with real tabs (shown as "» ").
vim.opt_local.expandtab = false
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4

vim.keymap.set("n", "<leader>r", function()
  run_in_terminal("make -f " .. vim.fn.shellescape(vim.fn.expand("%")))
end, { buffer = true, desc = "Запустить make" })
