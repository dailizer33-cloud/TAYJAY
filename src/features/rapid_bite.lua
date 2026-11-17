-- =========================================================
-- RAPID BITE: standalone attack button
-- =========================================================
do
local okRB, errRB = pcall(function()
   local GuiService = game:GetService("GuiService")
   local LogService = game:GetService("LogService")
   local VirtualInputManager = nil
   pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

   local RAPID_CPS = 20
   local RAPID_METHOD = "auto"               -- "auto" | "touch" | "signal"
   local RAPID_TEXTS = { "bite" }
   local STUN_WORDS = { "stun", "daze", "dizzy", "vulnerab", "exhaust", "weaken", "มึน", "สตัน" }

   local signalBad, lastSignalFireAt = false, -10
   local rapidMode = 0
   local biteButton, lastFindAt = nil, -10
   local lastMethod, stunSeen, stunText = "-", false, ""
   local clickAccumulator, stunCheckAt, visualAt = 0, 0, 0

   trackConnection(LogService.MessageOut:Connect(function(message)
       if signalBad or os.clock() - lastSignalFireAt > 2 then return end
       local msg = string.lower(tostring(message or ""))
       if string.find(msg, "current thread cannot access", 1, true)
           or (string.find(msg, "lacking capability", 1, true) and string.find(msg, "plugin", 1, true)) then
           signalBad = true
           lastMethod = "SIGNAL BLOCKED"
           pcall(function() warn("[TAYJAY RAPID] signal method disabled after capability error") end)
       end
   end))

   local button = Instance.new("TextButton", screenGui)
   button.Name = "TayJayRapidBiteBtn"
   button.AnchorPoint = Vector2.new(0.5, 0.5)
   button.Size = UDim2.fromOffset(UI_LAYOUT.ActionSize, UI_LAYOUT.ActionSize)
   button.Position = UI_LAYOUT.RapidBiteCenter
   button.BackgroundColor3 = GREEN.off
   button.RichText = true
   button.Text = '<font size="25">⚔</font>\n<font size="13">RAPID</font>\n<font size="10">OFF</font>'
   button.TextColor3 = WHITE_TEXT
   button.Font = Enum.Font.GothamBlack
   button.TextSize = 15
   button.Active = true
   button.AutoButtonColor = true
   Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
   local stroke = Instance.new("UIStroke", button)
   stroke.Color = Color3.fromRGB(255, 96, 132)
   stroke.Thickness = 2.5
   makeDraggable(button)

   local function normalize(text)
       local str = tostring(text or "")
       str = str:gsub("<[^>]*>", "")
       str = str:gsub("[^%w\128-\255]", "")
       return string.lower(str)
   end

   local function guiShown(obj)
       local gui = obj:FindFirstAncestorWhichIsA("ScreenGui")
       if not gui or not gui.Enabled or gui == screenGui then return false end
       local parent = obj
       while parent and parent ~= gui do
           if parent:IsA("GuiObject") and not parent.Visible then return false end
           parent = parent.Parent
       end
       return true
   end

   local function findBiteButton()
       local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
       if not playerGui then return nil end
       for _, obj in ipairs(playerGui:GetDescendants()) do
           if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and #obj.Text > 0 and #obj.Text <= 24 then
               local key = normalize(obj.Text)
               for _, want in ipairs(RAPID_TEXTS) do
                   if key == want and guiShown(obj) then
                       local target = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
                       return target or obj
                   end
               end
           end
       end
       return nil
   end

   local function fireSignals(target)
       if type(getconnections) ~= "function" then return false end
       for _, signalName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "TouchTap" }) do
           local okSig, signal = pcall(function() return target[signalName] end)
           if okSig and signal then
               local okConn, connections = pcall(getconnections, signal)
               if okConn and type(connections) == "table" then
                   local fired = false
                   for _, conn in ipairs(connections) do
                       if pcall(function() conn:Fire() end) then fired = true end
                   end
                   if fired then return true end
               end
           end
       end
       return false
   end

   local function clickScreen(target)
       if not VirtualInputManager then return false end
       local position, size = target.AbsolutePosition, target.AbsoluteSize
       local x, y = position.X + size.X / 2, position.Y + size.Y / 2
       local gui = target:FindFirstAncestorWhichIsA("ScreenGui")
       if gui and not gui.IgnoreGuiInset then
           local okInset, inset = pcall(function() return GuiService:GetGuiInset() end)
           if okInset and inset then y = y + inset.Y end
       end
       return (pcall(function()
           if UserInputService.TouchEnabled then
               VirtualInputManager:SendTouchEvent(91, 0, x, y)
               VirtualInputManager:SendTouchEvent(91, 2, x, y)
           else
               VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
               VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
           end
       end))
   end

   local function biteOnce()
       local now = os.clock()
       if (not biteButton or not biteButton.Parent) and now - lastFindAt > 1.5 then
           lastFindAt = now
           biteButton = findBiteButton()
           if biteButton then
               pcall(function() print("[TAYJAY RAPID] attack button found: " .. biteButton:GetFullName()) end)
           end
       end
       if not biteButton or not biteButton.Parent then lastMethod = "NO BUTTON" return false end
       if RAPID_METHOD ~= "signal" and clickScreen(biteButton) then lastMethod = "touch" return true end
       if RAPID_METHOD ~= "touch" and not signalBad then
           lastSignalFireAt = os.clock()
           if fireSignals(biteButton) then lastMethod = "signal" return true end
       end
       lastMethod = "NO INPUT"
       return false
   end

   local function scanStun()
       local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
       if not playerGui then return false end
       for _, obj in ipairs(playerGui:GetDescendants()) do
           if obj:IsA("TextLabel") and #obj.Text > 0 and #obj.Text <= 40 and guiShown(obj) then
               local key = string.lower(obj.Text)
               for _, word in ipairs(STUN_WORDS) do
                   if string.find(key, word, 1, true) then return true, obj.Text end
               end
           end
       end
       return false
   end

   local function updateVisual()
       local line3, color = "OFF", GREEN.off
       if rapidMode == 1 then
           line3, color = "ON • " .. lastMethod, GREEN.on
       elseif rapidMode == 2 then
           if stunSeen then line3, color = "AUTO • STUN! " .. lastMethod, GREEN.on
           else line3, color = "AUTO • รอมึน", GREEN.warning end
       end
       button.BackgroundColor3 = color
       button.Text = '<font size="25">⚔</font>\n<font size="13">RAPID</font>\n<font size="9">' .. line3 .. '</font>'
   end

   trackConnection(button.Activated:Connect(function()
       rapidMode = (rapidMode + 1) % 3
       clickAccumulator, stunSeen, stunCheckAt = 0, false, 0
       if rapidMode ~= 0 then lastFindAt = -10 end
       updateVisual()
   end))

   trackConnection(RunService.Heartbeat:Connect(function(dt)
       if rapidMode == 0 then clickAccumulator = 0 return end
       local now = os.clock()
       if rapidMode == 2 and now >= stunCheckAt then
           stunCheckAt = now + 0.3
           local seen, text = scanStun()
           if seen and not stunSeen then print("[TAYJAY RAPID] stun text detected: " .. tostring(text)) end
           stunSeen, stunText = seen, text or ""
       end
       if rapidMode == 2 and not stunSeen then clickAccumulator = 0 end
       if rapidMode == 1 or stunSeen then
           clickAccumulator = clickAccumulator + dt
           local interval = 1 / RAPID_CPS
           local clicks = 0
           while clickAccumulator >= interval and clicks < 3 do
               clickAccumulator = clickAccumulator - interval
               clicks = clicks + 1
               biteOnce()
           end
           if clickAccumulator > interval * 3 then clickAccumulator = 0 end
       end
       if now >= visualAt then visualAt = now + 0.25; updateVisual() end
   end))

   updateVisual()
end)
if not okRB then
   pcall(function() warn("[TAYJAY RAPID] initialization failed: " .. tostring(errRB)) end)
   pcall(function()
       if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", "RAPID: " .. tostring(errRB)) end
   end)
end
end


