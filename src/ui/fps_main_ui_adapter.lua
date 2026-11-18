-- =========================================================
-- FPS MAIN-UI INTEGRATION ADAPTER
-- Runs in the main script scope so main-menu locals stay explicit
-- and are not captured as undeclared globals by the isolated FPS task.
-- =========================================================
TJ.Main = TJ.Main or {}

-- Explicit dependency boundary for the isolated FPS task scope.
-- Keep this table limited to main-scope locals required by FPS.
TJ.Main.FPSContext = {
   Version = 1,
   newCleanupOwner = newCleanupOwner,
   newBag = newBag,
   ResourceManager = ResourceManager,
   SecureParentGui = SecureParentGui,
   UI_LAYOUT = UI_LAYOUT,
   GREEN = GREEN,
   WHITE_TEXT = WHITE_TEXT,
   applyTayJayTextContrast = applyTayJayTextContrast,
   Players = Players,
   RunService = RunService,
   UserInputService = UserInputService,
   Lighting = Lighting,
}
TJ.Main.IsWindowLocked = function()
   return _G.TAYJAY_UI ~= nil and _G.TAYJAY_UI.locked == true
end
TJ.Main.ApplyFPSMainUIAdapter = function(fpsGui, fpsPanel)
   if not fpsGui then return false end
   -- Apply the shared main-menu theme/layout pass from the main script scope.
   local function finishThemePass(guiRoot)
      for _, object in ipairs(guiRoot:GetDescendants()) do
         if not isProtectedMainBrandPart(object) then
            applyTayJayTextContrast(object)
            if object:IsA("TextButton") then
               object.TextWrapped = true
               object.AutoButtonColor = true
               if object.Name == "WindowLockButton" then
                  object.BackgroundColor3 = Color3.fromRGB(34, 92, 86)
               end
            elseif object:IsA("TextLabel") then
               object.TextWrapped = object.TextWrapped or false
            end
         end
      end
      local panelNames = {
         TayJayFlyControl=true, TayJaySpeedWidget=true, DeathNoteGroup=true, DeathNoteMain=true, TayJayMainMenu=true,
         TayJayMM2Dock=true, TayJayMM2PlayerList=true, FPSBoosterPanel=true,
         TayJayTargetPanel=true, TayJayServerSelector=true, TayJayMonsterTargetPanel=true,
      }
      for _, object in ipairs(guiRoot:GetDescendants()) do
         if object:IsA("Frame") and (panelNames[object.Name] or object == mainFrame) then
            local edge = object:FindFirstChildOfClass("UIStroke")
            if not edge then edge = Instance.new("UIStroke"); edge.Parent = object end
            edge.Color = GREEN.stroke
            edge.Thickness = 1.6
            local gradient = object:FindFirstChildOfClass("UIGradient")
            object.BackgroundColor3 = GREEN.dark
            if not gradient then gradient = Instance.new("UIGradient"); gradient.Parent = object end
            gradient.Color = ColorSequence.new({
               ColorSequenceKeypoint.new(0, GREEN.panel),
               ColorSequenceKeypoint.new(1, GREEN.dark),
            })
            gradient.Rotation = 90
         end
      end
   end
   finishThemePass(screenGui)
   finishThemePass(fpsGui)
   updateScreenScale()
   if makeDraggable and fpsPanel then pcall(function() makeDraggable(fpsPanel, false) end) end

   local function applyTayJayTextPass(guiRoot)
      if not guiRoot then return end
      for _, uiObject in ipairs(guiRoot:GetDescendants()) do
          applyTayJayTextContrast(uiObject)
      end
   end
   -- ย่อตัวหนังสือในหน้าต่าง FPS ให้พอดีกรอบ (TextScaled) โดยไม่ให้หลุดขอบ
   local function fitFpsText(obj)
      if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
      if obj:FindFirstChildOfClass("UITextSizeConstraint") then return end
      local maxSize = math.max(tonumber(obj.TextSize) or 14, 10)
      obj.TextScaled = true
      obj.TextWrapped = false
      obj.TextTruncate = Enum.TextTruncate.AtEnd
      local c = Instance.new("UITextSizeConstraint")
      c.MaxTextSize = maxSize
      c.MinTextSize = 9
      c.Parent = obj
   end
   local function fitFpsPanelText()
      for _, obj in ipairs(fpsGui:GetDescendants()) do fitFpsText(obj) end
   end
   
   -- 🔒 แถบล็อก: ล็อกหน้าต่างอยู่กับที่ (ปลดเพื่อลากด้วยการสัมผัส)
   do
       local lockGui = Instance.new("ScreenGui")
       lockGui.Name = "TayJayLockGui"; lockGui.ResetOnSpawn = false; lockGui.DisplayOrder = 1000
       lockGui.IgnoreGuiInset = true
       SecureParentGui(lockGui)
       local bar = Instance.new("Frame", lockGui)
       bar.Name = "TayJayLockBar"; bar.Size = UDim2.fromOffset(72, 44); bar.Position = UDim2.new(0, 12, 0.6, 0)
       bar.BackgroundColor3 = GREEN.deep; bar.BorderSizePixel = 0
       Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
       local barEdge = Instance.new("UIStroke", bar); barEdge.Color = UI_LAYOUT.Accent.Main; barEdge.Thickness = 1.5
       local lockBtn = Instance.new("TextButton", bar)
       lockBtn.Size = UDim2.fromOffset(60, 34); lockBtn.Position = UDim2.fromOffset(6, 5)
       lockBtn.BorderSizePixel = 0; lockBtn.Font = Enum.Font.GothamBold; lockBtn.TextSize = 13
       lockBtn.TextColor3 = WHITE_TEXT
       Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 8)
       local function refreshLock()
           local locked = _G.TAYJAY_UI.locked
           isWindowLocked = locked
           lockBtn.Text = locked and "🔒 ล็อก" or "🔓 ลาก"
           lockBtn.BackgroundColor3 = locked and Color3.fromRGB(255, 132, 24) or Color3.fromRGB(76, 158, 48)
       end
       lockBtn.Activated:Connect(function() _G.TAYJAY_UI.locked = not _G.TAYJAY_UI.locked; refreshLock() end)
       trackConnection(screenGui.DescendantAdded:Connect(function(o)
           if o:IsA("UIGradient") then o.Enabled = _G.TAYJAY_UI.effects == true end
       end))
       _G.TAYJAY_CLEAN_LOOK(screenGui)
       refreshLock()
   end
   
   applyTayJayTextPass(screenGui)
   -- ย่อตัวหนังสือทุกป้ายในหน้าต่างให้พอดีกรอบ (กันทับกัน) ยกเว้นโลโก้และปุ่มวงกลม
   do
       local SKIP = { KillAuraCircleBtn = true, KillAuraNormalBtn = true, TayJayMainToggle = true, TayJayBrandTitle = true, TayJayNoclipCircle = true }
       for _, obj in ipairs(screenGui:GetDescendants()) do
           if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not SKIP[obj.Name] and not obj:FindFirstAncestor("FPSBoosterPanel") and not obj:FindFirstAncestor("TayJayFlyControl") and not obj:FindFirstAncestor("TayJaySpeedWidget") and not obj:FindFirstChildOfClass("UITextSizeConstraint") then
               local maxSize = math.max(tonumber(obj.TextSize) or 13, 10)
               obj.TextScaled = true
               obj.TextWrapped = false
               obj.TextTruncate = Enum.TextTruncate.AtEnd
               local c = Instance.new("UITextSizeConstraint", obj)
               c.MaxTextSize = maxSize; c.MinTextSize = 9
           end
       end
   end
   applyTayJayTextPass(fpsGui)
   fitFpsPanelText()
   if _G.TAYJAY_CLEAN_LOOK then _G.TAYJAY_CLEAN_LOOK(fpsGui) end
   
   trackConnection(screenGui.DescendantAdded:Connect(function(uiObject)
      task.defer(function()
          if uiObject and uiObject.Parent then
              local dynamicStyle = TJ and TJ.Main and TJ.Main.ApplyDynamicStyle
              if type(dynamicStyle) == "function" then
                  pcall(dynamicStyle, uiObject)
              end
              applyTayJayTextContrast(uiObject)
          end
      end)
   end))
   trackConnection(fpsGui.DescendantAdded:Connect(function(uiObject)
      task.defer(function()
          if uiObject and uiObject.Parent then
              applyTayJayTextContrast(uiObject)
              fitFpsText(uiObject)
          end
      end)
   end))
   
   
   
   return true
end
