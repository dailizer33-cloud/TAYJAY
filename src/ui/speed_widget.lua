-- =========================================================
-- ⚡ SPEED WIDGET
-- =========================================================
-- ไอคอน +/- วาดด้วยกรอบสี่เหลี่ยมมน (คมชัดทุกฟอนต์ ไม่พึ่งอีโมจิ)
function UI_LAYOUT.glyph(button, isPlus, color, length, thickness)
   local bar = Instance.new("Frame", button)
   bar.Name = "TayJayGlyph"; bar.AnchorPoint = Vector2.new(0.5, 0.5); bar.Position = UDim2.fromScale(0.5, 0.5)
   bar.Size = UDim2.fromOffset(length, thickness); bar.BackgroundColor3 = color; bar.BorderSizePixel = 0
   Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
   if isPlus then
      local bar2 = bar:Clone(); bar2.Size = UDim2.fromOffset(thickness, length); bar2.Parent = button
   end
end

local speedWidget = Instance.new("Frame", screenGui)
speedWidget.Name = "TayJaySpeedWidget"
speedWidget.AnchorPoint = Vector2.new(0, 1)
speedWidget.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, 64) -- อยู่เหนือกล่อง FLY ความกว้างเท่ากัน
speedWidget.Position = UDim2.new(UI_LAYOUT.FlyBottom.X.Scale, UI_LAYOUT.FlyBottom.X.Offset, UI_LAYOUT.FlyBottom.Y.Scale, UI_LAYOUT.FlyBottom.Y.Offset - UI_LAYOUT.FlyH)
speedWidget.BackgroundColor3 = GREEN.dark
speedWidget.BackgroundTransparency = 0.02
speedWidget.Visible = false
Instance.new("UICorner", speedWidget).CornerRadius = UDim.new(0, 16)
do -- [TAYJAY LOCAL-LIMIT FIX 3/8]
local speedWidgetStroke = Instance.new("UIStroke", speedWidget); speedWidgetStroke.Name = "TayJayWindowAccent"
speedWidgetStroke.Color = UI_LAYOUT.Accent.Speed
speedWidgetStroke.Thickness = 2.5
makeDraggable(speedWidget, false)

-- ซ้าย = ลบ, กลาง = ตัวเลขความเร็ว, ขวา = บวก (ครั้งละ SpeedStep)
local speedDownBtn = Instance.new("TextButton", speedWidget)
speedDownBtn.Name = "SpeedMinus"; speedDownBtn.Text = ""
speedDownBtn.AnchorPoint = Vector2.new(0, 0.5); speedDownBtn.Position = UDim2.new(0, 10, 0.5, 0)
speedDownBtn.Size = UDim2.fromOffset(46, 46); speedDownBtn.BackgroundColor3 = Color3.fromRGB(26, 41, 68)
speedDownBtn.AutoButtonColor = true; speedDownBtn.BorderSizePixel = 0
Instance.new("UICorner", speedDownBtn).CornerRadius = UDim.new(1, 0)
do
   local ring = Instance.new("UIStroke", speedDownBtn)
   ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Color = UI_LAYOUT.Accent.Speed; ring.Thickness = 2
end
UI_LAYOUT.glyph(speedDownBtn, false, UI_LAYOUT.Accent.Speed, 20, 5)

local speedValLabel = Instance.new("TextLabel", speedWidget)
speedValLabel.Name = "TayJaySpeedValue"
speedValLabel.Position = UDim2.fromOffset(60, 0); speedValLabel.Size = UDim2.new(1, -120, 1, 0)
speedValLabel.BackgroundTransparency = 1; speedValLabel.Text = tostring(config.WalkSpeed)
speedValLabel.Font = Enum.Font.GothamBlack; speedValLabel.TextSize = 32; speedValLabel.TextColor3 = WHITE_TEXT

local speedUpBtn = Instance.new("TextButton", speedWidget)
speedUpBtn.Name = "SpeedPlus"; speedUpBtn.Text = ""
speedUpBtn.AnchorPoint = Vector2.new(1, 0.5); speedUpBtn.Position = UDim2.new(1, -10, 0.5, 0)
speedUpBtn.Size = UDim2.fromOffset(46, 46); speedUpBtn.BackgroundColor3 = UI_LAYOUT.Accent.Speed
speedUpBtn.AutoButtonColor = true; speedUpBtn.BorderSizePixel = 0
Instance.new("UICorner", speedUpBtn).CornerRadius = UDim.new(1, 0)
UI_LAYOUT.glyph(speedUpBtn, true, Color3.fromRGB(10, 16, 32), 20, 5)

local function updateSpeedDisplay() speedValLabel.Text = tostring(config.WalkSpeed) end
trackConnection(speedUpBtn.Activated:Connect(function()
   config.WalkSpeed = math.min(config.WalkSpeed + UI_LAYOUT.SpeedStep, 500); updateSpeedDisplay()
end))
trackConnection(speedDownBtn.Activated:Connect(function()
   config.WalkSpeed = math.max(config.WalkSpeed - UI_LAYOUT.SpeedStep, UI_LAYOUT.SpeedStep); updateSpeedDisplay()
end))

