-- =========================================================
-- 👤 MY HP FRAME
-- =========================================================
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

local function bindMyHealth(hum)
   if not hum then return end
   local function updateMyHp()
       pcall(function()
           local hp = math.clamp(hum.Health, 0, hum.MaxHealth)
           local maxHp = hum.MaxHealth > 0 and hum.MaxHealth or 100
           local pct = hp / maxHp
           myHealthBar.Size = UDim2.new(pct, 0, 1, 0)
           myHpText.Text = math.round(hp) .. " / " .. math.round(maxHp) .. " HP"
           myHealthBar.BackgroundColor3 = pct < 0.25 and Color3.fromRGB(255, 132, 24) or pct < 0.5 and Color3.fromRGB(255, 205, 65) or Color3.fromRGB(104, 211, 57)
       end)
   end
   trackConnection(hum.HealthChanged:Connect(updateMyHp)); trackConnection(hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateMyHp)); updateMyHp()
end

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then bindMyHealth(LocalPlayer.Character:FindFirstChildOfClass("Humanoid")) end
trackConnection(LocalPlayer.CharacterAdded:Connect(function(char) local hum = char:WaitForChild("Humanoid", 10); if hum then bindMyHealth(hum) end end))

