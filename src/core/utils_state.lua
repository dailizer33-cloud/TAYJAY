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
   TayJayRapidBiteBtn = true,
   TayJayWalk2Btn = true,
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


