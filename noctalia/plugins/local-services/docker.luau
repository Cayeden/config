local status = require("./status.luau")
local script = noctalia.expandPath(noctalia.getenv("XDG_CONFIG_HOME") or "~/.config") .. "/noctalia/scripts/docker-status.sh"
local widget = status.widget({script}, "brand-docker", 5000, function(data)
    barWidget.setText(string.match(data.text, "(%d+)$") or "–")
    barWidget.setColor(data.class == "up" and "primary" or "on_surface_variant")
    barWidget.setTooltip(data.tooltip .. "\nClick: container resource usage.")
end, {"kitty", "-e", "docker", "stats"})
function update() widget.update() end
function onClick() widget.click() end
