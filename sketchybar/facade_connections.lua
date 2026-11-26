local M = {}
local opened

M.style = {
  align = "center",
  y_offset = 6,
  height = 25,
  blur_radius = 24,
  background = {
    color = 0xf6241c18,
    border_color = 0xa06d5948,
    border_width = 1,
    corner_radius = 12,
  },
}

local networksetup = "/usr/sbin/networksetup"
local scutil = "/usr/sbin/scutil"
local blueutil = "/opt/homebrew/bin/blueutil"
local scan = '"$HOME/.config/sketchybar/helpers/facade-wifi-report.sh"'
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
  if #items > 6 then rows[#rows + 1] = { text = "+" .. (#items - 6) .. " more", muted = true } end
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
          if transient then
            rows[#rows + 1] = { text = name, value = state }
          else
            rows[#rows + 1] = {
              text = name,
              toggle = connected,
              command = scutil .. " --nc " .. (connected and "stop " or "start ") .. id,
            }
          end
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
      sbar.exec(scan, function(report)
        local has_report = type(report) == "table"
        local current = has_report and report.current
        local connected = has_report and report.connected
        local unavailable = connected and "Connected (name hidden)" or "Not connected"
        if not has_report then unavailable = "Network status unavailable" end
        table.insert(rows, 2, { text = "Current network", header = true })
        table.insert(rows, 3, { text = current or unavailable, muted = not current })
        if has_report and report.permission == "required" then
          table.insert(rows, 4, { text = "Allow network names ›", command = scan .. " request", link = true })
        end
        if has_report and #report.nearby > 0 then
          add_list(rows, "Nearby networks", report.nearby)
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
      sbar.exec("/usr/sbin/system_profiler SPBluetoothDataType -json", function(report)
        local profiled = type(report) == "table" and (report.SPBluetoothDataType or {})[1]
        local valid = {}
        local function address_key(address)
          return (address or ""):gsub("[^%x]", ""):lower()
        end
        if profiled then
          for _, entry in ipairs(profiled.device_not_connected or {}) do
            for _, info in pairs(entry) do
              if info.device_minorType or info.device_productID or info.device_vendorID or info.device_services then
                local key = address_key(info.device_address)
                if #key == 12 then valid[key] = true end
              end
            end
          end
        end
        table.sort(devices, function(a, b)
          if a.connected ~= b.connected then return not not a.connected end
          return (a.name or "") < (b.name or "")
        end)
        local names = {}
        for _, device in ipairs(devices) do
          if (device.connected or valid[address_key(device.address)]) and device.name and device.name ~= "" then
            names[#names + 1] = (device.connected and "● " or "○ ") .. device.name
          end
        end
        add_list(rows, "Paired devices", names)
        done(rows)
      end)
    end)
  end)
end

function M.attach(sbar, item, name, kind, options)
  options = options or {}
  local host = options.host or item
  local width = options.width or 212
  local inset, toggle_width = 12, 34
  local active = false
  local epoch = 0
  local menu_items, actions = {}, {}
  local load = options.load or (kind == "wifi" and wifi_rows or bluetooth_rows)

  local render, redraw

  local function on_click(i, env)
    local command = actions[i]
    if env.BUTTON ~= "left" or not active or not command then return end
    epoch = epoch + 1
    local request = epoch
    render({ { text = "Updating…" } })
    sbar.exec(command, function(_, code)
      sbar.delay(1, function()
        sbar.trigger("facade_connections_changed")
        if not active or epoch ~= request then return end
        redraw(code ~= 0 and "The system rejected the change" or nil)
      end)
    end)
  end

  render = function(rows)
    for i, row in ipairs(rows) do
      local text = row.text:gsub("[%c]", " ")
      local properties = {
        position = "popup." .. name,
        width = width,
        drawing = true,
        icon = { drawing = false },
        label = {
          string = text,
          font = row.header and "SF Mono:Bold:11" or "SF Mono:Semibold:12",
          color = row.header and 0xffd0a07e or row.link and 0xfff0c9a0 or row.muted and 0xffa9998b or 0xffe3dccb,
          padding_left = inset,
          padding_right = inset,
          max_chars = math.floor((width - 2 * inset) / 7.3),
          width = width,
          align = "left",
          background = { drawing = false },
        },
        padding_left = 0,
        padding_right = 0,
      }
      if row.center then
        properties.label.width = width
        properties.label.align = "center"
      elseif row.toggle ~= nil or row.value then
        local with_toggle = row.toggle ~= nil
        local right_width = with_toggle and toggle_width or (row.value_width or 88)
        properties.icon = {
          drawing = true,
          string = text,
          font = "SF Mono:Semibold:12",
          color = 0xffe3dccb,
          width = width - right_width,
          padding_left = inset,
          max_chars = math.floor((width - right_width - inset - 6) / 7.3),
        }
        properties.label = {
          string = with_toggle and " " or row.value,
          font = "SF Mono:Semibold:12",
          color = row.muted and 0xffa9998b or 0xffe3dccb,
          align = "right",
          width = right_width,
          padding_left = 0,
          padding_right = inset,
          background = { drawing = false },
        }
        if with_toggle then
          properties.label.background = {
            drawing = true,
            image = {
              string = asset_dir .. (row.toggle and "facade-toggle-on.png" or "facade-toggle-off.png"),
              scale = 0.5,
            },
          }
        end
      end
      actions[i] = row.command
      if menu_items[i] then
        menu_items[i]:set(properties)
      else
        local menu = sbar.add("item", name .. ".menu." .. i, properties)
        menu_items[i] = menu
        menu:subscribe("mouse.clicked", function(env) on_click(i, env) end)
      end
    end
    for i = #rows + 1, #menu_items do
      actions[i] = nil
      menu_items[i]:set({ drawing = false })
    end
    if active then host:set({ popup = { drawing = true } }) end
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
    host:set({ popup = { drawing = false } })
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
  -- The popup sits below the bar with a gap. Closing on mouse exit
  -- makes the controls disappear while the pointer crosses that gap.
  item:subscribe("aerospace_refresh", close)
  return function()
    close()
    for i in ipairs(menu_items) do sbar.remove(name .. ".menu." .. i) end
  end
end

return M
