-- Images inside the Markdown reading view (<leader>p).
--
-- glow can only print an image as a link, so the preview swaps every
-- `![alt](path)` line for a "▣ alt" caption and this module draws the
-- picture under it. It speaks the kitty graphics protocol (Ghostty
-- understands it): the PNG is sent to the terminal once, and nvim shows
-- it with Unicode placeholders — cells of U+10EEEE whose colour is the
-- image id and whose diacritics are the row/column of the tile. They are
-- ordinary text in virtual lines, so the picture scrolls with the buffer.
-- Inside tmux the escapes go through DCS passthrough (allow-passthrough).
local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("mdimage")
local PLACEHOLDER = "\u{10EEEE}"
-- assumed cell size in pixels: only used to pick a sensible box size,
-- the terminal keeps the aspect ratio inside the box itself
local CELL_W, CELL_H = 9, 18

-- row/column diacritics from kitty's gen/rowcolumn-diacritics.txt
-- (the first 200: images are never wider or taller than that in cells)
-- stylua: ignore
local DIACRITICS = {
  0x0305,0x030D,0x030E,0x0310,0x0312,0x033D,0x033E,0x033F,0x0346,0x034A,0x034B,0x034C,0x0350,0x0351,
  0x0352,0x0357,0x035B,0x0363,0x0364,0x0365,0x0366,0x0367,0x0368,0x0369,0x036A,0x036B,0x036C,0x036D,
  0x036E,0x036F,0x0483,0x0484,0x0485,0x0486,0x0487,0x0592,0x0593,0x0594,0x0595,0x0597,0x0598,0x0599,
  0x059C,0x059D,0x059E,0x059F,0x05A0,0x05A1,0x05A8,0x05A9,0x05AB,0x05AC,0x05AF,0x05C4,0x0610,0x0611,
  0x0612,0x0613,0x0614,0x0615,0x0616,0x0617,0x0657,0x0658,0x0659,0x065A,0x065B,0x065D,0x065E,0x06D6,
  0x06D7,0x06D8,0x06D9,0x06DA,0x06DB,0x06DC,0x06DF,0x06E0,0x06E1,0x06E2,0x06E4,0x06E7,0x06E8,0x06EB,
  0x06EC,0x0730,0x0732,0x0733,0x0735,0x0736,0x073A,0x073D,0x073F,0x0740,0x0741,0x0743,0x0745,0x0747,
  0x0749,0x074A,0x07EB,0x07EC,0x07ED,0x07EE,0x07EF,0x07F0,0x07F1,0x07F3,0x0816,0x0817,0x0818,0x0819,
  0x081B,0x081C,0x081D,0x081E,0x081F,0x0820,0x0821,0x0822,0x0823,0x0825,0x0826,0x0827,0x0829,0x082A,
  0x082B,0x082C,0x082D,0x0951,0x0953,0x0954,0x0F82,0x0F83,0x0F86,0x0F87,0x135D,0x135E,0x135F,0x17DD,
  0x193A,0x1A17,0x1A75,0x1A76,0x1A77,0x1A78,0x1A79,0x1A7A,0x1A7B,0x1A7C,0x1B6B,0x1B6D,0x1B6E,0x1B6F,
  0x1B70,0x1B71,0x1B72,0x1B73,0x1CD0,0x1CD1,0x1CD2,0x1CDA,0x1CDB,0x1CE0,0x1DC0,0x1DC1,0x1DC3,0x1DC4,
  0x1DC5,0x1DC6,0x1DC7,0x1DC8,0x1DC9,0x1DCB,0x1DCC,0x1DD1,0x1DD2,0x1DD3,0x1DD4,0x1DD5,0x1DD6,0x1DD7,
  0x1DD8,0x1DD9,0x1DDA,0x1DDB,0x1DDC,0x1DDD,0x1DDE,0x1DDF,0x1DE0,0x1DE1,0x1DE2,0x1DE3,0x1DE4,0x1DE5,
  0x1DE6,0x1DFE,0x20D0,0x20D1,
}
for i, cp in ipairs(DIACRITICS) do
  DIACRITICS[i] = vim.fn.nr2char(cp)
end

local next_id = 0x4d4400 -- any non-zero 24-bit number; "MD" + counter

-- write an escape sequence straight to the terminal nvim runs in
local function send(seq)
  if vim.env.TMUX then
    seq = "\027Ptmux;" .. seq:gsub("\027", "\027\027") .. "\027\\"
  end
  api.nvim_ui_send(seq)
end

-- width and height of a PNG from its IHDR chunk
local function png_size(data)
  if data:sub(1, 8) ~= "\137PNG\r\n\26\n" then
    return nil
  end
  local function u32(at)
    local a, b, c, d = data:byte(at, at + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return u32(17), u32(21)
end

-- send the PNG and create a virtual placement `cols` x `rows` cells big
local function transmit(id, data, cols, rows)
  local b64 = vim.base64.encode(data)
  local chunk = 4096
  for i = 1, #b64, chunk do
    local more = i + chunk <= #b64 and 1 or 0
    local keys = i == 1
        and string.format("a=T,U=1,f=100,q=2,i=%d,c=%d,r=%d,m=%d", id, cols, rows, more)
      or string.format("m=%d", more)
    send(string.format("\027_G%s;%s\027\\", keys, b64:sub(i, i + chunk - 1)))
  end
end

-- Draw the image file `path` as virtual lines under `line` (0-based) of
-- `buf`, at most `max_cols` cells wide and `max_rows` tall. Returns the
-- image id (for M.clear) or nil when the file is missing or not a PNG.
-- indent: columns left of the box max_cols wide; the picture is centred in it
function M.show(buf, line, path, max_cols, max_rows, indent)
  local fd = io.open(path, "rb")
  if not fd then
    return nil
  end
  local data = fd:read("*a")
  fd:close()
  local w, h = png_size(data)
  if not w then
    return nil
  end

  -- fit into the window, never upscale past the picture's own size
  local cols = math.min(max_cols, #DIACRITICS, math.ceil(w / CELL_W))
  local rows = math.ceil(cols * (h / w) * (CELL_W / CELL_H))
  if rows > max_rows then
    rows = max_rows
    cols = math.min(cols, math.ceil(rows * (w / h) * (CELL_H / CELL_W)))
  end
  rows = math.min(rows, #DIACRITICS)

  next_id = next_id + 1
  local id = next_id
  transmit(id, data, cols, rows)

  -- the foreground colour of the placeholder cells is the image id
  local hl = "MdImage" .. id
  api.nvim_set_hl(0, hl, { fg = string.format("#%06x", id) })
  local virt = { { { "" } } }
  for r = 1, rows do
    local cells = {}
    for c = 1, cols do
      cells[c] = PLACEHOLDER .. DIACRITICS[r] .. DIACRITICS[c]
    end
    local left = indent and indent + math.floor((max_cols - cols) / 2) or 2
    virt[#virt + 1] = { { string.rep(" ", left) }, { table.concat(cells), hl } }
  end
  virt[#virt + 1] = { { "" } }
  api.nvim_buf_set_extmark(buf, ns, line, 0, { virt_lines = virt })
  return id
end

-- forget the images (terminal memory) and their virtual lines
function M.clear(buf, ids)
  for _, id in ipairs(ids) do
    send(string.format("\027_Ga=d,d=I,q=2,i=%d\027\\", id))
  end
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

return M
