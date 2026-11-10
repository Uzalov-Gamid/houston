-- The only plugins, installed by Neovim's own vim.pack (no plugin manager).
-- First start after adding one: Neovim asks to install it — answer y.
-- Update all: :lua vim.pack.update()   (versions pinned in nvim-pack-lock.json)
--
--   which-key      press Space (or g, ], [, z, Ctrl-w) and wait: a window lists the keys
--   mini.pairs     ( [ { " ' ` close themselves, Enter between {} opens the body
--   gitsigns       │ marks of changed lines, stage / preview a hunk, blame
--   neogit         git control panel (status, stage, commit, push, log)
--   diffview       side-by-side diff of the working tree / a commit
--   vim-dadbod(-ui) SQL: databases, tables, run a query from a .sql buffer
--
-- Outside Neovim, in a floating frame: lazydocker (containers), harlequin
-- (SQL client). Keys are listed in nvim/README.md.
-- headless runs (scripts, checks) skip plugins: the install prompt would hang them
if #vim.api.nvim_list_uis() == 0 then
  return
end

local ok_pack = pcall(vim.pack.add, {
  "https://github.com/folke/which-key.nvim",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/nvim-lua/plenary.nvim", -- needed by neogit
  "https://github.com/sindrets/diffview.nvim",
  "https://github.com/NeogitOrg/neogit",
  "https://github.com/tpope/vim-dadbod",
  "https://github.com/kristijanhusak/vim-dadbod-ui",
})
if not ok_pack then
  return
end

local map = vim.keymap.set

-- ── Key hints ────────────────────────────────────────────────────────
-- Space and a pause → every <leader> key with its description (the desc of
-- each mapping, written in Russian); also g, ], [, z, Ctrl-w. Space ? — the
-- keys that work only in this buffer (tree, reading view, language server).
pcall(function()
  local wk = require("which-key")
  wk.setup({
    preset = "helix",
    delay = 200,
    icons = { mappings = false, separator = "\u{203a}", group = "" },
    win = { border = "rounded", title = true, title_pos = "left", padding = { 1, 2 } },
    spec = {
      { "<leader>h", group = "git: изменения" },
      { "<leader>?", function() wk.show({ global = false }) end, desc = "Клавиши этого файла" },
      { "g", group = "переходы" },
      { "]", group = "следующее" },
      { "[", group = "предыдущее" },
      { "z", group = "сворачивание и вид" },
      { "<C-w>", group = "окна" },
      -- Neovim's own keys, signed in Russian
      { "K", desc = "Что это (описание)" },
      { "grn", desc = "Переименовать везде" },
      { "grr", desc = "Где используется" },
      { "gra", desc = "Исправить / действие по месту" },
      { "gri", desc = "Реализации" },
      { "grt", desc = "Определение типа" },
      { "gO", desc = "Символы файла" },
      { "]d", desc = "Следующая ошибка" },
      { "[d", desc = "Предыдущая ошибка" },
      { "]q", desc = "Следующее совпадение поиска" },
      { "[q", desc = "Предыдущее совпадение поиска" },
      { "gcc", desc = "Закомментировать строку" },
      { "gc", desc = "Закомментировать", mode = { "n", "x" } },
      { "gf", desc = "Открыть файл под курсором" },
      { "za", desc = "Свернуть / развернуть блок" },
      { "zM", desc = "Свернуть всё" },
      { "zR", desc = "Развернуть всё" },
    },
  })
end)

-- ── Brackets and quotes ──────────────────────────────────────────────
pcall(function() require("mini.pairs").setup() end)

-- ── Git ──────────────────────────────────────────────────────────────
pcall(function()
  require("gitsigns").setup({
    signs = {
      add = { text = "\u{2502}" }, change = { text = "\u{2502}" }, delete = { text = "\u{2581}" },
      topdelete = { text = "\u{2594}" }, changedelete = { text = "\u{2502}" }, untracked = { text = "\u{2506}" },
    },
    preview_config = { border = "rounded" },
    on_attach = function(buf)
      local gs = require("gitsigns")
      local m = function(lhs, rhs, desc) map("n", lhs, rhs, { buffer = buf, desc = desc }) end
      m("]h", function() gs.nav_hunk("next") end, "Следующее изменение")
      m("[h", function() gs.nav_hunk("prev") end, "Предыдущее изменение")
      m("<leader>hs", gs.stage_hunk, "Добавить изменение в коммит")
      m("<leader>hr", gs.reset_hunk, "Откатить изменение")
      m("<leader>hp", gs.preview_hunk, "Показать изменение")
      m("<leader>hb", function() gs.blame_line({ full = true }) end, "Кто написал строку")
    end,
  })
end)

pcall(function()
  require("diffview").setup({ enhanced_diff_hl = true, use_icons = true })
  map("n", "<leader>hd", "<cmd>DiffviewOpen<cr>", { desc = "Все изменения бок о бок" })
  map("n", "<leader>hh", "<cmd>DiffviewFileHistory %<cr>", { desc = "История файла" })
end)

pcall(function()
  require("neogit").setup({
    kind = "floating",
    commit_editor = { kind = "floating" },
    disable_hint = true,
    graph_style = "unicode",
    integrations = { diffview = true },
    signs = { section = { "\u{203a}", "\u{2304}" }, item = { "\u{203a}", "\u{2304}" }, hunk = { "", "" } },
  })
  map("n", "<leader>G", "<cmd>Neogit<cr>", { desc = "Пульт git (neogit)" })
end)

-- ── SQL ──────────────────────────────────────────────────────────────
-- The local Postgres (brew services, database = your user name). Add more
-- as name = "postgresql://user:password@host:5432/db".
vim.g.dbs = { local_pg = "postgresql:///" .. vim.env.USER }
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_winwidth = 34
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
vim.g.db_ui_execute_on_save = 0
map("n", "<leader>s", "<cmd>DBUIToggle<cr>", { desc = "Базы данных (SQL)" })

-- ── TUIs in a floating frame ─────────────────────────────────────────
-- the program fills a rounded box over the editor; quitting it closes the box
local function float(cmd, title)
  local w = math.floor(vim.o.columns * 0.9)
  local h = math.floor(vim.o.lines * 0.85)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h,
    row = math.floor((vim.o.lines - h) / 2) - 1, col = math.floor((vim.o.columns - w) / 2),
    border = "rounded", title = " " .. title .. " ", title_pos = "left",
  })
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  vim.cmd.startinsert()
end
map("n", "<leader>c", function() float({ "lazydocker" }, "\u{f308} контейнеры") end, { desc = "Контейнеры (lazydocker)" })
map("n", "<leader>H", function()
  float({ "harlequin", "-a", "postgres", "postgresql:///" .. vim.env.USER }, "\u{f1c0} SQL")
end, { desc = "SQL-клиент harlequin" })
