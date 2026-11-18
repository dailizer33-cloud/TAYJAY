local _tjStateEnv = _G
pcall(function()
    if type(getgenv) == "function" then
        local shared = getgenv()
        if type(shared) == "table" then _tjStateEnv = shared end
    end
end)
local TJ = _tjStateEnv.TJ
if type(TJ) ~= "table" then TJ = {}; _tjStateEnv.TJ = TJ end
TJ.Main = TJ.Main or {}
local config = { WalkSpeed = 16 }
local originalWalkSpeed = nil
local isBusy = false 
local states = {
   Speed = false, Fly = false, InfJump = false, Noclip = false, 
   Xray = false, ESP = true, DeathNote = false, KillAura = false, NormalKillAura = false, MonsterWarp = false,
   ServerSelector = false, MM2RoleESP = false, AutoWarp = false, DNWarp = false
}



-- Canonical state registry. Existing locals remain aliases for feature compatibility.
TJ.Main.config = config
TJ.Main.originalWalkSpeed = originalWalkSpeed
TJ.Main.isBusy = isBusy
TJ.Main.states = states
