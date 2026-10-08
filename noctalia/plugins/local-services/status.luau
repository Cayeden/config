local M = {}

function M.widget(argv, glyph, interval, render, click, rightClick)
    local polling = false
    local acting = false
    barWidget.setGlyph(glyph)
    noctalia.setUpdateInterval(interval)

    local function poll()
        if polling then return end
        polling = true
        if not noctalia.runAsync(argv, function(result)
            polling = false
            local data = noctalia.json.decode(result.stdout)
            if result.exitCode == 0 and data then
                render(data)
            else
                barWidget.setColor("error")
                barWidget.setTooltip(result.stderr ~= "" and result.stderr or "Status unavailable")
            end
        end) then
            polling = false
        end
    end

    local function act(command)
        if acting then return end
        acting = true
        if not noctalia.runAsync(command, function(result)
            acting = false
            if result.exitCode ~= 0 then
                noctalia.notifyError("Local service", result.stderr)
            end
            poll()
        end) then
            acting = false
            noctalia.notifyError("Local service", "Could not start the command")
        end
    end

    return {
        update = poll,
        click = function() act(click) end,
        rightClick = rightClick,
    }
end

return M
