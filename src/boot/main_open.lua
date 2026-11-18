-- Re-execution safety: stop the previous TAYJAY session before replacing it.
-- STOP ALL sets this guard permanently for that session; reset it for the new run.
local _tjPreviousStopAll = _G.TAYJAY_STOP_ALL
if type(_tjPreviousStopAll) == "function" then
    pcall(_tjPreviousStopAll)
end
_G.TAYJAY_STOPPED = false

-- Catch synchronous startup failures and keep the error visible on-screen.
local _tjRunOK, _tjRunError = xpcall(function()
