-- =========================================================
-- TAYJAY ANT EVOLUTION | RADAR V25 (TABLET PURE - NO PC INPUT)
-- Delta Android Tablet
-- ✅ V25: ลบอินพุต PC 100% / กัดปุ่ม BITE จริง / สกิลตามร่างอัตโนมัติ
--         Rebirth ปลดล็อก stage / บล็อก GUI Purchase ทุกชั้น
-- =========================================================
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local MS = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
-- =========================================================
-- CONFIG
-- =========================================================
local CFG = {
GUARD = true,
HP_LOW = 0.35,
HP_RESUME = 0.80,
THREAT_RADIUS = 90,
THREAT_WAIT_MAX = 45,
NO_REGEN_TIMEOUT = 35,
GUARD_COOLDOWN = 60,
SAFE_HEIGHT = 350,
CAUTION_HP = 0.60,
CAUTION_RADIUS = 50,
HP_TEXT_PATH = " ",
REBIRTH = true,
REBIRTH_POLL = 0.25,
REBIRTH_STEP_DELAY = 1.0,
EVOLVE = true,
EVOLVE_COOLDOWN = 2,
EVOLVE_GUI_WORD = "action",
CLAIM = true,
CLAIM_POLL = 3,
CLAIM_RETRY = 20,
WARP_SPEED = 0.85,
MONSTER_MODE = "value",
MONSTER_TIMEOUT = 8,
MONSTER_BLACKLIST = 10,
BITE_INTERVAL = 0.14,
SKILLS = true,
SKILL_RANGE = 90,
SKILL_NEED_ENEMY = false,
SKILL_Q_INTERVAL = 7,
SKILL_E_INTERVAL = 9,
SKILL_CLUSTER_RADIUS = 210,
SKILL_CLUSTER_DX = 150,
BLOCK_ROBUX = true,
PURCHASE_POLL = 1.0,
CLAIM_PAUSE_AFTER_PROMPT = 20,
TABLET_NUDGE = 2.0,
ROAM = true,
ROAM_AFTER = 1.0,
ROAM_INTERVAL = 1.6,
SAVE_FILE = "TayJay_AntFarm_V23.json",
SAVE_FLAGS = {"REBIRTH", "GUARD", "CLAIM", "EVOLVE", "SKILLS", "ROAM", "BLOCK_ROBUX"},
AUTO_COLLECT_BUFFS = true,
EXTRA_BUFF_WORDS = {},
MAP_LIMIT = 0,
VOID_LEVEL = -250,
VOID_DROP = 260,
SAFE_MAX_DROP = 220,
SAFE_TTL_OK = 25,
SAFE_TTL_BAD = 45,
SAFE_CHECKS_PER_SEC = 45,
ORB_BLACKLIST_TIME = 90,
EXP_CHECK = false,
EXP_FAIL_LIMIT = 5,
AUTO_NOCLIP = true,
STATUS_POLL = 0.25,
RECALL_COOLDOWN = 2.5,
}
local ST = {
hp = 1, everHealthy = false, hpLabel = nil, hpScanAt = -1e9,
threats = {}, guard = false, fleeFrom = nil, fleeAt = 0, pad = nil,
lastRise = 0, lastHp = 1, resumeReadyAt = nil, cooldownUntil = 0,
note = "", noteUntil = 0, touchHits = 0, touchMiss = 0,
rb = nil, rbScanAt = -1e9, rbTryAt = -1e9, rbLogAt = -1e9, rbOpenAt = -1e9, rbBlockedUntil = 0, rbLoggedFor = "",
rbBCount = 0, rbBStart = 0, rbDbgAt = -1e9, rbReadyPrev = false, rbRowLogged = false, evoAt = -1e9, evoClicks = 0,
mt = nil, mBlack = setmetatable({}, {__mode = "k"}), hot = {}, idleSince = nil, roamAt = -1e9, origin = nil,
skillQAt = -1e9, skillEAt = -1e9, dirty = false, closing = false, mCheckAt = 0,
spawnPoint = nil, inVoid = false, inWater = false,
voidBlacklist = setmetatable({}, {__mode = "k"}),
lastSafePos = nil, lastSafeTime = 0,
statusAt = 0, groundCheckAt = 0, groundOK = false,
recallAt = -1e9, recallCount = 0, recallWindow = 0,
farmPauseUntil = 0, lastTarget = nil,
buyWindows = setmetatable({}, {__mode = "k"}), buyScanAt = -1e9,
expLabel = nil, expLabelAt = -1e9, noclipUserOff = false,
biteBtn = nil, biteBtnAt = -1e9, biteFound = false, biteLogged = "",
skillList = {}, skillScanAt = -1e9, skillLogged = "",
nudgeAt = -1e9,
lastClaimBtn = nil, lastClaimAt = -1e9,
badClaim = setmetatable({}, {__mode = "k"}),
claimPauseUntil = 0, promptHits = 0,
}
pcall(function()
local g = getgenv and getgenv()
if g and g.TAYJAY_ANT_SHUTDOWN then g.TAYJAY_ANT_SHUTDOWN() end
end)
local GUI_NAME = "TayJay_BugEvolution_ContinuousRadar"
do
local old
pcall(function() old = (gethui and gethui() or CoreGui):FindFirstChild(GUI_NAME) end)
if old then old:Destroy() end
end
local function make(class, props, parent)
local o = Instance.new(class)
for k,v in pairs(props) do o[k] = v end
o.Parent = parent
return o
end
local function style(o, stroke, radius)
make("UICorner", {CornerRadius=UDim.new(0, radius or 12)}, o)
if stroke then make("UIStroke", {Color=stroke, Thickness=2}, o) end
end
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100000
pcall(function() gui.Parent = gethui and gethui() or CoreGui end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end
local conns = {}
local function bind(signal, fn)
local c = signal:Connect(fn)
conns[#conns+1] = c
return c
end
local itemWords = {"item", "drop", "orb", "void", "coin", "collect", "pickup", "egg", "gem", "chest", "fruit", "food", "loot"}
local monsterWords = {"monster", "mob", "enemy", "creature", "npc", "boss", "ant", "beetle", "caterpillar", "spider"}
local itemFolders = {"items", "drops", "orbs", "collectibles", "pickups", "loot"}
local partSuffixes = {"_legs", " legs", "_leg", "_body", "_head", "_wings", "_wing", "_arm", "_tail", "_part"}
local baseNameAliases = {["antennal"] = "ant", ["antennar"] = "ant", ["ant_antenna_l"] = "ant", ["ant_antenna_r"] = "ant"}
local function hasWord(s, words)
s = string.lower(s or "")
for _,w in ipairs(words) do if string.find(s,w,1,true) then return true end end
return false
end
local function baseName(name)
local n = string.lower(name or "")
local changed = true
while changed do
changed = false
for _,suffix in ipairs(partSuffixes) do
if #n > #suffix and n:sub(-#suffix) == suffix then
n = n:sub(1, #n-#suffix)
changed = true
end
end
end
return baseNameAliases[n] or n
end
local monsterFamilies = {
{"ant", {"ant", "ants", "antenna", "antennae", "antennal", "antennar"}},
{"beetle", {"beetle", "beetles"}},
{"caterpillar", {"caterpillar", "caterpillars"}},
{"spider", {"spider", "spiders"}},
}
local monsterFamilyLookup = {}
for _,fam in ipairs(monsterFamilies) do
for _,word in ipairs(fam[2]) do monsterFamilyLookup[word] = fam[1] end
end
local function nameTokens(name)
local s = (string.gsub(tostring(name or ""), "(%l)(%u)", "%1 %2"))
local tokens = {}
for w in string.gmatch(string.lower(s), "%a+") do tokens[#tokens+1] = w end
return tokens
end
local function stripId(name)
local n = string.lower(name or "")
local original = n
local prev
repeat
prev = n
n = string.gsub(n, "%s*%(%d+%)$", "")
n = string.gsub(n, "[%s_%-%.#]*%d+$", "")
until n == prev or n == ""
n = string.gsub(n, "[%s_%-%.#]+$", "")
if n == "" then return original end
return n
end
local function groupName(obj, cat)
if cat == "MONSTER" then
for _,token in ipairs(nameTokens(obj.Name)) do
local fam = monsterFamilyLookup[token]
if fam then return fam end
end
end
return stripId(baseName(stripId(obj.Name)))
end
local buffWords = {"buff", "shield", "powerup", "power_up", "power-up", "boost", "potion", "bubble", "bless", "aura", "magnet", "haste", "rage", "heal", "invinc", "regen"}
local function isBuffName(name)
return hasWord(name, buffWords) or hasWord(name, CFG.EXTRA_BUFF_WORDS)
end
local function insideCharacter(obj)
if obj:IsA("Model") and Players:GetPlayerFromCharacter(obj) then return true end
local p = obj.Parent
while p and p ~= Workspace do
if p:IsA("Model") and Players:GetPlayerFromCharacter(p) then return true end
p = p.Parent
end
return false
end
local RAR = {}
RAR.tiers = {
{100, {"secret", "exclusive", "divine", "celestial", "cosmic", "omega"}},
{90, {"mythic"}}, {80, {"legend"}}, {70, {"crown", "royal"}},
{60, {"epic", "diamond", "rainbow", "prism"}}, {50, {"gold"}},
{40, {"rare", "gem", "crystal"}}, {35, {"egg", "chest"}},
{30, {"super", "mega", "giant", "large", "big"}}, {20, {"uncommon"}},
{10, {"orb", "coin", "fruit", "food"}},
}
RAR.overrides = {}
RAR.TOP = 70
RAR.cache = setmetatable({}, {__mode="k"})
local function rarityOf(text)
local lname = string.lower(tostring(text or ""))
local best = 0
for _,tier in ipairs(RAR.tiers) do
if tier[1] > best and hasWord(lname, tier[2]) then best = tier[1] end
end
return best
end
local function itemScore(obj, g)
local now = os.clock()
local c = RAR.cache[obj]
if c and now - c.t < 5 then return c.v end
local base = RAR.overrides[g.name]
if not base then
base = rarityOf(obj.Name)
local okAttr, attr = pcall(function() return obj:GetAttribute("Rarity") end)
if okAttr and type(attr) == "string" then base = math.max(base, rarityOf(attr)) end
end
local size = 0
pcall(function()
if obj:IsA("Model") then size = obj:GetExtentsSize().Magnitude else size = obj.Size.Magnitude end
end)
local v = base + math.min(30, size * 2)
RAR.cache[obj] = {t = now, v = v}
return v
end
local function itemRankBucket(obj, g)
local sc = itemScore(obj, g)
local rank = g.buff and 1 or ((sc >= RAR.TOP) and 2 or 3)
return rank, math.floor(sc / 5)
end
local function groupPriority(g)
local o = g.objects[1]
if not (o and o.Parent) then return g.buff and 1 or 3, 0 end
local sc = itemScore(o, g)
return (g.buff and 1 or ((sc >= RAR.TOP) and 2 or 3)), sc
end
local MON = {}
MON.tiers = {
{100, {"boss", "mantis", "queen", "king", "emperor"}},
{80, {"elite", "giant", "mega", "hornet", "scorpion", "tarantula"}},
{60, {"wasp", "spider", "beetle", "centipede"}},
{40, {"soldier", "warrior"}},
}
MON.overrides = {}
MON.TOP, MON.BIG = 90, 55
MON.cache = setmetatable({}, {__mode = "k"})
local function monsterScore(obj, g)
local now = os.clock()
local c = MON.cache[obj]
if c and now - c.t < 5 then return c.v end
local base = MON.overrides[g.name]
if not base then
base = 0
local lname = string.lower(obj.Name or "")
for _,tier in ipairs(MON.tiers) do
if tier[1] > base and hasWord(lname, tier[2]) then base = tier[1] end
end
end
local size = 0
pcall(function()
if obj:IsA("Model") then size = obj:GetExtentsSize().Magnitude else size = obj.Size.Magnitude end
end)
local hp = 0
pcall(function()
local hum = obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
if hum and hum.MaxHealth > 1 then hp = math.min(20, math.log(hum.MaxHealth, 10) * 4) end
end)
local v = base + math.min(30, size * 1.5) + hp
MON.cache[obj] = {t = now, v = v}
return v
end
local function monsterRank(sc)
return (sc >= MON.TOP) and 1 or ((sc >= MON.BIG) and 2 or 3)
end
local function monsterRankBucket(obj, g)
local sc = monsterScore(obj, g)
return monsterRank(sc), math.floor(sc / 10)
end
local function monsterGroupPriority(g)
local o = g.objects[1]
if not (o and o.Parent) then return 3, 0 end
local sc = monsterScore(o, g)
return monsterRank(sc), sc
end
local function isMonster(obj)
if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
if insideCharacter(obj) then return false end
if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return true end
return hasWord(baseName(obj.Name), monsterWords)
end
local function isItem(obj)
if obj == Workspace.Terrain or isMonster(obj) or insideCharacter(obj) then return false end
if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
if hasWord(obj.Name,itemWords) or isBuffName(obj.Name) then return true end
local p=obj.Parent
while p and p~=Workspace do
if hasWord(p.Name,itemFolders) then return true end
p=p.Parent
end
return false
end
local function category(obj)
if isMonster(obj) then return "MONSTER" end
if isItem(obj) then return "ITEM" end
end
local function getPosition(obj)
if not obj or not obj.Parent then return nil end
if obj:IsA("BasePart") then return obj.Position end
if obj:IsA("Model") then
local ok,cf=pcall(function() return obj:GetPivot() end)
if ok then return cf.Position end
end
local part=obj:FindFirstChildWhichIsA("BasePart",true)
return part and part.Position or nil
end
local function getRoot()
local c=player.Character
return c and c:FindFirstChild("HumanoidRootPart")
end
local groups={ITEM={},MONSTER={}}
local objectGroup={}
local enabled={}
local known={ITEM={},MONSTER={}}
local function noteKnown(cat,key,g)
local k=known[cat][key]
if not k then
known[cat][key]={key=key,name=g.name,buff=g.buff,rank=g.buff and 1 or 3,pscore=0}
ST.dirty=true
elseif g.buff and not k.buff then
k.buff=true; k.rank=1; ST.dirty=true
end
end
local function addHotspot(pos,kind)
if not pos then return end
local hs=ST.hot
for _,h in ipairs(hs) do
if (h.pos-pos).Magnitude<25 then h.t=os.clock(); return end
end
hs[#hs+1]={pos=pos,kind=kind,t=os.clock(),visits=0,last=-1e9}
if #hs>60 then table.remove(hs,1) end
end
local selected="ITEM"
local collapsed=false
local FONT = Enum.Font.GothamBold
pcall(function() FONT = Enum.Font.FredokaOne or Enum.Font.GothamBold end)
local TH = {
bg = Color3.fromRGB(255,248,229), stroke = Color3.fromRGB(255,190,60),
head = Color3.fromRGB(70,185,255), headDark = Color3.fromRGB(40,140,230),
text = Color3.fromRGB(70,55,110), sub = Color3.fromRGB(125,110,160),
on = Color3.fromRGB(70,205,110), off = Color3.fromRGB(255,140,160),
btnBlue = Color3.fromRGB(90,160,255), green = Color3.fromRGB(70,205,110), danger = Color3.fromRGB(255,95,105),
tabItem = Color3.fromRGB(255,170,40), tabMonster = Color3.fromRGB(170,110,255), tabSet = Color3.fromRGB(70,185,255),
tabOff = Color3.fromRGB(238,228,205), row = Color3.fromRGB(255,255,255), rowDim = Color3.fromRGB(246,240,228),
buff = Color3.fromRGB(255,222,90), rare = Color3.fromRGB(255,190,215), plain = Color3.fromRGB(205,220,255),
}
local FW, FH = 400, 540
do
local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
FW = math.min(400, (tonumber(viewport and viewport.X) or 1000) - 24)
FH = math.min(540, (tonumber(viewport and viewport.Y) or 700) - 24)
end
local function mkBtn(parent, text, color, size, pos, textSize)
local b = make("TextButton", {Size=size, Position=pos or UDim2.new(0,0,0,0), BackgroundColor3=color, Text=text,
TextColor3=Color3.new(1,1,1), TextSize=textSize or 15, Font=FONT, BorderSizePixel=0}, parent)
style(b, nil, 12)
return b
end
local frame=make("Frame",{Size=UDim2.fromOffset(FW,FH),Position=UDim2.new(1,-(FW+12),0,12),BackgroundColor3=TH.bg,BorderSizePixel=0},gui)
style(frame,TH.stroke,18)
local head=make("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=TH.head,BorderSizePixel=0},frame)
style(head,nil,18)
local title=make("TextLabel",{Size=UDim2.new(1,-214,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Text="🐜 ANT FARM V25",TextColor3=Color3.new(1,1,1),TextSize=19,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left,Active=true},head)
local fold=mkBtn(head,"−",TH.headDark,UDim2.fromOffset(38,34),UDim2.new(1,-204,0,7),22)
local refresh=mkBtn(head,"สแกน",TH.green,UDim2.fromOffset(54,34),UDim2.new(1,-160,0,7),14)
local closeBtn=mkBtn(head,"ปิดสคริป",TH.danger,UDim2.fromOffset(92,34),UDim2.new(1,-102,0,7),14)
local status=make("TextLabel",{Size=UDim2.new(1,-20,0,22),Position=UDim2.fromOffset(10,54),BackgroundTransparency=1,Text="เริ่มสแกน...",TextColor3=TH.sub,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},frame)
local quick=make("Frame",{Size=UDim2.new(1,-20,0,42),Position=UDim2.fromOffset(10,80),BackgroundTransparency=1},frame)
local combat=mkBtn(quick,"MONSTER WARP: OFF",TH.off,UDim2.new(.5,-4,1,0),UDim2.new(0,0,0,0),14)
local abilityToggle=mkBtn(quick,"BITE AUTO: OFF",TH.off,UDim2.new(.5,-4,1,0),UDim2.new(.5,4,0,0),14)
local tabs=make("Frame",{Size=UDim2.new(1,-20,0,42),Position=UDim2.fromOffset(10,128),BackgroundTransparency=1},frame)
local itemTab=mkBtn(tabs,"ITEM",TH.tabItem,UDim2.new(1/3,-4,1,0),UDim2.new(0,0,0,0),15)
local monsterTab=mkBtn(tabs,"MONSTER",TH.tabOff,UDim2.new(1/3,-4,1,0),UDim2.new(1/3,2,0,0),15)
local settingsTab=mkBtn(tabs,"SETTINGS",TH.tabOff,UDim2.new(1/3,-4,1,0),UDim2.new(2/3,4,0,0),15)
local content=make("Frame",{Size=UDim2.new(1,-20,1,-184),Position=UDim2.fromOffset(10,176),BackgroundTransparency=1},frame)
local listPanel=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},content)
local searchBox=make("TextBox",{Size=UDim2.new(1,-100,0,36),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Text="",PlaceholderText="🔍 ค้นหาชื่อ...",PlaceholderColor3=TH.sub,TextColor3=TH.text,TextSize=15,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},listPanel)
style(searchBox,TH.stroke,12)
local allBtn=mkBtn(listPanel,"ALL ON",TH.btnBlue,UDim2.fromOffset(92,36),UDim2.new(1,-92,0,0),14)
local list=make("ScrollingFrame",{Size=UDim2.new(1,0,1,-44),Position=UDim2.fromOffset(0,44),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.35,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},listPanel)
style(list,nil,12)
local layout=make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},list)
local settingsPanel=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0),Visible=false},content)
local SET = {}
local SL = {}
local sGrid
do
local sList=make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},settingsPanel)
sList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() settingsPanel.CanvasSize=UDim2.new(0,0,0,sList.AbsoluteContentSize.Y+10) end)
local sliderBox=make("Frame",{Size=UDim2.new(1,-8,0,170),BackgroundTransparency=1,LayoutOrder=1},settingsPanel)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sliderBox)
local function mkSlider(order, title, minV, maxV, step, fmt)
local S = {min=minV, max=maxV, step=step, value=minV}
local box=make("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=TH.row,BorderSizePixel=0,LayoutOrder=order},sliderBox)
style(box,TH.plain,12)
local label=make("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.fromOffset(10,3),BackgroundTransparency=1,Text=title,TextColor3=TH.text,TextSize=15,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left},box)
local minus=mkBtn(box,"−",TH.btnBlue,UDim2.fromOffset(34,32),UDim2.new(0,8,0,28),22)
local plus=mkBtn(box,"+",TH.btnBlue,UDim2.fromOffset(34,32),UDim2.new(1,-42,0,28),22)
local track=make("Frame",{Size=UDim2.new(1,-100,0,12),Position=UDim2.new(0,50,0,38),BackgroundColor3=TH.tabOff,BorderSizePixel=0},box)
style(track,nil,6)
local fill=make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=TH.on,BorderSizePixel=0},track)
style(fill,nil,6)
local knob=make("Frame",{Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},track)
style(knob,TH.stroke,13)
local hit=make("TextButton",{Size=UDim2.new(1,-100,0,36),Position=UDim2.new(0,50,0,26),BackgroundTransparency=1,Text="",AutoButtonColor=false},box)
function S.set(v, silent)
v = math.max(minV, math.min(maxV, v))
if not silent then
v = math.floor(v / step + 0.5) * step
v = math.max(minV, math.min(maxV, v))
end
S.value = v
local f = (v - minV) / (maxV - minV)
fill.Size = UDim2.new(f,0,1,0)
knob.Position = UDim2.new(f,0,.5,0)
label.Text = title .. "   " .. fmt(v)
if not silent and S.onChange then S.onChange(v) end
end
function S.setFraction(f)
S.set(minV + math.max(0, math.min(1, f)) * (maxV - minV))
end
local dragging = false
local function fromInput(input)
local w = hit.AbsoluteSize.X
if not w or w <= 0 then return end
S.setFraction((input.Position.X - hit.AbsolutePosition.X) / w)
end
hit.InputBegan:Connect(function(input)
if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
dragging = true
settingsPanel.ScrollingEnabled = false
fromInput(input)
input.Changed:Connect(function()
if input.UserInputState==Enum.UserInputState.End then
dragging = false
settingsPanel.ScrollingEnabled = true
end
end)
end
end)
bind(UIS.InputChanged, function(input)
if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
fromInput(input)
end
end)
minus.MouseButton1Click:Connect(function() S.set(S.value - step) end)
plus.MouseButton1Click:Connect(function() S.set(S.value + step) end)
S.set(minV, true)
return S
end
SL.bite = mkSlider(1, "⚔ ความไวการกัด", 2, 15, 0.5, function(v) return string.format("%.1f ครั้ง/วิ", v) end)
SL.warp = mkSlider(2, "🌀 ความไววาร์ป", 0.3, 1.5, 0.05, function(v) return string.format("x%.2f", v) end)
make("TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="⚠ ตั้งเร็วมากเสี่ยงโดนเกมเตะ ถ้าหลุดบ่อยให้ลดลง",TextColor3=TH.sub,TextSize=12,Font=Enum.Font.GothamBold,TextWrapped=true,LayoutOrder=3},sliderBox)
local gridFrame=make("Frame",{Size=UDim2.new(1,-8,0,300),BackgroundTransparency=1,LayoutOrder=2},settingsPanel)
sGrid=make("UIGridLayout",{CellSize=UDim2.new(.5,-4,0,50),CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder},gridFrame)
SET.grid=gridFrame
end
local function mkSetting(order, text, color)
local b=mkBtn(SET.grid,text,color,UDim2.new(.5,-4,0,50),nil,14)
b.LayoutOrder=order
return b
end
local noclipToggle=mkSetting(1,"NOCLIP: OFF",TH.off)
SET.robux=mkSetting(2,"BLOCK ROBUX: ON",TH.on)
SET.rebirth=mkSetting(3,"REBIRTH: ON",TH.on)
SET.guard=mkSetting(4,"GUARD: ON",TH.on)
SET.claim=mkSetting(5,"CLAIM: ON",TH.on)
SET.evolve=mkSetting(6,"HATCH: ON",TH.on)
SET.skill=mkSetting(7,"SKILL AUTO: ON",TH.on)
SET.roam=mkSetting(8,"ROAM: ON",TH.on)
SET.mode=mkSetting(9,"ตีมอน: ค่าสูงก่อน",TH.btnBlue)
local noclipOn = false
local noclipCharacter = nil
local collisionSnapshot = {}
local lastSafeCFrame = nil
local antiFallBusy = false
local noclipDescendantConnection = nil
local noclipIgnoredParts = {HumanoidRootPart=true, LeftFoot=true, RightFoot=true, LeftLeg=true, RightLeg=true, LeftLowerLeg=true, RightLowerLeg=true}
local antiFallParams = RaycastParams.new()
antiFallParams.FilterType = Enum.RaycastFilterType.Exclude
local function rememberAndDisableCollision(part)
if not part or not part:IsA("BasePart") or noclipIgnoredParts[part.Name] then return end
if collisionSnapshot[part] == nil then collisionSnapshot[part] = part.CanCollide end
if part.CanCollide then part.CanCollide = false end
end
local function disconnectNoclipCharacter()
if noclipDescendantConnection then
noclipDescendantConnection:Disconnect()
noclipDescendantConnection = nil
end
end
local function restoreCharacterCollision()
disconnectNoclipCharacter()
for part, originalValue in pairs(collisionSnapshot) do
if part and part.Parent then pcall(function() part.CanCollide = originalValue end) end
end
table.clear(collisionSnapshot)
end
local function applyNoclipToCharacter()
local character = player.Character
if not character then return end
if noclipCharacter ~= character then
restoreCharacterCollision()
noclipCharacter = character
collisionSnapshot = {}
for _,obj in ipairs(character:GetDescendants()) do rememberAndDisableCollision(obj) end
noclipDescendantConnection = character.DescendantAdded:Connect(function(obj)
if noclipOn then rememberAndDisableCollision(obj) end
end)
end
end
local function setNoclip(value)
noclipOn = value
if value then
local root = getRoot()
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if root and humanoid then
antiFallParams.FilterDescendantsInstances = {player.Character}
local floor = Workspace:Raycast(root.Position, Vector3.new(0,-18,0), antiFallParams)
if humanoid.FloorMaterial ~= Enum.Material.Air and floor then
lastSafeCFrame = root.CFrame
elseif floor and (root.Position-floor.Position).Magnitude <= 9 then
lastSafeCFrame = CFrame.new(root.Position, root.Position + root.CFrame.LookVector)
end
end
applyNoclipToCharacter()
noclipToggle.Text = "NOCLIP: ON"
noclipToggle.BackgroundColor3 = TH.on
else
restoreCharacterCollision()
noclipCharacter = nil
antiFallBusy = false
noclipToggle.Text = "NOCLIP: OFF"
noclipToggle.BackgroundColor3 = TH.off
end
end
noclipToggle.MouseButton1Click:Connect(function()
setNoclip(not noclipOn)
ST.noclipUserOff = not noclipOn
end)
bind(player.CharacterAdded, function(character)
task.wait(0.5)
lastSafeCFrame = nil
if noclipOn and gui.Parent then applyNoclipToCharacter() end
end)
task.spawn(function()
while gui.Parent do
if noclipOn then
local character = player.Character
local root = getRoot()
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if character and root and humanoid and humanoid.Health > 0 then
if noclipCharacter ~= character then applyNoclipToCharacter() end
antiFallParams.FilterDescendantsInstances = {character}
local floorNear = Workspace:Raycast(root.Position, Vector3.new(0,-9,0), antiFallParams)
if humanoid.FloorMaterial ~= Enum.Material.Air and floorNear then
lastSafeCFrame = root.CFrame
elseif lastSafeCFrame and not antiFallBusy then
local velocity = root.AssemblyLinearVelocity
local tooLow = root.Position.Y < lastSafeCFrame.Position.Y - 32
local fallingWithoutFloor = velocity.Y < -48 and not floorNear
if tooLow or fallingWithoutFloor then
antiFallBusy = true
local safeCFrame = lastSafeCFrame
setNoclip(false)
local currentRoot = getRoot()
if currentRoot and safeCFrame then
currentRoot.AssemblyLinearVelocity = Vector3.zero
currentRoot.AssemblyAngularVelocity = Vector3.zero
currentRoot.CFrame = safeCFrame + Vector3.new(0,4,0)
end
task.wait(0.6)
antiFallBusy = false
end
end
end
end
task.wait(0.25)
end
end)
make("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},list)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10) end)
sGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SET.grid.Size=UDim2.new(1,-8,0,sGrid.AbsoluteContentSize.Y) end)
local function clearRows()
for _,c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
end
local K = {}
K.ITEM_DWELL = 0
K.MONSTER_DWELL = 0.1
K.IDLE_DELAY = 0.08
K.TOUCH_TRIES = 2
K.TOUCH_COOLDOWN = 0.12
K.WARP_TRIES = 4
K.WARP_COOLDOWN = 0.15 / CFG.WARP_SPEED
K.ITEM_SKIP_SECONDS = 2
K.ITEM_STREAK_LIMIT = 120
local itemVisits = setmetatable({}, {__mode="k"})
ST.currentAction = "IDLE"
ST.lastGroupCount = 0
local render
ST.scanRunning = false
ST.renderQueued = false
local function scheduleRender()
if ST.renderQueued then return end
ST.renderQueued = true
task.delay(1.0, function()
ST.renderQueued = false
if gui.Parent and render then render() end
end)
end
local function keyFor(obj,cat)
return cat.."|"..groupName(obj,cat)
end
local function addObject(obj)
if not obj or not obj.Parent or objectGroup[obj] then return false end
local cat=category(obj)
if not cat then return false end
local p=obj.Parent
while p and p~=Workspace do
if p:IsA("Model") and p~=obj then
local parentKey = objectGroup[p]
if parentKey and string.sub(parentKey,1,#cat+1)==cat.."|" then return false end
if category(p)==cat then return false end
end
p=p.Parent
end
local key=keyFor(obj,cat)
local g=groups[cat][key]
if not g then
g={key=key,name=groupName(obj,cat),objects={}}
if cat=="ITEM" and isBuffName(obj.Name) then
g.buff=true
if CFG.AUTO_COLLECT_BUFFS and enabled[key]==nil then enabled[key]=true end
end
groups[cat][key]=g
noteKnown(cat,key,g)
end
table.insert(g.objects,obj)
objectGroup[obj]=key
return true
end
local function removeObject(obj)
local key=objectGroup[obj]
if not key then return end
objectGroup[obj]=nil
local hp=getPosition(obj)
if hp then addHotspot(hp, string.sub(key,1,8)=="MONSTER|" and "MONSTER" or "ITEM") end
if ST.mt and ST.mt.obj==obj then ST.mt=nil end
if ST.lastTarget==obj then ST.lastTarget=nil end
local vv=itemVisits[obj]
if vv and vv.touches>0 and vv.warps==0 then ST.touchHits=ST.touchHits+1 end
itemVisits[obj]=nil
for _,cat in ipairs({"ITEM","MONSTER"}) do
local g=groups[cat][key]
if g then
for i=#g.objects,1,-1 do
if g.objects[i]==obj then table.remove(g.objects,i) end
end
if #g.objects==0 then groups[cat][key]=nil end
end
end
scheduleRender()
end
local pendingAdds = {}
local pendingAddHead, pendingAddTail = 1, 0
local pendingAddSet = setmetatable({}, {__mode="k"})
local function queueObject(obj)
if not obj or pendingAddSet[obj] then return end
pendingAddSet[obj]=true
pendingAddTail=pendingAddTail+1
pendingAdds[pendingAddTail]=obj
end
task.spawn(function()
while gui.Parent do
local processed, changed = 0, false
while not ST.scanRunning and pendingAddHead<=pendingAddTail and processed<80 do
local obj=pendingAdds[pendingAddHead]
pendingAdds[pendingAddHead]=nil
pendingAddHead=pendingAddHead+1
if obj then
pendingAddSet[obj]=nil
if addObject(obj) then changed=true end
end
processed=processed+1
end
if pendingAddHead>pendingAddTail then
pendingAdds={}
pendingAddHead,pendingAddTail=1,0
end
if changed then scheduleRender() end
task.wait(0.08)
end
end)
local function fullScan()
if ST.scanRunning or not gui.Parent then return end
ST.scanRunning=true
local oldText=refresh.Text
refresh.Text="สแกน..."
groups.ITEM={}
groups.MONSTER={}
objectGroup={}
local ok,err=pcall(function()
local stack={Workspace}
local processed=0
while #stack>0 and gui.Parent do
local parent=stack[#stack]
stack[#stack]=nil
local children=parent:GetChildren()
for _,obj in ipairs(children) do
if obj and obj.Parent then
pcall(addObject,obj)
stack[#stack+1]=obj
end
processed=processed+1
if processed%220==0 then task.wait(0.035) end
end
end
end)
ST.scanRunning=false
refresh.Text=oldText
if render then render() end
if not ok then warn("[TAYJAY V25] Scan warning: "..tostring(err)) end
end
local ROW_HEAD = {
ITEM = {[1]="⭐ บัฟ — เก็บก่อนเสมอ", [2]="💎 หายาก/ใหญ่ — เก็บเป็นอันดับถัดไป", [3]="📦 ไอเท็มทั่วไป — เรียงจากมีค่าไปน้อย"},
MONSTER = {[1]="👑 บอส/อีเวนต์ — ตีก่อน", [2]="💪 ตัวใหญ่/แข็ง", [3]="🐜 ตัวทั่วไป"},
}
local function applyLayout()
for _,o in ipairs({status,quick,tabs,content}) do o.Visible = not collapsed end
listPanel.Visible = (selected ~= "SET")
settingsPanel.Visible = (selected == "SET")
frame.Size = collapsed and UDim2.fromOffset(FW,56) or UDim2.fromOffset(FW,FH)
fold.Text = collapsed and "+" or "−"
end
local function setTab(cat)
selected = cat
itemTab.BackgroundColor3 = (cat=="ITEM") and TH.tabItem or TH.tabOff
monsterTab.BackgroundColor3 = (cat=="MONSTER") and TH.tabMonster or TH.tabOff
settingsTab.BackgroundColor3 = (cat=="SET") and TH.tabSet or TH.tabOff
itemTab.TextColor3 = (cat=="ITEM") and Color3.new(1,1,1) or TH.text
monsterTab.TextColor3 = (cat=="MONSTER") and Color3.new(1,1,1) or TH.text
settingsTab.TextColor3 = (cat=="SET") and Color3.new(1,1,1) or TH.text
applyLayout()
if cat ~= "SET" and render then render() end
end
local function toggleGroup(key,button)
enabled[key]=not enabled[key]
button.Text=enabled[key] and "ON" or "OFF"
button.BackgroundColor3=enabled[key] and TH.on or TH.off
ST.dirty=true
end
local function prettyName(n) return (string.gsub(n, "^%l", string.upper)) end
local function addHeader(text, order)
make("TextLabel",{Size=UDim2.new(1,-6,0,30),BackgroundTransparency=1,Text=text,TextColor3=TH.text,TextSize=15,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order},list)
end
local function addRow(e, order)
local live = e.count > 0
local row = make("Frame",{Size=UDim2.new(1,-6,0,54),BackgroundColor3=live and TH.row or TH.rowDim,BorderSizePixel=0,LayoutOrder=order},list)
local accent = (e.rank==1) and TH.buff or ((e.rank==2) and TH.rare or TH.plain)
style(row, accent, 12)
local badge = " "
if selected == "ITEM" then
badge = e.buff and "⭐ " or ((e.rank==2) and "💎 " or " ")
else
badge = (e.rank==1) and "👑 " or ((e.rank==2) and "💪 " or " ")
end
make("TextLabel",{Size=UDim2.new(1,-96,0,26),Position=UDim2.fromOffset(12,5),BackgroundTransparency=1,Text=badge..prettyName(e.name),TextColor3=live and TH.text or TH.sub,TextSize=17,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
make("TextLabel",{Size=UDim2.new(1,-96,0,18),Position=UDim2.fromOffset(12,31),BackgroundTransparency=1,Text=live and ("ในแมพตอนนี้ × "..e.count) or "ไม่เจอตอนนี้ (จำไว้ให้แล้ว)",TextColor3=TH.sub,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},row)
local b = mkBtn(row, enabled[e.key] and "ON" or "OFF", enabled[e.key] and TH.on or TH.off, UDim2.fromOffset(74,38), UDim2.new(1,-82,.5,-19), 16)
b.MouseButton1Click:Connect(function() toggleGroup(e.key, b) end)
end
render=function()
if selected == "SET" then return end
local keepPos = list.CanvasPosition
clearRows()
local q = string.lower(searchBox.Text or "")
local arr = {}
for key,k in pairs(known[selected]) do
local g = groups[selected][key]
local live = 0
if g then
local objs = {}
for _,o in ipairs(g.objects) do if o and o.Parent then objs[#objs+1] = o end end
g.objects = objs
live = #objs
end
if q == "" or string.find(string.lower(k.name), q, 1, true) then
local rank, score = k.rank or 3, k.pscore or 0
if g and live > 0 then
if selected == "ITEM" then rank, score = groupPriority(g) else rank, score = monsterGroupPriority(g) end
if k.rank ~= rank then k.rank = rank; ST.dirty = true end
k.pscore = score
end
arr[#arr+1] = {key=key, name=k.name, buff=k.buff, count=live, rank=rank, score=score}
end
end
table.sort(arr, function(a, b)
if a.rank ~= b.rank then return a.rank < b.rank end
if a.score ~= b.score then return a.score > b.score end
if a.name ~= b.name then return a.name < b.name end
return a.key < b.key
end)
local order, lastRank = 0, nil
ST.visibleKeys = {}
for _,e in ipairs(arr) do
if e.rank ~= lastRank then
lastRank = e.rank
order = order + 1
addHeader(ROW_HEAD[selected][e.rank] or "", order)
end
order = order + 1
addRow(e, order)
ST.visibleKeys[#ST.visibleKeys+1] = e.key
end
ST.lastGroupCount = #arr
local allOn = #arr > 0
for _,e in ipairs(arr) do if not enabled[e.key] then allOn = false break end end
allBtn.Text = allOn and "ALL OFF" or "ALL ON"
if #arr == 0 then
make("TextLabel",{Size=UDim2.new(1,-8,0,60),BackgroundTransparency=1,Text="ยังไม่พบรายการ\nกด 'สแกน' หรือเดินไปที่มีของ/มอนสเตอร์",TextColor3=TH.sub,TextSize=14,Font=Enum.Font.GothamBold,LayoutOrder=1},list)
end
task.defer(function() if list.Parent then list.CanvasPosition = keepPos end end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() if render then render() end end)
allBtn.MouseButton1Click:Connect(function()
local keys = ST.visibleKeys or {}
local allOn = #keys > 0
for _,k in ipairs(keys) do if not enabled[k] then allOn = false break end end
for _,k in ipairs(keys) do enabled[k] = not allOn end
ST.dirty = true
render()
end)
local function buttonText(button)
local texts = {}
if button:IsA("TextButton") then table.insert(texts, button.Text or "") end
for _,child in ipairs(button:GetDescendants()) do
if child:IsA("TextLabel") or child:IsA("TextButton") then
table.insert(texts, child.Text or "")
end
end
return string.upper(table.concat(texts, " "))
end
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local GuiService = game:GetService("GuiService")
-- =========================================================
-- ✅ V25: TOUCH ONLY — ไม่มี SendKeyEvent / SendMouseButtonEvent
--          / SendMouseMoveEvent เหลืออยู่ในไฟล์นี้เลย
-- =========================================================
local TAP = {id = 7100}
function TAP.visible(o)
while o do
if o:IsA("GuiObject") and not o.Visible then return false end
if o:IsA("LayerCollector") and not o.Enabled then return false end
o = o.Parent
end
return true
end
-- ✅ อยู่ใน GUI ซื้อ/Robux ห้ามแตะเด็ดขาด (AntPurchaseFocusPark ฯลฯ)
function TAP.purchase(o)
local p = o
while p do
if ST.buyWindows[p] then return true end
if p:IsA("GuiObject") or p:IsA("LayerCollector") then
local nm = (string.gsub(string.lower(p.Name), "[^%a]", ""))
if string.find(nm, "purchase", 1, true)
or string.find(nm, "buyitem", 1, true)
or string.find(nm, "robux", 1, true)
or string.find(nm, "premium", 1, true)
or string.find(nm, "robloxplus", 1, true)
or string.find(nm, "freetrial", 1, true)
or nm == "shop" or nm == "store" then
return true
end
end
p = p.Parent
end
return false
end
function TAP.signals(btn, names)
local haveGC = (typeof(getconnections) == "function")
local haveFS = (typeof(firesignal) == "function")
if not (haveGC or haveFS) then return false end
local any = false
for _,name in ipairs(names) do
local okSig, sig = pcall(function() return btn[name] end)
if okSig and sig then
if haveGC then
local ok, cs = pcall(getconnections, sig)
if ok and type(cs) == "table" and #cs > 0 then
for _,c in ipairs(cs) do
if pcall(function() c:Fire() end) then any = true end
end
end
end
if not any and haveFS then
if pcall(firesignal, sig) then any = true end
end
end
end
return any
end
-- แตะพิกัดบนจอ (ทัชจริงเท่านั้น = ดันเกมกลับโหมด tablet)
function TAP.point(x, y, hold)
if not VIM then return false end
TAP.id = TAP.id + 1
if TAP.id > 7990 then TAP.id = 7100 end
local id = TAP.id
local ok = pcall(function() VIM:SendTouchEvent(id, 0, x, y) end)
task.wait(hold or 0.04)
pcall(function() VIM:SendTouchEvent(id, 2, x, y) end)
return ok
end
function TAP.touch(btn)
if not VIM then return false end
local okSize, sz = pcall(function() return btn.AbsoluteSize end)
if not okSize or not sz or sz.X <= 0 or sz.Y <= 0 then return false end
local sg = btn:FindFirstAncestorOfClass("ScreenGui")
local inset = (sg and sg.IgnoreGuiInset) and Vector2.new(0,0) or GuiService:GetGuiInset()
local c = btn.AbsolutePosition + sz / 2 + inset
return TAP.point(c.X, c.Y, 0.04)
end
-- ✅ กัด/สกิล: ทัชจริงก่อนเสมอ (บังคับ layout มือถือ) แล้วยิงสัญญาณซ้ำ
function TAP.hard(btn)
if not (btn and btn.Parent) then return false end
if TAP.purchase(btn) then return false end
local touched = TAP.touch(btn)
TAP.signals(btn, {"Activated", "MouseButton1Click"})
if not touched then pcall(function() btn:Activate() end) end
return true
end
-- ✅ หาปุ่ม BITE แบบเจาะจง (ตัดคำว่า HIT ทิ้ง ไม่ไปโดน EvoBar.Hit)
function TAP.findBite()
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then return nil end
local best, bestScore = nil, 0
for _,o in ipairs(pg:GetDescendants()) do
if o:IsA("GuiButton") and not o:IsDescendantOf(gui) and TAP.visible(o) and not TAP.purchase(o) then
local nm = string.upper(o.Name)
local own = ""
if o:IsA("TextButton") then own = (string.gsub(string.upper(o.Text), "%s", "")) end
local score = 0
if nm == "BITE" or own == "BITE" then
score = 100
elseif string.find(nm, "BITE", 1, true) then
score = 70
elseif string.find(buttonText(o), "BITE", 1, true) then
score = 45
end
if score > 0 then
score = score + math.min(20, (o.AbsoluteSize.X * o.AbsoluteSize.Y) / 900)
if score > bestScore then best, bestScore = o, score end
end
end
end
return best
end
-- ✅ หากลุ่มปุ่มสกิลรอบ BITE (SHIELD/CHARGE/SNAP/STING/STOMP เปลี่ยนตามร่าง)
function TAP.skills()
local bite = ST.biteBtn
if not (bite and bite.Parent and TAP.visible(bite)) then return {} end
local sg = bite:FindFirstAncestorOfClass("ScreenGui")
if not sg then return {} end
local bc = bite.AbsolutePosition + bite.AbsoluteSize / 2
local list = {}
for _,o in ipairs(sg:GetDescendants()) do
if o:IsA("GuiButton") and o ~= bite and TAP.visible(o) and not TAP.purchase(o) then
local sz = o.AbsoluteSize
if sz.X > 10 and sz.Y > 10 then
local c = o.AbsolutePosition + sz / 2
local lbl = string.upper(o.Name .. " " .. buttonText(o))
local skip = string.find(lbl, "RUN", 1, true) or string.find(lbl, "SPRINT", 1, true)
or string.find(lbl, "FLY", 1, true) or string.find(lbl, "JUMP", 1, true)
or string.find(lbl, "MENU", 1, true) or string.find(lbl, "BITE", 1, true)
if not skip and c.Y < bc.Y - 8
and math.abs(c.X - bc.X) <= CFG.SKILL_CLUSTER_DX
and (c - bc).Magnitude <= CFG.SKILL_CLUSTER_RADIUS then
list[#list+1] = {btn = o, x = c.X, y = c.Y}
end
end
end
end
table.sort(list, function(a, b)
if math.abs(a.y - b.y) > 12 then return a.y < b.y end
return a.x < b.x
end)
local out = {}
for i,e in ipairs(list) do out[i] = e.btn end
return out
end
-- ✅ คลิกทั่วไป (Rebirth/Claim/ปิดหน้าต่าง) ไม่บังคับทัช ไม่ยิงคีย์
local function clickGui(btn)
if not btn or not btn.Parent then return false end
if TAP.purchase(btn) then return false end
if TAP.signals(btn, {"Activated", "MouseButton1Click"}) then return true end
if TAP.touch(btn) then return true end
if pcall(function() btn:Activate() end) then return true end
return false
end
local function pressBite()
local now = os.clock()
local b = ST.biteBtn
if not (b and b.Parent and TAP.visible(b)) then
b = nil
if now - ST.biteBtnAt >= 1.2 then
ST.biteBtnAt = now
b = TAP.findBite()
ST.biteBtn = b
if b and ST.biteLogged ~= b:GetFullName() then
ST.biteLogged = b:GetFullName()
print("[TAYJAY] เจอปุ่มกัด: "..ST.biteLogged)
end
end
end
ST.biteFound = (b ~= nil)
if b then return TAP.hard(b) end
-- ไม่มีปุ่มมือถือ = เกมอยู่ layout PC → แตะจอว่างเพื่อดันกลับ tablet
if now - ST.nudgeAt >= CFG.TABLET_NUDGE then
ST.nudgeAt = now
local cam = Workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 800)
TAP.point(vp.X * 0.28, vp.Y * 0.45, 0.05)
end
return false
end
local function pressSkill(index)
local now = os.clock()
local list = ST.skillList
local b = list and list[index]
if not (b and b.Parent and TAP.visible(b)) or now - ST.skillScanAt > 2.5 then
ST.skillScanAt = now
list = TAP.skills()
ST.skillList = list
b = list[index]
local sig = (list[1] and list[1].Name or "-") .. " / " .. (list[2] and list[2].Name or "-")
if sig ~= ST.skillLogged then
ST.skillLogged = sig
print("[TAYJAY] ปุ่มสกิลบนจอ: Q=" .. (list[1] and list[1]:GetFullName() or "-") .. " | E=" .. (list[2] and list[2]:GetFullName() or "-"))
end
end
if b then return TAP.hard(b) end
return false
end
local function monsterInRange(pos, radius)
for _,g in pairs(groups.MONSTER) do
for _,o in ipairs(g.objects) do
if o and o.Parent then
local p = getPosition(o)
if p and (p - pos).Magnitude <= radius then return true end
end
end
end
return false
end
local function isAlive(obj)
if not obj or not obj.Parent then return false end
if obj:IsA("Model") then
local hum = obj:FindFirstChildOfClass("Humanoid")
if hum and hum.Health <= 0 then return false end
end
return true
end
local combatOn=false
local autoAttackOn=false
local miniAtk=nil
local function paintToggle(button, enabled, onText, offText)
button.Text = enabled and onText or offText
button.BackgroundColor3 = enabled and TH.on or TH.off
ST.dirty = true
end
local function setCombat(value)
combatOn=value
paintToggle(combat, value, "MONSTER WARP: ON", "MONSTER WARP: OFF")
if value and not autoAttackOn then
autoAttackOn=true
paintToggle(abilityToggle, true, "BITE AUTO: ON", "BITE AUTO: OFF")
if miniAtk then paintToggle(miniAtk, true, "⚔\nON", "⚔\nBITE") end
end
end
combat.MouseButton1Click:Connect(function() setCombat(not combatOn) end)
abilityToggle.MouseButton1Click:Connect(function()
autoAttackOn = not autoAttackOn
paintToggle(abilityToggle, autoAttackOn, "BITE AUTO: ON", "BITE AUTO: OFF")
if miniAtk then paintToggle(miniAtk, autoAttackOn, "⚔\nON", "⚔\nBITE") end
end)
K.MOVE_COOLDOWN = 0.04 / CFG.WARP_SPEED
K.ITEM_NEAR_DISTANCE = 2.5
K.MONSTER_NEAR_DISTANCE = 5
ST.lastWarpAt = 0
local function parseAmount(str)
local num, suf = string.match(str, "^([%d%.]+)(%a?)$")
local n = tonumber(num)
if not n then return nil end
local mult = {K=1e3, M=1e6, B=1e9, T=1e12}
return n * (mult[suf] or 1)
end
local function parsePair(text)
local t = string.upper(tostring(text or ""))
t = string.gsub(t, "<[^>]*>", "")
t = string.gsub(t, ",", "")
local a, b = string.match(t, "([%d%.]+%u?)%s*/%s*([%d%.]+%u?)")
if not a then return nil end
return parseAmount(a), parseAmount(b)
end
local function resolvePath(path)
local o = player
for seg in string.gmatch(path, "[^%.]+") do
o = o and o:FindFirstChild(seg)
if not o then return nil end
end
return o
end
local function findHPLabel()
if CFG.HP_TEXT_PATH ~= " " then
local o = resolvePath(CFG.HP_TEXT_PATH)
if o and o:IsA("TextLabel") then return o end
end
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then return nil end
local cam = Workspace.CurrentCamera
local vh = cam and cam.ViewportSize.Y or 1000
local best, bestY = nil, -1
for _,o in ipairs(pg:GetDescendants()) do
if o:IsA("TextLabel") and o.Visible and string.find(o.Text, "/", 1, true) then
local cur, max = parsePair(o.Text)
if cur and max and max > 0 and cur <= max then
local y = o.AbsolutePosition.Y + o.AbsoluteSize.Y / 2
if y > vh * 0.78 and y > bestY then best, bestY = o, y end
end
end
end
return best
end
local function readHPRatio()
local ratio = nil
local lbl = ST.hpLabel
if not (lbl and lbl.Parent) then
ST.hpLabel = nil
lbl = nil
local now = os.clock()
if now - ST.hpScanAt >= 4 then
ST.hpScanAt = now
lbl = findHPLabel()
ST.hpLabel = lbl
ST.everHealthy = false
if lbl then print("[TAYJAY] HP label: " .. lbl:GetFullName() .. " = " .. lbl.Text) end
end
end
if lbl then
local cur, max = parsePair(lbl.Text)
if cur and max and max > 0 then ratio = math.clamp(cur / max, 0, 1) end
end
local ch = player.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
if hum and hum.Health > 0 and hum.MaxHealth > 0 then
local hr = hum.Health / hum.MaxHealth
ratio = ratio and math.min(ratio, hr) or hr
end
return ratio
end
local function refreshThreats()
local t = ST.threats
table.clear(t)
for _,p in ipairs(Players:GetPlayers()) do
if p ~= player then
local ch = p.Character
local r = ch and ch:FindFirstChild("HumanoidRootPart")
if r then t[#t+1] = r.Position end
end
end
end
local function nearThreat(pos, radius)
for _,tp in ipairs(ST.threats) do
if (tp - pos).Magnitude <= radius then return true end
end
return false
end
-- =========================================================
-- ระบบตำแหน่งปลอดภัย
-- =========================================================
local function setNote(text, sec)
ST.note = text
ST.noteUntil = os.clock() + (sec or 4)
end
local SAFE = {cache = setmetatable({}, {__mode="k"}), budget = 0, budgetAt = 0, params = RaycastParams.new()}
SAFE.params.FilterType = Enum.RaycastFilterType.Exclude
function SAFE.filter(extra)
local list = {}
local ch = player.Character
if ch then list[#list+1] = ch end
if extra then list[#list+1] = extra end
SAFE.params.FilterDescendantsInstances = list
end
function SAFE.voidLevel()
local ref = ST.spawnPoint and ST.spawnPoint.Y or 0
return math.min(CFG.VOID_LEVEL, ref - CFG.VOID_DROP)
end
function SAFE.water(pos, depth, extra)
SAFE.filter(extra)
local hit = Workspace:Raycast(pos + Vector3.new(0,4,0), Vector3.new(0,-(depth+4),0), SAFE.params)
return hit ~= nil and hit.Material == Enum.Material.Water
end
local function isPositionInVoid(pos)
if not pos then return false end
return pos.Y < SAFE.voidLevel()
end
local function isPositionOutOfBounds(pos)
if not pos or CFG.MAP_LIMIT <= 0 then return false end
return math.abs(pos.X) > CFG.MAP_LIMIT or math.abs(pos.Z) > CFG.MAP_LIMIT
end
function SAFE.raw(pos, extra)
if not pos then return false end
if isPositionInVoid(pos) or isPositionOutOfBounds(pos) then return false end
SAFE.filter(extra)
local hit = Workspace:Raycast(pos + Vector3.new(0,6,0), Vector3.new(0,-(CFG.SAFE_MAX_DROP+6),0), SAFE.params)
if not hit then return false end
if hit.Material == Enum.Material.Water then return false end
return true
end
local function isSafePosition(pos, extra) return SAFE.raw(pos, extra) end
function SAFE.check(obj, pos, kind)
if not pos then return false end
if isPositionInVoid(pos) or isPositionOutOfBounds(pos) then return false end
local now = os.clock()
local c = SAFE.cache[obj]
if c and now < c.exp and (c.pos - pos).Magnitude < 10 then return c.ok end
if now - SAFE.budgetAt >= 1 then SAFE.budgetAt = now; SAFE.budget = CFG.SAFE_CHECKS_PER_SEC end
if SAFE.budget <= 0 then return true end
SAFE.budget = SAFE.budget - 1
local ok
if kind == "MONSTER" then
ok = not SAFE.water(pos, 12, obj)
else
ok = SAFE.raw(pos, obj)
end
SAFE.cache[obj] = {pos = pos, ok = ok, exp = now + (ok and CFG.SAFE_TTL_OK or CFG.SAFE_TTL_BAD)}
return ok
end
function SAFE.blacklist(obj, sec, why)
if not obj then return end
ST.voidBlacklist[obj] = os.clock() + (sec or CFG.ORB_BLACKLIST_TIME)
SAFE.cache[obj] = nil
if ST.mt and ST.mt.obj == obj then ST.mt = nil end
if ST.lastTarget == obj then ST.lastTarget = nil end
if why then setNote(why, 2) end
end
local function groundAt(x, z, y0)
SAFE.filter()
local hit = Workspace:Raycast(Vector3.new(x, y0 + 300, z), Vector3.new(0, -900, 0), SAFE.params)
if not hit or hit.Material == Enum.Material.Water then return nil end
return hit.Position + Vector3.new(0, 4, 0)
end
-- =========================================================
-- EXP tri-state
-- =========================================================
local function findExpLabel()
local pg = player:FindFirstChildOfClass("PlayerGui")
if not pg then return nil end
for _, o in ipairs(pg:GetDescendants()) do
if o:IsA("TextLabel") and o.Visible then
local t = string.upper(o.Text)
if (string.find(t,"POWER",1,true) or string.find(t,"EXP",1,true)) and string.find(t,"/",1,true) then
if o.AbsolutePosition.Y < 260 then return o end
end
end
end
return nil
end
local function readCurrentExp()
local ls = player:FindFirstChild("leaderstats")
if ls then
for _, v in ipairs(ls:GetChildren()) do
if v:IsA("IntValue") or v:IsA("NumberValue") then
local n = string.lower(v.Name)
if string.find(n,"exp",1,true) or string.find(n,"power",1,true) then
return tonumber(v.Value)
end
end
end
end
local now = os.clock()
if not (ST.expLabel and ST.expLabel.Parent) or now - ST.expLabelAt >= 15 then
ST.expLabelAt = now
ST.expLabel = findExpLabel()
end
local lbl = ST.expLabel
if lbl and lbl.Parent then return (parsePair(lbl.Text)) end
return nil
end
local function expGained(before)
if not before then return nil end
local after = readCurrentExp()
if not after then return nil end
if after < before then return nil end
if after > before then return true end
return false
end
-- =========================================================
-- Emergency Recall
-- =========================================================
local function saveSpawnPoint()
if ST.spawnPoint then return end
local root = getRoot()
if not root then return end
local pos = root.Position
if isPositionInVoid(pos) then return end
SAFE.filter()
local hit = Workspace:Raycast(pos + Vector3.new(0,6,0), Vector3.new(0,-60,0), SAFE.params)
if hit and hit.Material ~= Enum.Material.Water then
ST.spawnPoint = pos
ST.lastSafePos = pos
ST.lastSafeTime = os.clock()
print("[TAYJAY] จุดเกิดปลอดภัย: "..tostring(pos))
end
end
local function emergencyRecall(reason)
local now = os.clock()
if now - ST.recallAt < CFG.RECALL_COOLDOWN then return end
ST.recallAt = now
if now - ST.recallWindow > 30 then ST.recallWindow = now; ST.recallCount = 0 end
ST.recallCount = ST.recallCount + 1
local root = getRoot()
if not root then return end
local bad = ST.lastTarget
if bad and bad.Parent then
local bp = getPosition(bad)
if bp and (bp - root.Position).Magnitude <= 60 then SAFE.blacklist(bad, 60) end
end
ST.lastTarget = nil
local target = ST.spawnPoint or ST.lastSafePos
if not target then
SAFE.filter()
local hit = Workspace:Raycast(root.Position + Vector3.new(0,20,0), Vector3.new(0,-900,0), SAFE.params)
if hit and hit.Material ~= Enum.Material.Water then target = hit.Position end
end
if not target then target = Vector3.new(root.Position.X, SAFE.voidLevel() + 150, root.Position.Z) end
pcall(function()
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
root.CFrame = CFrame.new(target + Vector3.new(0,5,0))
end)
ST.mt = nil
ST.inVoid, ST.inWater = false, false
if ST.recallCount >= 5 then
ST.recallCount = 0
ST.farmPauseUntil = now + 10
setNote("🚨 วาร์ปฉุกเฉินถี่ผิดปกติ - พัก 10 วิ", 5)
else
setNote("🚨 "..reason, 3)
end
print("[TAYJAY] Emergency Recall: "..reason)
end
local function checkCharacterStatus()
local now = os.clock()
if now - ST.statusAt < CFG.STATUS_POLL then return end
ST.statusAt = now
local ch = player.Character
local root = getRoot()
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
if not (root and hum and hum.Health > 0) then return end
saveSpawnPoint()
local pos = root.Position
if isPositionInVoid(pos) then
ST.inVoid = true
emergencyRecall("ตก VOID")
return
end
ST.inVoid = false
local swimming = hum:GetState() == Enum.HumanoidStateType.Swimming
if swimming or hum.FloorMaterial == Enum.Material.Water then
ST.inWater = true
emergencyRecall("จมน้ำ")
return
end
ST.inWater = false
if hum.FloorMaterial ~= Enum.Material.Air and pos.Y > SAFE.voidLevel() + 20 then
if now - ST.groundCheckAt > 1.0 then
ST.groundCheckAt = now
SAFE.filter()
local hit = Workspace:Raycast(pos + Vector3.new(0,4,0), Vector3.new(0,-16,0), SAFE.params)
ST.groundOK = hit ~= nil and hit.Material ~= Enum.Material.Water
end
if ST.groundOK then
ST.lastSafePos = pos
ST.lastSafeTime = now
end
end
end
-- =========================================================
-- ✅ V25: บล็อก Robux 3 ชั้น (namecall / ปิดหน้าต่าง / แบนปุ่ม)
-- =========================================================
local function findCloseButton(root)
for _,d in ipairs(root:GetDescendants()) do
if d:IsA("GuiButton") and TAP.visible(d) then
local t = buttonText(d)
local nm = string.upper(d.Name)
if t == "X" or t == "✕" or t == "×" or t == "✖" or t == "NO"
or string.find(t, "CLOSE", 1, true) or string.find(nm, "CLOSE", 1, true)
or string.find(nm, "BACK", 1, true) or string.find(t, "CANCEL", 1, true)
or string.find(t, "ยกเลิก", 1, true) or string.find(t, "ปิด", 1, true) then
return d
end
end
end
return nil
end
local function closePurchasePrompt()
local found = false
local ok, kids = pcall(function() return CoreGui:GetChildren() end)
if not ok or type(kids) ~= "table" then return false end
for _,o in ipairs(kids) do
local okGui, isGui = pcall(function() return o:IsA("ScreenGui") end)
if okGui and isGui then
local nm = string.lower(o.Name)
if string.find(nm,"purchase",1,true) or string.find(nm,"robux",1,true) or string.find(nm,"premium",1,true) then
local on = false
pcall(function() on = o.Enabled end)
if on then
found = true
pcall(function()
local c = findCloseButton(o)
if c then clickGui(c) end
end)
pcall(function() o.Enabled = false end)
end
end
end
end
return found
end
pcall(function()
local g = getgenv and getgenv()
if not g then return end
g.TAYJAY_BLOCK_ROBUX = CFG.BLOCK_ROBUX and true or false
if g.TAYJAY_PURCHASE_HOOK then return end
if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then return end
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
if self == MS and g.TAYJAY_BLOCK_ROBUX then
local okM, m = pcall(getnamecallmethod)
if okM and (m == "PromptProductPurchase" or m == "PromptPurchase"
or m == "PromptBundlePurchase" or m == "PromptPremiumPurchase"
or m == "PromptGamePassPurchase" or m == "PromptRobuxPurchase") then
return nil
end
end
return old(self, ...)
end)
g.TAYJAY_PURCHASE_HOOK = true
print("[TAYJAY] ติดตั้งตัวบล็อกหน้าต่าง Robux แล้ว")
end)
local function closeShopWindows(pg)
local now = os.clock()
if now - ST.buyScanAt < 2 then return false end
ST.buyScanAt = now
table.clear(ST.buyWindows)
local closed = false
-- ชั้น 1: ScreenGui ที่ชื่อสื่อว่า "ซื้อ" ทั้งก้อน
for _,sg in ipairs(pg:GetChildren()) do
if sg:IsA("ScreenGui") and sg ~= gui then
local nm = (string.gsub(string.lower(sg.Name), "[^%a]", ""))
if string.find(nm,"purchase",1,true) or string.find(nm,"buyitem",1,true)
or string.find(nm,"robux",1,true) or string.find(nm,"premium",1,true) then
ST.buyWindows[sg] = true
if sg.Enabled then
local c = findCloseButton(sg)
if c then clickGui(c); closed = true end
end
end
end
end
-- ชั้น 2: เฟรมที่มีข้อความราคา/ซื้อ
local cam = Workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 800)
local maxArea = vp.X * vp.Y * 0.7
for _, o in ipairs(pg:GetDescendants()) do
if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and not o:IsDescendantOf(gui) and TAP.visible(o) then
local t = string.upper(o.Text)
if string.find(t,"BUY ITEM",1,true) or string.find(t,"ROBUX",1,true) or string.find(t,"R$",1,true)
or string.find(t,"◎",1,true) or string.find(t,"ROBLOX PLUS",1,true)
or string.find(t,"GET FREE TRIAL",1,true) or string.find(t,"BUY NOW",1,true) then
local w = o
for _ = 1, 5 do
if w.Parent and w.Parent:IsA("Frame") then w = w.Parent else break end
end
if w:IsA("Frame") and not ST.buyWindows[w] then
local area = w.AbsoluteSize.X * w.AbsoluteSize.Y
if area >= 18000 and area <= maxArea then
ST.buyWindows[w] = true
local c = findCloseButton(w)
if c then clickGui(c); closed = true end
end
end
end
end
end
return closed
end
local function nearestEnabled(kind, rootPos)
local best, bestRank, bestBucket, bestDist = nil, math.huge, -math.huge, math.huge
local now = os.clock()
local avoid = CFG.GUARD and ST.hp < CFG.CAUTION_HP
for key,g in pairs(groups[kind]) do
if enabled[key] then
for _,obj in ipairs(g.objects) do
local bl = ST.voidBlacklist[obj]
if obj and obj.Parent and not (bl and now < bl) then
local rawName = string.lower(obj.Name or "")
local whole = (kind ~= "MONSTER") or (isAlive(obj) and baseName(rawName) == rawName)
if whole then
local canVisit = true
if kind == "ITEM" then
local v = itemVisits[obj]
if v and (v.skipUntil > now or v.cool > now) then canVisit = false end
else
local mb = ST.mBlack[obj]
if mb and mb > now then canVisit = false end
end
if canVisit then
local pos = getPosition(obj)
if pos and SAFE.check(obj, pos, kind) and not (avoid and nearThreat(pos, CFG.CAUTION_RADIUS)) then
local d = (pos - rootPos).Magnitude
local rank, bucket = 1, 0
if kind == "ITEM" then
rank, bucket = itemRankBucket(obj, g)
elseif CFG.MONSTER_MODE == "value" then
rank, bucket = monsterRankBucket(obj, g)
end
if rank < bestRank or (rank == bestRank and (bucket > bestBucket or (bucket == bestBucket and d < bestDist))) then
best, bestRank, bestBucket, bestDist = obj, rank, bucket, d
end
end
end
end
end
end
end
end
return best
end
local function moveToObject(obj,root,kind)
local pos=getPosition(obj)
if not pos or not root or not root.Parent then return false end
local distance=(pos-root.Position).Magnitude
local nearDistance=(kind=="ITEM") and K.ITEM_NEAR_DISTANCE or K.MONSTER_NEAR_DISTANCE
if distance<=nearDistance then return true end
local now=os.clock()
if now-ST.lastWarpAt<K.MOVE_COOLDOWN then return true end
local ok=pcall(function()
root.CFrame=CFrame.new(pos)
root.AssemblyLinearVelocity=Vector3.zero
root.AssemblyAngularVelocity=Vector3.zero
end)
if ok then ST.lastWarpAt=now end
return ok
end
local function monsterTarget(rootPos)
local now = os.clock()
local t = ST.mt
if t then
local o = t.obj
if not (o and o.Parent and isAlive(o)) then
ST.mt = nil
elseif now - t.since > CFG.MONSTER_TIMEOUT then
ST.mBlack[o] = now + CFG.MONSTER_BLACKLIST
ST.mt = nil
elseif not enabled[objectGroup[o] or ""] then
ST.mt = nil
elseif CFG.MONSTER_MODE == "value" and now - ST.mCheckAt >= 1.0 then
ST.mCheckAt = now
local best = nearestEnabled("MONSTER", rootPos)
if best and best ~= o then
local g1 = groups.MONSTER[objectGroup[best] or ""]
local g0 = groups.MONSTER[objectGroup[o] or ""]
if g1 and g0 and monsterRankBucket(best, g1) < monsterRankBucket(o, g0) then
ST.mt = {obj = best, since = now}
end
end
end
end
if not ST.mt then
local m = nearestEnabled("MONSTER", rootPos)
if m then ST.mt = {obj = m, since = now} end
end
return ST.mt and ST.mt.obj or nil
end
local function anyEnabledTarget()
for key,on in pairs(enabled) do
if on then
if string.sub(key,1,5)=="ITEM|" then return true end
if combatOn and string.sub(key,1,8)=="MONSTER|" then return true end
end
end
return false
end
local function pickHotspot(fromPos)
local best, bestScore = nil, nil
local now = os.clock()
for _,h in ipairs(ST.hot) do
if (h.pos - fromPos).Magnitude > 40 then
local sc = h.visits * 1000 - math.min(900, now - h.last)
if not bestScore or sc < bestScore then best, bestScore = h, sc end
end
end
return best
end
local function roamStep(root)
local now = os.clock()
if now - ST.roamAt < CFG.ROAM_INTERVAL then return false end
ST.roamAt = now
local pos = nil
local h = pickHotspot(root.Position)
if h then
h.visits = h.visits + 1
h.last = now
local cand = h.pos + Vector3.new(0, 3, 0)
if isSafePosition(cand) then pos = cand end
else
local o = ST.origin or root.Position
local ang = math.random() * math.pi * 2
local r = 80 + math.random() * 180
pos = groundAt(o.X + math.cos(ang) * r, o.Z + math.sin(ang) * r, root.Position.Y)
end
if not pos then return false end
pcall(function()
root.CFrame = CFrame.new(pos)
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
end)
task.spawn(function() pcall(function() player:RequestStreamAroundAsync(pos) end) end)
return true
end
local hasFireTouch = (typeof(firetouchinterest) == "function")
local touchPartCache = setmetatable({}, {__mode="k"})
local function getTouchParts(obj)
local c = touchPartCache[obj]
if c and c[1] and c[1].Parent then return c end
local list = {}
if obj:IsA("BasePart") then
list[1] = obj
else
local first = nil
for _,d in ipairs(obj:GetDescendants()) do
if d:IsA("BasePart") then
first = first or d
if #list < 6 and d:FindFirstChildWhichIsA("TouchTransmitter") then list[#list+1] = d end
end
end
if #list == 0 and first then list[1] = first end
end
touchPartCache[obj] = list
return list
end
local function touchUseful()
local n = ST.touchHits + ST.touchMiss
return n < 8 or ST.touchHits / n >= 0.25
end
local function fireTouch(obj, root)
if not hasFireTouch or not touchUseful() then return false end
local fired = false
for _,p in ipairs(getTouchParts(obj)) do
if p.Parent then
pcall(firetouchinterest, root, p, 0)
pcall(firetouchinterest, root, p, 1)
fired = true
end
end
return fired
end
local function visitItem(obj,root)
local now=os.clock()
local v=itemVisits[obj]
if not v then
v={touches=0,warps=0,skipUntil=0,cool=0,failCount=0}
itemVisits[obj]=v
end
if v.skipUntil>now or v.cool>now then return false end
local bl = ST.voidBlacklist[obj]
if bl and now < bl then return false end
local pos = getPosition(obj)
local g = groups.ITEM[objectGroup[obj] or ""]
local isBuff = (g and g.buff) or false
local function snap()
if CFG.EXP_CHECK and not isBuff then return readCurrentExp() end
return nil
end
local function expWatch(before)
if not before then return end
task.delay(1.2, function()
if not obj.Parent then return end
local gained = expGained(before)
if gained == true then
v.failCount = 0
elseif gained == false then
v.failCount = v.failCount + 1
if v.failCount >= CFG.EXP_FAIL_LIMIT then
v.failCount = 0
SAFE.blacklist(obj, CFG.ORB_BLACKLIST_TIME, "⚠️ Orb ไม่ได้ EXP - พักชั่วคราว")
end
end
end)
end
if v.touches<K.TOUCH_TRIES and fireTouch(obj,root) then
v.touches=v.touches+1
v.cool=now+K.TOUCH_COOLDOWN
expWatch(snap())
return true
end
v.warps=v.warps+1
if v.warps==1 and v.touches>0 then ST.touchMiss=ST.touchMiss+1 end
if v.warps>K.WARP_TRIES then
v.warps=0
v.touches=0
v.skipUntil=now+K.ITEM_SKIP_SECONDS
return false
end
if pos and not SAFE.check(obj, pos, "ITEM") then
SAFE.blacklist(obj, CFG.ORB_BLACKLIST_TIME, "⚠️ Orb นอกแมพ/ในน้ำ - ข้าม")
v.skipUntil = now + 30
return false
end
local before = snap()
local ok=moveToObject(obj,root,"ITEM")
if ok then
fireTouch(obj,root)
v.cool=now+K.WARP_COOLDOWN
expWatch(before)
end
return ok
end
ST.itemStreak=0
local function nextEnabledTarget(rootPos)
if combatOn and ST.itemStreak>=K.ITEM_STREAK_LIMIT then
local m=monsterTarget(rootPos)
if m then
ST.itemStreak=0
return "MONSTER",m
end
end
local item=nearestEnabled("ITEM",rootPos)
if item then
ST.itemStreak=ST.itemStreak+1
return "ITEM",item
end
if combatOn then
local m=monsterTarget(rootPos)
if m then
ST.itemStreak=0
return "MONSTER",m
end
end
return nil,nil
end
ST.shownAction=nil
ST.lastStatusAt=0
local function showAction()
local now=os.clock()
if ST.shownAction~=ST.currentAction and now-ST.lastStatusAt>=0.12 then
ST.shownAction=ST.currentAction
ST.lastStatusAt=now
status.Text="HP "..math.floor(ST.hp*100+0.5).."% • กัด:"..(ST.biteFound and "✓" or "✗").." • "..ST.currentAction
end
end
local function enterSafe(root)
ST.guard=true
ST.fleeFrom=root.Position
ST.fleeAt=os.clock()
ST.lastRise=ST.fleeAt
ST.lastHp=ST.hp
ST.resumeReadyAt=nil
setNoclip(false)
local padPos=ST.fleeFrom+Vector3.new(0,CFG.SAFE_HEIGHT,0)
if not (ST.pad and ST.pad.Parent) then
local pad=Instance.new("Part")
pad.Name="SafeZonePad_TJ"
pad.Anchored=true
pad.CanCollide=true
pad.Size=Vector3.new(30,2,30)
pad.Transparency=0.6
pad.Parent=Workspace
ST.pad=pad
end
ST.pad.CFrame=CFrame.new(padPos)
pcall(function()
root.AssemblyLinearVelocity=Vector3.zero
root.AssemblyAngularVelocity=Vector3.zero
root.CFrame=CFrame.new(padPos+Vector3.new(0,4,0))
end)
print("[TAYJAY] HP "..math.floor(ST.hp*100+0.5).."% -> ไปหลบบนแท่นปลอดภัย")
end
local function exitSafe(reason, cooldown)
ST.guard=false
ST.resumeReadyAt=nil
ST.cooldownUntil=os.clock()+(cooldown or 3)
lastSafeCFrame=nil
local root=getRoot()
if root and ST.fleeFrom then
pcall(function()
root.AssemblyLinearVelocity=Vector3.zero
root.CFrame=CFrame.new(ST.fleeFrom+Vector3.new(0,3,0))
end)
end
if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad=nil end
setNote(reason,5)
print("[TAYJAY] "..reason)
end
task.spawn(function()
while gui.Parent do
refreshThreats()
local r=readHPRatio()
if r then
ST.hp=r
if r >=0.5 then ST.everHealthy=true end
end
local root=getRoot()
local now=os.clock()
checkCharacterStatus()
if ST.guard and not CFG.GUARD then
exitSafe("ปิดระบบหลบ - กลับไปเก็บของ",0)
elseif CFG.GUARD and root and r then
if not ST.guard then
if r <CFG.HP_LOW and ST.everHealthy and now >=ST.cooldownUntil then enterSafe(root) end
else
if r >ST.lastHp+0.005 then ST.lastRise=now end
ST.lastHp=r
if r >=CFG.HP_RESUME then
ST.resumeReadyAt=ST.resumeReadyAt or now
if not nearThreat(ST.fleeFrom,CFG.THREAT_RADIUS) then
exitSafe("เลือดฟื้นแล้ว ไม่มีศัตรู - กลับไปเก็บของ",3)
elseif now-ST.resumeReadyAt >CFG.THREAT_WAIT_MAX then
exitSafe("รอศัตรูนานเกินไป - กลับไปเก็บของ",10)
end
else
ST.resumeReadyAt=nil
if now-ST.lastRise >CFG.NO_REGEN_TIMEOUT then
exitSafe("เลือดไม่ฟื้น - เลิกรอ กลับไปเก็บของ",CFG.GUARD_COOLDOWN)
end
end
end
end
task.wait(0.1)
end
end)
do
local function guiShown(o) return TAP.visible(o) end
local function pathOf(o)
if o and o.Parent then return o:GetFullName() end
return "-"
end
local function hasRebirthAncestor(o, pg)
local p = o.Parent
while p and p ~= pg do
if string.find(string.lower(p.Name), "rebirth", 1, true) then return true end
p = p.Parent
end
return false
end
local function inRebirthGui(o)
local sg = o:FindFirstAncestorOfClass("ScreenGui")
return sg ~= nil and string.find(string.lower(sg.Name), "rebirth", 1, true) ~= nil
end
local PURE_PAIR = "^%s*%a*%s*[%d%.,]+%s*[KkMmBbTt]?%s*/%s*[%d%.,]+%s*[KkMmBbTt]?%s*$"
local function visibleText(o)
local parts = {}
local function add(x)
if (x:IsA("TextLabel") or x:IsA("TextButton")) and x.Text ~= "" and guiShown(x) then
parts[#parts+1] = x.Text
end
end
add(o)
for _,d in ipairs(o:GetDescendants()) do add(d) end
return string.upper(table.concat(parts, " "))
end
local function scanRebirthUI(pg)
local ui = {rowTexts = {}}
local cam = Workspace.CurrentCamera
local vh = cam and cam.ViewportSize.Y or 1000
for _,o in ipairs(pg:GetDescendants()) do
if o:IsA("TextLabel") then
local t = string.upper(o.Text)
local inRebirth = hasRebirthAncestor(o, pg)
if inRebirth and o.Text ~= "" and #ui.rowTexts < 8 then ui.rowTexts[#ui.rowTexts+1] = o.Text end
if string.find(t, "/",1,true) then
local cur, req = parsePair(o.Text)
if cur and req and req > 0 then
if inRebirth and string.find(t, "POWER",1,true) then ui.power = ui.power or o end
if not ui.top and string.find(o.Text, PURE_PAIR) and guiShown(o) then
local y = o.AbsolutePosition.Y + o.AbsoluteSize.Y / 2
if y < vh * 0.18 then ui.top = o end
end
end
end
if not ui.readyLbl and inRebirth and string.find(t, "READY TO REBIRTH",1,true) then ui.readyLbl = o end
elseif o:IsA("GuiButton") and not o:IsDescendantOf(gui) and not TAP.purchase(o) then
local lname = string.lower(o.Name)
if string.find(lname, "evolve", 1, true) then
local sg = o:FindFirstAncestorOfClass("ScreenGui")
if sg and string.find(string.lower(sg.Name), CFG.EVOLVE_GUI_WORD, 1, true) then
if not ui.evo or (guiShown(o) and not guiShown(ui.evo)) then ui.evo = o end
end
else
local all = buttonText(o)
if string.find(all, "REBIRTH",1,true) or string.find(all, "TAP AGAIN",1,true) or string.find(lname, "rebirth",1,true) then
local shownNow = guiShown(o)
local txt = shownNow and visibleText(o) or all
local inWin = inRebirthGui(o)
local isB = string.find(txt, "TAP AGAIN",1,true) ~= nil
local isA = (not isB) and (string.find(txt, "REBIRTH%sX%s%d") ~= nil or (inWin and string.find(txt, "REBIRTH",1,true) ~= nil))
local key = isB and "b" or (isA and "a" or "opener")
local cur = ui[key]
if not cur or (shownNow and not guiShown(cur)) then ui[key] = o end
end
end
end
end
return ui
end
local function evoShownText(ui)
local e = ui.evo
if e and e.Parent and guiShown(e) then return visibleText(e) end
return ""
end
-- ✅ V25: ลบเงื่อนไข stage="omega" ทิ้ง — เทียบหลอดบนตรง ๆ ทุกร่าง
local function rebirthReadyFromUI(ui)
if string.find(evoShownText(ui), "REBIRTH", 1, true) then return true end
if ui.power and ui.power.Parent then
local cur, req = parsePair(ui.power.Text)
if cur and req and req > 0 then return cur >= req end
end
if ui.readyLbl and ui.readyLbl.Parent then
return not string.find(string.upper(ui.readyLbl.Text), "NOT", 1, true)
end
if ui.top and ui.top.Parent and string.find(ui.top.Text, PURE_PAIR) then
local cur, req = parsePair(ui.top.Text)
if cur and req and req > 0 then return cur >= req end
end
return false
end
local function rebirthCount()
local ls=player:FindFirstChild("leaderstats")
if ls then
for _,v in ipairs(ls:GetChildren()) do
if v:IsA("ValueBase") and string.find(string.lower(v.Name), "rebirth",1,true) then
return tonumber(v.Value)
end
end
end
return nil
end
task.spawn(function()
local fails=0
while gui.Parent do
local pg=player:FindFirstChildOfClass("PlayerGui")
local now=os.clock()
if pg and (CFG.REBIRTH or CFG.EVOLVE) then
local inSeq = now-ST.rbTryAt <6
if now-ST.rbScanAt >=(inSeq and 0.3 or 1.5) then
ST.rbScanAt=now
local ui=scanRebirthUI(pg)
ST.rb=ui
local sig=pathOf(ui.power).."| "..pathOf(ui.a).."| "..pathOf(ui.b).."| "..pathOf(ui.opener).."| "..pathOf(ui.evo)
if sig~=ST.rbLoggedFor then
ST.rbLoggedFor=sig
print("[TAYJAY] Rebirth UI: HUD="..pathOf(ui.evo).." | top="..pathOf(ui.top).." | ปุ่มขั้น2="..pathOf(ui.a).." | ปุ่มขั้น3="..pathOf(ui.b).." | สำรอง="..pathOf(ui.opener))
end
local readyNow=rebirthReadyFromUI(ui)
if readyNow~=ST.rbReadyPrev or now-ST.rbDbgAt >=60 then
ST.rbReadyPrev=readyNow
ST.rbDbgAt=now
local rowInfo=""
if not ST.rbRowLogged then
ST.rbRowLogged=true
rowInfo=" | แถวRebirth='"..table.concat(ui.rowTexts, " ; ").."'"
end
print("[TAYJAY] Rebirth check: พร้อม="..tostring(readyNow).." | top='"..(ui.top and ui.top.Text or "-").."' | ปุ่มHUD='"..evoShownText(ui).."' "..rowInfo)
end
end
local ui=ST.rb
if CFG.REBIRTH and ui and now>=ST.rbBlockedUntil and now-ST.rbTryAt>=CFG.REBIRTH_STEP_DELAY and rebirthReadyFromUI(ui) then
local opener=ui.opener
if string.find(evoShownText(ui),"REBIRTH",1,true) then opener=ui.evo end
local pick,stage=nil,1
if ui.b and ui.b.Parent then
pick,stage=ui.b,3
elseif ui.a and ui.a.Parent then
if guiShown(ui.a) then
pick,stage=ui.a,2
elseif opener and opener.Parent and now-ST.rbOpenAt>=6 then
pick,stage=opener,1
ST.rbOpenAt=now
elseif now-ST.rbOpenAt>=2.5 then
pick,stage=ui.a,2
end
elseif opener and opener.Parent and now-ST.rbOpenAt>=6 then
pick,stage=opener,1
ST.rbOpenAt=now
end
if pick then
ST.rbTryAt=now
clickGui(pick)
setNote("REBIRTH ขั้น "..stage.."/3",3)
print("[TAYJAY] Rebirth ขั้น "..stage.."/3 -> "..pathOf(pick))
if stage==3 then
if now-ST.rbBStart>40 then ST.rbBStart=now; ST.rbBCount=0 end
ST.rbBCount=ST.rbBCount+1
if ST.rbBCount>4 then
ST.rbBCount=0
ST.rbBlockedUntil=now+60
print("[TAYJAY] กดยืนยัน Rebirth หลายครั้งแต่ยังไม่สำเร็จ - พัก 60 วินาที")
end
local before=rebirthCount()
if before then
task.delay(4,function()
local after=rebirthCount()
if after and after>before then
fails=0
else
fails=fails+1
if fails>=3 then
fails=0
ST.rbBlockedUntil=os.clock()+120
print("[TAYJAY] Rebirth 3 รอบแล้วจำนวนไม่เพิ่ม - พัก 120 วินาที")
end
end
end)
end
end
elseif not (ui.a or ui.b or ui.opener or ui.evo) and now-ST.rbLogAt>30 then
ST.rbLogAt=now
print("[TAYJAY] พร้อม Rebirth แล้ว แต่ยังไม่พบปุ่ม - ส่งบรรทัด Rebirth UI มาให้ปรับ")
end
end
if CFG.EVOLVE and ui and ui.evo and ui.evo.Parent and now-ST.evoAt>=CFG.EVOLVE_COOLDOWN and now-ST.rbTryAt>=8 then
local txt=evoShownText(ui)
if txt~="" and not string.find(txt,"REBIRTH",1,true) then
ST.evoAt=now
ST.evoClicks=ST.evoClicks+1
clickGui(ui.evo)
setNote("EVOLVE",2)
if ST.evoClicks<=5 or ST.evoClicks%20==0 then
print("[TAYJAY] กดปุ่ม HUD '"..txt.."' ครั้งที่ "..ST.evoClicks)
end
end
end
end
task.wait(CFG.REBIRTH_POLL)
end
end)
-- ✅ V25: CLAIM — เฉพาะปุ่มที่มองเห็น + ไม่อยู่ใน GUI ซื้อ + ไม่โดนแบน
local function scanClaimButtons(pg)
local found = {}
for _,o in ipairs(pg:GetDescendants()) do
if o:IsA("GuiButton") and not o:IsDescendantOf(gui)
and not ST.badClaim[o] and TAP.visible(o) and not TAP.purchase(o) then
local txt = buttonText(o)
if string.find(txt, "%f[%a]CLAIM%f[%A]")
and not string.find(txt, "BUY", 1, true)
and not string.find(txt, "PURCHASE", 1, true)
and not string.find(txt, "ROBUX", 1, true)
and not string.find(txt, "R$", 1, true)
and not string.find(txt, "◎", 1, true)
and not string.find(txt, "ALL 7", 1, true) then
found[#found+1] = o
end
end
end
return found
end
task.spawn(function()
local lastClaim = setmetatable({}, {__mode="k"})
local loggedClaim = setmetatable({}, {__mode="k"})
local attempts = setmetatable({}, {__mode="k"})
local blockedUntil = setmetatable({}, {__mode="k"})
while gui.Parent do
if CFG.CLAIM and os.clock() >= ST.claimPauseUntil then
local pg = player:FindFirstChildOfClass("PlayerGui")
if pg then
closeShopWindows(pg)
for _,btn in ipairs(scanClaimButtons(pg)) do
local now = os.clock()
if btn.Parent and now >= (blockedUntil[btn] or 0) and (not lastClaim[btn] or now-lastClaim[btn] >= CFG.CLAIM_RETRY) then
lastClaim[btn] = now
ST.lastClaimBtn = btn
ST.lastClaimAt = now
attempts[btn] = (attempts[btn] or 0) + 1
if attempts[btn] >= 3 then
attempts[btn] = 0
blockedUntil[btn] = now + 600
print("[TAYJAY] Claim ปุ่มนี้กด 3 ครั้งแล้วยังเป็น CLAIM - พัก 10 นาที: "..pathOf(btn))
end
clickGui(btn)
if not loggedClaim[btn] then
loggedClaim[btn] = true
print("[TAYJAY] Claim -> "..pathOf(btn))
end
setNote("CLAIM",2)
task.wait(0.4)
end
end
end
end
task.wait(CFG.CLAIM_POLL)
end
end)
SET.rebirth.MouseButton1Click:Connect(function()
CFG.REBIRTH=not CFG.REBIRTH
paintToggle(SET.rebirth,CFG.REBIRTH,"REBIRTH: ON","REBIRTH: OFF")
end)
SET.guard.MouseButton1Click:Connect(function()
CFG.GUARD=not CFG.GUARD
paintToggle(SET.guard,CFG.GUARD,"GUARD: ON","GUARD: OFF")
end)
SET.claim.MouseButton1Click:Connect(function()
CFG.CLAIM=not CFG.CLAIM
paintToggle(SET.claim,CFG.CLAIM,"CLAIM: ON","CLAIM: OFF")
end)
end
-- =========================================================
-- Worker หลัก
-- =========================================================
task.spawn(function()
task.wait(0.5)
saveSpawnPoint()
while gui.Parent do
local root=getRoot()
if root then
ST.origin=ST.origin or root.Position
checkCharacterStatus()
local now = os.clock()
if now < ST.farmPauseUntil then
ST.currentAction="⏸ พักกันวาร์ปวน "..math.ceil(ST.farmPauseUntil-now).." วิ"
showAction()
task.wait(0.3)
elseif ST.guard then
ST.currentAction="[GUARD] หลบอยู่ HP "..math.floor(ST.hp*100+0.5).."% รอ "..math.floor(CFG.HP_RESUME*100).."%"
showAction()
task.wait(0.15)
else
if CFG.AUTO_NOCLIP and not noclipOn and not ST.noclipUserOff then setNoclip(true) end
local kind,target=nextEnabledTarget(root.Position)
ST.lastTarget = target
if kind and target then
ST.idleSince=nil
local ok=false
if kind=="ITEM" then
ok=visitItem(target,root)
else
ok=moveToObject(target,root,"MONSTER")
end
if ok then
ST.currentAction=kind.." • "..groupName(target,kind)
else
ST.currentAction="ค้นหาเป้าหมายถัดไป..."
end
if os.clock()<ST.noteUntil then ST.currentAction=ST.note.." | "..ST.currentAction end
showAction()
task.wait(kind=="ITEM" and K.ITEM_DWELL or K.MONSTER_DWELL)
else
ST.idleSince=ST.idleSince or now
ST.currentAction="รอเป้าหมาย..."
if CFG.ROAM and now-ST.idleSince>=CFG.ROAM_AFTER and anyEnabledTarget() then
if roamStep(root) then
ST.currentAction="เดินสำรวจหาเป้าหมาย..."
showAction()
task.wait(0.7)
end
end
if os.clock()<ST.noteUntil then ST.currentAction=ST.note.." | "..ST.currentAction end
showAction()
task.wait(K.IDLE_DELAY)
end
end
else
ST.currentAction="รอตัวละคร..."
showAction()
task.wait(0.3)
end
end
end)
miniAtk = make("TextButton",{Name="TayJayMiniAttack",Size=UDim2.fromOffset(66,66),Position=UDim2.new(1,-84,0.55,0),BackgroundColor3=TH.off,Text="⚔\nBITE",TextColor3=Color3.new(1,1,1),TextSize=14,Font=FONT,BorderSizePixel=0,Active=true,Draggable=true},gui)
make("UICorner",{CornerRadius=UDim.new(1,0)},miniAtk)
make("UIStroke",{Color=Color3.new(1,1,1),Thickness=3},miniAtk)
miniAtk.MouseButton1Click:Connect(function()
autoAttackOn=not autoAttackOn
paintToggle(miniAtk,autoAttackOn,"⚔\nON","⚔\nBITE")
paintToggle(abilityToggle,autoAttackOn,"BITE AUTO: ON","BITE AUTO: OFF")
end)
-- ✅ เธรดกัด (ทัชปุ่ม BITE บนจอเท่านั้น)
task.spawn(function()
while gui.Parent do
local root=getRoot()
if autoAttackOn and root and not ST.guard then
pressBite()
task.wait(CFG.BITE_INTERVAL)
else
task.wait(0.25)
end
end
end)
-- ✅ เธรดสกิลอิสระ (ทัชปุ่มบนจอ ไม่ผูก MONSTER WARP / ไม่ยิงคีย์)
task.spawn(function()
while gui.Parent do
if CFG.SKILLS and not ST.guard and not ST.closing then
local root = getRoot()
if root then
local go = true
if CFG.SKILL_NEED_ENEMY then
go = monsterInRange(root.Position, CFG.SKILL_RANGE) or (ST.mt ~= nil)
end
if go then
local now = os.clock()
if now - ST.skillQAt >= CFG.SKILL_Q_INTERVAL then
ST.skillQAt = now
pressSkill(1)
end
if now - ST.skillEAt >= CFG.SKILL_E_INTERVAL then
ST.skillEAt = now
pressSkill(2)
end
end
end
end
task.wait(0.25)
end
end)
-- ✅ เฝ้าปิดหน้าต่าง Robux + แบนปุ่มต้นเหตุ
task.spawn(function()
while gui.Parent do
if CFG.BLOCK_ROBUX then
local pg = player:FindFirstChildOfClass("PlayerGui")
local hit = closePurchasePrompt()
if pg and closeShopWindows(pg) then hit = true end
if hit then
ST.promptHits = ST.promptHits + 1
local now = os.clock()
local b = ST.lastClaimBtn
if b and now - ST.lastClaimAt < 3 then
ST.badClaim[b] = true
ST.lastClaimBtn = nil
print("[TAYJAY] ⛔ ปุ่ม CLAIM นี้เปิดหน้าต่าง Robux - แบนถาวร: "..b:GetFullName())
end
ST.claimPauseUntil = now + CFG.CLAIM_PAUSE_AFTER_PROMPT
setNote("⛔ บล็อกหน้าต่าง Robux", 3)
end
end
task.wait(CFG.PURCHASE_POLL)
end
end)
local function applyWarpSpeed()
K.WARP_COOLDOWN = 0.15 / CFG.WARP_SPEED
K.MOVE_COOLDOWN = 0.04 / CFG.WARP_SPEED
end
local function saveState()
if typeof(writefile) ~= "function" then return end
local d = {v=250, enabled={}, known={ITEM={}, MONSTER={}}, cfg={}}
for k,v in pairs(enabled) do d.enabled[k] = v and true or false end
for _,cat in ipairs({"ITEM", "MONSTER"}) do
for key,k in pairs(known[cat]) do
d.known[cat][key] = {name=k.name, buff=k.buff and true or false, rank=k.rank, pscore=k.pscore}
end
end
for _,f in ipairs(CFG.SAVE_FLAGS) do d.cfg[f] = CFG[f] and true or false end
d.cfg.MONSTER_MODE = CFG.MONSTER_MODE
d.cfg.BITE_INTERVAL = CFG.BITE_INTERVAL
d.cfg.WARP_SPEED = CFG.WARP_SPEED
pcall(function() writefile(CFG.SAVE_FILE, game:GetService("HttpService"):JSONEncode(d)) end)
end
local function loadState()
if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return end
local ok, d = pcall(function()
if not isfile(CFG.SAVE_FILE) then return nil end
return game:GetService("HttpService"):JSONDecode(readfile(CFG.SAVE_FILE))
end)
if not ok or type(d) ~= "table" then return end
if type(d.enabled) == "table" then
for k,v in pairs(d.enabled) do enabled[k] = (v == true) end
end
if type(d.known) == "table" then
for _,cat in ipairs({"ITEM", "MONSTER"}) do
local src = d.known[cat]
if type(src) == "table" then
for key,k in pairs(src) do
if type(k) == "table" and type(k.name) == "string" then
known[cat][key] = {key=key, name=k.name, buff=(k.buff == true), rank=tonumber(k.rank) or 3, pscore=tonumber(k.pscore) or 0}
end
end
end
end
end
if type(d.cfg) == "table" then
for _,f in ipairs(CFG.SAVE_FLAGS) do
if type(d.cfg[f]) == "boolean" then CFG[f] = d.cfg[f] end
end
if d.cfg.MONSTER_MODE == "value" or d.cfg.MONSTER_MODE == "near" then CFG.MONSTER_MODE = d.cfg.MONSTER_MODE end
local bi = tonumber(d.cfg.BITE_INTERVAL)
if bi and bi >= 0.05 and bi <= 0.6 then CFG.BITE_INTERVAL = bi end
local ws = tonumber(d.cfg.WARP_SPEED)
if ws and ws >= 0.2 and ws <= 2 then CFG.WARP_SPEED = ws; applyWarpSpeed() end
end
end
task.spawn(function()
while gui.Parent do
task.wait(4)
if ST.dirty and not ST.closing then
ST.dirty = false
saveState()
end
end
end)
local function paintMode()
SET.mode.Text = (CFG.MONSTER_MODE == "value") and "ตีมอน: ค่าสูงก่อน" or "ตีมอน: ใกล้สุดก่อน"
SET.mode.BackgroundColor3 = TH.btnBlue
end
SL.bite.onChange = function(v) CFG.BITE_INTERVAL = 1 / v; ST.dirty = true end
SL.warp.onChange = function(v) CFG.WARP_SPEED = v; applyWarpSpeed(); ST.dirty = true end
local function repaintSettings()
SL.bite.set(1 / CFG.BITE_INTERVAL, true)
SL.warp.set(CFG.WARP_SPEED, true)
paintToggle(SET.robux,CFG.BLOCK_ROBUX,"BLOCK ROBUX: ON","BLOCK ROBUX: OFF")
paintToggle(SET.rebirth,CFG.REBIRTH,"REBIRTH: ON","REBIRTH: OFF")
paintToggle(SET.guard,CFG.GUARD,"GUARD: ON","GUARD: OFF")
paintToggle(SET.claim,CFG.CLAIM,"CLAIM: ON","CLAIM: OFF")
paintToggle(SET.evolve,CFG.EVOLVE,"HATCH: ON","HATCH: OFF")
paintToggle(SET.skill,CFG.SKILLS,"SKILL AUTO: ON","SKILL AUTO: OFF")
paintToggle(SET.roam,CFG.ROAM,"ROAM: ON","ROAM: OFF")
paintMode()
end
SET.robux.MouseButton1Click:Connect(function()
CFG.BLOCK_ROBUX = not CFG.BLOCK_ROBUX
paintToggle(SET.robux,CFG.BLOCK_ROBUX,"BLOCK ROBUX: ON","BLOCK ROBUX: OFF")
pcall(function()
local g = getgenv and getgenv()
if g then g.TAYJAY_BLOCK_ROBUX = CFG.BLOCK_ROBUX and true or false end
end)
if not CFG.BLOCK_ROBUX then ST.claimPauseUntil = 0 end
end)
SET.evolve.MouseButton1Click:Connect(function()
CFG.EVOLVE=not CFG.EVOLVE
paintToggle(SET.evolve,CFG.EVOLVE,"HATCH: ON","HATCH: OFF")
end)
SET.skill.MouseButton1Click:Connect(function()
CFG.SKILLS=not CFG.SKILLS
paintToggle(SET.skill,CFG.SKILLS,"SKILL AUTO: ON","SKILL AUTO: OFF")
end)
SET.roam.MouseButton1Click:Connect(function()
CFG.ROAM=not CFG.ROAM
paintToggle(SET.roam,CFG.ROAM,"ROAM: ON","ROAM: OFF")
end)
SET.mode.MouseButton1Click:Connect(function()
CFG.MONSTER_MODE = (CFG.MONSTER_MODE == "value") and "near" or "value"
ST.mt = nil
ST.dirty = true
paintMode()
end)
local function shutdownAll()
if ST.closing then return end
ST.closing = true
pcall(saveState)
combatOn = false
autoAttackOn = false
CFG.GUARD = false; CFG.REBIRTH = false; CFG.CLAIM = false
CFG.EVOLVE = false; CFG.SKILLS = false; CFG.ROAM = false
pcall(function()
local g = getgenv and getgenv()
if g then g.TAYJAY_BLOCK_ROBUX = false end
end)
if ST.guard then pcall(exitSafe, "ปิดสคริป - กลับลงมาจากแท่นหลบภัย", 0) end
ST.guard = false
if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad = nil end
pcall(function() setNoclip(false) end)
pcall(restoreCharacterCollision)
for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
conns = {}
ST.mt = nil
table.clear(ST.hot); table.clear(ST.mBlack)
table.clear(groups.ITEM); table.clear(groups.MONSTER)
table.clear(objectGroup); table.clear(enabled); table.clear(known.ITEM); table.clear(known.MONSTER)
table.clear(itemVisits)
table.clear(pendingAdds); pendingAddHead, pendingAddTail = 1, 0
table.clear(ST.voidBlacklist); table.clear(SAFE.cache); table.clear(ST.buyWindows)
table.clear(ST.badClaim); table.clear(ST.skillList)
ST.biteBtn = nil; ST.biteFound = false; ST.biteLogged = ""; ST.skillLogged = ""
ST.lastTarget = nil; ST.expLabel = nil; ST.spawnPoint = nil
ST.lastSafePos = nil; ST.farmPauseUntil = 0; ST.noclipUserOff = false
ST.lastClaimBtn = nil; ST.claimPauseUntil = 0
ST.inVoid = false; ST.inWater = false
pcall(function()
local g = getgenv and getgenv()
if g and g.TAYJAY_ANT_SHUTDOWN == shutdownAll then g.TAYJAY_ANT_SHUTDOWN = nil end
end)
pcall(function() gui:Destroy() end)
print("[TAYJAY] ปิดสคริปแล้ว - ล้างสถานะ/การเชื่อมต่อเรียบร้อย")
end
ST.closeArmedAt = -1e9
closeBtn.MouseButton1Click:Connect(function()
local now = os.clock()
if now - ST.closeArmedAt < 3 then
shutdownAll()
else
ST.closeArmedAt = now
closeBtn.Text = "แตะอีกครั้ง!"
task.delay(3, function()
if gui.Parent and os.clock() - ST.closeArmedAt >= 2.9 then closeBtn.Text = "ปิดสคริป" end
end)
end
end)
itemTab.MouseButton1Click:Connect(function() setTab("ITEM") end)
monsterTab.MouseButton1Click:Connect(function() setTab("MONSTER") end)
settingsTab.MouseButton1Click:Connect(function() setTab("SET") end)
refresh.MouseButton1Click:Connect(fullScan)
fold.MouseButton1Click:Connect(function()
collapsed = not collapsed
applyLayout()
end)
local DRAG = {}
title.InputBegan:Connect(function(input)
if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
DRAG.on,DRAG.start,DRAG.pos=true,input.Position,frame.Position
input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then DRAG.on=false end end)
end
end)
bind(UIS.InputChanged, function(input)
if DRAG.on and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
local d=input.Position-DRAG.start
frame.Position=UDim2.new(DRAG.pos.X.Scale,DRAG.pos.X.Offset+d.X,DRAG.pos.Y.Scale,DRAG.pos.Y.Offset+d.Y)
end
end)
bind(Workspace.DescendantAdded, queueObject)
bind(Workspace.DescendantRemoving, removeObject)
bind(player.CharacterAdded, function()
ST.guard=false; ST.resumeReadyAt=nil; ST.everHealthy=false; ST.hp=1; ST.mt=nil
ST.lastTarget=nil; ST.inVoid=false; ST.inWater=false; ST.groundOK=false
ST.biteBtn=nil; ST.biteLogged=""; ST.skillLogged=""; table.clear(ST.skillList)
if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad=nil end
task.wait(1)
if gui.Parent then render() end
end)
gui.Destroying:Connect(function() shutdownAll() end)
loadState()
repaintSettings()
setTab("ITEM")
task.spawn(function() task.wait(1); fullScan() end)
pcall(function()
local g = getgenv and getgenv()
if g then
g.TAYJAY_ANT_SHUTDOWN = shutdownAll
g.TAYJAY_BLOCK_ROBUX = CFG.BLOCK_ROBUX and true or false
end
end)
print("[TAYJAY ANT EVOLUTION RADAR V25 TABLET-PURE | ไม่มีคีย์บอร์ด/เมาส์ในไฟล์] Loaded | firetouchinterest="..tostring(hasFireTouch))
-- =========================================================
-- CHANGELOG V24 -> V25
-- 1  ลบ tapKey() / SendKeyEvent / BITE_KEY / KEY_FALLBACK ทิ้งทั้งหมด
-- 2  ลบวงวนปล่อยคีย์ใน shutdownAll (Enum.KeyCode หายจากไฟล์)
-- 3  TAP.hard ทัชจริงก่อนเสมอ → บังคับเกมกลับ layout มือถือ
-- 4  TAP.findBite เจาะจง BITE (ตัด HIT) → ไม่กด EvoBar.Hit อีก
-- 5  TAP.skills หาปุ่มสกิลจากกลุ่มรอบ BITE ใช้ได้ทุกร่าง (SHIELD/CHARGE/SNAP/STING)
-- 6  TAP.purchase บล็อกทุกปุ่มใน GUI ชื่อ purchase/robux/premium/shop
-- 7  CLAIM กดเฉพาะปุ่มที่ "มองเห็น" (เลิกกดตัวโคลนใน AntPurchaseFocusPark)
-- 8  CLAIM กรอง "ALL 7" (แพ็กเกจ Robux 199)
-- 9  closeShopWindows ปิดทั้ง ScreenGui ต้องสงสัย + หาปุ่ม X ทุกชั้น
-- 10 rebirthReadyFromUI ลบเงื่อนไข stage="omega" → เทียบหลอดบนทุกร่าง
-- 11 เพิ่ม TAP.point แตะจอว่างดันกลับ tablet เมื่อปุ่มมือถือหาย
-- 12 ลบ CFG.REBIRTH_STAGE / SKILL_RANGE unused / UI mode remnants
-- =========================================================
