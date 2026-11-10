-- tree.lua — a small project tree (file explorer) for the left side.
-- Written by hand instead of a plugin, so every line can be read and changed.
--
--   <leader>e   toggle the tree
--   Enter / l   open file · expand / collapse folder
--   h           collapse folder (or jump to its parent)
--   a           new file (end the name with / for a folder)
--   r           rename          d   delete (to the macOS Trash)
--   H           show / hide dotfiles     R   refresh     q   close
--   ?           help

local M = {}
local api, uv = vim.api, vim.uv
local ns = api.nvim_create_namespace("tree")

local WIDTH = 32
local NEVER_SHOW = { [".git"] = true, [".DS_Store"] = true, ["__pycache__"] = true, ["node_modules"] = true }

-- Nerd Font icons (Ghostty has them built in) + the highlight group of each.
local ICON = {
  dir = "\u{f07b}", dir_open = "\u{f07c}", file = "\u{f016}",
}
local BY_EXT = {
  py = { "\u{e606}", "TreeIconYellow" },
  c = { "\u{e61e}", "TreeIconBlue" }, h = { "\u{e61e}", "TreeIconSteel" },
  cpp = { "\u{e61d}", "TreeIconBlue" }, hpp = { "\u{e61d}", "TreeIconSteel" },
  md = { "\u{e609}", "TreeIconFg" },
  json = { "\u{e60b}", "TreeIconYellow" },
  lua = { "\u{e620}", "TreeIconBlue" },
  yaml = { "\u{e615}", "TreeIconOrange" }, yml = { "\u{e615}", "TreeIconOrange" },
  toml = { "\u{e6b2}", "TreeIconOrange" },
  conf = { "\u{e615}", "TreeIconSteel" }, ini = { "\u{e615}", "TreeIconSteel" },
  sh = { "\u{f489}", "TreeIconGreen" }, bash = { "\u{f489}", "TreeIconGreen" },
  zsh = { "\u{f489}", "TreeIconGreen" }, fish = { "\u{f489}", "TreeIconGreen" },
  html = { "\u{e60e}", "TreeIconOrange" },
  txt = { "\u{f0f6}", "TreeIconGrey" }, log = { "\u{f0f6}", "TreeIconGrey" },
  lock = { "\u{f023}", "TreeIconGrey" },
  png = { "\u{f1c5}", "TreeIconTan" }, jpg = { "\u{f1c5}", "TreeIconTan" },
  jpeg = { "\u{f1c5}", "TreeIconTan" }, svg = { "\u{f1c5}", "TreeIconTan" },
}
local BY_NAME = {
  Dockerfile = { "\u{f308}", "TreeIconBlue" },
  ["docker-compose.yml"] = { "\u{f308}", "TreeIconBlue" },
  ["compose.yaml"] = { "\u{f308}", "TreeIconBlue" },
  Makefile = { "\u{e673}", "TreeIconOrange" },
  [".gitignore"] = { "\u{e702}", "TreeIconOrange" },
  [".gitattributes"] = { "\u{e702}", "TreeIconOrange" },
  [".env"] = { "\u{f023}", "TreeIconYellow" },
}

local state = {
  root = nil,         -- project folder (Neovim's current directory)
  open = {},          -- [folder path] = true when expanded
  show_hidden = true, -- dotfiles (.github, .env, .editorconfig…)
  current = nil,      -- file in the editor window, highlighted in the tree
  buf = nil, win = nil,
  items = {},         -- [line number] = { path, name, dir, depth }
}

local function icon_for(item)
  if item.dir then
    if state.open[item.path] then
      return ICON.dir_open, "TreeIconDirOpen"
    end
    return ICON.dir, "TreeIconDir"
  end
  local by_name = BY_NAME[item.name] or (item.name:match("^Dockerfile") and BY_NAME.Dockerfile)
  local spec = by_name or BY_EXT[(item.name:match("%.([^.]+)$") or ""):lower()]
  if spec then
    return spec[1], spec[2]
  end
  return ICON.file, "TreeIconGrey"
end

-- icon + colour name for a file name (also used by the status line)
function M.file_icon(name)
  local icon, group = icon_for({ name = name, dir = false })
  return icon, (group:gsub("^TreeIcon", ""))
end

-- folder contents: folders first, then files, both alphabetical
local function scan(dir)
  local list = {}
  local handle = uv.fs_scandir(dir)
  while handle do
    local name, kind = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if not NEVER_SHOW[name] and (state.show_hidden or name:sub(1, 1) ~= ".") then
      local path = dir .. "/" .. name
      if kind == "link" then
        local stat = uv.fs_stat(path)
        kind = stat and stat.type or "file"
      end
      table.insert(list, { name = name, path = path, dir = kind == "directory" })
    end
  end
  table.sort(list, function(a, b)
    if a.dir ~= b.dir then
      return a.dir
    end
    return a.name:lower() < b.name:lower()
  end)
  return list
end

local function valid(x, kind)
  return x and api["nvim_" .. kind .. "_is_valid"](x)
end

local function render()
  if not valid(state.buf, "buf") then
    return
  end
  local lines, marks = {}, {}
  state.items = {}

  local function mark(row, col, len, group)
    table.insert(marks, { row, col, col + len, group })
  end

  -- header: project name
  local title = " " .. ICON.dir_open .. " " .. vim.fn.fnamemodify(state.root, ":t")
  lines[1] = title
  mark(0, 0, #title, "TreeRoot")
  lines[2] = ""

  local function walk(dir, depth)
    for _, item in ipairs(scan(dir)) do
      item.depth = depth
      local guide = string.rep("│ ", depth)
      local icon, icon_hl = icon_for(item)
      local line = "  " .. guide .. icon .. " " .. item.name
      table.insert(lines, line)
      local row = #lines - 1
      state.items[#lines] = item

      local col = 2
      mark(row, col, #guide, "TreeGuide")
      col = col + #guide
      mark(row, col, #icon, icon_hl)
      col = col + #icon + 1
      local name_hl = item.dir and "TreeDir" or (item.path == state.current and "TreeCurrent" or "TreeFile")
      if not item.dir and item.name:sub(1, 1) == "." then
        name_hl = item.path == state.current and "TreeCurrent" or "TreeHidden"
      end
      mark(row, col, #item.name, name_hl)

      if item.dir and state.open[item.path] then
        walk(item.path, depth + 1)
      end
    end
  end
  walk(state.root, 0)

  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(state.buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
end

local function line_of(path)
  for row, item in pairs(state.items) do
    if item.path == path then
      return row
    end
  end
end

local function item_under_cursor()
  return state.items[api.nvim_win_get_cursor(0)[1]]
end

-- the window files open in: the last editor window, or a new split
local function editor_window()
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and prev ~= state.win and valid(prev, "win") then
    return prev
  end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if win ~= state.win and api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  vim.cmd("botright vsplit")
  local win = api.nvim_get_current_win()
  api.nvim_set_current_win(state.win)
  api.nvim_win_set_width(state.win, WIDTH)
  return win
end

local function activate()
  local item = item_under_cursor()
  if not item then
    return
  end
  if item.dir then
    state.open[item.path] = not state.open[item.path] or nil
    render()
  else
    local win = editor_window()
    api.nvim_set_current_win(win)
    vim.cmd.edit(vim.fn.fnameescape(item.path))
  end
end

local function collapse()
  local item = item_under_cursor()
  if not item then
    return
  end
  if item.dir and state.open[item.path] then
    state.open[item.path] = nil
    render()
    return
  end
  local parent = vim.fn.fnamemodify(item.path, ":h")
  if parent ~= state.root then
    state.open[parent] = nil
    render()
    local row = line_of(parent)
    if row then
      api.nvim_win_set_cursor(state.win, { row, 0 })
    end
  end
end

-- folder for new files: the folder under the cursor, or the file's folder
local function target_dir()
  local item = item_under_cursor()
  if not item then
    return state.root
  end
  return item.dir and item.path or vim.fn.fnamemodify(item.path, ":h")
end

local function create()
  local dir = target_dir()
  vim.ui.input({ prompt = "New in " .. vim.fn.fnamemodify(dir, ":~:.") .. "/ (end with / for a folder): " }, function(name)
    if not name or name == "" then
      return
    end
    local path = dir .. "/" .. name
    if name:sub(-1) == "/" then
      vim.fn.mkdir(path, "p")
    else
      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
      if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({}, path)
      end
    end
    state.open[dir] = true
    render()
    local row = line_of(path:gsub("/$", ""))
    if row then
      api.nvim_win_set_cursor(state.win, { row, 0 })
    end
  end)
end

local function rename()
  local item = item_under_cursor()
  if not item then
    return
  end
  vim.ui.input({ prompt = "Rename to: ", default = item.name }, function(name)
    if not name or name == "" or name == item.name then
      return
    end
    local new = vim.fn.fnamemodify(item.path, ":h") .. "/" .. name
    local ok, err = os.rename(item.path, new)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    -- keep an open buffer pointing at the renamed file
    local buf = vim.fn.bufnr(item.path)
    if buf ~= -1 then
      api.nvim_buf_set_name(buf, new)
      api.nvim_buf_call(buf, function()
        vim.cmd("silent! write!")
      end)
    end
    render()
  end)
end

local function delete()
  local item = item_under_cursor()
  if not item then
    return
  end
  local answer = vim.fn.confirm("Move " .. item.name .. " to the Trash?", "&Yes\n&No", 2)
  if answer ~= 1 then
    return
  end
  vim.fn.system({ "/usr/bin/trash", item.path })
  local buf = vim.fn.bufnr(item.path)
  if buf ~= -1 then
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
  render()
end

local function help()
  print("Enter/l open · h collapse · a new · r rename · d delete · H dotfiles · R refresh · q close")
end

local function setup_buffer()
  state.buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(state.buf, "Project")
  vim.bo[state.buf].filetype = "tree"
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].modifiable = false

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, silent = true })
  end
  map("<CR>", activate)
  map("l", activate)
  map("o", activate)
  map("<2-LeftMouse>", activate)
  map("h", collapse)
  map("a", create)
  map("r", rename)
  map("d", delete)
  map("R", render)
  map("H", function()
    state.show_hidden = not state.show_hidden
    render()
  end)
  map("q", M.close)
  map("?", help)
end

local function setup_window()
  local wo = vim.wo[state.win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.list = false
  wo.wrap = false
  wo.spell = false
  wo.cursorline = true
  wo.cursorcolumn = false
  wo.colorcolumn = ""
  wo.winfixwidth = true
  wo.winhighlight = "Normal:TreeNormal,CursorLine:TreeCursorLine"
  wo.fillchars = "eob: " -- no ~ under the last entry
end

function M.open()
  state.root = vim.fn.getcwd()
  local file = api.nvim_buf_get_name(0)
  if file ~= "" and vim.bo.buftype == "" then
    state.current = file
    -- expand the folders down to the current file
    local dir = vim.fn.fnamemodify(file, ":h")
    while #dir > #state.root and dir:sub(1, #state.root) == state.root do
      state.open[dir] = true
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end
  if not valid(state.buf, "buf") then
    setup_buffer()
  end
  vim.cmd("topleft vertical " .. WIDTH .. "split")
  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)
  setup_window()
  render()
  local row = state.current and line_of(state.current)
  api.nvim_win_set_cursor(state.win, { row or math.min(3, api.nvim_buf_line_count(state.buf)), 0 })
end

function M.close()
  if valid(state.win, "win") then
    api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.toggle()
  if valid(state.win, "win") then
    M.close()
  else
    M.open()
  end
end

-- keep the tree in sync with the editor
local group = api.nvim_create_augroup("tree", { clear = true })
api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(args)
    -- the tree is the last window left: quit instead of staying alone
    if args.buf == state.buf and #api.nvim_tabpage_list_wins(0) == 1 then
      vim.schedule(function()
        vim.cmd("quit")
      end)
      return
    end
    local name = api.nvim_buf_get_name(args.buf)
    if valid(state.win, "win") and vim.bo[args.buf].buftype == "" and name ~= "" and name ~= state.current then
      state.current = name
      render()
    end
  end,
})
api.nvim_create_autocmd({ "BufWritePost", "DirChanged" }, {
  group = group,
  callback = function()
    if valid(state.win, "win") then
      state.root = vim.fn.getcwd()
      render()
    end
  end,
})

return M
