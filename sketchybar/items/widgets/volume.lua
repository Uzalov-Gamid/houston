local icons = require("icons")
local colors = require("colors")
local capsule = require("helpers.capsule")

-- Icon only: the speaker glyph shows the level (fewer waves when quieter,
-- crossed out at 0). When the volume changes the number appears next to it
-- for a couple of seconds.

local show_seconds = 2
local glyph_slot = 24 -- the glyph's width changes with the level, the slot doesn't

local volume = capsule.item("widgets.volume", {
	icon = capsule.icon(icons.volume._100, colors.white, {
		width = glyph_slot,
		align = "center",
		padding_left = 0,
		padding_right = 0,
	}),
	label = capsule.label("", { drawing = false, padding_left = capsule.icon_gap, padding_right = 0 }),
})

local function volume_glyph(level)
	if level > 60 then
		return icons.volume._100
	elseif level > 30 then
		return icons.volume._66
	elseif level > 10 then
		return icons.volume._33
	elseif level > 0 then
		return icons.volume._10
	end
	return icons.volume._0
end

local shown_at = 0
local first_event = true

volume:subscribe("volume_change", function(env)
	local level = tonumber(env.INFO) or 0

	volume:set({ icon = { string = volume_glyph(level), color = level > 0 and colors.white or colors.grey } })

	-- the event also fires once at startup, no need to flash the number then
	if first_event then
		first_event = false
		return
	end

	volume:set({ label = { string = level .. "%", drawing = true } })
	shown_at = shown_at + 1
	local this_change = shown_at
	sbar.delay(show_seconds, function()
		if this_change == shown_at then
			volume:set({ label = { drawing = false } })
		end
	end)
end)
