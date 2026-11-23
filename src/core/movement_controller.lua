-- TAYJAY MOVEMENT CONTROLLER V1
-- Grants one movement writer at a time and tracks the owner of shared locks/platforms.
local _tjMovementEnv = _G
pcall(function()
    if type(getgenv) == "function" then
        local shared = getgenv()
        if type(shared) == "table" then _tjMovementEnv = shared end
    end
end)
local _tjMovementTJ = _tjMovementEnv.TJ or TJ
if type(_tjMovementTJ) ~= "table" then _tjMovementTJ = {}; _tjMovementEnv.TJ = _tjMovementTJ end
local _tjMovementMain = _tjMovementTJ.Main
if type(_tjMovementMain) ~= "table" then _tjMovementMain = {}; _tjMovementTJ.Main = _tjMovementMain end
local _tjMovementController = _tjMovementMain.MovementController
if type(_tjMovementController) ~= "table" then
    _tjMovementController = {}
    _tjMovementMain.MovementController = _tjMovementController
end
_tjMovementController.Generation = tonumber(_tjMovementController.Generation) or 0
_tjMovementController.Transition = false
_tjMovementController.PlatformOwner = _tjMovementController.PlatformOwner
_tjMovementController.Platform = _tjMovementController.Platform

local function _tjInferMovementOwner()
    local monsterOn = states and states.MonsterWarp == true
    local playerOn = states and (states.KillAura == true or states.DNWarp == true or states.AutoWarp == true)
    if monsterOn and playerOn then return "CONFLICT" end
    if monsterOn then return "MONSTER" end
    if playerOn then return "PLAYER_WARP" end
    return nil
end

function _tjMovementController:Acquire(nextOwner, stopPrevious)
    if nextOwner ~= "PLAYER_WARP" and nextOwner ~= "MONSTER" then
        return false, "invalid movement owner"
    end
    if self.Transition then return false, "movement transition in progress" end

    local observed = _tjInferMovementOwner()
    local current = observed or self.Owner
    if current == nextOwner and current ~= "CONFLICT" then
        self.Owner = nextOwner
        return true
    end

    self.Transition = true
    if current and current ~= nextOwner then
        if type(stopPrevious) ~= "function" then
            self.Transition = false
            return false, "missing previous-owner cleanup"
        end
        local ok, stopped = pcall(stopPrevious, current)
        if not ok or stopped ~= true then
            self.Transition = false
            return false, "previous movement owner did not confirm cleanup"
        end
    end

    if self.PlatformOwner and self.PlatformOwner ~= nextOwner then
        local oldPlatform = self.Platform
        if oldPlatform and oldPlatform.Parent then
            self.Transition = false
            return false, "previous movement platform is still active"
        end
        self.PlatformOwner, self.Platform = nil, nil
        _G.TAYJAY_PLATFORM_OWNER = nil
    end

    if self.PositionLockOwner and self.PositionLockOwner ~= nextOwner then
        self:ClearPositionLock(self.PositionLockOwner)
    end

    self.Owner = nextOwner
    self.Generation = self.Generation + 1
    self.ActiveSince = os.clock()
    self.Transition = false
    return true
end

function _tjMovementController:Release(owner)
    if self.Transition then return false end
    if owner and self.Owner ~= owner then return false end
    self.Owner = nil
    self.ActiveSince = nil
    return true
end

function _tjMovementController:IsOwner(owner)
    return not self.Transition and self.Owner == owner
end

function _tjMovementController:SetPositionLock(owner, untilTime)
    if self.Transition or self.Owner ~= owner then return false end
    self.PositionLockOwner = owner
    _G.TAYJAY_POS_LOCK_OWNER = owner
    _G.TAYJAY_POS_LOCK_UNTIL = tonumber(untilTime) or (os.clock() + 0.3)
    return true
end

function _tjMovementController:ClearPositionLock(owner)
    if not owner then return false end
    if self.PositionLockOwner ~= owner and _G.TAYJAY_POS_LOCK_OWNER ~= owner then
        return false
    end
    self.PositionLockOwner = nil
    if _G.TAYJAY_POS_LOCK_OWNER == owner then
        _G.TAYJAY_POS_LOCK_OWNER = nil
        _G.TAYJAY_POS_LOCK_UNTIL = nil
    end
    return true
end

function _tjMovementController:ClaimPlatform(owner, platform)
    if self.Transition or self.Owner ~= owner or not platform then return false end
    if self.PlatformOwner and self.PlatformOwner ~= owner then
        local previous = self.Platform
        if previous and previous.Parent then return false end
    end
    self.PlatformOwner = owner
    self.Platform = platform
    _G.TAYJAY_PLATFORM_OWNER = owner
    return true
end

function _tjMovementController:ReleasePlatform(owner, platform)
    if self.PlatformOwner ~= owner then return false end
    if platform and self.Platform and self.Platform ~= platform then return false end
    self.PlatformOwner, self.Platform = nil, nil
    if _G.TAYJAY_PLATFORM_OWNER == owner then _G.TAYJAY_PLATFORM_OWNER = nil end
    return true
end

function _tjMovementController:ForceClear(reason)
    self.Owner = nil
    self.Transition = false
    self.ActiveSince = nil
    self.PositionLockOwner = nil
    self.PlatformOwner = nil
    self.Platform = nil
    _G.TAYJAY_POS_LOCK_OWNER = nil
    _G.TAYJAY_POS_LOCK_UNTIL = nil
    _G.TAYJAY_PLATFORM_OWNER = nil
    self.LastStopReason = tostring(reason or "RESET")
    return true
end
