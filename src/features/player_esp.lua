-- =========================================================
-- 🌟 AUTO PLAYER ESP (BACKGROUND)
-- =========================================================
local ESP_NAME = "TayJay_PlayerESP"
local ESP_HIGHLIGHT = "TayJay_PlayerHighlight"
local ESP_SILVER = Color3.fromRGB(255, 249, 210)
local ESP_DARK_STROKE = Color3.fromRGB(36, 142, 68)
local ESP_FILL = Color3.fromRGB(90, 175, 55)
local ESP_OUTLINE = Color3.fromRGB(255, 211, 58)
local espBoundCharacters = {}

local function cleanupEspCharacter(character)
   local entry = character and espBoundCharacters[character]
   if not entry then return false end
   espBoundCharacters[character] = nil
   if entry.owner and entry.owner.Stopped ~= true then
      pcall(function()
         ResourceManager:StopOwner(entry.ownerId, "character_removed")
      end)
   end
   return true
end

local function cleanupEspPlayer(player)
   for character, entry in pairs(espBoundCharacters) do
      if entry.player == player then
         cleanupEspCharacter(character)
      end
   end
end

local function applyEspToCharacter(character)
   if not character or not character.Parent then return end
   local head = character:FindFirstChild("Head")
   local humanoid = character:FindFirstChildOfClass("Humanoid")
   if not head or not humanoid then return end
   if not states.ESP and not states.MM2RoleESP then
       local oldHighlight = character:FindFirstChild(ESP_HIGHLIGHT)
       if oldHighlight then oldHighlight:Destroy() end
       local oldBillboard = head:FindFirstChild(ESP_NAME)
       if oldBillboard then oldBillboard:Destroy() end
       return
   end
   local highlight = character:FindFirstChild(ESP_HIGHLIGHT)
   if not highlight then
       highlight = Instance.new("Highlight")
       highlight.Name = ESP_HIGHLIGHT
       highlight.Adornee = character
       highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
       highlight.FillColor = ESP_FILL
       highlight.OutlineColor = ESP_OUTLINE
       highlight.FillTransparency = 0.78
       highlight.OutlineTransparency = 0.08
       highlight.Parent = character
   else
       highlight.Enabled = true
       if not states.MM2RoleESP then
           highlight.FillColor = ESP_FILL
           highlight.OutlineColor = ESP_OUTLINE
           highlight.FillTransparency = 0.78
           highlight.OutlineTransparency = 0.08
       end
   end

   local billboard = head:FindFirstChild(ESP_NAME)
   if not billboard then
       billboard = Instance.new("BillboardGui")
       billboard.Name = ESP_NAME
       billboard.Adornee = head
       billboard.AlwaysOnTop = true
       billboard.LightInfluence = 0
       billboard.MaxDistance = 500
       billboard.Size = UDim2.new(0, 190, 0, 42)
       billboard.StudsOffset = Vector3.new(0, 2.8, 0)
       billboard.Parent = head

       local nameLabel = Instance.new("TextLabel")
       nameLabel.Name = "PlayerName"
       nameLabel.BackgroundTransparency = 1
       nameLabel.Size = UDim2.new(1, 0, 0, 21)
       nameLabel.Position = UDim2.new(0, 0, 0, 0)
       nameLabel.Font = Enum.Font.GothamBold
       nameLabel.Text = "Player"
       nameLabel.TextColor3 = WHITE_TEXT
       nameLabel.TextSize = 13
       nameLabel.TextStrokeColor3 = TEXT_OUTLINE
       nameLabel.TextStrokeTransparency = 0.48
       nameLabel.TextXAlignment = Enum.TextXAlignment.Center
       nameLabel.Parent = billboard
       applyTayJayTextContrast(nameLabel)

       local healthLabel = Instance.new("TextLabel")
       healthLabel.Name = "PlayerHealth"
       healthLabel.BackgroundTransparency = 1
       healthLabel.Size = UDim2.new(1, 0, 0, 18)
       healthLabel.Position = UDim2.new(0, 0, 0, 21)
       healthLabel.Font = Enum.Font.GothamBold
       healthLabel.Text = "100 / 100 HP"
       healthLabel.TextColor3 = WHITE_TEXT
       healthLabel.TextSize = 14
       healthLabel.TextStrokeColor3 = TEXT_OUTLINE
       healthLabel.TextStrokeTransparency = 0.48
       healthLabel.TextXAlignment = Enum.TextXAlignment.Center
       healthLabel.Parent = billboard
       applyTayJayTextContrast(healthLabel)
   end

   local player = Players:GetPlayerFromCharacter(character)
   local nameLabel = billboard:FindFirstChild("PlayerName")
   if nameLabel and player then
       nameLabel.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
   end

   local healthLabel = billboard:FindFirstChild("PlayerHealth")
   if healthLabel then
       local hp = math.max(0, math.floor(humanoid.Health + 0.5))
       local maxHp = math.max(1, math.floor(humanoid.MaxHealth + 0.5))
       healthLabel.Text = tostring(hp) .. " / " .. tostring(maxHp) .. " HP"
   end

   if not espBoundCharacters[character] then
       local playerForCharacter = Players:GetPlayerFromCharacter(character)
       local ownerId = "ESPCharacter:" .. tostring(playerForCharacter and playerForCharacter.UserId or "Unknown") .. ":" .. tostring(character)
       local owner = ResourceManager:CreateOwner(ownerId, function()
           if espBoundCharacters[character] then
               espBoundCharacters[character] = nil
           end
       end)
       if owner then
           espBoundCharacters[character] = {
               owner = owner,
               ownerId = ownerId,
               player = playerForCharacter,
           }
           owner:Own(humanoid.HealthChanged:Connect(function(health)
               if not character.Parent or not healthLabel or not healthLabel.Parent then return end
               local maxHp = math.max(1, math.floor(humanoid.MaxHealth + 0.5))
               healthLabel.Text = tostring(math.max(0, math.floor(health + 0.5))) .. " / " .. tostring(maxHp) .. " HP"
           end))
           owner:Own(humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
               if not character.Parent or not healthLabel or not healthLabel.Parent then return end
               local hp = math.max(0, math.floor(humanoid.Health + 0.5))
               local maxHp = math.max(1, math.floor(humanoid.MaxHealth + 0.5))
               healthLabel.Text = tostring(hp) .. " / " .. tostring(maxHp) .. " HP"
           end))
           owner:Own(character.AncestryChanged:Connect(function(_, parent)
               if parent == nil then
                   cleanupEspCharacter(character)
               end
           end))
       end
   end
end
registerUiSync("ESP", function(isOn)
    if isOn then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then applyEspToCharacter(player.Character) end
        end
    elseif not states.MM2RoleESP then
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                local highlight = character:FindFirstChild(ESP_HIGHLIGHT)
                if highlight then highlight:Destroy() end
                local head = character:FindFirstChild("Head") or character.PrimaryPart
                local billboard = head and head:FindFirstChild(ESP_NAME)
                if billboard then billboard:Destroy() end
            end
        end
    end
end)

local function bindEspPlayer(player)
   if player == LocalPlayer then return end
   if player.Character then
       task.spawn(function()
           local character = player.Character
           if character then
               character:WaitForChild("Head", 8)
               character:WaitForChild("Humanoid", 8)
               applyEspToCharacter(character)
           end
       end)
   end
   trackConnection(player.CharacterAdded:Connect(function(character)
       task.spawn(function()
           character:WaitForChild("Head", 8)
           character:WaitForChild("Humanoid", 8)
           if character.Parent and player.Parent == Players then
               applyEspToCharacter(character)
           end
       end)
   end))
   trackConnection(player.CharacterRemoving:Connect(function(character)
       cleanupEspCharacter(character)
   end))
end

for _, player in ipairs(Players:GetPlayers()) do
   bindEspPlayer(player)
end
trackConnection(Players.PlayerAdded:Connect(bindEspPlayer))
trackConnection(Players.PlayerRemoving:Connect(function(player)
   cleanupEspPlayer(player)
end))

task.spawn(function()
   while screenGui.Parent do
       task.wait(0.75)
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer and player.Character then
               local character = player.Character
               if character.Parent and character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") then
                   applyEspToCharacter(character)
               end
           end
       end
       for character in pairs(espBoundCharacters) do
           if not character.Parent then
               cleanupEspCharacter(character)
           end
       end
   end
end)

