local status = require("./status.luau")
local ctl = noctalia.expandPath("~/.local/bin/stratactl")
local widget = status.widget({ctl, "status", "--json"}, "brain", 2000, function(data)
    barWidget.setText(data.text)
    barWidget.setColor(data.color)
    barWidget.setGlyphColor(data.color)
    barWidget.setTooltip(data.tooltip .. "\nRight-click: logs. Middle-click: widget settings.")
end, {ctl, "toggle"}, function()
    noctalia.runInTerminal("stratactl logs")
end)
function update() widget.update() end
function onClick() widget.click() end
function onRightClick() widget.rightClick() end
function onIpc(event)
    if event == "toggle" then widget.click() end
end
