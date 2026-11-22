
do
   -- WARP (ปุ่มวงกลม): สุ่มหาเป้าหมายในระยะ 200 studs ไม่ต้องเลือกในสมุดสั่งตาย
   trackConnection(kaCircleBtn.Activated:Connect(function()
       local turningOn = not states.KillAura
       if turningOn and stopMonsterWarp and states.MonsterWarp then
           stopMonsterWarp(true)
       end
       states.KillAura = not states.KillAura
       if states.KillAura then
           states.NormalKillAura = false
            if type(TargetService) == "table" and TargetService.Source == "deathnote" then
                TargetService:Unlock("warp_mode")
            end
            selectedDeathNoteTarget = nil
            syncButtonState("DNWarp", false)
            -- อนุญาตคู่ Fly + WARP: ไม่ปิด Fly แล้ว (ตัวล็อกตำแหน่งกลางกันแย่งกันขยับ ดู TAYJAY_POS_LOCK_UNTIL)
       end
       updateKaBtnDisplay()
   end))

   -- WALK: โจมตีระยะใกล้ (ไม่เปลี่ยน)
   trackConnection(kaNormalBtn.Activated:Connect(function()
       states.NormalKillAura = not states.NormalKillAura
       if states.NormalKillAura then
           states.KillAura = false
           if type(TargetService) == "table" then
               if TargetService.Source == "deathnote" then
                   TargetService:Unlock("walk_mode")
               end
               TargetService:EnsureCombatOwner()
           end
       end
       updateKaBtnDisplay()
   end))

   -- โหมดสมุดสั่งตาย (รวม Auto Warp เดิม): เปิด/ปิดด้วยการกดชื่อในรายการ
   _G.TAYJAY_DN_REPAINT = function()
       if not dnScroll then return end
       for _, card in ipairs(dnScroll:GetChildren()) do
           if card:IsA("TextButton") then
               local picked = selectedDeathNoteTarget ~= nil and selectedDeathNoteTarget.Name == card.Name
               card.BackgroundColor3 = picked and Color3.fromRGB(190, 35, 35) or Color3.fromRGB(30, 52, 78)
               local stroke = card:FindFirstChildOfClass("UIStroke")
               if stroke then stroke.Color = picked and Color3.fromRGB(255, 110, 110) or UI_LAYOUT.Accent.Players end
           end
       end
   end
   registerUiSync("DNWarp", function(isOn)
       if isOn then
           if stopMonsterWarp and states.MonsterWarp then stopMonsterWarp(true) end
           states.KillAura = false
           if flyNowe then stopFlying() end
       end
       if _G.TAYJAY_DN_REPAINT then _G.TAYJAY_DN_REPAINT() end
       updateKaBtnDisplay()
   end)

-- เมนู 7 (วาร์ปออโต้) ทำงานกับเป้าหมายในสมุด จึงไม่ซ้อนกับ WARP สุ่ม
   registerUiSync("AutoWarp", function(isOn)
       if isOn then
           if stopMonsterWarp and states.MonsterWarp then stopMonsterWarp(true) end
           states.KillAura = false
       end
       updateKaBtnDisplay()
   end)
end

local warpRuntimeOwner -- shared with the WARP runtime section below
do -- [TAYJAY LOCAL-LIMIT FIX 5/8]
local radius = 15
local numParts = 36
local circleParts = {}

-- Runtime owner: owns circle cleanup + long-running Warp loops.
-- Keep warpOwner reserved for the character reference inside the WARP loop.
warpRuntimeOwner = ResourceManager:CreateOwner("WarpRuntime", function(reason)
   pcall(function()
      for _, inst in ipairs(workspace:GetChildren()) do
         if inst.Name == "TayJayWarpPlatform" then
            inst:Destroy()
         end
      end
   end)
   _G.TAYJAY_FOLLOW = nil
   _G.TAYJAY_POS_LOCK_UNTIL = nil
end)

local function destroyCircleParts()
   for i = #circleParts, 1, -1 do
       local part = circleParts[i]
       circleParts[i] = nil
       if part and part.Parent then pcall(function() part:Destroy() end) end
   end
end

local function ensureCircleParts()
   if #circleParts > 0 then return end
   for i = 1, numParts do
       local part = Instance.new("Part")
       part.Name = "TayJayWarpCirclePart"
       part.Anchored = true
       part.CanCollide = false
       part.Material = Enum.Material.Neon
       part.Color = Color3.fromRGB(255, 211, 58)
       part.Size = Vector3.new(1, 0.1, (2 * math.pi * radius) / numParts)
       part.Transparency = 1
       part.Parent = workspace
       table.insert(circleParts, part)
   end
end
warpRuntimeOwner:Own(destroyCircleParts)

local function getClosestPlayer_V57(maxDist)
   local closestPlayer = nil; local shortestDistance = maxDist or maxAttackDistance
   local myChar = LocalPlayer.Character
   if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
   local myPos = myChar.HumanoidRootPart.Position

   for _, v in pairs(Players:GetPlayers()) do
       if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
           if v.Character.Humanoid.Health > 0 then
               local distance = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
               if distance < shortestDistance then closestPlayer = v.Character; shortestDistance = distance end
           end
       end
   end
   return closestPlayer
end

local function updateCirclePosition()
   local char = LocalPlayer.Character
   if not char or not char:FindFirstChild("HumanoidRootPart") or not (states.KillAura or states.NormalKillAura) then
       destroyCircleParts()
       return
   end
   ensureCircleParts()
   local cframe = char.HumanoidRootPart.CFrame
   local angleInc = math.rad(360 / numParts)
   for i, part in ipairs(circleParts) do
       local angle = angleInc * i
       part.CFrame = cframe * CFrame.new(math.cos(angle) * radius, -2, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
       part.Transparency = 0.3
   end
end

do
   local conn = RunService.RenderStepped:Connect(function()
      if not (states.KillAura or states.AutoWarp or states.NormalKillAura or states.DNWarp) then
          targetGui.Visible = false
          destroyCircleParts()
          return
      end
      targetGui.Visible = true
      local shadowMode = states.KillAura or states.AutoWarp or states.DNWarp
      local target
      if shadowMode then
          target = selectedDeathNoteTarget and selectedDeathNoteTarget.Character or nil
      else
          local searchDist = states.NormalKillAura and math.huge or maxAttackDistance
          target = getClosestPlayer_V57(searchDist)
      end

      if shadowMode then
          -- โหมด WARP: ลูป Shadow Hunter เป็นผู้เขียนข้อความและแถบ HP แต่เพียงผู้เดียว (กันข้อความกระพริบ)
      elseif target then
          local humanoid = target:FindFirstChildOfClass("Humanoid")
          if humanoid then
              local health = math.floor(humanoid.Health); local maxHealth = math.floor(humanoid.MaxHealth)
              targetTitle.Text = (shadowMode and "🕶 Target: " or "⚔️ เป้าหมาย: ") .. target.Name
              targetHpLabel.Text = health .. " / " .. maxHealth .. " HP"
              targetBarFill.Size = UDim2.new(math.clamp(health / math.max(maxHealth, 1), 0, 1), 0, 1, 0)
          end
      else
          targetTitle.Text = shadowMode and "☠ Select target in Death Note" or "⚔️ เป้าหมาย: ไม่พบเป้าหมาย"
          targetHpLabel.Text = "0 / 0 HP"; targetBarFill.Size = UDim2.new(0, 0, 1, 0)
      end
      updateCirclePosition()
   end)
   if warpRuntimeOwner then
      warpRuntimeOwner:Own(conn)
   else
      trackConnection(conn)
   end
end

end -- [/TAYJAY LOCAL-LIMIT FIX 5/8]

-- DEATH NOTE SHADOW HUNTER: Death Note selects the target; WARP UI / AutoWarp starts tracking.
-- Replaces the old head-sit warp entirely. Position updates are client-side and remain subject to server correction.
local SHADOW_FOLLOW_OFFSET = CFrame.new(0, 0, 3.5)
local SHADOW_UPDATE_INTERVAL = 0.12
local lastShadowTarget = nil
local lastShadowCharacter = nil
local shadowHiddenCharacter = nil

local function stopShadowHunterVisuals()
   if shadowHiddenCharacter then
       setInvisibility(shadowHiddenCharacter, false)
       shadowHiddenCharacter = nil
   end
   lastShadowTarget = nil
   lastShadowCharacter = nil
end

-- WARP physics connections exist only while a WARP mode is active.
local warpHeartbeatConnection, warpSteppedConnection
local warpNoclipParts, warpNoclipChar, warpNoclipRefreshAt = {}, nil, 0
local warpCollisionSaved = {}

local function restoreWarpCollision()
   for part in pairs(warpCollisionSaved) do
       if part and part.Parent then pcall(function() part.CanCollide = true end) end
       warpCollisionSaved[part] = nil
   end
   warpNoclipParts, warpNoclipChar, warpNoclipRefreshAt = {}, nil, 0
end

local function stopWarpPhysicsConnections()
   if warpHeartbeatConnection then warpHeartbeatConnection:Disconnect(); warpHeartbeatConnection = nil end
   if warpSteppedConnection then warpSteppedConnection:Disconnect(); warpSteppedConnection = nil end
   restoreWarpCollision()
   _G.TAYJAY_FOLLOW = nil
   _G.TAYJAY_POS_LOCK_UNTIL = nil
end

local function startWarpPhysicsConnections()
   if warpHeartbeatConnection and warpSteppedConnection then return end
   local FOLLOW_OFFSET = CFrame.new(0, 0, 3.5)
   if not warpHeartbeatConnection then
       warpHeartbeatConnection = RunService.Heartbeat:Connect(function()
           local f = _G.TAYJAY_FOLLOW
           if not f or not f.player or f.player.Parent ~= Players then return end
           if (_G.TAYJAY_WARP_HOLD_UNTIL or 0) > os.clock() then return end
           local myChar = LocalPlayer.Character
           local myRootNow = myChar and myChar:FindFirstChild("HumanoidRootPart")
           local tChar = f.player.Character
           local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
           local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
           if not myRootNow or not tRoot or not tHum or tHum.Health <= 0 then return end
           _G.TAYJAY_POS_LOCK_UNTIL = os.clock() + 0.3
           ResourceManager:RecordWrite("ShadowHunter", "Velocity")
           myRootNow.AssemblyLinearVelocity = Vector3.zero
           myRootNow.AssemblyAngularVelocity = Vector3.zero
           ResourceManager:RecordWrite("ShadowHunter", "Position")
           myRootNow.CFrame = tRoot.CFrame * FOLLOW_OFFSET
       end)
       if warpRuntimeOwner then warpRuntimeOwner:Own(warpHeartbeatConnection) end
   end
   if not warpSteppedConnection then
       warpSteppedConnection = RunService.Stepped:Connect(function()
           local lockUntil = _G.TAYJAY_POS_LOCK_UNTIL
           local locked = (states.KillAura or states.DNWarp) and _G.TAYJAY_FOLLOW ~= nil
               and lockUntil ~= nil and os.clock() < lockUntil
           if not locked then restoreWarpCollision(); return end
           local char = LocalPlayer.Character
           if not char then return end
           if char ~= warpNoclipChar or os.clock() >= warpNoclipRefreshAt then
               warpNoclipChar = char
               warpNoclipRefreshAt = os.clock() + 0.5
               local list = {}
               for _, part in ipairs(char:GetDescendants()) do
                   if part:IsA("BasePart") then
                       table.insert(list, part)
                       if part.CanCollide then warpCollisionSaved[part] = true end
                   end
               end
               warpNoclipParts = list
           end
           for _, part in ipairs(warpNoclipParts) do
               if part.Parent and part.CanCollide then part.CanCollide = false end
           end
       end)
       if warpRuntimeOwner then warpRuntimeOwner:Own(warpSteppedConnection) end
   end
end

warpRuntimeOwner:Own(stopWarpPhysicsConnections)


local shadowThread = task.spawn(function()
   local WARP_SEARCH_RANGE = math.huge -- ค้นทั้งแมพ (ใส่ตัวเลข เช่น 200 เพื่อจำกัดระยะจากจุดยืน)
   local WARP_CHAIN_COUNT = 3 -- เมื่อเป้าหมายตาย สุ่มจากคนที่ใกล้จุดตายที่สุดกี่คน
   local WARP_REST_SECONDS = 1 -- พักที่จุดยืนกี่วินาทีก่อนหาเป้าหมายใหม่
   local WARP_PLATFORM_SIZE = Vector3.new(16, 1, 16) -- ขนาดพื้นกันตก
   local WARP_FEET_DROP = 3 -- ระยะจากกลาง HumanoidRootPart ถึงใต้เท้า (studs)
   local randomWarpTarget = nil -- เป้าหมาย WARP ปัจจุบัน
   local warpHome = nil -- CFrame จุดยืนที่กด WARP
   local warpOwner = nil -- ตัวละครที่กด WARP (ใช้ตรวจการเกิดใหม่)
   local warpPlatform = nil -- พื้นกันตก
   local warpRestUntil = 0 -- เวลาที่พักเสร็จ
   local warpWasOn = false
   local warpLastPos = nil -- ตำแหน่งล่าสุดของเป้าหมาย WARP
   local function isSkipped(player)
       return _G.TAYJAY_BL.has(player.Name)
   end

   -- หาคนที่ใกล้จุดยืนที่สุดในระยะ maxDistance (ข้าม blacklist และคนที่ตายแล้ว)
   local function pickNearChain(origin, count)
       if type(TargetService) ~= "table" then return nil end
       local pool = TargetService:FindNearestPoolFromPosition(origin, count, true)
       if #pool == 0 then return nil end
       return pool[math.random(1, #pool)]
   end
   local function findNearestFromHome(maxDistance, origin)
       if type(TargetService) ~= "table" then return nil end
       return TargetService:FindNearestFromPosition(origin, maxDistance, true)
   end

   -- พื้นกันตก: แพตโปร่งใสที่ชนได้ อยู่ใต้เท้าตัวละครเสมอ (กันตกเมื่อแมพยังไม่โหลด)
   local function ensurePlatform()
       if not warpPlatform or not warpPlatform.Parent then
           local part = Instance.new("Part")
           part.Name = "TayJayWarpPlatform"
           part.Anchored = true
           part.CanCollide = true
           part.Size = WARP_PLATFORM_SIZE
           part.Transparency = 1
           part.TopSurface = Enum.SurfaceType.Smooth
           part.BottomSurface = Enum.SurfaceType.Smooth
           part.Parent = workspace
           warpPlatform = part
           if warpRuntimeOwner then
               warpRuntimeOwner:Own(part)
           end
       end
       return warpPlatform
   end
   local function placePlatformUnder(position)
       ensurePlatform().CFrame = CFrame.new(position.X, position.Y - WARP_FEET_DROP - WARP_PLATFORM_SIZE.Y / 2, position.Z)
   end
   -- ลบพื้นกันตกทันทีเมื่อ WARP ปิดหรือเปลี่ยนตัวละคร
   local function destroyPlatform()
       local part = warpPlatform
       warpPlatform = nil
       if part and part.Parent then pcall(function() part:Destroy() end) end
   end

   warpRuntimeOwner:Own(function()
       destroyPlatform()
       _G.TAYJAY_FOLLOW = nil
       stopShadowHunterVisuals()
   end)
   -- กลับไปยืนที่จุดยืน (ใช้เฉพาะเมื่อยังเป็นตัวละครเดิม)
   local function goHome(myRoot)
       if warpHome and warpOwner and myRoot and warpOwner == LocalPlayer.Character then
           myRoot.Anchored = false
           myRoot.CFrame = warpHome
           placePlatformUnder(warpHome.Position)
       end
   end

   while screenGui.Parent do
       if warpRuntimeOwner and warpRuntimeOwner.Stopped then
           break
       end
       local shadowEnabled = states.KillAura or states.DNWarp
       local warpActive = states.KillAura or states.DNWarp
       if warpActive and not isBusy then
           startWarpPhysicsConnections()
           task.wait(SHADOW_UPDATE_INTERVAL)
       else
           stopWarpPhysicsConnections()
           task.wait(0.5)
       end
       local myCharacterNow = LocalPlayer.Character
       local myRootNow = myCharacterNow and myCharacterNow:FindFirstChild("HumanoidRootPart")

       -- ฐานล่องหนกันตก: ติดตามตำแหน่งผู้เล่นตลอดช่วง WARP
       -- ทำงานแม้ Shadow Hunter กำลังพัก/ติด busy เพื่อไม่ให้ฐานค้างอยู่ตำแหน่งเก่า
       if warpActive and myRootNow then
           placePlatformUnder(myRootNow.Position)
       end

       -- ตัวละครเกิดใหม่: ลืมจุดยืนเดิมและพื้นเก่า
       if warpOwner and warpOwner ~= myCharacterNow then
           warpHome, warpOwner, randomWarpTarget = nil, nil, nil
           destroyPlatform()
           warpWasOn = false
       end
       -- เปิด WARP: จดจุดยืนและสร้างพื้นกันตก
       if warpActive and not warpWasOn and myRootNow then
           warpHome = myRootNow.CFrame
           warpOwner = myCharacterNow
           warpRestUntil = 0
           placePlatformUnder(myRootNow.Position)
           warpWasOn = true
       end
       -- ปิด WARP: กลับจุดยืน แต่คงฐานล่องหนไว้รองรับการกด WARP รอบถัดไป
       if warpWasOn and not warpActive then
           if _G.TAYJAY_WARP_STAY then
               _G.TAYJAY_WARP_STAY = false
           else
               goHome(myRootNow)
           end
           -- วางฐานใต้ตำแหน่งสุดท้ายหลังกลับบ้าน/เลือกให้อยู่ที่เป้าหมาย
           if myRootNow then
               placePlatformUnder(myRootNow.Position)
           end
           -- เก็บ warpOwner ไว้ตรวจจับการเกิดใหม่ แล้วค่อยลบฐานเมื่อเปลี่ยนตัวละคร
           warpHome, randomWarpTarget = nil, nil
           warpWasOn = false
       end

       if not shadowEnabled then
           stopShadowHunterVisuals()
       elseif isBusy then
           if shadowHiddenCharacter then
               setInvisibility(shadowHiddenCharacter, false)
               shadowHiddenCharacter = nil
           end
           _G.TAYJAY_FOLLOW = nil; targetTitle.Text = "⏸ Shadow Hunter: paused"
       else
           if not states.KillAura then
               randomWarpTarget = nil
               if type(TargetService) == "table" and TargetService.Source == "warp" then
                   TargetService:Unlock("warp_off")
               end
           end
           local targetPlayer
           if states.KillAura then
               -- WARP: เป้าหมาย = คนที่ใกล้ "จุดยืน" ที่สุดทั้งแมพ
               local rc = randomWarpTarget and randomWarpTarget.Character
               local rh = rc and rc:FindFirstChildOfClass("Humanoid")
               local alive = randomWarpTarget and randomWarpTarget.Parent == Players and rh and rh.Health > 0 and not isSkipped(randomWarpTarget)
               if alive and randomWarpTarget.Character then local r = randomWarpTarget.Character:FindFirstChild("HumanoidRootPart"); if r then warpLastPos = r.Position end end
               if randomWarpTarget and not alive then
                   -- เป้าหมายตาย/ออก: สุ่มคนที่อยู่ใกล้จุดสุดท้ายของเป้าเดิม ต่อเนื่องจนกว่าจะกดยกเลิก
                   local origin = warpLastPos or (myRootNow and myRootNow.Position)
                   randomWarpTarget = origin and pickNearChain(origin, WARP_CHAIN_COUNT) or nil
                   warpLastPos = nil
               end
               if states.KillAura and not randomWarpTarget and warpHome and os.clock() >= warpRestUntil then
                   randomWarpTarget = findNearestFromHome(WARP_SEARCH_RANGE, warpHome.Position)
               end
               targetPlayer = randomWarpTarget
               if type(TargetService) == "table" and TargetService.Source ~= "deathnote"
                   and (TargetService.Player ~= randomWarpTarget or TargetService.Source ~= "warp") then
                   TargetService:SetTransient(randomWarpTarget, "warp")
               end
               if not targetPlayer then goHome(myRootNow) end
           elseif states.DNWarp then
               -- ปุ่ม "⇢ WARP ไป": ย้ายไปหาเป้าหมายครั้งเดียว แล้วอยู่ตรงนั้น (ไม่กลับจุดยืน)
               if _G.TAYJAY_STAY_REQUEST then
                   _G.TAYJAY_STAY_REQUEST = false
                   local stayTarget = selectedDeathNoteTarget
                   local stayRoot = stayTarget and stayTarget.Character and stayTarget.Character:FindFirstChild("HumanoidRootPart")
                   if stayTarget and stayTarget.Parent == Players and stayRoot and myRootNow then
                       local dest = stayRoot.CFrame * SHADOW_FOLLOW_OFFSET
                       placePlatformUnder(dest.Position)
                       myRootNow.CFrame = dest
                       _G.TAYJAY_WARP_STAY = true; _G.TAYJAY_FOLLOW = nil
                       selectedDeathNoteTarget = nil
                       if type(TargetService) == "table" and TargetService.Source == "deathnote" then
                           TargetService:Unlock("deathnote_warp_stay")
                       end
                       syncButtonState("DNWarp", false)
                   end
               end
               -- เลือกจากรายชื่อ: ตามคนที่เลือกไว้ (ไม่สุ่ม ไม่จำกัดระยะ)
               local dnChar = selectedDeathNoteTarget and selectedDeathNoteTarget.Character
               local dnHum = dnChar and dnChar:FindFirstChildOfClass("Humanoid")
               local dnGone = selectedDeathNoteTarget and (
                   selectedDeathNoteTarget.Parent ~= Players
                   or not dnChar
                   or not dnHum
                   or dnHum.Health <= 0
               )
                if dnGone then
                    -- เป้าหมายตาย/ออก: หยุดโจมตี ปลดล็อก แล้วกลับจุดยืน
                    goHome(myRootNow)
                    selectedDeathNoteTarget = nil
                    lockedDeathNoteTarget = nil
                    isDeathNoteTargetLocked = false
                    shadowTargetReleased = true
                    if type(TargetService) == "table" and TargetService.Source == "deathnote" then
                        TargetService:Unlock("deathnote_target_gone")
                    end
                    syncButtonState("DNWarp", false)
               else
                   targetPlayer = selectedDeathNoteTarget
               end
           end
           if isDeathNoteTargetLocked and (not lockedDeathNoteTarget or lockedDeathNoteTarget.Parent ~= Players) then
               lockedDeathNoteTarget = nil
               isDeathNoteTargetLocked = false
               shadowTargetReleased = true
               updateTargetLockVisual()
               if states.AutoWarp then syncButtonState("AutoWarp", false) end
               targetPlayer = nil
           end
           local targetCharacter = targetPlayer and targetPlayer.Character
           local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
           local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
           local myCharacter = LocalPlayer.Character
           local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
           local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")

           if targetPlayer and targetPlayer ~= LocalPlayer and targetRoot and targetHumanoid and targetHumanoid.Health > 0 and myRoot and myHumanoid and myHumanoid.Health > 0 then
               if shadowHiddenCharacter ~= myCharacter then
                   if shadowHiddenCharacter then setInvisibility(shadowHiddenCharacter, false) end
                   setInvisibility(myCharacter, true)
                   shadowHiddenCharacter = myCharacter
               end

               -- Initial approach / respawn retarget; never moves above or attaches to the target's head.
               if lastShadowTarget ~= targetPlayer or lastShadowCharacter ~= targetCharacter then
                   myRoot.Anchored = false
                   myHumanoid.Sit = false
                   if warpActive then placePlatformUnder((targetRoot.CFrame * SHADOW_FOLLOW_OFFSET).Position) end; myRoot.CFrame = targetRoot.CFrame * SHADOW_FOLLOW_OFFSET; _G.TAYJAY_WARP_HOLD_UNTIL = os.clock() + (_G.TAYJAY_WARP_HOLD or 0)
                   lastShadowTarget = targetPlayer
                   lastShadowCharacter = targetCharacter
               else
                   -- Follow at a modest update rate to avoid writing CFrame every rendered frame.
                   myRoot.Anchored = false
                   myHumanoid.Sit = false
                   if warpActive then placePlatformUnder((targetRoot.CFrame * SHADOW_FOLLOW_OFFSET).Position) end
               end

               if warpActive and myRoot then placePlatformUnder(myRoot.Position) end
               _G.TAYJAY_FOLLOW = {player = targetPlayer}
               targetTitle.Text = (states.KillAura and "🕶 WARP: " or "🕶 DN: ") .. targetPlayer.Name
               local hp = math.max(0, math.floor(targetHumanoid.Health))
               local maxHp = math.max(1, math.floor(targetHumanoid.MaxHealth))
                local followStatus = states.DNWarp
                    and (isDeathNoteTargetLocked and (AttackRemote and "LOCKED + WALK2 ATTACK" or "LOCKED • NO ATTACK REMOTE") or "FOLLOW ONLY")
                    or (AttackRemote and "FOLLOW + ATTACK" or "FOLLOW • NO ATTACK REMOTE")
                targetHpLabel.Text = hp .. " / " .. maxHp .. " HP  •  " .. followStatus
                targetBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
                -- Death Note lock calls the same walk2AttackTarget() path as WALK2; KillAura remains separate.
               if states.KillAura and AttackRemote then tryAttackTarget(targetCharacter) end
           else
               if shadowHiddenCharacter then
                   setInvisibility(shadowHiddenCharacter, false)
                   shadowHiddenCharacter = nil
               end
               lastShadowTarget = nil
               lastShadowCharacter = nil
               if isDeathNoteTargetLocked and targetPlayer then
                   lockedDeathNoteTarget = nil
                   isDeathNoteTargetLocked = false
                   shadowTargetReleased = true
                   updateTargetLockVisual()
                   if states.AutoWarp then syncButtonState("AutoWarp", false) end
                   targetTitle.Text = "⚠ Locked target unavailable • stopped"
               else
                   if states.KillAura then
                       targetTitle.Text = os.clock() < warpRestUntil and "🕶 WARP: กลับจุดยืน • รอเป้าหมายใหม่" or ("🕶 WARP: ไม่พบผู้เล่นในแมพ")
                   else
                       targetTitle.Text = targetPlayer and "⚠ Target unavailable" or "☠ Select target in Death Note"
                   end
               end
               targetHpLabel.Text = states.KillAura and "Searching the whole map..." or "Choose a living player in Death Note, then enable DN WARP"
               targetBarFill.Size = UDim2.new(0, 0, 1, 0)
           end
       end
   end
   -- Loop exit cleanup (also safe if STOP ALL already destroyed these resources).
   stopShadowHunterVisuals()
   _G.TAYJAY_FOLLOW = nil
   destroyPlatform()
end)
if warpRuntimeOwner then
   warpRuntimeOwner:OwnTask(shadowThread)
end

