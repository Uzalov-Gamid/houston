-- Markdown: soft-wrap long lines at word boundaries, keep the indent of
-- wrapped list items, 2-space lists.
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

-- with wrap on, j/k move by screen line, not by paragraph
vim.keymap.set("n", "j", "gj", { buffer = true })
vim.keymap.set("n", "k", "gk", { buffer = true })

-- ── Obsidian extras in the editor ────────────────────────────────────
-- Tree-sitter colours headings, lists, links and code (colors/palette.lua).
-- What it does not know about is drawn here with extmarks: [[wiki links]],
-- ==highlights==, #tags, plain > quotes (brass bar) and callouts
-- > [!type] Title — an icon in front and the block's > markers in the
-- callout's colour, like Obsidian.
local CALLOUT = require("mdview").CALLOUT -- type → { colour family, icon }
local ns = vim.api.nvim_create_namespace("md_obsidian")
local buf = vim.api.nvim_get_current_buf()

local function mark(row, from, to, group)
  vim.api.nvim_buf_set_extmark(buf, ns, row, from, { end_col = to, hl_group = group, priority = 150 })
end

local function decorate()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local in_code, callout = false, nil
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local row = i - 1
    if line:match("^%s*```") or line:match("^%s*~~~") then
      in_code = not in_code
    elseif not in_code then
      -- quotes and callouts
      local gt = line:match("^%s*()>")
      if gt then
        local kind, title_at = line:match("^%s*>%s*%[!(%a+)%][-+]?()")
        if kind then
          local spec = CALLOUT[kind:lower()] or CALLOUT.note
          callout = spec[1]
          local bracket = line:find("[", 1, true) - 1
          vim.api.nvim_buf_set_extmark(buf, ns, row, bracket, {
            virt_text = { { spec[2] .. " ", "MdCallout" .. callout } }, virt_text_pos = "inline",
          })
          mark(row, gt - 1, gt, "MdCallout" .. callout .. "Bar")
          mark(row, bracket, #line, "MdCallout" .. callout)
        else
          mark(row, gt - 1, gt, callout and "MdCallout" .. callout .. "Bar" or "MdQuoteBar")
        end
      else
        callout = nil
      end
      -- [[wiki links]], ==highlights==, #tags (not headings)
      for s, e in line:gmatch("()%[%[.-%]%]()") do
        mark(row, s - 1, e - 1, "MdWikiLink")
      end
      for s, e in line:gmatch("()==[^=].-==()") do
        mark(row, s - 1, e - 1, "MdHighlight")
      end
      if not line:match("^#+%s") then
        for s, e in line:gmatch("()#[^%s#%[%]%(%)%.,;:!%?\"'`=]+()") do
          if s == 1 or line:sub(s - 1, s - 1):match("%s") then
            mark(row, s - 1, e - 1, "MdTag")
          end
        end
      end
    end
  end
end

decorate()
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter" }, {
  buffer = buf,
  callback = function() vim.schedule(decorate) end,
})

-- ── Reading view (like Obsidian's) ────────────────────────────────────
-- <leader>p swaps the editor for the note drawn the Obsidian way
-- (lua/mdview.lua): properties, headings, callouts that fold, code cards,
-- tables, embeds, pictures. q or <leader>p — back to the same place.
vim.keymap.set("n", "<leader>p", function() require("mdview").open() end,
  { buffer = true, desc = "Reading view" })

-- <leader>r: open the file in the default Markdown app (Obsidian)
vim.keymap.set("n", "<leader>r", function()
  vim.cmd.write()
  vim.fn.jobstart({ "open", vim.fn.expand("%:p") })
end, { buffer = true, desc = "Open in Markdown app" })
