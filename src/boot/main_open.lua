-- Catch synchronous startup failures and keep the error visible on-screen.
local _tjRunOK, _tjRunError = xpcall(function()
