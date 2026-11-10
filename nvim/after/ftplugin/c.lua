-- C: 4 spaces. A project's .editorconfig wins.
-- <leader>r: `make` if there is a Makefile, otherwise compile this file
-- with the School 21 flags and run it.
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.cindent = true
vim.opt_local.commentstring = "// %s"

vim.keymap.set("n", "<leader>r", function()
  if vim.fn.filereadable("Makefile") == 1 then
    run_in_terminal("make")
  else
    local src = vim.fn.shellescape(vim.fn.expand("%"))
    local bin = vim.fn.shellescape(vim.fn.tempname())
    run_in_terminal("cc -Wall -Wextra -Werror -std=c11 " .. src .. " -o " .. bin .. " && " .. bin)
  end
end, { buffer = true, desc = "Build & run (make or cc)" })

-- Format with clang-format on save (style: nearest .clang-format, otherwise
-- Google with 4-space indent). Skipped silently if clang-format is missing
-- or the code does not parse.
if vim.fn.executable("clang-format") == 1 then
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = 0,
    callback = function(args)
      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
      local name = vim.api.nvim_buf_get_name(args.buf)
      local has_config = #vim.fs.find(".clang-format", { upward = true, path = vim.fs.dirname(name) }) > 0
      local style = has_config and "file" or "{BasedOnStyle: Google, IndentWidth: 4, ColumnLimit: 110}"
      local res = vim.system({ "clang-format", "--assume-filename=" .. name, "--style=" .. style }, {
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
