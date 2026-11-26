local M = {}
local opened

M.style = {
  align = "center",
  y_offset = 7,
  blur_radius = 22,
  background = {
    color = 0xf51c1513,
    border_color = 0x806d5948,
    border_width = 1,
    corner_radius = 10,
  },
}

local networksetup = "/usr/sbin/networksetup"
local scutil = "/usr/sbin/scutil"
local blueutil = "/opt/homebrew/bin/blueutil"
local scan = '"$HOME/.local/bin/sketchybar-facade-wifi"'
local asset_dir = os.getenv("HOME") .. "/.config/sketchybar/assets/"

local function rows_from(output)
  local rows = {}
  for line in output:gmatch("[^\r\n]+") do rows[#rows + 1] = line end
  return rows
end

local function add_list(rows, title, items)
  rows[#rows + 1] = { text = title, header = true }
  if #items == 0 then
    rows[#rows + 1] = { text = "None" }
    return
  end
  for index = 1, math.min(#items, 6) do rows[#rows + 1] = { text = items[index] } end
  if #items > 6 then rows[#rows + 1] = { text = "+" .. (#items - 6) .. " more" } end
end

local function wifi_rows(sbar, done)
  sbar.exec(networksetup .. " -getairportpower en0", function(power, code)
    local on = power:match(": On%s*$") ~= nil
    local rows = {}
    if code == 0 then
      rows[1] = {
        text = "Wi-Fi", toggle = on,
        command = networksetup .. " -setairportpower en0 " .. (on and "off" or "on"),
      }
    else
      rows[1] = { text = "Wi-Fi status unavailable" }
    end
    rows[#rows + 1] = { text = "VPN", header = true }
    sbar.exec(scutil .. " --nc list", function(output)
      local count = 0
      for line in output:gmatch("[^\r\n]+") do
        local state, id, name = line:match('%((%a+)%)%s+([%x%-]+)%s+VPN%s+.-"(.-)"')
        if id and #id == 36 then
          local connected = state == "Connected"
          local transient = state == "Connecting" or state == "Disconnecting"
          rows[#rows + 1] = {
            text = (transient and state .. " · " or connected and "Disconnect · " or "Connect · ") .. name,
            command = not transient and scutil .. " --nc " .. (connected and "stop " or "start ") .. id or nil,
          }
          count = count + 1
        end
      end
      if count == 0 then rows[#rows + 1] = { text = "No VPN profiles" } end
      if not on then
        done(rows)
        return
      end
      -- Draw controls as soon as they are ready, then replace the scanning row.
      local pending_rows = {}
      for i, row in ipairs(rows) do pending_rows[i] = row end
      pending_rows[#pending_rows + 1] = { text = "Scanning Wi-Fi…" }
      done(pending_rows)
      sbar.exec(scan, function(out)
        if type(out) == "table" and #out > 0 then
          add_list(rows, "Nearby networks", out)
          done(rows)
          return
        end
        sbar.exec(networksetup .. " -listpreferredwirelessnetworks en0", function(saved)
          local networks = rows_from(saved)
          table.remove(networks, 1)
          for i, network in ipairs(networks) do networks[i] = network:match("^%s*(.-)%s*$") end
          add_list(rows, "Saved networks", networks)
          done(rows)
        end)
      end)
    end)
  end)
end

local function bluetooth_rows(sbar, done)
  sbar.exec(blueutil .. " --power", function(out, code)
    if code ~= 0 then done({ { text = "Bluetooth access unavailable" } }); return end
    local on = out:match("^1%s*$") ~= nil
    local rows = {
      {
        text = "Bluetooth", toggle = on,
        command = blueutil .. " --power " .. (on and "0" or "1"),
      },
    }
    if not on then done(rows); return end
    sbar.exec(blueutil .. " --paired --format json", function(devices)
      if type(devices) ~= "table" then
        rows[#rows + 1] = { text = "Paired devices unavailable" }
        done(rows)
        return
      end
      table.sort(devices, function(a, b)
        if a.connected ~= b.connected then return not not a.connected end
        return (a.name or "") < (b.name or "")
      end)
      local names = {}
      for _, device in ipairs(devices) do
        if device.name and device.name ~= "" then
          names[#names + 1] = (device.connected and "● " or "○ ") .. device.name
        end
      end
      add_list(rows, "Paired devices", names)
      done(rows)
    end)
  end)
end

function M.attach(sbar, item, name, kind)
  local active = false
  local epoch = 0
  local count = 0
  local load = kind == "wifi" and wifi_rows or bluetooth_rows

  local function clear()
    for i = 1, count do sbar.remove(name .. ".menu." .. i) end
    count = 0
  end

  local redraw
  local function render(rows)
    clear()
    for i, row in ipairs(rows) do
      count = i
      local label = (row.command and "›  " or "") .. row.text
      local properties = {
        position = "popup." .. name,
        icon = { drawing = false },
        label = {
          string = label:gsub("[%c]", " "),
          font = row.header and "SF Mono:Bold:11" or "SF Mono:Semibold:12",
          color = row.header and 0xffd0a07e or row.command and 0xfff0c9a0 or 0xffe3dccb,
          padding_left = 11,
          padding_right = 11,
          max_chars = 34,
        },
        background = { height = 24 },
        padding_left = 0,
        padding_right = 0,
      }
      if row.toggle ~= nil then
        properties.icon = {
          string = row.text,
          font = "SF Mono:Bold:12",
          color = 0xffe3dccb,
          width = 146,
          padding_left = 11,
        }
        properties.label = {
          string = " ",
          width = 33,
          background = {
            drawing = true,
            image = {
              string = asset_dir .. (row.toggle and "facade-toggle-on.png" or "facade-toggle-off.png"),
              scale = 0.5,
            },
          },
        }
      end
      local menu = sbar.add("item", name .. ".menu." .. i, properties)
      if row.command then
        menu:subscribe("mouse.clicked", function(env)
          if env.BUTTON ~= "left" or not active then return end
          epoch = epoch + 1
          local request = epoch
          render({ { text = "Updating…" } })
          sbar.exec(row.command, function(_, code)
            sbar.delay(1, function()
              sbar.trigger("facade_connections_changed")
              if not active or epoch ~= request then return end
              redraw(code ~= 0 and "The system rejected the change" or nil)
            end)
          end)
        end)
      end
    end
    if active then item:set({ popup = { drawing = true } }) end
  end

  redraw = function(message)
    epoch = epoch + 1
    local request = epoch
    load(sbar, function(rows)
      if not active or request ~= epoch then return end
      if message then table.insert(rows, 1, { text = message }) end
      render(rows)
    end)
  end

  local function close()
    if not active then return end
    active = false
    opened = nil
    epoch = epoch + 1
    item:set({ popup = { drawing = false } })
    clear()
  end

  item:subscribe("mouse.clicked", function(env)
    if env.BUTTON ~= "left" then return end
    if active then close(); return end
    if opened then opened() end
    active = true
    opened = close
    render({ { text = "Loading…" } })
    redraw()
  end)
  item:subscribe("mouse.exited.global", close)
  return close
end

return M
