local colors = require("colors")
local settings = require("settings")
local capsule = require("helpers.capsule")

-- Rightmost widget: just the time. Click for the date.

local weekdays = { "воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота" }
local months = {
	"января", "февраля", "марта", "апреля", "мая", "июня",
	"июля", "августа", "сентября", "октября", "ноября", "декабря",
}

-- A square piece over the plate's rounded end: the plate seems to run on past
-- the screen edge. Same trick on the left, see items/widgets/aerospace_d.lua.
sbar.add("item", "widgets.plate.tail", {
	position = "right",
	width = settings.paddings.edge_padding,
	icon = { drawing = false },
	label = { drawing = false },
	background = {
		color = colors.container.bg,
		height = settings.ui.container.height,
		corner_radius = 0,
	},
	padding_left = 0,
	padding_right = 0,
})

local digit_inset = 1 -- empty space inside the digits on both sides

local cal = capsule.item("widgets.calendar", {
	icon = { drawing = false },
	-- the tail adds up to capsule.inner to the screen edge
	label = capsule.label("??:??", { padding_right = capsule.inner - settings.paddings.edge_padding - digit_inset }),
	padding_left = capsule.step - digit_inset,
	update_freq = settings.widgets.calendar.update_freq,
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
	date = capsule.popup_row("widgets.calendar.popup.date", "widgets.calendar", "Дата"),
	day = capsule.popup_row("widgets.calendar.popup.day", "widgets.calendar", "День"),
}

local function update()
	local now = os.date("*t")
	cal:set({ label = { string = os.date("%H:%M") } })
	rows.date:set({ label = { string = string.format("%d %s", now.day, months[now.month]) } })
	rows.day:set({ label = { string = weekdays[now.wday] } })
end

cal:subscribe({ "forced", "routine", "system_woke" }, update)
capsule.attach_popup(cal, update)
