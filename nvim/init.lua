-- Minimal Neovim config. No autocompletion — you write the code yourself,
-- that is how it sticks. Language servers only check it (underline, a
-- note on the current line) and answer questions (K, gd). A handful of
-- plugins: git, SQL, auto-closing brackets. C is run through clang-format
-- on save (after/ftplugin/c.lua).
--
--   init.lua                 — everything that applies to all files
--   after/ftplugin/<ft>.lua  — per-language settings (indent width, how
--                              <leader>r runs the file, …)
--   lsp/<server>.lua         — one file per language server
--   lua/lsp_setup.lua        — which servers run, diagnostics, LSP keys
--   lua/plugins.lua          — the plugins (vim.pack) and their keys
--   lua/tree.lua             — the project tree (<leader>e)
--   lua/mdview.lua           — Markdown reading view (<leader>p)
--   colors/palette.lua       — the colour scheme

-- ── Leader ───────────────────────────────────────────────────────────
-- Must be set before any mapping that uses <leader>.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Options ──────────────────────────────────────────────────────────
local opt = vim.opt

opt.number = true             -- line numbers
opt.relativenumber = true     -- relative numbers: easy `5j`, `12k`
opt.cursorline = true         -- highlight the current line
opt.signcolumn = "yes"        -- keep a fixed column on the left
opt.scrolloff = 6             -- keep lines visible above/below the cursor
opt.sidescrolloff = 8
opt.wrap = false

-- defaults; each language overrides them in after/ftplugin/, and a
-- project's .editorconfig (supported out of the box) overrides both
opt.expandtab = true          -- spaces instead of tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.smartindent = true

opt.ignorecase = true         -- search ignores case...
opt.smartcase = true          -- ...unless you type a capital letter

opt.splitright = true         -- :vsplit opens on the right
opt.splitbelow = true         -- :split opens below
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- y / p use the macOS clipboard
opt.undofile = true           -- undo history survives closing the file
opt.swapfile = false          -- no .swp files / "swapfile exists" warnings
opt.updatetime = 250
opt.termguicolors = true      -- 24-bit colours (Ghostty supports them)
opt.showmode = false          -- the mode is shown in the status line
opt.confirm = true            -- ask to save instead of refusing to quit
opt.winborder = "rounded"     -- every floating window: thin rounded frame, no fill

-- tabs, trailing spaces and indent guides (the "│" every indent level)
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- folds by indentation (YAML, Python…), all open by default.
-- za = toggle fold, zM = close all, zR = open all
opt.foldmethod = "indent"
opt.foldlevel = 99

-- ── Finding things (built in, no plugins) ───────────────────────────
opt.path:append("**")         -- :find searches the whole project
opt.wildignore:append({ "*/.git/*", "*/node_modules/*", "*/.venv/*", "*/__pycache__/*", "*.o", "*.pyc" })
opt.wildmode = "longest:full,full"
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob=!.git"
opt.grepformat = "%f:%l:%c:%m"

-- netrw (built-in browser, :Explore): no banner, tree view, no ./ and ../
-- The project tree on <leader>e is lua/tree.lua.
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_list_hide = [[^\.\.\=/\=$]]
vim.g.netrw_hide = 1

-- ── File types ───────────────────────────────────────────────────────
-- fix what Neovim guesses wrong for this stack
vim.filetype.add({
  extension = {
    h = "c",                  -- C headers, not C++
    tf = "terraform",         -- not TinyFugue
    tfvars = "terraform",
    j2 = "jinja",             -- Ansible / Jinja templates
    nginx = "nginx",
  },
  -- compound types: YAML highlighting + the right language server on top
  filename = {
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
  pattern = {
    [".*/nginx/.*%.conf"] = "nginx",
    [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
    [".*/playbooks?/.*%.ya?ml"] = "yaml.ansible",
    ["playbook.*%.ya?ml"] = "yaml.ansible",
    -- Helm: a template inside a chart (a Chart.yaml somewhere above)
    [".*/templates/.*%.ya?ml"] = function(path)
      return vim.fs.find("Chart.yaml", { upward = true, path = vim.fs.dirname(path) })[1] and "helm" or nil
    end,
    [".*/templates/.*%.tpl"] = "helm",
  },
})

-- language servers (lsp/*.lua, lua/lsp_setup.lua) and the few plugins
-- (lua/plugins.lua): git, SQL, auto-closing brackets
require("lsp_setup")
require("plugins")

-- ── Keymaps ──────────────────────────────────────────────────────────
local map = vim.keymap.set

map("n", "<leader>w", "<cmd>silent write<cr>", { desc = "Сохранить" })
-- plain :w is silent too: the BufWritePost message (● file · N строк) replaces
-- Neovim's '"file" 18L, 412B written'
vim.cmd([[cnoreabbrev <expr> w (getcmdtype() == ':' && getcmdline() == 'w') ? 'silent w' : 'w']])
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Закрыть окно" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Убрать подсветку поиска" })
map("n", "<leader>e", function() require("tree").toggle() end, { desc = "Дерево проекта" })

-- finding: file by name, text in the project, open buffers
map("n", "<leader>f", ":find ", { desc = "Найти файл (Tab дополняет)" })
map("n", "<leader>g", ":silent grep! ", { desc = "Найти текст в проекте" })
map("n", "<leader>b", ":ls<cr>:buffer ", { desc = "Открытые файлы" })
-- grep results open in the quickfix list: ]q / [q jump between them
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "grep",
  command = "cwindow",
})

-- move between splits with Ctrl-h/j/k/l; at the edge of Neovim the same
-- keys jump on to the next tmux pane (tmux side: vim-tmux-navigator)
local function navigate(dir)
  local win = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(dir)
  if vim.env.TMUX and win == vim.api.nvim_get_current_win() then
    local pane = ({ h = "L", j = "D", k = "U", l = "R" })[dir]
    vim.fn.system({ "tmux", "select-pane", "-" .. pane })
  end
end
map("n", "<C-h>", function() navigate("h") end, { desc = "Окно / панель слева" })
map("n", "<C-j>", function() navigate("j") end, { desc = "Окно / панель ниже" })
map("n", "<C-k>", function() navigate("k") end, { desc = "Окно / панель выше" })
map("n", "<C-l>", function() navigate("l") end, { desc = "Окно / панель справа" })

-- resize the current split with Shift + arrows (Ctrl-w = makes them equal)
map("n", "<S-Left>", "<cmd>vertical resize -4<cr>", { desc = "Окно уже" })
map("n", "<S-Right>", "<cmd>vertical resize +4<cr>", { desc = "Окно шире" })
map("n", "<S-Up>", "<cmd>resize +2<cr>", { desc = "Окно выше" })
map("n", "<S-Down>", "<cmd>resize -2<cr>", { desc = "Окно ниже" })

-- move selected lines up/down, keep the selection
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Строки вниз" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Строки вверх" })

-- keep the selection when indenting with < and >
map("v", "<", "<gv")
map("v", ">", ">gv")

-- paste over a selection without losing what you copied
map("x", "p", "P", { desc = "Вставить, не теряя скопированное" })

-- keep the cursor in the middle when jumping half pages / through search
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- ── Terminal & running code ──────────────────────────────────────────
-- <leader>t: a terminal at the bottom. Esc Esc leaves terminal mode.
map("n", "<leader>t", "<cmd>botright 12split | terminal<cr>", { desc = "Терминал снизу" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Выйти из ввода терминала" })

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.list = false
    -- read-only outputs (Markdown preview) are not typed into
    if not vim.b[args.buf].no_insert then
      vim.cmd.startinsert()
    end
  end,
})

-- Save the file and run `cmd` in a terminal split at the bottom. Each
-- language sets what <leader>r runs in after/ftplugin/<ft>.lua.
function _G.run_in_terminal(cmd)
  vim.cmd.write()
  vim.cmd("botright 12split")
  vim.cmd.terminal(cmd)
end

-- ── Autocommands ─────────────────────────────────────────────────────
-- briefly highlight what you just yanked
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- reopen a file where you left it
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- strip trailing spaces on save (not in Markdown: two spaces = line break)
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    if vim.bo.filetype ~= "markdown" then
      local view = vim.fn.winsaveview()
      vim.cmd([[keeppatterns %s/\s\+$//e]])
      vim.fn.winrestview(view)
    end
  end,
})

-- indent guides: a "│" at every indent level, following the buffer's
-- shiftwidth (2 in YAML, 4 in Python…)
local function indent_guides()
  local sw = vim.fn.shiftwidth()
  vim.opt_local.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    leadmultispace = "│" .. string.rep(" ", sw - 1),
  }
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  callback = function()
    vim.schedule(indent_guides) -- after after/ftplugin has set shiftwidth
  end,
})
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = { "shiftwidth", "tabstop" },
  callback = indent_guides,
})

-- ── Syntax highlighting ──────────────────────────────────────────────
-- Neovim ships tree-sitter parsers for Lua, C, Vimscript, Markdown and
-- help files: those get precise highlighting. Every other language uses
-- Neovim's built-in regex syntax, coloured by the same theme.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- ── Look ─────────────────────────────────────────────────────────────
vim.cmd.colorscheme("palette")
-- Neovim learns the terminal's background (dark astronaut / cream
-- astronaut-light) a moment after start: reload the palette to match
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function() vim.cmd.colorscheme("palette") end,
})

-- start screen: a small personal profile instead of the Neovim intro
-- (lua/dashboard.lua); lua/activity.lua counts editing time for it
require("activity").setup()
require("dashboard").setup()

-- Status line in the tmux bar's style: rounded pills on a transparent
-- background.   ( NORMAL ) (  file ● )            ( filetype ) ( 26:1  14% )
-- Colours: StMode* / StFile / StInfo in colors/palette.lua.
local L, R = "\u{e0b6}", "\u{e0b4}" -- rounded pill ends (Nerd Font)

local modes = {
  n = { "NORMAL", "StMode" },
  i = { "INSERT", "StModeInsert" },
  v = { "VISUAL", "StModeVisual" },
  V = { "V-LINE", "StModeVisual" },
  ["\22"] = { "V-BLOCK", "StModeVisual" },
  c = { "COMMAND", "StModeCommand" },
  R = { "REPLACE", "StModeInsert" },
  t = { "TERMINAL", "StModeInsert" },
}

local function pill(group, text)
  return "%#" .. group .. "Cap#" .. L .. "%#" .. group .. "#" .. text .. "%#" .. group .. "Cap#" .. R .. "%*"
end

-- icon + name of what is in the window (not "term://~/…//73894:/bin/sh")
local function file_part()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "dashboard" then
    return "%#StIconTan#\u{f007} %#StFile#profile"
  elseif vim.b[buf].no_insert then
    return "%#StIconBlue#\u{f02d} %#StFile#reading"
  elseif vim.bo[buf].buftype == "terminal" then
    return "%#StIconGreen#\u{f120} %#StFile#terminal"
  elseif vim.bo[buf].filetype == "tree" then
    return "%#StIconDir#\u{f07c} %#StFile#project"
  end
  local name = vim.fn.expand("%:t")
  if name == "" then
    return "%#StFile#[new file]"
  end
  local icon, color = require("tree").file_icon(name)
  local modified = vim.bo[buf].modified and " %#StModified#\u{25cf}" or ""
  return "%#StIcon" .. color .. "#" .. icon .. " %#StFile#" .. vim.fn.expand("%:~:."):gsub("%%", "%%%%") .. modified
end

function _G.statusline()
  local m = modes[vim.fn.mode():sub(1, 1)] or modes.n
  -- filetype pill only for real files (not terminal / reading view / tree)
  local is_file = vim.bo.buftype == "" and vim.bo.filetype ~= "tree"
  local is_dashboard = vim.bo.filetype == "dashboard"
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
  -- no padding at the edges: pills sit flush, like the tmux bar
  return table.concat({
    pill(m[2], " " .. m[1] .. " "),
    " ",
    -- the file pill: its parts set their own colours, so build it by hand
    "%#StFileCap#" .. L .. "%#StFile# " .. file_part() .. " %#StFileCap#" .. R .. "%*",
    "%=",
    is_file and (pill("StInfo", " " .. ft .. " ") .. " ") or "",
    is_dashboard and "" or pill("StInfo", " %l:%c  %p%% "),
  })
end

opt.statusline = "%!v:lua.statusline()"
opt.laststatus = 3 -- one status line for all splits

-- Path above the code (winbar):   project › src › ● telemetry.c ●
-- Only for real files; the tree, terminal and reading view keep the row free.
function _G.winbar()
  local path = vim.fn.expand("%:~:.")
  if path == "" then
    return ""
  end
  local parts = vim.split(path, "/", { plain = true })
  local name = table.remove(parts)
  local icon, color = require("tree").file_icon(name)
  -- inside the project: start from its name; elsewhere the path speaks for itself
  local inside = not path:match("^[~/]")
  local crumbs = { "%#WinBar# " .. (inside and vim.fn.fnamemodify(vim.fn.getcwd(), ":t") or table.remove(parts, 1)) }
  for _, dir in ipairs(parts) do
    crumbs[#crumbs + 1] = dir
  end
  local modified = vim.bo.modified and " %#WinBarModified#\u{25cf}" or ""
  return table.concat(crumbs, " %#WinBarSep#›%#WinBar# ")
    .. " %#WinBarSep#›%#TreeIcon" .. color .. "# " .. icon .. " %#WinBarFile#"
    .. name:gsub("%%", "%%%%") .. modified
end
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    local normal = vim.bo[args.buf].buftype == "" and vim.bo[args.buf].filetype ~= "tree"
      and vim.api.nvim_win_get_config(0).relative == ""
    vim.wo.winbar = normal and "%!v:lua.winbar()" or ""
  end,
})

-- "file written" as one quiet line:   ● telemetry.c · 18 строк · 0.4 КБ
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(args)
    local size = vim.fn.getfsize(args.file)
    local kb = size < 1024 and (size .. " Б") or string.format("%.1f КБ", size / 1024)
    local n = vim.api.nvim_buf_line_count(args.buf)
    local word = (n % 10 == 1 and n % 100 ~= 11) and "строка"
      or (n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14)) and "строки" or "строк"
    -- scheduled: the write itself runs under :silent (see <leader>w and :w)
    vim.schedule(function() vim.api.nvim_echo({
      { "\u{25cf} ", "MsgSaved" },
      { vim.fn.fnamemodify(args.file, ":t"), "MsgSavedFile" },
      { " · " .. n .. " " .. word .. " · " .. kb, "MsgSavedInfo" },
    }, false, {}) end)
  end,
})

-- No command line row at the bottom: ':' and '/' open the input only while
-- you type, messages pop up in a small window and fade after 4 s.
-- ui2 is Neovim 0.12's built-in (experimental) messages/cmdline UI.
opt.cmdheight = 0
local ok_ui2, ui2 = pcall(require, "vim._core.ui2")
if ok_ui2 then
  ui2.enable({ enable = true, msg = { targets = "msg", msg = { timeout = 4000 } } })

  -- Messages in the top-right corner, right under the tmux pills (ui2 puts
  -- them bottom-right above the status line). Wraps ui2's positioning
  -- function; pcall: if a future Neovim renames it, they just stay below.
  pcall(function()
    local msgs = require("vim._core.ui2.messages")
    local set_pos = msgs.set_pos
    msgs.set_pos = function(tgt)
      set_pos(tgt)
      local win = ui2.wins and ui2.wins.msg
      if (tgt == nil or tgt == "msg") and win and vim.api.nvim_win_is_valid(win)
        and not vim.api.nvim_win_get_config(win).hide then
        vim.api.nvim_win_set_config(win, { relative = "editor", anchor = "NE", row = 0, col = vim.o.columns })
      end
    end
  end)

  -- Put the ':' / '/' input in a centred box (like a command palette)
  -- instead of the bottom row. Uses ui2's internal window handle, so it is
  -- wrapped in pcall: if a future Neovim changes ui2, input just stays at
  -- the bottom.
  local function center_cmdline()
    local win = ui2.wins and ui2.wins.cmd
    if not (win and vim.api.nvim_win_is_valid(win)) then
      return
    end
    local width = math.min(70, vim.o.columns - 8)
    pcall(vim.api.nvim_win_set_config, win, {
      relative = "editor",
      row = math.floor(vim.o.lines * 0.3),
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      border = "rounded",
      -- the box says what it is for, like the title of an Obsidian prompt
      title = ({ [":"] = " команда ", ["/"] = " поиск ", ["?"] = " поиск " })[vim.fn.getcmdtype()],
      title_pos = "left",
    })
  end
  vim.api.nvim_create_autocmd({ "VimEnter", "VimResized", "CmdlineEnter" }, {
    callback = function()
      vim.schedule(center_cmdline)
    end,
  })
end
