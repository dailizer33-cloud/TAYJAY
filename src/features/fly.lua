-- =========================================================
-- 🕊️ FLY WIDGET
-- =========================================================
local FlyFrame = Instance.new("Frame", screenGui)
FlyFrame.Name = "TayJayFlyControl"
FlyFrame.BackgroundColor3 = GREEN.dark
FlyFrame.BackgroundTransparency = 0.02
FlyFrame.AnchorPoint = Vector2.new(0, 1)
FlyFrame.Position = UI_LAYOUT.FlyBottom
FlyFrame.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.FlyH)
FlyFrame.Active = true
FlyFrame.Visible = false
FlyFrame.ClipsDescendants = true
Instance.new("UICorner", FlyFrame).CornerRadius = UDim.new(0, 16)
local flyFrameStroke = Instance.new("UIStroke", FlyFrame); flyFrameStroke.Name = "TayJayWindowAccent"
flyFrameStroke.Color = UI_LAYOUT.Accent.Fly
flyFrameStroke.Thickness = 2.5
makeDraggable(FlyFrame)

-- ดีไซน์ใหม่: หัวข้อ + ป้ายสถานะ, ปุ่มบินใหญ่, ปุ่มขึ้น/ลงใหญ่, แถวปรับความเร็ว, ปุ่มหยุดฉุกเฉิน
local flyUi = {
   accent = UI_LAYOUT.Accent.Fly,
   navy = Color3.fromRGB(26, 41, 68),
   ink = Color3.fromRGB(10, 16, 32),
   muted = Color3.fromRGB(159, 176, 200),
}
function flyUi.button(name, pos, size, bg, text, textSize, textColor)
   local b = Instance.new("TextButton", FlyFrame)
   b.Name = name; b.Position = pos; b.Size = size
   b.BackgroundColor3 = bg; b.Text = text; b.TextSize = textSize
   b.TextColor3 = textColor or WHITE_TEXT; b.Font = Enum.Font.GothamBold
   b.AutoButtonColor = true; b.BorderSizePixel = 0
   Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
   return b
end
do
   local title = Instance.new("TextLabel", FlyFrame)
   title.Name = "FlyTitle"; title.BackgroundTransparency = 1
   title.Position = UDim2.fromOffset(12, 8); title.Size = UDim2.fromOffset(60, 24)
   title.Font = Enum.Font.GothamBlack; title.Text = "FLY"; title.TextSize = 17
   title.TextColor3 = flyUi.accent; title.TextXAlignment = Enum.TextXAlignment.Left
   flyUi.pill = Instance.new("Frame", FlyFrame)
   flyUi.pill.Name = "FlyPill"; flyUi.pill.Position = UDim2.new(1, -112, 0, 10)
   flyUi.pill.Size = UDim2.fromOffset(76, 22); flyUi.pill.BorderSizePixel = 0
   Instance.new("UICorner", flyUi.pill).CornerRadius = UDim.new(1, 0)
   flyUi.pillText = Instance.new("TextLabel", flyUi.pill)
   flyUi.pillText.Size = UDim2.fromScale(1, 1); flyUi.pillText.BackgroundTransparency = 1
   flyUi.pillText.Font = Enum.Font.GothamBold; flyUi.pillText.TextSize = 11

   -- [เพิ่มใหม่] ปุ่ม (X) สำหรับปิดหน้าต่างบิน
   local flyClose = Instance.new("TextButton", FlyFrame)
   flyClose.Name = "FlyCloseBtn"
   flyClose.Size = UDim2.new(0, 22, 0, 22)
   flyClose.Position = UDim2.new(1, -28, 0, 8)
   flyClose.BackgroundColor3 = Color3.fromRGB(215, 45, 40)
   flyClose.Text = "✕"
   flyClose.TextColor3 = Color3.fromRGB(255, 255, 255)
   flyClose.Font = Enum.Font.GothamBold
   flyClose.TextSize = 13
   Instance.new("UICorner", flyClose).CornerRadius = UDim.new(1, 0)
   
   trackConnection(flyClose.Activated:Connect(function()
       syncButtonState("Fly", false) -- เมื่อกดกากบาท จะปิดหน้าต่างและซิงค์เมนูหลักเป็น OFF
   end))
end

local flyOnOf = flyUi.button("FlyToggle", UDim2.fromOffset(10, 42), UDim2.new(1, -20, 0, 38), flyUi.navy, "", 15)
flyUi.ring = Instance.new("UIStroke", flyOnOf)
flyUi.ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; flyUi.ring.Color = flyUi.accent; flyUi.ring.Thickness = 2

local flyUp = flyUi.button("FlyUp", UDim2.fromOffset(10, 88), UDim2.new(0.5, -14, 0, 44), flyUi.navy, "▲  ขึ้น", 15)
local flyDown = flyUi.button("FlyDown", UDim2.new(0.5, 4, 0, 88), UDim2.new(0.5, -14, 0, 44), flyUi.navy, "▼  ลง", 15)

local flyMine = flyUi.button("FlySpeedMinus", UDim2.fromOffset(10, 140), UDim2.fromOffset(34, 34), flyUi.navy, "", 14)
UI_LAYOUT.glyph(flyMine, false, flyUi.accent, 16, 4)
local flySpeedLabel = Instance.new("TextLabel", FlyFrame)
flySpeedLabel.Name = "FlySpeedLabel"; flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Position = UDim2.fromOffset(48, 140); flySpeedLabel.Size = UDim2.new(1, -96, 0, 34)
flySpeedLabel.Font = Enum.Font.GothamBold; flySpeedLabel.TextSize = 14; flySpeedLabel.TextColor3 = WHITE_TEXT
flySpeedLabel.TextScaled = true; flySpeedLabel.Text = "ความเร็วบิน  x1"
do
   local c = Instance.new("UITextSizeConstraint", flySpeedLabel); c.MaxTextSize = 14; c.MinTextSize = 9
end
local flyPlus = flyUi.button("FlySpeedPlus", UDim2.new(1, -44, 0, 140), UDim2.fromOffset(34, 34), flyUi.accent, "", 14)
UI_LAYOUT.glyph(flyPlus, true, flyUi.ink, 16, 4)

local flyEmergencyStop = flyUi.button("FlyEmergencyStop", UDim2.fromOffset(10, 182), UDim2.new(1, -20, 0, 32),
   Color3.fromRGB(44, 22, 34), "⛔ หยุดฉุกเฉิน", 13, Color3.fromRGB(255, 143, 163))
do
   local ring = Instance.new("UIStroke", flyEmergencyStop)
   ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Color = Color3.fromRGB(255, 92, 122); ring.Thickness = 2
end

function flyUi.setVisual(on)
   flyOnOf.Text = on and "บิน · เปิดอยู่" or "บิน · ปิดอยู่"
   flyOnOf.BackgroundColor3 = on and flyUi.accent or flyUi.navy
   flyOnOf.TextColor3 = on and flyUi.ink or WHITE_TEXT
   flyUi.ring.Enabled = not on
   flyUi.pill.BackgroundColor3 = on and flyUi.accent or Color3.fromRGB(42, 55, 80)
   flyUi.pillText.Text = on and "กำลังบิน" or "ปิดอยู่"
   flyUi.pillText.TextColor3 = on and flyUi.ink or flyUi.muted
end
flyUi.setVisual(false)

local flySpeeds = 1
local flyNowe = false
local bg, bv, flyLoop
local flyOwner = nil
local verticalInput = 0
local savedHumanoid = nil
local savedPlatformStand = false
local savedAutoRotate = true
local savedAnimateDisabled = false
local savedStateEnabled = {}
local flyStateTypes = {
   Enum.HumanoidStateType.Climbing,
   Enum.HumanoidStateType.FallingDown,
   Enum.HumanoidStateType.Flying,
   Enum.HumanoidStateType.Freefall,
   Enum.HumanoidStateType.GettingUp,
   Enum.HumanoidStateType.Jumping,
   Enum.HumanoidStateType.Landed,
   Enum.HumanoidStateType.Physics,
   Enum.HumanoidStateType.PlatformStanding,
   Enum.HumanoidStateType.Ragdoll,
   Enum.HumanoidStateType.Running,
   Enum.HumanoidStateType.RunningNoPhysics,
   Enum.HumanoidStateType.Seated,
   Enum.HumanoidStateType.StrafingNoPhysics,
   Enum.HumanoidStateType.Swimming
}

local function setVerticalInput(value)
   verticalInput = value
end

local function stopFlying(syncState)
   if not flyNowe and not flyOwner then
      return
   end

   flyNowe = false
   verticalInput = 0
   flyUi.setVisual(false)

   -- คืนค่า Humanoid / Animate ก่อนล้าง physics objects
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if hum then
      for _, stateType in ipairs(flyStateTypes) do
         local oldEnabled = savedStateEnabled[stateType]
         if oldEnabled ~= nil then
            pcall(function() hum:SetStateEnabled(stateType, oldEnabled) end)
         else
            pcall(function() hum:SetStateEnabled(stateType, true) end)
         end
      end
      hum.PlatformStand = savedPlatformStand
      hum.AutoRotate = savedAutoRotate
      pcall(function() hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
   end

   if char then
      local animate = char:FindFirstChild("Animate")
      if animate then animate.Disabled = savedAnimateDisabled end
      local root = char:FindFirstChild("HumanoidRootPart")
      if root then
         for _, obj in ipairs(root:GetChildren()) do
            if obj.Name == "TayJayFlyGyro" or obj.Name == "TayJayFlyVelocity" then
               pcall(function() obj:Destroy() end)
            end
         end
      end
   end

   -- หยุด Owner → Bag จะ Disconnect flyLoop และ Destroy bg/bv
   local owner = flyOwner
   flyOwner = nil
   flyLoop = nil
   bg = nil
   bv = nil
   if owner and owner.Stopped ~= true then
      pcall(function()
         ResourceManager:StopOwner("Fly", syncState and "sync" or "stopFlying")
      end)
   end

   savedHumanoid = nil
   savedStateEnabled = {}
end
trackConnection(flyEmergencyStop.Activated:Connect(function()
   verticalInput = 0
   local char = LocalPlayer.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if root then
       pcall(function()
           root.AssemblyLinearVelocity = Vector3.zero
           root.AssemblyAngularVelocity = Vector3.zero
       end)
   end
   if flyNowe then
       stopFlying()
       FlyFrame.Visible = true
   end
end))

do -- [TAYJAY LOCAL-LIMIT FIX 4/8]
local function beginVerticalHold(button, direction)
   local began = button.InputBegan:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
           setVerticalInput(direction)
       end
   end)
   local ended = button.InputEnded:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
           if verticalInput == direction then setVerticalInput(0) end
       end
   end)
   trackConnection(began)
   trackConnection(ended)
end

local function toggleFlyState()
   -- Fly may be toggled while Warp/MM2 movement is active.
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if not hum or not root or hum.Health <= 0 then return end

   if flyNowe then
       stopFlying()
       FlyFrame.Visible = true
       return
   end

   for _, obj in ipairs(root:GetChildren()) do
       if obj.Name == "TayJayFlyGyro" or obj.Name == "TayJayFlyVelocity" then
           pcall(function() obj:Destroy() end)
       end
   end

   flyNowe = true
   syncButtonState("Fly", true)
   FlyFrame.Visible = true
   flyUi.setVisual(true)

   savedHumanoid = hum
   savedPlatformStand = hum.PlatformStand
   savedAutoRotate = hum.AutoRotate
   savedStateEnabled = {}
   for _, stateType in ipairs(flyStateTypes) do
       local ok, enabled = pcall(function() return hum:GetStateEnabled(stateType) end)
       if ok then savedStateEnabled[stateType] = enabled end
   end

   local animate = char:FindFirstChild("Animate")
   savedAnimateDisabled = animate and animate.Disabled or false
   if animate then ResourceManager:RecordWrite("Fly", "AnimateState"); animate.Disabled = true end

   ResourceManager:RecordWrite("Fly", "HumanoidFlags")
    hum.AutoRotate = false
   for _, stateType in ipairs(flyStateTypes) do
       ResourceManager:RecordWrite("Fly", "HumanoidFlags")
        pcall(function() hum:SetStateEnabled(stateType, false) end)
   end
   ResourceManager:RecordWrite("Fly", "HumanoidFlags")
    hum.PlatformStand = true
   pcall(function() hum:ChangeState(Enum.HumanoidStateType.Swimming) end)

   local flyPart = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or root

   -- Owner สำหรับทรัพยากรช่วงบินเท่านั้น (loop + body movers)
   flyOwner = ResourceManager:CreateOwner("Fly", function(reason)
      -- onStop: กันกรณีถูก Stop จาก STOP ALL โดยตรง
      if flyNowe then
         flyNowe = false
         verticalInput = 0
         flyUi.setVisual(false)
         local c = LocalPlayer.Character
         local h = c and c:FindFirstChildOfClass("Humanoid")
         if h then
            for _, stateType in ipairs(flyStateTypes) do
               local oldEnabled = savedStateEnabled[stateType]
               if oldEnabled ~= nil then
                  pcall(function() h:SetStateEnabled(stateType, oldEnabled) end)
               else
                  pcall(function() h:SetStateEnabled(stateType, true) end)
               end
            end
            h.PlatformStand = savedPlatformStand
            h.AutoRotate = savedAutoRotate
            pcall(function() h:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
         end
         if c then
            local anim = c:FindFirstChild("Animate")
            if anim then anim.Disabled = savedAnimateDisabled end
         end
         savedHumanoid = nil
         savedStateEnabled = {}
      end
      flyOwner = nil
      flyLoop = nil
      bg = nil
      bv = nil
   end)

   bg = Instance.new("BodyGyro")
   bg.Name = "TayJayFlyGyro"
   bg.P = 9e4
   bg.D = 1000
   bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
   bg.CFrame = flyPart.CFrame
   bg.Parent = flyPart
   flyOwner:Own(bg)

   bv = Instance.new("BodyVelocity")
   bv.Name = "TayJayFlyVelocity"
   bv.P = 9e4
   bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
   bv.Velocity = Vector3.new(0, 0.1, 0)
   bv.Parent = flyPart
   flyOwner:Own(bv)

   flyLoop = RunService.Heartbeat:Connect(function(dt)
      if not flyNowe then return end
      if not char.Parent or not hum.Parent or hum.Health <= 0 or not root.Parent or not flyPart.Parent then
         stopFlying()
         return
      end

      local camera = workspace.CurrentCamera
      if not camera then return end

      local mwLockUntil = _G.TAYJAY_POS_LOCK_UNTIL
      local mwLocked = mwLockUntil ~= nil and os.clock() < mwLockUntil

      local move = hum.MoveDirection
      if not mwLocked and move.Magnitude > 0.001 then
         local frameScale = math.clamp(dt * 60, 0, 2)
         ResourceManager:RecordWrite("Fly", "Position")
         char:TranslateBy(move * flySpeeds * frameScale)
      end

      if not mwLocked and verticalInput ~= 0 then
         local frameScale = math.clamp(dt * 60, 0, 2)
         ResourceManager:RecordWrite("Fly", "Position")
         char:TranslateBy(Vector3.new(0, verticalInput * flySpeeds * frameScale, 0))
      end

      if bv then bv.Velocity = Vector3.new(0, 0.1, 0) end
      if bg then
         local look = camera.CFrame.LookVector
         local flatLook = Vector3.new(look.X, 0, look.Z)
         if flatLook.Magnitude > 0.001 then
            bg.CFrame = CFrame.lookAt(flyPart.Position, flyPart.Position + flatLook.Unit)
         end
      end
   end)
   flyOwner:Own(flyLoop)
end

trackConnection(flyOnOf.Activated:Connect(toggleFlyState))
beginVerticalHold(flyUp, 1)
beginVerticalHold(flyDown, -1)
local function updateFlySpeedLabel()
   flySpeedLabel.Text = "ความเร็วบิน  x" .. tostring(flySpeeds)
end
updateFlySpeedLabel()

trackConnection(flyPlus.Activated:Connect(function()
   flySpeeds = math.min(flySpeeds + 1, 10)
   updateFlySpeedLabel()
end))
trackConnection(flyMine.Activated:Connect(function()
   flySpeeds = math.max(1, flySpeeds - 1)
   updateFlySpeedLabel()
end))

trackConnection(UserInputService.WindowFocusReleased:Connect(function()
   setVerticalInput(0)
end))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   if flyNowe then stopFlying() end
end))

end -- [/TAYJAY LOCAL-LIMIT FIX 4/8]
