local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local capsule = require("helpers.capsule")

-- The outline battery glyph, same set and colour as the other icons, with the
-- charge written inside. The number is a zero-width item added before the
-- glyph (on the right side such items draw leftwards, over the next one).
-- Green while charging, red under 20%. Click for the time left.

local glyph_width = 36
local glyph_inset = 4 -- empty space inside the glyph on its left
local terminal_width = 4 -- the nub on the glyph's right, the number centres on the body

local value = sbar.add("item", "widgets.battery.value", {
	position = "right",
	width = 0,
	icon = { drawing = false },
	label = {
		string = "??",
		font = { family = "SF Pro", style = settings.font.style_map["Heavy"], size = settings.sizes.label_tiny },
		color = colors.white,
		width = glyph_width - terminal_width,
		align = "center",
		padding_left = 0,
		padding_right = terminal_width,
	},
	padding_left = 0,
	padding_right = 0,
})

local battery = capsule.item("widgets.battery", {
	icon = capsule.icon(icons.battery._0, colors.white, {
		font = {
			family = settings.icon_font.family,
			style = settings.font.style_map["Regular"],
			size = settings.sizes.icon_large + 4,
		},
		width = glyph_width,
		padding_left = 0,
		padding_right = 0,
	}),
	label = { drawing = false },
	padding_left = capsule.step - glyph_inset,
	update_freq = settings.widgets.battery.update_freq,
	popup = (function()
		local popup = {}
		for k, v in pairs(capsule.popup_style) do
			popup[k] = v
		end
		popup.align = "right" -- centred it would run off the screen edge
		return popup
	end)(),
})

local rows = {
	charge = capsule.popup_row("widgets.battery.popup.charge", "widgets.battery", "Заряд"),
	left = capsule.popup_row("widgets.battery.popup.left", "widgets.battery", "Осталось"),
}

local function update()
	sbar.exec("pmset -g batt", function(batt_info)
		local charge = tonumber(batt_info:match("(%d+)%%"))
		if not charge then
			return
		end

		local charging = batt_info:find("AC Power") ~= nil
		local color = colors.white
		if charging then
			color = colors.green
		elseif charge < 20 then
			color = colors.red
		end

		battery:set({ icon = { color = color } })
		value:set({
			label = {
				string = tostring(charge),
				color = color,
			},
		})

		local remaining = batt_info:match("(%d+:%d+) remaining")
		local left = "—"
		if charging then
			left = "заряжается"
		elseif remaining then
			left = remaining
		end
		rows.charge:set({ label = { string = charge .. "%" } })
		rows.left:set({ label = { string = left } })
	end)
end

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, update)
capsule.attach_popup(battery, update)
