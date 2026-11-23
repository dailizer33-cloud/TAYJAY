-- =========================================================
-- TAYJAY TARGET SERVICE V2
-- Single source of truth for combat / warp targeting.
-- Sources: "none" | "walk" | "deathnote" | "warp"
-- Loaded in the shared main-script scope after app_state.lua and cleanup.lua.
-- =========================================================
local _tjTargetEnv = _G
pcall(function()
    if type(getgenv) == "function" then
        local shared = getgenv()
        if type(shared) == "table" then _tjTargetEnv = shared end
    end
end)

local TJ = _tjTargetEnv.TJ
if type(TJ) ~= "table" then
    TJ = {}
    _tjTargetEnv.TJ = TJ
end

local Main = TJ.Main
if type(Main) ~= "table" then
    Main = {}
    TJ.Main = Main
end

local statesRef = Main.states
if type(statesRef) ~= "table" then
    statesRef = {}
    Main.states = statesRef
end

local TargetService = TJ.TargetService
if type(TargetService) ~= "table" then
    TargetService = {}
    TJ.TargetService = TargetService
end

TargetService.Player = TargetService.Player
TargetService.Source = TargetService.Source or "none"
TargetService.Locked = TargetService.Locked == true
TargetService.Released = TargetService.Released == true
TargetService.Range = tonumber(TargetService.Range) or 25
TargetService._attackFn = TargetService._attackFn
TargetService._listeners = type(TargetService._listeners) == "table" and TargetService._listeners or {}
TargetService._combatOwner = TargetService._combatOwner

do -- [TAYJAY LOCAL-LIMIT FIX 1/8]
-- Legacy mirror table (death_note / warp can read these during migration).
local Legacy = TargetService.Legacy
if type(Legacy) ~= "table" then
    Legacy = {
        selected = nil,
        locked = nil,
        isLocked = false,
        released = false,
    }
    TargetService.Legacy = Legacy
end
_tjTargetEnv.TAYJAY_TARGET_LEGACY = Legacy

local function notify(eventName, payload)
    for _, fn in ipairs(TargetService._listeners) do
        pcall(fn, eventName, payload)
    end
end

local function isPlayerValid(player)
    return player ~= nil and player.Parent == Players
end

local function mirrorLegacy()
    Legacy.selected = TargetService.Player
    Legacy.locked = TargetService.Locked and TargetService.Player or nil
    Legacy.isLocked = TargetService.Locked == true
    Legacy.released = TargetService.Released == true
end

function TargetService:Get()
    return {
        player = self.Player,
        source = self.Source,
        locked = self.Locked == true,
        released = self.Released == true,
        range = self.Range,
    }
end

function TargetService:GetPlayer()
    if isPlayerValid(self.Player) then
        return self.Player
    end
    return nil
end

function TargetService:IsLocked()
    return self.Locked == true and isPlayerValid(self.Player)
end

function TargetService:OnChange(fn)
    if type(fn) ~= "function" then
        return function() end
    end
    self._listeners[#self._listeners + 1] = fn
    local connected = true
    return function()
        if not connected then return end
        connected = false
        for i, listener in ipairs(self._listeners) do
            if listener == fn then
                table.remove(self._listeners, i)
                break
            end
        end
    end
end

function TargetService:BindAttack(fn)
    if type(fn) == "function" then
        self._attackFn = fn
    else
        self._attackFn = nil
    end
end

function TargetService:SetRange(range)
    local value = tonumber(range)
    if value and value == value and value > 0 then
        self.Range = value
    end
    return self.Range
end

function TargetService:Lock(player, source)
    if not isPlayerValid(player) then
        return false, "invalid_player"
    end
    if player == LocalPlayer then
        return false, "local_player"
    end
    if _G.TAYJAY_BL and _G.TAYJAY_BL.has and _G.TAYJAY_BL.has(player.Name) then
        return false, "blacklist"
    end

    self.Player = player
    self.Source = source or "deathnote"
    self.Locked = true
    self.Released = false
    mirrorLegacy()

    if self.Source == "deathnote" then
        statesRef.DNWarp = true
    end

    notify("lock", self:Get())
    self:EnsureCombatOwner()
    return true
end

function TargetService:Unlock(reason)
    local previous = self:Get()
    self.Player = nil
    self.Source = "none"
    self.Locked = false
    self.Released = true
    mirrorLegacy()

    statesRef.DNWarp = false
    if statesRef.NormalKillAura == true then
        self:EnsureCombatOwner()
    else
        self:StopCombatOwner(reason or "unlock")
    end
    notify("unlock", previous)
    return true
end

function TargetService:SetTransient(player, source)
    if player ~= nil and not isPlayerValid(player) then
        return false, "invalid_player"
    end
    self.Player = player
    self.Source = source or "warp"
    self.Locked = false
    self.Released = false
    mirrorLegacy()
    notify("transient", self:Get())
    return true
end

function TargetService:Clear(reason)
    return self:Unlock(reason or "clear")
end

local function distanceTo(player)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not root or not hum or hum.Health <= 0 then
        return nil
    end
    return (myRoot.Position - root.Position).Magnitude, char, hum
end


-- =========================================================
-- WALK HOLD BITE: resolve the game's visible BITE button and
-- maintain a press while the selected target remains valid.
-- =========================================================
local HoldSystem = {
    isHolding = false,
    currentTarget = nil,
    biteButton = nil,
    lastDownAt = 0,
    reFireInterval = 0.05,
    lastFindAt = 0,
}

local function findHoldBiteButton()
    local now = os.clock()
    if HoldSystem.biteButton and HoldSystem.biteButton.Parent then
        return HoldSystem.biteButton
    end
    if now - HoldSystem.lastFindAt < 0.35 then return nil end
    HoldSystem.lastFindAt = now

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and #obj.Text > 0 and #obj.Text <= 24 then
            local normalized = string.lower(tostring(obj.Text)):gsub("<[^>]*>", ""):gsub("[^%w]", "")
            if normalized == "bite" then
                local gui = obj:FindFirstAncestorWhichIsA("ScreenGui")
                local visible = gui ~= nil and gui.Enabled
                local parent = obj
                while visible and parent and parent ~= gui do
                    if parent:IsA("GuiObject") and not parent.Visible then visible = false end
                    parent = parent.Parent
                end
                if visible then
                    local button = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
                    if button then
                        HoldSystem.biteButton = button
                        return button
                    end
                end
            end
        end
    end
    return nil
end

local function fireHoldDown(button)
    if not button or not button.Parent then return false end
    local fired = false
    pcall(function()
        if type(firesignal) == "function" then
            firesignal(button.MouseButton1Down)
            fired = true
        end
    end)
    pcall(function()
        if type(getconnections) == "function" then
            local connections = getconnections(button.MouseButton1Down)
            for _, connection in ipairs(connections or {}) do
                pcall(function() connection:Fire(); fired = true end)
            end
        end
    end)
    if not fired then
        pcall(function() button:Activate(); fired = true end)
    end
    return fired
end

local function fireHoldUp(button)
    if not button or not button.Parent then return end
    pcall(function()
        if type(firesignal) == "function" then firesignal(button.MouseButton1Up) end
    end)
    pcall(function()
        if type(getconnections) == "function" then
            for _, connection in ipairs(getconnections(button.MouseButton1Up) or {}) do
                pcall(function() connection:Fire() end)
            end
        end
    end)
end

local function stopHold()
    local wasHolding = HoldSystem.isHolding
    local button = wasHolding and HoldSystem.biteButton or nil
    HoldSystem.isHolding = false
    HoldSystem.currentTarget = nil
    HoldSystem.lastDownAt = 0
    if wasHolding then fireHoldUp(button) end
end

local function startHold(targetChar)
    if not targetChar or not targetChar.Parent then
        stopHold()
        return false
    end
    if HoldSystem.isHolding and HoldSystem.currentTarget == targetChar then
        return true
    end

    if HoldSystem.isHolding then stopHold() end
    local button = findHoldBiteButton()
    if not button or not button.Parent then
        stopHold()
        return false
    end

    HoldSystem.isHolding = true
    HoldSystem.currentTarget = targetChar
    HoldSystem.biteButton = button
    HoldSystem.lastDownAt = os.clock()
    fireHoldDown(button)

    task.spawn(function()
        while HoldSystem.isHolding and HoldSystem.currentTarget == targetChar do
            if not targetChar.Parent then
                stopHold()
                break
            end
            local currentButton = HoldSystem.biteButton
            if not currentButton or not currentButton.Parent then
                HoldSystem.biteButton = nil
                stopHold()
                break
            end
            local now = os.clock()
            if now - HoldSystem.lastDownAt >= HoldSystem.reFireInterval then
                fireHoldDown(currentButton)
                HoldSystem.lastDownAt = now
            end
            task.wait(0.03)
        end
    end)
    return true
end



-- Resolve only explicit attacker attribution exposed by the game.
-- Roblox has no universal damage-attacker API; unsupported games fall back to WALK's nearest target.
local function resolveAttackerValue(value)
    if not value then return nil end
    if value:IsA("Player") and isPlayerValid(value) and value ~= LocalPlayer then
        return value
    end
    if value:IsA("Model") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character == value then return player end
        end
    end
    return nil
end

function TargetService:FindRetaliationTarget()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    for _, tagName in ipairs({"creator", "Creator", "attacker", "Attacker", "LastAttacker"}) do
        local tag = humanoid:FindFirstChild(tagName) or character:FindFirstChild(tagName)
        if tag and tag:IsA("ObjectValue") then
            local player = resolveAttackerValue(tag.Value)
            if player then
                local dist = distanceTo(player)
                if dist then
                    self.RetaliationTarget = player
                    return player
                end
            end
        end
    end

    for _, attributeName in ipairs({"LastAttackerUserId", "AttackerUserId", "creatorUserId"}) do
        local userId = tonumber(humanoid:GetAttribute(attributeName) or character:GetAttribute(attributeName))
        if userId then
            local player = Players:GetPlayerByUserId(userId)
            if player and player ~= LocalPlayer and distanceTo(player) then
                self.RetaliationTarget = player
                return player
            end
        end
    end

    self.RetaliationTarget = nil
    return nil
end
function TargetService:FindNearestFromPosition(origin, maxDist, skipBlacklist)
    if typeof(origin) ~= "Vector3" then return nil end
    local bestPlayer, bestChar, bestDist = nil, nil, tonumber(maxDist) or math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local skipped = skipBlacklist == true and _G.TAYJAY_BL
                and type(_G.TAYJAY_BL.has) == "function" and _G.TAYJAY_BL.has(player.Name)
            if not skipped then
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local dist = (root.Position - origin).Magnitude
                    if dist <= bestDist then bestPlayer, bestChar, bestDist = player, char, dist end
                end
            end
        end
    end
    return bestPlayer, bestChar, bestDist
end

function TargetService:FindNearestPoolFromPosition(origin, count, skipBlacklist)
    if typeof(origin) ~= "Vector3" then return {} end
    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local skipped = skipBlacklist == true and _G.TAYJAY_BL
                and type(_G.TAYJAY_BL.has) == "function" and _G.TAYJAY_BL.has(player.Name)
            if not skipped then
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    table.insert(candidates, {
                        player = player,
                        distance = (root.Position - origin).Magnitude,
                    })
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local result = {}
    local limit = math.max(0, math.floor(tonumber(count) or #candidates))
    for i = 1, math.min(limit, #candidates) do
        result[i] = candidates[i].player
    end
    return result
end

function TargetService:FindNearest(maxDist, skipBlacklist)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then
        return nil
    end

    local bestPlayer, bestChar, bestDist = nil, nil, tonumber(maxDist) or math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local skipped = skipBlacklist == true
                and _G.TAYJAY_BL
                and type(_G.TAYJAY_BL.has) == "function"
                and _G.TAYJAY_BL.has(player.Name)
            if not skipped then
                local dist, char = distanceTo(player)
                if dist and dist < bestDist then
                    bestDist = dist
                    bestPlayer = player
                    bestChar = char
                end
            end
        end
    end
    return bestPlayer, bestChar, bestDist
end

function TargetService:TryAttackPlayer(player)
    if type(self._attackFn) ~= "function" or not isPlayerValid(player) then
        return false
    end
    local char = player.Character
    if not char then
        return false
    end
    local ok, result = pcall(self._attackFn, char)
    return ok and result == true
end

function TargetService:StopCombatOwner(reason)
    stopHold()
    local owner = self._combatOwner
    self._combatOwner = nil
    if owner and owner.Stopped ~= true and ResourceManager then
        pcall(function()
            ResourceManager:StopOwner("TargetCombat", reason or "stop")
        end)
    end
end

function TargetService:EnsureCombatOwner()
    if not ResourceManager or type(ResourceManager.CreateOwner) ~= "function" then
        return nil
    end
    if self._combatOwner and self._combatOwner.Stopped ~= true then
        return self._combatOwner
    end

    local owner = ResourceManager:CreateOwner("TargetCombat", function()
        TargetService._combatOwner = nil
    end)
    if not owner then
        return nil
    end
    self._combatOwner = owner

    local conn = RunService.Heartbeat:Connect(function()
        if owner.Stopped then
            return
        end
        local attackFn = TargetService._attackFn
        if type(attackFn) ~= "function" then
            return
        end

        -- Busy state is read only from the canonical app-state table.
        -- Do not depend on an undeclared/global isBusy variable.
        local state = Main.State
        local busy = (state and state.isBusy == true) or Main.isBusy == true
        if busy then
            stopHold()
            return
        end

        if TargetService.Locked and TargetService.Source == "deathnote" then
            stopHold()
            local player = TargetService:GetPlayer()
            if not player then
                TargetService:Unlock("invalid_player")
                return
            end
            local dist, char = distanceTo(player)
            if dist and dist <= (TargetService.Range or 25) and char then
                pcall(attackFn, char)
            end
            return
        end


        if statesRef.NormalKillAura then
            -- WALK's primary target is always the nearest living, non-blacklisted player.
            local nearestPlayer, nearestChar = TargetService:FindNearest(math.huge, true)
            TargetService.WalkTarget = nearestPlayer

            -- Retaliation is tracked separately and never overwrites the nearest target.
            local attacker = TargetService:FindRetaliationTarget()
            local attackerChar
            if attacker then
                local attackerDistance
                attackerDistance, attackerChar = distanceTo(attacker)
            end

            local targetChar
            local shouldSwitchLane = false
            if attackerChar and nearestChar and attacker ~= nearestPlayer then
                local lane = TargetService._combatLane or "walk"
                targetChar = lane == "retaliation" and attackerChar or nearestChar
                shouldSwitchLane = true
            elseif attackerChar then
                targetChar = attackerChar
            elseif nearestChar then
                targetChar = nearestChar
            end

            if targetChar then
                startHold(targetChar)
                if shouldSwitchLane then
                    local now = os.clock()
                    if not TargetService._lastLaneSwitch
                        or now - TargetService._lastLaneSwitch >= 1.2 then
                        local lane = TargetService._combatLane or "walk"
                        TargetService._combatLane = lane == "retaliation" and "walk" or "retaliation"
                        TargetService._lastLaneSwitch = now
                    end
                end
            else
                stopHold()
            end
        else
            stopHold()
            TargetService.WalkTarget = nil
            TargetService.RetaliationTarget = nil
            TargetService._combatLane = "walk"
        end
    end)
    owner:Own(conn)

    owner:Own(Players.PlayerRemoving:Connect(function(player)
        if TargetService.Player == player then
            TargetService:Unlock("player_removing")
        end
    end))

    return owner
end

_tjTargetEnv.TAYJAY_TARGET = TargetService
TJ.TargetService = TargetService
Main.TargetService = TargetService

