-- Resource declarations: descriptive only in Monitor Mode.
ResourceManager:Register({ id = "Speed", writes = { "WalkSpeed" }, priority = 10 })
ResourceManager:Register({ id = "Fly", writes = { "Position", "HumanoidFlags", "AnimateState" }, priority = 30 })
ResourceManager:Register({ id = "ShadowHunter", writes = { "Position", "Velocity", "Collision" }, priority = 50 })
ResourceManager:Register({ id = "MonsterWarp", writes = { "Position", "Velocity", "Collision" }, priority = 60 })
ResourceManager:Register({ id = "MM2Movement", writes = { "Position" }, priority = 50 })
ResourceManager:Register({ id = "Noclip", writes = { "Collision" }, priority = 20 })
ResourceManager:Register({ id = "ZoomLimit", writes = { "CameraSettings" }, priority = 20 })
ResourceManager:Register({ id = "NoclipCam", writes = { "CameraOcclusion" }, priority = 20 })
ResourceManager:Register({ id = "Attack", writes = {}, priority = 0 })

local resourceMonitorGui = Instance.new("Frame")
resourceMonitorGui.Name = "TayJayResourceMonitor"
resourceMonitorGui.Size = UDim2.fromOffset(204, 48)
resourceMonitorGui.AnchorPoint = Vector2.new(0.5, 0)
resourceMonitorGui.Position = UDim2.new(0.5, 0, 0, 10)
resourceMonitorGui.BackgroundColor3 = Color3.fromRGB(24, 34, 48)
resourceMonitorGui.BackgroundTransparency = 0.12
resourceMonitorGui.BorderSizePixel = 0
resourceMonitorGui.ZIndex = 100
resourceMonitorGui.Parent = screenGui
local resourceMonitorCorner = Instance.new("UICorner")
resourceMonitorCorner.CornerRadius = UDim.new(0, 9)
resourceMonitorCorner.Parent = resourceMonitorGui
local resourceMonitorStroke = Instance.new("UIStroke")
resourceMonitorStroke.Color = Color3.fromRGB(65, 210, 180)
resourceMonitorStroke.Thickness = 1.2
resourceMonitorStroke.Parent = resourceMonitorGui
local resourceMonitorText = Instance.new("TextLabel")
resourceMonitorText.BackgroundTransparency = 1
resourceMonitorText.Size = UDim2.new(1, -12, 1, -8)
resourceMonitorText.Position = UDim2.fromOffset(6, 4)
resourceMonitorText.Font = Enum.Font.GothamSemibold
resourceMonitorText.TextSize = 11
resourceMonitorText.TextColor3 = Color3.fromRGB(245, 250, 255)
resourceMonitorText.TextXAlignment = Enum.TextXAlignment.Left
resourceMonitorText.TextYAlignment = Enum.TextYAlignment.Center
resourceMonitorText.TextWrapped = true
resourceMonitorText.ZIndex = 101
resourceMonitorText.Parent = resourceMonitorGui
task.spawn(function()
    while screenGui.Parent do
        local status = ResourceManager:GetStatus()
        local latest = status.latest
        local conflictLine = latest and ("Last: " .. latest.first .. " / " .. latest.second .. " (" .. latest.resource .. ")") or "No conflicts detected"
        resourceMonitorText.Text = "RESOURCE MONITOR · " .. status.mode
            .. "\nModules " .. status.modules .. "  |  Writes " .. status.writes
            .. "  |  Conflicts " .. status.conflicts .. "\n" .. conflictLine
        task.wait(0.5)
    end
end)

