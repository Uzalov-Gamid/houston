-- "palette": a tiny colour scheme in the "astronaut" colours — picked from
-- the desktop wallpaper (orange background, cream fur, dark visor, steel
-- helmet) plus the aqua-blue window glow. Same palette as the Ghostty
-- theme (ghostty/themes/astronaut). No plugin — just highlight groups.
-- The background is left to the terminal, so Neovim blends in with it.
--
-- To change a colour: edit `c` below, then `:colorscheme palette`.

vim.cmd("highlight clear")
vim.g.colors_name = "palette"
-- Dark or light is picked from 'background', which Neovim detects from
-- the terminal's background colour (Ghostty astronaut / astronaut-light).
local light = vim.o.background == "light"

local c = light and {
  fg = "#2a1f1b",      -- dark visor: main text
  grey = "#76695d",    -- comments
  dim = "#a18f80",     -- line numbers, borders
  bg0 = "#f1ead8",     -- terminal background (text on the pills)
  bg1 = "#e6dcc6",     -- current line, status line, popups
  bg2 = "#d6c8ab",     -- selection
  faint = "#c9b99c",   -- indent guides: barely visible
  orange = "#b4541b",
  red = "#b0381a",
  yellow = "#876100",
  green = "#5d6a1c",
  blue = "#2b6b60",
  steel = "#3d5878",
  tan = "#87562f",
} or {
  fg = "#e3dccb",      -- cream fur: main text
  grey = "#8f857a",    -- warm steel: comments
  dim = "#6b5a50",     -- line numbers, borders
  bg0 = "#1c1513",     -- terminal background (text on the pills)
  bg1 = "#2a1f1b",     -- current line, status line, popups
  bg2 = "#3b2c26",     -- selection
  faint = "#463731",   -- indent guides: barely visible
  orange = "#ef8f4c",  -- wallpaper background: spot accent
  red = "#e0603a",     -- arrow on the helmet
  yellow = "#e5c15a",  -- "YORK" sticker
  green = "#b5b07a",   -- olive jacket
  blue = "#7daea3",    -- window glow / bar accent: the main colour
  steel = "#8aa1b8",   -- steel blue of the helmet
  tan = "#d0a07e",     -- leather / warm tan
}

local hl = function(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- ── Editor UI ────────────────────────────────────────────────────────
hl("Normal", { fg = c.fg })                -- no bg: use the terminal's
hl("NormalFloat", { fg = c.fg })                  -- floating windows: transparent
hl("MsgArea", { fg = c.fg })                      -- cmdline box & messages: transparent
hl("FloatBorder", { fg = c.blue })                -- rounded borders: just the blue line
hl("CursorLine", { bg = c.bg1 })
hl("CursorLineNr", { fg = c.orange, bold = true })
hl("LineNr", { fg = c.dim })
hl("SignColumn", {})
hl("ColorColumn", { bg = c.bg1 })
hl("WinSeparator", { fg = c.dim })
hl("Visual", { bg = c.bg2 })
hl("Search", { fg = c.bg1, bg = c.yellow })
hl("IncSearch", { fg = c.bg1, bg = c.orange })
hl("CurSearch", { link = "IncSearch" })
hl("MatchParen", { fg = c.orange, bold = true, underline = true })
hl("NonText", { fg = c.dim })
hl("Whitespace", { fg = c.faint }) -- indent guides & trailing spaces: barely visible
hl("EndOfBuffer", { fg = c.bg1 })
hl("Pmenu", { fg = c.fg, bg = c.bg1 })
hl("PmenuSel", { fg = c.bg1, bg = c.blue, bold = true })
hl("PmenuThumb", { bg = c.dim })
hl("StatusLine", { fg = c.fg })    -- transparent: the pills carry the colour
hl("StatusLineNC", { fg = c.grey })
hl("TabLine", { fg = c.grey, bg = c.bg1 })
hl("TabLineSel", { fg = c.fg, bold = true })
hl("TabLineFill", { bg = c.bg1 })
hl("Title", { fg = c.orange, bold = true })
hl("Directory", { fg = c.blue })
hl("Folded", { fg = c.grey, bg = c.bg1 })
hl("ErrorMsg", { fg = c.red, bold = true })
hl("WarningMsg", { fg = c.yellow })
hl("MoreMsg", { fg = c.green })
hl("Question", { fg = c.blue })

-- status line mode pill (used by the statusline in init.lua)
-- status line pills, same look as the tmux bar (init.lua builds the line).
-- Each pill = body group + "Cap" group for the rounded ends.
local pills = {
  StMode = { c.blue, c.bg0 },        -- NORMAL (like the tmux session)
  StModeInsert = { c.orange, c.bg0 },
  StModeVisual = { c.yellow, c.bg0 },
  StModeCommand = { c.green, c.bg0 },
  StFile = { c.bg2, c.fg },               -- file name (like the current window)
  StInfo = { c.bg1, c.grey },             -- filetype, position
}
for name, p in pairs(pills) do
  hl(name, { fg = p[2], bg = p[1], bold = name:match("^StMode") ~= nil })
  hl(name .. "Cap", { fg = p[1] })
end
hl("StModified", { fg = c.orange, bg = c.bg2 })
-- file icons inside the file pill: tree colours on the pill background
for icon_name, color in pairs({ Blue = c.blue, Steel = c.steel, Yellow = c.yellow,
  Orange = c.orange, Green = c.green, Tan = c.tan, Fg = c.fg, Grey = c.grey, Dir = c.blue }) do
  hl("StIcon" .. icon_name, { fg = color, bg = c.bg2 })
end

-- project tree (lua/tree.lua): a slightly darker side panel
hl("TreeNormal", { fg = c.fg })                   -- transparent, like the editor
hl("TreeCursorLine", { bg = c.bg1 })
hl("TreeRoot", { fg = c.orange, bold = true })
hl("TreeDir", { fg = c.blue, bold = true })
hl("TreeFile", { fg = c.fg })
hl("TreeHidden", { fg = c.grey })
hl("TreeCurrent", { fg = c.orange, bold = true })
hl("TreeGuide", { fg = c.faint })
hl("TreeIconDir", { fg = c.blue })
hl("TreeIconBlue", { fg = c.blue })
hl("TreeIconSteel", { fg = c.steel })
hl("TreeIconYellow", { fg = c.yellow })
hl("TreeIconOrange", { fg = c.orange })
hl("TreeIconGreen", { fg = c.green })
hl("TreeIconTan", { fg = c.tan })
hl("TreeIconFg", { fg = c.fg })
hl("TreeIconGrey", { fg = c.grey })

-- start screen (lua/dashboard.lua)
hl("DashLogo", { fg = "#d6a389" })                -- the identicon, its own colour
hl("DashName", { fg = c.fg, bold = true })
hl("DashText", { fg = c.fg })
hl("DashDim", { fg = c.grey })
hl("DashQuip", { fg = c.grey, italic = true })
hl("DashAccent", { fg = c.orange, bold = true })
hl("DashPrompt", { fg = c.blue, bold = true })
hl("DashCmd", { fg = c.fg, bold = true })
hl("DashKey", { fg = c.orange, bold = true })
hl("DashSpark", { fg = c.blue })
hl("DashNvim", { fg = c.yellow })
hl("DashGh0", { fg = light and "#e0d4bc" or "#3a2c27" })                 -- no contributions
hl("DashGh1", { fg = "#6b4430" })
hl("DashGh2", { fg = "#a35f36" })
hl("DashGh3", { fg = "#d97a3e" })
hl("DashGh4", { fg = c.orange })

-- ── Syntax ───────────────────────────────────────────────────────────
hl("Comment", { fg = c.grey, italic = true })
hl("String", { fg = c.green })
hl("Character", { fg = c.green })
hl("Number", { fg = c.orange })
hl("Boolean", { fg = c.orange, bold = true })
hl("Float", { fg = c.orange })
hl("Constant", { fg = c.orange })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.yellow })
hl("Statement", { fg = c.blue })
hl("Keyword", { fg = c.blue })
hl("Conditional", { fg = c.blue })
hl("Repeat", { fg = c.blue })
hl("Exception", { fg = c.red })
hl("Operator", { fg = c.steel })
hl("PreProc", { fg = c.steel })
hl("Include", { fg = c.blue })
hl("Type", { fg = c.steel })
hl("Special", { fg = c.red })
hl("Delimiter", { fg = c.grey })
hl("Todo", { fg = c.bg1, bg = c.yellow, bold = true })
hl("Error", { fg = c.red })
hl("Underlined", { underline = true })

-- tree-sitter captures (finer-grained than the classic groups above)
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.tan, italic = true })
hl("@variable.parameter", { fg = c.fg, italic = true })
hl("@variable.member", { fg = c.fg })
hl("@property", { fg = c.fg })
hl("@constant", { fg = c.orange })
hl("@constant.builtin", { fg = c.orange, bold = true })
hl("@module", { fg = c.steel })
hl("@function.builtin", { fg = c.yellow, italic = true })
hl("@function.method", { fg = c.yellow })
hl("@constructor", { fg = c.steel })
hl("@keyword.function", { fg = c.blue, italic = true })
hl("@keyword.return", { fg = c.blue, bold = true })
hl("@type.builtin", { fg = c.steel, italic = true })
hl("@tag", { fg = c.blue })
hl("@tag.attribute", { fg = c.yellow })
hl("@tag.delimiter", { fg = c.grey })
hl("@punctuation", { fg = c.grey })
hl("@string.escape", { fg = c.red })
hl("@string.special", { fg = c.steel })
hl("@markup.heading", { fg = c.orange, bold = true })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.link", { fg = c.blue, underline = true })
hl("@markup.raw", { fg = c.green })
hl("@markup.list", { fg = c.blue })

-- ── Diagnostics & diffs (for later, when you add LSP) ────────────────
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.yellow })
hl("DiagnosticInfo", { fg = c.blue })
hl("DiagnosticHint", { fg = c.steel })
hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
hl("DiffAdd", { fg = c.green })
hl("DiffChange", { fg = c.yellow })
hl("DiffDelete", { fg = c.red })
hl("Added", { fg = c.green })
hl("Changed", { fg = c.yellow })
hl("Removed", { fg = c.red })
