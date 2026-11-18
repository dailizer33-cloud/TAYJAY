-- =========================================================
-- LOGIC SYSTEMS
-- =========================================================

-- AutoWarp menu toggle shares the Death Note Shadow Hunter loop above.
-- The empty legacy Stepped warp was removed to prevent competing CFrame controllers.

-- LOGIC หลักอื่นๆ
trackConnection(RunService.RenderStepped:Connect(function()
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if states.Speed and hum then
       if TJ.Main.State.originalWalkSpeed == nil then
           TJ.Main.State.originalWalkSpeed = hum.WalkSpeed
           TJ.Main.originalWalkSpeed = TJ.Main.State.originalWalkSpeed
       end
       ResourceManager:RecordWrite("Speed", "WalkSpeed")
        hum.WalkSpeed = config.WalkSpeed
   end
end))

trackConnection(UserInputService.JumpRequest:Connect(function()
   if states.InfJump and LocalPlayer.Character then
       local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
       if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
   end
end))

local noclipCache = {}
local function setNoclip(enabled)
   local char = LocalPlayer.Character
   if enabled and char then
       for _, part in ipairs(char:GetDescendants()) do
           if part:IsA("BasePart") then
               if noclipCache[part] == nil then noclipCache[part] = part.CanCollide end
               part.CanCollide = false
           end
       end
   else
       for part, wasCollidable in pairs(noclipCache) do
           if part and part.Parent then part.CanCollide = wasCollidable end
           noclipCache[part] = nil
       end
   end
end

registerUiSync("Noclip", setNoclip)
trackConnection(RunService.Stepped:Connect(function()
   if states.Noclip then setNoclip(true) end
end))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   table.clear(noclipCache)
   TJ.Main.State.originalWalkSpeed = nil
   TJ.Main.originalWalkSpeed = nil
end))

local xrayCache = {}
registerUiSync("Xray", function(isOn)
   for _, part in ipairs(workspace:GetDescendants()) do
       if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) and not part:IsA("Terrain") then
           if isOn then
               if xrayCache[part] == nil then xrayCache[part] = part.LocalTransparencyModifier end
               part.LocalTransparencyModifier = 0.65
           else
               if xrayCache[part] ~= nil then part.LocalTransparencyModifier = xrayCache[part]; xrayCache[part] = nil end
           end
       end
   end
end)

