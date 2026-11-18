TJ.Main._TayJayThemeInit = function()
-- =========================================================
-- 🌌 TAYJAY MIDNIGHT NEON THEME + CAMERA QUALITY OF LIFE
-- =========================================================

-- ZoomLimit: independently maintain the camera zoom range and Classic camera mode.
TJ.Main.ZoomLimitActive = true
local function enforceZoomLimit()
   if not TJ.Main.ZoomLimitActive then return end
   pcall(function()
      ResourceManager:RecordWrite("ZoomLimit", "CameraSettings")
       if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
         LocalPlayer.CameraMode = Enum.CameraMode.Classic
      end
      if LocalPlayer.CameraMaxZoomDistance ~= 70 then
         LocalPlayer.CameraMaxZoomDistance = 70
      end
      if LocalPlayer.CameraMinZoomDistance ~= 0.5 then
         LocalPlayer.CameraMinZoomDistance = 0.5
      end
   end)
end
trackConnection(LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(enforceZoomLimit))
trackConnection(LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(enforceZoomLimit))
trackConnection(LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(enforceZoomLimit))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   task.defer(enforceZoomLimit)
end))
enforceZoomLimit()

-- NoclipCam: independently maintain Invisicam occlusion only; it does not change character collision.
TJ.Main.NoclipCamActive = true
local function enforceNoclipCam()
   if not TJ.Main.NoclipCamActive then return end
   pcall(function()
      ResourceManager:RecordWrite("NoclipCam", "CameraOcclusion")
       if LocalPlayer.DevCameraOcclusionMode ~= Enum.DevCameraOcclusionMode.Invisicam then
         LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
      end
   end)
end
trackConnection(LocalPlayer:GetPropertyChangedSignal("DevCameraOcclusionMode"):Connect(enforceNoclipCam))
trackConnection(LocalPlayer.CharacterAdded:Connect(function()
   task.defer(enforceNoclipCam)
end))
enforceNoclipCam()

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
   local ancestor=obj
   while ancestor and ancestor~=screenGui do
       if ancestor:GetAttribute("TayJayKeepCustomStyle")==true then return end
       ancestor=ancestor.Parent
   end

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
-- Expose the callback for UI modules initialized in a separate local scope.
TJ.Main.ApplyDynamicStyle = styleDynamicObject

applyGreenTheme(screenGui)
trackConnection(screenGui.DescendantAdded:Connect(function(obj)
   task.defer(function()
       if obj and obj.Parent then styleDynamicObject(obj) end
   end)
end))


end
TJ.Main._TayJayThemeInit()
TJ.Main._TayJayThemeInit = nil

-- Build trigger: keep generated MAIN synchronized with manifest sources.
