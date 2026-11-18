-- =========================================================
-- 🗡️ MM2 ROLE ESP + PLAYER LIST 
-- =========================================================
do
   print("[TAYJAY MM2] Initializing merged MM2 controls...")

   local mm2MainFrame = Instance.new("Frame")
   mm2MainFrame.Name = "TayJayMM2Dock"
   mm2MainFrame.Size = UDim2.new(0, 118, 0, 48)
   mm2MainFrame.Position = UI_LAYOUT.MM2Dock
   mm2MainFrame.BackgroundColor3 = GREEN.dark
   mm2MainFrame.BackgroundTransparency = 0.05
   mm2MainFrame.Active = true
   mm2MainFrame.Parent = screenGui
   Instance.new("UICorner", mm2MainFrame).CornerRadius = UDim.new(0, 15)
   local mm2MainStroke = Instance.new("UIStroke")
   mm2MainStroke.Color = GREEN.stroke
   mm2MainStroke.Thickness = 1.5
   mm2MainStroke.Parent = mm2MainFrame
   makeDraggable(mm2MainFrame, false)

   local function createMM2Button(iconText, xOffset)
       local button = Instance.new("TextButton")
       button.Size = UDim2.new(0, 38, 0, 38)
       button.Position = UDim2.new(0, xOffset, 0, 5)
       button.BackgroundColor3 = GREEN.off
       button.Text = iconText
       button.TextSize = 20
       button.Parent = mm2MainFrame
       Instance.new("UICorner", button).CornerRadius = UDim.new(0.5, 0)
       return button
   end

   local mm2ESPButton = createMM2Button("🗡️", 7)
   local mm2ListButton = createMM2Button("📋", 72)

   local mm2ListFrame = Instance.new("Frame")
   mm2ListFrame.Name = "TayJayMM2PlayerList"
   mm2ListFrame.Size = UDim2.new(0, 252, 0, 316)
   mm2ListFrame.AnchorPoint = Vector2.new(0, 1)
   mm2ListFrame.Position = UDim2.new(0, 244, 1, -12)
   mm2ListFrame.BackgroundColor3 = GREEN.deep
   mm2ListFrame.BackgroundTransparency = 0.05
   mm2ListFrame.Active = true
   mm2ListFrame.Visible = false
   mm2ListFrame.Parent = screenGui
   Instance.new("UICorner", mm2ListFrame).CornerRadius = UDim.new(0, 10)
   local mm2ListStroke = Instance.new("UIStroke")
   mm2ListStroke.Color = GREEN.stroke
   mm2ListStroke.Thickness = 1.5
   mm2ListStroke.Parent = mm2ListFrame
   makeDraggable(mm2ListFrame, false)

   local mm2ListTitle = Instance.new("TextLabel")
   mm2ListTitle.Size = UDim2.new(1, -74, 0, 32)
   mm2ListTitle.BackgroundTransparency = 1
   mm2ListTitle.Text = "👥 ผู้เล่นทั้งหมด (MM2)"
   mm2ListTitle.TextColor3 = WHITE_TEXT
   mm2ListTitle.Font = Enum.Font.GothamBold
   mm2ListTitle.TextSize = 14
   mm2ListTitle.TextStrokeColor3 = TEXT_OUTLINE
   mm2ListTitle.TextStrokeTransparency = 0.48
   mm2ListTitle.TextXAlignment = Enum.TextXAlignment.Left
   mm2ListTitle.Position = UDim2.new(0, 10, 0, 0)
   mm2ListTitle.Parent = mm2ListFrame

   local mm2ScrollingFrame = Instance.new("ScrollingFrame")
   mm2ScrollingFrame.Size = UDim2.new(1, -16, 1, -42)
   mm2ScrollingFrame.Position = UDim2.new(0, 8, 0, 36)
   mm2ScrollingFrame.BackgroundTransparency = 1
   mm2ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
   mm2ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
   mm2ScrollingFrame.ScrollBarThickness = 4
   mm2ScrollingFrame.Parent = mm2ListFrame

   local mm2ListLayout = Instance.new("UIListLayout")
   mm2ListLayout.Padding = UDim.new(0, 5)
   mm2ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
   mm2ListLayout.Parent = mm2ScrollingFrame

   local function detectMM2ExplicitRole(player)
       local value = player:GetAttribute("Role")
       if type(value) ~= "string" then
           local object = player:FindFirstChild("Role")
           if object and object:IsA("StringValue") then value = object.Value end
       end
       if type(value) ~= "string" then return nil end
       value = string.lower(value)
       if value == "murderer" then return "Murderer" end
       if value == "sheriff" then return "Sheriff" end
       if value == "innocent" then return "Innocent" end
       return nil
   end

   local function detectMM2MurdererTool(player)
       for _, container in ipairs({player.Character, player:FindFirstChild("Backpack")}) do
           if container then
               for _, item in ipairs(container:GetChildren()) do
                   if item:IsA("Tool") then
                       local name = string.lower(item.Name)
                       if name == "knife" or name == "murdererknife" then return true end
                   end
               end
           end
       end
       return false
   end

   local function detectMM2SheriffTool(player)
       for _, container in ipairs({player.Character, player:FindFirstChild("Backpack")}) do
           if container then
               for _, item in ipairs(container:GetChildren()) do
                   if item:IsA("Tool") then
                       local name = string.lower(item.Name)
                       if name == "gun" or name == "sheriffgun" or name == "revolver" then return true end
                   end
               end
           end
       end
       return false
   end

   local function getMM2PlayerRole(player)
       local role = detectMM2ExplicitRole(player)
       if role == "Murderer" then return "Murderer", Color3.fromRGB(255, 55, 65), "🔪", 1 end
       if role == "Sheriff" then return "Sheriff", Color3.fromRGB(55, 155, 255), "🔫", 2 end
       if role == "Innocent" then return "Innocent", Color3.fromRGB(65, 220, 105), "•", 3 end
       local knife = detectMM2MurdererTool(player)
       local gun = detectMM2SheriffTool(player)
       if knife and not gun then return "Murderer*", Color3.fromRGB(255, 75, 80), "🔪", 1 end
       if gun and not knife then return "Sheriff*", Color3.fromRGB(75, 165, 255), "🔫", 2 end
       return "Unknown", Color3.fromRGB(255, 215, 95), "❔", 4
   end

   local function teleportAndAttack(targetPlayer)
       if isBusy or flyNowe or states.Fly or targetPlayer == LocalPlayer then return end

       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       local targetCharacter = targetPlayer.Character
       local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
       if not (root and targetRoot) then return end

       isBusy = true
       local followConnection = nil
       local ok, err = pcall(function()
           local originalCFrame = root.CFrame
           local backpack = LocalPlayer:FindFirstChild("Backpack")
           if backpack then
               for _, tool in ipairs(backpack:GetChildren()) do
                   if tool:IsA("Tool") then
                       tool.Parent = character
                       break
                   end
               end
           end

           local startTime = tick()
           followConnection = RunService.RenderStepped:Connect(function()
               if tick() - startTime > 2 then
                   if followConnection then followConnection:Disconnect() end
                   return
               end

               local currentTargetCharacter = targetPlayer.Character
               local currentTargetRoot = currentTargetCharacter and currentTargetCharacter:FindFirstChild("HumanoidRootPart")
               local currentCharacter = LocalPlayer.Character
               local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
               if currentTargetRoot and currentRoot then
                   ResourceManager:RecordWrite("MM2Movement", "Position")
                    currentRoot.CFrame = currentTargetRoot.CFrame * CFrame.new(0, 0, 2.5)
                   local targetHumanoid = currentTargetCharacter:FindFirstChildOfClass("Humanoid")
                   if targetHumanoid and targetHumanoid.Health > 0 then
                       tryAttackTarget(currentTargetCharacter)
                   end
               end
           end)

           task.wait(2.1)
           local currentCharacter = LocalPlayer.Character
           local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
           if currentRoot then
               ResourceManager:RecordWrite("MM2Movement", "Position")
                currentRoot.CFrame = originalCFrame
           end
       end)
       -- Always release this short-lived RenderStepped connection, including pcall failures.
       if followConnection then
           pcall(function() followConnection:Disconnect() end)
           followConnection = nil
       end
       isBusy = false
       if not ok then warn("[TAYJAY MM2] Follow action stopped: " .. tostring(err)) end
   end

   local mm2ESPEnabled = false
   local function updateMM2RoleESP()
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer and player.Character then
               local roleName, roleColor = getMM2PlayerRole(player)
               local character = player.Character
               local highlight = character:FindFirstChild("TayJay_PlayerHighlight")

               if not highlight then
                   highlight = Instance.new("Highlight")
                   highlight.Name = "TayJay_PlayerHighlight"
                   highlight.Adornee = character
                   highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                   highlight.Parent = character
               end
               highlight.Enabled = true
               highlight.FillColor = roleColor
               highlight.OutlineColor = roleColor
               highlight.FillTransparency = 0.6
               highlight.OutlineTransparency = 0.1

               local head = character:FindFirstChild("Head") or character.PrimaryPart
               local billboard = head and head:FindFirstChild("TayJay_PlayerESP")
               if billboard then
                   billboard.Size = UDim2.new(0, 190, 0, 60)
                   local roleLabel = billboard:FindFirstChild("MM2RoleText")
                   if not roleLabel then
                       roleLabel = Instance.new("TextLabel")
                       roleLabel.Name = "MM2RoleText"
                       roleLabel.Size = UDim2.new(1, 0, 0, 18)
                       roleLabel.Position = UDim2.new(0, 0, 0, 40)
                       roleLabel.BackgroundTransparency = 1
                       roleLabel.Font = Enum.Font.GothamBold
                       roleLabel.TextSize = 13
                       roleLabel.TextStrokeTransparency = 0.48
                       roleLabel.TextStrokeColor3 = TEXT_OUTLINE
                       roleLabel.TextXAlignment = Enum.TextXAlignment.Center
                       roleLabel.Parent = billboard
                       applyTayJayTextContrast(roleLabel)
                   end
                   roleLabel.Text = roleName
                   roleLabel.TextColor3 = roleColor
               end
           end
       end
   end

   local function clearMM2RoleESP()
       states.MM2RoleESP = false
       for _, player in ipairs(Players:GetPlayers()) do
           local character = player.Character
           if character then
               local highlight = character:FindFirstChild("TayJay_PlayerHighlight")
               if highlight then
                   highlight.FillColor = ESP_FILL
                   highlight.OutlineColor = ESP_OUTLINE
                   highlight.FillTransparency = 0.78
                   highlight.OutlineTransparency = 0.08
               end
               local head = character:FindFirstChild("Head") or character.PrimaryPart
               local billboard = head and head:FindFirstChild("TayJay_PlayerESP")
               if billboard then
                   local roleLabel = billboard:FindFirstChild("MM2RoleText")
                   if roleLabel then roleLabel:Destroy() end
                   billboard.Size = UDim2.new(0, 190, 0, 42)
               end
           end
       end
   end

   _G.TAYJAY_MM2_STOP = function()
       mm2ESPEnabled = false
       states.MM2RoleESP = false
       mm2ESPButton.BackgroundColor3 = GREEN.off
       mm2ESPButton:SetAttribute("TayJayEnabled", false)
       clearMM2RoleESP()
   end

   -- Row button connections are row-scoped, not retained in the long-lived Global owner.
   local rowConnections = setmetatable({}, {__mode = "k"})
   local function disconnectRowConnections(row)
       local connections = rowConnections[row]
       if not connections then return end
       for _, connection in ipairs(connections) do
           pcall(function() connection:Disconnect() end)
       end
       table.clear(connections)
       rowConnections[row] = nil
   end

   local function updateMM2PlayerList()
       if not mm2ListFrame.Visible then return end
       mm2ListTitle.Text = "👥 ผู้เล่นทั้งหมด (" .. math.max(0, #Players:GetPlayers() - 1) .. ")"

       for _, child in ipairs(mm2ScrollingFrame:GetChildren()) do
           if child:IsA("Frame") and not Players:FindFirstChild(child.Name) then
               disconnectRowConnections(child)
               child:Destroy()
           end
       end

       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer then
               local roleName, roleColor, roleIcon, roleOrder = getMM2PlayerRole(player)
               local row = mm2ScrollingFrame:FindFirstChild(player.Name)

               if not row then
                   row = Instance.new("Frame")
                   row.Name = player.Name
                   row.Size = UDim2.new(1, 0, 0, 50)
                   row.BackgroundColor3 = GREEN.panel
                   row.Parent = mm2ScrollingFrame
                   row.LayoutOrder = roleOrder
                   local connections = {}
                   rowConnections[row] = connections
                   local rowTap = Instance.new("TextButton")
                   rowTap.Name = "RowTap"
                   rowTap.Size = UDim2.new(1, 0, 1, 0)
                   rowTap.BackgroundTransparency = 1
                   rowTap.Text = ""
                   rowTap.AutoButtonColor = false
                   rowTap.ZIndex = 1
                   rowTap.Parent = row
                   connections[#connections + 1] = rowTap.Activated:Connect(function()
                       teleportAndAttack(player)
                   end)
                   Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
                   local rowStroke = Instance.new("UIStroke", row)
                   rowStroke.Color = GREEN.stroke
                   rowStroke.Thickness = 1.4

                   local nameLabel = Instance.new("TextLabel")
                   nameLabel.Name = "PlayerName"
                   nameLabel.Size = UDim2.new(0.46, -8, 1, 0)
                   nameLabel.Position = UDim2.new(0, 10, 0, 0)
                   nameLabel.BackgroundTransparency = 1
                   nameLabel.Text = player.Name
                   nameLabel.TextColor3 = WHITE_TEXT
                   nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                   nameLabel.Font = Enum.Font.GothamBold
                   nameLabel.TextSize = 16
                   nameLabel.TextStrokeColor3 = TEXT_OUTLINE
                   nameLabel.TextStrokeTransparency = 0.48
                   nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                   nameLabel.ZIndex = 2
                   nameLabel.Parent = row

                   local roleLabel = Instance.new("TextLabel")
                   roleLabel.Name = "RoleLabel"
                   roleLabel.Size = UDim2.new(0.31, 0, 1, 0)
                   roleLabel.Position = UDim2.new(0.49, 0, 0, 0)
                   roleLabel.BackgroundTransparency = 1
                   roleLabel.Text = roleName
                   roleLabel.TextColor3 = roleColor
                   roleLabel.Font = Enum.Font.GothamBold
                   roleLabel.TextSize = 13
                   roleLabel.TextStrokeColor3 = TEXT_OUTLINE
                   roleLabel.TextStrokeTransparency = 0.48
                   roleLabel.TextXAlignment = Enum.TextXAlignment.Center
                   roleLabel.ZIndex = 2
                   roleLabel.Parent = row

                   local actionButton = Instance.new("TextButton")
                   actionButton.Name = "ActionBtn"
                   actionButton.Size = UDim2.new(0, 32, 0, 30)
                   actionButton.Position = UDim2.new(1, -37, 0.5, -15)
                   actionButton.BackgroundColor3 = GREEN.warning
                   actionButton.TextColor3 = WHITE_TEXT
                   actionButton.Text = roleIcon
                   actionButton.TextSize = 16
                   actionButton.Font = Enum.Font.GothamBold
                   actionButton.ZIndex = 3
                   actionButton.Parent = row
                   Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 6)
                   connections[#connections + 1] = actionButton.Activated:Connect(function()
                       teleportAndAttack(player)
                   end)
               else
                   local roleLabel = row:FindFirstChild("RoleLabel")
                   local actionButton = row:FindFirstChild("ActionBtn")
                   if roleLabel then
                       roleLabel.Text = roleName
                       roleLabel.TextColor3 = roleColor
                   end
                   if actionButton then actionButton.Text = roleIcon end
                   row.LayoutOrder = roleOrder
               end
           end
       end
   end

   trackConnection(mm2ESPButton.Activated:Connect(function()
       mm2ESPEnabled = not mm2ESPEnabled
       states.MM2RoleESP = mm2ESPEnabled
       if mm2ESPEnabled then
           mm2ESPButton.BackgroundColor3 = GREEN.on
           mm2ESPButton:SetAttribute("TayJayEnabled", true)
           updateMM2RoleESP()
       else
           mm2ESPButton.BackgroundColor3 = GREEN.off
           mm2ESPButton:SetAttribute("TayJayEnabled", false)
           clearMM2RoleESP()
       end
   end))

   trackConnection(mm2ListButton.Activated:Connect(function()
       mm2ListFrame.Visible = not mm2ListFrame.Visible
       if mm2ListFrame.Visible then
           mm2ListButton.BackgroundColor3 = GREEN.on
           mm2ListButton:SetAttribute("TayJayEnabled", true)
           updateMM2PlayerList()
       else
           mm2ListButton.BackgroundColor3 = GREEN.off
           mm2ListButton:SetAttribute("TayJayEnabled", false)
       end
   end))

   trackConnection(Players.PlayerAdded:Connect(function()
       task.defer(updateMM2PlayerList)
   end))
   trackConnection(Players.PlayerRemoving:Connect(function()
       task.defer(updateMM2PlayerList)
   end))

   task.spawn(function()
       while screenGui.Parent do
           task.wait(0.5)
           if mm2ESPEnabled then
               updateMM2RoleESP()
           end
       end
       clearMM2RoleESP()
   end)

   task.spawn(function()
       while screenGui.Parent do
           task.wait(1)
           updateMM2PlayerList()
       end
   end)
end

-- Capture original camera values before applying this script's camera defaults.
local originalCameraSettings = {
    CameraMode=LocalPlayer.CameraMode,
    CameraMaxZoomDistance=LocalPlayer.CameraMaxZoomDistance,
    CameraMinZoomDistance=LocalPlayer.CameraMinZoomDistance,
    DevCameraOcclusionMode=LocalPlayer.DevCameraOcclusionMode
}
