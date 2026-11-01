local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local capsule = require("helpers.capsule")

local keyboard_settings = {
	default_label = "??",
	event_name = "input_change",
	notification = "AppleSelectedInputSourcesChangedNotification",
	layout_aliases = {
		Russian = "RU",
		RussianWin = "RU",
		ABC = "EN",
		["U.S."] = "EN",
		US = "EN",
	},
}

os.execute(
	string.format(
		"sketchybar --add event %s '%s' 2>/dev/null",
		keyboard_settings.event_name,
		keyboard_settings.notification
	)
)

-- Network status icon. The keyboard layout label ( 􀙇 EN ) is switched off:
-- to bring it back, restore the label below and the update_layout calls.
local system = capsule.item("widgets.system", {
	icon = capsule.icon(icons.wifi.connected, colors.white, {
		font = {
			family = settings.icon_font.family,
			style = settings.icon_font.style,
			-- the VPN glyph (wifi + lock) draws small, so this one goes above icon_large
			size = settings.sizes.icon_large + 2,
		},
		padding_right = 0,
	}),
	padding_left = 0,
	label = { drawing = false },
	-- label = capsule.label(keyboard_settings.default_label),
})
local keyboard = system
local wifi = system

local layout_script = [[
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -w "KeyboardLayout Name" | cut -d "=" -f 2 | tr -d '"; '
]]

local function normalize_layout(raw)
	if not raw or raw == "" then
		return keyboard_settings.default_label
	end
	raw = raw:gsub("^%s*(.-)%s*$", "%1")

	local mapped_layout = keyboard_settings.layout_aliases[raw]
	if mapped_layout then
		return mapped_layout
	end

	return string.sub(raw:upper(), 1, 2)
end

local function update_layout()
	sbar.exec(layout_script, function(result)
		local label = normalize_layout(result)
		keyboard:set({ label = label })
	end)
end

-- keyboard:subscribe(keyboard_settings.event_name, update_layout)
-- update_layout()

local network_script = [[
VPN_STATUS="OFF"
if scutil --nwi | grep -m1 'VPN' >/dev/null; then
  VPN_STATUS="ON"
fi

IFACE="__NETWORK_INTERFACE__"
WIFI_POWER=$(networksetup -getairportpower "$IFACE" | awk '{print $4}')
if [ "$WIFI_POWER" = "Off" ]; then
  CONN="OFF"
else
  SUMMARY=$(ipconfig getsummary "$IFACE")
  SSID=$(printf "%s\n" "$SUMMARY" | awk -F ' SSID : ' '/ SSID : / {print $2}')
  if [ -n "$SSID" ]; then
    if printf "%s\n" "$SUMMARY" | grep -qE '^ *sname = [a-zA-Z0-9]'; then
      CONN="HOTSPOT"
    else
      CONN="WIFI"
    fi
  elif [ -n "$(ipconfig getifaddr "$IFACE")" ]; then
    CONN="ETHERNET"
  else
    CONN="NO_INTERNET"
  fi
fi
echo "${VPN_STATUS}|${CONN}"
]]
network_script = network_script:gsub("__NETWORK_INTERFACE__", settings.network.interface)

local function update_wifi()
	sbar.exec(network_script, function(result)
		result = result:gsub("^%s*(.-)%s*$", "%1")
		local vpn_status, connection_type = result:match("([^|]+)|([^|]+)")
		local icon
		local color

		if connection_type == "WIFI" then
			icon = (vpn_status == "ON") and icons.wifi.vpn or icons.wifi.connected
			color = colors.white
		elseif connection_type == "HOTSPOT" then
			icon = icons.wifi.hotspot
			color = colors.white
		elseif connection_type == "ETHERNET" then
			icon = icons.wifi.ethernet
			color = colors.white
		elseif connection_type == "NO_INTERNET" then
			icon = icons.wifi.disconnected
			color = colors.red
		else
			icon = icons.wifi.disconnected
			color = colors.red
		end

		wifi:set({
			icon = { string = icon, color = color },
		})
	end)
end

wifi:subscribe("wifi_change", update_wifi)
-- one item can hold one callback per event, so wake refreshes both halves
system:subscribe("system_woke", function()
	update_wifi()
	-- update_layout()
end)
sbar.exec("sleep 0.1", update_wifi)
