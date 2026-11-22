-- =========================================================
-- 👤 MY HP FRAME
-- =========================================================
do -- [TAYJAY LOCAL-LIMIT FIX 2/8]
local myHpFrame = Instance.new("Frame", screenGui)
myHpFrame.Size = UDim2.fromOffset(180, 44); myHpFrame.Position = UDim2.new(0, 10, 0, 52)
myHpFrame.BackgroundColor3 = GREEN.dark; myHpFrame.BackgroundTransparency = 0.05
Instance.new("UICorner", myHpFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", myHpFrame).Color = Color3.fromRGB(255, 211, 58); Instance.new("UIStroke", myHpFrame).Thickness = 2.5
makeDraggable(myHpFrame)

local myHpTitle = Instance.new("TextLabel", myHpFrame)
myHpTitle.Size = UDim2.new(1, -12, 0, 17); myHpTitle.Position = UDim2.new(0, 9, 0, 2); myHpTitle.BackgroundTransparency = 1
myHpTitle.Text = "👤 " .. (LocalPlayer.DisplayName or LocalPlayer.Name); myHpTitle.TextColor3 = WHITE_TEXT; myHpTitle.Font = Enum.Font.GothamBold; myHpTitle.TextSize = 13; myHpTitle.TextXAlignment = Enum.TextXAlignment.Left

local myBarBG = Instance.new("Frame", myHpFrame)
myBarBG.Size = UDim2.new(1, -18, 0, 17); myBarBG.Position = UDim2.new(0, 9, 0, 24); myBarBG.BackgroundColor3 = Color3.fromRGB(255, 249, 210); myBarBG.BorderSizePixel = 0
Instance.new("UICorner", myBarBG).CornerRadius = UDim.new(0, 5)

local myHealthBar = Instance.new("Frame", myBarBG)
myHealthBar.Size = UDim2.new(1, 0, 1, 0); myHealthBar.BackgroundColor3 = Color3.fromRGB(104, 211, 57); myHealthBar.BorderSizePixel = 0
Instance.new("UICorner", myHealthBar).CornerRadius = UDim.new(0, 5)

local myHpText = Instance.new("TextLabel", myBarBG)
myHpText.Size = UDim2.new(1, 0, 1, 0); myHpText.BackgroundTransparency = 1; myHpText.Text = "100 / 100 HP"; myHpText.TextColor3 = WHITE_TEXT; myHpText.Font = Enum.Font.GothamBold; myHpText.TextSize = 12

local myHpOwner = nil
local myHpCharacter = nil

local function stopMyHpOwner(reason)
   if myHpOwner and not myHpOwner.Stopped then
       ResourceManager:StopOwner("MyHP", reason or "character_replaced")
   end
   myHpOwner = nil
   myHpCharacter = nil
end

local function bindMyHealth(hum, character)
   if not hum or not character or character ~= LocalPlayer.Character then return end

   -- A single stable Owner is recreated for each current character.
   stopMyHpOwner("character_replaced")
   local owner = ResourceManager:CreateOwner("MyHP", function()
       if myHpOwner == owner then
           myHpOwner = nil
           myHpCharacter = nil
       end
   end)
   if not owner then return end
   myHpOwner = owner
   myHpCharacter = character

   local function updateMyHp()
       if not owner:IsAlive() or LocalPlayer.Character ~= character or not character.Parent then return end
       pcall(function()
           local maxHp = hum.MaxHealth > 0 and hum.MaxHealth or 100
           local hp = math.clamp(hum.Health, 0, maxHp)
           local pct = math.clamp(hp / maxHp, 0, 1)
           myHealthBar.Size = UDim2.new(pct, 0, 1, 0)
           myHpText.Text = math.round(hp) .. " / " .. math.round(maxHp) .. " HP"
           myHealthBar.BackgroundColor3 = pct < 0.25 and Color3.fromRGB(255, 132, 24) or pct < 0.5 and Color3.fromRGB(255, 205, 65) or Color3.fromRGB(104, 211, 57)
       end)
   end

   owner:Own(hum.HealthChanged:Connect(updateMyHp))
   owner:Own(hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateMyHp))
   updateMyHp()
end

local function bindMyHpCharacter(character)
   if not character then return end
   local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
   if hum and LocalPlayer.Character == character and character.Parent then
       bindMyHealth(hum, character)
   end
end

if LocalPlayer.Character then
   bindMyHpCharacter(LocalPlayer.Character)
end

trackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
   bindMyHpCharacter(character)
end))

trackConnection(LocalPlayer.CharacterRemoving:Connect(function(character)
   if myHpCharacter == character then
       stopMyHpOwner("character_removing")
   end
end))

end -- [/TAYJAY LOCAL-LIMIT FIX 2/8]
