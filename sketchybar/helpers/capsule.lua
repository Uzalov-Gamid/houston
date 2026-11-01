local colors = require("colors")
local settings = require("settings")

-- Shared look of the status widgets. All of them sit on one plate (a bracket
-- added in items/widgets/init.lua) and follow the same rules: icons and text
-- in one colour, one icon size, one text size, the same step between widgets.
-- Colour is reserved for state (charging, low battery, no network).
--
--   ╭──────────────────────╮
--   │ 􀙇    ▐ 89 ▌    17:28 │
--   ╰──────────────────────╯
--
-- A widget made of one item gets the capsule as its own background
-- (capsule.item). A widget made of several items (network) draws the same
-- background around them with capsule.bracket.

local inner = 15 -- plate edge -> content
local gap = settings.paddings.container_paddings -- space between capsules
local icon_gap = 5 -- icon -> value inside a capsule
local step = 15 -- between widgets on a plate, same as inner on purpose

local capsule = {}

capsule.background = {
	color = colors.container.bg,
	height = settings.ui.container.height,
	border_color = colors.container.border_color,
	border_width = settings.ui.container.border_width,
	corner_radius = settings.ui.container.corner_radius,
	y_offset = settings.ui.container.y_offset,
}

function capsule.icon(glyph, color, extra)
	local icon = {
		string = glyph,
		color = color or colors.white,
		font = settings.icon_font,
		padding_left = inner,
		padding_right = icon_gap,
		align = "center",
	}
	for k, v in pairs(extra or {}) do
		icon[k] = v
	end
	return icon
end

function capsule.label(text, extra)
	local label = {
		string = text,
		font = settings.label_font,
		color = colors.white,
		padding_right = inner,
	}
	for k, v in pairs(extra or {}) do
		label[k] = v
	end
	return label
end

-- A single-item widget: icon + label inside its own capsule.
function capsule.item(name, props)
	props.position = props.position or "right"
	props.background = props.background or { drawing = false }
	props.padding_left = props.padding_left or step
	props.padding_right = props.padding_right or 0
	return sbar.add("item", name, props)
end

-- A capsule drawn around several items that are already added.
function capsule.bracket(name, members)
	return sbar.add("bracket", name, members, { background = capsule.background })
end

-- The small window that opens under a widget on click. Same palette as
-- the capsules, a bit more opaque so the text stays readable over windows.
capsule.popup_style = {
	align = "center",
	y_offset = 6,
	blur_radius = 30,
	background = {
		color = colors.with_alpha(colors.black, 0.94),
		border_color = colors.popup.border_color,
		border_width = 1,
		corner_radius = 12,
	},
}

-- Left click toggles the popup, leaving the bar/popup closes it.
-- on_open (optional) runs every time the popup opens.
-- on_right_click (optional): an item keeps one callback per event, so any
-- other click handling has to go through here.
function capsule.attach_popup(item, on_open, on_right_click)
	local is_open = false

	local function set_open(open)
		is_open = open
		item:set({ popup = { drawing = open } })
		if open and on_open then
			on_open()
		end
	end

	item:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			set_open(not is_open)
		elseif on_right_click then
			on_right_click(env)
		end
	end)
	item:subscribe("mouse.exited.global", function()
		set_open(false)
	end)

	return {
		is_open = function()
			return is_open
		end,
		-- for other items that should open the same popup
		toggle = function()
			set_open(not is_open)
		end,
	}
end

-- A "key   value" row inside a popup: key grey on the left, value white
-- on the right.
function capsule.popup_row(name, parent, key, extra)
	local props = {
		position = "popup." .. parent,
		icon = {
			string = key,
			font = settings.label_font,
			color = colors.grey,
			width = 110,
			padding_left = 12,
		},
		label = {
			string = "…",
			font = settings.label_font,
			color = colors.white,
			width = 140,
			align = "right",
			padding_right = 12,
		},
		background = { drawing = false },
	}
	for k, v in pairs(extra or {}) do
		props[k] = v
	end
	return sbar.add("item", name, props)
end

capsule.gap = gap
capsule.step = step
capsule.icon_gap = icon_gap
capsule.inner = inner

return capsule
