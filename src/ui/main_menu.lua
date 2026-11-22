-- =========================================================
-- 🔘 MAIN MENU UI
-- =========================================================
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Name = "TayJayMainToggle"
toggleBtn.Size = UDim2.fromOffset(UI_LAYOUT.ToggleSize, UI_LAYOUT.ToggleSize); toggleBtn.Position = UDim2.new(0, 12, 0.18, 0)
toggleBtn.BackgroundColor3 = GREEN.mid; toggleBtn.Text = ""; toggleBtn.AutoButtonColor = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
do -- [TAYJAY LOCAL-LIMIT FIX 6/8]
local toggleRing = Instance.new("UIStroke", toggleBtn)
toggleRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; toggleRing.Color = Color3.fromRGB(255, 255, 255); toggleRing.Thickness = 3.5

-- โลโก้ ⚡ บนแผ่นกลมสีเข้ม: ตัดกับวงส้มชัดเจน และใหญ่กว่าเดิม (เดิมโดนระบบย่อเหลือ 19px)
local toggleDisc = Instance.new("Frame", toggleBtn)
toggleDisc.Name = "TayJayToggleLogoDisc"
toggleDisc.AnchorPoint = Vector2.new(0.5, 0.5); toggleDisc.Position = UDim2.fromScale(0.5, 0.5); toggleDisc.Size = UDim2.fromScale(0.80, 0.80)
toggleDisc.BackgroundColor3 = GREEN.deep; toggleDisc.BorderSizePixel = 0
Instance.new("UICorner", toggleDisc).CornerRadius = UDim.new(1, 0)
local toggleDiscRing = Instance.new("UIStroke", toggleDisc)
toggleDiscRing.Color = Color3.fromRGB(255, 211, 58); toggleDiscRing.Thickness = 2
local toggleLogo = Instance.new("TextLabel", toggleDisc)
toggleLogo.Name = "TayJayToggleLogo"
toggleLogo.Size = UDim2.fromScale(1, 1); toggleLogo.BackgroundTransparency = 1
toggleLogo.Text = "⚡"; toggleLogo.Font = Enum.Font.GothamBlack; toggleLogo.TextSize = 40; toggleLogo.TextColor3 = Color3.fromRGB(255, 224, 70)

end -- [/TAYJAY LOCAL-LIMIT FIX 6/8]

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "TayJayMainMenu"
mainFrame.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH); mainFrame.Position = UI_LAYOUT.MainMenu; mainFrame.BackgroundColor3 = GREEN.dark; mainFrame.Visible = true; mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18); local mainMenuStroke = Instance.new("UIStroke", mainFrame); mainMenuStroke.Name = "TayJayWindowAccent"; mainMenuStroke.Color = UI_LAYOUT.Accent.Main; mainMenuStroke.Thickness = 2.5
makeDraggable(mainFrame)
trackConnection(toggleBtn.Activated:Connect(function() mainFrame.Visible = not mainFrame.Visible end))
-- Compact tablet layout: the TAYJAY menu uses one column; Death Note remains beside it.
do -- [TAYJAY LOCAL-LIMIT FIX 7/8]
local function applyCompactTabletLayout()
   local camera = workspace.CurrentCamera
   if not camera then return end
   local viewport = camera.ViewportSize
   local narrow = viewport.X < 900
   if narrow then
      mainFrame.Size = UDim2.fromOffset(286, 370)
       mainFrame.Position = UDim2.new(0, 8, 0, 104)
       deathNoteGroup.Size = UDim2.fromOffset(224, 300)
       deathNoteGroup.Position = UDim2.new(0, 360, 0, 104)
   else
      mainFrame.Size = UDim2.fromOffset(286, 370)
      mainFrame.Position = UI_LAYOUT.MainMenu
      deathNoteGroup.Size = UDim2.fromOffset(224, 300)
      deathNoteGroup.Position = UI_LAYOUT.PlayerList
   end
end
applyCompactTabletLayout()
if workspace.CurrentCamera then trackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyCompactTabletLayout)) end

local title = Instance.new("TextLabel", mainFrame)
title.Name = "TayJayBrandTitle"; title.Size = UDim2.new(1, 0, 0, 54); title.Position = UDim2.new(0, 0, 0, 0); title.BackgroundTransparency = 1; title.Text = "TAYJAY"; title.TextColor3 = GREEN.ink; title.TextSize = 48; title.Font = Enum.Font.FredokaOne
-- ขอบเข้มหนาขึ้น (เดิมขอบขาวบนสีพาสเทล ทำให้ตัวอักษรกลืนกัน) เพื่อให้โลโก้อ่านชัด
local titleStroke = Instance.new("UIStroke", title)
titleStroke.Color = Color3.fromRGB(8, 12, 28); titleStroke.Thickness = 2.6; titleStroke.Transparency = 0; title.TextStrokeTransparency = 1
local candyRainbow = ColorSequence.new({
   ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 105, 180)),
   ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255, 190, 225)),
   ColorSequenceKeypoint.new(0.36, Color3.fromRGB(160, 235, 255)),
   ColorSequenceKeypoint.new(0.54, Color3.fromRGB(170, 255, 190)),
   ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 245, 150)),
   ColorSequenceKeypoint.new(0.88, Color3.fromRGB(255, 175, 115)),
   ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 105, 180)),
})
local function addCandyRainbow(target, duration, rotation)
   local gradient = Instance.new("UIGradient")
   gradient.Name = "TayJayCandyRainbow"
   gradient.Color = candyRainbow
   gradient.Rotation = rotation or 0
   gradient.Offset = Vector2.new(-1, 0)
   gradient.Parent = target
   local tween = TweenService:Create(gradient,
       TweenInfo.new(duration or 4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
       {Offset = Vector2.new(1, 0)})
   tween:Play()
   return gradient, tween
end
if _G.TAYJAY_UI.effects then addCandyRainbow(title, 3.2, 0) end

end -- [/TAYJAY LOCAL-LIMIT FIX 7/8]

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -14, 1, -62); scroll.Position = UDim2.new(0, 7, 0, 56); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = GREEN.neon
local list = Instance.new("UIGridLayout", scroll)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.CellSize = UDim2.new(1, -4, 0, 34)
list.CellPadding = UDim2.fromOffset(0, 5)
list.FillDirectionMaxCells = 1

do -- [TAYJAY LOCAL-LIMIT FIX 8/8]
local function createBtn(order, text, key)
   local btn = Instance.new("TextButton", scroll)
   btn.Size = UDim2.new(1, -4, 0, 34); btn.BackgroundColor3 = GREEN.off; btn.Text = text .. " : OFF"; btn.TextColor3 = WHITE_TEXT; btn.Font = Enum.Font.GothamBold; btn.LayoutOrder = order
   btn.TextScaled = true; btn.TextWrapped = false
   local btnSize = Instance.new("UITextSizeConstraint", btn); btnSize.MaxTextSize = 14; btnSize.MinTextSize = 9
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11); local btnEdge = Instance.new("UIStroke", btn); btnEdge.Color = GREEN.warning; btnEdge.Thickness = 1.2

   local function updateVisual(isOn)
       btn.BackgroundColor3 = isOn and GREEN.on or GREEN.off
       btn.TextColor3 = WHITE_TEXT
       btn.TextStrokeTransparency = 0.48
       btnEdge.Color = isOn and GREEN.neon or Color3.fromRGB(255, 115, 75)
       btn.Text = text .. (isOn and " : ON" or " : OFF")
   end

   registerUiSync(key, function(isOn) 
       updateVisual(isOn)
       if key == "Speed" then
           speedWidget.Visible = isOn
           local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
           if isOn then
               if hum and originalWalkSpeed == nil then originalWalkSpeed = hum.WalkSpeed end
           else
               if hum and originalWalkSpeed ~= nil then hum.WalkSpeed = originalWalkSpeed end
               originalWalkSpeed = nil
           end
       elseif key == "Fly" then FlyFrame.Visible = isOn; if not isOn and flyNowe then stopFlying(false) end
       elseif key == "DeathNote" then
           deathNoteGroup.Visible = isOn
           deathNoteMain.Visible = isOn
           if isOn then task.defer(updatePlayerList) end
       elseif key == "ServerSelector" then serverFrame.Visible = isOn; if isOn and #sfList:GetChildren() <= 2 then loadPublicServers() end
       end
   end)
   updateVisual(states[key])
   trackConnection(btn.Activated:Connect(function() syncButtonState(key, not states[key]) end))
end

createBtn(1, "1. 🚀 ความเร็ว (Speed)", "Speed")
createBtn(2, "2. 🛸 โหมดบิน (Fly)", "Fly")
createBtn(3, "3. 🌌 กระโดดไร้ขีดจำกัด (Inf Jump)", "InfJump")
createBtn(4, "4. 🔍 มองทะลุ (X-Ray)", "Xray")
createBtn(5, "5. ☠️ สมุดสั่งตาย (Death Note)", "DeathNote")
createBtn(6, "6. 🌍 Server Selector", "ServerSelector")
createBtn(7, "7. ESP", "ESP")
local monsterMenuButton = Instance.new("TextButton", scroll)
monsterMenuButton.Name = "TayJayMonsterMenuButton"
monsterMenuButton.LayoutOrder = 8
monsterMenuButton.Size = UDim2.new(1, -4, 0, 34)
monsterMenuButton.BackgroundColor3 = GREEN.on
monsterMenuButton.Text = "8. 👾 Monster : ON"
monsterMenuButton.TextColor3 = WHITE_TEXT
monsterMenuButton.TextStrokeColor3 = TEXT_OUTLINE
monsterMenuButton.TextStrokeTransparency = 0.35
monsterMenuButton.Font = Enum.Font.GothamBold
monsterMenuButton.TextScaled = true
local monsterMenuTextSize = Instance.new("UITextSizeConstraint", monsterMenuButton)
monsterMenuTextSize.MaxTextSize = 14
monsterMenuTextSize.MinTextSize = 9
Instance.new("UICorner", monsterMenuButton).CornerRadius = UDim.new(0, 11)
local monsterMenuEdge = Instance.new("UIStroke", monsterMenuButton)
monsterMenuEdge.Color = GREEN.neon
monsterMenuEdge.Thickness = 1.4
local monsterMenuVisible = true
local function refreshMonsterMenuButton()
    monsterMenuButton.Text = "8. 👾 Monster : " .. (monsterMenuVisible and "ON" or "OFF")
    monsterMenuButton.BackgroundColor3 = monsterMenuVisible and GREEN.on or GREEN.off
    monsterMenuEdge.Color = monsterMenuVisible and GREEN.neon or Color3.fromRGB(255, 115, 75)
end
trackConnection(monsterMenuButton.Activated:Connect(function()
    monsterMenuVisible = not monsterMenuVisible
    if type(_G.TAYJAY_MONSTER_PANEL_SET_VISIBLE) == "function" then _G.TAYJAY_MONSTER_PANEL_SET_VISIBLE(monsterMenuVisible) end
    refreshMonsterMenuButton()
end))
refreshMonsterMenuButton()
end -- [/TAYJAY LOCAL-LIMIT FIX 8/8]
local stopAllButton = Instance.new("TextButton", scroll)
stopAllButton.Name = "TayJayStopAllButton"
stopAllButton.LayoutOrder = 9
stopAllButton.Size = UDim2.new(1, -4, 0, 38)
stopAllButton.BackgroundColor3 = Color3.fromRGB(176, 36, 48)
stopAllButton.Text = "STOP ALL"
stopAllButton.TextColor3 = WHITE_TEXT
stopAllButton.Font = Enum.Font.GothamBlack
stopAllButton.TextSize = 14
stopAllButton.TextStrokeColor3 = TEXT_OUTLINE
stopAllButton.TextStrokeTransparency = 0.25
stopAllButton.BorderSizePixel = 0
Instance.new("UICorner", stopAllButton).CornerRadius = UDim.new(0, 9)
local stopEdge = Instance.new("UIStroke", stopAllButton)
stopEdge.Color = Color3.fromRGB(255, 214, 72)
stopEdge.Thickness = 2
trackConnection(stopAllButton.Activated:Connect(function()
    if type(_G.TAYJAY_STOP_ALL) == "function" then _G.TAYJAY_STOP_ALL() end
end))
trackConnection(list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12) end))

