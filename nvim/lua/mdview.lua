-- Reading view for Markdown (<leader>p): the note drawn the way the
-- Obsidian theme Astronaut draws it — properties in a frame, headings
-- navy → pine → ◆ gold → CAPS → tan → stone, callouts with a tinted
-- background, an icon and folding, code on a dark "night" card with
-- syntax colours, tables with hairlines, embedded sections, pictures.
-- No glow, no plugins: a scratch buffer with extmark highlights
-- (groups Mdv* in colors/palette.lua).
--
-- In the view: q or <leader>p — back to the editor; Enter — fold / unfold
-- the callout under the cursor or follow the [[link]] under it; ]] / [[ —
-- next / previous heading.
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("mdview")
local dw = vim.fn.strdisplaywidth

local MAX_WIDTH = 96 -- text column, centred in the window

-- callout type → { colour family (MdvCallout<Family>*), Nerd Font icon }
local CALLOUT = {
  note = { "Note", "\u{f040}" },
  abstract = { "Summary", "\u{f0ea}" }, summary = { "Summary", "\u{f0ea}" }, tldr = { "Summary", "\u{f0ea}" },
  info = { "Info", "\u{f05a}" },
  todo = { "Tip", "\u{f058}" },
  tip = { "Tip", "\u{f06d}" }, hint = { "Tip", "\u{f06d}" },
  important = { "Warning", "\u{f06d}" },
  success = { "Success", "\u{f00c}" }, check = { "Success", "\u{f00c}" }, done = { "Success", "\u{f00c}" },
  question = { "Question", "\u{f059}" }, help = { "Question", "\u{f059}" }, faq = { "Question", "\u{f059}" },
  warning = { "Warning", "\u{f071}" }, caution = { "Warning", "\u{f071}" }, attention = { "Warning", "\u{f071}" },
  failure = { "Fail", "\u{f00d}" }, fail = { "Fail", "\u{f00d}" }, missing = { "Fail", "\u{f00d}" },
  danger = { "Fail", "\u{f0e7}" }, error = { "Fail", "\u{f0e7}" },
  bug = { "Fail", "\u{f188}" },
  example = { "Example", "\u{f03a}" },
  quote = { "Quote", "\u{f10d}" }, cite = { "Quote", "\u{f10d}" },
}
M.CALLOUT = CALLOUT

local IMAGE_EXT = { png = true, jpg = true, jpeg = true, gif = true, webp = true, svg = true }

-- ── Inline: **bold**, *italic*, ~~strike~~, ==mark==, `code`, links, #tags ──

-- base group + modifiers → a derived group (created on first use;
-- forgotten when the colour scheme reloads and clears them)
local derived = {}
api.nvim_create_autocmd("ColorScheme", { callback = function() derived = {} end })
local function style(base, mods)
  if not (mods.b or mods.i or mods.s or mods.m) then
    return base
  end
  local name = base .. (mods.b and "B" or "") .. (mods.i and "I" or "") .. (mods.s and "S" or "") .. (mods.m and "M" or "")
  if not derived[name] then
    local spec = api.nvim_get_hl(0, { name = base, link = false })
    if base == "MdvText" then -- plain text: bold espresso, italic tan, like the theme
      if mods.b then spec.fg = api.nvim_get_hl(0, { name = "MdvBold" }).fg end
      if mods.i and not mods.b then spec.fg = api.nvim_get_hl(0, { name = "MdvItalic" }).fg end
    end
    spec.bold = mods.b or spec.bold
    spec.italic = mods.i or spec.italic
    if mods.s then
      spec.strikethrough = true
      spec.fg = api.nvim_get_hl(0, { name = "MdvStrike" }).fg
    end
    if mods.m then
      local mark = api.nvim_get_hl(0, { name = "MdvMark" })
      spec.bg, spec.fg = mark.bg, mark.fg
    end
    api.nvim_set_hl(0, name, spec)
    derived[name] = true
  end
  return name
end

-- text → list of segments { text, hl[, atomic] }
local function inline(text, base)
  local segs, buf, mods = {}, "", {}
  local function flush()
    if buf ~= "" then
      segs[#segs + 1] = { buf, style(base, mods) }
      buf = ""
    end
  end
  local function toggle(key)
    flush()
    mods[key] = not mods[key] or nil
  end
  local i, n = 1, #text
  while i <= n do
    local ch, two = text:sub(i, i), text:sub(i, i + 1)
    local prev = i > 1 and text:sub(i - 1, i - 1) or " "
    if ch == "\\" and i < n then
      buf = buf .. text:sub(i + 1, i + 1)
      i = i + 2
    elseif ch == "`" then
      local close = text:find("`", i + 1, true)
      if close then
        flush()
        segs[#segs + 1] = { " " .. text:sub(i + 1, close - 1) .. " ", "MdvCode", atomic = true }
        i = close + 1
      else
        buf, i = buf .. ch, i + 1
      end
    elseif two == "[[" then
      local close = text:find("]]", i + 2, true)
      if close then
        flush()
        local target = text:sub(i + 2, close - 1)
        local page, alias = target:match("^(.-)|(.*)$")
        local shown = alias or target:gsub("#%^?", " › ")
        segs[#segs + 1] = { shown, "MdvWiki", target = page or target }
        i = close + 2
      else
        buf, i = buf .. ch, i + 1
      end
    elseif ch == "[" and text:find("^%[[^%]]*%]%([^)]*%)", i) then
      local label, url, stop = text:match("^%[([^%]]*)%]%(([^)]*)%)()", i)
      flush()
      segs[#segs + 1] = { label ~= "" and label or url, "MdvLink" }
      if url:match("^%a+://") then
        segs[#segs + 1] = { " \u{2197}", "MdvLinkIcon" }
      end
      i = stop
    elseif two == "**" or two == "__" and prev:match("[%s%p]") then
      toggle("b")
      i = i + 2
    elseif two == "~~" then
      toggle("s")
      i = i + 2
    elseif two == "==" then
      toggle("m")
      i = i + 2
    elseif ch == "*" or (ch == "_" and (prev:match("[%s%p]") or mods.i)) then
      toggle("i")
      i = i + 1
    elseif ch == "#" and prev:match("%s") and text:find("^#[^%s#%p]", i) or (ch == "#" and i == 1 and text:find("^#[^%s#]", i)) then
      local tag, stop = text:match("^(#[^%s,;:!%?%(%)%[%]\"'`]+)()", i)
      flush()
      segs[#segs + 1] = { "\u{e0b6}", "MdvTagCap", atomic = true, join = true }
      segs[#segs + 1] = { tag, "MdvTag", atomic = true, join = true }
      segs[#segs + 1] = { "\u{e0b4}", "MdvTagCap", atomic = true }
      i = stop
    else
      buf, i = buf .. ch, i + 1
    end
  end
  flush()
  return segs
end

-- ── Wrapping (by display width, words stay whole) ───────────────────────

local function seg_width(segs)
  local w = 0
  for _, s in ipairs(segs) do
    w = w + dw(s[1])
  end
  return w
end

-- segs → list of lines (each a list of segs), every line ≤ width
local function wrap(segs, width)
  width = math.max(width, 8)
  -- tokens: words (list of pieces glued together) and spaces
  local tokens, word = {}, nil
  local function push_piece(text, hl, target)
    word = word or { pieces = {}, w = 0 }
    table.insert(word.pieces, { text, hl, target = target })
    word.w = word.w + dw(text)
  end
  local function end_word()
    if word then
      tokens[#tokens + 1] = word
      word = nil
    end
  end
  for _, s in ipairs(segs) do
    if s.atomic then
      push_piece(s[1], s[2]) -- a pill or `code`: never split, glued to its neighbours
    else
      for part, spaces in s[1]:gmatch("([^ ]*)( *)") do
        if part ~= "" then
          push_piece(part, s[2], s.target)
        end
        if spaces ~= "" then
          end_word()
          tokens[#tokens + 1] = { space = spaces, hl = s[2] }
        end
      end
    end
  end
  end_word()

  local lines, cur, curw = {}, {}, 0
  local function newline()
    -- no trailing spaces
    while #cur > 0 and cur[#cur][1]:match("^ +$") do
      curw = curw - dw(cur[#cur][1])
      table.remove(cur)
    end
    lines[#lines + 1] = cur
    cur, curw = {}, 0
  end
  for _, t in ipairs(tokens) do
    if t.space then
      if curw > 0 then
        table.insert(cur, { t.space, t.hl })
        curw = curw + dw(t.space)
      end
    else
      if curw > 0 and curw + t.w > width then
        newline()
      end
      if t.w > width then -- longer than a line: cut by characters
        for _, p in ipairs(t.pieces) do
          local chars = vim.fn.split(p[1], "\\zs")
          for _, chr in ipairs(chars) do
            if curw + dw(chr) > width then
              newline()
            end
            table.insert(cur, { chr, p[2], target = p.target })
            curw = curw + dw(chr)
          end
        end
      else
        for _, p in ipairs(t.pieces) do
          table.insert(cur, p)
        end
        curw = curw + t.w
      end
    end
  end
  if #cur > 0 or #lines == 0 then
    newline()
  end
  return lines
end

-- ── Output ──────────────────────────────────────────────────────────────

-- out = { lines = {}, marks = {}, map = {src line → row}, callouts = {row → key}, images = {} }
-- ctx = { width, full, prefix = segs, bg = hl, out, margin, file, depth }

local function emit(ctx, segs, extra)
  local out = ctx.out
  local line, row = string.rep(" ", ctx.margin), #out.lines
  local start_all = #line
  local function add(text, hl, prio)
    local s = #line
    line = line .. text
    if hl and text ~= "" then
      table.insert(out.marks, { row, s, #line, hl, prio or 200 })
    end
  end
  for _, s in ipairs(ctx.prefix or {}) do
    add(s[1], s[2])
  end
  for _, s in ipairs(segs) do
    local from = #line
    add(s[1], s[2], s[3])
    if s.target then -- a [[link]]: Enter follows it
      table.insert(out.links, { row, from, #line, s.target })
    end
  end
  local bg = extra and extra.bg or ctx.bg
  if bg then
    local w = dw(line) - ctx.margin
    local full = extra and extra.full or ctx.full
    if w < full then
      line = line .. string.rep(" ", full - w)
    end
    table.insert(out.marks, { row, start_all, #line, bg, 100 })
  end
  out.lines[#out.lines + 1] = line
  return row
end

local function blank(ctx)
  local out = ctx.out
  if #out.lines == 0 then
    return
  end
  if ctx.prefix and #ctx.prefix > 0 then
    emit(ctx, {})
  elseif out.lines[#out.lines] ~= "" then
    out.lines[#out.lines + 1] = ""
  end
end

-- a paragraph-ish line with a first-line lead (bullet) and hanging indent
local function emit_wrapped(ctx, segs, lead, hang)
  lead, hang = lead or {}, hang or ""
  local lead_w = seg_width(lead)
  for k, l in ipairs(wrap(segs, ctx.width - lead_w)) do
    local row_segs = {}
    if k == 1 then
      vim.list_extend(row_segs, lead)
    else
      row_segs[1] = { string.rep(" ", lead_w) }
    end
    vim.list_extend(row_segs, l)
    emit(ctx, row_segs)
  end
end

-- ── Code card: night background, tree-sitter colours ─────────────────────

local LANG = { sh = "bash", shell = "bash", zsh = "bash", console = "bash", yml = "yaml", py = "python",
  js = "javascript", ts = "typescript", dockerfile = "dockerfile", ["c++"] = "cpp", tf = "hcl", terraform = "hcl" }

local CAPTURE = {
  keyword = "MdvCardKw", conditional = "MdvCardKw", ["repeat"] = "MdvCardKw", include = "MdvCardKw",
  ["function"] = "MdvCardFn", method = "MdvCardFn", constructor = "MdvCardType",
  string = "MdvCardStr", character = "MdvCardStr",
  number = "MdvCardNum", float = "MdvCardNum", boolean = "MdvCardNum", constant = "MdvCardNum",
  comment = "MdvCardCm", type = "MdvCardType", module = "MdvCardType", label = "MdvCardType",
  operator = "MdvCardOp", punctuation = "MdvCardPunct",
  property = "MdvCardProp", field = "MdvCardProp", attribute = "MdvCardProp", tag = "MdvCardType",
}

local function code_marks(code, lang)
  lang = LANG[lang] or lang
  if lang == "" or not pcall(vim.treesitter.language.add, lang) then
    return {}
  end
  local ok, parser = pcall(vim.treesitter.get_string_parser, code, lang)
  local query = ok and vim.treesitter.query.get(lang, "highlights")
  if not query then
    return {}
  end
  local res = {}
  local tree = parser:parse()[1]
  for id, node in query:iter_captures(tree:root(), code) do
    local name = query.captures[id]
    local group = CAPTURE[name] or CAPTURE[name:match("^[^.]+")]
    if name:match("^string%.escape") or name:match("^keyword%.exception") then
      group = "MdvCardImp"
    elseif name:match("%.builtin$") then
      group = "MdvCardFn"
    end
    if group then
      local sr, sc, er, ec = node:range()
      res[#res + 1] = { sr, sc, er, ec, group }
    end
  end
  return res
end

local function render_code(ctx, lines, lang)
  local out = ctx.out
  local inner = 0
  for _, l in ipairs(lines) do
    inner = math.max(inner, dw(l))
  end
  local avail = vim.o.columns - ctx.margin - seg_width(ctx.prefix or {}) - 2
  local width = math.min(math.max(ctx.width, inner + 4), avail)
  -- half-block rows above and below: a softer card edge than a full empty line
  emit(ctx, { { string.rep("\u{2584}", width), "MdvCardEdge" } })
  local marks = code_marks(table.concat(lines, "\n"), lang)
  local first_row = #out.lines
  for k, l in ipairs(lines) do
    local text = l
    if dw(text) > width - 4 then
      text = vim.fn.strcharpart(text, 0, width - 5) .. "\u{2026}"
    end
    local segs = { { "  " .. text, "MdvCard" } }
    if k == 1 and lang ~= "" and dw(text) + dw(lang) + 6 <= width then
      segs[2] = { string.rep(" ", width - dw(text) - dw(lang) - 4), "MdvCard" }
      segs[3] = { lang, "MdvCardLang" }
    end
    emit(ctx, segs, { bg = "MdvCard", full = width + seg_width(ctx.prefix or {}) })
  end
  if #lines == 0 then
    emit(ctx, {}, { bg = "MdvCard", full = width + seg_width(ctx.prefix or {}) })
  end
  emit(ctx, { { string.rep("\u{2580}", width), "MdvCardEdge" } })
  -- tree-sitter colours: shift by the margin + prefix + the 2-space padding
  local shift = ctx.margin + #table.concat(vim.tbl_map(function(s) return s[1] end, ctx.prefix or {})) + 2
  for _, m in ipairs(marks) do
    for r = m[1], m[3] do
      local src = lines[r + 1]
      if src then
        local s = r == m[1] and m[2] or 0
        local e = r == m[3] and m[4] or #src
        if e > s then
          table.insert(out.marks, { first_row + r, shift + s, math.min(shift + e, #out.lines[first_row + r + 1]), m[5], 210 })
        end
      end
    end
  end
end

-- ── Blocks ──────────────────────────────────────────────────────────────

local render -- forward

local function vault_root(file)
  local found = vim.fs.find(".obsidian", { upward = true, path = vim.fs.dirname(file), type = "directory" })[1]
  return found and vim.fs.dirname(found) or vim.fs.dirname(file)
end

-- an Obsidian link target → absolute path (next to the note, else anywhere in the vault)
local function resolve(file, name)
  local dir = vim.fs.dirname(file)
  local direct = vim.fs.normalize(name:sub(1, 1) == "/" and name or dir .. "/" .. name)
  if vim.uv.fs_stat(direct) then
    return direct
  end
  local base = vim.fs.basename(name)
  local hit = vim.fs.find(function(n) return n == base end, { path = vault_root(file), limit = 1, type = "file" })[1]
  return hit
end

-- caption centred in the column; the picture is drawn centred under it
local function image(ctx, alt, path)
  local caption = "\u{25a3} " .. alt
  local pad = math.max(0, math.floor((ctx.width - dw(caption)) / 2))
  local row = emit(ctx, { { string.rep(" ", pad) }, { caption, "MdvCaption" } })
  if path then
    local indent = ctx.margin + seg_width(ctx.prefix or {})
    table.insert(ctx.out.images, { row = row, path = path, width = ctx.width, indent = indent })
  end
end

-- ![[note#Heading]]: the section, under a bar, like an Obsidian embed
local function embed(ctx, target)
  local name, heading = target:match("^([^#|]*)#?([^|]*)")
  local title = (name ~= "" and name or vim.fn.fnamemodify(ctx.file, ":t:r")) .. (heading ~= "" and " › " .. heading or "")
  local sub = vim.tbl_extend("force", ctx, {
    prefix = vim.list_extend(vim.deepcopy(ctx.prefix or {}), { { "\u{258e} ", "MdvEmbedBar" } }),
    width = ctx.width - 2,
    depth = (ctx.depth or 0) + 1,
  })
  emit(sub, { { vim.fn.toupper(title), "MdvEmbedTitle" } })
  if name:match("%.base$") or sub.depth > 1 then
    emit(sub, { { "база Obsidian — открыть в приложении", "MdvCaption" } })
    return
  end
  local path = resolve(ctx.file, name ~= "" and (name:match("%.md$") and name or name .. ".md") or ctx.file)
  if not path then
    emit(sub, { { "заметка не найдена", "MdvCaption" } })
    return
  end
  local lines = vim.fn.readfile(path)
  if heading ~= "" then
    local from, level
    for k, l in ipairs(lines) do
      local hashes, text = l:match("^(#+)%s+(.-)%s*$")
      if hashes and not from and text == heading then
        from, level = k + 1, #hashes
      elseif hashes and from and #hashes <= level then
        lines = vim.list_slice(lines, from, k - 1)
        from = nil
        break
      end
    end
    if from then
      lines = vim.list_slice(lines, from)
    end
  end
  sub.file = path
  render(sub, lines, 0, true)
end

local function properties(ctx, yaml)
  -- key: value / key: [] / key:\n  - item
  local props, last = {}, nil
  for _, l in ipairs(yaml) do
    local key, val = l:match("^([%w_%-]+):%s*(.-)%s*$")
    if key then
      last = { key = key, items = {} }
      props[#props + 1] = last
      if val ~= "" and val ~= "[]" then
        last.items[1] = val
      end
    elseif last and l:match("^%s+%-%s+") then
      table.insert(last.items, (l:gsub("^%s+%-%s+", "")))
    end
  end
  if #props == 0 then
    return
  end
  local keyw = 0
  for _, p in ipairs(props) do
    keyw = math.max(keyw, dw(p.key))
  end
  local w = ctx.width
  local title = " \u{f02c} Свойства "
  emit(ctx, { { "\u{256d}\u{2500}", "MdvPropBorder" }, { title, "MdvPropTitle" },
    { string.rep("\u{2500}", w - dw(title) - 3) .. "\u{256e}", "MdvPropBorder" } })
  for _, p in ipairs(props) do
    local vals = {}
    for k, item in ipairs(p.items) do
      item = item:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
      if p.key == "tags" then
        vim.list_extend(vals, inline("#" .. item:gsub("^#", ""), "MdvPropVal"))
        vals[#vals + 1] = { " ", "MdvPropVal" }
      else
        vim.list_extend(vals, inline(item, "MdvPropVal"))
        if k < #p.items then
          vals[#vals + 1] = { ", ", "MdvPropKey" }
        end
      end
    end
    if #vals == 0 then
      vals = { { "—", "MdvPropKey" } }
    end
    local inner = w - keyw - 7
    for k, l in ipairs(wrap(vals, inner)) do
      local key = k == 1 and p.key or ""
      local row = { { "\u{2502}  ", "MdvPropBorder" }, { key .. string.rep(" ", keyw - dw(key) + 2), "MdvPropKey" } }
      vim.list_extend(row, l)
      row[#row + 1] = { string.rep(" ", math.max(0, inner - seg_width(l))) .. "\u{2502}", "MdvPropBorder" }
      emit(ctx, row)
    end
  end
  emit(ctx, { { "\u{2570}" .. string.rep("\u{2500}", w - 2) .. "\u{256f}", "MdvPropBorder" } })
end

local function table_block(ctx, rows)
  local cells, header = {}, nil
  for k, l in ipairs(rows) do
    if not l:match("^%s*|?%s*:?%-+:?%s*|") then
      local row = {}
      local body = l:gsub("^%s*|", ""):gsub("|%s*$", "")
      body = body:gsub("\\|", "\1")
      for cell in (body .. "|"):gmatch("(.-)|") do
        cell = vim.trim(cell:gsub("\1", "|"))
        row[#row + 1] = inline(k == 1 and vim.fn.toupper(cell) or cell, k == 1 and "MdvTableHead" or "MdvText")
      end
      cells[#cells + 1] = row
      header = header or row
    end
  end
  local ncol = 0
  for _, r in ipairs(cells) do
    ncol = math.max(ncol, #r)
  end
  local natural, total = {}, 0
  for c = 1, ncol do
    natural[c] = 3
    for _, r in ipairs(cells) do
      natural[c] = math.max(natural[c], r[c] and seg_width(r[c]) or 0)
    end
    total = total + natural[c]
  end
  local gap = 3
  local avail = ctx.width - gap * (ncol - 1)
  local widths = {}
  for c = 1, ncol do
    widths[c] = total <= avail and natural[c] or math.max(6, math.floor(avail * natural[c] / total))
  end
  local full = gap * (ncol - 1)
  for c = 1, ncol do
    full = full + widths[c]
  end
  local rule = { { string.rep("\u{2500}", full), "MdvTableRule" } }
  for k, r in ipairs(cells) do
    local wrapped, height = {}, 1
    for c = 1, ncol do
      wrapped[c] = wrap(r[c] or {}, widths[c])
      height = math.max(height, #wrapped[c])
    end
    for h = 1, height do
      local segs = {}
      for c = 1, ncol do
        local part = wrapped[c][h] or {}
        vim.list_extend(segs, part)
        if c < ncol then
          segs[#segs + 1] = { string.rep(" ", widths[c] - seg_width(part) + gap) }
        end
      end
      emit(ctx, segs)
    end
    emit(ctx, rule)
  end
end

local function heading(ctx, level, text)
  local base = "MdvH" .. level
  if level == 4 then
    text = vim.fn.toupper(text)
  end
  local segs = inline(text, base)
  if level == 3 then
    table.insert(segs, 1, { "\u{25c6} ", "MdvH3Mark" })
  end
  blank(ctx)
  table.insert(ctx.out.headings, #ctx.out.lines)
  emit_wrapped(ctx, segs)
  if level == 2 then
    emit(ctx, { { string.rep("\u{2500}", ctx.width), "MdvH2Rule" } })
  end
end

-- one level of list nesting = 2 spaces (or a tab) of indent
local function list_item(ctx, indent, marker, body)
  local level = math.floor(#indent:gsub("\t", "  ") / 2)
  local pad = string.rep("  ", level)
  local task, rest = body:match("^%[(.)%]%s+(.*)$")
  local lead
  local segs
  if task then
    local done = task ~= " "
    lead = { { pad }, done and { "\u{2713} ", "MdvTaskDone" } or { "\u{25cb} ", "MdvTaskOpen" } }
    segs = inline(rest, done and "MdvDoneText" or "MdvText")
  elseif marker:match("%d") then
    lead = { { pad }, { marker .. " ", "MdvBullet" } }
    segs = inline(body, "MdvText")
  else
    lead = { { pad }, { level == 0 and "\u{2022} " or "\u{25e6} ", "MdvBullet" } }
    segs = inline(body, "MdvText")
  end
  emit_wrapped(ctx, segs, lead)
end

-- strip one level of "> " from a quote / callout body
local function unquote(l)
  return (l:gsub("^%s*>%s?", "", 1))
end

render = function(ctx, lines, offset, nested)
  local out = ctx.out
  local i, n = 1, #lines
  local in_comment = false

  -- front matter → properties
  if not nested and lines[1] == "---" then
    for k = 2, n do
      if lines[k] == "---" then
        properties(ctx, vim.list_slice(lines, 2, k - 1))
        i = k + 1
        break
      end
    end
  end

  while i <= n do
    local l = lines[i]
    out.map[offset + i] = out.map[offset + i] or #out.lines

    if in_comment or l:match("^%s*%%%%") then -- %% Obsidian comments %%
      local opens = not in_comment
      local count = select(2, l:gsub("%%%%", ""))
      in_comment = (opens and count == 1) or (not opens and count == 0)
      i = i + 1
    elseif l:match("^%s*$") then
      blank(ctx)
      i = i + 1
    elseif l:match("^%s*```") or l:match("^%s*~~~") then
      local fence, lang = l:match("^%s*([`~]+)%s*([%w%+%-_]*)")
      local body = {}
      i = i + 1
      while i <= n and not lines[i]:match("^%s*" .. fence:sub(1, 1):rep(3)) do
        body[#body + 1] = lines[i]
        i = i + 1
      end
      i = i + 1
      render_code(ctx, body, lang:lower())
    elseif l:match("^#+%s") then
      local hashes, text = l:match("^(#+)%s+(.-)%s*#*%s*$")
      heading(ctx, math.min(#hashes, 6), text)
      i = i + 1
    elseif l:match("^%s*>%s*%[!%a+%]") then
      -- callout: header + following > lines
      local kind, fold, title = l:match("^%s*>%s*%[!(%a+)%]([-+]?)%s*(.*)$")
      local spec = CALLOUT[kind:lower()] or CALLOUT.note
      local family = spec[1]
      local key = (ctx.file or "") .. ":" .. (offset + i)
      local body = {}
      local j = i + 1
      while j <= n and lines[j]:match("^%s*>") do
        body[#body + 1] = unquote(lines[j])
        j = j + 1
      end
      local open = out.folds[key]
      if open == nil then
        open = fold ~= "-"
      end
      if title == "" then
        title = kind:sub(1, 1):upper() .. kind:sub(2):lower()
      end
      local sub = vim.tbl_extend("force", ctx, {
        prefix = vim.list_extend(vim.deepcopy(ctx.prefix or {}), { { "\u{258c} ", "MdvCallout" .. family .. "Bar" } }),
        bg = "MdvCallout" .. family .. "Bg",
        full = ctx.width + seg_width(ctx.prefix or {}),
        width = ctx.width - 2,
      })
      local head = { { spec[2] .. "  ", "MdvCallout" .. family .. "Title" } }
      vim.list_extend(head, inline(title, "MdvCallout" .. family .. "Title"))
      if fold ~= "" then
        head[#head + 1] = { open and "  \u{f078}" or "  \u{f054}", "MdvCallout" .. family .. "Title" }
      end
      local row = #out.lines
      emit_wrapped(sub, head)
      out.callouts[row] = { key = key, open = open }
      if open and #body > 0 then
        render(sub, body, offset + i, true)
      end
      i = j
    elseif l:match("^%s*>") then
      local body = {}
      while i <= n and lines[i]:match("^%s*>") do
        body[#body + 1] = unquote(lines[i])
        i = i + 1
      end
      local sub = vim.tbl_extend("force", ctx, {
        prefix = vim.list_extend(vim.deepcopy(ctx.prefix or {}), { { "\u{258e} ", "MdvQuoteBar" } }),
        width = ctx.width - 2,
        quote = true,
      })
      render(sub, body, offset + i - #body - 1, true)
    elseif l:match("^%s*|") then
      local rows = {}
      while i <= n and lines[i]:match("^%s*|") do
        rows[#rows + 1] = lines[i]
        i = i + 1
      end
      table_block(ctx, rows)
    elseif l:match("^%s*[-*_][-*_%s]*$") and select(2, l:gsub("[-*_]", "")) >= 3 then
      blank(ctx)
      emit(ctx, { { string.rep("\u{2500}", ctx.width), "MdvHr" } })
      i = i + 1
    elseif l:match("^%s*!%[%[.-%]%]%s*$") then
      local target = l:match("!%[%[(.-)%]%]")
      local name = target:match("^([^|#]*)")
      if IMAGE_EXT[(name:match("%.(%w+)$") or ""):lower()] then
        image(ctx, target:match("|(.*)$") or name, resolve(ctx.file, name))
      else
        embed(ctx, target)
      end
      i = i + 1
    elseif l:match("^%s*!%[.-%]%(.-%)%s*$") then
      local alt, path = l:match("!%[(.-)%]%((.-)%)")
      path = path:gsub("%s+[\"'].*$", ""):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
      local abs = not path:match("^%a+://") and resolve(ctx.file, path) or nil
      image(ctx, alt ~= "" and alt or vim.fs.basename(path), abs)
      i = i + 1
    elseif l:match("^%s*[-*+]%s+") or l:match("^%s*%d+[.)]%s+") then
      local indent, marker, body = l:match("^(%s*)([-*+])%s+(.*)$")
      if not indent then
        indent, marker, body = l:match("^(%s*)(%d+[.)])%s+(.*)$")
      end
      list_item(ctx, indent, marker, body)
      i = i + 1
    else
      -- a line of text: Obsidian keeps single line breaks
      emit_wrapped(ctx, inline(vim.trim(l), ctx.quote and "MdvQuote" or "MdvText"))
      i = i + 1
    end
  end
end

-- ── The view ────────────────────────────────────────────────────────────

local function draw(view)
  local win, buf = view.win, view.buf
  local width = api.nvim_win_get_width(win)
  local text_w = math.min(MAX_WIDTH, width - 6)
  local out = { lines = {}, marks = {}, map = {}, callouts = {}, images = {}, links = {}, headings = {},
    folds = view.folds }
  local ctx = { width = text_w, full = text_w, margin = math.max(2, math.floor((width - text_w) / 2)), out = out,
    file = view.file }
  local src = api.nvim_buf_get_lines(view.src, 0, -1, false)

  -- inline title: the file name, as Obsidian shows it above the note
  out.lines[1] = ""
  emit(ctx, { { vim.fn.fnamemodify(view.file, ":t:r"), "MdvTitle" } })
  out.lines[#out.lines + 1] = ""
  render(ctx, src, 0, false)
  out.lines[#out.lines + 1] = ""

  require("mdimage").clear(buf, view.image_ids)
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, out.lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(out.marks) do
    pcall(api.nvim_buf_set_extmark, buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4], priority = m[5] })
  end
  view.out = out

  view.image_ids = {}
  local max_rows = api.nvim_win_get_height(win) - 2
  for _, img in ipairs(out.images) do
    local id = require("mdimage").show(buf, img.row, img.path, img.width, max_rows, img.indent)
    if id then
      table.insert(view.image_ids, id)
    end
  end
end

function M.open()
  local src = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  if vim.bo[src].modified then
    vim.cmd("silent write")
  end
  local cursor = api.nvim_win_get_cursor(win)[1]
  local buf = api.nvim_create_buf(false, true)
  local view = { src = src, buf = buf, win = win, file = api.nvim_buf_get_name(src), folds = {}, image_ids = {} }
  vim.b[buf].no_insert = true -- the status line shows "reading"
  vim.bo[buf].bufhidden = "wipe"
  api.nvim_win_set_buf(win, buf)
  for opt, val in pairs({ wrap = false, number = false, relativenumber = false, signcolumn = "no",
    cursorline = false, list = false, colorcolumn = "", winbar = "", conceallevel = 0 }) do
    vim.wo[win][opt] = val
  end
  draw(view)

  -- start where the editor cursor was
  local row = 0
  for line = cursor, 1, -1 do
    if view.out.map[line] then
      row = view.out.map[line]
      break
    end
  end
  pcall(api.nvim_win_set_cursor, win, { row + 1, 0 })

  local function back()
    require("mdimage").clear(buf, view.image_ids)
    if api.nvim_buf_is_valid(src) then
      api.nvim_win_set_buf(win, src)
    end
    if api.nvim_buf_is_valid(buf) then
      api.nvim_buf_delete(buf, { force = true })
    end
  end
  local function enter()
    local r, col = unpack(api.nvim_win_get_cursor(win))
    local c = view.out.callouts[r - 1]
    if c then
      view.folds[c.key] = not c.open
      draw(view)
      pcall(api.nvim_win_set_cursor, win, { r, 0 })
      return
    end
    for _, link in ipairs(view.out.links) do
      if link[1] == r - 1 and col >= link[2] and col < link[3] then
        local name = link[4]:match("^([^#]*)")
        local path = name == "" and view.file or resolve(view.file, name:match("%.md$") and name or name .. ".md")
        if not path then
          vim.notify("Заметка не найдена: " .. name, vim.log.levels.WARN)
          return
        end
        back()
        vim.cmd.edit(vim.fn.fnameescape(path))
        M.open()
        return
      end
    end
  end
  local function jump(dir)
    local r = api.nvim_win_get_cursor(win)[1] - 1
    local list = view.out.headings
    for k = dir > 0 and 1 or #list, dir > 0 and #list or 1, dir do
      if (dir > 0 and list[k] > r) or (dir < 0 and list[k] < r) then
        api.nvim_win_set_cursor(win, { list[k] + 1, 0 })
        vim.cmd("normal! zt")
        return
      end
    end
  end
  for _, key in ipairs({ "q", "<leader>p" }) do
    vim.keymap.set("n", key, back, { buffer = buf, desc = "Back to the editor" })
  end
  for _, key in ipairs({ "<CR>", "za" }) do
    vim.keymap.set("n", key, enter, { buffer = buf, desc = "Fold the callout / follow the link" })
  end
  vim.keymap.set("n", "]]", function() jump(1) end, { buffer = buf, desc = "Next heading" })
  vim.keymap.set("n", "[[", function() jump(-1) end, { buffer = buf, desc = "Previous heading" })
  api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function()
      if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
        draw(view)
      end
    end,
  })
end

return M
