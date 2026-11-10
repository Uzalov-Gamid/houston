-- Shell scripts: 2 spaces, <leader>r runs the script with bash.
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

vim.keymap.set("n", "<leader>r", function()
  run_in_terminal("bash " .. vim.fn.shellescape(vim.fn.expand("%")))
end, { buffer = true, desc = "Запустить (bash)" })
