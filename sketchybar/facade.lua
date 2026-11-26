local palette = {
  muted_blue = 0xffb8ccdf,
  linen = 0xffe6dcc6,
  sand = 0xffd6c8ab,
  peach = 0xfff0c9a0,
  ink = 0xff2a1f1b,
  blue = 0xffc9dbe8,
  navy = 0xff1e3a5f,
  slate = 0xff355468,
  clay = 0xff8e4233,
  rim = 0x381e3a5f,
}

local battery_icons = require("icons").battery
local connections = require("facade_connections")
local aerospace = "/opt/homebrew/bin/aerospace"
local font = "SF Mono:Heavy:14"
local home = os.getenv("HOME")
local edge, gap = 14, 7

local function symbol(name)
  return {
    drawing = true,
    image = { string = home .. "/.config/sketchybar/assets/facade-" .. name .. ".png", scale = 0.5, padding_left = 9 },
  }
end

local function pill(position, fill, foreground)
  return {
    position = position,
    y_offset = -5,
    padding_left = 0,
    padding_right = gap,
    icon = { drawing = false },
    label = { color = foreground, font = font, padding_left = 12, padding_right = 12 },
    background = {
      drawing = true, height = 28, corner_radius = 14,
      color = fill, border_color = palette.rim, border_width = 1,
    },
  }
end

return function(sbar)
  sbar.bar({
    display = "all", position = "top", height = 38, notch_width = 210,
    color = 0x00000000, blur_radius = 0, shadow = false,
    padding_left = edge, padding_right = edge - gap,
  })

  local displays = {}
  sbar.add("event", "facade_connections_changed")
  local status_values = {
    battery = { drawing = false },
    wifi = { icon = { background = symbol("wifi-off") } },
    audio = { icon = { background = symbol("bluetooth") } },
  }

  local function set_status(name, properties)
    status_values[name] = properties
    for _, display in pairs(displays) do
      display.status[name]:set(properties)
    end
  end

  local function add_status(display_id, built_in)
    local positions = built_in
      and { clock = "e", wifi = "q", audio = "q", battery = "e" }
      or { clock = "center", wifi = "right", audio = "left", battery = "right" }
    local order = built_in and { "clock", "wifi", "audio", "battery" } or { "clock", "battery", "audio", "wifi" }
    local fill = { clock = palette.linen, battery = palette.blue, audio = palette.sand, wifi = palette.muted_blue }
    local status, close_menus = {}, {}
    for _, name in ipairs(order) do
      local foreground = name == "clock" and palette.ink or palette.slate
      local props = pill(positions[name], fill[name], foreground)
      props.associated_display = display_id
      if built_in and name == "wifi" then props.padding_right = 0 end
      if name == "clock" then
        if not built_in then props.padding_right = 0 end
      elseif name == "battery" then
        props.icon = { drawing = true, font = "SF Pro:Medium:14", padding_left = 12, padding_right = 5 }
        props.label.padding_left = 0
      else
        props.icon = { drawing = true, string = " ", width = 40 }
        props.label.drawing = false
        props.popup = connections.style
      end
      local item_name = "facade." .. name .. "." .. display_id
      status[name] = sbar.add("item", item_name, props)
      if props.popup then close_menus[name] = connections.attach(sbar, status[name], item_name, name) end
      if status_values[name] then status[name]:set(status_values[name]) end
    end
    return status, close_menus
  end

  local status = sbar.add("item", "facade.status", { drawing = false, updates = true, update_freq = 8 })
  local power = sbar.add("item", "facade.power", { drawing = false, updates = true, update_freq = 120 })

  local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
  local last_clock

  local last_battery
  power:subscribe({ "forced", "routine", "power_source_change", "system_woke" }, function()
    sbar.exec("/usr/bin/pmset -g batt", function(output)
      local charge = tonumber(output:match("(%d+)%%"))
      if not charge then return end

      local on_ac = output:find("AC Power", 1, true) ~= nil
      local state = charge .. ":" .. tostring(on_ac)
      if state == last_battery then return end
      last_battery = state

      local glyph = (on_ac and battery_icons.charging)
        or (charge > 75 and battery_icons._100)
        or (charge > 50 and battery_icons._75)
        or (charge > 25 and battery_icons._50)
        or (charge > 10 and battery_icons._25)
        or battery_icons._0
      local color = (charge <= 20 and not on_ac) and palette.clay or palette.slate
      set_status("battery", {
        drawing = true,
        icon = { string = glyph, color = color },
        label = { string = charge .. "%", color = color },
      })
    end)
  end)

  local audio_icon, wifi_icon = "bluetooth", "wifi-off"
  local status_script = [[
    wifi=wifi-off
    if /sbin/ifconfig en0 | /usr/bin/grep -q 'status: active'; then wifi=wifi; fi
    if /usr/sbin/scutil --nc list | /usr/bin/grep -q '(Connected)'; then wifi="$wifi-locked"; fi
    audio=$("$HOME/.local/bin/sketchybar-facade-audio")
    printf '%s|%s\n' "$wifi" "$audio"
  ]]
  local status_running = false
  status:subscribe({ "forced", "routine", "system_woke", "wifi_change", "volume_change", "facade_connections_changed" }, function()
    local now = os.date("*t")
    local label = string.format("%d %s  %02d:%02d", now.day, months[now.month], now.hour, now.min)
    if label ~= last_clock then
      last_clock = label
      set_status("clock", { label = { string = label } })
    end

    if status_running then return end
    status_running = true
    sbar.exec(status_script, function(output)
      status_running = false
      local next_wifi, next_audio = output:match("^([%a-]+)|([%a-]*)")
      if next_wifi and next_wifi ~= wifi_icon then
        wifi_icon = next_wifi
        set_status("wifi", { icon = { background = symbol(wifi_icon) } })
      end
      if next_audio and next_audio ~= "" and next_audio ~= audio_icon then
        audio_icon = next_audio
        set_status("audio", { icon = { background = symbol(audio_icon) } })
      end
    end)
  end)

  sbar.add("event", "aerospace_refresh")
  sbar.add("event", "aerospace_mode_change")
  sbar.add("event", "aerospace_resync")
  local listener = sbar.add("item", "facade.listener", { drawing = false, updates = true })
  local mode = "main"
  local refreshing = false
  local pending = false
  local assignments = {}
  local focused_workspace
  local topology_pending = false

  local function remove_display(id, desktop)
    for _, close in pairs(desktop.close_menus) do close() end
    sbar.remove("facade.desktop." .. id)
    for name in pairs(desktop.status) do sbar.remove("facade." .. name .. "." .. id) end
    displays[id] = nil
  end

  local function render(display, workspace, focused, built_in)
    local desktop = displays[display]
    if desktop and desktop.built_in ~= built_in then
      remove_display(display, desktop)
      desktop = nil
    end
    if not desktop then
      local props = pill(built_in and "q" or "left", palette.muted_blue, palette.navy)
      props.associated_display = display
      props.icon = { drawing = true, color = palette.slate, font = "SF Pro:Semibold:9", padding_left = 12, padding_right = 7 }
      props.label.padding_left = 0
      local status, close_menus
      if built_in then status, close_menus = add_status(display, true) end
      local item = sbar.add("item", "facade.desktop." .. display, props)
      if not built_in then status, close_menus = add_status(display, false) end
      desktop = { item = item, status = status, close_menus = close_menus, built_in = built_in }
      displays[display] = desktop
    end

    desktop.workspace = workspace
    local label = workspace
    if focused and mode ~= "main" then label = label .. "  ·  " .. mode end
    if desktop.label == label and desktop.focused == focused then return end
    desktop.label, desktop.focused = label, focused
    desktop.item:set({
      drawing = true,
      icon = { string = focused and "●" or "○", color = focused and palette.slate or palette.navy },
      label = { string = label, color = focused and palette.ink or palette.navy },
      background = { color = focused and palette.peach or palette.muted_blue },
    })
  end

  local function refresh()
    if refreshing then
      pending = true
      return
    end
    refreshing = true
    sbar.exec(aerospace .. " list-workspaces --all --format '%{monitor-appkit-nsscreen-screens-id}|%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}|%{monitor-name}'", function(output)
      local visible, next_assignments = {}, {}
      local next_focus
      for line in output:gmatch("[^\r\n]+") do
        local id, workspace, focused, shown, monitor = line:match("^(%d+)|(.+)|(%a+)|(%a+)|(.+)$")
        if id then
          local display = tonumber(id)
          next_assignments[workspace] = display
          if focused == "true" then next_focus = workspace end
          if shown == "true" then
            visible[display] = true
            render(display, workspace, focused == "true", monitor:lower():find("built-in", 1, true) ~= nil)
          end
        end
      end
      if next(visible) then
        assignments, focused_workspace = next_assignments, next_focus
        for display, desktop in pairs(displays) do
          if not visible[display] then remove_display(display, desktop) end
        end
      end
      refreshing = false
      if pending then
        pending = false
        refresh()
      end
    end)
  end

  local topology_event = 0
  listener:subscribe({ "display_change", "system_woke" }, function()
    topology_event = topology_event + 1
    topology_pending = true
    local event = topology_event
    -- Let both apps settle on the new display arrangement before reconciling.
    sbar.delay(0.6, function()
      if event == topology_event then
        topology_pending = false
        refresh()
      end
    end)
  end)

  local function workspace_changed(env)
    local workspace = env.FOCUSED
    local display = assignments[workspace]
    if topology_pending or refreshing or not displays[display] or env.PREVIOUS ~= focused_workspace then
      refresh()
      return
    end

    focused_workspace = workspace
    for id, desktop in pairs(displays) do
      local focused = id == display
      render(id, focused and workspace or desktop.workspace, focused, desktop.built_in)
    end
  end

  listener:subscribe("aerospace_refresh", workspace_changed)
  listener:subscribe("aerospace_resync", refresh)
  local function refresh_mode()
    sbar.exec(aerospace .. " list-modes --current", function(output)
      mode = output:match("^%s*(%S+)") or "main"
      refresh()
    end)
  end

  listener:subscribe("aerospace_mode_change", refresh_mode)
  refresh_mode()
end
