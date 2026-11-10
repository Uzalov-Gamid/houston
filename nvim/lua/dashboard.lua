-- dashboard.lua — start screen: a small personal profile instead of the
-- Neovim intro. Shown when `nvim` starts without a file (and on :Dashboard).
--
--   avatar + name           identicon logo, name, bio, stardate, a quip
--   ❯ gh contributions      GitHub activity grid, streak, today
--   ❯ atuin stats           terminal commands per day + top commands
--   ❯ nvim --time           time spent editing this week, by language
--   ❯ sky                   moon phase, sunrise / sunset
--
-- Slow data (gh, sqlite) loads in the background and GitHub is cached for
-- an hour, so the screen opens instantly; each block shows "…" until ready
-- and keeps working (with the last cache) offline.
--
-- keys: e tree · f find · g grep · n new file · r refresh · q quit

local M = {}
local api = vim.api

-- ── Settings ─────────────────────────────────────────────────────────
-- Defaults shown in the repo. Your own data goes into lua/local_profile.lua
-- (not tracked, see local_profile.example.lua) and overrides these.
local PROFILE = {
  name = "Astro Naut",
  handle = "@astronaut",
  bio = "devops · linux · homelab",
}
local CITY = { name = "greenwich", lat = 51.4779, lon = -0.0015, utc = 0 }
local ok_local, mine = pcall(require, "local_profile")
if ok_local and type(mine) == "table" then
  PROFILE = vim.tbl_extend("force", PROFILE, mine.profile or {})
  CITY = vim.tbl_extend("force", CITY, mine.city or {})
end
local WIDTH = 66 -- content width; the block is centred in the window
local WEEKS = 26 -- GitHub grid: last half year
local DAYS = 52 -- terminal sparkline: last 52 days
local CACHE = vim.fn.stdpath("cache") .. "/dashboard"
local ATUIN_DB = vim.fn.expand("~/.local/share/atuin/history.db")
-- commands that say nothing about what you work on
local NOISE = { clear = true, c = true, cd = true, ls = true, z = true, exit = true, ll = true, pwd = true }

-- the logo: 5×2 identicon (1 = filled), each cell 4 columns × 2 rows
local LOGO = { { 1, 1, 1, 1, 1 }, { 1, 0, 1, 0, 1 } }

local state = { buf = nil, gh = nil, atuin = nil }

-- ── Helpers ──────────────────────────────────────────────────────────
local function dw(s)
  return vim.fn.strdisplaywidth(s)
end

local MONTHS = { "янв", "фев", "мар", "апр", "мая", "июн", "июл", "авг", "сен", "окт", "ноя", "дек" }
local WDAYS = { "вс", "пн", "вт", "ср", "чт", "пт", "сб" }

local function quip()
  local h, wd = tonumber(os.date("%H")), tonumber(os.date("%w"))
  local pool
  if h < 5 then
    pool = { "три часа ночи. серьёзно?", "ночью segfault'ы честнее.", "кофе закончился ещё вчера." }
  elseif h < 12 then
    pool = { "доброе утро. компилятор уже ждёт.", "утро — время для make clean.", "сначала кофе, потом коммиты." }
  elseif h < 18 then
    pool = { "продуктивного дня, экипаж из одного.", "всё ещё не в той ветке?", "отличный день, чтобы починить CI." }
  else
    pool = { "вечер. самое время для yaml.", "последний коммит на сегодня? конечно.", "docker compose down. и ты тоже." }
  end
  if wd == 1 then
    table.insert(pool, "понедельник. держись.")
  elseif wd == 5 then
    table.insert(pool, "пятница. не деплой в прод.")
  elseif wd == 0 or wd == 6 then
    table.insert(pool, "выходной, а ты в nvim. уважаю.")
  end
  math.randomseed(os.time())
  return pool[math.random(#pool)]
end

-- ── Sky: moon phase and sun times (computed locally) ─────────────────
local function moon()
  local synodic = 29.530588853
  local known_new = os.time({ year = 2000, month = 1, day = 6, hour = 18, min = 14 }) -- UTC-ish anchor
  local age = ((os.time() - known_new) / 86400) % synodic
  local lit = math.floor((1 - math.cos(2 * math.pi * age / synodic)) / 2 * 100 + 0.5)
  local names = {
    -- Nerd Font weather glyphs (monochrome, not Apple emoji)
    { 1.84, "\u{e38d}", "новолуние" }, { 5.53, "\u{e390}", "растущий серп" },
    { 9.22, "\u{e394}", "первая четверть" }, { 12.91, "\u{e396}", "растущая луна" },
    { 16.61, "\u{e39b}", "полнолуние" }, { 20.30, "\u{e3a2}", "убывающая луна" },
    { 23.99, "\u{e3a2}", "последняя четверть" }, { 27.68, "\u{e3a8}", "убывающий серп" },
    { 99, "\u{e38d}", "новолуние" },
  }
  for _, n in ipairs(names) do
    if age < n[1] then
      local to_full = math.floor((14.765 - age) % synodic + 0.5)
      return n[2], n[3], lit, to_full
    end
  end
end

-- NOAA sunrise equation; returns "HH:MM" local time
local function sun(rising)
  local rad, deg = math.pi / 180, 180 / math.pi
  local n = tonumber(os.date("%j"))
  local lng_hour = CITY.lon / 15
  local t = n + (((rising and 6 or 18) - lng_hour) / 24)
  local m = 0.9856 * t - 3.289
  local l = (m + 1.916 * math.sin(m * rad) + 0.020 * math.sin(2 * m * rad) + 282.634) % 360
  local ra = (deg * math.atan(0.91764 * math.tan(l * rad))) % 360
  ra = (ra + (math.floor(l / 90) * 90 - math.floor(ra / 90) * 90)) / 15
  local sin_dec = 0.39782 * math.sin(l * rad)
  local cos_dec = math.cos(math.asin(sin_dec))
  local cos_h = (math.cos(90.833 * rad) - sin_dec * math.sin(CITY.lat * rad)) / (cos_dec * math.cos(CITY.lat * rad))
  if cos_h > 1 or cos_h < -1 then
    return "--:--"
  end
  local h = (rising and (360 - deg * math.acos(cos_h)) or (deg * math.acos(cos_h))) / 15
  local local_t = (h + ra - 0.06571 * t - 6.622 - lng_hour + CITY.utc) % 24
  return string.format("%02d:%02d", math.floor(local_t), math.floor((local_t % 1) * 60))
end

-- ── Data: GitHub (gh, cached 1 h) ────────────────────────────────────
local GH_FILE = CACHE .. "/github.json"
local GH_QUERY = "query={viewer{contributionsCollection{contributionCalendar{totalContributions "
  .. "weeks{contributionDays{contributionCount date weekday}}}}}}"

local function read_json(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and data or nil
end

local function load_github(done)
  local cached = read_json(GH_FILE)
  if cached then
    state.gh = cached
  end
  if cached and os.time() - (cached.fetched or 0) < 3600 then
    return
  end
  if vim.fn.executable("gh") == 0 then
    return
  end
  vim.system({ "gh", "api", "graphql", "-f", GH_QUERY }, { text = true }, function(res)
    if res.code ~= 0 then
      return
    end
    local ok, data = pcall(vim.json.decode, res.stdout)
    if not ok then
      return
    end
    local cal = data.data.viewer.contributionsCollection.contributionCalendar
    local fresh = { fetched = os.time(), total = cal.totalContributions, weeks = cal.weeks }
    vim.schedule(function()
      vim.fn.mkdir(CACHE, "p")
      local f = io.open(GH_FILE, "w")
      if f then
        f:write(vim.json.encode(fresh))
        f:close()
      end
      state.gh = fresh
      done()
    end)
  end)
end

-- ── Data: atuin (its sqlite database, read-only) ─────────────────────
local function load_atuin(done)
  if vim.fn.filereadable(ATUIN_DB) == 0 or vim.fn.executable("sqlite3") == 0 then
    return
  end
  local per_day = string.format(
    "select date(timestamp/1000000000,'unixepoch','localtime'), count(*) from history "
      .. "where deleted_at is null and timestamp > strftime('%%s','now','-%d days')*1000000000 group by 1;",
    DAYS
  )
  local commands = "select command from history where deleted_at is null "
    .. "and timestamp > strftime('%s','now','-30 days')*1000000000;"
  local total = "select count(*) from history where deleted_at is null;"
  vim.system({ "sqlite3", "-readonly", "-separator", "\t", ATUIN_DB, total, per_day, commands }, { text = true },
    function(res)
      if res.code ~= 0 then
        return
      end
      local lines = vim.split(res.stdout, "\n", { trimempty = true })
      local data = { total = tonumber(lines[1]) or 0, days = {}, top = {} }
      local counts, all = {}, 0
      for i = 2, #lines do
        local day, n = lines[i]:match("^(%d%d%d%d%-%d%d%-%d%d)\t(%d+)$")
        if day then
          data.days[day] = tonumber(n)
        else
          local word = (lines[i]:match("^%s*(%S+)") or ""):gsub("^.*/", "")
          -- skip noise and typos (one letter, or typed in the Russian layout)
          if #word > 1 and word:match("^[%w%._%-]+$") and not NOISE[word] then
            counts[word] = (counts[word] or 0) + 1
            all = all + 1
          end
        end
      end
      for word, n in pairs(counts) do
        table.insert(data.top, { word, n })
      end
      table.sort(data.top, function(a, b)
        return a[2] > b[2]
      end)
      data.all = all
      vim.schedule(function()
        state.atuin = data
        done()
      end)
    end)
end

-- ── Rendering ────────────────────────────────────────────────────────
-- a line is a list of {text, highlight}; render() turns them into buffer
-- lines + extmarks, centred in the window.
local lines

local function line(...)
  table.insert(lines, { ... })
end

local function header(cmd, stats)
  -- "❯ cmd ......................... stats"
  local left = "❯ " .. cmd
  local gap = math.max(2, WIDTH - dw(left) - dw(stats or ""))
  line({ "❯ ", "DashPrompt" }, { cmd, "DashCmd" }, { string.rep(" ", gap), "" }, { stats or "", "DashDim" })
end

local function profile_block()
  local now = os.date("*t")
  local info = {
    { { PROFILE.name, "DashName" }, { "  " .. PROFILE.handle, "DashDim" } },
    { { PROFILE.bio, "DashText" } },
    {
      { "stardate ", "DashDim" },
      { os.date("%Y.") .. os.date("%j"), "DashAccent" },
      { string.format(" · %s %d %s · %s", WDAYS[now.wday], now.day, MONTHS[now.month], os.date("%H:%M")), "DashDim" },
    },
    { { "// " .. quip(), "DashQuip" } },
  }
  local logo_rows = {}
  for _, row in ipairs(LOGO) do
    local s = ""
    for _, cell in ipairs(row) do
      s = s .. (cell == 1 and "████" or "    ")
    end
    table.insert(logo_rows, s)
    table.insert(logo_rows, s)
  end
  for i = 1, 4 do
    local segs = { { logo_rows[i], "DashLogo" }, { "   ", "" } }
    for _, seg in ipairs(info[i] or {}) do
      table.insert(segs, seg)
    end
    line(unpack(segs))
  end
end

local GH_LEVELS = { "DashGh0", "DashGh1", "DashGh2", "DashGh3", "DashGh4" }

local function github_block()
  local gh = state.gh
  if not gh then
    header("gh contributions --last " .. WEEKS .. "w", "…")
    return
  end
  -- flatten days, streak, today
  local days, max = {}, 1
  for _, week in ipairs(gh.weeks) do
    for _, d in ipairs(week.contributionDays) do
      table.insert(days, d)
      max = math.max(max, d.contributionCount)
    end
  end
  local today = days[#days] and days[#days].contributionCount or 0
  local streak, i = 0, #days
  if today == 0 then
    i = i - 1
  end
  while i > 0 and days[i].contributionCount > 0 do
    streak, i = streak + 1, i - 1
  end
  header("gh contributions --last " .. WEEKS .. "w",
    string.format("%d/год · \u{f490} %d · сегодня %d", gh.total or 0, streak, today))

  -- grid: rows Mon..Sun, columns = weeks
  local weeks = {}
  for w = math.max(1, #gh.weeks - WEEKS + 1), #gh.weeks do
    table.insert(weeks, gh.weeks[w])
  end
  local labels = { "пн", "  ", "ср", "  ", "пт", "  ", "  " }
  for row = 1, 7 do
    local wd = row % 7 -- GitHub weekday: 0 = Sunday … 6 = Saturday
    local segs = { { "  " .. labels[row] .. " ", "DashDim" } }
    for _, week in ipairs(weeks) do
      local cell
      for _, d in ipairs(week.contributionDays) do
        if d.weekday == wd then
          cell = d
        end
      end
      if cell then
        local n = cell.contributionCount
        local lvl = n == 0 and 1 or math.min(5, 1 + math.ceil(4 * n / max))
        table.insert(segs, { "■ ", GH_LEVELS[lvl] })
      else
        table.insert(segs, { "  ", "" })
      end
    end
    line(unpack(segs))
  end
end

local SPARK = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

local function atuin_block()
  local a = state.atuin
  if not a then
    header("atuin stats --days " .. DAYS, "…")
    return
  end
  local today_key = os.date("%Y-%m-%d")
  header("atuin stats --days " .. DAYS,
    string.format("%d команд · сегодня %d", a.total, a.days[today_key] or 0))
  local max = 1
  for _, n in pairs(a.days) do
    max = math.max(max, n)
  end
  local segs = { { "  ", "" } }
  for back = DAYS - 1, 0, -1 do
    local key = os.date("%Y-%m-%d", os.time() - back * 86400)
    local n = a.days[key] or 0
    local ch = n == 0 and "▁" or SPARK[math.max(1, math.ceil(8 * n / max))]
    local hl = back == 0 and "DashAccent" or (n == 0 and "DashGh0" or "DashSpark")
    table.insert(segs, { ch, hl })
  end
  line(unpack(segs))
  -- top commands of the last 30 days
  local top = { { "  ", "" } }
  for k = 1, math.min(5, #a.top) do
    local pct = math.floor(100 * a.top[k][2] / math.max(1, a.all) + 0.5)
    table.insert(top, { a.top[k][1], "DashText" })
    table.insert(top, { " " .. pct .. "%", "DashDim" })
    if k < math.min(5, #a.top) then
      table.insert(top, { "  ·  ", "DashDim" })
    end
  end
  line(unpack(top))
end

local function nvim_block()
  local data = require("activity").load()
  local now = os.date("*t")
  local monday = os.time({ year = now.year, month = now.month, day = now.day, hour = 12 })
    - ((now.wday + 5) % 7) * 86400
  local per_day, langs, total = {}, {}, 0
  for i = 0, 6 do
    local key = os.date("%Y-%m-%d", monday + i * 86400)
    local sec = 0
    for ft, s in pairs(data[key] or {}) do
      sec = sec + s
      langs[ft] = (langs[ft] or 0) + s
    end
    per_day[i + 1] = sec
    total = total + sec
  end
  header("nvim --time --week", string.format("%dч %02dм", math.floor(total / 3600), math.floor(total % 3600 / 60)))
  local max = math.max(1, unpack(per_day))
  local names = { "пн", "вт", "ср", "чт", "пт", "сб", "вс" }
  local segs = { { "  ", "" } }
  local today_i = (now.wday + 5) % 7 + 1
  for i = 1, 7 do
    local s = per_day[i]
    local bar = s == 0 and "·" or SPARK[math.max(1, math.ceil(8 * s / max))]
    table.insert(segs, { names[i] .. " ", i == today_i and "DashAccent" or "DashDim" })
    table.insert(segs, { bar .. "   ", s == 0 and "DashGh0" or "DashNvim" })
  end
  line(unpack(segs))
  local list = {}
  for ft, s in pairs(langs) do
    table.insert(list, { ft, s })
  end
  table.sort(list, function(a, b)
    return a[2] > b[2]
  end)
  local row = { { "  ", "" } }
  if #list == 0 then
    table.insert(row, { "статистика копится с первого открытия файла", "DashDim" })
  end
  for k = 1, math.min(5, #list) do
    table.insert(row, { list[k][1], "DashText" })
    table.insert(row, { " " .. math.floor(100 * list[k][2] / math.max(1, total) + 0.5) .. "%", "DashDim" })
    if k < math.min(5, #list) then
      table.insert(row, { "  ·  ", "DashDim" })
    end
  end
  line(unpack(row))
end

local function sky_block()
  local icon, name, lit, to_full = moon()
  header("sky --city " .. CITY.name, "")
  local when = (to_full == 0 or to_full >= 29) and " · сегодня" or string.format(" · полнолуние через %d дн", to_full)
  line(
    { "  ", "" },
    { icon .. " ", "DashText" },
    { name, "DashText" },
    { string.format(" %d%%%s", lit, when), "DashDim" },
    { "     \u{e34c} ", "DashAccent" },
    { sun(true), "DashText" },
    { "   \u{e34d} ", "DashAccent" },
    { sun(false), "DashText" }
  )
end

local function keys_block()
  local keys = { { "e", "дерево" }, { "f", "найти" }, { "g", "поиск" }, { "n", "новый" }, { "r", "обновить" }, { "q", "выход" } }
  local segs = {}
  for k, item in ipairs(keys) do
    table.insert(segs, { item[1], "DashKey" })
    table.insert(segs, { " " .. item[2], "DashDim" })
    if k < #keys then
      table.insert(segs, { "   ", "" })
    end
  end
  line(unpack(segs))
end

local ns = api.nvim_create_namespace("dashboard")

local function render()
  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    return
  end
  local win = vim.fn.bufwinid(state.buf)
  if win == -1 then
    return
  end
  lines = {}
  local blocks = { profile_block, github_block, atuin_block, nvim_block, sky_block }
  for b, fn in ipairs(blocks) do
    local ok, err = pcall(fn)
    if not ok then
      line({ "  (" .. tostring(err):sub(1, 60) .. ")", "DashDim" })
    end
    if b < #blocks then
      line()
    end
  end
  line()
  keys_block()

  local width, height = api.nvim_win_get_width(win), api.nvim_win_get_height(win)
  local left = string.rep(" ", math.max(0, math.floor((width - WIDTH) / 2)))
  local top = math.max(0, math.floor((height - #lines) / 2))
  local text, marks = {}, {}
  for _ = 1, top do
    table.insert(text, "")
  end
  for _, segs in ipairs(lines) do
    local s, col = left, #left
    for _, seg in ipairs(segs) do
      if seg[2] ~= "" then
        table.insert(marks, { #text, col, col + #seg[1], seg[2] })
      end
      s = s .. seg[1]
      col = col + #seg[1]
    end
    table.insert(text, s)
  end

  vim.bo[state.buf].modifiable = true
  api.nvim_buf_set_lines(state.buf, 0, -1, false, text)
  vim.bo[state.buf].modifiable = false
  api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(state.buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
end

-- ── Open ─────────────────────────────────────────────────────────────
function M.open()
  local buf = api.nvim_create_buf(false, true)
  state.buf = buf
  api.nvim_win_set_buf(0, buf)
  vim.bo[buf].filetype = "dashboard"
  vim.bo[buf].bufhidden = "wipe"
  local wo = vim.wo[0][0] -- setlocal: files opened later in this window keep numbers
  wo.number, wo.relativenumber, wo.cursorline, wo.list = false, false, false, false
  wo.signcolumn, wo.colorcolumn, wo.foldcolumn = "no", "", "0"
  wo.fillchars = "eob: "

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  local function leave(cmd)
    return function()
      vim.cmd("enew")
      if cmd then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
      end
    end
  end
  map("e", function()
    require("tree").toggle()
  end)
  map("f", leave(":find "))
  map("g", leave(":silent grep! "))
  map("n", leave())
  map("i", leave("i"))
  map("r", function()
    if state.gh then
      state.gh.fetched = 0
    end
    load_github(render)
    load_atuin(render)
    render()
  end)
  map("q", "<cmd>qa<cr>")

  render()
  load_github(render)
  load_atuin(render)

  -- re-centre when the window or the terminal changes size
  local group = api.nvim_create_augroup("dashboard", { clear = true })
  api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = group, callback = render })
end

-- start screen when nvim starts without a file
function M.setup()
  vim.opt.shortmess:append("I") -- no built-in intro
  local stdin = false
  vim.api.nvim_create_autocmd("StdinReadPre", {
    callback = function()
      stdin = true
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc() == 0 and not stdin and api.nvim_buf_get_name(0) == ""
        and api.nvim_buf_line_count(0) == 1 and api.nvim_buf_get_lines(0, 0, 1, false)[1] == "" then
        M.open()
      end
    end,
  })
  api.nvim_create_user_command("Dashboard", M.open, {})
end

return M
