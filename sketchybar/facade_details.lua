local M = {}

function M.battery(sbar, done)
  sbar.exec("/usr/bin/pmset -g batt", function(output)
    local charge = output:match("(%d+)%%")
    if not charge then done({ { text = "Battery unavailable" } }); return end
    local on_ac = output:find("AC Power", 1, true) ~= nil
    local hours, minutes = output:match("(%d+):(%d+)%s+remaining")
    local state = output:match("%%%s*;%s*([^;\r\n]+)")
    local rows = {
      { text = "Battery", value = charge .. "%" },
      { text = "Power source", value = on_ac and "AC power" or "Battery" },
    }
    if not on_ac or state == "charging" then
      local estimate = "Unavailable"
      if hours and minutes then
        hours, minutes = tonumber(hours), tonumber(minutes)
        estimate = hours > 0 and ("%dh %02dm"):format(hours, minutes) or ("%dm"):format(minutes)
      end
      rows[3] = { text = on_ac and "Time to full" or "Time left", value = estimate, muted = not hours }
    elseif state == "charged" then
      rows[3] = { text = "Status", value = "Charged" }
    else
      rows[3] = { text = "Status", value = "Not charging" }
    end
    done(rows)
  end)
end

return M
