-- =========================================================
-- TAYJAY FPS BOOSTER V72
-- =========================================================
pcall(function()
   local previous = _G.TAYJAY_V70_PERF or _G.TAYJAY_V69_PERF
   if previous and previous.Cleanup then previous.Cleanup() end
end)

local originalFPSCap = 60
if type(getfpscap) == "function" then
   local capOk, capValue = pcall(getfpscap)
   if capOk and type(capValue) == "number" and capValue > 0 then
       originalFPSCap = capValue
   end
end

local V70Perf = {
   Alive = true, Enabled = false, Saved = {},
   MonitorConnections = {}, ContentConnections = {}, BoostConnections = {},
   FPS = 0, MinFPS = math.huge, MaxFPS = 0,
   SampleTotal = 0, SampleCount = 0, Ping = "N/A",
   GUI = nil, LastUIUpdate = 0, Samples = {}, ScanToken = 0,
   FrameWindowTime = 0, FrameWindowFrames = 0, EnforceRunning = false,
   CurrentPreset = "Potato",
   OriginalFPSCap = originalFPSCap, FPSUnlock = true, FPSUnlockStatus = "STARTING",
   Options = {Shadows = true, Particles = true, PostEffects = true,
       Reflections = true, Water = true, Decals = true, Lights = true}
}
_G.TAYJAY_V70_PERF = V70Perf

local v70RestoreAll
local v70RestoreFPSCap -- both callbacks must be forward-declared before FPS Owner creation

local V70Owner = newCleanupOwner("FPS", function()
    -- Isolate each restoration so one failure cannot skip the final state reset.
    local restoreAllOK, restoreAllErr = pcall(v70RestoreAll)
    if not restoreAllOK then
        warn("[TAYJAY FPS Owner] RestoreAll failed: " .. tostring(restoreAllErr))
    end

    local restoreCapOK, restoreCapErr = pcall(v70RestoreFPSCap)
    if not restoreCapOK then
        warn("[TAYJAY FPS Owner] RestoreFPSCap failed: " .. tostring(restoreCapErr))
    end

    V70Perf.Alive = false
end)
local V70MonitorBag, V70ContentBag, V70BoostBag = newBag(), newBag(), newBag()
V70Owner:OwnBag(V70MonitorBag)
V70Owner:OwnBag(V70ContentBag)
V70Owner:OwnBag(V70BoostBag)
assert(ResourceManager:RegisterOwner("FPS", V70Owner), "FPS owner registration failed")
V70Perf.Owner = V70Owner
V70Perf.MonitorBag, V70Perf.ContentBag, V70Perf.BoostBag = V70MonitorBag, V70ContentBag, V70BoostBag

local function v70Track(list, connection)
   table.insert(list, connection)
   local ownerBag = list == V70Perf.MonitorConnections and V70MonitorBag
       or list == V70Perf.ContentConnections and V70ContentBag
       or list == V70Perf.BoostConnections and V70BoostBag
   if ownerBag then ownerBag:Add(connection) end
   return connection
end

-- FPS unlock is controlled only by the FPS panel. ON requests the executor's
-- high cap; OFF restores the cap captured before this script changed it.
local function v70SetFPSUnlock(enabled)
   V70Perf.FPSUnlock = enabled == true
   if type(setfpscap) ~= "function" then
       V70Perf.FPSUnlockStatus = "UNAVAILABLE"
       warn("[TAYJAY FPS] setfpscap() is not supported by this executor.")
       return false
   end

   -- Request a very high cap; actual FPS remains limited by the game, executor and device.
   local targetCap = V70Perf.FPSUnlock and 9999 or (V70Perf.OriginalFPSCap or 60)
   local ok, err = pcall(setfpscap, targetCap)
   if not ok then
       V70Perf.FPSUnlockStatus = "FAILED"
       warn("[TAYJAY FPS] Could not apply FPS cap: " .. tostring(err))
       return false
   end

   V70Perf.FPSUnlockStatus = V70Perf.FPSUnlock and "ACTIVE" or "RESTORED"
   return true
end

v70RestoreFPSCap = function()
   if type(setfpscap) == "function" then
       pcall(setfpscap, V70Perf.OriginalFPSCap or 60)
   end
end

local function v70FPSUnlockApplied()
   return V70Perf.FPSUnlock == true and V70Perf.FPSUnlockStatus == "ACTIVE"
end

-- Default ON whenever the script starts.
v70SetFPSUnlock(true)

local function v70SaveSet(object, property, value)
   if not object then return end
   local ok, original = pcall(function() return object[property] end)
   if not ok then return end
   local saved = V70Perf.Saved[object]
   if not saved then saved = {}; V70Perf.Saved[object] = saved end
   if saved[property] == nil then saved[property] = original end
   if original ~= value then pcall(function() object[property] = value end) end
end

v70RestoreAll = function()
   V70Perf.ScanToken = V70Perf.ScanToken + 1
   V70Perf.Enabled = false
   V70BoostBag:Clean()
   V70BoostBag:Reset()
   table.clear(V70Perf.BoostConnections)
   for object, properties in pairs(V70Perf.Saved) do
       for property, originalValue in pairs(properties) do
           pcall(function() object[property] = originalValue end)
       end
   end
   table.clear(V70Perf.Saved)
end

local function v70IsCharacterPart(object)
   local current = object
   while current and current ~= workspace do
       if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then return true end
       current = current.Parent
   end
   return false
end

local function v70OptimizeVisual(object)
   if not V70Perf.Enabled or not object then return end
   local o = V70Perf.Options

   -- Filter by class and active option first; most map instances are skipped
   -- without walking their ancestor chain.
   local isPart = object:IsA("BasePart") and (o.Shadows or o.Reflections)
   local isParticle = o.Particles and (object:IsA("ParticleEmitter") or object:IsA("Trail")
       or object:IsA("Beam") or object:IsA("Fire") or object:IsA("Smoke")
       or object:IsA("Sparkles"))
   local isPostEffect = o.PostEffects and object:IsA("PostEffect")
   local isDecal = o.Decals and (object:IsA("Decal") or object:IsA("Texture"))
   local isLight = o.Lights and (object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight"))
   if not (isPart or isParticle or isPostEffect or isDecal or isLight) then return end
   if v70IsCharacterPart(object) then return end

   if isPart then
       if o.Shadows then v70SaveSet(object, "CastShadow", false) end
       if o.Reflections then
           local ok, reflectance = pcall(function() return object.Reflectance end)
           if ok and reflectance > 0 then v70SaveSet(object, "Reflectance", 0) end
       end
   elseif isParticle or isPostEffect or isLight then
       v70SaveSet(object, "Enabled", false)
   elseif isDecal then
       v70SaveSet(object, "Transparency", 1)
   end
end

local function v70ApplyOptions()
   v70RestoreAll()
   V70Perf.Enabled = true
   local scanToken = V70Perf.ScanToken
   local o = V70Perf.Options
   if o.Shadows then v70SaveSet(Lighting, "GlobalShadows", false) end
   if o.Water then
       local terrain = workspace:FindFirstChildOfClass("Terrain")
       if terrain then
           v70SaveSet(terrain, "Decoration", false)
           v70SaveSet(terrain, "WaterWaveSize", 0)
           v70SaveSet(terrain, "WaterWaveSpeed", 0)
           v70SaveSet(terrain, "WaterReflectance", 0)
       end
   end
   task.spawn(function()
       local processed = 0
       for _, root in ipairs({workspace, Lighting}) do
           for _, object in ipairs(root:GetDescendants()) do
               if not V70Perf.Alive or not V70Perf.Enabled or scanToken ~= V70Perf.ScanToken then return end
               v70OptimizeVisual(object)
               processed = processed + 1
               if processed % 100 == 0 then task.wait(0.025) end
           end
       end
   end)
   v70Track(V70Perf.BoostConnections, workspace.DescendantAdded:Connect(function(object)
       if V70Perf.Enabled then v70OptimizeVisual(object) end
   end))
   v70Track(V70Perf.BoostConnections, Lighting.DescendantAdded:Connect(function(object)
       if V70Perf.Enabled then v70OptimizeVisual(object) end
   end))

   -- Re-apply the selected profile periodically because some games rewrite visual properties.
   -- The scan is throttled and processed in batches to limit performance overhead.
   if not V70Perf.EnforceRunning then
       V70Perf.EnforceRunning = true
       task.spawn(function()
           while V70Perf.Alive do
               task.wait(5)
               if V70Perf.Alive and V70Perf.Enabled then
                   local activeOptions = V70Perf.Options
                   if activeOptions.Shadows then
                       v70SaveSet(Lighting, "GlobalShadows", false)
                   end
                   if activeOptions.Water then
                       local terrain = workspace:FindFirstChildOfClass("Terrain")
                       if terrain then
                           v70SaveSet(terrain, "Decoration", false)
                           v70SaveSet(terrain, "WaterWaveSize", 0)
                           v70SaveSet(terrain, "WaterWaveSpeed", 0)
                           v70SaveSet(terrain, "WaterReflectance", 0)
                       end
                   end
                   local processed = 0
                   for _, root in ipairs({workspace, Lighting}) do
                       for _, object in ipairs(root:GetDescendants()) do
                           if not V70Perf.Alive or not V70Perf.Enabled then break end
                           v70OptimizeVisual(object)
                           processed = processed + 1
                           if processed % 200 == 0 then task.wait(0.03) end
                       end
                       if not V70Perf.Alive or not V70Perf.Enabled then break end
                   end
               end
           end
           V70Perf.EnforceRunning = false
       end)
   end
end

local MODE_DEFS = {
    {name="Potato", detail="ปิดเอฟเฟกต์ทั้งหมดที่รองรับ เหมาะกับเครื่องอ่อนที่สุด", hold=0,
        opts={Shadows=true, Particles=true, PostEffects=true, Reflections=true, Water=true, Decals=true, Lights=true}},
    {name="Balanced", detail="ลดเงา เอฟเฟกต์ภาพ การสะท้อน และคลื่นน้ำ โดยคงอนุภาค เดคัล และไฟ", hold=0,
        opts={Shadows=true, Particles=false, PostEffects=true, Reflections=true, Water=true, Decals=false, Lights=false}},
    {name="Battle", detail="ปิดเงาและเอฟเฟกต์รบกวน ลดอนุภาคและเดคัล", hold=0,
        opts={Shadows=true, Particles=true, PostEffects=true, Reflections=true, Water=true, Decals=true, Lights=false}},
    {name="Stream-safe", detail="ค่ากลาง หน่วง 0.6 วินาทีหลังวาร์ปให้แมพโหลดทัน", hold=0.6,
        opts={Shadows=true, Particles=true, PostEffects=true, Reflections=true, Water=true, Decals=false, Lights=false}},
    {name="Quality", detail="คืนค่ากราฟิกเดิมทั้งหมด", hold=0, opts=nil},
}
local function v70SetPreset(name)
    local mode
    for _, m in ipairs(MODE_DEFS) do
        if m.name == name then mode = m end
    end
    if not mode then return end
    V70Perf.CurrentPreset = mode.name
    if not mode.opts then
        v70RestoreAll()
        V70Perf.Options = {Shadows=false, Particles=false, PostEffects=false, Reflections=false, Water=false, Decals=false, Lights=false}
        _G.TAYJAY_WARP_HOLD = 0
        return
    end
    for key, value in pairs(mode.opts) do V70Perf.Options[key] = value end
    _G.TAYJAY_WARP_HOLD = mode.hold or 0
    v70ApplyOptions()
end

local lowPresetStarted = pcall(function()
   v70SetPreset("Potato")
end)

local function v70ReadPing()
   local ok, item = pcall(function()
       return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
   end)
   if not ok or not item then return "N/A" end
   local okText, value = pcall(function() return item:GetValueString() end)
   if okText and value ~= nil then return tostring(value) end
   return "N/A"
end

local perfGui = Instance.new("ScreenGui")
perfGui.Name = "TayJay_FPS_Booster_V72"
perfGui.ResetOnSpawn = false
perfGui.IgnoreGuiInset = true
perfGui.DisplayOrder = 1000000
perfGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- FIXED: ใช้ SecureParentGui แทนการกำหนด guiParent โดยตรง
SecureParentGui(perfGui)

local function updatePerfScale()
   local camera = workspace.CurrentCamera
   if not camera then return end
   local viewport = camera.ViewportSize
   local scaleValue = math.clamp(math.min(viewport.X / 1200, viewport.Y / 820), 0.82, 0.92)
   for _, root in ipairs(perfGui:GetChildren()) do
       if root:IsA("GuiObject") then
           local scaleObject = root:FindFirstChild("TayJayPerfResponsiveScale")
           if not scaleObject then
               scaleObject = Instance.new("UIScale")
               scaleObject.Name = "TayJayPerfResponsiveScale"
               scaleObject.Parent = root
           end
           scaleObject.Scale = scaleValue
       end
   end
end
updatePerfScale()
if workspace.CurrentCamera then v70Track(V70Perf.MonitorConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePerfScale)) end
v70Track(V70Perf.MonitorConnections, perfGui.ChildAdded:Connect(function() task.defer(updatePerfScale) end))
V70Perf.GUI = perfGui
 V70Owner.Bag:Add(perfGui)

local function ui(className, props, parent)
   local obj = Instance.new(className)
   for key, value in pairs(props or {}) do pcall(function() obj[key] = value end) end
   obj.Parent = parent
   applyTayJayTextContrast(obj)
   return obj
end
local function corner(parent, radius)
   ui("UICorner", {CornerRadius=UDim.new(0, radius or 10)}, parent)
end
local function stroke(parent, color, thickness)
   ui("UIStroke", {Color=color, Thickness=thickness or 1.5, Transparency=0.08}, parent)
end

local panel = ui("Frame", {Name="FPSBoosterPanel", Size=UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH),
   Position=UI_LAYOUT.FPSPanel, BackgroundColor3=GREEN.dark,
   BorderSizePixel=0, Active=true, ClipsDescendants=true}, perfGui)
corner(panel, 16); stroke(panel, UI_LAYOUT.Accent.FPS, 2.5)
panel.Visible = false -- keep the game view clear; open from the floating launcher
local accent = Color3.fromRGB(104, 211, 57)
local muted = Color3.fromRGB(220, 231, 190)
local header = ui("Frame", {Size=UDim2.new(1,0,0,42), BackgroundColor3=Color3.fromRGB(16, 28, 45), BorderSizePixel=0}, panel)
ui("TextLabel", {Name="FPSTitle", Size=UDim2.new(1,-84,1,0), Position=UDim2.fromOffset(13,0), BackgroundTransparency=1,
   Text="⚡ TAYJAY FPS BOOSTER", TextColor3= WHITE_TEXT, Font=Enum.Font.GothamBold, TextSize=16,
   TextXAlignment=Enum.TextXAlignment.Left}, header)
local collapse = ui("TextButton", {Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-68,0,7),
   BackgroundColor3=Color3.fromRGB(92, 65, 24), Text="—", TextColor3= WHITE_TEXT,
   Font=Enum.Font.GothamBold, TextSize=18, BorderSizePixel=0}, header)
corner(collapse, 8)
local close = ui("TextButton", {Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-36,0,7),
   BackgroundColor3=Color3.fromRGB(92, 65, 24), Text="×", TextColor3= WHITE_TEXT,
   Font=Enum.Font.GothamBold, TextSize=20, BorderSizePixel=0}, header)
corner(close, 8)

local collapsed = false
local expandedSize = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH)
local collapsedSize = UDim2.fromOffset(UI_LAYOUT.PanelW, 42)
v70Track(V70Perf.MonitorConnections, close.Activated:Connect(function() panel.Visible = false end))

local search = ui("TextBox", {Size=UDim2.new(1,-20,0,30), Position=UDim2.fromOffset(10,49),
   BackgroundColor3=Color3.fromRGB(17,30,47), PlaceholderText="⌕  Search options...",
   PlaceholderColor3=muted, Text="", TextColor3= WHITE_TEXT, Font=Enum.Font.Gotham, TextSize=14,
   ClearTextOnFocus=false, BorderSizePixel=0}, panel)
corner(search, 8)
local tabs = ui("Frame", {Size=UDim2.new(1,-20,0,34), Position=UDim2.fromOffset(10,87),
   BackgroundTransparency=1}, panel)
local tabLayout = ui("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,
   Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, tabs)
local content = ui("ScrollingFrame", {Size=UDim2.new(1,-20,1,-134), Position=UDim2.fromOffset(10,127),
   BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
   ScrollBarImageColor3=accent, CanvasSize=UDim2.new()}, panel)
local contentLayout = ui("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, content)
v70Track(V70Perf.MonitorConnections, contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
   content.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 8)
end))

local currentTab = "FPS"
local statusLabel
local function clearContent()
   V70ContentBag:Clean()
   V70ContentBag:Reset()
   table.clear(V70Perf.ContentConnections)
   for _, child in ipairs(content:GetChildren()) do
       if not child:IsA("UIListLayout") then child:Destroy() end
   end
end
local function section(text)
   ui("TextLabel", {Size=UDim2.new(1,-4,0,22), BackgroundTransparency=1,
       Text=text, TextColor3= WHITE_TEXT, Font=Enum.Font.GothamBold,
       TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, content)
end
local function rowLabel(text, detail)
   local row = ui("Frame", {Size=UDim2.new(1,-4,0,50), BackgroundColor3=Color3.fromRGB(25, 52, 28), BorderSizePixel=0}, content)
   corner(row, 8)
   ui("TextLabel", {Size=UDim2.new(1,-12,0,20), Position=UDim2.fromOffset(9,3), BackgroundTransparency=1,
       Text=text, TextColor3= WHITE_TEXT, Font=Enum.Font.GothamBold, TextSize=14,
       TextXAlignment=Enum.TextXAlignment.Left}, row)
   if detail then ui("TextLabel", {Size=UDim2.new(1,-12,0,18), Position=UDim2.fromOffset(9,27),
       BackgroundTransparency=1, Text=detail, TextColor3= WHITE_TEXT, Font=Enum.Font.Gotham,
       TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row) end
   return row
end
local function actionButton(parent, text, width, callback)
   local b = ui("TextButton", {Size=UDim2.new(0,width,0,34), Position=UDim2.new(1,-width-8,0,7),
       BackgroundColor3=accent, Text=text, TextColor3= WHITE_TEXT, Font=Enum.Font.GothamBold,
       TextSize=13, BorderSizePixel=0}, parent)
   corner(b, 7)
   v70Track(V70Perf.ContentConnections, b.Activated:Connect(callback))
   return b
end
local function refreshTabButtons()
   for _, child in ipairs(tabs:GetChildren()) do
       if child:IsA("TextButton") then
           child.BackgroundColor3 = child.Name == currentTab and Color3.fromRGB(104, 211, 57) or Color3.fromRGB(25,52,28)
           child.TextColor3 = WHITE_TEXT
       end
   end
end
V70Perf.Pinned = V70Perf.Pinned or {}
local function buildCatalog()
    local list = {}
    local unlockUnavailable = V70Perf.FPSUnlockStatus == "UNAVAILABLE" or V70Perf.FPSUnlockStatus == "FAILED"
    table.insert(list, {id="fps:unlock", name="Unlock FPS",
        detail=unlockUnavailable and "Executor does not support the FPS cap command" or "ON requests 9999 FPS; OFF restores the previous cap",
        toggle=true, on=v70FPSUnlockApplied(),
        button=unlockUnavailable and "N/A" or (V70Perf.FPSUnlock and "ON" or "OFF"),
        run=function()
            local requested = not V70Perf.FPSUnlock
            v70SetFPSUnlock(requested)
            if statusLabel then
                statusLabel.Text = V70Perf.FPSUnlockStatus == "ACTIVE" and "FPS UNLOCK: ON"
                    or (V70Perf.FPSUnlockStatus == "RESTORED" and "FPS UNLOCK: OFF" or "FPS UNLOCK: NOT AVAILABLE")
            end
        end})
    for _, m in ipairs(MODE_DEFS) do
        table.insert(list, {id="mode:"..m.name, name=m.name, detail=m.detail,
            button=(m.name == "Quality") and "RESTORE" or "APPLY",
            run=function() v70SetPreset(m.name); statusLabel.Text = "PROFILE: " .. string.upper(m.name) end})
    end
    -- Graphics are changed only by selecting a preset in the FPS tab.
    table.insert(list, {id="action:restore", name="Restore original", detail="ยกเลิกการเปลี่ยนแปลงทั้งหมด",
        button="RESTORE", run=function() v70SetPreset("Quality"); statusLabel.Text = "PROFILE: RESTORED" end})
    return list
end
local function drawEntry(entry, refresh)
    local r = rowLabel(entry.name, entry.detail)
    for _, child in ipairs(r:GetChildren()) do
        if child:IsA("TextLabel") then child.Size = UDim2.new(1, -124, child.Size.Y.Scale, child.Size.Y.Offset) end
    end
    local pinned = V70Perf.Pinned[entry.id] == true
    local pinBtn = ui("TextButton", {Size=UDim2.new(0,34,0,34), Position=UDim2.new(1,-(8+64+6+34),0,7),
        BackgroundColor3 = pinned and Color3.fromRGB(255,211,58) or Color3.fromRGB(35,70,40),
        Text="📌", TextSize=13, Font=Enum.Font.GothamBold, TextColor3=WHITE_TEXT, BorderSizePixel=0}, r)
    corner(pinBtn, 7)
    v70Track(V70Perf.ContentConnections, pinBtn.Activated:Connect(function()
        if pinned then V70Perf.Pinned[entry.id] = nil else V70Perf.Pinned[entry.id] = true end
        refresh()
    end))
    local b = actionButton(r, entry.button, 64, function() entry.run(); refresh() end)
    if entry.toggle then b.BackgroundColor3 = entry.on and Color3.fromRGB(104, 211, 57) or Color3.fromRGB(166, 43, 38) end
    return r
end
local function renderSearch(query)
    clearContent()
    section("RESULTS")
    local count = 0
    for _, entry in ipairs(buildCatalog()) do
        -- Preset changes are intentionally available only in the FPS tab.
        if string.sub(entry.id, 1, 5) ~= "mode:" and string.find(string.lower(entry.name .. " " .. entry.detail), query, 1, true) then
            count = count + 1
            drawEntry(entry, function() renderSearch(query) end)
        end
    end
    if count == 0 then rowLabel("ไม่พบตัวเลือก", "ลองพิมพ์คำอื่น") end
    refreshTabButtons()
end

local function renderTab()
   clearContent()
   if currentTab == "FPS" then
       section("PERFORMANCE MONITOR")
       local metrics = rowLabel("FPS: --   |   AVG: --   |   MIN: --   |   MAX: --", "PING: --   •   Client frame-rate estimate")
       metrics.Name = "LiveMetrics"
       local unlockUnavailable = V70Perf.FPSUnlockStatus == "UNAVAILABLE" or V70Perf.FPSUnlockStatus == "FAILED"
       local unlockRow = rowLabel("UNLOCK FPS", unlockUnavailable and "Executor does not support setfpscap()" or "ขอเพดาน 9999 FPS • OFF จะคืนค่าเดิม")
       local unlockButton = actionButton(unlockRow, unlockUnavailable and "N/A" or (V70Perf.FPSUnlock and "ON" or "OFF"), 64, function()
           local requested = not V70Perf.FPSUnlock
           v70SetFPSUnlock(requested)
           renderTab()
           if statusLabel then
               statusLabel.Text = V70Perf.FPSUnlockStatus == "ACTIVE" and "PROFILE: BALANCED • FPS UNLOCK ON"
                   or (V70Perf.FPSUnlockStatus == "RESTORED" and "PROFILE: BALANCED • FPS UNLOCK OFF" or "FPS UNLOCK: NOT AVAILABLE")
           end
       end)
       unlockButton.BackgroundColor3 = v70FPSUnlockApplied() and Color3.fromRGB(104, 211, 57) or Color3.fromRGB(166, 43, 38)
       local graph = ui("Frame", {Size=UDim2.new(1,-4,0,58), BackgroundColor3=Color3.fromRGB(20, 42, 24), BorderSizePixel=0}, content)
       corner(graph, 8)
       local bars = {}
       for i=1,28 do
           bars[i] = ui("Frame", {AnchorPoint=Vector2.new(0,1), Position=UDim2.new((i-1)/28,2,1,-7),
               Size=UDim2.new(1/34,0,0,8), BackgroundColor3=Color3.fromRGB(255, 215, 55), BorderSizePixel=0}, graph)
           corner(bars[i], 3)
       end
       V70Perf.GraphBars = bars
       local pinnedEntries = {}
       for _, entry in ipairs(buildCatalog()) do if V70Perf.Pinned[entry.id] then table.insert(pinnedEntries, entry) end end
       if #pinnedEntries > 0 then
           section("PINNED")
           for _, entry in ipairs(pinnedEntries) do drawEntry(entry, function() renderTab() end) end
       end
       section("QUICK PRESET SELECTION")
       for _, entry in ipairs(buildCatalog()) do
           if string.sub(entry.id, 1, 5) == "mode:" then drawEntry(entry, function() renderTab() end) end
       end
   else
       section("ACTIVE GRAPHICS PROFILE")
       rowLabel("PROFILE: " .. string.upper(V70Perf.CurrentPreset or "POTATO"),
           "กราฟิกจะเปลี่ยนได้จากปุ่ม Preset ในแท็บ FPS เท่านั้น")
       rowLabel("PERSISTENT LOW GRAPHICS",
           "ระบบจะตรวจซ้ำเป็นช่วง ๆ เพื่อป้องกันเกมเขียนค่าเอฟเฟกต์กลับ")
       rowLabel("TO CHANGE PROFILE",
           "เปิดแท็บ FPS แล้วเลือก Potato / Balanced / Battle / Stream-safe / Quality")
   end
   refreshTabButtons()
end

for index, name in ipairs({"FPS", "GRAPHICS"}) do
   local b = ui("TextButton", {Name=name, Size=UDim2.new(1/2,-4,1,0),
       BackgroundColor3=Color3.fromRGB(17,30,47), Text=name, TextColor3= WHITE_TEXT,
       Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0, LayoutOrder=index}, tabs)
   corner(b, 7)
   v70Track(V70Perf.MonitorConnections, b.Activated:Connect(function()
       currentTab = name; renderTab()
   end))
end
statusLabel = ui("TextLabel", {Size=UDim2.new(1,-20,0,17), Position=UDim2.new(0,10,1,-19),
   BackgroundTransparency=1, Text=(lowPresetStarted and (v70FPSUnlockApplied() and "PROFILE: POTATO  •  FPS UNLOCK ON" or "PROFILE: POTATO  •  FPS UNLOCK N/A") or "PROFILE: POTATO  •  APPLY FAILED"), TextColor3= WHITE_TEXT,
   Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, panel)
local function setCollapsed(value)
   collapsed = value
   search.Visible = not value
   tabs.Visible = not value
   content.Visible = not value
   statusLabel.Visible = not value
   panel.Size = value and collapsedSize or expandedSize
   collapse.Text = value and "□" or "—"
end
v70Track(V70Perf.MonitorConnections, collapse.Activated:Connect(function() setCollapsed(not collapsed) end))

v70Track(V70Perf.MonitorConnections, search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(search.Text)
    if q == "" then renderTab() else renderSearch(q) end
end))

local launcher = ui("TextButton", {
   Name="TayJayFloatingLauncher", Size=UDim2.fromOffset(44,44),
   Position=UI_LAYOUT.FPSLauncher, BackgroundColor3=Color3.fromRGB(104,211,57),
   Text="⚡", TextColor3= WHITE_TEXT, Font=Enum.Font.GothamBlack, TextSize=23,
   BorderSizePixel=0, Active=true, AutoButtonColor=true
}, perfGui)
corner(launcher, 25); stroke(launcher, Color3.fromRGB(255, 231, 92), 2.5)
local launcherDragging, launcherDragStart, launcherStartPos = false, nil, nil
v70Track(V70Perf.MonitorConnections, launcher.InputBegan:Connect(function(input)
   if not _G.TAYJAY_UI.locked and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
       launcherDragging = true
       launcherDragStart = input.Position
       launcherStartPos = launcher.Position
   end
end))
v70Track(V70Perf.MonitorConnections, launcher.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
       launcherDragging = false
   end
end))
v70Track(V70Perf.MonitorConnections, UserInputService.InputChanged:Connect(function(input)
   if launcherDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
       local delta = input.Position - launcherDragStart
       launcher.Position = UDim2.new(launcherStartPos.X.Scale, launcherStartPos.X.Offset + delta.X,
           launcherStartPos.Y.Scale, launcherStartPos.Y.Offset + delta.Y)
   end
end))
v70Track(V70Perf.MonitorConnections, launcher.Activated:Connect(function()
   panel.Visible = not panel.Visible
   if panel.Visible then setCollapsed(false) end
end))

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
finishThemePass(perfGui)
updateScreenScale()

if makeDraggable then pcall(function() makeDraggable(panel, false) end) end

v70Track(V70Perf.MonitorConnections, RunService.Heartbeat:Connect(function(dt)
   if not V70Perf.Alive then return end
   if dt > 0 then
       V70Perf.FrameWindowTime = V70Perf.FrameWindowTime + dt
       V70Perf.FrameWindowFrames = V70Perf.FrameWindowFrames + 1
       if V70Perf.FrameWindowTime >= 0.25 then
           local instant = V70Perf.FrameWindowFrames / V70Perf.FrameWindowTime
           V70Perf.FPS = V70Perf.FPS == 0 and instant or (V70Perf.FPS * 0.70 + instant * 0.30)
           V70Perf.MinFPS = math.min(V70Perf.MinFPS, instant)
           V70Perf.MaxFPS = math.max(V70Perf.MaxFPS, instant)
           V70Perf.SampleTotal = V70Perf.SampleTotal + instant
           V70Perf.SampleCount = V70Perf.SampleCount + 1
           table.insert(V70Perf.Samples, math.clamp(instant, 0, 120))
           if #V70Perf.Samples > 28 then table.remove(V70Perf.Samples, 1) end
           V70Perf.FrameWindowTime = 0
           V70Perf.FrameWindowFrames = 0
       end
   end
   V70Perf.LastUIUpdate = V70Perf.LastUIUpdate + dt
   if V70Perf.LastUIUpdate >= 1 then
       V70Perf.Ping = v70ReadPing()
       local avg = V70Perf.SampleCount > 0 and V70Perf.SampleTotal / V70Perf.SampleCount or 0
       local metrics = content:FindFirstChild("LiveMetrics")
       if metrics then
           local labels = metrics:GetChildren()
           for _, label in ipairs(labels) do
               if label:IsA("TextLabel") then
                   if label.Position.Y.Offset < 20 then
                       label.Text = string.format("FPS: %.0f   |   AVG: %.0f   |   MIN: %.0f   |   MAX: %.0f", V70Perf.FPS, avg, V70Perf.MinFPS == math.huge and 0 or V70Perf.MinFPS, V70Perf.MaxFPS)
                   else label.Text = "PING: " .. V70Perf.Ping .. "   •   Client frame-rate estimate" end
               end
           end
       end
       if V70Perf.GraphBars then
           for i, bar in ipairs(V70Perf.GraphBars) do
               local value = V70Perf.Samples[i] or 0
               bar.Size = UDim2.new(1/34,0,0,math.clamp(value/120*42,3,42))
           end
       end
       V70Perf.LastUIUpdate = 0
   end
end))

function V70Perf.Cleanup()
   if not V70Perf.Alive then return false end
   local stopped = ResourceManager:StopOwner("FPS")
   table.clear(V70Perf.MonitorConnections)
   table.clear(V70Perf.ContentConnections)
   table.clear(V70Perf.BoostConnections)
   V70Perf.GUI = nil
   V70Perf.GraphBars = nil
   if _G.TAYJAY_V70_PERF == V70Perf then _G.TAYJAY_V70_PERF = nil end
   return stopped
end

renderTab()
statusLabel.Text = "PROFILE: BALANCED  •  " .. (v70FPSUnlockApplied() and "FPS UNLOCK ON" or "FPS UNLOCK N/A") .. "  •  FLOATING UI READY"
print("[TAYJAY V72 FPS BOOSTER] Dashboard ready | Collapsible + Floating Launcher")

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
   for _, obj in ipairs(perfGui:GetDescendants()) do fitFpsText(obj) end
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
applyTayJayTextPass(perfGui)
fitFpsPanelText()
if _G.TAYJAY_CLEAN_LOOK then _G.TAYJAY_CLEAN_LOOK(perfGui) end

trackConnection(screenGui.DescendantAdded:Connect(function(uiObject)
   task.defer(function()
       if uiObject and uiObject.Parent then
           -- styleDynamicObject is local to the theme init scope; use the exported callback.
           local applyStyle = TJ.Main.ApplyDynamicStyle
           if type(applyStyle) == "function" then applyStyle(uiObject) end
           applyTayJayTextContrast(uiObject)
       end
   end)
end))
trackConnection(perfGui.DescendantAdded:Connect(function(uiObject)
   task.defer(function()
       if uiObject and uiObject.Parent then
           applyTayJayTextContrast(uiObject)
           fitFpsText(uiObject)
       end
   end)
end))


