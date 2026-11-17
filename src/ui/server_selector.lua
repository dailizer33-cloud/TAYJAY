-- =========================================================
-- 🌐 SERVER SELECTOR
-- =========================================================
local serverFrame = Instance.new("Frame", screenGui)
serverFrame.Name = "TayJayServerSelector"; serverFrame.Size = UDim2.new(0, UI_LAYOUT.PanelW, 0, UI_LAYOUT.PanelH); serverFrame.Position = UDim2.new(1, -272, 0.5, -155); serverFrame.BackgroundColor3 = Color3.fromRGB(48, 166, 76); serverFrame.Visible = false
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

