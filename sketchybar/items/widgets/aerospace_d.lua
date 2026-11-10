local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local capsule = require("helpers.capsule")

-- Workspace + apps widget, one copy per display.
--
--   [ 1 ][ ]  [ ]            <- DELL (second monitor): its workspace 1..5
--   [ ai ][ ]  [ ]           <- MacBook (main): its workspace
--
-- Each copy is tied to one display (associated_display) and shows the
-- workspace that is visible on the AeroSpace monitor of that display: the
-- main display <-> the main monitor, any other display <-> the secondary one.
-- When displays are plugged in or out the bar reloads and this runs again.

local aerospace_bin = settings.binaries.aerospace
local app_icon_size_medium = "sketchybar-app-font:Regular:" .. settings.sizes.icon_medium
local app_icon_size_small = "sketchybar-app-font:Regular:" .. settings.sizes.icon_small

local MAX_INACTIVE_SLOTS = 10

local function trim(value)
	return value and value:gsub("^%s*(.-)%s*$", "%1") or value
end

local function aerospace_exec(arguments, callback)
	sbar.exec(aerospace_bin .. " " .. arguments, callback)
end

local y_cfg = {
	bracket_padding = 1,
	after_space_gap = settings.paddings.paddings - 3,
	space = {
		padding_left = 6, -- edge piece + this = capsule.inner; gap after space name to edge of it's container
		padding_right = 0,
		gap = settings.paddings.group_padding - 3, -- gap between space's containers
	},
	apps = {
		gap = settings.paddings.paddings,
	},
}

sbar.add("event", "aerospace_refresh")
sbar.add("event", "aerospace_mode_change")

-- square piece from the screen edge to the plate, so it seems to run on past
-- the edge. The workspace item covers the plate's rounded corners.
sbar.add("item", "another_edge_padding", {
	position = "left",
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

--------------------------------------------------
-- DISPLAYS
--------------------------------------------------

-- SketchyBar display ids; the main display is the one at the origin (0, 0).
local function detect_displays()
	local displays = {}
	local pipe = io.popen(
		[[sketchybar --query displays | /opt/homebrew/bin/jq -r '.[] | "\(.["arrangement-id"]) \(.frame.x) \(.frame.y)"' 2>/dev/null]]
	)
	if pipe then
		for line in pipe:lines() do
			local id, x, y = line:match("^(%d+) (%-?[%d%.]+) (%-?[%d%.]+)$")
			if id then
				table.insert(displays, { id = tonumber(id), main = tonumber(x) == 0 and tonumber(y) == 0 })
			end
		end
		pipe:close()
	end
	table.sort(displays, function(a, b)
		return a.main and not b.main
	end)
	return displays
end

--------------------------------------------------
-- ONE COPY OF THE WIDGET
--------------------------------------------------

-- suffix: "" for the main display, ".ext" for the other one (item names)
-- display: SketchyBar display id, or nil when it could not be detected
-- is_main: true -> follows the main AeroSpace monitor, false -> the secondary
local function build(suffix, display, is_main)
	local function add_item(name, props)
		if display then
			props.associated_display = display
		end
		return sbar.add("item", name, props)
	end

	local aerospace_workspace = add_item("aerospace.ws" .. suffix, {
		position = "left",
		icon = {
			-- workspace name one step heavier than the other labels
			font = { family = settings.font.text, style = settings.font.style_map["Heavy"], size = settings.sizes.label_medium },
			color = colors.white,
			align = "center",
			padding_left = y_cfg.space.padding_left,
			padding_right = y_cfg.space.padding_right,
		},
		background = {
			height = settings.ui.container.height,
			color = colors.container.bg,
			corner_radius = 0,
			border_color = colors.container.nesting_border_color,
			border_width = 0,
		},
		label = { drawing = false },
		padding_left = 0,
		padding_right = 0,
	})

	local aerospace_active = add_item("aerospace.active" .. suffix, {
		position = "left",
		icon = {
			font = app_icon_size_medium,
			color = colors.white,
			align = "center",
		},
		label = { drawing = false },
		-- the name and the glyph have 2pt and 1pt of empty space around them
		padding_left = capsule.step - 2,
		padding_right = capsule.step - 1,
	})

	local inactive_slots = {}
	local bracket_items = { "aerospace.ws" .. suffix, "aerospace.active" .. suffix }

	for i = 1, MAX_INACTIVE_SLOTS do
		local name = "aerospace.inactive" .. suffix .. "." .. i
		inactive_slots[i] = add_item(name, {
			position = "left",
			icon = { drawing = false },
			label = {
				font = app_icon_size_small,
				color = colors.grey,
				align = "center",
			},
			drawing = false,
			padding_right = capsule.step,
		})
		table.insert(bracket_items, name)
	end

	local bracket_props = {
		background = {
			color = colors.container.bg,
			height = settings.ui.container.height,
			border_color = colors.container.border_color,
			border_width = settings.ui.container.border_width,
			corner_radius = settings.ui.container.corner_radius,
			y_offset = settings.ui.container.y_offset,
		},
	}
	if display then
		bracket_props.associated_display = display
	end
	sbar.add("bracket", "aerospace.bracket" .. suffix, bracket_items, bracket_props)

	local function render_workspace(workspace_id)
		if not workspace_id or workspace_id == "" then
			return
		end

		aerospace_exec(
			string.format("list-windows --workspace %q --format '%%{app-name}'", workspace_id),
			function(workspace_apps_output)
				aerospace_exec("list-windows --focused --format '%{app-name}|%{workspace}'", function(focused_output)
					local focused_app, focused_workspace = string.match(focused_output, "^([^|]+)|([^|\r\n]+)")
					focused_app = trim(focused_app)
					focused_workspace = trim(focused_workspace)

					local active_icon = ""
					local inactive_glyphs = {}
					local seen_apps = {}

					for app_name in string.gmatch(workspace_apps_output, "[^\r\n]+") do
						local normalized_app_name = trim(app_name)
						if normalized_app_name ~= "" and not seen_apps[normalized_app_name] then
							seen_apps[normalized_app_name] = true
							local glyph = app_icons[normalized_app_name] or app_icons.Default or "—"

							if normalized_app_name == focused_app and focused_workspace == workspace_id then
								active_icon = glyph
							else
								table.insert(inactive_glyphs, glyph)
							end
						end
					end

					if active_icon == "" and #inactive_glyphs == 0 then
						active_icon = "—"
					end

					for i, slot in ipairs(inactive_slots) do
						local glyph = inactive_glyphs[i]
						if glyph then
							slot:set({
								label = { string = glyph },
								drawing = true,
							})
						else
							slot:set({ drawing = false })
						end
					end

					aerospace_exec("list-modes --current", function(mode_output)
						local workspace_label = workspace_id

						if trim(mode_output) == "service" then
							workspace_label = workspace_id .. "\n[S]"
						end

						aerospace_workspace:set({
							icon = { string = workspace_label },
						})

						aerospace_active:set({
							icon = {
								string = active_icon,
								drawing = (active_icon ~= ""),
							},
						})
					end)
				end)
			end
		)
	end

	-- the workspace currently shown on this copy's monitor
	local function refresh()
		aerospace_exec(
			"list-workspaces --monitor all --visible --format '%{monitor-is-main}|%{workspace}'",
			function(out)
				for line in string.gmatch(out or "", "[^\r\n]+") do
					local main_flag, workspace = line:match("^(%a+)|(.+)$")
					if main_flag and ((main_flag == "true") == is_main) then
						render_workspace(trim(workspace))
						return
					end
				end
			end
		)
	end

	aerospace_workspace:subscribe({ "aerospace_refresh", "front_app_switched", "aerospace_mode_change" }, refresh)
	refresh()
end

local displays = detect_displays()

if #displays == 0 then
	-- could not read the displays: one copy, drawn wherever the bar is
	build("", nil, true)
else
	for _, display in ipairs(displays) do
		build(display.main and "" or ".ext", display.id, display.main)
	end
end

-- Plugging a monitor in or out changes the display ids: reload the bar so the
-- copies above are tied to the right displays again. (Ignored in the first
-- seconds after loading, in case the event fires on startup.)
local loaded_at = os.time()
sbar.add("item", "aerospace.display_watch", { drawing = false, updates = true }):subscribe("display_change", function()
	if os.time() - loaded_at > 5 then
		sbar.exec("sleep 1; /opt/homebrew/bin/sketchybar --reload")
	end
end)
