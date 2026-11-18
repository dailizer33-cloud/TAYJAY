-- =========================================================
-- WALK Dynamic Target: เลือกผู้เล่นที่มีชีวิตและใกล้ที่สุดใหม่ทุกครั้งที่ค้นหา
local function getDynamicWalkTarget()
   local myCharacter = LocalPlayer.Character
   local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
   local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
   if not myRoot or not myHumanoid or myHumanoid.Health <= 0 then return nil end

   local nearestCharacter = nil
   local nearestDistance = math.huge
   for _, player in ipairs(Players:GetPlayers()) do
       if player ~= LocalPlayer then
           local character = player.Character
           local root = character and character:FindFirstChild("HumanoidRootPart")
           local humanoid = character and character:FindFirstChildOfClass("Humanoid")
           if root and humanoid and humanoid.Health > 0 then
               local distance = (root.Position - myRoot.Position).Magnitude
               if distance < nearestDistance then
                   nearestDistance = distance
                   nearestCharacter = character
               end
           end
       end
   end
   return nearestCharacter
end

task.spawn(function()
   while screenGui.Parent do
       task.wait(0.05)
       if states.NormalKillAura and AttackRemote and not isBusy then
           local targetChar = getDynamicWalkTarget()
           if targetChar then
               tryAttackTarget(targetChar)
           end
       end
   end
end)

