local colors = require("colors")
local settings = require("settings")

sbar.bar({
	height = settings.ui.bar_height,
	color = colors.bar.bg,
	border_color = colors.bar.border_color,
	border_width = settings.ui.background.border_width,
	blur_radius = colors.bar.blur,
	-- the plate spans its items' outer paddings, so the edge gap lives here
	padding_right = 0,
	padding_left = 0,
	margin = settings.ui.background.margin,
	y_offset = settings.ui.background.y_offset,
	corner_radius = settings.ui.background.corner_radius,
	notch_width = settings.ui.notch_width,
	-- one bar on every display (items can be tied to one display with
	-- associated_display, see items/widgets/aerospace_d.lua)
	display = "all",
	position = "top",
})
