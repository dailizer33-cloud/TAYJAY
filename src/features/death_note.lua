-- =========================================================
-- 📖 DEATH NOTE ( Player List )
-- =========================================================
local AttackRemote = nil
pcall(function()
   for _, candidateName in ipairs({"AttackRemote", "Punch", "Attack", "CombatRemote"}) do
       local candidate = ReplicatedStorage:FindFirstChild(candidateName, true)
       if candidate and (candidate:IsA("RemoteEvent") or candidate:IsA("RemoteFunction")) then
           AttackRemote = candidate
           break
       end
   end
end)
local ATTACK_COOLDOWN = 1 / 15
local lastAttackAt = 0
local attackCallBusy = false
local function tryAttackTarget(targetCharacter)
   if not AttackRemote or not targetCharacter or attackCallBusy then return false end
   local now = os.clock()
   if now - lastAttackAt < ATTACK_COOLDOWN then return false end
   lastAttackAt = now
   attackCallBusy = true
   local ok = pcall(function()
       if AttackRemote:IsA("RemoteEvent") then
           AttackRemote:FireServer(targetCharacter)
       elseif AttackRemote:IsA("RemoteFunction") then
           AttackRemote:InvokeServer(targetCharacter)
       end
   end)
   attackCallBusy = false
   return ok
end

local function walk2AttackTarget(targetCharacter)
   if not targetCharacter or not targetCharacter.Parent then return false end
   local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
   if not targetHumanoid or targetHumanoid.Health <= 0 then return false end
   return tryAttackTarget(targetCharacter)
end

local deathNoteGroup = Instance.new("Frame", screenGui)
deathNoteGroup.Name = "DeathNoteGroup"; deathNoteGroup.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH); deathNoteGroup.Position = UI_LAYOUT.PlayerList
deathNoteGroup.BackgroundTransparency = 1; deathNoteGroup.Visible = false; deathNoteGroup.Active = true
local deathNoteMain = Instance.new("Frame", deathNoteGroup)
deathNoteMain.Name = "DeathNoteMain"
deathNoteMain.Size = UDim2.new(1, 0, 1, 0); deathNoteMain.Position = UDim2.new(0, 0, 0, 0)
deathNoteMain.BackgroundColor3 = GREEN.dark; deathNoteMain.Visible = false
Instance.new("UICorner", deathNoteMain).CornerRadius = UDim.new(0, 12)
local dnStroke = Instance.new("UIStroke", deathNoteMain); dnStroke.Name = "TayJayWindowAccent"; dnStroke.Color = UI_LAYOUT.Accent.Players; dnStroke.Thickness = 2.5

local groupDragging, groupDragInput, groupDragStart, groupStartPos = false, nil, nil, nil
local isWindowLocked = false
local function beginGroupDrag(panel)
   panel.InputBegan:Connect(function(input)
       if not isWindowLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
           groupDragging = true; groupDragStart = input.Position; groupStartPos = deathNoteGroup.Position
           input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then groupDragging = false end end)
       end
   end)
   panel.InputChanged:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then groupDragInput = input end
   end)
end
beginGroupDrag(deathNoteMain)
trackConnection(UserInputService.InputChanged:Connect(function(input)
   if input == groupDragInput and groupDragging and not isWindowLocked then
       local delta = input.Position - groupDragStart
       deathNoteGroup.Position = UDim2.new(
           groupStartPos.X.Scale, groupStartPos.X.Offset + delta.X,
           groupStartPos.Y.Scale, groupStartPos.Y.Offset + delta.Y
       )
   end
end))

local dnTitle = Instance.new("TextLabel", deathNoteMain)
dnTitle.Size = UDim2.new(1, -82, 0, 32); dnTitle.Position = UDim2.new(0, 10, 0, 0); dnTitle.BackgroundTransparency = 1; dnTitle.Text = "👥 ผู้เล่นทั้งหมด"; dnTitle.TextColor3 = WHITE_TEXT; dnTitle.Font = Enum.Font.GothamBold; dnTitle.TextSize = 14; dnTitle.TextXAlignment = Enum.TextXAlignment.Left; dnTitle.TextStrokeColor3 = TEXT_OUTLINE; dnTitle.TextStrokeTransparency = 0.48

local dnLock = Instance.new("TextButton", deathNoteMain)
dnLock.Name = "WindowLockButton"; dnLock.Size = UDim2.new(0, 25, 0, 25); dnLock.Position = UDim2.new(1, -57, 0, 5); dnLock.BackgroundColor3 = Color3.fromRGB(76, 158, 48); dnLock.Text = "🔓"; dnLock.TextColor3 = WHITE_TEXT; dnLock.Font = Enum.Font.GothamBold; dnLock.TextSize = 15; dnLock.AutoButtonColor = true; Instance.new("UICorner", dnLock).CornerRadius = UDim.new(0, 7)
dnLock.Activated:Connect(function()
   isWindowLocked = not isWindowLocked
   groupDragging = false
   dnLock.Text = isWindowLocked and "🔒" or "🔓"
   dnLock.BackgroundColor3 = isWindowLocked and Color3.fromRGB(205, 48, 42) or Color3.fromRGB(76, 158, 48)
end)

local dnClose = Instance.new("TextButton", deathNoteMain)
dnClose.Size = UDim2.new(0, 22, 0, 22); dnClose.Position = UDim2.new(1, -28, 0, 5); dnClose.BackgroundColor3 = Color3.fromRGB(215, 45, 40); dnClose.Text = "✕"; dnClose.TextColor3 = WHITE_TEXT; dnClose.Font = Enum.Font.GothamBold; dnClose.TextSize = 13; Instance.new("UICorner", dnClose).CornerRadius = UDim.new(1, 0)
dnClose.Activated:Connect(function() deathNoteGroup.Visible = false; syncButtonState("DeathNote", false) end)

local dnScroll = Instance.new("ScrollingFrame", deathNoteMain)
dnScroll.Size = UDim2.new(1, -16, 1, -42); dnScroll.Position = UDim2.new(0, 8, 0, 36); dnScroll.BackgroundTransparency = 1; dnScroll.ScrollBarThickness = 5
dnScroll.ScrollingDirection = Enum.ScrollingDirection.Y; dnScroll.ClipsDescendants = true
dnScroll.CanvasSize = UDim2.new(0, 0, 0, 0); dnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- ความสูงตามรายชื่อจริงเสมอ
local dnListLayout = Instance.new("UIListLayout", dnScroll); dnListLayout.SortOrder = Enum.SortOrder.LayoutOrder; dnListLayout.Padding = UDim.new(0, 5)
local dnPadding = Instance.new("UIPadding", dnScroll)
dnPadding.PaddingTop = UDim.new(0, 2); dnPadding.PaddingBottom = UDim.new(0, 14) -- เว้นช่องท้ายให้แถวสุดท้ายเลื่อนพ้นขอบ


local originalTransparencies = {}
local selectedDeathNoteTarget = nil
local lockedDeathNoteTarget = nil
local isDeathNoteTargetLocked = false
local shadowTargetReleased = false

-- Death Note attack lock: reuse the same target attack routine as WALK2.
-- The shared 0.25s cooldown in tryAttackTarget remains the rate limiter.
trackConnection(RunService.Heartbeat:Connect(function()
    if not states.DNWarp or not isDeathNoteTargetLocked then return end
    local lockedPlayer = lockedDeathNoteTarget
    if not lockedPlayer or lockedPlayer.Parent ~= Players then return end

    local targetCharacter = lockedPlayer.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    -- Match WALK2's 25-stud range, without switching to another player.
    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and localRoot
        and (localRoot.Position - targetRoot.Position).Magnitude <= 25 then
        walk2AttackTarget(targetCharacter)
    end
end))

-- Client-side visual hide only; this does not make the character server-invisible.
local function setInvisibility(char, invisible)
   if not char then return end
   for _, obj in ipairs(char:GetDescendants()) do
       if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
           if invisible then
               if originalTransparencies[obj] == nil then
                   originalTransparencies[obj] = {kind = "part", value = obj.LocalTransparencyModifier}
               end
               obj.LocalTransparencyModifier = 1
           else
               local saved = originalTransparencies[obj]
               if saved and saved.kind == "part" then
                   pcall(function() obj.LocalTransparencyModifier = saved.value end)
                   originalTransparencies[obj] = nil
               end
           end
       elseif obj:IsA("Decal") or obj:IsA("Texture") then
           if invisible then
               if originalTransparencies[obj] == nil then
                   originalTransparencies[obj] = {kind = "decal", value = obj.Transparency}
               end
               obj.Transparency = 1
           else
               local saved = originalTransparencies[obj]
               if saved and saved.kind == "decal" then
                   pcall(function() obj.Transparency = saved.value end)
                   originalTransparencies[obj] = nil
               end
           end
       end
   end
end

local function setupCardContent(playerObj, hpBarFill, hpText)
   local function updateHealth()
       pcall(function()
           if playerObj and playerObj.Character then
               local hum = playerObj.Character:FindFirstChildOfClass("Humanoid")
               if hum then
                   local hp = math.max(0, math.floor(hum.Health)); local maxHp = math.max(1, math.floor(hum.MaxHealth))
                   hpBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
                   hpText.Text = hp .. "/" .. maxHp
               else
                   hpBarFill.Size = UDim2.new(0, 0, 1, 0); hpText.Text = "Dead"
               end
           else hpBarFill.Size = UDim2.new(0, 0, 1, 0); hpText.Text = "Offline" end
       end)
   end
   pcall(function()
       if playerObj.Character then
           local hum = playerObj.Character:FindFirstChildOfClass("Humanoid")
           if hum then hum.HealthChanged:Connect(updateHealth) end
       end
       playerObj.CharacterAdded:Connect(function(newChar)
           local hum = newChar:WaitForChild("Humanoid", 5)
           if hum then hum.HealthChanged:Connect(updateHealth); updateHealth() end
       end)
   end)
   updateHealth()
end

local targetTitle, targetHpLabel, targetBarFill

local function createPlayerCard(playerObj, parentScroll, isKiller)
   local card = Instance.new("TextButton", parentScroll)
   card.Name = playerObj.Name; card.Size = UDim2.new(1, 0, 0, isKiller and 50 or 46); card.BackgroundColor3 = isKiller and Color3.fromRGB(105, 40, 33) or Color3.fromRGB(30, 52, 78); card.Text = ""
   Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
   local cardStroke = Instance.new("UIStroke", card); cardStroke.Color = isKiller and Color3.fromRGB(255, 105, 75) or UI_LAYOUT.Accent.Players; cardStroke.Thickness = 1.2
   if selectedDeathNoteTarget and selectedDeathNoteTarget.Name == playerObj.Name then
       card.BackgroundColor3 = Color3.fromRGB(190, 35, 35); cardStroke.Color = Color3.fromRGB(255, 110, 110)
   end
   
   local avatar = Instance.new("ImageLabel", card)
   avatar.Size = UDim2.new(0, 32, 0, 32); avatar.Position = UDim2.new(0, 7, 0, 7); avatar.BackgroundTransparency = 1
   pcall(function() avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. playerObj.UserId .. "&w=150&h=150" end)
   Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

   local nameLabel = Instance.new("TextLabel", card)
   nameLabel.Size = UDim2.new(1, -99, 0, 21); nameLabel.Position = UDim2.new(0, 45, 0, 2); nameLabel.BackgroundTransparency = 1; nameLabel.Text = playerObj.DisplayName
   nameLabel.TextColor3 = WHITE_TEXT; nameLabel.TextSize = 13
   nameLabel.TextStrokeColor3 = TEXT_OUTLINE; nameLabel.TextStrokeTransparency = 0.48; nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextXAlignment = Enum.TextXAlignment.Left

   local hpBarBg = Instance.new("Frame", card)
   hpBarBg.Size = UDim2.new(1, -141, 0, 8); hpBarBg.Position = UDim2.new(0, 45, 0, 28); hpBarBg.BackgroundColor3 = Color3.fromRGB(55, 82, 51); hpBarBg.BorderSizePixel = 0; Instance.new("UICorner", hpBarBg).CornerRadius = UDim.new(1, 0)
   
   local hpBarFill = Instance.new("Frame", hpBarBg)
   hpBarFill.Size = UDim2.new(1, 0, 1, 0); hpBarFill.BackgroundColor3 = Color3.fromRGB(104, 211, 57); hpBarFill.BorderSizePixel = 0; Instance.new("UICorner", hpBarFill).CornerRadius = UDim.new(1, 0)

   local hpText = Instance.new("TextLabel", card)
   hpText.Size = UDim2.new(0, 36, 0, 14); hpText.Position = UDim2.new(1, -92, 0, 26); hpText.BackgroundTransparency = 1; hpText.Text = "100/100"
   hpText.TextColor3 = WHITE_TEXT; hpText.TextSize = 10; hpText.Font = Enum.Font.GothamBold; hpText.TextXAlignment = Enum.TextXAlignment.Right

   setupCardContent(playerObj, hpBarFill, hpText)

   -- ปุ่ม "ข้าม": ผู้เล่นที่ตั้งข้ามจะไม่ถูก WARP เลือกเป็นเป้าหมาย
   local skipBtn = Instance.new("TextButton", card)
   skipBtn.Name = "WarpSkipBtn"; skipBtn.Size = UDim2.new(0, 46, 0, 20); skipBtn.Position = UDim2.new(1, -50, 0.5, -10)
   skipBtn.BorderSizePixel = 0; skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextSize = 10; skipBtn.TextColor3 = WHITE_TEXT
   Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)
   skipBtn.Visible = playerObj ~= LocalPlayer
   local function refreshSkip()
       local skipped = _G.TAYJAY_BL.has(playerObj.Name)
       skipBtn.Text = skipped and "✕ ข้าม" or "ข้าม"
       skipBtn.BackgroundColor3 = skipped and Color3.fromRGB(205, 48, 42) or Color3.fromRGB(76, 110, 70)
   end
   skipBtn.Activated:Connect(function()
       _G.TAYJAY_BL.set(playerObj.Name, not _G.TAYJAY_BL.has(playerObj.Name))
       refreshSkip()
   end)
   refreshSkip()

   card.Activated:Connect(function()
       if playerObj == LocalPlayer then
           pcall(function() if setclipboard then setclipboard(playerObj.Name) end end)
           nameLabel.Text = "✓ คัดลอกชื่อแล้ว"
           task.delay(1.2, function()
               if nameLabel and nameLabel.Parent then nameLabel.Text = playerObj.DisplayName end
           end)
           return
       end

       if _G.TAYJAY_BL.has(playerObj.Name) then
           targetTitle.Text = "🚫 อยู่ใน blacklist"
           return
       end
       if selectedDeathNoteTarget == playerObj then
           -- กดชื่อเดิมอีกครั้ง = ปลดล็อก หยุดโจมตี และหยุดติดตาม
           selectedDeathNoteTarget = nil
           if lockedDeathNoteTarget == playerObj then lockedDeathNoteTarget = nil end
           isDeathNoteTargetLocked = false
           shadowTargetReleased = true
           syncButtonState("DNWarp", false)
           targetTitle.Text = "🎯 Target: none"
           targetHpLabel.Text = "Target unlocked • Attack stopped"
           return
       end
       -- กดชื่อใหม่ = ล็อก Player ตัวนี้เป็นเป้าหมายเดียวของ Death Note + WALK2
       selectedDeathNoteTarget = playerObj
       lockedDeathNoteTarget = playerObj
       isDeathNoteTargetLocked = true
       shadowTargetReleased = false
       syncButtonState("DNWarp", true)
       -- เริ่มโจมตีทันทีหนึ่งครั้ง; Heartbeat จะใช้ WALK2 ซ้ำกับเป้าหมายเดิมในระยะ 25 studs
       if playerObj.Character then walk2AttackTarget(playerObj.Character) end
       pcall(function() if setclipboard then setclipboard(playerObj.Name) end end)
       nameLabel.Text = "✓ SELECTED"
       targetTitle.Text = "🎯 Target: " .. playerObj.Name
       local targetHumanoid = playerObj.Character and playerObj.Character:FindFirstChildOfClass("Humanoid")
       if targetHumanoid then
           local hp = math.max(0, math.floor(targetHumanoid.Health))
           local maxHp = math.max(1, math.floor(targetHumanoid.MaxHealth))
           targetHpLabel.Text = hp .. " / " .. maxHp .. " HP"
           targetBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
       end
       task.delay(1.2, function()
           if nameLabel and nameLabel.Parent then nameLabel.Text = playerObj.DisplayName end
       end)
   end)
end

local playerListRefreshQueued = false
local function updatePlayerList()
   if playerListRefreshQueued then return end
   playerListRefreshQueued = true
   task.defer(function()
       playerListRefreshQueued = false
       if not dnScroll or not dnScroll.Parent then return end
       pcall(function()
           for _, child in ipairs(dnScroll:GetChildren()) do
               if child:IsA("TextButton") then child:Destroy() end
           end
           local allPlayers = Players:GetPlayers()
           for _, player in ipairs(allPlayers) do
               createPlayerCard(player, dnScroll, false)
           end
           dnTitle.Text = "👥 ผู้เล่นทั้งหมด (" .. #allPlayers .. ")"
           task.defer(function()
               -- canvas ของรายชื่อคำนวณอัตโนมัติ (AutomaticCanvasSize) ไม่ต้องตั้งค่าเอง
           end)
       end)
   end)
end
trackConnection(Players.PlayerAdded:Connect(updatePlayerList))
trackConnection(Players.PlayerRemoving:Connect(function(player)
   if lockedDeathNoteTarget == player then
       lockedDeathNoteTarget = nil
       isDeathNoteTargetLocked = false
       shadowTargetReleased = true
       if states.AutoWarp then syncButtonState("AutoWarp", false) end
   end
   if selectedDeathNoteTarget == player then
       selectedDeathNoteTarget = nil
       syncButtonState("DNWarp", false)
       targetTitle.Text = "🎯 Target: unavailable"
       targetHpLabel.Text = "0 / 0 HP"
       targetBarFill.Size = UDim2.new(0, 0, 1, 0)
   end
   updatePlayerList()
end))
task.defer(updatePlayerList)

-- 💥 KILL AURA (WARP & WALK)
-- Forward declaration: player-WARP activation can cleanly stop the independent Monster Warp.
local stopMonsterWarp
local maxAttackDistance = 100

-- FIXED SYNTAX ERROR: String \n
local kaCircleBtn = Instance.new("TextButton", screenGui)
kaCircleBtn.Name = "KillAuraCircleBtn"; kaCircleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
kaCircleBtn.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize); kaCircleBtn.Position = UI_LAYOUT.WarpCenter
kaCircleBtn.BackgroundColor3 = GREEN.deep; kaCircleBtn.RichText = true
kaCircleBtn.Text = '<font size="32">🕶</font>\n<font size="18">WARP</font>'
kaCircleBtn.TextColor3 = WHITE_TEXT; kaCircleBtn.Font = Enum.Font.GothamBlack; kaCircleBtn.TextSize = 18; kaCircleBtn.Active = true
Instance.new("UICorner", kaCircleBtn).CornerRadius = UDim.new(1, 0)
local kaCircleStroke = Instance.new("UIStroke", kaCircleBtn); kaCircleStroke.Color = GREEN.neon; kaCircleStroke.Thickness = 2.5
makeDraggable(kaCircleBtn)

-- FIXED SYNTAX ERROR: String \n
local kaNormalBtn = Instance.new("TextButton", screenGui)
kaNormalBtn.Name = "KillAuraNormalBtn"; kaNormalBtn.AnchorPoint = Vector2.new(0.5, 0.5)
kaNormalBtn.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize); kaNormalBtn.Position = UI_LAYOUT.WalkCenter
kaNormalBtn.BackgroundColor3 = GREEN.deep; kaNormalBtn.RichText = true
kaNormalBtn.Text = '<font size="32">👹</font>\n<font size="18">WALK</font>'
kaNormalBtn.TextColor3 = WHITE_TEXT; kaNormalBtn.Font = Enum.Font.GothamBlack; kaNormalBtn.TextSize = 18; kaNormalBtn.Active = true
Instance.new("UICorner", kaNormalBtn).CornerRadius = UDim.new(1, 0)
local kaNormalStroke = Instance.new("UIStroke", kaNormalBtn); kaNormalStroke.Color = GREEN.neon; kaNormalStroke.Thickness = 2.5
makeDraggable(kaNormalBtn)

local targetGui = Instance.new("Frame", screenGui)
targetGui.Name = "TayJayTargetPanel"; targetGui.Size = UDim2.new(0, UI_LAYOUT.PanelW, 0, 116); targetGui.Position = UI_LAYOUT.TargetPanel
targetGui.BackgroundColor3 = GREEN.dark; targetGui.Visible = false
Instance.new("UICorner", targetGui).CornerRadius = UDim.new(0, 12)
local tgStroke = Instance.new("UIStroke", targetGui); tgStroke.Name = "TayJayWindowAccent"; tgStroke.Color = UI_LAYOUT.Accent.Target; tgStroke.Thickness = 2.5
makeDraggable(targetGui)

targetTitle = Instance.new("TextLabel", targetGui)
targetTitle.Size = UDim2.new(1, -32, 0, 22); targetTitle.Position = UDim2.new(0, 10, 0, 4); targetTitle.BackgroundTransparency = 1; targetTitle.Text = "⚔️ เป้าหมาย: ไม่พบเป้าหมาย"; targetTitle.TextColor3 = WHITE_TEXT; targetTitle.Font = Enum.Font.GothamBold; targetTitle.TextSize = 12; targetTitle.TextXAlignment = Enum.TextXAlignment.Left

local targetBarBG = Instance.new("Frame", targetGui)
targetBarBG.Size = UDim2.new(1, -20, 0, 10); targetBarBG.Position = UDim2.new(0, 10, 0, 30); targetBarBG.BackgroundColor3 = Color3.fromRGB(255, 249, 210); targetBarBG.BorderSizePixel = 0; Instance.new("UICorner", targetBarBG).CornerRadius = UDim.new(0, 6)
targetBarFill = Instance.new("Frame", targetBarBG)
targetBarFill.Size = UDim2.new(0, 0, 1, 0); targetBarFill.BackgroundColor3 = Color3.fromRGB(104, 211, 57); targetBarFill.BorderSizePixel = 0; Instance.new("UICorner", targetBarFill).CornerRadius = UDim.new(0, 6)

targetHpLabel = Instance.new("TextLabel", targetGui)
targetHpLabel.Size = UDim2.new(1, -20, 0, 16); targetHpLabel.Position = UDim2.new(0, 10, 0, 44); targetHpLabel.BackgroundTransparency = 1; targetHpLabel.Text = "0 / 0 HP"; targetHpLabel.TextColor3 = WHITE_TEXT; targetHpLabel.Font = Enum.Font.Gotham; targetHpLabel.TextSize = 11

-- Target Lock controls. The lock is bound to the exact Player selected in Death Note.
local targetLockButton = Instance.new("TextButton", targetGui)
targetLockButton.Name = "TargetLockButton"
targetLockButton.Size = UDim2.new(0.5, -14, 0, 27)
targetLockButton.Position = UDim2.new(0, 9, 0, 76)
targetLockButton.BackgroundColor3 = Color3.fromRGB(15, 128, 194)
targetLockButton.Text = "🎯 TARGET LOCK"
targetLockButton.TextColor3 = WHITE_TEXT
targetLockButton.Font = Enum.Font.GothamBold
targetLockButton.TextSize = 11
targetLockButton.TextStrokeColor3 = TEXT_OUTLINE
targetLockButton.TextStrokeTransparency = 0.45
Instance.new("UICorner", targetLockButton).CornerRadius = UDim.new(0, 7)
local targetLockStroke = Instance.new("UIStroke", targetLockButton)
targetLockStroke.Color = Color3.fromRGB(95, 205, 255)
targetLockStroke.Thickness = 1.4

local targetUnlockButton = Instance.new("TextButton", targetGui)
targetUnlockButton.Name = "UntargetLockButton"
targetUnlockButton.Size = UDim2.new(0.5, -14, 0, 27)
targetUnlockButton.Position = UDim2.new(0.5, 5, 0, 76)
targetLockButton.Visible = true
targetUnlockButton.Size = UDim2.new(0.5, -14, 0, 27); targetUnlockButton.Position = UDim2.new(0.5, 5, 0, 76)
targetUnlockButton.BackgroundColor3 = Color3.fromRGB(170, 65, 42)
targetUnlockButton.Text = "🔓 UNTARGET"
targetUnlockButton.TextColor3 = WHITE_TEXT
targetUnlockButton.Font = Enum.Font.GothamBold
targetUnlockButton.TextSize = 11
targetUnlockButton.TextStrokeColor3 = TEXT_OUTLINE
targetUnlockButton.TextStrokeTransparency = 0.45
Instance.new("UICorner", targetUnlockButton).CornerRadius = UDim.new(0, 7)
local targetUnlockStroke = Instance.new("UIStroke", targetUnlockButton)
targetUnlockStroke.Color = Color3.fromRGB(255, 145, 100)
targetUnlockStroke.Thickness = 1.4

local function updateTargetLockVisual()
    local locked = isDeathNoteTargetLocked and lockedDeathNoteTarget ~= nil
    targetLockButton.Text = "⇢ WARP ไป"
    targetLockButton.BackgroundColor3 = Color3.fromRGB(20, 150, 175)
    targetLockStroke.Color = UI_LAYOUT.Accent.Stay
end

targetLockButton.Activated:Connect(function()
    local candidate = selectedDeathNoteTarget
    if not candidate or candidate.Parent ~= Players then
        targetTitle.Text = "⚠ เลือกชื่อในรายการก่อน"
        return
    end
    -- ให้ลูปวาร์ปไปหาเป้าหมายครั้งเดียว แล้วอยู่ตรงนั้น (ไม่กลับจุดยืน)
    _G.TAYJAY_STAY_REQUEST = true
    targetTitle.Text = "⇢ ไปหา " .. candidate.Name .. " (ไม่กลับ)"
end)

targetUnlockButton.Activated:Connect(function()
    selectedDeathNoteTarget = nil
    syncButtonState("DNWarp", false)
    lockedDeathNoteTarget = nil
    isDeathNoteTargetLocked = false
    shadowTargetReleased = true
    updateTargetLockVisual()
    if states.AutoWarp then syncButtonState("AutoWarp", false) end
    targetTitle.Text = "🔓 Target unlocked"
    targetHpLabel.Text = "Tracking stopped • Select a new target"
end)

updateTargetLockVisual()

task.spawn(function()
   while screenGui.Parent and task.wait(0.03) do
       local pulse = _G.TAYJAY_UI.effects and (math.sin(tick() * 15) + 1) / 2 or 0
       if states.KillAura then
           kaCircleStroke.Thickness = 3 + (pulse * 3)
           kaCircleStroke.Color = Color3.fromRGB(255, math.floor(pulse * 100), math.floor(pulse * 100))
       else
           kaCircleStroke.Thickness = 2.5
           kaCircleStroke.Color = Color3.fromRGB(255, 190, 45)
       end
       if states.NormalKillAura then
           kaNormalStroke.Thickness = 3 + (pulse * 3)
           kaNormalStroke.Color = Color3.fromRGB(255, math.floor(pulse * 100), math.floor(pulse * 100))
       else
           kaNormalStroke.Thickness = 2.5
           kaNormalStroke.Color = Color3.fromRGB(104, 211, 57)
       end
   end
end)

local function updateKaBtnDisplay()
   local warpOn, walkOn = states.KillAura, states.NormalKillAura
   kaCircleBtn.BackgroundColor3 = warpOn and GREEN.on or GREEN.off
   kaNormalBtn.BackgroundColor3 = walkOn and GREEN.on or GREEN.off
   kaCircleBtn.Text = '<font size="26">🕶</font>\n<font size="15">WARP</font>\n<font size="11">' .. (warpOn and "ON" or "OFF") .. '</font>'
   kaNormalBtn.Text = '<font size="26">👹</font>\n<font size="15">WALK</font>\n<font size="11">' .. (walkOn and "ON" or "OFF") .. '</font>'
   if not (warpOn or states.DNWarp) then _G.TAYJAY_FOLLOW = nil end
   targetGui.Visible = (states.KillAura or states.AutoWarp or states.NormalKillAura or states.DNWarp)
end
updateKaBtnDisplay()
