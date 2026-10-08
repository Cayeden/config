barWidget.setGlyph("memory")
noctalia.setUpdateInterval(2000)

local function reading(value, suffix)
    if value == nil then return "Unavailable" end
    return string.format("%.0f%s", value, suffix)
end

function update()
    local stats = noctalia.systemStats()
    if stats == nil then
        barWidget.setText("N/A")
        barWidget.setTooltip("System monitoring unavailable")
        return
    end
    local cpu, gpu = stats.cpu, stats.gpu
    local used, total = gpu.vramUsedBytes, gpu.vramTotalBytes
    local vram = "Unavailable"
    if used ~= nil and total ~= nil and total > 0 then
        vram = string.format("%.1f / %.1f GiB", used / 1073741824, total / 1073741824)
        barWidget.setText(string.format("%.0f%%", 100 * used / total))
    else
        barWidget.setText("N/A")
    end
    barWidget.setTooltip({
        { "CPU usage", reading(cpu.usagePercent, "%") },
        { "CPU temperature", reading(cpu.tempC, "°C") },
        { "GPU usage", reading(gpu.usagePercent, "%") },
        { "GPU temperature", reading(gpu.tempC, "°C") },
        { "VRAM", vram },
    })
end

function onClick()
    noctalia.runAsync({"noctalia", "msg", "panel-toggle", "control-center", "system"}, function() end)
end
