-- TAYJAY EARLY BOOTSTRAP: visible before game loading / PlayerGui waits.
local _tjBootGui, _tjBootLabel
local function _tjAttachBootGui()
    if _tjBootGui and _tjBootGui.Parent then return true end
    local parents = {}
    local function addParent(parent)
        if parent then
            for _, existing in ipairs(parents) do
                if existing == parent then return end
            end
            table.insert(parents, parent)
        end
    end
    pcall(function()
        if type(gethui) == "function" then addParent(gethui()) end
    end)
    pcall(function() addParent(game:GetService("CoreGui")) end)
    pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
        addParent(playerGui)
    end)
    for _, parent in ipairs(parents) do
        local ok = pcall(function() _tjBootGui.Parent = parent end)
        if ok and _tjBootGui.Parent == parent then return true end
    end
    return false
end

local function _tjShowDiagnostic(state, message)
    local isError = state == "ERROR"
    local body = tostring(message or "")
    pcall(function()
        if not _tjBootGui then
            _tjBootGui = Instance.new("ScreenGui")
            _tjBootGui.Name = "TayJay_IndependentStartupStatus"
            _tjBootGui.ResetOnSpawn = false
            _tjBootGui.IgnoreGuiInset = true
            _tjBootGui.DisplayOrder = 1000000
            _tjBootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            _tjBootLabel = Instance.new("TextLabel")
            _tjBootLabel.Name = "Status"
            _tjBootLabel.Size = UDim2.new(1, -16, 0, 58)
            _tjBootLabel.Position = UDim2.new(0, 8, 0, 8)
            _tjBootLabel.BackgroundColor3 = Color3.fromRGB(28, 38, 54)
            _tjBootLabel.BackgroundTransparency = 0.06
            _tjBootLabel.BorderSizePixel = 0
            _tjBootLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            _tjBootLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            _tjBootLabel.TextStrokeTransparency = 0.25
            _tjBootLabel.Font = Enum.Font.GothamBold
            _tjBootLabel.TextSize = 13
            _tjBootLabel.TextWrapped = true
            _tjBootLabel.TextXAlignment = Enum.TextXAlignment.Left
            _tjBootLabel.TextYAlignment = Enum.TextYAlignment.Center
            _tjBootLabel.ZIndex = 10000
            _tjBootLabel.Parent = _tjBootGui
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = _tjBootLabel
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.fromRGB(80, 210, 235)
            outline.Thickness = 1.5
            outline.Parent = _tjBootLabel
        end
        _tjAttachBootGui()
        if _tjBootLabel then
            _tjBootLabel.BackgroundColor3 = isError and Color3.fromRGB(105, 32, 35) or Color3.fromRGB(28, 38, 54)
            local outline = _tjBootLabel:FindFirstChildOfClass("UIStroke")
            if outline then outline.Color = isError and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(80, 210, 235) end
            _tjBootLabel.Text = isError
                and ("TAYJAY ERROR\n" .. string.sub(body, 1, 500))
                or ("TAYJAY " .. tostring(state) .. "\n" .. string.sub(body, 1, 260))
        end
    end)

    -- Retry GUI parenting while PlayerGui becomes available; notification is a fallback.
    pcall(function()
        task.spawn(function()
            for _ = 1, 12 do
                if _tjBootGui and _tjBootGui.Parent then break end
                pcall(_tjAttachBootGui)
                task.wait(0.5)
            end
        end)
    end)
    if state == "STARTING" or state == "ERROR" or state == "READY" then
        pcall(function()
            task.spawn(function()
                local starter = game:GetService("StarterGui")
                for _ = 1, 10 do
                    local ok = pcall(function()
                        starter:SetCore("SendNotification", {
                            Title = isError and "TAYJAY SCRIPT ERROR" or "TAYJAY",
                            Text = string.sub(body ~= "" and body or tostring(state), 1, 180),
                            Duration = isError and 10 or 5
                        })
                    end)
                    if ok then break end
                    task.wait(0.5)
                end
            end)
        end)
    end
    if state == "READY" then
        pcall(function()
            task.delay(12, function()
                if _tjBootGui and _tjBootGui.Parent then _tjBootGui:Destroy() end
                _tjBootGui, _tjBootLabel = nil, nil
            end)
        end)
    end
end

_G.TAYJAY_DIAGNOSTIC = _tjShowDiagnostic
pcall(function() _tjShowDiagnostic("STARTING", "ไฟล์ถูกเรียกใช้งานแล้ว • กำลังเริ่มระบบ...") end)

-- Capture asynchronous Roblox/Luau errors as well as errors caught by xpcall below.
local _tjLogConnection
pcall(function()
    local logService = game:GetService("LogService")
    _tjLogConnection = logService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            pcall(function() _tjShowDiagnostic("ERROR", message) end)
        end
    end)
    task.delay(120, function()
        if _tjLogConnection then
            pcall(function() _tjLogConnection:Disconnect() end)
            _tjLogConnection = nil
        end
    end)
end)

-- Catch synchronous startup failures and keep the error visible on-screen.
local _tjRunOK, _tjRunError = xpcall(function()
-- TAYJAY STARTUP DIAGNOSTIC: must be the first executable statement.
print("[TAYJAY BOOT] File entered; startup sequence begins.")

print("[TAYJAY SHADOW HUNTER + DEATH NOTE WARP] Starting initialization...")
if not game:IsLoaded() then 
   pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.1); LocalPlayer = Players.LocalPlayer end
local PlaceId = game.PlaceId

-- =========================================================
-- 🔴 100% BULLETPROOF GUI PARENTING
-- =========================================================
local guiName = "TayJay_DeltaMenu_V70_Pastel"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function SecureParentGui(gui)
   local parents = {}
   pcall(function()
       if type(gethui) == "function" then
           local hidden = gethui()
           if hidden then table.insert(parents, hidden) end
       end
   end)
   table.insert(parents, CoreGui)
   local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
       or LocalPlayer:WaitForChild("PlayerGui", 10)
   if playerGui then table.insert(parents, playerGui) end

   for _, parent in ipairs(parents) do
       local ok = pcall(function() gui.Parent = parent end)
       if ok and gui.Parent == parent then
           return true
       end
   end
   warn("[TAYJAY] FATAL: Could not parent GUI securely!")
   return false
end

-- ล้าง GUI เก่าออกก่อนสร้างใหม่
pcall(function()
   local targets = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
   pcall(function() if gethui then table.insert(targets, gethui()) end end)
   for _, parentObj in ipairs(targets) do
       if parentObj then
           for _, v in pairs(parentObj:GetChildren()) do
               if v.Name == guiName
                   or v.Name == "TayJay_DeltaMenu_V68_Pastel"
                   or v.Name == "TayJay_DeltaMenu_V69_Pastel"
                   or v.Name == "TayJay_FPS_Booster_V72" or v.Name == "TayJayLockGui" or v.Name == "TayJayControlGui" then
                   pcall(function() v:Destroy() end)
               end
           end
       end
   end
end)

SecureParentGui(screenGui)

-- Startup UI is intentionally independent from the main menu ScreenGui.
-- If the main GUI fails to parent, this separate banner can still report why.
-- Declare connection tracking before any startup code uses it.
-- Previously this helper was declared below the first calls, which caused
-- an attempt to call a nil global and stopped the script before the menu appeared.
local activeConnections = {}
local shutdownHooks = {}
local function registerShutdownHook(callback)
   if type(callback) == "function" then table.insert(shutdownHooks, callback) end
end
local function trackConnection(conn)
   if conn then table.insert(activeConnections, conn) end
   return conn
end

local function updateScreenScale()
   local camera = workspace.CurrentCamera
   if not camera then return end
   local viewport = camera.ViewportSize
   local scaleValue = math.clamp(math.min(viewport.X / 1200, viewport.Y / 820), 0.82, 0.92)
   for _, root in ipairs(screenGui:GetChildren()) do
       if root:IsA("GuiObject") then
           local scaleObject = root:FindFirstChild("TayJayResponsiveScale")
           if not scaleObject then
               scaleObject = Instance.new("UIScale")
               scaleObject.Name = "TayJayResponsiveScale"
               scaleObject.Parent = root
           end
           local isPrimaryUI = root.Name == "TayJayMainMenu" or root.Name == "TayJayMainToggle"
           scaleObject.Scale = scaleValue * (isPrimaryUI and 1 or 0.9)
       end
   end
end

-- =========================================================
-- CORE UTILS & STATE MANAGEMENT
-- =========================================================

local WHITE_TEXT = Color3.fromRGB(255, 255, 255)
local TEXT_OUTLINE = Color3.fromRGB(0, 0, 0)
-- ชิ้นส่วนที่ต้องคงขนาด/สไตล์ของตัวเอง (โลโก้, ปุ่มเมนูหลัก, ปุ่ม WARP/WALK)
-- ไม่ให้ระบบปรับตัวอักษรอัตโนมัติ (จำกัดไว้ที่ 19px) มาย่อให้เล็กลง
local PROTECTED_BRAND_NAMES = {
   TayJayBrandTitle = true,
   TayJayMainToggle = true,
   TayJayToggleLogoDisc = true,
   TayJayToggleLogo = true,
   TayJayNoclipCircle = true,
   TayJaySpeedWidget = true,
   TayJayFlyControl = true,
   KillAuraCircleBtn = true,
   KillAuraNormalBtn = true,
   TayJayMonsterWarpBtn = true,
}
local function isProtectedMainBrandPart(obj)
   if not obj then return false end
   if PROTECTED_BRAND_NAMES[obj.Name] == true then return true end
   local parent = obj.Parent
   while parent do
       if PROTECTED_BRAND_NAMES[parent.Name] == true then return true end
       parent = parent.Parent
   end
   return false
end

local function hasReadableText(value)
   local content = tostring(value or "")
   if content:find("[%a%d]") then return true end
   local hasThai = false
   if utf8 and utf8.codes then
       pcall(function()
           for _, codepoint in utf8.codes(content) do
               if codepoint >= 0x0E00 and codepoint <= 0x0E7F then
                   hasThai = true
                   break
               end
           end
       end)
   end
   return hasThai
end

local function applyTayJayTextContrast(obj)
   if not obj or isProtectedMainBrandPart(obj) then return end
   if obj.Name == "MM2RoleText" or obj.Name == "RoleLabel" then
       obj.TextStrokeColor3 = TEXT_OUTLINE
       obj.TextStrokeTransparency = 0.48
       return
   end
   if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
       obj.TextColor3 = WHITE_TEXT
       obj.TextStrokeColor3 = TEXT_OUTLINE
       obj.TextStrokeTransparency = 0.48
       obj.Font = Enum.Font.GothamBold

       local readable = obj:IsA("TextBox") or hasReadableText(obj.Text)
       -- หน้าต่าง FPS Booster มีขนาดตายตัว จึงไม่ให้ระบบเพิ่มขนาดตัวอักษรซ้ำ (ทำให้ล้นกรอบ)
       if readable and not obj:FindFirstAncestor("FPSBoosterPanel") then
           local baseSize = tonumber(obj.TextSize) or 14
           obj.TextScaled = true -- ย่อให้พอดีกรอบ ไม่ขยายจนทับกัน
           if not obj:FindFirstChildOfClass("UITextSizeConstraint") then
               local fit = Instance.new("UITextSizeConstraint", obj)
               fit.MaxTextSize = math.clamp(baseSize, 10, 18)
               fit.MinTextSize = 9
           end
       end

       if obj:IsA("TextBox") then
           obj.PlaceholderColor3 = Color3.fromRGB(245, 248, 255)
       end
   end
end
if workspace.CurrentCamera then
   trackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreenScale))
end
trackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
   task.defer(updateScreenScale)
end))
trackConnection(screenGui.ChildAdded:Connect(function()
   task.defer(updateScreenScale)
end))

local GREEN = {
   deep = Color3.fromRGB(15, 26, 44),       
   dark = Color3.fromRGB(23, 39, 60),       
   panel = Color3.fromRGB(34, 57, 82),      
   mid = Color3.fromRGB(255, 151, 66),      
   emerald = Color3.fromRGB(42, 184, 132),  
   bright = Color3.fromRGB(48, 201, 224),   
   neon = Color3.fromRGB(72, 222, 242),     
   pale = Color3.fromRGB(232, 244, 255),    
   ink = Color3.fromRGB(255, 255, 255),     
   stroke = Color3.fromRGB(73, 211, 235),   
   off = Color3.fromRGB(198, 88, 58),       
   on = Color3.fromRGB(39, 174, 119),       
   warning = Color3.fromRGB(255, 190, 68),  
}

local config = { WalkSpeed = 16 }
local originalWalkSpeed = nil
local isBusy = false 
local states = {
   Speed = false, Fly = false, InfJump = false, Noclip = false, 
   Xray = false, ESP = true, DeathNote = false, KillAura = false, NormalKillAura = false, MonsterWarp = false,
   ServerSelector = false, MM2RoleESP = false, AutoWarp = false, DNWarp = false
}

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

-- =========================================================
-- 🔒 UI CONTROL: ล็อกตำแหน่งหน้าต่าง / ปิดเอฟเฟกต์ภาพ
-- locked = true: หน้าต่างอยู่กับที่ (ปลดเพื่อลากด้วยการสัมผัส)
-- effects = false: ไม่มีแสง สีไล่ระดับ การกระพริบ หรือแอนิเมชัน
-- =====================================================================
_G.TAYJAY_UI = { locked = true, effects = false }
_G.TAYJAY_CLEAN_LOOK = function(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UIGradient") then obj.Enabled = _G.TAYJAY_UI.effects == true end
        if obj:IsA("UIStroke") and obj.Thickness > 2 then obj.Thickness = 1.6 end
    end
end

-- =========================================================
-- 🚫 BLACKLIST: รายชื่อผู้เล่นที่ WARP จะไม่เลือกเป็นเป้าหมาย
-- ใส่ Username ในรายการด้านล่างได้เลย (ไม่สนตัวพิมพ์เล็ก-ใหญ่)
-- หรือกดปุ่ม "ข้าม" ในสมุดสั่งตาย ระบบจะเพิ่ม/ลบชื่อให้เอง
-- ถ้า executor รองรับ writefile ระบบจะบันทึกลงไฟล์ TAYJAY_blacklist.json
-- =========================================================
_G.TAYJAY_BLACKLIST_DEFAULT = {
   -- "ตัวอย่างชื่อ1", "ตัวอย่างชื่อ2",
}
_G.TAYJAY_BL = {}
do
   local HttpService = game:GetService("HttpService")
   local FILE = "TAYJAY_blacklist.json"
   local names = {} -- key = ชื่อตัวพิมพ์เล็ก, value = ชื่อที่บันทึกไว้
   local BL = _G.TAYJAY_BL

   function BL.has(name)
       return name ~= nil and names[string.lower(name)] ~= nil
   end

   function BL.list()
       local out = {}
       for _, original in pairs(names) do table.insert(out, original) end
       table.sort(out, function(a, b) return string.lower(a) < string.lower(b) end)
       return out
   end

   function BL.save()
       pcall(function()
           if writefile then writefile(FILE, HttpService:JSONEncode(BL.list())) end
       end)
   end

   function BL.set(name, on)
       if not name then return end
       local key = string.lower(name)
       if on then names[key] = name else names[key] = nil end
       BL.save()
   end

   for _, name in ipairs(_G.TAYJAY_BLACKLIST_DEFAULT) do names[string.lower(name)] = name end
   pcall(function()
       if readfile and isfile and isfile(FILE) then
           for _, name in ipairs(HttpService:JSONDecode(readfile(FILE))) do names[string.lower(name)] = name end
       end
   end)
   print("[TAYJAY] Blacklist loaded: " .. #BL.list() .. " ชื่อ")
end

-- =========================================================
-- 📐 DEFAULT UI LAYOUT  (ตำแหน่งเริ่มต้นหลังกดรันสคริปต์)
-- วัดจากภาพหน้าจอจริง เก็บเป็นสัดส่วนหน้าจอ (0-1) ให้ตรงกันทุกความละเอียด
-- อยากขยับ UI ไหน แก้เลขตรงนี้ที่เดียว
--   X = ซ้าย→ขวา , Y = บน→ล่าง
-- =========================================================
local UI_LAYOUT = {
   MainMenu     = UDim2.fromScale(0.1030, 0.1960), -- เมนูหลัก TAYJAY (ตำแหน่งตามภาพอ้างอิง)
   PlayerList   = UDim2.fromScale(0.3000, 0.5670), -- ตารางผู้เล่นช่วงล่างค่อนไปทางกลางเพื่อไม่ชนเมนูหลักที่ขยาย
   TargetPanel  = UDim2.fromScale(0.3219, 0.8370), -- กรอบ Select target / TARGET (ย้ายลงให้พ้นตารางผู้เล่นที่สูงขึ้น)
   FlyBottom    = UDim2.fromScale(0.6387, 0.9921), -- กรอบ FLY CONTROL (AnchorPoint 0,1 = มุมซ้ายล่าง)
   WarpCenter   = UDim2.fromScale(0.1728, 0.6150), -- ปุ่มวงกลม WARP เดิมสำหรับผู้เล่น
   WalkCenter   = UDim2.fromScale(0.2389, 0.6978), -- ปุ่มวงกลม WALK เดิม
   MonsterWarpCenter = UDim2.fromScale(0.3020, 0.6150), -- ปุ่ม WARP แยกสำหรับ Monster
   MonsterTargetPanel = UDim2.fromScale(0.5600, 0.8370), -- สถานะ Monster Warp แยกจาก Target ผู้เล่น
   MM2Dock      = UDim2.fromScale(0.8350, 0.4630), -- กรอบปุ่มดาบ/สมุด (MM2)
   PanelW       = 224, -- ความกว้างมาตรฐานของหน้าต่างรอง
    MainW        = 286, -- เมนู TAYJAY กว้างขึ้นเพื่อแสดงคำสั่งครบในหน้าเดียว
    MainH        = 400, -- ความสูงสำหรับปุ่มคำสั่งทั้ง 7 รายการ
   FlyH         = 224, -- ความสูงกล่อง FLY (ดีไซน์ใหม่)
   NoclipCenter = UDim2.fromScale(0.1000, 0.7000), -- ปุ่มวงกลม NOCLIP (AnchorPoint 0.5,0.5 = จุดกึ่งกลาง)
   SpeedStep    = 2, -- ปุ่มบวก/ลบความเร็วเดิน ครั้งละกี่หน่วย
   PanelH       = 300, -- ความสูงมาตรฐานของหน้าต่างใหญ่ (เมนู/รายชื่อ/FPS)
   -- สีประจำแต่ละหน้าต่าง (ขอบและไฮไลต์) ปรับได้ที่นี่
   Accent = {
       Main = Color3.fromRGB(73, 211, 235),  -- TAYJAY เมนูหลัก: ฟ้าไซเบอร์
       Players = Color3.fromRGB(168, 120, 255), -- ผู้เล่นทั้งหมด: ม่วง
       Target = Color3.fromRGB(255, 96, 132),  -- เป้าหมาย: ชมพูแดง
       Noclip = Color3.fromRGB(255, 130, 60),  -- NOCLIP: อำพัน
      Speed   = Color3.fromRGB(255, 211, 58),  -- SPEED: เหลืองทอง
       Fly = Color3.fromRGB(72, 230, 186),  -- FLY: มิ้นต์
       FPS = Color3.fromRGB(150, 235, 80),  -- FPS BOOSTER: เขียวมะนาว
       Server = Color3.fromRGB(90, 170, 255),  -- หาเซิร์ฟว่าง: ฟ้าน้ำเงิน
       Stay    = Color3.fromRGB(72, 222, 242),  -- ปุ่ม WARP ไป (ไม่กลับ): ฟ้าอ่อน
   },
   FPSPanel     = UDim2.fromScale(0.8400, 0.0120), -- กรอบ TAYJAY FPS BOOSTER มุมขวาบน
   FPSLauncher  = UDim2.fromScale(0.0140, 0.3050), -- ปุ่ม ⚡ เปิด/ปิด FPS Booster ฝั่งซ้าย
   ToggleSize   = 68,  -- เส้นผ่านศูนย์กลางปุ่ม ⚡ เมนูหลัก (เดิม 48)
   ActionSize   = 66,  -- ลดปุ่ม WARP / WALK ลงเล็กน้อย
   NoclipSize   = 72,  -- คงขนาดปุ่ม NOCLIP เดิม
}

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
speedWidget.Position = UDim2.new(UI_LAYOUT.FlyBottom.X.Scale, UI_LAYOUT.FlyBottom.X.Offset, UI_LAYOUT.FlyBottom.Y.Scale, UI_LAYOUT.FlyBottom.Y.Offset - UI_LAYOUT.FlyH - 8)
speedWidget.BackgroundColor3 = GREEN.dark
speedWidget.BackgroundTransparency = 0.02
speedWidget.Visible = false
Instance.new("UICorner", speedWidget).CornerRadius = UDim.new(0, 16)
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

-- 👻 NOCLIP: ปุ่มวงกลมลอย (แยกออกจากความเร็ว) กดเปิด/กดปิด ลากย้ายได้เมื่อปลดล็อก
do
   local noclipCircle = Instance.new("TextButton", screenGui)
   noclipCircle.Name = "TayJayNoclipCircle"
   noclipCircle.AnchorPoint = Vector2.new(0.5, 0.5)
   noclipCircle.Size = UDim2.fromOffset(UI_LAYOUT.NoclipSize, UI_LAYOUT.NoclipSize)
   noclipCircle.Position = UI_LAYOUT.NoclipCenter
   noclipCircle.RichText = true; noclipCircle.Font = Enum.Font.GothamBlack
   noclipCircle.TextSize = 14; noclipCircle.TextColor3 = WHITE_TEXT
   noclipCircle.AutoButtonColor = true; noclipCircle.Active = true
   Instance.new("UICorner", noclipCircle).CornerRadius = UDim.new(1, 0)
   local ring = Instance.new("UIStroke", noclipCircle)
   ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Color = UI_LAYOUT.Accent.Noclip; ring.Thickness = 3
   makeDraggable(noclipCircle)
   local function refresh()
      local on = states.Noclip == true
      noclipCircle.BackgroundColor3 = on and GREEN.on or GREEN.off
      noclipCircle.Text = '<font size="26">👻</font>\n<font size="13">NOCLIP</font>\n<font size="11">' .. (on and "ON" or "OFF") .. '</font>'
   end
   refresh()
   trackConnection(noclipCircle.Activated:Connect(function() syncButtonState("Noclip", not states.Noclip) end))
   registerUiSync("Noclip", refresh)
end

-- =========================================================
-- 🕊️ FLY WIDGET
-- =========================================================
local FlyFrame = Instance.new("Frame", screenGui)
FlyFrame.Name = "TayJayFlyControl"
FlyFrame.BackgroundColor3 = GREEN.dark
FlyFrame.BackgroundTransparency = 0.02
FlyFrame.AnchorPoint = Vector2.new(0, 1)
FlyFrame.Position = UI_LAYOUT.FlyBottom
FlyFrame.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.FlyH)
FlyFrame.Active = true
FlyFrame.Visible = false
FlyFrame.ClipsDescendants = true
Instance.new("UICorner", FlyFrame).CornerRadius = UDim.new(0, 16)
local flyFrameStroke = Instance.new("UIStroke", FlyFrame); flyFrameStroke.Name = "TayJayWindowAccent"
flyFrameStroke.Color = UI_LAYOUT.Accent.Fly
flyFrameStroke.Thickness = 2.5
makeDraggable(FlyFrame)

-- ดีไซน์ใหม่: หัวข้อ + ป้ายสถานะ, ปุ่มบินใหญ่, ปุ่มขึ้น/ลงใหญ่, แถวปรับความเร็ว, ปุ่มหยุดฉุกเฉิน
local flyUi = {
   accent = UI_LAYOUT.Accent.Fly,
   navy = Color3.fromRGB(26, 41, 68),
   ink = Color3.fromRGB(10, 16, 32),
   muted = Color3.fromRGB(159, 176, 200),
}
function flyUi.button(name, pos, size, bg, text, textSize, textColor)
   local b = Instance.new("TextButton", FlyFrame)
   b.Name = name; b.Position = pos; b.Size = size
   b.BackgroundColor3 = bg; b.Text = text; b.TextSize = textSize
   b.TextColor3 = textColor or WHITE_TEXT; b.Font = Enum.Font.GothamBold
   b.AutoButtonColor = true; b.BorderSizePixel = 0
   Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
   return b
end
do
   local title = Instance.new("TextLabel", FlyFrame)
   title.Name = "FlyTitle"; title.BackgroundTransparency = 1
   title.Position = UDim2.fromOffset(12, 8); title.Size = UDim2.fromOffset(60, 24)
   title.Font = Enum.Font.GothamBlack; title.Text = "FLY"; title.TextSize = 17
   title.TextColor3 = flyUi.accent; title.TextXAlignment = Enum.TextXAlignment.Left
   flyUi.pill = Instance.new("Frame", FlyFrame)
   flyUi.pill.Name = "FlyPill"; flyUi.pill.Position = UDim2.new(1, -112, 0, 10)
   flyUi.pill.Size = UDim2.fromOffset(76, 22); flyUi.pill.BorderSizePixel = 0
   Instance.new("UICorner", flyUi.pill).CornerRadius = UDim.new(1, 0)
   flyUi.pillText = Instance.new("TextLabel", flyUi.pill)
   flyUi.pillText.Size = UDim2.fromScale(1, 1); flyUi.pillText.BackgroundTransparency = 1
   flyUi.pillText.Font = Enum.Font.GothamBold; flyUi.pillText.TextSize = 11

   -- [เพิ่มใหม่] ปุ่ม (X) สำหรับปิดหน้าต่างบิน
   local flyClose = Instance.new("TextButton", FlyFrame)
   flyClose.Name = "FlyCloseBtn"
   flyClose.Size = UDim2.new(0, 22, 0, 22)
   flyClose.Position = UDim2.new(1, -28, 0, 8)
   flyClose.BackgroundColor3 = Color3.fromRGB(215, 45, 40)
   flyClose.Text = "✕"
   flyClose.TextColor3 = Color3.fromRGB(255, 255, 255)
   flyClose.Font = Enum.Font.GothamBold
   flyClose.TextSize = 13
   Instance.new("UICorner", flyClose).CornerRadius = UDim.new(1, 0)
   
   flyClose.Visible = false -- หน้าต่าง Fly ปิดได้จากเมนูหลักเท่านั้น
end

local flyOnOf = flyUi.button("FlyToggle", UDim2.fromOffset(10, 42), UDim2.new(1, -20, 0, 38), flyUi.navy, "", 15)
flyUi.ring = Instance.new("UIStroke", flyOnOf)
flyUi.ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; flyUi.ring.Color = flyUi.accent; flyUi.ring.Thickness = 2

local flyUp = flyUi.button("FlyUp", UDim2.fromOffset(10, 88), UDim2.new(0.5, -14, 0, 44), flyUi.navy, "▲  ขึ้น", 15)
local flyDown = flyUi.button("FlyDown", UDim2.new(0.5, 4, 0, 88), UDim2.new(0.5, -14, 0, 44), flyUi.navy, "▼  ลง", 15)

local flyMine = flyUi.button("FlySpeedMinus", UDim2.fromOffset(10, 140), UDim2.fromOffset(34, 34), flyUi.navy, "", 14)
UI_LAYOUT.glyph(flyMine, false, flyUi.accent, 16, 4)
local flySpeedLabel = Instance.new("TextLabel", FlyFrame)
flySpeedLabel.Name = "FlySpeedLabel"; flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Position = UDim2.fromOffset(48, 140); flySpeedLabel.Size = UDim2.new(1, -96, 0, 34)
flySpeedLabel.Font = Enum.Font.GothamBold; flySpeedLabel.TextSize = 14; flySpeedLabel.TextColor3 = WHITE_TEXT
flySpeedLabel.TextScaled = true; flySpeedLabel.Text = "ความเร็วบิน  x1"
do
   local c = Instance.new("UITextSizeConstraint", flySpeedLabel); c.MaxTextSize = 14; c.MinTextSize = 9
end
local flyPlus = flyUi.button("FlySpeedPlus", UDim2.new(1, -44, 0, 140), UDim2.fromOffset(34, 34), flyUi.accent, "", 14)
UI_LAYOUT.glyph(flyPlus, true, flyUi.ink, 16, 4)

local flyEmergencyStop = flyUi.button("FlyEmergencyStop", UDim2.fromOffset(10, 182), UDim2.new(1, -20, 0, 32),
   Color3.fromRGB(44, 22, 34), "⛔ หยุดฉุกเฉิน", 13, Color3.fromRGB(255, 143, 163))
do
   local ring = Instance.new("UIStroke", flyEmergencyStop)
   ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ring.Color = Color3.fromRGB(255, 92, 122); ring.Thickness = 2
end

function flyUi.setVisual(on)
   flyOnOf.Text = on and "บิน · เปิดอยู่" or "บิน · ปิดอยู่"
   flyOnOf.BackgroundColor3 = on and flyUi.accent or flyUi.navy
   flyOnOf.TextColor3 = on and flyUi.ink or WHITE_TEXT
   flyUi.ring.Enabled = not on
   flyUi.pill.BackgroundColor3 = on and flyUi.accent or Color3.fromRGB(42, 55, 80)
   flyUi.pillText.Text = on and "กำลังบิน" or "ปิดอยู่"
   flyUi.pillText.TextColor3 = on and flyUi.ink or flyUi.muted
end
flyUi.setVisual(false)

local flySpeeds = 1
local flyNowe = false
-- Shared tpwalking worker: one Heartbeat connection handles all horizontal movement.
local tpwalking = false
local bg, bv, flyLoop
local verticalInput = 0
local savedHumanoid = nil
local savedPlatformStand = false
local savedAutoRotate = true
local savedAnimateDisabled = false
local savedStateEnabled = {}
local flyStateTypes = {
   Enum.HumanoidStateType.Climbing,
   Enum.HumanoidStateType.FallingDown,
   Enum.HumanoidStateType.Flying,
   Enum.HumanoidStateType.Freefall,
   Enum.HumanoidStateType.GettingUp,
   Enum.HumanoidStateType.Jumping,
   Enum.HumanoidStateType.Landed,
   Enum.HumanoidStateType.Physics,
   Enum.HumanoidStateType.PlatformStanding,
   Enum.HumanoidStateType.Ragdoll,
   Enum.HumanoidStateType.Running,
   Enum.HumanoidStateType.RunningNoPhysics,
   Enum.HumanoidStateType.Seated,
   Enum.HumanoidStateType.StrafingNoPhysics,
   Enum.HumanoidStateType.Swimming
}

local function setVerticalInput(value)
   verticalInput = value
end

local function stopFlying(syncState)
   flyNowe = false
   tpwalking = false
   verticalInput = 0

   flyUi.setVisual(false)

   if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
   if bg then pcall(function() bg:Destroy() end); bg = nil end
   if bv then pcall(function() bv:Destroy() end); bv = nil end

   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if hum then
       for _, stateType in ipairs(flyStateTypes) do
           local oldEnabled = savedStateEnabled[stateType]
           if oldEnabled ~= nil then
               pcall(function() hum:SetStateEnabled(stateType, oldEnabled) end)
           else
               pcall(function() hum:SetStateEnabled(stateType, true) end)
           end
       end
       hum.PlatformStand = savedPlatformStand
       hum.AutoRotate = savedAutoRotate
       pcall(function() hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
   end

   if char then
       local animate = char:FindFirstChild("Animate")
       if animate then animate.Disabled = savedAnimateDisabled end
       local root = char:FindFirstChild("HumanoidRootPart")
       if root then
           for _, obj in ipairs(root:GetChildren()) do
               if obj.Name == "TayJayFlyGyro" or obj.Name == "TayJayFlyVelocity" then
                   obj:Destroy()
               end
           end
       end
   end
   savedHumanoid = nil
   savedStateEnabled = {}
end

trackConnection(flyEmergencyStop.Activated:Connect(function()
   verticalInput = 0
   local char = LocalPlayer.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if root then
       pcall(function()
           root.AssemblyLinearVelocity = Vector3.zero
           root.AssemblyAngularVelocity = Vector3.zero
       end)
   end
   if flyNowe then
       stopFlying()
       syncButtonState("Fly", false)
       FlyFrame.Visible = true
   end
end))

local function beginVerticalHold(button, direction)
   local began = button.InputBegan:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
           setVerticalInput(direction)
       end
   end)
   local ended = button.InputEnded:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
           if verticalInput == direction then setVerticalInput(0) end
       end
   end)
   trackConnection(began)
   trackConnection(ended)
end

local function toggleFlyState()
   if isBusy and not flyNowe then return end
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if not hum or not root or hum.Health <= 0 then return end

   if flyNowe then
       stopFlying()
       syncButtonState("Fly", false)
       FlyFrame.Visible = true
       return
   end

   for _, obj in ipairs(root:GetChildren()) do
       if obj.Name == "TayJayFlyGyro" or obj.Name == "TayJayFlyVelocity" then
           pcall(function() obj:Destroy() end)
       end
   end

   flyNowe = true
   tpwalking = true
   syncButtonState("Fly", true)
   FlyFrame.Visible = true
   flyUi.setVisual(true)

   savedHumanoid = hum
   savedPlatformStand = hum.PlatformStand
   savedAutoRotate = hum.AutoRotate
   savedStateEnabled = {}
   for _, stateType in ipairs(flyStateTypes) do
       local ok, enabled = pcall(function() return hum:GetStateEnabled(stateType) end)
       if ok then savedStateEnabled[stateType] = enabled end
   end

   local animate = char:FindFirstChild("Animate")
   savedAnimateDisabled = animate and animate.Disabled or false
   if animate then animate.Disabled = true end

   hum.AutoRotate = false
   for _, stateType in ipairs(flyStateTypes) do
       pcall(function() hum:SetStateEnabled(stateType, false) end)
   end
   hum.PlatformStand = true
   pcall(function() hum:ChangeState(Enum.HumanoidStateType.Swimming) end)

   local flyPart = root -- ยึดตัวควบคุมกับ HumanoidRootPart เพื่อลดการเลื่อนตัวจากจุดศูนย์กลาง

   bg = Instance.new("BodyGyro")
   bg.Name = "TayJayFlyGyro"
   bg.P = 9e4
   bg.D = 1000
   bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
   bg.CFrame = flyPart.CFrame
   bg.Parent = flyPart

   bv = Instance.new("BodyVelocity")
   bv.Name = "TayJayFlyVelocity"
   bv.P = 9e4
   bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
   bv.Velocity = Vector3.zero
   bv.Parent = flyPart

   -- One shared tpwalking worker: BodyGyro + BodyVelocity provide the
   -- actual flight force. Do not combine TranslateBy with BodyVelocity.
   flyLoop = trackConnection(RunService.Heartbeat:Connect(function()
       if not flyNowe or not tpwalking then return end
       if not char.Parent or not hum.Parent or hum.Health <= 0 or not root.Parent or not flyPart.Parent then
           stopFlying()
           return
       end

       local camera = workspace.CurrentCamera
       if not camera or not bg or not bg.Parent or not bv or not bv.Parent then return end

       -- Adapt the tested Fly GUI V3 movement pattern for the existing tablet UI.
       -- tpwalking is the single horizontal movement worker; do not spawn parallel loops.
       -- BodyVelocity is reserved for vertical hold/UP-DOWN so it cannot fight TranslateBy.
       local moveDir = hum.MoveDirection
       if moveDir.Magnitude > 0 then
           char:TranslateBy(moveDir * flySpeeds)
       end

       -- Keep the V3 BodyGyro camera-facing behavior.
       bg.CFrame = camera.CFrame

       -- V3 uses a small upward BodyVelocity while PlatformStand is active.
       -- UP/DOWN controls are applied to the same vertical force.
       bv.Velocity = Vector3.new(0, 0.1 + (verticalInput * 50 * flySpeeds), 0)
   end))
end

trackConnection(flyOnOf.Activated:Connect(toggleFlyState))
beginVerticalHold(flyUp, 1)
beginVerticalHold(flyDown, -1)
local function updateFlySpeedLabel()
   flySpeedLabel.Text = "ความเร็วบิน  x" .. tostring(flySpeeds)
end
updateFlySpeedLabel()

trackConnection(flyPlus.Activated:Connect(function()
   flySpeeds = math.min(flySpeeds + 1, 10)
   updateFlySpeedLabel()
end))
trackConnection(flyMine.Activated:Connect(function()
   flySpeeds = math.max(1, flySpeeds - 1)
   updateFlySpeedLabel()
end))

trackConnection(UserInputService.WindowFocusReleased:Connect(function()
   setVerticalInput(0)
end))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   if flyNowe then stopFlying() end
end))

-- =========================================================
-- 📖 DEATH NOTE ( Player List )
-- =========================================================
local AttackRemote = nil
pcall(function()
   for _, candidateName in ipairs({"AttackRemote", "Punch", "Attack", "CombatRemote"}) do
       local candidate = ReplicatedStorage:FindFirstChild(candidateName, true)
       if candidate and (candidate:IsA("RemoteEvent") or candidate:IsA("RemoteFunction")) then
           AttackRemote = candidate
           break
       end
   end
end)
local ATTACK_COOLDOWN = 0.25
local lastAttackAt = 0
local attackCallBusy = false
local function tryAttackTarget(targetCharacter)
   if not AttackRemote or not targetCharacter or attackCallBusy then return false end
   local now = os.clock()
   if now - lastAttackAt < ATTACK_COOLDOWN then return false end
   lastAttackAt = now
   attackCallBusy = true
   local ok = pcall(function()
       if AttackRemote:IsA("RemoteEvent") then
           AttackRemote:FireServer(targetCharacter)
       elseif AttackRemote:IsA("RemoteFunction") then
           AttackRemote:InvokeServer(targetCharacter)
       end
   end)
   attackCallBusy = false
   return ok
end

local deathNoteGroup = Instance.new("Frame", screenGui)
deathNoteGroup.Name = "DeathNoteGroup"; deathNoteGroup.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH); deathNoteGroup.Position = UI_LAYOUT.PlayerList
deathNoteGroup.BackgroundTransparency = 1; deathNoteGroup.Visible = false; deathNoteGroup.Active = true
local deathNoteMain = Instance.new("Frame", deathNoteGroup)
deathNoteMain.Name = "DeathNoteMain"
deathNoteMain.Size = UDim2.new(1, 0, 1, 0); deathNoteMain.Position = UDim2.new(0, 0, 0, 0)
deathNoteMain.BackgroundColor3 = GREEN.dark; deathNoteMain.Visible = false
Instance.new("UICorner", deathNoteMain).CornerRadius = UDim.new(0, 12)
local dnStroke = Instance.new("UIStroke", deathNoteMain); dnStroke.Name = "TayJayWindowAccent"; dnStroke.Color = UI_LAYOUT.Accent.Players; dnStroke.Thickness = 2.5

local groupDragging, groupDragInput, groupDragStart, groupStartPos = false, nil, nil, nil
local isWindowLocked = false
local function beginGroupDrag(panel)
   panel.InputBegan:Connect(function(input)
       if not isWindowLocked and not _G.TAYJAY_UI.locked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
           groupDragging = true; groupDragStart = input.Position; groupStartPos = deathNoteGroup.Position
           input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then groupDragging = false end end)
       end
   end)
   panel.InputChanged:Connect(function(input)
       if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then groupDragInput = input end
   end)
end
beginGroupDrag(deathNoteMain)
trackConnection(UserInputService.InputChanged:Connect(function(input)
   if input == groupDragInput and groupDragging and not isWindowLocked and not _G.TAYJAY_UI.locked then
       local delta = input.Position - groupDragStart
       deathNoteGroup.Position = UDim2.new(
           groupStartPos.X.Scale, groupStartPos.X.Offset + delta.X,
           groupStartPos.Y.Scale, groupStartPos.Y.Offset + delta.Y
       )
   end
end))

local dnTitle = Instance.new("TextLabel", deathNoteMain)
dnTitle.Size = UDim2.new(1, -82, 0, 32); dnTitle.Position = UDim2.new(0, 10, 0, 0); dnTitle.BackgroundTransparency = 1; dnTitle.Text = "👥 ผู้เล่นทั้งหมด"; dnTitle.TextColor3 = WHITE_TEXT; dnTitle.Font = Enum.Font.GothamBold; dnTitle.TextSize = 14; dnTitle.TextXAlignment = Enum.TextXAlignment.Left; dnTitle.TextStrokeColor3 = TEXT_OUTLINE; dnTitle.TextStrokeTransparency = 0.48

local dnLock = Instance.new("TextButton", deathNoteMain)
dnLock.Name = "WindowLockButton"; dnLock.Size = UDim2.new(0, 25, 0, 25); dnLock.Position = UDim2.new(1, -57, 0, 5); dnLock.BackgroundColor3 = Color3.fromRGB(76, 158, 48); dnLock.Text = "🔓"; dnLock.TextColor3 = WHITE_TEXT; dnLock.Font = Enum.Font.GothamBold; dnLock.TextSize = 15; dnLock.AutoButtonColor = true; Instance.new("UICorner", dnLock).CornerRadius = UDim.new(0, 7)
dnLock.Activated:Connect(function()
   isWindowLocked = not isWindowLocked
   groupDragging = false
   dnLock.Text = isWindowLocked and "🔒" or "🔓"
   dnLock.BackgroundColor3 = isWindowLocked and Color3.fromRGB(205, 48, 42) or Color3.fromRGB(76, 158, 48)
end)

local dnClose = Instance.new("TextButton", deathNoteMain)
dnClose.Size = UDim2.new(0, 22, 0, 22); dnClose.Position = UDim2.new(1, -28, 0, 5); dnClose.BackgroundColor3 = Color3.fromRGB(215, 45, 40); dnClose.Text = "✕"; dnClose.TextColor3 = WHITE_TEXT; dnClose.Font = Enum.Font.GothamBold; dnClose.TextSize = 13; Instance.new("UICorner", dnClose).CornerRadius = UDim.new(1, 0)
dnClose.Activated:Connect(function() deathNoteGroup.Visible = false; syncButtonState("DeathNote", false) end)

local dnScroll = Instance.new("ScrollingFrame", deathNoteMain)
dnScroll.Size = UDim2.new(1, -16, 1, -42); dnScroll.Position = UDim2.new(0, 8, 0, 36); dnScroll.BackgroundTransparency = 1; dnScroll.ScrollBarThickness = 5
dnScroll.ScrollingDirection = Enum.ScrollingDirection.Y; dnScroll.ClipsDescendants = true
dnScroll.CanvasSize = UDim2.new(0, 0, 0, 0); dnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- ความสูงตามรายชื่อจริงเสมอ
local dnListLayout = Instance.new("UIListLayout", dnScroll); dnListLayout.SortOrder = Enum.SortOrder.LayoutOrder; dnListLayout.Padding = UDim.new(0, 5)
local dnPadding = Instance.new("UIPadding", dnScroll)
dnPadding.PaddingTop = UDim.new(0, 2); dnPadding.PaddingBottom = UDim.new(0, 14) -- เว้นช่องท้ายให้แถวสุดท้ายเลื่อนพ้นขอบ


local originalTransparencies = {}
local selectedDeathNoteTarget = nil
local lockedDeathNoteTarget = nil
local isDeathNoteTargetLocked = false
local shadowTargetReleased = false

-- Client-side visual hide only; this does not make the character server-invisible.
local function setInvisibility(char, invisible)
   if not char then return end
   for _, obj in ipairs(char:GetDescendants()) do
       if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
           if invisible then
               if originalTransparencies[obj] == nil then
                   originalTransparencies[obj] = {kind = "part", value = obj.LocalTransparencyModifier}
               end
               obj.LocalTransparencyModifier = 1
           else
               local saved = originalTransparencies[obj]
               if saved and saved.kind == "part" then
                   pcall(function() obj.LocalTransparencyModifier = saved.value end)
                   originalTransparencies[obj] = nil
               end
           end
       elseif obj:IsA("Decal") or obj:IsA("Texture") then
           if invisible then
               if originalTransparencies[obj] == nil then
                   originalTransparencies[obj] = {kind = "decal", value = obj.Transparency}
               end
               obj.Transparency = 1
           else
               local saved = originalTransparencies[obj]
               if saved and saved.kind == "decal" then
                   pcall(function() obj.Transparency = saved.value end)
                   originalTransparencies[obj] = nil
               end
           end
       end
   end
end

local function setupCardContent(playerObj, hpBarFill, hpText)
   local function updateHealth()
       pcall(function()
           if playerObj and playerObj.Character then
               local hum = playerObj.Character:FindFirstChildOfClass("Humanoid")
               if hum then
                   local hp = math.max(0, math.floor(hum.Health)); local maxHp = math.max(1, math.floor(hum.MaxHealth))
                   hpBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
                   hpText.Text = hp .. "/" .. maxHp
               else
                   hpBarFill.Size = UDim2.new(0, 0, 1, 0); hpText.Text = "Dead"
               end
           else hpBarFill.Size = UDim2.new(0, 0, 1, 0); hpText.Text = "Offline" end
       end)
   end
   pcall(function()
       if playerObj.Character then
           local hum = playerObj.Character:FindFirstChildOfClass("Humanoid")
           if hum then hum.HealthChanged:Connect(updateHealth) end
       end
       playerObj.CharacterAdded:Connect(function(newChar)
           local hum = newChar:WaitForChild("Humanoid", 5)
           if hum then hum.HealthChanged:Connect(updateHealth); updateHealth() end
       end)
   end)
   updateHealth()
end

local targetTitle, targetHpLabel, targetBarFill

local function createPlayerCard(playerObj, parentScroll, isKiller)
   local card = Instance.new("TextButton", parentScroll)
   card.Name = playerObj.Name; card.Size = UDim2.new(1, 0, 0, isKiller and 50 or 46); card.BackgroundColor3 = isKiller and Color3.fromRGB(105, 40, 33) or Color3.fromRGB(30, 52, 78); card.Text = ""
   Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
   local cardStroke = Instance.new("UIStroke", card); cardStroke.Color = isKiller and Color3.fromRGB(255, 105, 75) or UI_LAYOUT.Accent.Players; cardStroke.Thickness = 1.2
   if selectedDeathNoteTarget and selectedDeathNoteTarget.Name == playerObj.Name then
       card.BackgroundColor3 = Color3.fromRGB(190, 35, 35); cardStroke.Color = Color3.fromRGB(255, 110, 110)
   end
   
   local avatar = Instance.new("ImageLabel", card)
   avatar.Size = UDim2.new(0, 32, 0, 32); avatar.Position = UDim2.new(0, 7, 0, 7); avatar.BackgroundTransparency = 1
   pcall(function() avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. playerObj.UserId .. "&w=150&h=150" end)
   Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

   local nameLabel = Instance.new("TextLabel", card)
   nameLabel.Size = UDim2.new(1, -99, 0, 21); nameLabel.Position = UDim2.new(0, 45, 0, 2); nameLabel.BackgroundTransparency = 1; nameLabel.Text = playerObj.DisplayName
   nameLabel.TextColor3 = WHITE_TEXT; nameLabel.TextSize = 13
   nameLabel.TextStrokeColor3 = TEXT_OUTLINE; nameLabel.TextStrokeTransparency = 0.48; nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextXAlignment = Enum.TextXAlignment.Left

   local hpBarBg = Instance.new("Frame", card)
   hpBarBg.Size = UDim2.new(1, -141, 0, 8); hpBarBg.Position = UDim2.new(0, 45, 0, 28); hpBarBg.BackgroundColor3 = Color3.fromRGB(55, 82, 51); hpBarBg.BorderSizePixel = 0; Instance.new("UICorner", hpBarBg).CornerRadius = UDim.new(1, 0)
   
   local hpBarFill = Instance.new("Frame", hpBarBg)
   hpBarFill.Size = UDim2.new(1, 0, 1, 0); hpBarFill.BackgroundColor3 = Color3.fromRGB(104, 211, 57); hpBarFill.BorderSizePixel = 0; Instance.new("UICorner", hpBarFill).CornerRadius = UDim.new(1, 0)

   local hpText = Instance.new("TextLabel", card)
   hpText.Size = UDim2.new(0, 36, 0, 14); hpText.Position = UDim2.new(1, -92, 0, 26); hpText.BackgroundTransparency = 1; hpText.Text = "100/100"
   hpText.TextColor3 = WHITE_TEXT; hpText.TextSize = 10; hpText.Font = Enum.Font.GothamBold; hpText.TextXAlignment = Enum.TextXAlignment.Right

   setupCardContent(playerObj, hpBarFill, hpText)

   -- ปุ่ม "ข้าม": ผู้เล่นที่ตั้งข้ามจะไม่ถูก WARP เลือกเป็นเป้าหมาย
   local skipBtn = Instance.new("TextButton", card)
   skipBtn.Name = "WarpSkipBtn"; skipBtn.Size = UDim2.new(0, 46, 0, 20); skipBtn.Position = UDim2.new(1, -50, 0.5, -10)
   skipBtn.BorderSizePixel = 0; skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextSize = 10; skipBtn.TextColor3 = WHITE_TEXT
   Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)
   skipBtn.Visible = playerObj ~= LocalPlayer
   local function refreshSkip()
       local skipped = _G.TAYJAY_BL.has(playerObj.Name)
       skipBtn.Text = skipped and "✕ ข้าม" or "ข้าม"
       skipBtn.BackgroundColor3 = skipped and Color3.fromRGB(205, 48, 42) or Color3.fromRGB(76, 110, 70)
   end
   skipBtn.Activated:Connect(function()
       _G.TAYJAY_BL.set(playerObj.Name, not _G.TAYJAY_BL.has(playerObj.Name))
       refreshSkip()
   end)
   refreshSkip()

   card.Activated:Connect(function()
       if playerObj == LocalPlayer then
           pcall(function() if setclipboard then setclipboard(playerObj.Name) end end)
           nameLabel.Text = "✓ คัดลอกชื่อแล้ว"
           task.delay(1.2, function()
               if nameLabel and nameLabel.Parent then nameLabel.Text = playerObj.DisplayName end
           end)
           return
       end

       if _G.TAYJAY_BL.has(playerObj.Name) then
           targetTitle.Text = "🚫 อยู่ใน blacklist"
           return
       end
       if selectedDeathNoteTarget == playerObj then
           -- กดชื่อเดิมอีกครั้ง = ยกเลิก แล้วกลับไปยืนที่จุดยืน
           selectedDeathNoteTarget = nil
           syncButtonState("DNWarp", false)
           targetTitle.Text = "🎯 Target: none"
           return
       end
       -- กดชื่อใหม่ = เปลี่ยนเป้าหมายและเปิด WARP ตามเป้านั้น
       selectedDeathNoteTarget = playerObj
       shadowTargetReleased = false
       syncButtonState("DNWarp", true)
       pcall(function() if setclipboard then setclipboard(playerObj.Name) end end)
       nameLabel.Text = "✓ SELECTED"
       targetTitle.Text = "🎯 Target: " .. playerObj.Name
       local targetHumanoid = playerObj.Character and playerObj.Character:FindFirstChildOfClass("Humanoid")
       if targetHumanoid then
           local hp = math.max(0, math.floor(targetHumanoid.Health))
           local maxHp = math.max(1, math.floor(targetHumanoid.MaxHealth))
           targetHpLabel.Text = hp .. " / " .. maxHp .. " HP"
           targetBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
       end
       task.delay(1.2, function()
           if nameLabel and nameLabel.Parent then nameLabel.Text = playerObj.DisplayName end
       end)
   end)
end

local playerListRefreshQueued = false
local function updatePlayerList()
   if playerListRefreshQueued then return end
   playerListRefreshQueued = true
   task.defer(function()
       playerListRefreshQueued = false
       if not dnScroll or not dnScroll.Parent then return end
       pcall(function()
           for _, child in ipairs(dnScroll:GetChildren()) do
               if child:IsA("TextButton") then child:Destroy() end
           end
           local allPlayers = Players:GetPlayers()
           for _, player in ipairs(allPlayers) do
               createPlayerCard(player, dnScroll, false)
           end
           dnTitle.Text = "👥 ผู้เล่นทั้งหมด (" .. #allPlayers .. ")"
           task.defer(function()
               -- canvas ของรายชื่อคำนวณอัตโนมัติ (AutomaticCanvasSize) ไม่ต้องตั้งค่าเอง
           end)
       end)
   end)
end
trackConnection(Players.PlayerAdded:Connect(updatePlayerList))
trackConnection(Players.PlayerRemoving:Connect(function(player)
   if lockedDeathNoteTarget == player then
       lockedDeathNoteTarget = nil
       isDeathNoteTargetLocked = false
       shadowTargetReleased = true
       if states.AutoWarp then syncButtonState("AutoWarp", false) end
   end
   if selectedDeathNoteTarget == player then
       selectedDeathNoteTarget = nil
       targetTitle.Text = "🎯 Target: unavailable"
       targetHpLabel.Text = "0 / 0 HP"
       targetBarFill.Size = UDim2.new(0, 0, 1, 0)
   end
   updatePlayerList()
end))
task.defer(updatePlayerList)

-- 💥 KILL AURA (WARP & WALK)
-- Forward declaration: player-WARP activation can cleanly stop the independent Monster Warp.
local stopMonsterWarp
local maxAttackDistance = 100

-- FIXED SYNTAX ERROR: String \n
local kaCircleBtn = Instance.new("TextButton", screenGui)
kaCircleBtn.Name = "KillAuraCircleBtn"; kaCircleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
kaCircleBtn.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize); kaCircleBtn.Position = UI_LAYOUT.WarpCenter
kaCircleBtn.BackgroundColor3 = GREEN.deep; kaCircleBtn.RichText = true
kaCircleBtn.Text = '<font size="32">🕶</font>\n<font size="18">WARP</font>'
kaCircleBtn.TextColor3 = WHITE_TEXT; kaCircleBtn.Font = Enum.Font.GothamBlack; kaCircleBtn.TextSize = 18; kaCircleBtn.Active = true
Instance.new("UICorner", kaCircleBtn).CornerRadius = UDim.new(1, 0)
local kaCircleStroke = Instance.new("UIStroke", kaCircleBtn); kaCircleStroke.Color = GREEN.neon; kaCircleStroke.Thickness = 2.5
makeDraggable(kaCircleBtn)

-- FIXED SYNTAX ERROR: String \n
local kaNormalBtn = Instance.new("TextButton", screenGui)
kaNormalBtn.Name = "KillAuraNormalBtn"; kaNormalBtn.AnchorPoint = Vector2.new(0.5, 0.5)
kaNormalBtn.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize); kaNormalBtn.Position = UI_LAYOUT.WalkCenter
kaNormalBtn.BackgroundColor3 = GREEN.deep; kaNormalBtn.RichText = true
kaNormalBtn.Text = '<font size="32">👹</font>\n<font size="18">WALK</font>'
kaNormalBtn.TextColor3 = WHITE_TEXT; kaNormalBtn.Font = Enum.Font.GothamBlack; kaNormalBtn.TextSize = 18; kaNormalBtn.Active = true
Instance.new("UICorner", kaNormalBtn).CornerRadius = UDim.new(1, 0)
local kaNormalStroke = Instance.new("UIStroke", kaNormalBtn); kaNormalStroke.Color = GREEN.neon; kaNormalStroke.Thickness = 2.5
makeDraggable(kaNormalBtn)

local targetGui = Instance.new("Frame", screenGui)
targetGui.Name = "TayJayTargetPanel"; targetGui.Size = UDim2.new(0, UI_LAYOUT.PanelW, 0, 116); targetGui.Position = UI_LAYOUT.TargetPanel
targetGui.BackgroundColor3 = GREEN.dark; targetGui.Visible = false
Instance.new("UICorner", targetGui).CornerRadius = UDim.new(0, 12)
local tgStroke = Instance.new("UIStroke", targetGui); tgStroke.Name = "TayJayWindowAccent"; tgStroke.Color = UI_LAYOUT.Accent.Target; tgStroke.Thickness = 2.5
makeDraggable(targetGui)

targetTitle = Instance.new("TextLabel", targetGui)
targetTitle.Size = UDim2.new(1, -32, 0, 22); targetTitle.Position = UDim2.new(0, 10, 0, 4); targetTitle.BackgroundTransparency = 1; targetTitle.Text = "⚔️ เป้าหมาย: ไม่พบเป้าหมาย"; targetTitle.TextColor3 = WHITE_TEXT; targetTitle.Font = Enum.Font.GothamBold; targetTitle.TextSize = 12; targetTitle.TextXAlignment = Enum.TextXAlignment.Left

local targetBarBG = Instance.new("Frame", targetGui)
targetBarBG.Size = UDim2.new(1, -20, 0, 10); targetBarBG.Position = UDim2.new(0, 10, 0, 30); targetBarBG.BackgroundColor3 = Color3.fromRGB(255, 249, 210); targetBarBG.BorderSizePixel = 0; Instance.new("UICorner", targetBarBG).CornerRadius = UDim.new(0, 6)
targetBarFill = Instance.new("Frame", targetBarBG)
targetBarFill.Size = UDim2.new(0, 0, 1, 0); targetBarFill.BackgroundColor3 = Color3.fromRGB(104, 211, 57); targetBarFill.BorderSizePixel = 0; Instance.new("UICorner", targetBarFill).CornerRadius = UDim.new(0, 6)

targetHpLabel = Instance.new("TextLabel", targetGui)
targetHpLabel.Size = UDim2.new(1, -20, 0, 16); targetHpLabel.Position = UDim2.new(0, 10, 0, 44); targetHpLabel.BackgroundTransparency = 1; targetHpLabel.Text = "0 / 0 HP"; targetHpLabel.TextColor3 = WHITE_TEXT; targetHpLabel.Font = Enum.Font.Gotham; targetHpLabel.TextSize = 11

-- Target Lock controls. The lock is bound to the exact Player selected in Death Note.
local targetLockButton = Instance.new("TextButton", targetGui)
targetLockButton.Name = "TargetLockButton"
targetLockButton.Size = UDim2.new(0.5, -14, 0, 27)
targetLockButton.Position = UDim2.new(0, 9, 0, 76)
targetLockButton.BackgroundColor3 = Color3.fromRGB(15, 128, 194)
targetLockButton.Text = "🎯 TARGET LOCK"
targetLockButton.TextColor3 = WHITE_TEXT
targetLockButton.Font = Enum.Font.GothamBold
targetLockButton.TextSize = 11
targetLockButton.TextStrokeColor3 = TEXT_OUTLINE
targetLockButton.TextStrokeTransparency = 0.45
Instance.new("UICorner", targetLockButton).CornerRadius = UDim.new(0, 7)
local targetLockStroke = Instance.new("UIStroke", targetLockButton)
targetLockStroke.Color = Color3.fromRGB(95, 205, 255)
targetLockStroke.Thickness = 1.4

local targetUnlockButton = Instance.new("TextButton", targetGui)
targetUnlockButton.Name = "UntargetLockButton"
targetUnlockButton.Size = UDim2.new(0.5, -14, 0, 27)
targetUnlockButton.Position = UDim2.new(0.5, 5, 0, 76)
targetLockButton.Visible = true
targetUnlockButton.Size = UDim2.new(0.5, -14, 0, 27); targetUnlockButton.Position = UDim2.new(0.5, 5, 0, 76)
targetUnlockButton.BackgroundColor3 = Color3.fromRGB(170, 65, 42)
targetUnlockButton.Text = "🔓 UNTARGET"
targetUnlockButton.TextColor3 = WHITE_TEXT
targetUnlockButton.Font = Enum.Font.GothamBold
targetUnlockButton.TextSize = 11
targetUnlockButton.TextStrokeColor3 = TEXT_OUTLINE
targetUnlockButton.TextStrokeTransparency = 0.45
Instance.new("UICorner", targetUnlockButton).CornerRadius = UDim.new(0, 7)
local targetUnlockStroke = Instance.new("UIStroke", targetUnlockButton)
targetUnlockStroke.Color = Color3.fromRGB(255, 145, 100)
targetUnlockStroke.Thickness = 1.4

local function updateTargetLockVisual()
    local locked = isDeathNoteTargetLocked and lockedDeathNoteTarget ~= nil
    targetLockButton.Text = "⇢ WARP ไป"
    targetLockButton.BackgroundColor3 = Color3.fromRGB(20, 150, 175)
    targetLockStroke.Color = UI_LAYOUT.Accent.Stay
end

targetLockButton.Activated:Connect(function()
    local candidate = selectedDeathNoteTarget
    if not candidate or candidate.Parent ~= Players then
        targetTitle.Text = "⚠ เลือกชื่อในรายการก่อน"
        return
    end
    -- ให้ลูปวาร์ปไปหาเป้าหมายครั้งเดียว แล้วอยู่ตรงนั้น (ไม่กลับจุดยืน)
    _G.TAYJAY_STAY_REQUEST = true
    targetTitle.Text = "⇢ ไปหา " .. candidate.Name .. " (ไม่กลับ)"
end)

targetUnlockButton.Activated:Connect(function()
    selectedDeathNoteTarget = nil
    syncButtonState("DNWarp", false)
    lockedDeathNoteTarget = nil
    isDeathNoteTargetLocked = false
    shadowTargetReleased = true
    updateTargetLockVisual()
    if states.AutoWarp then syncButtonState("AutoWarp", false) end
    targetTitle.Text = "🔓 Target unlocked"
    targetHpLabel.Text = "Tracking stopped • Select a new target"
end)

updateTargetLockVisual()

task.spawn(function()
   while screenGui.Parent and task.wait(0.03) do
       local pulse = _G.TAYJAY_UI.effects and (math.sin(tick() * 15) + 1) / 2 or 0
       if states.KillAura then
           kaCircleStroke.Thickness = 3 + (pulse * 3)
           kaCircleStroke.Color = Color3.fromRGB(255, math.floor(pulse * 100), math.floor(pulse * 100))
       else
           kaCircleStroke.Thickness = 2.5
           kaCircleStroke.Color = Color3.fromRGB(255, 190, 45)
       end
       if states.NormalKillAura then
           kaNormalStroke.Thickness = 3 + (pulse * 3)
           kaNormalStroke.Color = Color3.fromRGB(255, math.floor(pulse * 100), math.floor(pulse * 100))
       else
           kaNormalStroke.Thickness = 2.5
           kaNormalStroke.Color = Color3.fromRGB(104, 211, 57)
       end
   end
end)

local function updateKaBtnDisplay()
   local warpOn, walkOn = states.KillAura, states.NormalKillAura
   kaCircleBtn.BackgroundColor3 = warpOn and GREEN.on or GREEN.off
   kaNormalBtn.BackgroundColor3 = walkOn and GREEN.on or GREEN.off
   kaCircleBtn.Text = '<font size="26">🕶</font>\n<font size="15">WARP</font>\n<font size="11">' .. (warpOn and "ON" or "OFF") .. '</font>'
   kaNormalBtn.Text = '<font size="26">👹</font>\n<font size="15">WALK</font>\n<font size="11">' .. (walkOn and "ON" or "OFF") .. '</font>'
   if not (warpOn or states.DNWarp) then _G.TAYJAY_FOLLOW = nil end
   targetGui.Visible = (states.KillAura or states.AutoWarp or states.NormalKillAura or states.DNWarp)
end
updateKaBtnDisplay()

-- Central arbitration: only one character-position controller may run at a time.
local baseSyncButtonState = syncButtonState
local resolvingExclusiveMode = false
local exclusiveConflicts = {
    Fly = {"KillAura", "NormalKillAura", "DNWarp", "AutoWarp", "MonsterWarp"},
    KillAura = {"Fly", "NormalKillAura", "DNWarp", "AutoWarp", "MonsterWarp"},
    NormalKillAura = {"Fly", "KillAura"},
    DNWarp = {"Fly", "KillAura", "AutoWarp", "MonsterWarp"},
    AutoWarp = {"Fly", "KillAura", "DNWarp", "MonsterWarp"},
    MonsterWarp = {"Fly", "KillAura", "DNWarp", "AutoWarp"}
}
local function resolveExclusiveMode(nextKey)
    if resolvingExclusiveMode then return end
    resolvingExclusiveMode = true
    for _, oldKey in ipairs(exclusiveConflicts[nextKey] or {}) do
        if states[oldKey] then
            if oldKey == "MonsterWarp" then
                if stopMonsterWarp then stopMonsterWarp(true) else states.MonsterWarp = false end
            elseif oldKey == "KillAura" or oldKey == "NormalKillAura" then
                states[oldKey] = false
                updateKaBtnDisplay()
            else
                baseSyncButtonState(oldKey, false)
            end
        end
    end
    resolvingExclusiveMode = false
   if nextKey == "Fly" or nextKey == "KillAura" or nextKey == "DNWarp"
       or nextKey == "AutoWarp" or nextKey == "MonsterWarp" then
       local stopOldPlayerWarp = _G.TAYJAY_STOP_PLAYER_WARP
       if type(stopOldPlayerWarp) == "function" then pcall(stopOldPlayerWarp) end
   end
end
syncButtonState = function(key, isOn)
    if isOn then resolveExclusiveMode(key) end
    baseSyncButtonState(key, isOn)
end

do
   -- WARP (ปุ่มวงกลม): สุ่มหาเป้าหมายในระยะ 200 studs ไม่ต้องเลือกในสมุดสั่งตาย
   trackConnection(kaCircleBtn.Activated:Connect(function()
       local turningOn = not states.KillAura
       if turningOn then resolveExclusiveMode("KillAura") end
       if turningOn and stopMonsterWarp and states.MonsterWarp then
           stopMonsterWarp(true)
       end
       states.KillAura = not states.KillAura
       if states.KillAura then
           states.NormalKillAura = false
            selectedDeathNoteTarget = nil
            syncButtonState("DNWarp", false)
            if flyNowe then stopFlying() end
       end
       updateKaBtnDisplay()
   end))

   -- WALK: โจมตีระยะใกล้ (ไม่เปลี่ยน)
   trackConnection(kaNormalBtn.Activated:Connect(function()
       local turningOn = not states.NormalKillAura
       if turningOn then resolveExclusiveMode("NormalKillAura") end
       states.NormalKillAura = turningOn
       if states.NormalKillAura then states.KillAura = false end
       updateKaBtnDisplay()
   end))

   -- โหมดสมุดสั่งตาย (รวม Auto Warp เดิม): เปิด/ปิดด้วยการกดชื่อในรายการ
   _G.TAYJAY_DN_REPAINT = function()
       if not dnScroll then return end
       for _, card in ipairs(dnScroll:GetChildren()) do
           if card:IsA("TextButton") then
               local picked = selectedDeathNoteTarget ~= nil and selectedDeathNoteTarget.Name == card.Name
               card.BackgroundColor3 = picked and Color3.fromRGB(190, 35, 35) or Color3.fromRGB(30, 52, 78)
               local stroke = card:FindFirstChildOfClass("UIStroke")
               if stroke then stroke.Color = picked and Color3.fromRGB(255, 110, 110) or UI_LAYOUT.Accent.Players end
           end
       end
   end
   registerUiSync("DNWarp", function(isOn)
       if isOn then
           if stopMonsterWarp and states.MonsterWarp then stopMonsterWarp(true) end
           states.KillAura = false
           if flyNowe then stopFlying() end
       end
       if _G.TAYJAY_DN_REPAINT then _G.TAYJAY_DN_REPAINT() end
       updateKaBtnDisplay()
   end)

-- เมนู 7 (วาร์ปออโต้) ทำงานกับเป้าหมายในสมุด จึงไม่ซ้อนกับ WARP สุ่ม
   registerUiSync("AutoWarp", function(isOn)
       if isOn then
           if stopMonsterWarp and states.MonsterWarp then stopMonsterWarp(true) end
           states.KillAura = false
       end
       updateKaBtnDisplay()
   end)
end

local radius = 15; local numParts = 36; local circleParts = {}
for i = 1, numParts do
   local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = false; part.Material = Enum.Material.Neon; part.Color = Color3.fromRGB(255, 211, 58); part.Size = Vector3.new(1, 0.1, (2 * math.pi * radius) / numParts); part.Transparency = 1; part.Parent = workspace
   table.insert(circleParts, part)
end

local function getClosestPlayer_V57(maxDist)
   local closestPlayer = nil; local shortestDistance = maxDist or maxAttackDistance
   local myChar = LocalPlayer.Character
   if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
   local myPos = myChar.HumanoidRootPart.Position

   for _, v in pairs(Players:GetPlayers()) do
       if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
           if v.Character.Humanoid.Health > 0 then
               local distance = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
               if distance < shortestDistance then closestPlayer = v.Character; shortestDistance = distance end
           end
       end
   end
   return closestPlayer
end

local function updateCirclePosition()
   local char = LocalPlayer.Character
   if not char or not char:FindFirstChild("HumanoidRootPart") or not (states.KillAura or states.NormalKillAura) then
       for _, part in ipairs(circleParts) do part.Transparency = 1 end
       return
   end
   local cframe = char.HumanoidRootPart.CFrame
   local angleInc = math.rad(360 / numParts)
   for i, part in ipairs(circleParts) do
       local angle = angleInc * i
       part.CFrame = cframe * CFrame.new(math.cos(angle) * radius, -2, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
       part.Transparency = 0.3
   end
end

trackConnection(RunService.RenderStepped:Connect(function()
   if not (states.KillAura or states.AutoWarp or states.NormalKillAura or states.DNWarp) then
       targetGui.Visible = false
       for _, part in ipairs(circleParts) do part.Transparency = 1 end
       return
   end
   targetGui.Visible = true
   local shadowMode = states.KillAura or states.AutoWarp or states.DNWarp
   local target
   if shadowMode then
       target = selectedDeathNoteTarget and selectedDeathNoteTarget.Character or nil
   else
       local searchDist = states.NormalKillAura and 25 or maxAttackDistance
       target = getClosestPlayer_V57(searchDist)
   end

   if shadowMode then
       -- โหมด WARP: ลูป Shadow Hunter เป็นผู้เขียนข้อความและแถบ HP แต่เพียงผู้เดียว (กันข้อความกระพริบ)
   elseif target then
       local humanoid = target:FindFirstChildOfClass("Humanoid")
       if humanoid then
           local health = math.floor(humanoid.Health); local maxHealth = math.floor(humanoid.MaxHealth)
           targetTitle.Text = (shadowMode and "🕶 Target: " or "⚔️ เป้าหมาย: ") .. target.Name
           targetHpLabel.Text = health .. " / " .. maxHealth .. " HP"
           targetBarFill.Size = UDim2.new(math.clamp(health / math.max(maxHealth, 1), 0, 1), 0, 1, 0)
       end
   else
       targetTitle.Text = shadowMode and "☠ Select target in Death Note" or "⚔️ เป้าหมาย: ไม่พบเป้าหมาย"
       targetHpLabel.Text = "0 / 0 HP"; targetBarFill.Size = UDim2.new(0, 0, 1, 0)
   end
   updateCirclePosition()
end))

-- DEATH NOTE SHADOW HUNTER: Death Note selects the target; WARP UI / AutoWarp starts tracking.
-- Replaces the old head-sit warp entirely. Position updates are client-side and remain subject to server correction.
local SHADOW_FOLLOW_OFFSET = CFrame.new(0, 0, 3.5)
local SHADOW_UPDATE_INTERVAL = 0.12
local lastShadowTarget = nil
local lastShadowCharacter = nil
local shadowHiddenCharacter = nil

local function stopShadowHunterVisuals()
   if shadowHiddenCharacter then
       setInvisibility(shadowHiddenCharacter, false)
       shadowHiddenCharacter = nil
   end
   lastShadowTarget = nil
   lastShadowCharacter = nil
end

-- ตามเป้าหมายทุกเฟรมฟิสิกส์ (ลื่นกว่าการอัปเดตทุก 0.12 วินาที)
do
   local FOLLOW_OFFSET = CFrame.new(0, 0, 3.5)
   trackConnection(RunService.Heartbeat:Connect(function()
       local f = _G.TAYJAY_FOLLOW
       if not f or not f.player or f.player.Parent ~= Players then return end
       if (_G.TAYJAY_WARP_HOLD_UNTIL or 0) > os.clock() then return end
       local myChar = LocalPlayer.Character
       local myRootNow = myChar and myChar:FindFirstChild("HumanoidRootPart")
       local tChar = f.player.Character
       local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
       local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
       if not myRootNow or not tRoot or not tHum or tHum.Health <= 0 then return end
       myRootNow.AssemblyLinearVelocity = Vector3.zero
       myRootNow.AssemblyAngularVelocity = Vector3.zero
       myRootNow.CFrame = tRoot.CFrame * FOLLOW_OFFSET
   end))
end

task.spawn(function()
   local WARP_SEARCH_RANGE = math.huge -- ค้นทั้งแมพ (ใส่ตัวเลข เช่น 200 เพื่อจำกัดระยะจากจุดยืน)
   local WARP_CHAIN_COUNT = 3 -- เมื่อเป้าหมายตาย สุ่มจากคนที่ใกล้จุดตายที่สุดกี่คน
   local WARP_REST_SECONDS = 1 -- พักที่จุดยืนกี่วินาทีก่อนหาเป้าหมายใหม่
   local WARP_PLATFORM_SIZE = Vector3.new(16, 1, 16) -- ขนาดพื้นกันตก
   local WARP_FEET_DROP = 3 -- ระยะจากกลาง HumanoidRootPart ถึงใต้เท้า (studs)
   local randomWarpTarget = nil -- เป้าหมาย WARP ปัจจุบัน
   local warpHome = nil -- CFrame จุดยืนที่กด WARP
   local warpOwner = nil -- ตัวละครที่กด WARP (ใช้ตรวจการเกิดใหม่)
   local warpPlatform = nil -- พื้นกันตก
   local warpRestUntil = 0 -- เวลาที่พักเสร็จ
   local warpWasOn = false
   local warpLastPos = nil -- ตำแหน่งล่าสุดของเป้าหมาย WARP
   local function isSkipped(player)
       return _G.TAYJAY_BL.has(player.Name)
   end

   -- หาคนที่ใกล้จุดยืนที่สุดในระยะ maxDistance (ข้าม blacklist และคนที่ตายแล้ว)
   local function pickNearChain(origin, count)
       local list = {}
       for _, player in ipairs(Players:GetPlayers()) do
           local char = player ~= LocalPlayer and player.Character
           local root = char and char:FindFirstChild("HumanoidRootPart")
           local hum = char and char:FindFirstChildOfClass("Humanoid")
           if root and hum and hum.Health > 0 and not isSkipped(player) then
               table.insert(list, {p = player, d = (root.Position - origin).Magnitude})
           end
       end
       if #list == 0 then return nil end
       table.sort(list, function(a, b) return a.d < b.d end)
       local pool = {}
       for n = 1, math.min(count, #list) do pool[n] = list[n].p end
       return pool[math.random(1, #pool)]
   end
   local function findNearestFromHome(maxDistance, origin)
       local best, bestDistance = nil, maxDistance
       for _, player in ipairs(Players:GetPlayers()) do
           local char = player ~= LocalPlayer and player.Character
           local root = char and char:FindFirstChild("HumanoidRootPart")
           local hum = char and char:FindFirstChildOfClass("Humanoid")
           if root and hum and hum.Health > 0 and not isSkipped(player) then
               local distance = (root.Position - origin).Magnitude
               if distance <= bestDistance then
                   best, bestDistance = player, distance
               end
           end
       end
       return best
   end

   -- พื้นกันตก: แพตโปร่งใสที่ชนได้ อยู่ใต้เท้าตัวละครเสมอ (กันตกเมื่อแมพยังไม่โหลด)
   local function ensurePlatform()
       if not warpPlatform or not warpPlatform.Parent then
           local part = Instance.new("Part")
           part.Name = "TayJayWarpPlatform"
           part.Anchored = true
           part.CanCollide = true
           part.Size = WARP_PLATFORM_SIZE
           part.Transparency = 1
           part.TopSurface = Enum.SurfaceType.Smooth
           part.BottomSurface = Enum.SurfaceType.Smooth
           part.Parent = workspace
           warpPlatform = part
       end
       return warpPlatform
   end
   local function placePlatformUnder(position)
       ensurePlatform().CFrame = CFrame.new(position.X, position.Y - WARP_FEET_DROP - WARP_PLATFORM_SIZE.Y / 2, position.Z)
   end
   -- ลบพื้นกันตกหลังหน่วง 3 วินาที เพื่อให้แมพที่จุดยืนโหลดทัน ไม่ตกระหว่างรอ
   local function destroyPlatform()
       local part = warpPlatform
       warpPlatform = nil
       if part then
           task.delay(3, function()
               if part.Parent then part:Destroy() end
           end)
       end
   end
   -- กลับไปยืนที่จุดยืน (ใช้เฉพาะเมื่อยังเป็นตัวละครเดิม)
   local function goHome(myRoot)
       if warpHome and warpOwner and myRoot and warpOwner == LocalPlayer.Character then
           myRoot.Anchored = false
           myRoot.CFrame = warpHome
           placePlatformUnder(warpHome.Position)
       end
   end

   -- Synchronously finish the previous player-WARP controller before another movement mode starts.
   _G.TAYJAY_STOP_PLAYER_WARP = function()
       if not warpWasOn then return end
       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       if _G.TAYJAY_WARP_STAY then
           _G.TAYJAY_WARP_STAY = false
       else
           goHome(root)
       end
       destroyPlatform()
       warpHome, warpOwner, randomWarpTarget = nil, nil, nil
       warpWasOn = false
   end

   registerShutdownHook(function()
       states.KillAura = false
       states.DNWarp = false
       states.AutoWarp = false
       _G.TAYJAY_FOLLOW = nil
       _G.TAYJAY_STAY_REQUEST = nil
       _G.TAYJAY_STOP_PLAYER_WARP = nil
       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       if warpWasOn and root then goHome(root) end
       if warpPlatform then pcall(function() warpPlatform:Destroy() end); warpPlatform = nil end
       warpHome, warpOwner, randomWarpTarget = nil, nil, nil
       warpWasOn = false
       stopShadowHunterVisuals()
   end)

   while screenGui.Parent do
       task.wait(SHADOW_UPDATE_INTERVAL)
       local shadowEnabled = states.KillAura or states.DNWarp
       local warpActive = states.KillAura or states.DNWarp
       local myCharacterNow = LocalPlayer.Character
       local myRootNow = myCharacterNow and myCharacterNow:FindFirstChild("HumanoidRootPart")

       -- ตัวละครเกิดใหม่: ลืมจุดยืนเดิมและพื้นเก่า
       if warpOwner and warpOwner ~= myCharacterNow then
           warpHome, warpOwner, randomWarpTarget = nil, nil, nil
           destroyPlatform()
           warpWasOn = false
       end
       -- เปิด WARP: จดจุดยืนและสร้างพื้นกันตก
       if warpActive and not warpWasOn and myRootNow then
           warpHome = myRootNow.CFrame
           warpOwner = myCharacterNow
           warpRestUntil = 0
           placePlatformUnder(myRootNow.Position)
           warpWasOn = true
       end
       -- ปิด WARP: กลับจุดยืนและลบพื้นกันตก
       if warpWasOn and not warpActive then
           if _G.TAYJAY_WARP_STAY then _G.TAYJAY_WARP_STAY = false else goHome(myRootNow) end
           destroyPlatform()
           warpHome, warpOwner, randomWarpTarget = nil, nil, nil
           warpWasOn = false
       end

       if not shadowEnabled then
           stopShadowHunterVisuals()
       elseif states.Fly or flyNowe or isBusy then
           if shadowHiddenCharacter then
               setInvisibility(shadowHiddenCharacter, false)
               shadowHiddenCharacter = nil
           end
           _G.TAYJAY_FOLLOW = nil; targetTitle.Text = "⏸ Shadow Hunter: paused"
       else
           if not states.KillAura then randomWarpTarget = nil end
           local targetPlayer
           if states.KillAura then
               -- WARP: เป้าหมาย = คนที่ใกล้ "จุดยืน" ที่สุดทั้งแมพ
               local rc = randomWarpTarget and randomWarpTarget.Character
               local rh = rc and rc:FindFirstChildOfClass("Humanoid")
               local alive = randomWarpTarget and randomWarpTarget.Parent == Players and rh and rh.Health > 0 and not isSkipped(randomWarpTarget)
               if alive and randomWarpTarget.Character then local r = randomWarpTarget.Character:FindFirstChild("HumanoidRootPart"); if r then warpLastPos = r.Position end end
               if randomWarpTarget and not alive then
                   -- เป้าหมายตาย/ออก: สุ่มคนที่อยู่ใกล้จุดสุดท้ายของเป้าเดิม ต่อเนื่องจนกว่าจะกดยกเลิก
                   local origin = warpLastPos or (myRootNow and myRootNow.Position)
                   randomWarpTarget = origin and pickNearChain(origin, WARP_CHAIN_COUNT) or nil
                   warpLastPos = nil
               end
               if states.KillAura and not randomWarpTarget and warpHome and os.clock() >= warpRestUntil then
                   randomWarpTarget = findNearestFromHome(WARP_SEARCH_RANGE, warpHome.Position)
               end
               targetPlayer = randomWarpTarget
               if not targetPlayer then goHome(myRootNow) end
           elseif states.DNWarp then
               -- ปุ่ม "⇢ WARP ไป": ย้ายไปหาเป้าหมายครั้งเดียว แล้วอยู่ตรงนั้น (ไม่กลับจุดยืน)
               if _G.TAYJAY_STAY_REQUEST then
                   _G.TAYJAY_STAY_REQUEST = false
                   local stayTarget = selectedDeathNoteTarget
                   local stayRoot = stayTarget and stayTarget.Character and stayTarget.Character:FindFirstChild("HumanoidRootPart")
                   if stayTarget and stayTarget.Parent == Players and stayRoot and myRootNow then
                       local dest = stayRoot.CFrame * SHADOW_FOLLOW_OFFSET
                       placePlatformUnder(dest.Position)
                       myRootNow.CFrame = dest
                       _G.TAYJAY_WARP_STAY = true; _G.TAYJAY_FOLLOW = nil
                       selectedDeathNoteTarget = nil
                       syncButtonState("DNWarp", false)
                   end
               end
               -- เลือกจากรายชื่อ: ตามคนที่เลือกไว้ (ไม่สุ่ม ไม่จำกัดระยะ)
               local dnChar = selectedDeathNoteTarget and selectedDeathNoteTarget.Character
               local dnHum = dnChar and dnChar:FindFirstChildOfClass("Humanoid")
               local dnGone = selectedDeathNoteTarget and (selectedDeathNoteTarget.Parent ~= Players or (dnHum ~= nil and dnHum.Health <= 0))
                if dnGone then
                   -- เป้าหมายตาย/ออก: กลับจุดยืน แล้วปิดโหมดและยกเลิกการเลือก
                   goHome(myRootNow)
                   selectedDeathNoteTarget = nil
                   syncButtonState("DNWarp", false)
               else
                   targetPlayer = selectedDeathNoteTarget
               end
           end
           if isDeathNoteTargetLocked and (not lockedDeathNoteTarget or lockedDeathNoteTarget.Parent ~= Players) then
               lockedDeathNoteTarget = nil
               isDeathNoteTargetLocked = false
               shadowTargetReleased = true
               updateTargetLockVisual()
               if states.AutoWarp then syncButtonState("AutoWarp", false) end
               targetPlayer = nil
           end
           local targetCharacter = targetPlayer and targetPlayer.Character
           local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
           local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
           local myCharacter = LocalPlayer.Character
           local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
           local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")

           if targetPlayer and targetPlayer ~= LocalPlayer and targetRoot and targetHumanoid and targetHumanoid.Health > 0 and myRoot and myHumanoid and myHumanoid.Health > 0 then
               if shadowHiddenCharacter ~= myCharacter then
                   if shadowHiddenCharacter then setInvisibility(shadowHiddenCharacter, false) end
                   setInvisibility(myCharacter, true)
                   shadowHiddenCharacter = myCharacter
               end

               -- Initial approach / respawn retarget; never moves above or attaches to the target's head.
               if lastShadowTarget ~= targetPlayer or lastShadowCharacter ~= targetCharacter then
                   myRoot.Anchored = false
                   myHumanoid.Sit = false
                   if warpActive then placePlatformUnder((targetRoot.CFrame * SHADOW_FOLLOW_OFFSET).Position) end; myRoot.CFrame = targetRoot.CFrame * SHADOW_FOLLOW_OFFSET; _G.TAYJAY_WARP_HOLD_UNTIL = os.clock() + (_G.TAYJAY_WARP_HOLD or 0)
                   lastShadowTarget = targetPlayer
                   lastShadowCharacter = targetCharacter
               else
                   -- Follow at a modest update rate to avoid writing CFrame every rendered frame.
                   myRoot.Anchored = false
                   myHumanoid.Sit = false
                   if warpActive then placePlatformUnder((targetRoot.CFrame * SHADOW_FOLLOW_OFFSET).Position) end
               end

               if warpActive and myRoot then placePlatformUnder(myRoot.Position) end
               _G.TAYJAY_FOLLOW = {player = targetPlayer}
               targetTitle.Text = (states.KillAura and "🕶 WARP: " or "🕶 DN: ") .. targetPlayer.Name
               local hp = math.max(0, math.floor(targetHumanoid.Health))
               local maxHp = math.max(1, math.floor(targetHumanoid.MaxHealth))
               targetHpLabel.Text = hp .. " / " .. maxHp .. " HP  •  " .. (AttackRemote and "FOLLOW + ATTACK" or "FOLLOW • NO ATTACK REMOTE")
               targetBarFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
               if AttackRemote then tryAttackTarget(targetCharacter) end
           else
               if shadowHiddenCharacter then
                   setInvisibility(shadowHiddenCharacter, false)
                   shadowHiddenCharacter = nil
               end
               lastShadowTarget = nil
               lastShadowCharacter = nil
               if isDeathNoteTargetLocked and targetPlayer then
                   lockedDeathNoteTarget = nil
                   isDeathNoteTargetLocked = false
                   shadowTargetReleased = true
                   updateTargetLockVisual()
                   if states.AutoWarp then syncButtonState("AutoWarp", false) end
                   targetTitle.Text = "⚠ Locked target unavailable • stopped"
               else
                   if states.KillAura then
                       targetTitle.Text = os.clock() < warpRestUntil and "🕶 WARP: กลับจุดยืน • รอเป้าหมายใหม่" or ("🕶 WARP: ไม่พบผู้เล่นในแมพ")
                   else
                       targetTitle.Text = targetPlayer and "⚠ Target unavailable" or "☠ Select target in Death Note"
                   end
               end
               targetHpLabel.Text = states.KillAura and "Searching the whole map..." or "Choose a living player in Death Note, then enable DN WARP"
               targetBarFill.Size = UDim2.new(0, 0, 1, 0)
           end
       end
   end
   stopShadowHunterVisuals()
end)

-- =========================================================
-- 👾 MONSTER WARP (แยกจาก Player WARP)
-- ค้นหา Monster ใน Workspace (แยก NPC ออกเป็นกลุ่มต่างหาก สลับได้ที่ปุ่ม MONSTER / NPC ในแผง)
-- แล้วติดตามเป้าหมายที่ใกล้จุดเริ่มต้นที่สุด
-- ระบบนี้ไม่เปลี่ยน Death Note, Player WARP, WALK หรือคำสั่งเดิมอื่น ๆ
-- =========================================================
-- ห่อด้วย do + pcall (ไม่ใช้ "(function() ... end)()" ที่ขึ้นต้นบรรทัดใหม่ เพราะ Luau มองว่าเป็น
-- Ambiguous syntax และ Lua จะอ่านเป็นการเรียกผลลัพธ์ของ task.spawn(...) ซ้อน → สคริปต์ล้มทั้งไฟล์)
-- pcall ทำให้ถ้า M-WARP พัง ส่วนอื่นของสคริปต์ยังทำงานต่อ และรายงานสาเหตุขึ้นจอ
do
local okMW, errMW = pcall(function()
   local monsterWarpButton = Instance.new("TextButton", screenGui)
   monsterWarpButton.Name = "TayJayMonsterWarpBtn"
   monsterWarpButton.AnchorPoint = Vector2.new(0.5, 0.5)
   monsterWarpButton.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize)
   monsterWarpButton.Position = UI_LAYOUT.MonsterWarpCenter
   monsterWarpButton.BackgroundColor3 = GREEN.off
   monsterWarpButton.RichText = true
   monsterWarpButton.Text = '<font size="25">👾</font>\n<font size="13">M-WARP</font>\n<font size="10">OFF</font>'
   monsterWarpButton.TextColor3 = WHITE_TEXT
   monsterWarpButton.Font = Enum.Font.GothamBlack
   monsterWarpButton.TextSize = 15
   monsterWarpButton.Active = true
   monsterWarpButton.AutoButtonColor = true
   Instance.new("UICorner", monsterWarpButton).CornerRadius = UDim.new(1, 0)
   local monsterWarpStroke = Instance.new("UIStroke", monsterWarpButton)
   monsterWarpStroke.Color = Color3.fromRGB(255, 145, 70)
   monsterWarpStroke.Thickness = 2.5
   makeDraggable(monsterWarpButton)

   local monsterPanel = Instance.new("Frame", screenGui)
   monsterPanel.Name = "TayJayMonsterTargetPanel"
   monsterPanel.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, 128)
   monsterPanel.Position = UI_LAYOUT.MonsterTargetPanel
   monsterPanel.BackgroundColor3 = GREEN.dark
   monsterPanel.BackgroundTransparency = 0.03
   monsterPanel.Visible = false
   Instance.new("UICorner", monsterPanel).CornerRadius = UDim.new(0, 12)
   local monsterPanelStroke = Instance.new("UIStroke", monsterPanel)
   monsterPanelStroke.Name = "TayJayWindowAccent"
   monsterPanelStroke.Color = Color3.fromRGB(255, 145, 70)
   monsterPanelStroke.Thickness = 2.2
   makeDraggable(monsterPanel)

   local monsterTitle = Instance.new("TextLabel", monsterPanel)
   monsterTitle.Name = "MonsterTargetTitle"
   monsterTitle.Size = UDim2.new(1, -38, 0, 22)
   monsterTitle.Position = UDim2.fromOffset(9, 4)
   monsterTitle.BackgroundTransparency = 1
   monsterTitle.Text = "👾 MONSTER WARP: OFF"
   monsterTitle.TextColor3 = WHITE_TEXT
   monsterTitle.TextStrokeColor3 = TEXT_OUTLINE
   monsterTitle.TextStrokeTransparency = 0.45
   monsterTitle.Font = Enum.Font.GothamBold
   monsterTitle.TextSize = 12
   monsterTitle.TextXAlignment = Enum.TextXAlignment.Left

   local monsterHealthBG = Instance.new("Frame", monsterPanel)
   monsterHealthBG.Name = "MonsterHealthBG"
   monsterHealthBG.Size = UDim2.new(1, -18, 0, 10)
   monsterHealthBG.Position = UDim2.fromOffset(9, 31)
   monsterHealthBG.BackgroundColor3 = Color3.fromRGB(65, 74, 63)
   monsterHealthBG.BorderSizePixel = 0
   Instance.new("UICorner", monsterHealthBG).CornerRadius = UDim.new(1, 0)

   local monsterHealthFill = Instance.new("Frame", monsterHealthBG)
   monsterHealthFill.Name = "MonsterHealthFill"
   monsterHealthFill.Size = UDim2.new(0, 0, 1, 0)
   monsterHealthFill.BackgroundColor3 = Color3.fromRGB(255, 145, 70)
   monsterHealthFill.BorderSizePixel = 0
   Instance.new("UICorner", monsterHealthFill).CornerRadius = UDim.new(1, 0)

   -- ===== ตัวกรองกลุ่มเป้าหมาย: Monster / NPC (แยกกันชัดเจน) =====
   local MONSTER_COLOR = Color3.fromRGB(255, 145, 70)
   local NPC_COLOR = Color3.fromRGB(70, 190, 255)
   local monsterFilterMode = "Monster" -- "Monster" = ตีเฉพาะมอนสเตอร์ | "NPC" = เฉพาะ NPC

   local filterRow = Instance.new("Frame", monsterPanel)
   filterRow.Name = "MonsterFilterRow"
   filterRow.Size = UDim2.new(1, -18, 0, 26)
   filterRow.Position = UDim2.fromOffset(9, 46)
   filterRow.BackgroundTransparency = 1
   local filterLayout = Instance.new("UIListLayout", filterRow)
   filterLayout.FillDirection = Enum.FillDirection.Horizontal
   filterLayout.Padding = UDim.new(0, 6)
   filterLayout.SortOrder = Enum.SortOrder.LayoutOrder

   local function makeFilterButton(name, text, order)
       local b = Instance.new("TextButton")
       b.Name = name
       b.LayoutOrder = order
       b.Size = UDim2.new(0.5, -3, 1, 0)
       b.BackgroundColor3 = Color3.fromRGB(65, 74, 63)
       b.Text = text
       b.TextColor3 = WHITE_TEXT
       b.Font = Enum.Font.GothamBold
       b.TextSize = 12
       b.AutoButtonColor = true
       b.Active = true
       b.Parent = filterRow
       Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
       return b
   end
   local monsterFilterBtn = makeFilterButton("FilterMonsterBtn", "👾 MONSTER", 1)
   local npcFilterBtn = makeFilterButton("FilterNpcBtn", "🧑 NPC", 2)

   local monsterCountLabel = Instance.new("TextLabel", monsterPanel)
   monsterCountLabel.Name = "MonsterFilterCount"
   monsterCountLabel.Size = UDim2.new(1, -18, 0, 14)
   monsterCountLabel.Position = UDim2.fromOffset(9, 76)
   monsterCountLabel.BackgroundTransparency = 1
   monsterCountLabel.RichText = true
   monsterCountLabel.Text = "👾 Monster: 0  |  🧑 NPC: 0"
   monsterCountLabel.TextColor3 = WHITE_TEXT
   monsterCountLabel.Font = Enum.Font.GothamBold
   monsterCountLabel.TextSize = 11
   monsterCountLabel.TextXAlignment = Enum.TextXAlignment.Left

   local monsterInfo = Instance.new("TextLabel", monsterPanel)
   monsterInfo.Name = "MonsterTargetInfo"
   monsterInfo.Size = UDim2.new(1, -18, 0, 28)
   monsterInfo.Position = UDim2.fromOffset(9, 93)
   monsterInfo.BackgroundTransparency = 1
   monsterInfo.Text = "ปิดอยู่ • กด M-WARP เพื่อเริ่มค้นหา"
   monsterInfo.TextColor3 = WHITE_TEXT
   monsterInfo.TextStrokeColor3 = TEXT_OUTLINE
   monsterInfo.TextStrokeTransparency = 0.48
   monsterInfo.Font = Enum.Font.Gotham
   monsterInfo.TextSize = 11
   monsterInfo.TextWrapped = true
   monsterInfo.TextXAlignment = Enum.TextXAlignment.Left

   local MONSTER_SCAN_ROOT_NAMES = {
       "HumanoidRootPart", "RootPart", "Root", "MonsterRoot", "MainPart",
       "PrimaryPart", "Torso", "UpperTorso", "LowerTorso", "Center"
   }
   -- Strict Monster-only allow rules for Bug Evolution. A Humanoid by itself
   -- is NOT evidence that a Model is a monster: player avatars and map props
   -- may also contain Humanoids.
   local MONSTER_NAME_HINTS = {
       "monster", "mob", "enemy", "boss", "creature", "ant", "beetle",
       "spider", "scorpion", "worm", "bug", "moth", "larva", "mantis",
       "crab", "slime", "dragon", "zombie", "insect", "mothstand", "void moth",
       "voidmoth", "蝎"
   }
   -- NPC = ตัวละครที่ไม่ใช่ศัตรู (ร้านค้า/เควสต์/ผู้ช่วย ฯลฯ) → แยกเป็นกลุ่ม NPC เสมอ
   local NPC_NAME_HINTS = {
       "npc", "shop", "shopkeeper", "merchant", "vendor", "quest", "questgiver",
       "trainer", "dealer", "banker", "guide", "villager", "citizen",
       "blacksmith", "seller", "cashier", "innkeeper", "mentor", "receptionist"
   }
   -- ชื่อโฟลเดอร์/โมเดลแม่ที่บอกว่าข้างในเป็น NPC
   local NPC_CONTAINER_HINTS = { "npc", "npcs", "shop", "shops", "vendor", "vendors", "merchant", "merchants", "safezone" }
   -- แอตทริบิวต์/แท็กที่เกมมักใช้ติดป้าย NPC
   local NPC_ATTRIBUTE_KEYS = { "IsNPC", "isNPC", "NPC", "Npc", "IsShop", "Shop", "Interactable", "Friendly", "QuestGiver" }
   local NPC_TAG_NAMES = { "NPC", "Npc", "npc", "Shop", "Vendor", "QuestGiver" }
   -- ไม่ใช่ทั้ง Monster และ NPC (ของประกอบฉาก/เอฟเฟกต์) → ตัดทิ้ง
   local MONSTER_EXCLUDE_HINTS = {
       "dummy", "training", "player", "character", "pet", "egg", "tool", "weapon",
       "platform", "floor", "terrain", "stand", "spawn", "portal", "gate",
       "button", "trigger", "hitbox", "effect", "vfx", "drop", "coin",
       -- ของตั้งโชว์ / ประกอบฉาก / โมเดลจำลอง (เช่น VoidMothDisplay) ไม่ใช่มอนสเตอร์จริง
       "display", "statue", "preview", "showcase", "pedestal", "decor", "prop",
       "sign", "banner", "poster", "hologram", "mannequin", "corpse", "ragdoll",
       "viewport", "icon", "image", "fake", "dead"
   }
   -- โมเดลที่อยู่ใต้โฟลเดอร์/โมเดลแม่ชื่อเหล่านี้ ถือเป็นของตั้งโชว์ → ตัดทิ้ง
   local DISPLAY_CONTAINER_HINTS = {
       "display", "displays", "statue", "statues", "decor", "decoration", "decorations",
       "prop", "props", "preview", "showcase", "viewport", "hologram", "cosmetics"
   }
   -- หลักฐานว่าเป็นศัตรูจริง (ใช้เมื่อโมเดลไม่มี Humanoid/ค่า Health)
   local MONSTER_CONTAINER_HINTS = {
       "monster", "monsters", "enemy", "enemies", "mob", "mobs", "boss", "bosses", "creatures"
   }
   local MONSTER_TAG_NAMES = { "Monster", "Enemy", "Mob", "Boss" }
   local MONSTER_ATTRIBUTE_KEYS = { "IsMonster", "IsEnemy", "Enemy", "Monster", "Mob" }

   local monsterCandidates = {}
   local monsterBlockedUntil = setmetatable({}, { __mode = "k" }) -- model -> เวลาที่หมดการพัก
   local monsterTrackedTarget = nil
   local monsterNoticeText, monsterNoticeUntil = "", 0
   local monsterCollisionSaved = {}
   local monsterScanDirty = true
   local monsterLastScan = 0
   local monsterCurrent = nil
   local monsterHome = nil
   local monsterOwner = nil
   local monsterLastRoot = nil
   local monsterHiddenCharacter = nil
   local monsterPlatform = nil
   local monsterLastAttack = 0
   local monsterNextSelectAt = 0
   local monsterWarpWasOn = false
   local monsterWarpStarting = false
   local MONSTER_SCAN_MIN_INTERVAL = 0.8
   local MONSTER_FOLLOW_INTERVAL = 0.12
   -- Go straight to the monster's root instead of stopping several studs away.
   local MONSTER_FOLLOW_OFFSET = CFrame.new(0, 0, 0)
   local MONSTER_PLATFORM_SIZE = Vector3.new(16, 1, 16)
   local MONSTER_FEET_DROP = 3
   local MONSTER_SEARCH_RANGE = math.huge
   local MONSTER_STUCK_SECONDS = 10   -- HP ไม่เปลี่ยนนานเท่านี้ = ตีไม่เข้า (ของตกแต่ง/อมตะ/เข้าไม่ถึง) → ข้าม
   local MONSTER_BLOCK_SECONDS = 60   -- พักเป้าที่ถูกข้ามไว้นานเท่านี้
   local MONSTER_SNAP_DISTANCE = 0.2  -- ขยับตัวละครเฉพาะเมื่อห่างเกินระยะนี้ (กันสั่นจากการแก้ตำแหน่งจิ๋ว ๆ)

   local function getMonsterRoot(model, humanoid)
       if humanoid then
           local ok, root = pcall(function() return humanoid.RootPart end)
           if ok and root and root:IsA("BasePart") then return root end
       end
       if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
           return model.PrimaryPart
       end
       for _, rootName in ipairs(MONSTER_SCAN_ROOT_NAMES) do
           local found = model:FindFirstChild(rootName, true)
           if found and found:IsA("BasePart") then return found end
       end
       -- Never select an arbitrary body/accessory/prop part as a target root.
       -- Models without a recognized root are rejected instead of warping at a map part.
       return nil
   end

   -- แยกชื่อเป็นคำ (CamelCase / _ / ช่องว่าง / ตัวเลข) แล้วเทียบเป็นคำ
   -- กันเคสผิด เช่น "Giant", "Plant", "Mobile", "Wormhole" ที่ไม่ใช่มอนสเตอร์
   local tokenCache = {}
   local function nameTokens(name)
       local key = tostring(name or "")
       local cached = tokenCache[key]
       if cached then return cached[1], cached[2] end
       local spaced = key
       spaced = spaced:gsub("(%l)(%u)", "%1 %2")
       spaced = spaced:gsub("(%a)(%d)", "%1 %2")
       spaced = spaced:gsub("(%d)(%a)", "%1 %2")
       spaced = string.lower((spaced:gsub("[^%w\128-\255]+", " ")))
       local tokens = {}
       for word in string.gmatch(spaced, "%S+") do table.insert(tokens, word) end
       local lowerName = string.lower(key)
       tokenCache[key] = { tokens, lowerName }
       return tokens, lowerName
   end

   -- คำสั้น (<5 ตัวอักษร) ต้องตรงทั้งคำ (หรือเติม s) ส่วนคำยาวยอมให้เป็นส่วนหนึ่งของชื่อ เช่น "FireBeetle"
   local function matchesHint(name, hints)
       local tokens, lowerName = nameTokens(name)
       for _, hint in ipairs(hints) do
           if string.find(hint, " ", 1, true) then
               if string.find(lowerName, hint, 1, true) then return true end
           else
               local longHint = #hint >= 5 or string.find(hint, "[\128-\255]") ~= nil
               for _, token in ipairs(tokens) do
                   if token == hint or token == hint .. "s" then return true end
                   if longHint and string.find(token, hint, 1, true) then return true end
               end
           end
       end
       return false
   end

   local function hasMonsterNameHint(name)
       return matchesHint(name, MONSTER_NAME_HINTS)
   end

   local function isExcludedMonsterName(name)
       return matchesHint(name, MONSTER_EXCLUDE_HINTS)
   end

   local function hasNpcNameHint(name)
       -- "npc" ติดอยู่ในชื่อที่ไหนก็ถือเป็น NPC (เช่น "NPC_Ant", "AntNPC", "npcGuide")
       if string.find(string.lower(tostring(name or "")), "npc", 1, true) then return true end
       return matchesHint(name, NPC_NAME_HINTS)
   end

   local CollectionServiceRef = game:GetService("CollectionService")

   -- หลักฐาน NPC ที่ "แน่นอน": ชื่อ / โฟลเดอร์แม่ / แอตทริบิวต์ / แท็ก
   local function hasStrongNpcEvidence(model)
       if hasNpcNameHint(model.Name) then return true, "name" end
       -- เดินขึ้นไปดูโมเดลแม่/โฟลเดอร์ (ลูกของ NPC ถือเป็น NPC ด้วย)
       local parent = model.Parent
       while parent and parent ~= workspace and parent ~= game do
           local parentName = string.lower(parent.Name)
           if hasNpcNameHint(parent.Name) or string.find(parentName, "safezone", 1, true)
               or matchesHint(parent.Name, NPC_CONTAINER_HINTS) then
               return true, "parent:" .. parent.Name
           end
           parent = parent.Parent
       end
       for _, key in ipairs(NPC_ATTRIBUTE_KEYS) do
           local ok, value = pcall(function() return model:GetAttribute(key) end)
           if ok and value ~= nil and value ~= false and value ~= 0 and value ~= "" then
               return true, "attr:" .. key
           end
       end
       for _, tag in ipairs(NPC_TAG_NAMES) do
           local ok, tagged = pcall(function() return CollectionServiceRef:HasTag(model, tag) end)
           if ok and tagged then return true, "tag:" .. tag end
       end
       return false
   end

   -- หลักฐาน NPC แบบ "อ่อน": มีปุ่มคุย/คลิก (ProximityPrompt/ClickDetector/Dialog)
   -- ใช้ตัดสินเฉพาะโมเดลที่ชื่อไม่เข้าข่ายมอนสเตอร์ เพื่อไม่ให้มอนสเตอร์จริงถูกจัดเป็น NPC ผิด
   local function hasInteractionEvidence(model)
       return model:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
           or model:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
           or model:FindFirstChildWhichIsA("Dialog", true) ~= nil
   end

   local function readHealthAttribute(model)
       for _, key in ipairs({ "Health", "HP", "CurrentHealth" }) do
           local ok, value = pcall(function() return model:GetAttribute(key) end)
           if ok and type(value) == "number" then
               local maxHp = 0
               for _, maxKey in ipairs({ "MaxHealth", "MaxHP" }) do
                   local ok2, mv = pcall(function() return model:GetAttribute(maxKey) end)
                   if ok2 and type(mv) == "number" then maxHp = mv break end
               end
               return value, maxHp
           end
       end
       return nil
   end

   -- มีแหล่งค่าพลังชีวิตจริงหรือไม่ (Humanoid / NumberValue Health / Attribute)
   local function hasHealthSource(model, humanoid)
       if humanoid then
           local ok, maxHp = pcall(function() return humanoid.MaxHealth end)
           if ok and (tonumber(maxHp) or 0) > 0 then return true end
       end
       local hv = model:FindFirstChild("Health", true)
       if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then return true end
       return readHealthAttribute(model) ~= nil
   end

   local function isInDisplayContainer(model)
       local camera = workspace.CurrentCamera
       if camera and model:IsDescendantOf(camera) then return true end
       local parent = model.Parent
       while parent and parent ~= workspace and parent ~= game do
           if matchesHint(parent.Name, DISPLAY_CONTAINER_HINTS) then return true end
           parent = parent.Parent
       end
       return false
   end

   -- หลักฐานว่าเป็นศัตรู: อยู่ในโฟลเดอร์ Monsters/Enemies หรือมีแท็ก/แอตทริบิวต์ศัตรู
   local function hasMonsterEvidence(model)
       local parent = model.Parent
       while parent and parent ~= workspace and parent ~= game do
           if matchesHint(parent.Name, MONSTER_CONTAINER_HINTS) then return true end
           parent = parent.Parent
       end
       for _, tag in ipairs(MONSTER_TAG_NAMES) do
           local ok, tagged = pcall(function() return CollectionServiceRef:HasTag(model, tag) end)
           if ok and tagged then return true end
       end
       for _, key in ipairs(MONSTER_ATTRIBUTE_KEYS) do
           local ok, value = pcall(function() return model:GetAttribute(key) end)
           if ok and value == true then return true end
       end
       return false
   end

   -- ผลลัพธ์: "Monster" | "NPC" | nil  และ (ตัวที่ 3) true = ไม่มีค่า HP แต่มีหลักฐานว่าเป็นศัตรู
   local function classifyModel(model, humanoid)
       local monsterNamed = hasMonsterNameHint(model.Name)
       local npcNamed = hasNpcNameHint(model.Name)
       if isExcludedMonsterName(model.Name) and not npcNamed then return nil end
       if not monsterNamed and not npcNamed and not humanoid then return nil end
       -- ของตั้งโชว์/พร็อพ/โมเดลในกล้อง ไม่ใช่ทั้ง Monster และ NPC
       if isInDisplayContainer(model) then return nil end

       local strongNpc, npcReason = hasStrongNpcEvidence(model)
       if strongNpc then return "NPC", npcReason end
       if monsterNamed then
           -- ชื่อเข้าข่ายอย่างเดียวไม่พอ: ต้องมี HP จริง หรืออยู่ในกลุ่ม/แท็กศัตรู
           if hasHealthSource(model, humanoid) then return "Monster", "name+hp" end
           if hasMonsterEvidence(model) then return "Monster", "name+container", true end
           return nil
       end
       if humanoid and hasInteractionEvidence(model) then return "NPC", "interaction" end
       return nil
   end

   -- allowNoHealth = true เฉพาะเป้าที่ยืนยันแล้วว่าไม่มีค่า HP (NPC / ศัตรูในโฟลเดอร์ Monsters)
   -- นอกนั้น "ไม่มี HP" = ไม่ใช่เป้าที่ตีได้ (เดิมถือว่ามีชีวิต 1/1 ทำให้ล็อกของตั้งโชว์)
   local function readMonsterHealth(model, humanoid, allowNoHealth)
       if humanoid then
           local hp = math.max(0, tonumber(humanoid.Health) or 0)
           local maxHp = math.max(1, tonumber(humanoid.MaxHealth) or 1)
           return hp, maxHp, hp > 0
       end
       local healthValue = model:FindFirstChild("Health", true)
       if healthValue and (healthValue:IsA("NumberValue") or healthValue:IsA("IntValue")) then
           local hp = math.max(0, tonumber(healthValue.Value) or 0)
           local maxValue = model:FindFirstChild("MaxHealth", true)
           local maxHp = math.max(hp, 1)
           if maxValue and (maxValue:IsA("NumberValue") or maxValue:IsA("IntValue")) then
               maxHp = math.max(1, tonumber(maxValue.Value) or maxHp)
           end
           return hp, maxHp, hp > 0
       end
       local attrHp, attrMax = readHealthAttribute(model)
       if attrHp then
           local hp = math.max(0, attrHp)
           return hp, math.max(1, attrMax > 0 and attrMax or hp), hp > 0
       end
       if allowNoHealth then return 1, 1, model.Parent ~= nil end
       return 0, 1, false
   end

   local function isPlayerCharacter(model, playerCharacters)
       if playerCharacters[model] then return true end
       for character in pairs(playerCharacters) do
           if model:IsDescendantOf(character) then return true end
       end
       return false
   end

   local monsterGroupCounts = { Monster = 0, NPC = 0 }

   local function scanMonsterModels()
       local playerCharacters = {}
       for _, player in ipairs(Players:GetPlayers()) do
           if player.Character then playerCharacters[player.Character] = true end
       end

       local found, seen = {}, {}
       local counts = { Monster = 0, NPC = 0 }
       for _, obj in ipairs(workspace:GetDescendants()) do
           if obj:IsA("Model") and obj.Parent and not seen[obj] then
               seen[obj] = true
               if not isPlayerCharacter(obj, playerCharacters) then
                   local humanoid = obj:FindFirstChildOfClass("Humanoid")
                   -- Monster ต้องมีชื่อเข้าข่ายเสมอ (Humanoid อย่างเดียวไม่พอ)
                   -- NPC จัดแยกด้วยชื่อ/โฟลเดอร์/แอตทริบิวต์/แท็ก/ปุ่มคุย
                   local kind, reason, noHealth = classifyModel(obj, humanoid)
                   if kind then
                       local root = getMonsterRoot(obj, humanoid)
                       if root and root:IsDescendantOf(obj) then
                           local allowNoHealth = (kind == "NPC") or noHealth == true
                           local hp, maxHp, alive = readMonsterHealth(obj, humanoid, allowNoHealth)
                           counts[kind] = counts[kind] + 1
                           table.insert(found, {
                               model = obj,
                               humanoid = humanoid,
                               root = root,
                               name = obj.Name,
                               kind = kind,
                               reason = reason,
                               allowNoHealth = allowNoHealth,
                               health = hp,
                               maxHealth = maxHp,
                               alive = alive
                           })
                       end
                   end
               end
           end
       end

       table.sort(found, function(a, b)
           return string.lower(a.name) < string.lower(b.name)
       end)
       monsterCandidates = found
       monsterGroupCounts = counts
       monsterScanDirty = false
       monsterLastScan = os.clock()
       return counts[monsterFilterMode] or 0, counts
   end

   local function isMonsterAlive(candidate)
       if not candidate or not candidate.model or not candidate.model.Parent then return false end
       local model = candidate.model
       -- ต้องเป็นกลุ่มที่เลือกอยู่เท่านั้น (Monster หรือ NPC) ไม่ปนกัน
       if candidate.kind ~= monsterFilterMode then return false end
       -- เป้าที่ถูกข้ามเพราะตีไม่เข้า (HP ไม่เปลี่ยน) จะถูกพักไว้ชั่วคราว
       local blockedUntil = monsterBlockedUntil[model]
       if blockedUntil and os.clock() < blockedUntil then return false end
       for _, player in ipairs(Players:GetPlayers()) do
           local playerCharacter = player.Character
           if playerCharacter and (model == playerCharacter or model:IsDescendantOf(playerCharacter)) then
               return false
           end
       end
       local humanoid = model:FindFirstChildOfClass("Humanoid")
       local hp, maxHp, alive = readMonsterHealth(model, humanoid, candidate.allowNoHealth)
       candidate.humanoid = humanoid
       candidate.health = hp
       candidate.maxHealth = maxHp
       candidate.alive = alive
       candidate.root = getMonsterRoot(model, humanoid)
       return alive and candidate.root ~= nil
   end

   local function nearestMonster(origin, ignoreModel)
       local best, bestDistance = nil, MONSTER_SEARCH_RANGE
       for _, candidate in ipairs(monsterCandidates) do
           if candidate.model ~= ignoreModel and isMonsterAlive(candidate) then
               local distance = (candidate.root.Position - origin).Magnitude
               if distance < bestDistance then
                   best = candidate
                   bestDistance = distance
               end
           end
       end
       return best
   end

   local function setMonsterPanelStatus(titleText, infoText, hp, maxHp)
       if monsterFilterMode == "NPC" then
           titleText = string.gsub(titleText, "👾 MONSTER", "🧑 NPC")
           infoText = string.gsub(infoText, "Monster", "NPC")
       end
       monsterTitle.Text = titleText
       monsterInfo.Text = infoText
       local ratio = math.clamp((tonumber(hp) or 0) / math.max(tonumber(maxHp) or 1, 1), 0, 1)
       monsterHealthFill.Size = UDim2.new(ratio, 0, 1, 0)
       monsterHealthFill.BackgroundColor3 = ratio <= 0.25 and Color3.fromRGB(255, 85, 65)
           or ratio <= 0.55 and Color3.fromRGB(255, 190, 65)
           or (monsterFilterMode == "NPC" and NPC_COLOR or MONSTER_COLOR)
   end

   local function modeLabel()
       return monsterFilterMode == "NPC" and "NPC" or "Monster"
   end

   local function refreshMonsterFilterUI()
       local isMonster = monsterFilterMode == "Monster"
       monsterFilterBtn.BackgroundColor3 = isMonster and MONSTER_COLOR or Color3.fromRGB(65, 74, 63)
       npcFilterBtn.BackgroundColor3 = (not isMonster) and NPC_COLOR or Color3.fromRGB(65, 74, 63)
       monsterFilterBtn.TextTransparency = isMonster and 0 or 0.35
       npcFilterBtn.TextTransparency = (not isMonster) and 0 or 0.35
       monsterHealthFill.BackgroundColor3 = isMonster and MONSTER_COLOR or NPC_COLOR
       monsterPanelStroke.Color = isMonster and MONSTER_COLOR or NPC_COLOR
       local m, n = monsterGroupCounts.Monster or 0, monsterGroupCounts.NPC or 0
       local monsterTxt = string.format("👾 Monster: %d", m)
       local npcTxt = string.format("🧑 NPC: %d", n)
       monsterCountLabel.Text = isMonster
           and string.format('<font color="#FFB27A"><b>%s</b></font>  |  <font color="#9AA79A">%s (ไม่ตี)</font>', monsterTxt, npcTxt)
           or string.format('<font color="#9AA79A">%s (ไม่ตี)</font>  |  <font color="#7FD6FF"><b>%s</b></font>', monsterTxt, npcTxt)
   end

   local function updateMonsterWarpVisual()
       local on = states.MonsterWarp == true
       monsterWarpButton.BackgroundColor3 = on and GREEN.on or GREEN.off
       monsterWarpStroke.Color = on and Color3.fromRGB(255, 210, 90) or (monsterFilterMode == "NPC" and NPC_COLOR or MONSTER_COLOR)
       monsterWarpButton.Text = '<font size="25">👾</font>\n<font size="13">M-WARP</font>\n<font size="10">' .. (on and "ON" or "OFF") .. '</font>'
       monsterPanel.Visible = on
       refreshMonsterFilterUI()
       if not on then
           setMonsterPanelStatus("👾 MONSTER WARP: OFF", "ปิดอยู่ • กด M-WARP เพื่อเริ่มค้นหา", 0, 1)
       end
   end

   local function ensureMonsterPlatform()
       if not monsterPlatform or not monsterPlatform.Parent then
           local part = Instance.new("Part")
           part.Name = "TayJayMonsterWarpPlatform"
           part.Anchored = true
           part.CanCollide = true
           part.Size = MONSTER_PLATFORM_SIZE
           part.Transparency = 1
           part.TopSurface = Enum.SurfaceType.Smooth
           part.BottomSurface = Enum.SurfaceType.Smooth
           part.Parent = workspace
           monsterPlatform = part
       end
       return monsterPlatform
   end

   local function placeMonsterPlatform(position)
       local platform = ensureMonsterPlatform()
       platform.CFrame = CFrame.new(
           position.X,
           position.Y - MONSTER_FEET_DROP - MONSTER_PLATFORM_SIZE.Y / 2,
           position.Z
       )
   end

   local function destroyMonsterPlatform()
       local old = monsterPlatform
       monsterPlatform = nil
       if old then
           task.delay(1, function()
               if old.Parent then pcall(function() old:Destroy() end) end
           end)
       end
   end

   -- ปิดการชนของตัวละครตัวเองระหว่างติดตาม: ไม่งั้นตัวมอนสเตอร์ดัน/ชนตัวละคร แล้วโดนดึงกลับทุกครั้ง = กระตุก
   local function monsterDisableCollision(character)
       for _, part in ipairs(character:GetDescendants()) do
           if part:IsA("BasePart") and part.CanCollide then
               monsterCollisionSaved[part] = true
               part.CanCollide = false
           end
       end
   end

   local function monsterRestoreCollision()
       for part in pairs(monsterCollisionSaved) do
           if part and part.Parent then pcall(function() part.CanCollide = true end) end
           monsterCollisionSaved[part] = nil
       end
   end

   -- วางตัวละครบนเป้าหมาย "ทุกเฟรม" (เดิมทำทุก 0.12 วิ ระหว่างนั้นฟิสิกส์ดึง/ตก จึงสั่นเป็นจังหวะ)
   local function monsterGlueStep()
       if not states.MonsterWarp then return end
       local target = monsterCurrent
       local targetRoot = target and target.root
       if not targetRoot or not targetRoot.Parent then return end
       local character = LocalPlayer.Character
       if not character or character ~= monsterOwner then return end
       local myRoot = character:FindFirstChild("HumanoidRootPart")
       if not myRoot then return end
       local destination = targetRoot.CFrame * MONSTER_FOLLOW_OFFSET
       myRoot.AssemblyLinearVelocity = Vector3.zero
       myRoot.AssemblyAngularVelocity = Vector3.zero
       if monsterLastRoot ~= targetRoot or (myRoot.Position - destination.Position).Magnitude > MONSTER_SNAP_DISTANCE then
           myRoot.CFrame = destination
           monsterLastRoot = targetRoot
       end
   end

   stopMonsterWarp = function(returnHome)
       if not states.MonsterWarp and not monsterWarpWasOn then return end
       states.MonsterWarp = false
       monsterCurrent = nil
       monsterLastRoot = nil
       monsterTrackedTarget = nil
       monsterRestoreCollision()
       if monsterHiddenCharacter then
           setInvisibility(monsterHiddenCharacter, false)
           monsterHiddenCharacter = nil
       end
       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       if returnHome ~= false and monsterHome and monsterOwner == character and root then
           root.Anchored = false
           root.AssemblyLinearVelocity = Vector3.zero
           root.AssemblyAngularVelocity = Vector3.zero
           root.CFrame = monsterHome
       end
       monsterHome = nil
       monsterOwner = nil
       monsterWarpWasOn = false
       destroyMonsterPlatform()
       updateMonsterWarpVisual()
   end

   local function startMonsterWarp()
       if states.MonsterWarp then
           stopMonsterWarp(true)
           return
       end
       if monsterWarpStarting then return end
       resolveExclusiveMode("MonsterWarp")
       monsterWarpStarting = true

       -- Only one warp controller may move the local character at a time.
       -- Allow the original player-WARP loop to return to its saved home before capturing this mode's home.
       if states.KillAura then states.KillAura = false end
       if states.DNWarp then syncButtonState("DNWarp", false) end
       if states.AutoWarp then syncButtonState("AutoWarp", false) end
       updateKaBtnDisplay()
       monsterPanel.Visible = true
       setMonsterPanelStatus("👾 MONSTER WARP: SWITCHING", "กำลังหยุดระบบ WARP ผู้เล่นก่อนเริ่มค้นหา Monster...", 0, 1)
       task.wait(0.20)

       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       local humanoid = character and character:FindFirstChildOfClass("Humanoid")
       if not character or not root or not humanoid or humanoid.Health <= 0 then
           monsterWarpStarting = false
           monsterPanel.Visible = false
           setMonsterPanelStatus("👾 MONSTER WARP: WAIT", "ไม่พบตัวละครที่พร้อมใช้งาน", 0, 1)
           return
       end

       states.MonsterWarp = true
       monsterHome = root.CFrame
       monsterOwner = character
       monsterCurrent = nil
       monsterLastRoot = nil
       monsterScanDirty = true
       monsterLastScan = 0
       monsterLastAttack = 0
       monsterNextSelectAt = 0
       monsterTrackedTarget = nil
       monsterNoticeText, monsterNoticeUntil = "", 0
       table.clear(monsterBlockedUntil)
       monsterWarpWasOn = true
       monsterWarpStarting = false
       setMonsterPanelStatus("👾 MONSTER WARP: SCANNING", "กำลังค้นหาเฉพาะ " .. modeLabel() .. " • แยกกลุ่มให้แล้ว...", 0, 1)
       updateMonsterWarpVisual()
   end

   local function setMonsterFilter(mode)
       if monsterFilterMode == mode then return end
       monsterFilterMode = mode
       -- เปลี่ยนกลุ่ม → ทิ้งเป้าเดิมทันที แล้วเลือกใหม่จากกลุ่มที่เลือก
       monsterCurrent = nil
       monsterLastRoot = nil
       monsterNextSelectAt = 0
       if monsterHiddenCharacter then
           setInvisibility(monsterHiddenCharacter, false)
           monsterHiddenCharacter = nil
       end
       refreshMonsterFilterUI()
       updateMonsterWarpVisual()
       if states.MonsterWarp then
           setMonsterPanelStatus("👾 MONSTER WARP: SWITCHING",
               "เปลี่ยนตัวกรองเป็น " .. modeLabel() .. " • กำลังเลือกเป้าหมายใหม่...", 0, 1)
       end
   end
   trackConnection(monsterFilterBtn.Activated:Connect(function() setMonsterFilter("Monster") end))
   trackConnection(npcFilterBtn.Activated:Connect(function() setMonsterFilter("NPC") end))

   trackConnection(monsterWarpButton.Activated:Connect(startMonsterWarp))
   trackConnection(workspace.DescendantAdded:Connect(function(obj)
       if obj:IsA("Model") or obj:IsA("Humanoid") then
           monsterScanDirty = true
       elseif obj:IsA("BasePart") then
           local lower = string.lower(obj.Name)
           if lower == "humanoidrootpart" or lower == "rootpart" or lower == "root" or lower == "monsterroot" or lower == "mainpart" then
               monsterScanDirty = true
           end
       end
   end))
   trackConnection(workspace.DescendantRemoving:Connect(function(obj)
       if obj:IsA("Model") or obj:IsA("Humanoid") then
           monsterScanDirty = true
       end
   end))
   trackConnection(LocalPlayer.CharacterAdded:Connect(function()
       if states.MonsterWarp then stopMonsterWarp(false) end
   end))

   trackConnection(RunService.Heartbeat:Connect(monsterGlueStep))
   do
       local okPre, preRender = pcall(function() return RunService.PreRender end)
       if okPre and preRender then trackConnection(preRender:Connect(monsterGlueStep)) end
   end

   -- Throttled scan/follow loop: no per-frame Workspace:GetDescendants() calls.
   task.spawn(function()
       local followAccumulator = 0
       while screenGui.Parent do
           local dt = RunService.Heartbeat:Wait()
           if not states.MonsterWarp then
               followAccumulator = 0
           else
               local now = os.clock()
               local character = LocalPlayer.Character
               local myRoot = character and character:FindFirstChild("HumanoidRootPart")
               local myHumanoid = character and character:FindFirstChildOfClass("Humanoid")

               if not character or character ~= monsterOwner or not myRoot or not myHumanoid or myHumanoid.Health <= 0 then
                   stopMonsterWarp(false)
               else
                   followAccumulator = followAccumulator + dt
                   if (monsterScanDirty or (now - monsterLastScan) >= 2.5)
                       and (now - monsterLastScan) >= MONSTER_SCAN_MIN_INTERVAL then
                       local count = scanMonsterModels()
                       refreshMonsterFilterUI()
                       if count == 0 then
                           setMonsterPanelStatus("👾 MONSTER WARP: SEARCHING", "ยังไม่พบ Monster • ระบบจะค้นหาอีกเมื่อมีโมเดลใหม่", 0, 1)
                       else
                           setMonsterPanelStatus("👾 MONSTER WARP: FOUND " .. tostring(count), "พบเป้าหมาย • กำลังเลือก Monster ที่ใกล้ที่สุด", 0, 1)
                       end
                   end

                   if followAccumulator >= MONSTER_FOLLOW_INTERVAL then
                       followAccumulator = 0
                       local target = monsterCurrent
                       if target then
                           local previousRoot = target.root
                           if not isMonsterAlive(target) then
                               local oldPosition = previousRoot and previousRoot.Parent and previousRoot.Position or myRoot.Position
                               local oldModel = target.model
                               monsterCurrent = nil
                               monsterLastRoot = nil
                               target = nil
                               if now >= monsterNextSelectAt then
                                   target = nearestMonster(oldPosition, oldModel)
                                   monsterCurrent = target
                                   monsterNextSelectAt = now + 0.55
                               end
                           end
                       elseif now >= monsterNextSelectAt then
                           local origin = monsterHome and monsterHome.Position or myRoot.Position
                           target = nearestMonster(origin, nil)
                           monsterCurrent = target
                           monsterNextSelectAt = now + 0.7
                       end

                       if target and target ~= monsterTrackedTarget then
                           monsterTrackedTarget = target
                           target.lastHp = nil
                           target.hpChangedAt = now
                       end

                       local alive = target ~= nil and isMonsterAlive(target)
                       if alive and not target.allowNoHealth then
                           -- เป้าที่ "ตีได้จริง" ต้องมี HP เปลี่ยน ถ้านิ่งเกินกำหนด = ของตกแต่ง/อมตะ/เข้าไม่ถึง → ข้าม
                           local hpNow = target.health
                           if target.lastHp == nil or math.abs(hpNow - target.lastHp) > 0.01 then
                               target.lastHp = hpNow
                               target.hpChangedAt = now
                           elseif now - target.hpChangedAt >= MONSTER_STUCK_SECONDS then
                               monsterBlockedUntil[target.model] = now + MONSTER_BLOCK_SECONDS
                               monsterNoticeText = "ข้าม " .. tostring(target.name) .. " (HP ไม่เปลี่ยน " .. tostring(MONSTER_STUCK_SECONDS) .. " วิ)"
                               monsterNoticeUntil = now + 4
                               monsterCurrent = nil
                               monsterLastRoot = nil
                               monsterTrackedTarget = nil
                               monsterNextSelectAt = 0
                               alive = false
                           end
                       end

                       if alive then
                           local hp, maxHp = target.health, target.maxHealth
                           if monsterHiddenCharacter ~= character then
                               if monsterHiddenCharacter then setInvisibility(monsterHiddenCharacter, false) end
                               setInvisibility(character, true)
                               monsterHiddenCharacter = character
                           end
                           monsterDisableCollision(character)
                           if myRoot.Anchored then myRoot.Anchored = false end
                           if myHumanoid.Sit then myHumanoid.Sit = false end
                           -- การวางตำแหน่งทำใน monsterGlueStep ทุกเฟรม (ไม่ทำที่นี่แล้ว เพื่อไม่ให้กระตุก)
                           -- Remote โจมตีทั่วไปไม่ถูกเรียกจากโหมดนี้ (กันพลาดไปโจมตีผู้เล่น):
                           -- ใช้ AUTO ATK / ปุ่มโจมตีของเกมเองตอนอยู่บนมอนสเตอร์
                           local notice = (now < monsterNoticeUntil) and ("\n⚠ " .. monsterNoticeText) or ""
                           setMonsterPanelStatus(
                               "👾 MONSTER: " .. tostring(target.name),
                               string.format("HP %d / %d  •  LOCKED", math.floor(hp), math.floor(maxHp)) .. notice,
                               hp, maxHp
                           )
                       else
                           if monsterHiddenCharacter then
                               setInvisibility(monsterHiddenCharacter, false)
                               monsterHiddenCharacter = nil
                           end
                           -- No monster found: hold the current position and keep scanning.
                           -- Do not warp back to the saved start/home point; that can look
                           -- like a false target selection on large maps.
                           setMonsterPanelStatus("👾 MONSTER WARP: SEARCHING",
                               "ยังไม่พบ Monster ที่ยืนยันได้ • ยืนรอและค้นหาใหม่"
                                   .. ((now < monsterNoticeUntil) and ("\n⚠ " .. monsterNoticeText) or ""), 0, 1)
                       end
                   end
               end
           end
       end
       if states.MonsterWarp then stopMonsterWarp(false) end
   end)

   updateMonsterWarpVisual()
end)
if not okMW then
   pcall(function() warn("[TAYJAY M-WARP] initialization failed: " .. tostring(errMW)) end)
   pcall(function()
       if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", "M-WARP: " .. tostring(errMW)) end
   end)
end
end

task.spawn(function()
   while screenGui.Parent do
       task.wait(0.05)
       if states.NormalKillAura and AttackRemote and not isBusy then
           local targetChar = getClosestPlayer_V57(25)
           if targetChar and targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid.Health > 0 then
               tryAttackTarget(targetChar)
           end
       end
   end
end)

-- =========================================================
-- 🌐 SERVER SELECTOR
-- =========================================================
local serverFrame = Instance.new("Frame", screenGui)
serverFrame.Name = "TayJayServerSelector"; serverFrame.Size = UDim2.new(0, UI_LAYOUT.PanelW, 0, UI_LAYOUT.PanelH); serverFrame.Position = UDim2.fromScale(0.7250, 0.3480); serverFrame.BackgroundColor3 = Color3.fromRGB(48, 166, 76); serverFrame.Visible = false
Instance.new("UICorner", serverFrame).CornerRadius = UDim.new(0, 14); local serverFrameStroke = Instance.new("UIStroke", serverFrame); serverFrameStroke.Name = "TayJayWindowAccent"; serverFrameStroke.Thickness = 2.5; serverFrameStroke.Color = UI_LAYOUT.Accent.Server
makeDraggable(serverFrame)

local sfTitle = Instance.new("TextLabel", serverFrame)
sfTitle.Size = UDim2.new(1, -62, 0, 30); sfTitle.Position = UDim2.new(0, 10, 0, 2); sfTitle.BackgroundTransparency = 1; sfTitle.Text = "🌍 เซิร์ฟเวอร์ | ผู้เล่นมาก → น้อย"; sfTitle.TextColor3 = WHITE_TEXT; sfTitle.Font = Enum.Font.GothamBold; sfTitle.TextSize = 15; sfTitle.TextXAlignment = Enum.TextXAlignment.Left
local sfClose = Instance.new("TextButton", serverFrame); sfClose.Size = UDim2.new(0, 22, 0, 22); sfClose.Position = UDim2.new(1, -28, 0, 5); sfClose.BackgroundColor3 = Color3.fromRGB(255, 132, 24); sfClose.Text = "✕"; sfClose.TextColor3 = WHITE_TEXT; Instance.new("UICorner", sfClose).CornerRadius = UDim.new(1, 0)
trackConnection(sfClose.Activated:Connect(function() syncButtonState("ServerSelector", false); serverFrame.Visible = false end))

local sfRefresh = Instance.new("TextButton", serverFrame)
sfRefresh.Name = "RefreshServers"; sfRefresh.Size = UDim2.new(1, -20, 0, 32); sfRefresh.Position = UDim2.new(0, 10, 0, 34)
sfRefresh.BackgroundColor3 = Color3.fromRGB(185, 145, 28); sfRefresh.Text = "↻  โหลดรายชื่อเซิร์ฟเวอร์"
sfRefresh.TextColor3 = WHITE_TEXT; sfRefresh.Font = Enum.Font.GothamBold; sfRefresh.TextSize = 14
Instance.new("UICorner", sfRefresh).CornerRadius = UDim.new(0,8)

local sfStatus = Instance.new("TextLabel", serverFrame)
sfStatus.Size = UDim2.new(1, -20, 0, 22); sfStatus.Position = UDim2.new(0, 10, 0, 67)
sfStatus.BackgroundTransparency = 1; sfStatus.Text = "กดโหลดเพื่อค้นหาเซิร์ฟเวอร์"
sfStatus.TextColor3 = WHITE_TEXT; sfStatus.Font = Enum.Font.Gotham; sfStatus.TextSize = 13

local sfList = Instance.new("ScrollingFrame", serverFrame)
sfList.Name = "ServerList"; sfList.Size = UDim2.new(1, -20, 1, -104); sfList.Position = UDim2.new(0, 10, 0, 95)
sfList.BackgroundColor3 = Color3.fromRGB(36, 142, 68); sfList.BorderSizePixel = 0
sfList.ScrollBarThickness = 5; sfList.CanvasSize = UDim2.new(0,0,0,0); sfList.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", sfList).CornerRadius = UDim.new(0,8)
local sfListLayout = Instance.new("UIListLayout", sfList)
sfListLayout.Padding = UDim.new(0,5); sfListLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sfListPadding = Instance.new("UIPadding", sfList)
sfListPadding.PaddingTop = UDim.new(0,6); sfListPadding.PaddingBottom = UDim.new(0,6)
sfListPadding.PaddingLeft = UDim.new(0,6); sfListPadding.PaddingRight = UDim.new(0,6)

local function getHttpRequest()
   if type(request) == "function" then return request end
   if type(http_request) == "function" then return http_request end
   if syn and type(syn.request) == "function" then return syn.request end
   return nil
end

local function clearServerRows()
   for _, child in ipairs(sfList:GetChildren()) do
       if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
   end
end

local function addServerRow(server, order)
   local row = Instance.new("TextButton")
   row.Name = "Server_" .. tostring(order); row.LayoutOrder = order
   row.Size = UDim2.new(1, -4, 0, 44); row.BackgroundColor3 = Color3.fromRGB(65, 116, 48)
   row.Text = string.format("ผู้เล่น %d/%d   |   เข้าร่วมเซิร์ฟเวอร์", server.playing or 0, server.maxPlayers or 0)
   row.TextColor3 = WHITE_TEXT; row.Font = Enum.Font.GothamBold; row.TextSize = 14
   row.TextWrapped = true; row.AutoButtonColor = true; row.Parent = sfList
   Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
   trackConnection(row.Activated:Connect(function()
       if type(server.id) == "string" and server.id ~= "" then
           sfStatus.Text = "กำลังเชื่อมต่อเซิร์ฟเวอร์..."
           local ok, err = pcall(function()
               game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
           end)
           if not ok then sfStatus.Text = "เข้าเซิร์ฟเวอร์ไม่สำเร็จ: " .. tostring(err) end
       end
   end))
end

local serverLoadBusy = false
local function loadPublicServers()
   if serverLoadBusy then return end
   local httpRequest = getHttpRequest()
   if not httpRequest then
       sfStatus.Text = "Executor นี้ไม่มี HTTP request API"
       return
   end
   serverLoadBusy = true; sfRefresh.Active = false; sfRefresh.Text = "กำลังโหลด..."
   sfStatus.Text = "กำลังดึงรายชื่อเซิร์ฟเวอร์..."
   clearServerRows()
   task.spawn(function()
       local allServers, cursor, pages = {}, "", 0
       local ok, err = pcall(function()
           repeat
               local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId)
                   .. "/servers/Public?sortOrder=Desc&limit=100"
               if cursor ~= "" then url = url .. "&cursor=" .. game:GetService("HttpService"):UrlEncode(cursor) end
               local response = httpRequest({Url=url, Method="GET"})
               if not response or (response.StatusCode and response.StatusCode ~= 200) then
                   error("Roblox API ตอบกลับไม่สำเร็จ")
               end
               local body = response.Body or response.body
               local decoded = game:GetService("HttpService"):JSONDecode(body)
               for _, server in ipairs(decoded.data or {}) do
                   if server.id and server.playing and server.maxPlayers
                       and server.playing < server.maxPlayers then
                       table.insert(allServers, server)
                   end
               end
               cursor = decoded.nextPageCursor or ""
               pages = pages + 1
           until cursor == "" or pages >= 5
       end)

       if ok then
           table.sort(allServers, function(a,b)
               if a.playing == b.playing then return a.maxPlayers > b.maxPlayers end
               return a.playing > b.playing
           end)
           for index, server in ipairs(allServers) do addServerRow(server, index) end
           sfStatus.Text = string.format("พบ %d เซิร์ฟเวอร์ | เรียงผู้เล่นมากไปน้อย", #allServers)
           if #allServers == 0 then
               sfStatus.Text = "ไม่พบเซิร์ฟเวอร์ว่าง หรือ API ไม่ส่งข้อมูล"
           end
       else
           sfStatus.Text = "โหลดไม่สำเร็จ: " .. tostring(err)
       end
       serverLoadBusy = false; sfRefresh.Active = true; sfRefresh.Text = "↻  โหลดรายชื่อเซิร์ฟเวอร์"
   end)
end
trackConnection(sfRefresh.Activated:Connect(loadPublicServers))

-- =========================================================
-- 🔘 MAIN MENU UI
-- =========================================================
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Name = "TayJayMainToggle"
toggleBtn.Size = UDim2.fromOffset(UI_LAYOUT.ToggleSize, UI_LAYOUT.ToggleSize); toggleBtn.Position = UDim2.fromScale(0.0120, 0.2000)
toggleBtn.BackgroundColor3 = GREEN.mid; toggleBtn.Text = ""; toggleBtn.AutoButtonColor = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
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

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "TayJayMainMenu"
mainFrame.Size = UDim2.fromOffset(UI_LAYOUT.MainW, UI_LAYOUT.MainH); mainFrame.Position = UI_LAYOUT.MainMenu; mainFrame.BackgroundColor3 = GREEN.dark; mainFrame.Visible = true; mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18); local mainMenuStroke = Instance.new("UIStroke", mainFrame); mainMenuStroke.Name = "TayJayWindowAccent"; mainMenuStroke.Color = UI_LAYOUT.Accent.Main; mainMenuStroke.Thickness = 2.5
makeDraggable(mainFrame)
trackConnection(toggleBtn.Activated:Connect(function() mainFrame.Visible = not mainFrame.Visible end))
-- Compact tablet layout: main menu and Death Note share a tidy two-column row.
local function applyCompactTabletLayout()
   local camera = workspace.CurrentCamera
   if not camera then return end
   local viewport = camera.ViewportSize
   local narrow = viewport.X < 900
   if narrow then
      mainFrame.Size = UDim2.fromOffset(250, 400)
      mainFrame.Position = UDim2.new(0, 8, 0, 104)
      deathNoteGroup.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH)
      deathNoteGroup.Position = UDim2.new(0, 268, 0, 104)
   else
      mainFrame.Size = UDim2.fromOffset(UI_LAYOUT.MainW, UI_LAYOUT.MainH)
      mainFrame.Position = UI_LAYOUT.MainMenu
      deathNoteGroup.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, UI_LAYOUT.PanelH)
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

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -14, 1, -62); scroll.Position = UDim2.new(0, 7, 0, 56); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = GREEN.neon
local list = Instance.new("UIListLayout", scroll); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0, 6)

local function createBtn(order, text, key)
   local btn = Instance.new("TextButton", scroll)
   btn.Size = UDim2.new(1, -4, 0, 40); btn.BackgroundColor3 = GREEN.off; btn.Text = text .. " : OFF"; btn.TextColor3 = WHITE_TEXT; btn.Font = Enum.Font.GothamBold; btn.LayoutOrder = order
   btn.TextScaled = true; btn.TextWrapped = false
   local btnSize = Instance.new("UITextSizeConstraint", btn); btnSize.MaxTextSize = 14; btnSize.MinTextSize = 9
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11); local btnEdge = Instance.new("UIStroke", btn); btnEdge.Color = GREEN.warning; btnEdge.Thickness = 2.0; btnEdge.Transparency = 0

   local function updateVisual(isOn)
       btn.BackgroundColor3 = isOn and GREEN.on or GREEN.off
       btn.TextColor3 = WHITE_TEXT
       btn.TextStrokeTransparency = 0.48
       btnEdge.Color = isOn and Color3.fromRGB(105, 255, 224) or Color3.fromRGB(255, 205, 74)
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
       elseif key == "Fly" then
           if isOn then FlyFrame.Visible = true end
           if not isOn and flyNowe then stopFlying(false) end
       elseif key == "DeathNote" then
           deathNoteGroup.Visible = isOn
           deathNoteMain.Visible = isOn
           if isOn then task.defer(updatePlayerList) end
       elseif key == "ServerSelector" then serverFrame.Visible = isOn; if isOn and #sfList:GetChildren() <= 2 then loadPublicServers() end
       elseif key == "ESP" then
           if _G.TAYJAY_SET_ESP then _G.TAYJAY_SET_ESP(isOn) end
       end
   end)
   updateVisual(states[key])
   trackConnection(btn.Activated:Connect(function()
       if key == "Fly" then
           if states.Fly then
               syncButtonState("Fly", false)
               FlyFrame.Visible = false
           elseif FlyFrame.Visible then
               FlyFrame.Visible = false
           else
               syncButtonState("Fly", true)
               FlyFrame.Visible = true
           end
       else
           syncButtonState(key, not states[key])
       end
   end))
end

createBtn(1, "1. 🚀 ความเร็ว (Speed)", "Speed")
createBtn(2, "2. 🛸 โหมดบิน (Fly)", "Fly")
createBtn(3, "3. 🌌 กระโดดไร้ขีดจำกัด (Inf Jump)", "InfJump")
createBtn(4, "4. 🔍 มองทะลุ (X-Ray)", "Xray")
createBtn(5, "5. ☠️ สมุดสั่งตาย (Death Note)", "DeathNote")
createBtn(6, "6. 🌍 หาเซิร์ฟว่าง (Server Selector)", "ServerSelector")
createBtn(7, "7. 👁 ESP ผู้เล่น (TayJay)", "ESP")

trackConnection(list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20) end))

-- =========================================================
-- LOGIC SYSTEMS
-- =========================================================

-- AutoWarp menu toggle shares the Death Note Shadow Hunter loop above.
-- The empty legacy Stepped warp was removed to prevent competing CFrame controllers.

-- LOGIC หลักอื่นๆ
trackConnection(RunService.RenderStepped:Connect(function()
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if states.Speed and hum then
       if originalWalkSpeed == nil then originalWalkSpeed = hum.WalkSpeed end
       hum.WalkSpeed = config.WalkSpeed
   end
end))

trackConnection(UserInputService.JumpRequest:Connect(function()
   if states.InfJump and LocalPlayer.Character then
       local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
       if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
   end
end))

local noclipCache = {}
local function setNoclip(enabled)
   local char = LocalPlayer.Character
   if enabled and char then
       for _, part in ipairs(char:GetDescendants()) do
           if part:IsA("BasePart") then
               if noclipCache[part] == nil then noclipCache[part] = part.CanCollide end
               part.CanCollide = false
           end
       end
   else
       for part, wasCollidable in pairs(noclipCache) do
           if part and part.Parent then part.CanCollide = wasCollidable end
           noclipCache[part] = nil
       end
   end
end

registerUiSync("Noclip", setNoclip)
trackConnection(RunService.Stepped:Connect(function()
   if states.Noclip then setNoclip(true) end
end))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   table.clear(noclipCache)
   originalWalkSpeed = nil
end))

local xrayCache = {}
registerUiSync("Xray", function(isOn)
   for _, part in ipairs(workspace:GetDescendants()) do
       if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) and not part:IsA("Terrain") then
           if isOn then
               if xrayCache[part] == nil then xrayCache[part] = part.LocalTransparencyModifier end
               part.LocalTransparencyModifier = 0.65
           else
               if xrayCache[part] ~= nil then part.LocalTransparencyModifier = xrayCache[part]; xrayCache[part] = nil end
           end
       end
   end
end)

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

local function applyEspToCharacter(character)
   if not character or not character.Parent then return end
   local head = character:FindFirstChild("Head")
   local humanoid = character:FindFirstChildOfClass("Humanoid")
   if not head or not humanoid then return end
   local mm2OverlayVisible = _G.TAYJAY_MM2_UI_VISIBLE ~= false
   if not states.ESP and (not states.MM2RoleESP or not mm2OverlayVisible) then
       local existingHighlight = character:FindFirstChild(ESP_HIGHLIGHT)
       if existingHighlight then existingHighlight.Enabled = false end
       local existingBillboard = head:FindFirstChild(ESP_NAME)
       if existingBillboard then existingBillboard.Enabled = false end
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
   highlight.Enabled = states.ESP or (states.MM2RoleESP and mm2OverlayVisible)

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

   billboard.Enabled = states.ESP or (states.MM2RoleESP and mm2OverlayVisible)
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
       espBoundCharacters[character] = true
       trackConnection(humanoid.HealthChanged:Connect(function(health)
           if not healthLabel or not healthLabel.Parent then return end
           local maxHp = math.max(1, math.floor(humanoid.MaxHealth + 0.5))
           healthLabel.Text = tostring(math.max(0, math.floor(health + 0.5))) .. " / " .. tostring(maxHp) .. " HP"
       end))
       trackConnection(humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
           if not healthLabel or not healthLabel.Parent then return end
           local hp = math.max(0, math.floor(humanoid.Health + 0.5))
           local maxHp = math.max(1, math.floor(humanoid.MaxHealth + 0.5))
           healthLabel.Text = tostring(hp) .. " / " .. tostring(maxHp) .. " HP"
       end))
   end
end

local function setTayJayESPEnabled(isOn)
   states.ESP = isOn == true
   local mm2OverlayVisible = _G.TAYJAY_MM2_UI_VISIBLE ~= false
   for _, player in ipairs(Players:GetPlayers()) do
       local character = player.Character
       if character then
           if states.ESP then
               applyEspToCharacter(character)
           else
               local shouldKeepMM2 = states.MM2RoleESP == true and mm2OverlayVisible
               local highlight = character:FindFirstChild(ESP_HIGHLIGHT)
               if highlight then highlight.Enabled = shouldKeepMM2 end
               local head = character:FindFirstChild("Head") or character.PrimaryPart
               local billboard = head and head:FindFirstChild(ESP_NAME)
               if billboard then billboard.Enabled = shouldKeepMM2 end
           end
       end
   end
end
_G.TAYJAY_SET_ESP = setTayJayESPEnabled

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
           applyEspToCharacter(character)
       end)
   end))
end

for _, player in ipairs(Players:GetPlayers()) do
   bindEspPlayer(player)
end
trackConnection(Players.PlayerAdded:Connect(bindEspPlayer))

task.spawn(function()
   while screenGui.Parent do
       task.wait(0.75)
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer and player.Character then
               local character = player.Character
               if character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") then
                   applyEspToCharacter(character)
               end
           end
       end
   end
end)

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
   mm2ListFrame.Size = UDim2.new(0, 258, 0, 292)
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

   local function getMM2PlayerRole(player)
       local character = player.Character
       local backpack = player:FindFirstChild("Backpack")
       local hasKnife, hasGun = false, false

       local function inspectTools(container)
           if not container then return end
           for _, item in ipairs(container:GetChildren()) do
               if item:IsA("Tool") then
                   local toolName = string.lower(item.Name)
                   if toolName == "knife" or toolName == "murdererknife" then
                       hasKnife = true
                   elseif toolName == "gun" or toolName == "sheriffgun" or toolName == "revolver" then
                       hasGun = true
                   end
               end
           end
       end
       inspectTools(character)
       inspectTools(backpack)

       if hasGun and hasKnife then
           return "Unknown", Color3.fromRGB(255, 220, 110), "❔"
       elseif hasGun then
           return "Sheriff*", Color3.fromRGB(65, 155, 255), "🔫"
       elseif hasKnife then
           return "Murderer*", Color3.fromRGB(255, 65, 65), "🔪"
       end
       return "Unknown", Color3.fromRGB(255, 220, 110), "❔"
   end

   local function teleportAndAttack(targetPlayer)
       if isBusy or flyNowe or states.Fly or targetPlayer == LocalPlayer then return end

       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       local targetCharacter = targetPlayer.Character
       local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
       if not (root and targetRoot) then return end

       isBusy = true
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
           local followConnection
           followConnection = trackConnection(RunService.RenderStepped:Connect(function()
               if tick() - startTime > 2 then
                   if followConnection then followConnection:Disconnect() end
                   return
               end

               local currentTargetCharacter = targetPlayer.Character
               local currentTargetRoot = currentTargetCharacter and currentTargetCharacter:FindFirstChild("HumanoidRootPart")
               local currentCharacter = LocalPlayer.Character
               local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
               if currentTargetRoot and currentRoot then
                   currentRoot.CFrame = currentTargetRoot.CFrame * CFrame.new(0, 0, 2.5)
                   local targetHumanoid = currentTargetCharacter:FindFirstChildOfClass("Humanoid")
                   if targetHumanoid and targetHumanoid.Health > 0 then
                       tryAttackTarget(currentTargetCharacter)
                   end
               end
           end))

           task.wait(2.1)
           local currentCharacter = LocalPlayer.Character
           local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
           if currentRoot then
               currentRoot.CFrame = originalCFrame
           end
       end)
       isBusy = false
       if not ok then warn("[TAYJAY MM2] Follow action stopped: " .. tostring(err)) end
   end

   local mm2ESPEnabled = false
   registerShutdownHook(function()
       mm2ESPEnabled = false
       states.MM2RoleESP = false
       clearMM2RoleESP()
       mm2ListFrame.Visible = false
   end)
   local function updateMM2RoleESP()
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer and player.Character then
               local roleName, roleColor = getMM2PlayerRole(player)
               local character = player.Character
               applyEspToCharacter(character)
               local highlight = character:FindFirstChild("TayJay_PlayerHighlight")

               if not highlight then
                   highlight = Instance.new("Highlight")
                   highlight.Name = "TayJay_PlayerHighlight"
                   highlight.Adornee = character
                   highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                   highlight.Parent = character
               end
               local roleUiVisible = _G.TAYJAY_MM2_UI_VISIBLE ~= false
               highlight.Enabled = roleUiVisible or states.ESP == true
               if roleUiVisible then
                   highlight.FillColor = roleColor
                   highlight.OutlineColor = roleColor
                   highlight.FillTransparency = 0.6
                   highlight.OutlineTransparency = 0.1
               elseif states.ESP then
                   highlight.FillColor = ESP_FILL
                   highlight.OutlineColor = ESP_OUTLINE
                   highlight.FillTransparency = 0.78
                   highlight.OutlineTransparency = 0.08
               end

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
                   roleLabel.Visible = roleUiVisible
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
                   highlight.Enabled = states.ESP == true
                   highlight.FillColor = ESP_FILL
                   highlight.OutlineColor = ESP_OUTLINE
                   highlight.FillTransparency = 0.78
                   highlight.OutlineTransparency = 0.08
               end
               local head = character:FindFirstChild("Head") or character.PrimaryPart
               local billboard = head and head:FindFirstChild("TayJay_PlayerESP")
               if billboard then
                   billboard.Enabled = states.ESP == true
                   local roleLabel = billboard:FindFirstChild("MM2RoleText")
                   if roleLabel then roleLabel:Destroy() end
                   billboard.Size = UDim2.new(0, 190, 0, 42)
               end
           end
       end
   end

   local function updateMM2PlayerList()
       if not mm2ListFrame.Visible then return end
       mm2ListTitle.Text = "👥 ผู้เล่นทั้งหมด (" .. math.max(0, #Players:GetPlayers() - 1) .. ")"

       for _, child in ipairs(mm2ScrollingFrame:GetChildren()) do
           if child:IsA("Frame") and not Players:FindFirstChild(child.Name) then
               child:Destroy()
           end
       end

       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer then
               local roleName, roleColor, roleIcon = getMM2PlayerRole(player)
               local row = mm2ScrollingFrame:FindFirstChild(player.Name)

               if not row then
                   row = Instance.new("Frame")
                   row.Name = player.Name
                   row.Size = UDim2.new(1, 0, 0, 48)
                   row.BackgroundColor3 = GREEN.panel
                   row.Parent = mm2ScrollingFrame
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
                   actionButton.Parent = row
                   Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 6)
                   trackConnection(actionButton.Activated:Connect(function()
                       teleportAndAttack(player)
                   end))
               else
                   local roleLabel = row:FindFirstChild("RoleLabel")
                   local actionButton = row:FindFirstChild("ActionBtn")
                   if roleLabel then
                       roleLabel.Text = roleName
                       roleLabel.TextColor3 = WHITE_TEXT
                   end
                   if actionButton then actionButton.Text = roleIcon end
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

-- =========================================================
-- 🌌 TAYJAY MIDNIGHT NEON THEME + CAMERA QUALITY OF LIFE
-- =========================================================
local originalCameraSettings = {}
pcall(function()
   originalCameraSettings.CameraMode = LocalPlayer.CameraMode
   originalCameraSettings.CameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
   originalCameraSettings.CameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance
   originalCameraSettings.DevCameraOcclusionMode = LocalPlayer.DevCameraOcclusionMode
end)
pcall(function()
   LocalPlayer.CameraMode = Enum.CameraMode.Classic
   LocalPlayer.CameraMaxZoomDistance = 70
   LocalPlayer.CameraMinZoomDistance = 0.5
   LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

local function isThemeContainer(obj)
   local names = {
       TayJayMainMenu=true, TayJayFlyControl=true, TayJaySpeedWidget=true,
       DeathNoteMain=true, TayJayServerSelector=true, TayJayMM2Dock=true,
       TayJayMM2PlayerList=true, TayJayTargetPanel=true, TayJayMonsterTargetPanel=true,
   }
   return names[obj.Name] == true
end

local function styleDynamicObject(obj)
   if not obj or isProtectedMainBrandPart(obj) then return end

   if obj:IsA("TextButton") then
       obj.Font = Enum.Font.GothamBold
       obj.AutoButtonColor = true
       local text = string.upper(tostring(obj.Text or ""))
       local isOn = text:find(" ON", 1, true) or text == "ON" or obj:GetAttribute("TayJayEnabled") == true
       local isOff = text:find("OFF", 1, true) or text == "OFF" or obj:GetAttribute("TayJayEnabled") == false
       if isOn then
           obj.BackgroundColor3 = GREEN.on
       elseif isOff then
           obj.BackgroundColor3 = GREEN.off
       end
   elseif obj:IsA("TextLabel") then
       obj.Font = Enum.Font.GothamBold
   elseif obj:IsA("TextBox") then
       obj.Font = Enum.Font.GothamBold
   elseif obj:IsA("ScrollingFrame") then
       obj.ScrollBarImageColor3 = GREEN.neon
   elseif obj:IsA("Frame") and isThemeContainer(obj) then
       obj.BackgroundColor3 = GREEN.dark
       if not obj:FindFirstChildOfClass("UIGradient") then
           local gradient = Instance.new("UIGradient")
           gradient.Color = ColorSequence.new({
               ColorSequenceKeypoint.new(0, GREEN.panel),
               ColorSequenceKeypoint.new(1, GREEN.dark),
           })
           gradient.Rotation = 90
           gradient.Parent = obj
       end
   end

   applyTayJayTextContrast(obj)

   if obj:IsA("UIStroke") and not isProtectedMainBrandPart(obj) and obj.Name ~= "TayJayWindowAccent" then
       obj.Color = GREEN.stroke
       obj.Thickness = math.clamp(obj.Thickness, 1.4, 2.8)
       obj.Transparency = 0.04
   end
end

local function applyGreenTheme(root)
   if not root then return end
   for _, obj in ipairs(root:GetDescendants()) do
       styleDynamicObject(obj)
   end
end
applyGreenTheme(screenGui)
trackConnection(screenGui.DescendantAdded:Connect(function(obj)
   task.defer(function()
       if obj and obj.Parent then styleDynamicObject(obj) end
   end)
end))

task.spawn(function()
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
   FrameWindowTime = 0, FrameWindowFrames = 0,
   OriginalFPSCap = originalFPSCap, FPSUnlock = true, FPSUnlockStatus = "STARTING",
   Options = {Shadows = true, Particles = true, PostEffects = true,
       Reflections = true, Water = true, Decals = false, Lights = false}
}
_G.TAYJAY_V70_PERF = V70Perf

local function v70Track(list, connection)
   table.insert(list, connection)
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

   local targetCap = V70Perf.FPSUnlock and 999 or (V70Perf.OriginalFPSCap or 60)
   local ok, err = pcall(setfpscap, targetCap)
   if not ok then
       V70Perf.FPSUnlockStatus = "FAILED"
       warn("[TAYJAY FPS] Could not apply FPS cap: " .. tostring(err))
       return false
   end

   V70Perf.FPSUnlockStatus = V70Perf.FPSUnlock and "ACTIVE" or "RESTORED"
   return true
end

local function v70RestoreFPSCap()
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

local function v70RestoreAll()
   V70Perf.ScanToken = V70Perf.ScanToken + 1
   V70Perf.Enabled = false
   for _, connection in ipairs(V70Perf.BoostConnections) do pcall(function() connection:Disconnect() end) end
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
    if not mode or not mode.opts then
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
   v70SetPreset("Balanced")
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
           scaleObject.Scale = scaleValue * 0.9
       end
   end
end
updatePerfScale()
if workspace.CurrentCamera then v70Track(V70Perf.MonitorConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePerfScale)) end
v70Track(V70Perf.MonitorConnections, perfGui.ChildAdded:Connect(function() task.defer(updatePerfScale) end))
V70Perf.GUI = perfGui

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
   for _, connection in ipairs(V70Perf.ContentConnections) do
       pcall(function() connection:Disconnect() end)
   end
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
   stroke(row, Color3.fromRGB(75, 205, 235), 1.4)
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
   stroke(b, Color3.fromRGB(255, 225, 92), 1.8)
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
        detail=unlockUnavailable and "Executor does not support the FPS cap command" or "ON requests 999 FPS; OFF restores the previous cap",
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
    local defs = {
        {"Shadows", "ปิดเงาของโลก", "Shadows"},
        {"Particles", "ปิดอนุภาคและเทรล", "Particles"},
        {"Post Effects", "ปิดเอฟเฟกต์ภาพหลัง", "PostEffects"},
        {"Reflections", "ลดการสะท้อนพื้นผิว", "Reflections"},
        {"Water", "ลดแอนิเมชันน้ำ", "Water"},
        {"Decals", "ซ่อนเดคัลและพื้นผิว", "Decals"},
        {"Dynamic Lights", "ปิดแสงไดนามิก", "Lights"},
    }
    for _, d in ipairs(defs) do
        local key = d[3]
        local on = V70Perf.Options[key] == true
        table.insert(list, {id="opt:"..key, name=d[1], detail=d[2], toggle=true, on=on,
            button=on and "ON" or "OFF",
            run=function() V70Perf.Options[key] = not V70Perf.Options[key]; v70ApplyOptions(); statusLabel.Text = "PROFILE: CUSTOM" end})
    end
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
        if string.find(string.lower(entry.name .. " " .. entry.detail), query, 1, true) then
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
       local unlockRow = rowLabel("UNLOCK FPS", unlockUnavailable and "Executor does not support setfpscap()" or "ปลดล็อก FPS สูงสุด • OFF จะคืนค่าเดิม")
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
       section("GRAPHICS OPTIONS")
       local definitions = {
           {"Shadows","Reduces world shadow rendering", "Shadows"},
           {"Particles","Disables particle and trail effects", "Particles"},
           {"Post Effects","Disables blur, bloom and color effects", "PostEffects"},
           {"Reflections","Removes reflective surface intensity", "Reflections"},
           {"Water","Reduces terrain water animation", "Water"},
           {"Decals","Hides decal and texture details", "Decals"},
           {"Dynamic Lights","Disables point, spot and surface lights", "Lights"}
       }
       for _, def in ipairs(definitions) do
           local r = rowLabel(def[1], def[2])
           local key = def[3]
           local toggle = actionButton(r, V70Perf.Options[key] and "ON" or "OFF", 54, function()
               V70Perf.Options[key] = not V70Perf.Options[key]
               v70ApplyOptions()
               renderTab()
           end)
           toggle.BackgroundColor3 = V70Perf.Options[key] and Color3.fromRGB(104, 211, 57) or Color3.fromRGB(166, 43, 38)
       end
       section("RESTORE")
       local restore = rowLabel("Restore original graphics", "Undo all changes made by FPS Booster")
       actionButton(restore, "RESTORE", 72, function()
           v70RestoreAll()
           V70Perf.Options = {Shadows=false, Particles=false, PostEffects=false, Reflections=false, Water=false, Decals=false, Lights=false}
           statusLabel.Text = "PROFILE: RESTORED"
           renderTab()
       end)
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
   BackgroundTransparency=1, Text=(lowPresetStarted and (v70FPSUnlockApplied() and "PROFILE: BALANCED  •  FPS UNLOCK ON" or "PROFILE: BALANCED  •  FPS UNLOCK N/A") or "PROFILE: BALANCED  •  APPLY FAILED"), TextColor3= WHITE_TEXT,
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
   if launcherDragging and not _G.TAYJAY_UI.locked and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
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
   if not V70Perf.Alive then return end
   v70RestoreAll()
   v70RestoreFPSCap()
   V70Perf.Alive = false
   for _, connection in ipairs(V70Perf.MonitorConnections) do pcall(function() connection:Disconnect() end) end
   table.clear(V70Perf.MonitorConnections)
   for _, connection in ipairs(V70Perf.ContentConnections) do pcall(function() connection:Disconnect() end) end
   table.clear(V70Perf.ContentConnections)
   if V70Perf.GUI then pcall(function() V70Perf.GUI:Destroy() end); V70Perf.GUI = nil end
   V70Perf.GraphBars = nil
   if _G.TAYJAY_V70_PERF == V70Perf then _G.TAYJAY_V70_PERF = nil end
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

-- 🔒 TAYJAY GLOBAL UI CONTROL: persistent controls for all three UI groups.
local controlGui = Instance.new("ScreenGui")
controlGui.Name = "TayJayControlGui"
controlGui.ResetOnSpawn = false
controlGui.DisplayOrder = 1000001
controlGui.IgnoreGuiInset = true
controlGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SecureParentGui(controlGui)

local bar = Instance.new("Frame", controlGui)
bar.Name = "TayJayControlBar"
bar.Size = UDim2.fromOffset(270, 46)
bar.Position = UDim2.fromOffset(12, 102)
bar.BackgroundColor3 = GREEN.deep
bar.BorderSizePixel = 0
bar.Active = true
bar.ZIndex = 10000
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local barEdge = Instance.new("UIStroke", bar)
barEdge.Color = UI_LAYOUT.Accent.Main
barEdge.Thickness = 1.5

local controlButtons = {}
local uiGroupState = {TAYJAY = true, MM2 = true, FPS = true}
local savedRootVisibility = {}
_G.TAYJAY_MM2_UI_VISIBLE = true

local function createControlButton(name, text, x, width, color)
    local button = Instance.new("TextButton", bar)
    button.Name = name
    button.Size = UDim2.fromOffset(width * 0.9, 36)
    button.Position = UDim2.fromOffset(x * 0.9, 5)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = WHITE_TEXT
    button.TextStrokeColor3 = TEXT_OUTLINE
    button.TextStrokeTransparency = 0.45
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = true
    button.ZIndex = 10001
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    controlButtons[name] = button
    return button
end

local function refreshGroupButton(group)
    local labels = {TAYJAY = "TAY", MM2 = "MM2", FPS = "FPS"}
    local button = controlButtons[group]
    if not button then return end
    local visible = uiGroupState[group] == true
    button.Text = labels[group] .. (visible and " ON" or " OFF")
    button.BackgroundColor3 = visible and GREEN.on or GREEN.off
end

local function setRootVisible(root, visible)
    if not root or not root.Parent then return end
    if savedRootVisibility[root] == nil then savedRootVisibility[root] = root.Visible end
    root.Visible = visible and savedRootVisibility[root] or false
end

local function setGroupVisible(group, visible)
    uiGroupState[group] = visible == true
    if group == "TAYJAY" then
        for _, root in ipairs(screenGui:GetChildren()) do
            if root:IsA("GuiObject") and root.Name ~= "TayJayMM2Dock" and root.Name ~= "TayJayMM2PlayerList" then
                setRootVisible(root, uiGroupState[group])
            end
        end
    elseif group == "MM2" then
        setRootVisible(screenGui:FindFirstChild("TayJayMM2Dock"), uiGroupState[group])
        setRootVisible(screenGui:FindFirstChild("TayJayMM2PlayerList"), uiGroupState[group])
        _G.TAYJAY_MM2_UI_VISIBLE = uiGroupState[group]
    elseif group == "FPS" then
        perfGui.Enabled = uiGroupState[group]
    end
    refreshGroupButton(group)
end

createControlButton("TAYJAY", "TAY ON", 6, 52, GREEN.on).Activated:Connect(function()
    setGroupVisible("TAYJAY", not uiGroupState.TAYJAY)
end)
createControlButton("MM2", "MM2 ON", 64, 52, GREEN.on).Activated:Connect(function()
    setGroupVisible("MM2", not uiGroupState.MM2)
end)
createControlButton("FPS", "FPS ON", 122, 52, GREEN.on).Activated:Connect(function()
    setGroupVisible("FPS", not uiGroupState.FPS)
end)
local lockBtn = createControlButton("GLOBAL_LOCK", "🔒", 180, 50, Color3.fromRGB(255, 132, 24))
local function refreshLock()
    local locked = _G.TAYJAY_UI.locked == true
    _G.TAYJAY_UI.locked = locked
    isWindowLocked = locked
    groupDragging = false
    for _, root in ipairs({screenGui, perfGui}) do
        if root then
            for _, object in ipairs(root:GetDescendants()) do
                if object:GetAttribute("TayJayWindowLocked") ~= nil then
                    object:SetAttribute("TayJayWindowLocked", locked)
                    local localLock = object:FindFirstChild("WindowLockButton")
                    if localLock then
                        localLock.Text = locked and "🔒" or "🔓"
                        localLock.BackgroundColor3 = locked and Color3.fromRGB(255, 132, 24) or Color3.fromRGB(76, 158, 48)
                    end
                end
            end
        end
    end
    if dnLock then
        dnLock.Text = locked and "🔒" or "🔓"
        dnLock.BackgroundColor3 = locked and Color3.fromRGB(255, 132, 24) or Color3.fromRGB(76, 158, 48)
    end
    lockBtn.Text = locked and "🔒" or "🔓"
    lockBtn.BackgroundColor3 = locked and Color3.fromRGB(255, 132, 24) or Color3.fromRGB(76, 158, 48)
end
trackConnection(lockBtn.Activated:Connect(function()
    _G.TAYJAY_UI.locked = not _G.TAYJAY_UI.locked
    refreshLock()
end))
local stopBtn = createControlButton("STOP_SCRIPT", "STOP", 236, 58, Color3.fromRGB(190, 45, 45))

local function shutdownTayJay()
    if _G.TAYJAY_SHUTDOWN_IN_PROGRESS then return end
    _G.TAYJAY_SHUTDOWN_IN_PROGRESS = true

    -- Switch all script features OFF before restoring their saved game state.
    local featureKeys = {"Speed", "Fly", "InfJump", "Noclip", "Xray", "ESP",
        "DeathNote", "KillAura", "NormalKillAura", "MonsterWarp", "ServerSelector",
        "MM2RoleESP", "AutoWarp", "DNWarp"}
    for _, key in ipairs(featureKeys) do
        if key == "KillAura" or key == "NormalKillAura" or key == "MonsterWarp" or key == "MM2RoleESP" then
            states[key] = false
        elseif uiSyncRegistry[key] then
            pcall(function() syncButtonState(key, false) end)
        else
            states[key] = false
        end
    end

    pcall(function() if stopFlying then stopFlying(false) end end)
    pcall(function() if stopMonsterWarp then stopMonsterWarp(true) end end)
    pcall(function() setNoclip(false) end)
    pcall(function()
        for part, oldTransparency in pairs(xrayCache) do
            if part and part.Parent then part.LocalTransparencyModifier = oldTransparency end
            xrayCache[part] = nil
        end
    end)

    for _, cleanup in ipairs(shutdownHooks) do pcall(cleanup) end
    table.clear(shutdownHooks)

    -- Remove any delayed warp platforms left by the movement controllers.
    for _, object in ipairs(workspace:GetDescendants()) do
        if object.Name == "TayJayWarpPlatform" or object.Name == "TayJayMonsterWarpPlatform" then
            pcall(function() object:Destroy() end)
        end
    end

    -- Restore transparency saved by Death Note and Monster Warp.
    for object, saved in pairs(originalTransparencies) do
        if object and object.Parent and saved then
            pcall(function()
                if saved.kind == "part" then
                    object.LocalTransparencyModifier = saved.value
                elseif saved.kind == "decal" then
                    object.Transparency = saved.value
                end
            end)
        end
        originalTransparencies[object] = nil
    end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and originalWalkSpeed ~= nil then
        pcall(function() humanoid.WalkSpeed = originalWalkSpeed end)
    end
    originalWalkSpeed = nil

    pcall(function()
        LocalPlayer.CameraMode = originalCameraSettings.CameraMode
        LocalPlayer.CameraMaxZoomDistance = originalCameraSettings.CameraMaxZoomDistance
        LocalPlayer.CameraMinZoomDistance = originalCameraSettings.CameraMinZoomDistance
        LocalPlayer.DevCameraOcclusionMode = originalCameraSettings.DevCameraOcclusionMode
    end)

    states.KillAura = false
    states.NormalKillAura = false
    states.MonsterWarp = false
    states.MM2RoleESP = false
    states.ESP = false
    _G.TAYJAY_FOLLOW = nil
    _G.TAYJAY_STAY_REQUEST = nil
    _G.TAYJAY_WARP_STAY = nil
    _G.TAYJAY_WARP_HOLD = nil
    _G.TAYJAY_WARP_HOLD_UNTIL = nil
    pcall(function() if updateKaBtnDisplay then updateKaBtnDisplay() end end)

    -- Remove shared player ESP objects after MM2 cleanup has run.
    for _, player in ipairs(Players:GetPlayers()) do
        local playerCharacter = player.Character
        if playerCharacter then
            local highlight = playerCharacter:FindFirstChild("TayJay_PlayerHighlight")
            if highlight then pcall(function() highlight:Destroy() end) end
            local head = playerCharacter:FindFirstChild("Head") or playerCharacter.PrimaryPart
            local billboard = head and head:FindFirstChild("TayJay_PlayerESP")
            if billboard then pcall(function() billboard:Destroy() end) end
        end
    end
    for _, part in ipairs(circleParts) do
        if part and part.Parent then pcall(function() part:Destroy() end) end
    end
    table.clear(circleParts)

    -- Restore graphics changes and the FPS cap before destroying the FPS UI.
    pcall(function() if V70Perf and V70Perf.Cleanup then V70Perf.Cleanup() end end)

    for _, connection in ipairs(activeConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(activeConnections)
    if _tjLogConnection then
        pcall(function() _tjLogConnection:Disconnect() end)
        _tjLogConnection = nil
    end

    if perfGui and perfGui.Parent then pcall(function() perfGui:Destroy() end) end
    if screenGui and screenGui.Parent then pcall(function() screenGui:Destroy() end) end
    if controlGui and controlGui.Parent then pcall(function() controlGui:Destroy() end) end
    if _tjBootGui and _tjBootGui.Parent then pcall(function() _tjBootGui:Destroy() end) end
    _tjBootGui, _tjBootLabel = nil, nil

    _G.TAYJAY_SET_ESP = nil
    _G.TAYJAY_MM2_UI_VISIBLE = nil
    _G.TAYJAY_UI = nil
    _G.TAYJAY_CLEAN_LOOK = nil
    _G.TAYJAY_DIAGNOSTIC = nil
    _G.TAYJAY_DN_REPAINT = nil
    _G.TAYJAY_V70_PERF = nil
    _G.TAYJAY_SHUTDOWN_IN_PROGRESS = nil
end

trackConnection(stopBtn.Activated:Connect(shutdownTayJay))
trackConnection(screenGui.DescendantAdded:Connect(function(o)
    if o:IsA("UIGradient") then o.Enabled = _G.TAYJAY_UI.effects == true end
end))
_G.TAYJAY_CLEAN_LOOK(screenGui)
refreshLock()
refreshGroupButton("TAYJAY")
refreshGroupButton("MM2")
refreshGroupButton("FPS")

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
           styleDynamicObject(uiObject)
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

if not screenGui or not screenGui.Parent then
   error("TAYJAY: main ScreenGui ไม่มี Parent จึงไม่สามารถแสดงเมนูได้")
end
if _G.TAYJAY_DIAGNOSTIC then
   _G.TAYJAY_DIAGNOSTIC("READY", "เมนูหลักและระบบเริ่มต้นทำงานแล้ว")
end
print("[TAYJAY] Death Note Shadow Hunter + WARP UI + MM2 ESP initialized.")

end) -- isolated FPS Booster scope; avoids main-chunk local limit
end, function(_tjErr)
    local _tjTrace = tostring(_tjErr)
    pcall(function() _tjTrace = debug.traceback(_tjTrace, 2) end)
    return _tjTrace
end)

if not _tjRunOK then
    pcall(function() warn("[TAYJAY STARTUP ERROR]\n" .. tostring(_tjRunError)) end)
    pcall(function()
        if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", _tjRunError) end
    end)
end