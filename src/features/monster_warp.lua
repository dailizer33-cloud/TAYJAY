-- =========================================================
-- 👾 MONSTER WARP (แยกจาก Player WARP)
-- ค้นหา Monster ใน Workspace (แยก NPC ออกเป็นกลุ่มต่างหาก สลับได้ที่ปุ่ม MONSTER / NPC ในแผง)
-- แล้วติดตามเป้าหมายที่ใกล้จุดเริ่มต้นที่สุด
-- ระบบนี้ไม่เปลี่ยน Death Note, Player WARP, WALK หรือคำสั่งเดิมอื่น ๆ
-- =========================================================
-- ห่อด้วย do + pcall (ไม่ใช้ "(function() ... end)()" ที่ขึ้นต้นบรรทัดใหม่ เพราะ Luau มองว่าเป็น
-- Ambiguous syntax และ Lua จะอ่านเป็นการเรียกผลลัพธ์ของ task.spawn(...) ซ้อน → สคริปต์ล้มทั้งไฟล์)
-- pcall ทำให้ถ้า MONSTER พัง ส่วนอื่นของสคริปต์ยังทำงานต่อ และรายงานสาเหตุขึ้นจอ
do
local okMonster, errMonster = pcall(function()


   local monsterPanel = Instance.new("Frame", screenGui)
   monsterPanel.Name = "TayJayMonsterTargetPanel"
   monsterPanel.Size = UDim2.fromOffset(UI_LAYOUT.PanelW, 180)
   monsterPanel.Position = UI_LAYOUT.MonsterTargetPanel
   monsterPanel.BackgroundColor3 = GREEN.dark
   monsterPanel.BackgroundTransparency = 0.03
   local monsterPanelVisible = true -- table visibility is controlled by main TAYJAY menu
   monsterPanel.Visible = monsterPanelVisible
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
   local monsterOrbitOn = true          -- วนรอบเป้าหมายตลอดเวลา (ไม่ยืนนิ่งให้โดนสวน)

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
       b.Size = UDim2.new(1 / 3, -4, 1, 0)
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
   local orbitBtn = makeFilterButton("MonsterOrbitBtn", "🌀 ORBIT", 3)

   local dodgeBtn = Instance.new("TextButton", monsterPanel)
   dodgeBtn.Name = "MonsterDodgeBtn"
   dodgeBtn.Size = UDim2.new(1, -18, 0, 22)
   dodgeBtn.Position = UDim2.fromOffset(9, 75)
   dodgeBtn.BackgroundColor3 = Color3.fromRGB(65, 74, 63)
   dodgeBtn.Text = "🛡 AUTO-DODGE สกิลมอนสเตอร์"
   dodgeBtn.TextColor3 = WHITE_TEXT
   dodgeBtn.Font = Enum.Font.GothamBold
   dodgeBtn.TextSize = 11
   dodgeBtn.AutoButtonColor = true
   dodgeBtn.Active = true
   Instance.new("UICorner", dodgeBtn).CornerRadius = UDim.new(0, 7)

   local claimPlaytimeBtn = Instance.new("TextButton", monsterPanel)
   claimPlaytimeBtn.Name = "ClaimPlaytimeAllBtn"
   claimPlaytimeBtn.Size = UDim2.new(1, -18, 0, 22)
   claimPlaytimeBtn.Position = UDim2.fromOffset(9, 102)
   claimPlaytimeBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 119)
   claimPlaytimeBtn.Text = "🎁 CLAIM PLAYTIME 1-10"
   claimPlaytimeBtn.TextColor3 = WHITE_TEXT
   claimPlaytimeBtn.Font = Enum.Font.GothamBold
   claimPlaytimeBtn.TextSize = 11
   claimPlaytimeBtn.AutoButtonColor = true
   claimPlaytimeBtn.Active = true
   Instance.new("UICorner", claimPlaytimeBtn).CornerRadius = UDim.new(0, 7)

   local claimPlaytimeBusy = false

   local monsterCountLabel = Instance.new("TextLabel", monsterPanel)
   monsterCountLabel.Name = "MonsterFilterCount"
   monsterCountLabel.Size = UDim2.new(1, -18, 0, 14)
   monsterCountLabel.Position = UDim2.fromOffset(9, 128)
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
   monsterInfo.Position = UDim2.fromOffset(9, 145)
   monsterInfo.Size = UDim2.new(1, -18, 0, 30)
   monsterInfo.BackgroundTransparency = 1
   monsterInfo.Text = "ปิดอยู่ • กด MONSTER เพื่อเริ่มค้นหา"
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
       "monster", "mob", "enemy", "boss", "creature", "ant",
       "scorpion", "worm", "bug", "moth", "larva", "mantis",
       "crab", "slime", "dragon", "zombie", "insect", "mothstand", "void moth",
       "voidmoth", "蝎",
       -- แมลงเพิ่มเติม (เกม Bug Evolution): เช่น GiantVoidMosquito, Hornet, Wasp
       "mosquito", "hornet", "wasp", "bee", "centipede", "millipede", "roach", "cockroach",
       "termite", "locust", "cicada", "cricket", "grasshopper", "dragonfly", "caterpillar",
       "tarantula", "leech", "aphid", "firefly", "ladybug", "stinkbug",
       -- คำที่มักใช้เรียกบอส
       "giant", "king", "queen", "elder", "alpha", "titan", "colossal", "overlord", "ancient", "apex", "mega"
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
   local monsterNoclipList = {}
   local monsterUnknownSummary, monsterUnknownPrinted = "", ""
   local monsterEnterAt = 0 -- เวลาที่เข้าสิงเป้าหมายปัจจุบัน
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
   local MONSTER_SCAN_MIN_INTERVAL = 0.45
   local MONSTER_FOLLOW_INTERVAL = 0.06
   local MONSTER_PLATFORM_SIZE = Vector3.new(16, 1, 16)
   local MONSTER_FEET_DROP = 3
   local MONSTER_STUCK_SECONDS = 10   -- HP ไม่เปลี่ยนนานเท่านี้ = ตีไม่เข้า (ของตกแต่ง/อมตะ/เข้าไม่ถึง) → ข้าม
   local MONSTER_BLOCK_SECONDS = 60   -- พักเป้าที่ถูกข้ามไว้นานเท่านี้
   -- วงโคจรรอบมอนสเตอร์ (เปิด/ปิดด้วยปุ่ม ORBIT): ขยับตลอด เป้าหมายจึงเล็ง/ตีโดนยาก
   local MONSTER_ORBIT_RADIUS = 4.5   -- รัศมีวง (studs) ควรอยู่ในระยะโจมตีของเกม
   local MONSTER_ORBIT_SPEED = 2.6    -- ความเร็วเชิงมุม (rad/วินาที)
   local MONSTER_ORBIT_BREATH = 1.2   -- รัศมีแกว่งเข้า-ออก (studs) ให้จังหวะไม่คงที่
   local MONSTER_ORBIT_BOB = 0.8      -- แกว่งขึ้น-ลง (studs)
   local MONSTER_ENTER_SECONDS = 0.6  -- เข้า "สิงร่าง" (อยู่กลางตัวมอนสเตอร์) ก่อน แล้วค่อยขยายวงออกถึงรัศมีเต็มในเวลานี้
   -- AUTO-DODGE: อ่านท่าที่มอนสเตอร์กำลังเล่น (AnimationTrack) ถ้าเป็นท่าโจมตี/สกิล → ลอยหนีขึ้นข้างบนชั่วคราว
   local MONSTER_DODGE_HEIGHT = 45     -- หนีขึ้นสูงจากตัวมอนสเตอร์ (studs)
   local MONSTER_DODGE_MAX_SECONDS = 2.5
   local MONSTER_DODGE_PAD = 0.35      -- อยู่ข้างบนต่ออีกเล็กน้อยหลังท่าจบ
   local DODGE_ANIM_HINTS = {
       "attack", "skill", "slam", "bite", "cast", "strike", "smash", "charge", "spit", "shoot",
       "ability", "special", "blast", "roar", "swipe", "sting", "pounce", "ultimate", "burst", "nova", "beam", "dash"
   }
   local DODGE_IGNORE_HINTS = {
       "idle", "walk", "run", "move", "fly", "hover", "hit", "hurt", "damage", "death", "die",
       "spawn", "stun", "react", "flinch", "emote", "land", "jump", "fall"
   }
   local monsterDodgeOn = true
   local monsterDodgeUntil, monsterDodgeWhy, monsterWasDodging = 0, "", false
   local monsterLastMyHealth = nil
   local learnedDangerAnims = {} -- ชื่อท่า (ตัวพิมพ์เล็ก) → จำนวนครั้งที่โดนตีระหว่างท่านี้

   local function getMonsterRoot(model, humanoid, allowLargest)
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
       -- บอสบางตัวไม่มี Humanoid/PrimaryPart/ชื่อราก: ถ้า "ยืนยันแล้วว่าเป็นมอนสเตอร์" ให้ใช้ชิ้นส่วนที่ใหญ่ที่สุด
       -- (ตัวลำตัว) เป็นราก ส่วนโมเดลที่ยังไม่ยืนยันจะถูกปฏิเสธเหมือนเดิม ไม่วาร์ปไปชิ้นส่วนแมพมั่ว ๆ
       if allowLargest then
           local best, bestVolume = nil, 0
           for _, part in ipairs(model:GetDescendants()) do
               if part:IsA("BasePart") then
                   local size = part.Size
                   local volume = size.X * size.Y * size.Z
                   if volume > bestVolume then best, bestVolume = part, volume end
               end
           end
           return best
       end
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

   -- คำสั้น (<5 ตัวอักษร) ต้องตรงทั้งคำ (หรือเติม s) ส่วนคำยาวยอมให้เป็นส่วนหนึ่งของชื่อ เช่น "Hornet"
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

   -- Generic human NPCs may have no NPC tag/name or interaction prompt.
   local function hasHumanNpcBody(model, humanoid)
       if not humanoid then return false end
       local head = model:FindFirstChild("Head", true)
       local torso = model:FindFirstChild("UpperTorso", true)
           or model:FindFirstChild("Torso", true)
           or model:FindFirstChild("LowerTorso", true)
       local root = model:FindFirstChild("HumanoidRootPart", true) or model.PrimaryPart
       return head ~= nil and torso ~= nil and root ~= nil and root:IsA("BasePart")
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

   -- ชื่อบอสจาก HUD ของเกม (เช่นแถบบอสด้านบนจอ "GIANT VOID MOSQUITO"): ถ้ามีโมเดลใน Workspace ชื่อตรงกัน
   -- (เทียบแบบไม่สนช่องว่าง/ตัวพิมพ์) ถือว่าเป็นบอสแน่นอน แม้โมเดลไม่มี HP/Humanoid
   local keyCache = {}
   local function normalizeKey(text)
       local raw = tostring(text or "")
       local cached = keyCache[raw]
       if cached then return cached end
       local key = string.lower((raw:gsub("[^%w\128-\255]", "")))
       keyCache[raw] = key
       return key
   end
   local currentGuiNames = {}
   local function collectGuiNames()
       local names = {}
       local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
       if not playerGui then return names end
       for _, obj in ipairs(playerGui:GetDescendants()) do
           if obj:IsA("TextLabel") and obj.Visible then
               local text = obj.Text
               if type(text) == "string" and #text >= 6 and #text <= 40 then
                   local gui = obj:FindFirstAncestorWhichIsA("ScreenGui")
                   if gui and gui.Enabled and gui ~= screenGui then
                       local shown, parent = true, obj.Parent
                       while parent and parent ~= gui do
                           if parent:IsA("GuiObject") and not parent.Visible then shown = false break end
                           parent = parent.Parent
                       end
                       if shown then names[normalizeKey(text)] = text end
                   end
               end
           end
       end
       return names
   end

   local function looksAnimated(model)
       return model:FindFirstChildWhichIsA("Animator", true) ~= nil
           or model:FindFirstChildWhichIsA("AnimationController", true) ~= nil
   end

   -- ผลลัพธ์: "Monster" | "NPC" | nil  และ (ตัวที่ 3) true = ไม่มีค่า HP แต่มีหลักฐานว่าเป็นศัตรู
   local function classifyModel(model, humanoid)
       local monsterNamed = hasMonsterNameHint(model.Name)
       local npcNamed = hasNpcNameHint(model.Name)
       local guiBoss = currentGuiNames[normalizeKey(model.Name)] ~= nil
       if isExcludedMonsterName(model.Name) and not npcNamed then return nil end
       if not monsterNamed and not npcNamed and not humanoid and not guiBoss then return nil end
       -- ของตั้งโชว์/พร็อพ/โมเดลในกล้อง ไม่ใช่ทั้ง Monster และ NPC
       if isInDisplayContainer(model) then return nil end

       local strongNpc, npcReason = hasStrongNpcEvidence(model)
       if strongNpc then return "NPC", npcReason end
       -- ชื่อตรงกับแถบบอส/HUD ของเกม → บอสแน่นอน
       if guiBoss then return "Monster", "boss-hud", not hasHealthSource(model, humanoid) end
       if monsterNamed then
           -- ชื่อเข้าข่ายอย่างเดียวไม่พอ: ต้องมี HP จริง, อยู่ในกลุ่ม/แท็กศัตรู, หรือมี Animator (ตัวเป็น ๆ ขยับได้)
           if hasHealthSource(model, humanoid) then return "Monster", "name+hp" end
           if hasMonsterEvidence(model) then return "Monster", "name+container", true end
           if looksAnimated(model) then return "Monster", "name+animator", true end
           return nil
       end
       if humanoid and hasInteractionEvidence(model) then return "NPC", "interaction" end
       if humanoid and not monsterNamed and not hasMonsterEvidence(model) and hasHealthSource(model, humanoid) and hasHumanNpcBody(model, humanoid) then
           return "NPC", "humanoid-rig"
       end
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
       currentGuiNames = collectGuiNames()
       local unknown = {}
       for _, obj in ipairs(workspace:GetDescendants()) do
           if obj:IsA("Model") and obj.Parent and not seen[obj] then
               seen[obj] = true
               if not isPlayerCharacter(obj, playerCharacters) then
                   local humanoid = obj:FindFirstChildOfClass("Humanoid")
                   -- Monster ต้องมีชื่อเข้าข่ายเสมอ (Humanoid อย่างเดียวไม่พอ)
                   -- NPC จัดแยกด้วยชื่อ/โฟลเดอร์/แอตทริบิวต์/แท็ก/ปุ่มคุย
                   local kind, reason, noHealth = classifyModel(obj, humanoid)
                   if not kind and humanoid and hasHealthSource(obj, humanoid) and not isExcludedMonsterName(obj.Name) and not isInDisplayContainer(obj) then
                       table.insert(unknown, { name = obj.Name, maxHp = tonumber(humanoid.MaxHealth) or 0 })
                   end
                   if kind then
                       local root = getMonsterRoot(obj, humanoid, kind == "Monster")
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
       -- โมเดลที่มี HP แต่จัดกลุ่มไม่ได้: โชว์ชื่อไว้ช่วยดูว่าบอสชื่ออะไร (แล้วเพิ่มคำใน MONSTER_NAME_HINTS)
       table.sort(unknown, function(a, b) return a.maxHp > b.maxHp end)
       local names = {}
       for i = 1, math.min(4, #unknown) do names[i] = string.format("%s(%d)", unknown[i].name, math.floor(unknown[i].maxHp)) end
       monsterUnknownSummary = table.concat(names, ", ")
       if monsterUnknownSummary ~= "" and monsterUnknownSummary ~= monsterUnknownPrinted then
           monsterUnknownPrinted = monsterUnknownSummary
           print("[TAYJAY MONSTER] unclassified models with HP: " .. monsterUnknownSummary)
       end
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
       candidate.root = getMonsterRoot(model, humanoid, candidate.kind == "Monster")
       return alive and candidate.root ~= nil
   end

   local function nearestMonster(origin, ignoreModel)
       local best, bestDistance = nil, math.huge
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
       local monsterActive = states.MonsterWarp and isMonster
       local npcActive = states.MonsterWarp and not isMonster
       monsterFilterBtn.Text = monsterActive and "👾 MONSTER: ON" or "👾 MONSTER"
       npcFilterBtn.Text = npcActive and "🧑 NPC: ON" or "🧑 NPC"
       monsterFilterBtn.BackgroundColor3 = monsterActive and GREEN.on or (isMonster and GREEN.off or Color3.fromRGB(65, 74, 63))
       npcFilterBtn.BackgroundColor3 = npcActive and NPC_COLOR or ((not isMonster) and Color3.fromRGB(40, 89, 112) or Color3.fromRGB(65, 74, 63))
       orbitBtn.BackgroundColor3 = monsterOrbitOn and Color3.fromRGB(39, 174, 119) or Color3.fromRGB(65, 74, 63)
       orbitBtn.TextTransparency = monsterOrbitOn and 0 or 0.35
       dodgeBtn.BackgroundColor3 = monsterDodgeOn and Color3.fromRGB(39, 174, 119) or Color3.fromRGB(65, 74, 63)
       dodgeBtn.TextTransparency = monsterDodgeOn and 0 or 0.35
       monsterFilterBtn.TextTransparency = 0
       npcFilterBtn.TextTransparency = 0
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
       monsterPanel.Visible = monsterPanelVisible
       refreshMonsterFilterUI()
       if not on then
           setMonsterPanelStatus("👾 MONSTER: OFF", "ปิดอยู่ • กด MONSTER ในตารางเพื่อเริ่มค้นหา", 0, 1)
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
           if _tjMovementController
               and not _tjMovementController:ClaimPlatform("MONSTER", part) then
               part:Destroy()
               return nil
           end
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
       if _tjMovementController then
           _tjMovementController:ReleasePlatform("MONSTER", old)
       end
       if old and old.Parent then pcall(function() old:Destroy() end) end
   end

   local function getMonsterTracks(target)
       local animator = target.animator
       if not animator or not animator.Parent then
           animator = target.model:FindFirstChildWhichIsA("Animator", true)
           target.animator = animator
       end
       if not animator then return nil end
       local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
       if ok and tracks then return tracks end
       return nil
   end

   -- ท่าไหนอันตราย: ชื่อเข้าข่ายโจมตี/สกิล (และไม่ใช่ท่าเดิน/ยืนนิ่ง/โดนตี) หรือเป็นท่าที่เคยทำให้เราเสียเลือด
   local function detectMonsterAttack(target)
       local tracks = getMonsterTracks(target)
       if not tracks then return false end
       for _, track in ipairs(tracks) do
           local name = tostring(track.Name or "")
           local learned = learnedDangerAnims[string.lower(name)] ~= nil
           local hinted = matchesHint(name, DODGE_ANIM_HINTS) and not matchesHint(name, DODGE_IGNORE_HINTS)
           if learned or hinted then
               local length = tonumber(track.Length) or 1
               local position = tonumber(track.TimePosition) or 0
               return true, name, math.clamp(length - position, 0.2, MONSTER_DODGE_MAX_SECONDS)
           end
       end
       return false
   end

   -- เรียนรู้: ตอนเราเสียเลือด ท่าที่ไม่วนซ้ำและไม่ใช่ท่าธรรมดาที่กำลังเล่นอยู่ ถือว่าอันตราย
   local function learnDanger(target)
       local tracks = getMonsterTracks(target)
       if not tracks then return end
       for _, track in ipairs(tracks) do
           local name = tostring(track.Name or "")
           if not track.Looped and not matchesHint(name, DODGE_IGNORE_HINTS) then
               local key = string.lower(name)
               if learnedDangerAnims[key] == nil then
                   learnedDangerAnims[key] = 0
                   print("[TAYJAY MONSTER] learned dangerous animation: " .. name)
               end
               learnedDangerAnims[key] = learnedDangerAnims[key] + 1
           end
       end
   end

   -- ปิดการชนของตัวละครตัวเองระหว่างติดตาม: ไม่งั้นตัวมอนสเตอร์ดัน/ชนตัวละคร แล้วโดนดึงกลับทุกครั้ง = กระตุก
   local function monsterDisableCollision(character)
       local list = {}
       for _, part in ipairs(character:GetDescendants()) do
           if part:IsA("BasePart") then
               table.insert(list, part)
               if part.CanCollide then
                   monsterCollisionSaved[part] = true
                   part.CanCollide = false
               end
           end
       end
       monsterNoclipList = list
   end

   -- NOCLIP ทุกเฟรมระหว่างล็อกเป้า: Humanoid/ฟิสิกส์เปิดการชนกลับเองระหว่างรอบ 0.12 วิ
   -- จึงต้องปิดซ้ำก่อนฟิสิกส์ทุกสเต็ป ตัวละครจึงทะลุสิ่งกีดขวางระหว่างเข้าหา/ติดอยู่บนมอนสเตอร์
   local function monsterNoclipStep()
       if not states.MonsterWarp or not monsterCurrent then return end
       for _, part in ipairs(monsterNoclipList) do
           if part.Parent and part.CanCollide then part.CanCollide = false end
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
       if not _tjMovementController or not _tjMovementController:IsOwner("MONSTER") then return end
       local target = monsterCurrent
       local targetRoot = target and target.root
       if not targetRoot or not targetRoot.Parent then return end
       local character = LocalPlayer.Character
       if not character or character ~= monsterOwner then return end
       local myRoot = character:FindFirstChild("HumanoidRootPart")
       if not myRoot then return end
       _tjMovementController:SetPositionLock("MONSTER", os.clock() + 0.3) -- บอก Fly ว่าตอนนี้ MONSTER คุมตำแหน่งอยู่
       local destination = targetRoot.CFrame
       local isBoss = target.reason == "boss-hud"
       local orbiting = monsterOrbitOn and monsterFilterMode == "Monster" and not isBoss
       local nowClock = os.clock()
       if monsterLastRoot ~= targetRoot then monsterEnterAt = nowClock end -- เป้าใหม่: เข้าสิงร่างทันที
       local dodging = not isBoss and monsterDodgeOn and monsterFilterMode == "Monster" and nowClock < monsterDodgeUntil
       if dodging then
           monsterWasDodging = true
       elseif monsterWasDodging then
           monsterWasDodging = false
           monsterEnterAt = nowClock -- หนีเสร็จ: กลับเข้าสิงร่างใหม่ แล้วค่อยขยายวง
       end
       if isBoss then
           -- Boss stance: เกาะด้านหลังช่วงท้ายลำตัว ไม่ Orbit และไม่ Dodge
           local tailOffset = math.max(2.5, (targetRoot.Size.Z * 0.5) + 1.25)
           local rearPosition = targetRoot.Position - targetRoot.CFrame.LookVector * tailOffset
           destination = CFrame.lookAt(rearPosition, targetRoot.Position)
       elseif orbiting then
           -- เริ่มจากกลางตัวมอนสเตอร์ (สิงร่าง) แล้วขยายวงโคจรออกอย่างนุ่มนวล
           local grow = math.clamp((nowClock - monsterEnterAt) / MONSTER_ENTER_SECONDS, 0, 1)
           local angle = nowClock * MONSTER_ORBIT_SPEED
           local radius = (MONSTER_ORBIT_RADIUS + math.sin(nowClock * 1.7) * MONSTER_ORBIT_BREATH) * grow
           if radius > 0.15 then
               local center = targetRoot.Position
               local orbitPos = center + Vector3.new(math.cos(angle) * radius, math.sin(nowClock * 3.1) * MONSTER_ORBIT_BOB * grow, math.sin(angle) * radius)
               destination = CFrame.lookAt(orbitPos, center)
           end
       end
       if dodging then
           destination = CFrame.new(targetRoot.Position + Vector3.new(0, MONSTER_DODGE_HEIGHT, 0))
       end
       ResourceManager:RecordWrite("MonsterWarp", "Velocity")
        myRoot.AssemblyLinearVelocity = Vector3.zero
       myRoot.AssemblyAngularVelocity = Vector3.zero
         -- Follow the selected table target directly; no separate approach-distance threshold.
       ResourceManager:RecordWrite("MonsterWarp", "Position")
       myRoot.CFrame = destination
       monsterLastRoot = targetRoot
   end

   stopMonsterWarp = function(returnHome)
       if not states.MonsterWarp and not monsterWarpWasOn then
           if _tjMovementController then
               _tjMovementController:ClearPositionLock("MONSTER")
               _tjMovementController:ReleasePlatform("MONSTER")
               _tjMovementController:Release("MONSTER")
           end
           return
       end
       states.MonsterWarp = false
       monsterCurrent = nil
       monsterLastRoot = nil
       monsterTrackedTarget = nil
       if _tjMovementController then
           _tjMovementController:ClearPositionLock("MONSTER")
       end
       monsterDodgeUntil, monsterWasDodging, monsterLastMyHealth = 0, false, nil
       monsterNoclipList = {}
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
       if _tjMovementController then
           _tjMovementController:Release("MONSTER")
       end
       updateMonsterWarpVisual()
   end

   local monsterResumeLatched = false
   local monsterResumeMode = nil
   local monsterResumeGeneration = 0
   local monsterResumeCancelled = false

   _G.TAYJAY_MONSTER_STOP = function()
       monsterResumeCancelled = true
       monsterResumeLatched = false
       monsterResumeGeneration = monsterResumeGeneration + 1
       stopMonsterWarp(true)
   end

   local function startMonsterWarp()
       if states.MonsterWarp then
           stopMonsterWarp(true)
           return
       end
       if monsterWarpStarting then return end
       monsterWarpStarting = true

       -- Atomically take movement ownership. The previous WARP owner must return
       -- home, disconnect both physics writers and restore collision before this succeeds.
       setMonsterPanelStatus("👾 MONSTER WARP: SWITCHING", "กำลังหยุด WARP และคืนค่า Collision ก่อนเริ่ม...", 0, 1)
       local movementReady = _tjMovementController
           and _tjMovementController:Acquire("MONSTER", function(previous)
               if previous == "PLAYER_WARP" or previous == "CONFLICT"
                   or states.KillAura or states.DNWarp or states.AutoWarp then
                   if type(_G.TAYJAY_WARP_STOP_NOW) ~= "function" then return false end
                   return _G.TAYJAY_WARP_STOP_NOW(true) == true
               end
               return true
           end)
       if not movementReady then
           monsterWarpStarting = false
           setMonsterPanelStatus("👾 MONSTER WARP: WAIT", "ยังยึดสิทธิ์ WARP อยู่ • ไม่เริ่มซ้อนระบบ", 0, 1)
           return
       end

       local character = LocalPlayer.Character
       local root = character and character:FindFirstChild("HumanoidRootPart")
       local humanoid = character and character:FindFirstChildOfClass("Humanoid")
       if not character or not root or not humanoid or humanoid.Health <= 0 then
           monsterWarpStarting = false
           if _tjMovementController then _tjMovementController:Release("MONSTER") end
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
   local function toggleMonsterMode(mode)
       if states.MonsterWarp then
           if monsterFilterMode == mode then
               stopMonsterWarp(true)
           else
               setMonsterFilter(mode)
           end
       else
           setMonsterFilter(mode)
           startMonsterWarp()
       end
   end
   trackConnection(monsterFilterBtn.Activated:Connect(function()
       monsterResumeCancelled = true
       monsterResumeLatched = false
       monsterResumeGeneration = monsterResumeGeneration + 1
       toggleMonsterMode("Monster")
   end))
   trackConnection(npcFilterBtn.Activated:Connect(function()
       monsterResumeCancelled = true
       monsterResumeLatched = false
       monsterResumeGeneration = monsterResumeGeneration + 1
       toggleMonsterMode("NPC")
   end))
   trackConnection(dodgeBtn.Activated:Connect(function()
       monsterDodgeOn = not monsterDodgeOn
       monsterDodgeUntil = 0
       refreshMonsterFilterUI()
   end))

   -- Manual one-tap claim only. No timer or automatic background claim loop.
   trackConnection(claimPlaytimeBtn.Activated:Connect(function()
       if claimPlaytimeBusy then return end
       claimPlaytimeBusy = true
       claimPlaytimeBtn.Active = false
       claimPlaytimeBtn.AutoButtonColor = false
       claimPlaytimeBtn.Text = "CLAIMING 1-10..."

       task.spawn(function()
           local remote
           local foundRemote = pcall(function()
               local folder = ReplicatedStorage:WaitForChild("AntRemotes", 5)
               remote = folder and folder:WaitForChild("ClaimPlaytime", 5)
           end)

           local claimed, dnaTotal, failed = 0, 0, 0
           if foundRemote and remote and remote:IsA("RemoteFunction") then
               for rewardIndex = 1, 10 do
                   local callOK, result = pcall(function()
                       return remote:InvokeServer(rewardIndex)
                   end)
                   if callOK and type(result) == "table" and result.ok == true then
                       claimed = claimed + 1
                       local reward = type(result.reward) == "table" and result.reward or {}
                       dnaTotal = dnaTotal + (tonumber(reward.dna) or 0)
                   else
                       failed = failed + 1
                   end
                   task.wait(0.15)
               end
           else
               failed = 10
           end

           claimPlaytimeBtn.Text = string.format("CLAIM DONE %d/10", claimed)
           claimPlaytimeBtn.BackgroundColor3 = claimed > 0
               and Color3.fromRGB(39, 174, 119) or Color3.fromRGB(190, 90, 65)
           monsterInfo.Text = string.format(
               "Claim สำเร็จ %d/10 | DNA +%d | ไม่สำเร็จ/ยังไม่พร้อม %d",
               claimed, dnaTotal, failed
           )
           claimPlaytimeBtn.Active = true
           claimPlaytimeBtn.AutoButtonColor = true
           claimPlaytimeBusy = false
       end)
   end))
   trackConnection(orbitBtn.Activated:Connect(function()
       monsterOrbitOn = not monsterOrbitOn
       monsterLastRoot = nil -- ให้วางตำแหน่งใหม่ทันที (กลับไปติดบนเป้าเมื่อปิดวง)
       refreshMonsterFilterUI()
   end))

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

   -- Resume Monster Warp after evolve/rebirth without taking movement from another warp.
   trackConnection(LocalPlayer.CharacterRemoving:Connect(function()
       monsterResumeCancelled = false
       monsterResumeLatched = states.MonsterWarp == true
       monsterResumeMode = monsterResumeLatched and monsterFilterMode or nil
       monsterResumeGeneration = monsterResumeGeneration + 1
   end))
   trackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
       if not monsterResumeLatched or monsterResumeCancelled then return end
       local myGeneration = monsterResumeGeneration
       task.spawn(function()
           local root = char:WaitForChild("HumanoidRootPart", 15)
           local humanoid = char:WaitForChild("Humanoid", 15)
           if not root or not humanoid then
               if monsterResumeGeneration == myGeneration then monsterResumeLatched = false end
               return
           end
           task.wait(1.5)
           for attempt = 1, 8 do
               if monsterResumeCancelled or _G.TAYJAY_STOPPED
                   or monsterResumeGeneration ~= myGeneration
                   or not monsterResumeLatched then return end
               if states.MonsterWarp then
                   monsterResumeLatched = false
                   return
               end
               local otherWarpActive = states.KillAura or states.DNWarp or states.AutoWarp
               local movementOwner = _tjMovementController and _tjMovementController.Owner
               local transitioning = _tjMovementController and _tjMovementController.Transition
               if not otherWarpActive and not transitioning
                   and (movementOwner == nil or movementOwner == "MONSTER") then
                   if monsterResumeMode and monsterFilterMode ~= monsterResumeMode then
                       pcall(setMonsterFilter, monsterResumeMode)
                   end
                   pcall(startMonsterWarp)
                   if states.MonsterWarp then
                       monsterResumeLatched = false
                       return
                   end
               end
               if attempt < 8 then task.wait(1) end
           end
           if monsterResumeGeneration == myGeneration then monsterResumeLatched = false end
       end)
   end))

   trackConnection(RunService.Heartbeat:Connect(monsterGlueStep))
   trackConnection(RunService.Stepped:Connect(monsterNoclipStep))
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
                   if (monsterScanDirty or (now - monsterLastScan) >= 1.0)
                       and (now - monsterLastScan) >= MONSTER_SCAN_MIN_INTERVAL then
                       local count = scanMonsterModels()
                       refreshMonsterFilterUI()
                       if count == 0 then
                           setMonsterPanelStatus("👾 MONSTER WARP: SEARCHING", "ยังไม่พบ Monster • ระบบจะค้นหาอีกเมื่อมีโมเดลใหม่"
                                   .. (monsterUnknownSummary ~= "" and ("\nไม่รู้จัก: " .. monsterUnknownSummary) or ""), 0, 1)
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
                                   monsterNextSelectAt = now + 0.25
                               end
                           end
                       elseif now >= monsterNextSelectAt then
                           local origin = monsterHome and monsterHome.Position or myRoot.Position
                           target = nearestMonster(origin, nil)
                           monsterCurrent = target
                           monsterNextSelectAt = now + 0.3
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
                           elseif target.reason ~= "boss-hud" and now - target.hpChangedAt >= MONSTER_STUCK_SECONDS then
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
                           if target.reason ~= "boss-hud" and monsterFilterMode == "Monster" and monsterDodgeOn then
                               local myHpNow = myHumanoid.Health
                               if monsterLastMyHealth and myHpNow < monsterLastMyHealth - 0.5 then
                                   learnDanger(target)
                                   monsterDodgeUntil = math.max(monsterDodgeUntil, now + 0.8)
                                   monsterDodgeWhy = "HIT"
                               end
                               monsterLastMyHealth = myHpNow
                               local isAttack, attackName, remaining = detectMonsterAttack(target)
                               if isAttack then
                                   monsterDodgeUntil = math.max(monsterDodgeUntil, now + remaining + MONSTER_DODGE_PAD)
                                   monsterDodgeWhy = attackName
                               end
                           end
                           local stateWord = "POSSESS"
                           if target.reason == "boss-hud" then stateWord = "BOSS REAR" end
                            if target.reason ~= "boss-hud" and monsterOrbitOn and monsterFilterMode == "Monster" then stateWord = "ORBIT" end
                           if target.reason ~= "boss-hud" and monsterDodgeOn and monsterFilterMode == "Monster" and now < monsterDodgeUntil then
                               stateWord = "DODGE " .. tostring(monsterDodgeWhy)
                           end
                           setMonsterPanelStatus(
                               "👾 MONSTER: " .. tostring(target.name),
                               string.format("HP %d / %d  •  %s", math.floor(hp), math.floor(maxHp), stateWord) .. notice,
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
                                   .. ((now < monsterNoticeUntil) and ("\n⚠ " .. monsterNoticeText)
                                       or (monsterUnknownSummary ~= "" and ("\nไม่รู้จัก: " .. monsterUnknownSummary) or "")), 0, 1)
                       end
                   end
               end
           end
       end
       if states.MonsterWarp then stopMonsterWarp(false) end
   end)

   _G.TAYJAY_MONSTER_PANEL_SET_VISIBLE = function(value)
       monsterPanelVisible = value == true
       monsterPanel.Visible = monsterPanelVisible
       return monsterPanelVisible
   end
   _G.TAYJAY_MONSTER_PANEL_GET_VISIBLE = function() return monsterPanelVisible end
   updateMonsterWarpVisual()
end)
if not okMonster then
   pcall(function() warn("[TAYJAY MONSTER] initialization failed: " .. tostring(errMonster)) end)
   pcall(function()
       if _G.TAYJAY_DIAGNOSTIC then _G.TAYJAY_DIAGNOSTIC("ERROR", "MONSTER: " .. tostring(errMonster)) end
   end)
end
end

