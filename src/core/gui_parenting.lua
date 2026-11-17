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
                   or v.Name == "TayJay_FPS_Booster_V72" then
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
           scaleObject.Scale = scaleValue
       end
   end
end

