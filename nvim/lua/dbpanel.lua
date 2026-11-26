-- <leader>s: a Postgres panel on the left, like the "Database Client" VS Code
-- extension: tables, views, materialized views, functions, triggers and
-- sequences of the database vim.g.db (schema public). A table unfolds into
-- its columns with types, keys and links; Enter opens its rows below.
--
--   Enter / double click  group: fold · table/view: rows (first 200) ·
--                         function/trigger/sequence: its definition
--   l / Tab               unfold a table into columns (or fold it back)
--   h                     fold what the cursor is in
--   R                     reload from the database
--   q                     close the panel
local M = {}

local ICON = {
  db = "\u{f1c0}", tables = "\u{f0ce}", views = "\u{f06e}", matviews = "\u{f06e}",
  functions = "\u{f121}", triggers = "\u{f0e7}", sequences = "\u{f0cb}",
  pk = "\u{f084}", fk = "\u{f0c1}",
}

local GROUPS = {
  { key = "tables", title = "Tables", kind = "relation",
    sql = [[select table_name, table_name from information_schema.tables
            where table_schema = 'public' and table_type = 'BASE TABLE' order by 1]] },
  { key = "views", title = "Views", kind = "relation",
    sql = [[select table_name, table_name from information_schema.views
            where table_schema = 'public' order by 1]] },
  { key = "matviews", title = "Materialized views", kind = "relation",
    sql = [[select matviewname, matviewname from pg_matviews where schemaname = 'public' order by 1]] },
  { key = "functions", title = "Functions", kind = "function",
    sql = [[select p.oid, p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' order by 2]] },
  { key = "triggers", title = "Triggers", kind = "trigger",
    sql = [[select t.oid, t.tgname || ' → ' || c.relname
            from pg_trigger t join pg_class c on c.oid = t.tgrelid
            join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and not t.tgisinternal order by 2]] },
  { key = "sequences", title = "Sequences", kind = "sequence",
    sql = [[select c.relname, c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'public' and c.relkind = 'S' order by 1]] },
}

local COLUMNS_SQL = [[
select a.attname, format_type(a.atttypid, a.atttypmod),
       exists (select 1 from pg_constraint k
               where k.conrelid = a.attrelid and k.contype = 'p' and a.attnum = any (k.conkey)),
       (select k.confrelid::regclass || '.' || f.attname
        from pg_constraint k
        join pg_attribute f on f.attrelid = k.confrelid and f.attnum = k.confkey[1]
        where k.conrelid = a.attrelid and k.contype = 'f' and a.attnum = any (k.conkey) limit 1),
       a.attnotnull
from pg_attribute a
where a.attrelid = 'public.%s'::regclass and a.attnum > 0 and not a.attisdropped
order by a.attnum]]

local state = {
  win = nil, buf = nil,
  data = {}, columns = {},
  open_groups = { tables = true },
  open_tables = {},
  map = {},
}

local function ident(name)
  return '"' .. name:gsub('"', '""') .. '"'
end

-- psql -At: rows of tab-separated fields; nil + error text on failure
local function query(sql)
  local res = vim.system({ "psql", "-X", "-At", "-F", "\t", "-d", vim.g.db or "postgres", "-c", sql },
    { text = true }):wait()
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "")
  end
  local rows = {}
  for _, line in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
    rows[#rows + 1] = vim.split(line, "\t", { plain = true })
  end
  return rows
end

-- psql's usual table view (or raw text) in a window at the bottom, the same
-- way <leader>r shows a .sql file: the cursor moves into it, q / Enter or
-- leaving the window closes it
local function show(sql, raw)
  local args = { "psql", "-X", "-q", "-P", "pager=off", "-d", vim.g.db or "postgres", "-c", sql }
  if raw then
    table.insert(args, 3, "-At")
  end
  local res = vim.system(args, { text = true }):wait()
  local lines = vim.split(vim.trim((res.stdout or "") .. (res.stderr or "")), "\n")
  vim.cmd("botright 16split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = raw and "sql" or "dbout"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  for _, key in ipairs({ "q", "<cr>" }) do
    vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, nowait = true, desc = "Закрыть результат" })
  end
  close_on_leave(win)
end

local function load()
  state.data, state.columns = {}, {}
  for _, g in ipairs(GROUPS) do
    local rows, err = query(g.sql)
    if not rows then
      state.error = err
      return
    end
    state.data[g.key] = rows
  end
  state.error = nil
end

local function columns_of(name)
  if not state.columns[name] then
    state.columns[name] = query(COLUMNS_SQL:format(ident(name):gsub("'", "''"))) or {}
  end
  return state.columns[name]
end

local function render()
  local lines, hls = {}, {}
  state.map = {}
  local function add(text, node, spans)
    lines[#lines + 1] = text
    state.map[#lines] = node
    for _, s in ipairs(spans or {}) do
      hls[#hls + 1] = { #lines - 1, s[1], s[2], s[3] }
    end
  end

  local dbname = (vim.g.db or "postgres"):match("[^/]+$") or "postgres"
  add(" " .. ICON.db .. "  " .. dbname, { type = "db" }, { { 0, -1, "Title" } })
  if state.error then
    add("   cannot connect:", nil, { { 0, -1, "ErrorMsg" } })
    for _, l in ipairs(vim.split(state.error, "\n")) do
      add("   " .. l, nil, { { 0, -1, "Comment" } })
    end
  else
    for _, g in ipairs(GROUPS) do
      local items = state.data[g.key] or {}
      local open = state.open_groups[g.key]
      local head = string.format(" %s %s  %s", open and "▾" or "▸", ICON[g.key], g.title)
      local count = string.format(" (%d)", #items)
      add(head .. count, { type = "group", group = g },
        { { 0, #head, #items > 0 and "Directory" or "Comment" }, { #head, -1, "Comment" } })
      if open then
        for _, row in ipairs(items) do
          local id, label = row[1], row[2]
          if g.kind == "relation" then
            local unfolded = state.open_tables[label]
            local text = string.format("    %s %s", unfolded and "▾" or "▸", label)
            add(text, { type = "relation", group = g, name = label })
            if unfolded then
              local cols = columns_of(label)
              local width = 0
              for _, c in ipairs(cols) do
                width = math.max(width, vim.fn.strdisplaywidth(c[1]))
              end
              for _, c in ipairs(cols) do
                local mark = c[3] == "t" and ICON.pk or (c[4] ~= "" and ICON.fk or " ")
                local prefix = "        " .. mark .. " "
                local name = c[1] .. string.rep(" ", width - vim.fn.strdisplaywidth(c[1]))
                local typ = "  " .. c[2] .. (c[5] == "t" and "" or "?")
                local link = c[4] ~= "" and ("  → " .. c[4]) or ""
                local text2 = prefix .. name .. typ .. link
                local p, n, t = #prefix, #prefix + #name, #prefix + #name + #typ
                add(text2, { type = "column", group = g, name = label }, {
                  { 0, p, c[3] == "t" and "WarningMsg" or "Special" },
                  { n, t, "Comment" },
                  { t, -1, "Special" },
                })
              end
            end
          else
            add("      " .. label, { type = "object", group = g, id = id, name = label })
          end
        end
      end
    end
  end

  local buf = state.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("dbpanel")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    local line_len = #lines[h[1] + 1]
    local stop = h[3] == -1 and line_len or math.min(h[3], line_len)
    if stop > h[2] then
      vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = stop, hl_group = h[4] })
    end
  end
end

local function node_here()
  return state.map[vim.api.nvim_win_get_cursor(0)[1]]
end

local function redraw_keep_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  render()
  pos[1] = math.min(pos[1], vim.api.nvim_buf_line_count(state.buf))
  vim.api.nvim_win_set_cursor(0, pos)
end

local function activate()
  local node = node_here()
  if not node then
    return
  end
  if node.type == "group" then
    state.open_groups[node.group.key] = not state.open_groups[node.group.key]
    redraw_keep_cursor()
  elseif node.type == "relation" or node.type == "column" then
    show("select * from public." .. ident(node.name) .. " limit 200")
  elseif node.group.kind == "function" then
    show("select pg_get_functiondef(" .. node.id .. ")", true)
  elseif node.group.kind == "trigger" then
    show("select pg_get_triggerdef(" .. node.id .. ", true)", true)
  elseif node.group.kind == "sequence" then
    show("select * from pg_sequences where schemaname = 'public' and sequencename = '"
      .. node.name:gsub("'", "''") .. "'")
  end
end

local function unfold()
  local node = node_here()
  if not node then
    return
  end
  if node.type == "group" then
    state.open_groups[node.group.key] = not state.open_groups[node.group.key]
  elseif node.type == "relation" then
    state.open_tables[node.name] = not state.open_tables[node.name]
  else
    return
  end
  redraw_keep_cursor()
end

local function fold()
  local node = node_here()
  if not node then
    return
  end
  if node.type == "relation" and state.open_tables[node.name] then
    state.open_tables[node.name] = nil
  elseif node.type == "column" then
    state.open_tables[node.name] = nil
  elseif node.group then
    state.open_groups[node.group.key] = nil
  end
  render()
  -- put the cursor on what was folded
  for lnum, n in pairs(state.map) do
    if (node.type == "column" and n.type == "relation" and n.name == node.name)
      or (node.type ~= "column" and n.type == "group" and n.group == node.group and not state.open_groups[node.group.key])
      or (node.type == "relation" and n.type == "relation" and n.name == node.name) then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      break
    end
  end
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.open()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].filetype = "dbpanel"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.cmd("topleft 40vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  for opt, val in pairs({ number = false, relativenumber = false, signcolumn = "no", wrap = false,
    cursorline = true, winfixwidth = true, list = false, foldcolumn = "0" }) do
    vim.wo[state.win][opt] = val
  end
  load()
  render()
  local o = { buffer = state.buf, nowait = true, silent = true }
  local function key(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, vim.tbl_extend("force", o, { desc = desc }))
  end
  key("<cr>", activate, "Открыть")
  key("<2-LeftMouse>", activate, "Открыть")
  key("l", unfold, "Развернуть / свернуть")
  key("<tab>", unfold, "Развернуть / свернуть")
  key("h", fold, "Свернуть")
  key("R", function()
    load()
    redraw_keep_cursor()
  end, "Обновить из базы")
  key("q", M.close, "Закрыть панель")
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = state.buf,
    once = true,
    callback = function()
      state.win = nil
    end,
  })
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

return M
