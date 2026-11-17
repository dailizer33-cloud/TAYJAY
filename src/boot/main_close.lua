end) -- isolated FPS Booster scope; avoids main-chunk local limit
end, function(_tjErr)
    local _tjTrace = tostring(_tjErr)
    pcall(function() _tjTrace = debug.traceback(_tjTrace, 2) end)
    return _tjTrace
end)

if not _tjRunOK then
    pcall(function() warn("[TAYJAY STARTUP ERROR]\n" .. tostring(_tjRunError)) end)
    pcall(function()
        if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", _tjRunError) end
    end)
end