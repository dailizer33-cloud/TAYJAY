local uiSyncRegistry = {}
local function registerUiSync(key, updateFunc)
   local previous = uiSyncRegistry[key]
   if previous then
       -- ไม่เขียนทับตัวเดิม: ปุ่มเมนู (ON/OFF) และฟังก์ชันของฟีเจอร์ทำงานคู่กันได้
       uiSyncRegistry[key] = function(isOn) pcall(previous, isOn); updateFunc(isOn) end
   else
       uiSyncRegistry[key] = updateFunc
   end
end
local function syncButtonState(key, isOn)
   states[key] = isOn
   if uiSyncRegistry[key] then pcall(function() uiSyncRegistry[key](isOn) end) end
end

local function makeDraggable(gui, addLockButton)
   local dragging, dragInput, dragStart, startPos
   gui.Active = true
   gui:SetAttribute("TayJayWindowLocked", false)
   if addLockButton ~= false and gui:IsA("Frame") then
       local lockButton = Instance.new("TextButton")
       lockButton.Name = "WindowLockButton"
       lockButton.Size = UDim2.new(0, 24, 0, 24)
       lockButton.Position = UDim2.new(1, -29, 0, 4)
       lockButton.BackgroundColor3 = Color3.fromRGB(76, 158, 48)
       lockButton.Text = "🔓"
       lockButton.TextColor3 = WHITE_TEXT
       lockButton.Font = Enum.Font.GothamBold
       lockButton.TextSize = 14
       lockButton.AutoButtonColor = true
       lockButton.Active = true
       lockButton.ZIndex = 30
       lockButton.Parent = gui
       Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 7)
       local lockStroke = Instance.new("UIStroke", lockButton)
       lockStroke.Color = Color3.fromRGB(31, 57, 31)
       lockStroke.Thickness = 1.5
       trackConnection(lockButton.Activated:Connect(function()
           local locked = not gui:GetAttribute("TayJayWindowLocked")
           gui:SetAttribute("TayJayWindowLocked", locked)
           lockButton.Text = locked and "🔒" or "🔓"
           lockButton.BackgroundColor3 = locked and Color3.fromRGB(255, 132, 24) or Color3.fromRGB(76, 158, 48)
           dragging = false
       end))
   end
   trackConnection(gui.InputBegan:Connect(function(input)
       if not gui:GetAttribute("TayJayWindowLocked") and not _G.TAYJAY_UI.locked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
           dragging = true; dragStart = input.Position; startPos = gui.Position
           local endedConn; endedConn = input.Changed:Connect(function()
               if input.UserInputState == Enum.UserInputState.End then dragging = false; if endedConn then endedConn:Disconnect() end end
           end)
       end
   end))
   trackConnection(gui.InputChanged:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
   end))
   trackConnection(UserInputService.InputChanged:Connect(function(input)
       if input == dragInput and dragging and not gui:GetAttribute("TayJayWindowLocked") and not _G.TAYJAY_UI.locked then
           local delta = input.Position - dragStart
           gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
       end
   end))
end

