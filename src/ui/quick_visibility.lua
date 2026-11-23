-- =========================================================
-- QUICK VISIBILITY CONTROLS + GLOBAL STOP ALL
-- =========================================================
-- FPS is initialized in its own task scope; access it only through the shared module API.
local function getFPSModule()
    return TJ and TJ.Main and TJ.Main.FPS
end
local function getFPSGui()
    local module = getFPSModule()
    return module and module.GUI
end
local quickGui = Instance.new("ScreenGui")
quickGui.Name = "TayJayQuickVisibility"
quickGui.ResetOnSpawn = false
quickGui.IgnoreGuiInset = true
quickGui.DisplayOrder = 1000002
quickGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SecureParentGui(quickGui)
local quickBar = Instance.new("Frame", quickGui)
quickBar.Name = "TayJayVisibilityBar"
quickBar.Size = UDim2.fromOffset(194, 32)
quickBar.Position = UDim2.new(0, 10, 0, 106)
quickBar.BackgroundColor3 = GREEN.deep
quickBar.BorderSizePixel = 0
Instance.new("UICorner", quickBar).CornerRadius = UDim.new(0, 8)
local quickEdge = Instance.new("UIStroke", quickBar)
quickEdge.Color = UI_LAYOUT.Accent.Main
quickEdge.Thickness = 1.5
local function getRoot(name) return screenGui:FindFirstChild(name) end
local tayjayRoots = {
    "TayJayMainMenu", "TayJayMainToggle", "TayJaySpeedWidget", "TayJayFlyControl",
    "TayJayNoclipCircle", "KillAuraCircleBtn", "KillAuraNormalBtn", "TayJayTargetPanel",
    "TayJayMonsterTargetPanel", "TayJayRapidBiteBtn",
    "TayJayServerSelector", "DeathNoteGroup"
}
local mm2Roots = {"TayJayMM2Dock", "TayJayMM2PlayerList"}
local visibility = {TAYJAY=true, MM2=true, FPS=true}
local tayjayVisibilityCache, mm2VisibilityCache = {}, {}
local quickButtons = {}
local function setRootGroup(names, visible, cache)
    cache = cache or {}
    for _, name in ipairs(names) do
        local root = getRoot(name)
        if root and root:IsA("GuiObject") then
            if visible then
                if cache[name] ~= nil then root.Visible = cache[name]; cache[name] = nil end
            else
                if cache[name] == nil then cache[name] = root.Visible end
                root.Visible = false
            end
        end
    end
end
local function refreshQuickButton(key)
    local button = quickButtons[key]
    if not button then return end
    button.Text = key .. (visibility[key] and " ON" or " OFF")
    button.BackgroundColor3 = visibility[key] and Color3.fromRGB(36,164,104) or Color3.fromRGB(174,52,54)
    local edge = button:FindFirstChildOfClass("UIStroke")
    if edge then edge.Color = visibility[key] and Color3.fromRGB(160,255,198) or Color3.fromRGB(255,145,130) end
end
local function setVisibility(key, value)
    visibility[key] = value == true
    if key == "TAYJAY" then setRootGroup(tayjayRoots,visibility[key],tayjayVisibilityCache)
    elseif key == "MM2" then setRootGroup(mm2Roots,visibility[key],mm2VisibilityCache)
    elseif key == "FPS" then
        local module = getFPSModule()
        if module and module.SetVisible then module.SetVisible(visibility[key]) end
    end
    refreshQuickButton(key)
end
for index,key in ipairs({"TAYJAY","MM2","FPS"}) do
    local button = Instance.new("TextButton",quickBar)
    button.Name = "Visibility_" .. key
    button.Size = UDim2.fromOffset(58,24)
    button.Position = UDim2.fromOffset(4+(index-1)*62,4)
    button.BackgroundColor3 = Color3.fromRGB(36,164,104)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextColor3 = WHITE_TEXT
    button.TextStrokeColor3 = TEXT_OUTLINE
    button.TextStrokeTransparency = 0.3
    button.AutoButtonColor = true
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,6)
    local edge = Instance.new("UIStroke",button)
    edge.Thickness = 1.2
    quickButtons[key] = button
    refreshQuickButton(key)
    trackConnection(button.Activated:Connect(function() setVisibility(key,not visibility[key]) end))
end
local function applySecondaryScale(guiRoot,excluded)
    for _,root in ipairs(guiRoot:GetChildren()) do
        if root:IsA("GuiObject") and not excluded[root.Name] then
            local scale=root:FindFirstChild("TayJaySecondaryScale")
            if not scale then scale=Instance.new("UIScale");scale.Name="TayJaySecondaryScale";scale.Parent=root end
            scale.Scale=0.9
        end
    end
end
applySecondaryScale(screenGui,{TayJayMainMenu=true,TayJayMainToggle=true})
if getFPSGui() then applySecondaryScale(getFPSGui(),{}) end
local function strengthenControlEdges(guiRoot)
    for _,obj in ipairs(guiRoot:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Name~="WindowLockButton" then
            local edge=obj:FindFirstChildOfClass("UIStroke")
            if not edge then edge=Instance.new("UIStroke");edge.Parent=obj end
            edge.Thickness=math.max(edge.Thickness,1.6)
            edge.Transparency=0.04
            local label=string.upper(tostring(obj.Text or ""))
            local enabled=obj:GetAttribute("TayJayEnabled")==true or label:find(" ON",1,true)~=nil
            edge.Color=enabled and Color3.fromRGB(170,255,190) or Color3.fromRGB(255,145,130)
        end
    end
end
strengthenControlEdges(screenGui)
if getFPSGui() then strengthenControlEdges(getFPSGui()) end
-- Reset the per-execution guard on every script launch. Delta keeps _G across re-executions,
-- so a flag left true by the previous run would otherwise make STOP ALL a no-op on run 2.
_G.TAYJAY_STOPPED = false
_G.TAYJAY_STOP_ALL = function()
    if _G.TAYJAY_STOPPED then return end
    _G.TAYJAY_STOPPED = true

    -- Release movement modes synchronously before their Owners cancel background loops.
    -- This guarantees return-home, collision restoration and platform cleanup are completed first.
    pcall(function()
        if type(_G.TAYJAY_MONSTER_STOP) == "function" then _G.TAYJAY_MONSTER_STOP() end
    end)
    pcall(function()
        if type(_G.TAYJAY_WARP_STOP_NOW) == "function" then _G.TAYJAY_WARP_STOP_NOW(true) end
    end)

    -- Stop every registered Owner only after movement cleanup has completed.
    pcall(function()
        if ResourceManager and ResourceManager.StopAllOwners then
            ResourceManager:StopAllOwners("STOP_ALL")
        end
    end)

    -- Hide and destroy UI first so a later feature-cleanup error cannot leave menus visible.
    pcall(function() if screenGui then screenGui.Enabled = false end end)
    pcall(function() local gui = getFPSGui(); if gui then gui.Enabled = false end end)
    pcall(function() if quickGui then quickGui.Enabled = false end end)
    local _tjGuiParents = {}
    local function _tjAddGuiParent(parent)
        if not parent then return end
        for _, known in ipairs(_tjGuiParents) do
            if known == parent then return end
        end
        _tjGuiParents[#_tjGuiParents + 1] = parent
    end
    pcall(function() if type(gethui) == "function" then _tjAddGuiParent(gethui()) end end)
    pcall(function() _tjAddGuiParent(CoreGui) end)
    pcall(function()
        local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        _tjAddGuiParent(playerGui)
    end)
    local _tjGuiNames = {
        [guiName] = true,
        ["TayJay_FPS_Booster_V72"] = true,
        ["TayJayLockGui"] = true,
        ["TayJayQuickVisibility"] = true,
        ["TayJay_IndependentStartupStatus"] = true
    }
    for _, parent in ipairs(_tjGuiParents) do
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if _tjGuiNames[child.Name] then
                    pcall(function()
                        if child:IsA("ScreenGui") then child.Enabled = false end
                        child:Destroy()
                    end)
                end
            end
        end)
    end
    pcall(function() if screenGui then screenGui:Destroy() end end)
    pcall(function() local gui = getFPSGui(); if gui then gui:Destroy() end end)
    pcall(function() if quickGui then quickGui:Destroy() end end)
    for key in pairs(states) do pcall(function() syncButtonState(key,false) end) end
    pcall(function() stopFlying(false) end)
    pcall(function() if TJ and TJ.Main and TJ.Main.SetNoclip then TJ.Main.SetNoclip(false) end end)
    pcall(function() if _G.TAYJAY_MONSTER_STOP then _G.TAYJAY_MONSTER_STOP() end end)
    states.KillAura = false
    states.NormalKillAura = false
    states.AutoWarp = false
    states.DNWarp = false
    pcall(updateKaBtnDisplay)
    _G.TAYJAY_POS_LOCK_UNTIL = nil
    _G.TAYJAY_POS_LOCK_OWNER = nil
    _G.TAYJAY_PLATFORM_OWNER = nil
    _G.TAYJAY_FOLLOW = nil
    pcall(function()
        if _tjMovementController then _tjMovementController:ForceClear("STOP_ALL") end
    end)
    pcall(function() if _G.TAYJAY_MM2_STOP then _G.TAYJAY_MM2_STOP() end end)
    -- FPS restoration is owned by ResourceManager -> FPS Owner -> Cleanup Bags.
    pcall(function()
        for _,player in ipairs(Players:GetPlayers()) do
            local character=player.Character
            if character then
                local highlight=character:FindFirstChild(TJ.Main.PlayerESP.Highlight)
                if highlight then highlight:Destroy() end
                local head=character:FindFirstChild("Head") or character.PrimaryPart
                local billboard=head and head:FindFirstChild(TJ.Main.PlayerESP.Name)
                if billboard then billboard:Destroy() end
            end
        end
    end)
    TJ.Main.NoclipCamActive = false
    TJ.Main.ZoomLimitActive = false
    pcall(function()
        LocalPlayer.CameraMode=TJ.Main.OriginalCameraSettings.CameraMode
        LocalPlayer.CameraMaxZoomDistance=TJ.Main.OriginalCameraSettings.CameraMaxZoomDistance
        LocalPlayer.CameraMinZoomDistance=TJ.Main.OriginalCameraSettings.CameraMinZoomDistance
        LocalPlayer.DevCameraOcclusionMode=TJ.Main.OriginalCameraSettings.DevCameraOcclusionMode
    end)
    pcall(function()
        local module = getFPSModule()
        if module and module.Cleanup then module.Cleanup() end
    end)
    for _,connection in ipairs(activeConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(activeConnections)
    pcall(function() if _tjLogConnection then _tjLogConnection:Disconnect(); _tjLogConnection=nil end end)
    pcall(function() if _tjBootGui then _tjBootGui:Destroy(); _tjBootGui=nil; _tjBootLabel=nil end end)
    pcall(function()
        if type(gethui)=="function" then
            local hidden=gethui()
            for _,child in ipairs(hidden:GetChildren()) do
                if child.Name==guiName or child.Name=="TayJay_FPS_Booster_V72"
                    or child.Name=="TayJayLockGui" or child.Name=="TayJayQuickVisibility" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end)
    for _,parent in ipairs({CoreGui,LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then
            for _,child in ipairs(parent:GetChildren()) do
                if child.Name==guiName or child.Name=="TayJay_FPS_Booster_V72"
                    or child.Name=="TayJayLockGui" or child.Name=="TayJayQuickVisibility"
                    or child.Name=="TayJay_IndependentStartupStatus" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
    pcall(function() if screenGui then screenGui:Destroy() end end)
    pcall(function() if perfGui then perfGui:Destroy() end end)
    pcall(function() if quickGui then quickGui:Destroy() end end)
    _G.TAYJAY_V70_PERF=nil
    _G.TAYJAY_MM2_STOP=nil
    _G.TAYJAY_MONSTER_STOP=nil
    _G.TAYJAY_MONSTER_PANEL_SET_VISIBLE=nil
    _G.TAYJAY_MONSTER_PANEL_GET_VISIBLE=nil
    _G.TAYJAY_STOP_ALL=nil
    print("[TAYJAY] STOP ALL completed: features restored, connections disconnected, UI removed.")
end


if not screenGui or not screenGui.Parent then
   error("TAYJAY: main ScreenGui ไม่มี Parent จึงไม่สามารถแสดงเมนูได้")
end
if _G.TAYJAY_DIAGNOSTIC then
   _G.TAYJAY_DIAGNOSTIC("READY", "เมนูหลักและระบบเริ่มต้นทำงานแล้ว")
end
print("[TAYJAY] Death Note Shadow Hunter + WARP UI + MM2 ESP initialized.")

