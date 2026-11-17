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
    -- No toast or full-width error banner: errors are stored behind a small top-right dot.
    if state ~= "ERROR" then return end
    local body = tostring(message or "Unknown error")
    pcall(function()
        if not _tjBootGui then
            _tjBootGui = Instance.new("ScreenGui")
            _tjBootGui.Name = "TayJay_IndependentStartupStatus"
            _tjBootGui.ResetOnSpawn = false
            _tjBootGui.IgnoreGuiInset = true
            _tjBootGui.DisplayOrder = 1000000
            _tjBootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            _tjBootLabel = Instance.new("TextButton")
            _tjBootLabel.Name = "ErrorDot"
            _tjBootLabel.Size = UDim2.fromOffset(34, 34)
            _tjBootLabel.Position = UDim2.new(1, -44, 0, 10)
            _tjBootLabel.BackgroundColor3 = Color3.fromRGB(190, 42, 48)
            _tjBootLabel.BorderSizePixel = 0
            _tjBootLabel.Text = "!"
            _tjBootLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            _tjBootLabel.TextSize = 20
            _tjBootLabel.Font = Enum.Font.GothamBold
            _tjBootLabel.AutoButtonColor = true
            _tjBootLabel.ZIndex = 10002
            _tjBootLabel.Parent = _tjBootGui
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0)
            dotCorner.Parent = _tjBootLabel
            local dotStroke = Instance.new("UIStroke")
            dotStroke.Color = Color3.fromRGB(255, 115, 115)
            dotStroke.Thickness = 2
            dotStroke.Parent = _tjBootLabel

            local panel = Instance.new("Frame")
            panel.Name = "ErrorDetails"
            panel.Size = UDim2.fromOffset(344, 237)
            panel.Position = UDim2.new(1, -358, 0, 54)
            panel.BackgroundColor3 = Color3.fromRGB(28, 31, 41)
            panel.BorderSizePixel = 0
            panel.Visible = false
            panel.ZIndex = 10001
            panel.Parent = _tjBootGui
            local panelCorner = Instance.new("UICorner")
            panelCorner.CornerRadius = UDim.new(0, 10)
            panelCorner.Parent = panel
            local panelStroke = Instance.new("UIStroke")
            panelStroke.Color = Color3.fromRGB(230, 75, 80)
            panelStroke.Thickness = 1.5
            panelStroke.Parent = panel

            local heading = Instance.new("TextLabel")
            heading.Name = "Heading"
            heading.Size = UDim2.new(1, -42, 0, 28)
            heading.Position = UDim2.fromOffset(10, 5)
            heading.BackgroundTransparency = 1
            heading.Text = "TAYJAY ERROR DETAILS"
            heading.TextColor3 = Color3.fromRGB(255, 125, 125)
            heading.TextSize = 13
            heading.Font = Enum.Font.GothamBold
            heading.TextXAlignment = Enum.TextXAlignment.Left
            heading.ZIndex = 10002
            heading.Parent = panel

            local close = Instance.new("TextButton")
            close.Name = "Close"
            close.Size = UDim2.fromOffset(26, 26)
            close.Position = UDim2.new(1, -32, 0, 5)
            close.BackgroundColor3 = Color3.fromRGB(75, 48, 54)
            close.BorderSizePixel = 0
            close.Text = "×"
            close.TextColor3 = Color3.fromRGB(255, 255, 255)
            close.TextSize = 18
            close.Font = Enum.Font.GothamBold
            close.ZIndex = 10003
            close.Parent = panel
            local closeCorner = Instance.new("UICorner")
            closeCorner.CornerRadius = UDim.new(0, 7)
            closeCorner.Parent = close
            close.Activated:Connect(function() panel.Visible = false end)

            local details = Instance.new("TextBox")
            details.Name = "Message"
            details.Size = UDim2.new(1, -20, 1, -44)
            details.Position = UDim2.fromOffset(10, 36)
            details.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
            details.BorderSizePixel = 0
            details.TextColor3 = Color3.fromRGB(245, 245, 245)
            details.TextSize = 12
            details.Font = Enum.Font.Code
            details.TextWrapped = true
            details.TextXAlignment = Enum.TextXAlignment.Left
            details.TextYAlignment = Enum.TextYAlignment.Top
            details.ClearTextOnFocus = false
            details.MultiLine = true
            details.TextEditable = false
            details.ZIndex = 10002
            details.Parent = panel
            local detailsCorner = Instance.new("UICorner")
            detailsCorner.CornerRadius = UDim.new(0, 7)
            detailsCorner.Parent = details

            _tjBootLabel.Activated:Connect(function()
                panel.Visible = not panel.Visible
            end)
            _tjBootGui:SetAttribute("ErrorPanelReady", true)
        end

        _tjAttachBootGui()
        local panel = _tjBootGui and _tjBootGui:FindFirstChild("ErrorDetails")
        local details = panel and panel:FindFirstChild("Message")
        if details then details.Text = string.sub(body, 1, 6000) end
        if _tjBootLabel then
            _tjBootLabel.Visible = true
            _tjBootLabel.BackgroundColor3 = Color3.fromRGB(190, 42, 48)
        end
    end)

    -- Retry parenting silently; never issue StarterGui notifications.
    pcall(function()
        task.spawn(function()
            for _ = 1, 12 do
                if _tjBootGui and _tjBootGui.Parent then break end
                pcall(_tjAttachBootGui)
                task.wait(0.5)
            end
        end)
    end)
end

_G.TAYJAY_DIAGNOSTIC = _tjShowDiagnostic
pcall(function() _tjShowDiagnostic("STARTING", "ไฟล์ถูกเรียกใช้งานแล้ว • กำลังเริ่มระบบ...") end)

-- Capture asynchronous Roblox/Luau errors as well as errors caught by xpcall below.
local _tjLogConnection
pcall(function()
    local logService = game:GetService("LogService")
    _tjLogConnection = logService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            local _tjMessageText = string.lower(tostring(message or ""))
            -- Ignore known Roblox/game asset-loading warnings in the TAYJAY error banner.
            -- These are client-side asset failures, not TAYJAY Lua runtime failures.
            local _tjIsCloverMatteWarning =
                string.find(_tjMessageText, "materialservice.clovermatte", 1, true) ~= nil
                and string.find(_tjMessageText, "pbr textures may not be visible in game", 1, true) ~= nil
            local _tjIsEmptySoundAssetWarning =
                string.find(_tjMessageText, "failed to load sound", 1, true) ~= nil
                and string.find(_tjMessageText, "rbxassetid://0", 1, true) ~= nil
                and string.find(_tjMessageText, "exactly one asset identifier", 1, true) ~= nil
            if not _tjIsCloverMatteWarning and not _tjIsEmptySoundAssetWarning then
                pcall(function() _tjShowDiagnostic("ERROR", message) end)
            end
        end
    end)
    task.delay(120, function()
        if _tjLogConnection then
            pcall(function() _tjLogConnection:Disconnect() end)
            _tjLogConnection = nil
        end
    end)
end)

