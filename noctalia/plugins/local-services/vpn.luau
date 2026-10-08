local status = require("./status.luau")
local scripts = noctalia.expandPath(noctalia.getenv("XDG_CONFIG_HOME") or "~/.config") .. "/noctalia/scripts/"
local widget = status.widget({scripts .. "riseup-status.py"}, "shield-lock", 5000, function(data)
    barWidget.setText("")
    local color = data.class == "connected" and "primary" or data.class == "connecting" and "tertiary" or "on_surface_variant"
    barWidget.setColor(color)
    barWidget.setGlyphColor(color)
    barWidget.setTooltip(data.tooltip)
end, {scripts .. "riseup-open.sh"})
function update() widget.update() end
function onClick() widget.click() end
