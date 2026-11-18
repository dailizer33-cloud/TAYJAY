end) -- isolated FPS Booster scope; avoids main-chunk local limit
end, function(_tjErr)
    local _tjTrace = tostring(_tjErr)
    pcall(function() _tjTrace = debug.traceback(_tjTrace, 2) end)
    return _tjTrace
end)

if not _tjRunOK then
    -- Startup may fail after one or more feature Owners have acquired resources.
    -- Stop registered Owners even when the main STOP ALL UI has not been created yet.
    pcall(function()
        local manager = _G.TAYJAY_RESOURCE_MANAGER
        if type(manager) == "table" and type(manager.StopAllOwners) == "function" then
            manager:StopAllOwners("STARTUP_ERROR")
        end
    end)
    pcall(function() warn("[TAYJAY STARTUP ERROR]\n" .. tostring(_tjRunError)) end)
    pcall(function()
        if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", _tjRunError) end
    end)
end