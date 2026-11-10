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

-- Light = palette/astronaut-light.json, roles as in the Obsidian theme
-- (palette/obsidian-colors.md): emerald links/keywords, navy types and h1,
-- pine h2, gold h3, sky external links, night cards for floats.
local c = light and {
  fg = "#2a1f1b",      -- ink: main text
  grey = "#6e6155",    -- stone: comments
  dim = "#8f8276",     -- ash: line numbers, borders
  bg0 = "#f1ead8",     -- cream: terminal background (text on the pills)
  bg1 = "#e6dcc6",     -- linen: current line, status line, popups
  bg2 = "#d6c8ab",     -- sand: pills, active items
  faint = "#c9b99c",   -- dune: indent guides, barely visible
  orange = "#b4541b",  -- ember
  red = "#b0381a",     -- rust
  yellow = "#765500",  -- mustard
  green = "#5d6a1c",   -- olive
  blue = "#1f6b5c",    -- emerald
  steel = "#1e3a5f",   -- navy
  tan = "#87562f",
  -- the rest of the Obsidian roles
  bold = "#3b2c26",    -- espresso
  pine = "#134b40",
  sky = "#2f64a0",
  gold = "#8c6a12",
  brass = "#c49a3a",
  glow = "#7daea3",
  mint = "#cfe3d6",
  peach = "#f0c9a0",
  butter = "#f2dc8f",
  select = "#f1d4b9",  -- text selection: flame 28% on paper
  card = "#1c1513",    -- night: dark cards (floats, popup menu)
  card_fg = "#e3dccb",
  card_sel = "#3b2c26",
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
  bold = "#f1ead8",
  pine = "#98c4ba",
  sky = "#8aa1b8",
  gold = "#e5c15a",
  brass = "#c49a3a",
  glow = "#7daea3",
  mint = "#24332e",
  peach = "#4a3324",
  butter = "#4f421c",
  select = "#3b2c26",
  card = "#2a1f1b",
  card_fg = "#e3dccb",
  card_sel = "#463731",
}

local hl = function(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- ── Editor UI ────────────────────────────────────────────────────────
hl("Normal", { fg = c.fg })                -- no bg: use the terminal's
hl("NormalFloat", { fg = c.fg })                  -- floating windows: transparent
hl("MsgArea", { fg = c.fg })                      -- cmdline box & messages: transparent
hl("FloatBorder", { fg = c.glow })                -- rounded borders: the aqua window glow
hl("FloatTitle", { fg = c.orange, bold = true })  -- title in the top border
hl("FloatFooter", { fg = c.dim })                 -- key hints in the bottom border
-- path above the code: project › src › file (init.lua builds it)
hl("WinBar", { fg = c.dim })
hl("WinBarNC", { fg = c.dim })
hl("WinBarSep", { fg = c.faint })
hl("WinBarFile", { fg = c.fg })
hl("WinBarModified", { fg = c.orange })
-- the "file written" message
hl("MsgSaved", { fg = c.green })
hl("MsgSavedFile", { fg = c.fg })
hl("MsgSavedInfo", { fg = c.dim })
hl("CursorLine", { bg = c.bg1 })
hl("CursorLineNr", { fg = c.orange, bold = true })
hl("LineNr", { fg = c.dim })
hl("SignColumn", {})
hl("ColorColumn", { bg = c.bg1 })
hl("WinSeparator", { fg = c.dim })
hl("Visual", { bg = c.select })                  -- like text selection in Obsidian
hl("Search", { fg = c.fg, bg = c.butter })       -- like ==highlight==
hl("IncSearch", { fg = c.bg1, bg = c.orange })
hl("CurSearch", { link = "IncSearch" })
hl("MatchParen", { fg = c.orange, bold = true, underline = true })
hl("NonText", { fg = c.dim })
hl("Whitespace", { fg = c.faint }) -- indent guides & trailing spaces: barely visible
hl("EndOfBuffer", { fg = c.bg1 })
-- popup menu: a dark night card, like code blocks in Obsidian
hl("Pmenu", { fg = c.card_fg, bg = c.card })
hl("PmenuSel", { fg = c.card_fg, bg = c.card_sel, bold = true })
hl("PmenuKind", { fg = c.glow, bg = c.card })
hl("PmenuExtra", { fg = c.dim, bg = c.card })
hl("PmenuSbar", { bg = c.card })
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
hl("TreeRoot", { fg = c.orange })
hl("TreeDir", { fg = c.blue })                     -- one weight everywhere: colour, not bold
hl("TreeFile", { fg = c.fg })
hl("TreeHidden", { fg = c.grey })
hl("TreeCurrent", { fg = c.orange })
hl("TreeGuide", { fg = c.faint })
hl("TreeIconDir", { fg = c.blue })              -- closed folder: emerald
hl("TreeIconDirOpen", { fg = c.orange })         -- open folder: ember, as in Obsidian
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
hl("Operator", { fg = c.sky })
hl("PreProc", { fg = c.steel })
hl("Include", { fg = c.blue })
hl("Type", { fg = c.steel })
hl("Special", { fg = c.red })
hl("Delimiter", { fg = c.dim })
hl("Todo", { fg = c.fg, bg = c.butter, bold = true })
hl("Error", { fg = c.red })
hl("Underlined", { underline = true })

-- tree-sitter captures (finer-grained than the classic groups above)
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.tan, italic = true })
hl("@variable.parameter", { fg = c.fg, italic = true })
hl("@variable.member", { fg = c.fg })
hl("@property", { fg = c.pine })
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
hl("@tag.attribute", { fg = c.gold })
hl("@tag.delimiter", { fg = c.grey })
hl("@punctuation", { fg = c.dim })
hl("@string.escape", { fg = c.red })
hl("@string.special", { fg = c.sky })
-- Markdown: the Obsidian look (headings navy → pine → gold → ember → tan → stone)
hl("@markup.heading", { fg = c.orange, bold = true })
for level, color in ipairs({ c.steel, c.pine, c.gold, c.orange, c.tan, c.grey }) do
  hl("@markup.heading." .. level .. ".markdown", { fg = color, bold = true })
  hl("@markup.heading." .. level .. ".marker.markdown", { fg = c.faint, bold = true })
end
hl("@markup.strong", { fg = c.bold, bold = true })
hl("@markup.italic", { fg = c.tan, italic = true })
hl("@markup.strikethrough", { fg = c.dim, strikethrough = true })
hl("@markup.quote", { fg = c.tan })
hl("@markup.link", { fg = c.blue, underline = true })
hl("@markup.link.label", { fg = c.blue })                     -- [text]
hl("@markup.link.url", { fg = c.sky, underline = true })      -- (https://…)
hl("@markup.raw", { fg = c.red })                            -- `inline code`: rust
hl("@markup.raw.block", { fg = c.fg })                        -- fenced code body
hl("@markup.list", { fg = c.orange })                         -- - * 1. markers: ember
hl("@markup.list.checked", { fg = c.green })                  -- [x]
hl("@markup.list.unchecked", { fg = c.orange })               -- [ ]
hl("@punctuation.special.markdown", { fg = c.brass })         -- > of a quote, --- rule
hl("@label.markdown", { fg = c.dim, italic = true })          -- ```lang
-- extras drawn by after/ftplugin/markdown.lua
hl("MdWikiLink", { fg = c.blue, underline = true, sp = c.glow })
hl("MdHighlight", { fg = c.fg, bg = c.butter })
hl("MdTag", { fg = c.pine, bg = c.mint })
hl("MdQuoteBar", { fg = c.brass })
-- callouts > [!type]: one colour family each, as in Obsidian.
-- MdCallout<Type> = title, MdCallout<Type>Bar = the > markers of the block.
local callouts = light and {
  Note = "#24578f", Info = c.sky, Tip = c.blue, Success = c.green, Question = c.gold,
  Warning = c.orange, Fail = c.red, Example = c.steel, Quote = c.tan, Summary = "#56616b",
} or {
  Note = "#8aa1b8", Info = c.sky, Tip = c.blue, Success = c.green, Question = c.gold,
  Warning = c.orange, Fail = c.red, Example = "#98a8c8", Quote = c.tan, Summary = c.grey,
}
for name, color in pairs(callouts) do
  hl("MdCallout" .. name, { fg = color, bold = true })
  hl("MdCallout" .. name .. "Bar", { fg = color })
end

-- ── Reading view (lua/mdview.lua): the Obsidian theme, cell by cell ────
-- colour a over the background, like Obsidian's rgba(...) on the page
local function mix(fg, a, bg)
  local function ch(h, i) return tonumber(h:sub(i, i + 1), 16) end
  bg = bg or c.bg0
  local out = "#"
  for i = 2, 6, 2 do
    out = out .. string.format("%02x", math.floor(ch(fg, i) * a + ch(bg, i) * (1 - a) + 0.5))
  end
  return out
end
hl("MdvTitle", { fg = c.steel, bold = true })                -- inline title = file name
hl("MdvText", { fg = c.fg })
hl("MdvBold", { fg = c.bold, bold = true })
hl("MdvItalic", { fg = c.tan, italic = true })
hl("MdvStrike", { fg = c.dim, strikethrough = true })
hl("MdvMark", { fg = c.fg, bg = c.butter })                  -- ==highlight==
hl("MdvCode", { fg = c.red, bg = c.bg1 })                    -- `inline code`: rust on linen
hl("MdvWiki", { fg = c.blue, underline = true, sp = mix(c.blue, 0.35) })
hl("MdvLink", { fg = c.sky, underline = true, sp = mix(c.sky, 0.35) })
hl("MdvLinkIcon", { fg = c.sky })
hl("MdvTag", { fg = c.pine, bg = c.mint })                   -- #tag pill
hl("MdvTagCap", { fg = c.mint })
for level, color in ipairs({ c.steel, c.pine, c.gold, c.grey, c.tan, c.grey }) do
  hl("MdvH" .. level, { fg = color, bold = true })
end
hl("MdvH2Rule", { fg = c.brass })                            -- gilded hairline under h2
hl("MdvH3Mark", { fg = c.brass })                            -- ◆ before h3
hl("MdvBullet", { fg = c.orange })
hl("MdvTaskOpen", { fg = c.orange })
hl("MdvTaskDone", { fg = c.green })
hl("MdvDoneText", { fg = c.dim, strikethrough = true })
hl("MdvQuoteBar", { fg = c.brass })
hl("MdvQuote", { fg = c.grey })
hl("MdvHr", { fg = c.faint })
hl("MdvCaption", { fg = c.grey, italic = true })
hl("MdvEmbedBar", { fg = c.blue })
hl("MdvEmbedTitle", { fg = c.dim, bold = true })
hl("MdvPropBorder", { fg = c.faint })
hl("MdvPropTitle", { fg = c.dim, bold = true })
hl("MdvPropKey", { fg = c.dim })
hl("MdvPropVal", { fg = c.fg })
hl("MdvTableHead", { fg = c.dim, bold = true })
hl("MdvTableRule", { fg = c.bg2 })
-- code card: night, with the dark syntax colours of Obsidian's code blocks
local card = { fg = "#e3dccb", cm = "#8f857a", fn = "#e5c15a", kw = "#7daea3", op = "#98c4ba", prop = "#c49a3a",
  punct = "#a18f80", str = "#b5b07a", type = "#8aa1b8", num = "#ef8f4c", imp = "#f07a52" }
hl("MdvCard", { fg = card.fg, bg = c.card })
hl("MdvCardEdge", { fg = c.card })
hl("MdvCardLang", { fg = card.cm, bg = c.card, italic = true })
for name, color in pairs({ Kw = card.kw, Fn = card.fn, Str = card.str, Num = card.num, Type = card.type,
  Op = card.op, Punct = card.punct, Prop = card.prop, Imp = card.imp }) do
  hl("MdvCard" .. name, { fg = color, bg = c.card })
end
hl("MdvCardCm", { fg = card.cm, bg = c.card, italic = true })
-- callouts: background 7 %, bar 85 %, title in the full colour
for name, color in pairs(callouts) do
  local bg = mix(color, light and 0.07 or 0.12)
  hl("MdvCallout" .. name .. "Bg", { bg = bg })
  hl("MdvCallout" .. name .. "Bar", { fg = mix(color, 0.85), bg = bg })
  hl("MdvCallout" .. name .. "Title", { fg = color, bg = bg, bold = true })
end

-- ── Diagnostics & diffs (for later, when you add LSP) ────────────────
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.yellow })
hl("DiagnosticInfo", { fg = c.sky })
hl("DiagnosticHint", { fg = c.blue })
hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
-- diffs (diffview, neogit, :diffthis): tinted lines, like Obsidian's callouts
hl("DiffAdd", { bg = mix(c.green, 0.16) })
hl("DiffChange", { bg = mix(c.yellow, 0.10) })
hl("DiffText", { bg = mix(c.yellow, 0.26) })
hl("DiffDelete", { fg = mix(c.red, 0.5), bg = mix(c.red, 0.10) })
hl("Added", { fg = c.green })
hl("Changed", { fg = c.yellow })
hl("Removed", { fg = c.red })

-- ── Language servers, git, SQL ───────────────────────────────────────
hl("DiagnosticOk", { fg = c.green })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.sky })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.blue })
hl("DiagnosticVirtualTextError", { fg = c.red, italic = true })
hl("DiagnosticVirtualTextWarn", { fg = c.yellow, italic = true })
hl("DiagnosticVirtualTextInfo", { fg = c.sky, italic = true })
hl("DiagnosticVirtualTextHint", { fg = c.dim, italic = true })
hl("LspReferenceText", { bg = c.bg1 })
hl("LspReferenceRead", { bg = c.bg1 })
hl("LspReferenceWrite", { bg = c.bg1, underline = true })
hl("LspSignatureActiveParameter", { fg = c.orange, bold = true })

-- gitsigns: olive added, mustard changed, rust removed
hl("GitSignsAdd", { fg = c.green })
hl("GitSignsChange", { fg = c.yellow })
hl("GitSignsDelete", { fg = c.red })
hl("GitSignsUntracked", { fg = c.dim })

-- neogit: emerald headings, pine branches, sky remotes, peach cursor line
hl("NeogitSectionHeader", { fg = c.orange, bold = true })
hl("NeogitBranch", { fg = c.pine, bold = true })
hl("NeogitBranchHead", { fg = c.pine, bold = true, underline = true })
hl("NeogitRemote", { fg = c.sky, bold = true })
hl("NeogitObjectId", { fg = c.dim })
hl("NeogitStash", { fg = c.tan })
hl("NeogitFold", { fg = c.dim })
hl("NeogitChangeModified", { fg = c.yellow, bold = true })
hl("NeogitChangeAdded", { fg = c.green, bold = true })
hl("NeogitChangeDeleted", { fg = c.red, bold = true })
hl("NeogitChangeRenamed", { fg = c.tan, bold = true })
hl("NeogitChangeNewFile", { fg = c.green, bold = true })
hl("NeogitHunkHeader", { fg = c.grey, bg = c.bg1 })
hl("NeogitHunkHeaderHighlight", { fg = c.fg, bg = c.bg2, bold = true })
hl("NeogitDiffContext", { fg = c.fg })
hl("NeogitDiffContextHighlight", { fg = c.fg, bg = mix(c.dim, 0.08) })
hl("NeogitDiffAdd", { fg = c.green, bg = mix(c.green, 0.10) })
hl("NeogitDiffAddHighlight", { fg = c.green, bg = mix(c.green, 0.18) })
hl("NeogitDiffDelete", { fg = c.red, bg = mix(c.red, 0.08) })
hl("NeogitDiffDeleteHighlight", { fg = c.red, bg = mix(c.red, 0.15) })
hl("NeogitCursorLine", { bg = c.select })
hl("NeogitGraphAuthor", { fg = c.tan })
hl("NeogitGraphOrange", { fg = c.orange })
hl("NeogitGraphGreen", { fg = c.green })
hl("NeogitGraphBlue", { fg = c.sky })
hl("NeogitGraphYellow", { fg = c.yellow })
hl("NeogitGraphRed", { fg = c.red })
hl("NeogitGraphCyan", { fg = c.blue })
hl("NeogitGraphPurple", { fg = c.steel })
hl("NeogitGraphGray", { fg = c.dim })
hl("NeogitPopupSectionTitle", { fg = c.orange, bold = true })
hl("NeogitPopupActionKey", { fg = c.blue, bold = true })
hl("NeogitPopupSwitchKey", { fg = c.sky })
hl("NeogitPopupOptionKey", { fg = c.sky })

-- which-key: ember keys, emerald groups, quiet separators, glow frame
hl("WhichKey", { fg = c.orange, bold = true })
hl("WhichKeyGroup", { fg = c.blue })
hl("WhichKeyDesc", { fg = c.fg })
hl("WhichKeySeparator", { fg = c.faint })
hl("WhichKeyValue", { fg = c.dim })
hl("WhichKeyNormal", { fg = c.fg })
hl("WhichKeyBorder", { fg = c.glow })
hl("WhichKeyTitle", { fg = c.orange, bold = true })

-- dadbod-ui: databases emerald like folders, tables ink
hl("NotificationInfo", { fg = c.green })
hl("NotificationWarning", { fg = c.yellow })
hl("NotificationError", { fg = c.red })
hl("dbui_tables", { fg = c.fg })
hl("dbui_connection_ok", { fg = c.green })
hl("dbui_connection_error", { fg = c.red })
hl("dbui_help", { fg = c.dim })

-- the terminal inside Neovim (lazydocker, harlequin, :terminal): the
-- Ghostty palette, so programs look the same in and out of the editor
local ansi = light and {
  "#2a1f1b", "#b0381a", "#5d6a1c", "#765500", "#2f64a0", "#87562f", "#1f6b5c", "#56616b",
  "#6e6155", "#b4541b", "#134b40", "#8c6a12", "#1e3a5f", "#3b2c26", "#24578f", "#8f8276",
} or {
  "#1c1513", "#e0603a", "#b5b07a", "#e5c15a", "#8aa1b8", "#d0a07e", "#7daea3", "#e3dccb",
  "#6b5a50", "#ef8f4c", "#c9c48e", "#f0d27a", "#a8bccf", "#e0b896", "#98c4ba", "#f1ead8",
}
for i, color in ipairs(ansi) do
  vim.g["terminal_color_" .. (i - 1)] = color
end
