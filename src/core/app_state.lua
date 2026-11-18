-- TAYJAY APP STATE V2: canonical, persistent state shared through TJ.Main.
local _tjStateEnv = _G
pcall(function()
    if type(getgenv) == "function" then
        local shared = getgenv()
        if type(shared) == "table" then _tjStateEnv = shared end
    end
end)
local TJ = _tjStateEnv.TJ
if type(TJ) ~= "table" then TJ = {}; _tjStateEnv.TJ = TJ end
local Main = TJ.Main
if type(Main) ~= "table" then Main = {}; TJ.Main = Main end
local config = Main.config
if type(config) ~= "table" then config = {}; Main.config = config end
if config.WalkSpeed == nil then config.WalkSpeed = 16 end
local states = Main.states
if type(states) ~= "table" then states = {}; Main.states = states end
local defaults = {
    Speed = false, Fly = false, InfJump = false, Noclip = false,
    Xray = false, ESP = true, DeathNote = false, KillAura = false,
    NormalKillAura = false, MonsterWarp = false, ServerSelector = false,
    MM2RoleESP = false, AutoWarp = false, DNWarp = false
}
for key, value in pairs(defaults) do
    if states[key] == nil then states[key] = value end
end
local State = Main.State
if type(State) ~= "table" then State = {}; Main.State = State end
if State.originalWalkSpeed == nil then State.originalWalkSpeed = Main.originalWalkSpeed end
if State.isBusy == nil then State.isBusy = Main.isBusy == true end
-- Legacy feature modules keep the same table references. Scalar runtime values
-- are stored in State and mirrored to legacy fields only when changed.
Main.config, Main.states = config, states
Main.originalWalkSpeed, Main.isBusy = State.originalWalkSpeed, State.isBusy
TJ.Main = Main
