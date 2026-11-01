local separator = require("items.widgets.separator")
local capsule = require("helpers.capsule")

require("items.widgets.calendar")

-- separator("widgets.separator.1")

require("items.widgets.battery")
-- require("items.widgets.volume")
-- require("items.widgets.cpu")
-- require("items.widgets.ram")

-- separator("widgets.separator.2")

-- require("items.widgets.keyboard")
-- right side is built right-to-left: network ends up left of RAM,
-- system (wifi + layout) left of network
-- require("items.widgets.network")
require("items.widgets.system")

-- one plate behind all the widgets on the right
capsule.bracket("widgets.plate", {
	"widgets.plate.tail",
	"widgets.calendar",
	"widgets.battery.value",
	"widgets.battery",
	"widgets.system",
})

require("items.widgets.aerospace_d")
-- after the spaces block, so the player sits right next to it
require("items.widgets.music")
-- require("items.widgets.yabai")
