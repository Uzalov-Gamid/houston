local settings = require("settings")

-- astronaut: the bar is black (it hides the notch), so it uses the dark
-- colours from Obsidian's code blocks (palette/obsidian-colors.md, §2):
-- cream text, aqua glow for "active", ember-orange, gold, olive, tan.

local colors = {
	black = 0xff1c1513, -- night
	white = 0xffe3dccb, -- cream text on dark

	red = 0xfff07a52,
	green = 0xffb5b07a,
	blue = 0xff7daea3, -- glow: the window border colour
	yellow = 0xffe5c15a,
	orange = 0xffef8f4c,
	magenta = 0xffd0a07e, -- no purple in the palette: warm tan
	grey = 0xff8f857a,

	transparent = 0xffffffff,

	bar = {
		-- bg = 0xb3202020,
		bg = 0xff000000,
		border_color = 0x35e2e2e3,
		blur = 12,
	},
	-- one plate per block: the widgets inside have no background of their own.
	-- Opaque, so the square pieces at the screen edges merge with it seamlessly.
	container = {
		-- no plates: icons and text sit straight on the bar (was 0xff1a1a1a)
		bg = 0x00000000,
		border_color = 0x00000000,
		nesting_bg = 0x00000000,
		nesting_border_color = 0x00000000,
	},
	popup = {
		border_color = 0x27ffffff,
	},

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}

-- tokyonight:

-- local colors = {
-- 	black = 0xff1a1b26,
-- 	white = 0xffc0caf5,
--
-- 	red = 0xfff7768e,
-- 	green = 0xff9ece6a,
-- 	blue = 0xff7aa2f7,
-- 	yellow = 0xffe0af68,
-- 	orange = 0xffff9e64,
-- 	magenta = 0xffbb9af7,
-- 	grey = 0xff565f89,
--
-- 	transparent = 0xffffffff,
--
-- 	bar = {
-- 		bg = 0xff000000,
-- 		border_color = 0x35c0caf5,
-- 		blur = 12,
-- 	},
--
-- 	container = {
-- 		bg = 0x11c0caf5,
-- 		border_color = 0x27c0caf5,
-- 		nesting_bg = 0x05c0caf5,
-- 		nesting_border_color = 0x10c0caf5,
-- 	},
--
-- 	with_alpha = function(color, alpha)
-- 		if alpha > 1.0 or alpha < 0.0 then
-- 			return color
-- 		end
-- 		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
-- 	end,
-- }

return colors
