-- =========================================================
-- WALK2: independent WALK-target attack toggle (shared with Death Note cards)
do
   local WALK2_MASK_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAAkFBMVEXkniagbB7drFKll0+mizH03KPuzVRraTJxhUteKQjVfBVfdUb48uXLsZK5oIk3a06TbUx6gT7/1TxHcEv+1Ew7a01Dbkz7y0VXdEj6xDr9p0nlhRfahBw5bVD6tij+s1hnd0T3ujT2pxh4dzvzqiT++MXHgyWIeDa3ZADJt0z7rVanWQHXhSGFh0ilo0w7cFL2L5RyAAAEk0lEQVR42m2VC5uiOgyGk5arl5ndA61VygiiICPq//9350vRcWZ3M89Im+ZtGpoEKp5iDcSGgZVx8VNsWCsK+jJ1GcTBOBvHZLxl5mufYO10BsIKYG7j7abVphTRjXHz6GbFwDg9KpWMSZncQDorgE7EINnsdvLM3m8BKEfYOxnvVCkW2thRm3CkMQBqtwt7u6x8EMaJITZS8rxh5wDgkMEFPYDkCZQ3Vc4AhdkoEFk3agsi+QKC/2/yBEKI8ABHSYZNNwBU+Q9RfwDWwgxxC7D7hz0cvIAsxJCVm3KzCYCcafNNsKIC8JiF12rNGOYC7LabzQ9iIw7UE9CmIJON5joDQpCf1MNyW7ZEPijpoWoEuP6nsi1k03pxMXVIEoKoW9Z0XXDr241YbLXBkYzePkV2o6oxyJxuGJBEtu4q2tHk53XdKLylF9BW3k9VH1LO1HV4Ol9N3tNsgAcBiLZUHbdtu6WFr6q+sd+T2jTQVRGW2/ZYUQDwO0SiqJqOubA/y8A45s6RrPMAU4u/D7nt9mN7te9/lY0gpnaLY9te6wKmM+Cso48ylIw15psPO9dZzfTRW9t8AYMpuE1weuOarnHFww/KTKa2sA0OVBhgiABA1RXmulEoF54Qou+Hefsukoh91Ej+L8378AR67KmOfHd95UkRrBgHMUP1mPrGjFKgOFIkb4mi2mYlDTVXXsWnU6x8JS938hTHpzieqsjoMnFFHZEA+LVQ0LKOKoV12FDVGdyZxzCJT8miN0tC4pkA1NGBrZPMNVxh9XJRJ7WAB7cAfsYsrnrc33Y0RX/4LQD1cLBJCtMBUDPgrF2ykhkB4Noh/1zhSZKvgR9ktMKpF7tT3HN82vFSqbpDCISZ4LhrXKyn0PkQNG3bSLof70PQbPR+fzX8KTEnlCIBFJL1HZYAcKYr0pDvWuuGSSmdYn2/V8akkVKKr1pfrWRqSp0AuHHMjoxN93t0t7TRV73//Nxfr9rZ1Ab9kiT9aW7GeE9tAD5hpcPuMvzEQyEtZ3WPCpAThe4t2YuUVbOLQu0WO/GgFntlzax10xEm7tHuTfQhgM0QBd5no1MWJ5zKzEGZGecBROYFQBqplRRpZczdXpVemrt8VlzKbE1GsMh+AlGdLiryEQ+Nc1IWzi0H7j1VC1c/tnwBxw/id8sXXlQLJOnUQ7yvaFF5lrolWBydfQKZTL278yXP1VpNEzIcWT1NKlZ5zmndHI9HifL5jXMEBXGdnjlfrbRexXyKOV7p9WqV83mJEj0eD2SeH0V4PEDI1Xz5tXrL07dfebzOf73l+XqFE90bLwbRCzDRgfAXBRc5LNN8/Zbzm0wu5+WdKexnvwA8DgIgCiFWqzWvVmm8WiOAc7pE8siqKV5AHVx0VVfz+cJaMV8uzErz5cx3K/vRobHfAEQBHYp6sHw+8/zP4VkPuMuIQh59B5yozMB1gZvlNF0u0zBwXDVSAfTsbc8B6guFP3e9ur7j937HnvdoQqxYdPYPABU969COuAudvunEs7RB61Lzp4fiq227LuqF877/0tpXv6W/23X4lljXueJf8j9PhrFJN8S/ygAAAABJRU5ErkJggg=="
   local function decodeBase64(data)
      local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
      local lookup = {}
      for i = 1, #alphabet do lookup[alphabet:sub(i, i)] = i - 1 end
      local buffer, bits, output = 0, 0, {}
      for i = 1, #data do
         local value = lookup[data:sub(i, i)]
         if value ~= nil then
            buffer = buffer * 64 + value
            bits = bits + 6
            if bits >= 8 then
               bits = bits - 8
               output[#output + 1] = string.char(math.floor(buffer / (2 ^ bits)) % 256)
               buffer = buffer % (2 ^ bits)
            end
         end
      end
      return table.concat(output)
   end
   local walk2IconAsset = nil
   pcall(function()
      local assetPath = "TAYJAY_WALK2_MASK.png"
      local assetLoader
      if type(getcustomasset) == "function" then
         assetLoader = getcustomasset
      elseif type(getsynasset) == "function" then
         assetLoader = getsynasset
      end
      if not assetLoader then return end
      local fileReady = false
      pcall(function()
         fileReady = type(isfile) == "function" and isfile(assetPath) == true
      end)
      if not fileReady then
         if type(writefile) ~= "function" then return end
         writefile(assetPath, decodeBase64(WALK2_MASK_BASE64))
         fileReady = true
      end
      if fileReady then walk2IconAsset = assetLoader(assetPath) end
   end)

   local walk2Enabled = false
   local button = Instance.new("TextButton", screenGui)
   button.Name = "TayJayWalk2Btn"
   button.AnchorPoint = Vector2.new(0.5, 0.5)
   button.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize)
   button.Position = UI_LAYOUT.Walk2Center
   button.BackgroundColor3 = GREEN.off
   button.Text = ""
   button.TextColor3 = WHITE_TEXT
   button.AutoButtonColor = true
   button.Active = true
   button.ClipsDescendants = true
   button:SetAttribute("TayJayKeepCustomStyle", true)
   Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
   local stroke = Instance.new("UIStroke", button)
   stroke.Color = Color3.fromRGB(255, 96, 132)
   stroke.Thickness = 2.5
   makeDraggable(button)

   local icon = Instance.new("ImageLabel", button)
   icon.Name = "Walk2MaskIcon"
   icon.AnchorPoint = Vector2.new(0.5, 0)
   icon.Position = UDim2.new(0.5, 0, 0, 1)
   icon.Size = UDim2.fromOffset(35, 35)
   icon.BackgroundTransparency = 1
   icon.ScaleType = Enum.ScaleType.Fit
   icon.ZIndex = button.ZIndex + 1
   icon.Visible = false

   local fallbackIcon = Instance.new("TextLabel", button)
   fallbackIcon.Name = "Walk2FallbackIcon"
   fallbackIcon.AnchorPoint = icon.AnchorPoint
   fallbackIcon.Position = icon.Position
   fallbackIcon.Size = icon.Size
   fallbackIcon.BackgroundTransparency = 1
   fallbackIcon.Text = "👹"
   fallbackIcon.TextColor3 = WHITE_TEXT
   fallbackIcon.TextStrokeColor3 = TEXT_OUTLINE
   fallbackIcon.TextStrokeTransparency = 0.25
   fallbackIcon.Font = Enum.Font.GothamBlack
   fallbackIcon.TextSize = 29
   fallbackIcon.ZIndex = button.ZIndex + 1

   if walk2IconAsset then
      local loaded = pcall(function()
         icon.Image = walk2IconAsset
         icon.Visible = true
         fallbackIcon.Visible = false
      end)
      if not loaded then icon.Visible = false; fallbackIcon.Visible = true end
   else
      fallbackIcon.Visible = true
   end

   local nameLabel = Instance.new("TextLabel", button)
   nameLabel.Name = "Walk2Name"
   nameLabel.Position = UDim2.new(0, 0, 0, 35)
   nameLabel.Size = UDim2.new(1, 0, 0, 12)
   nameLabel.BackgroundTransparency = 1
   nameLabel.Text = "WALK2"
   nameLabel.TextColor3 = WHITE_TEXT
   nameLabel.TextStrokeColor3 = TEXT_OUTLINE
   nameLabel.TextStrokeTransparency = 0.25
   nameLabel.Font = Enum.Font.GothamBlack
   nameLabel.TextSize = 10
   nameLabel.ZIndex = button.ZIndex + 1

   local statusLabel = Instance.new("TextLabel", button)
   statusLabel.Name = "Walk2Status"
   statusLabel.Position = UDim2.new(0, 0, 0, 46)
   statusLabel.Size = UDim2.new(1, 0, 0, 10)
   statusLabel.BackgroundTransparency = 1
   statusLabel.Text = "OFF"
   statusLabel.TextColor3 = WHITE_TEXT
   statusLabel.TextStrokeColor3 = TEXT_OUTLINE
   statusLabel.TextStrokeTransparency = 0.25
   statusLabel.Font = Enum.Font.GothamBold
   statusLabel.TextSize = 9
   statusLabel.ZIndex = button.ZIndex + 1

   local function updateWalk2Visual()
      button.BackgroundColor3 = walk2Enabled and GREEN.on or GREEN.off
      statusLabel.Text = walk2Enabled and "ON" or "OFF"
   end
   trackConnection(button.Activated:Connect(function()
      walk2Enabled = not walk2Enabled
      updateWalk2Visual()
   end))
   trackConnection(RunService.Heartbeat:Connect(function()
      if not walk2Enabled or not AttackRemote or isBusy then return end
      local targetChar = getClosestPlayer_V57(25)
      if targetChar then walk2AttackTarget(targetChar) end
   end))
   updateWalk2Visual()
end
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

