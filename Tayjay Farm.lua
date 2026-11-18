--=========================================================
-- TAYJAY ANT EVOLUTION | RADAR V26.2 (DELTA TABLET FIXED)
-- Fix: <40 Top-Level Locals (Fixes Luau 200-Local Compile Limit)
-- Fix: Pure Executor Signals (No VIM / No Namecall Hook)
-- Fix: Safe ViewportSize, Stepped Noclip, CFrame Anti-Fall, Touch Drag
--=========================================================
print("[TAYJAY V26.2] เริ่มโหลดสคริปต์...")
if not game:IsLoaded() then game.Loaded:Wait() end

local okRun, errRun = xpcall(function()
	local Players    = game:GetService("Players")
	local Workspace  = game:GetService("Workspace")
	local CoreGui    = game:GetService("CoreGui")
	local UIS        = game:GetService("UserInputService")
	local HS         = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local player     = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local RNG        = Random.new()
	local _tjFarmEnv = _G
	pcall(function()
		if type(getgenv) == "function" then
			local shared = getgenv()
			if type(shared) == "table" then _tjFarmEnv = shared end
		end
	end)
	local TJ = _tjFarmEnv.TJ
	if type(TJ) ~= "table" then TJ = {}; _tjFarmEnv.TJ = TJ end
	TJ.Farm = TJ.Farm or {}


	--=========================================================
	-- CONFIG & STATE
	--=========================================================
	local CFG = {
		GUARD=true, HP_LOW=0.35, HP_RESUME=0.80, THREAT_RADIUS=90, THREAT_WAIT_MAX=45,
		NO_REGEN_TIMEOUT=35, GUARD_COOLDOWN=60, SAFE_HEIGHT=350, CAUTION_HP=0.60, CAUTION_RADIUS=50,
		HP_TEXT_PATH="",
		REBIRTH=true, REBIRTH_POLL=0.30, REBIRTH_STEP_DELAY=1.0,
		EVOLVE=true, EVOLVE_COOLDOWN=2, EVOLVE_GUI_WORD="action",
		CLAIM=true, CLAIM_POLL=3, CLAIM_RETRY=20,
		WARP_SPEED=0.85, MONSTER_MODE="value", MONSTER_TIMEOUT=8, MONSTER_BLACKLIST=10,
		BITE_INTERVAL=0.14, SKILLS=true, SKILL_RANGE=90, SKILL_NEED_ENEMY=false,
		SKILL_Q_INTERVAL=7, SKILL_E_INTERVAL=9, SKILL_CLUSTER_RADIUS=210, SKILL_CLUSTER_DX=150,
		BLOCK_ROBUX=true, PURCHASE_POLL=1.0, CLAIM_PAUSE_AFTER_PROMPT=20,
		ROAM=true, ROAM_AFTER=1.0, ROAM_INTERVAL=1.6,
		-- P1 PERFORMANCE
		UI_INDEX_TTL=0.55, RAY_BUDGET=40, RENDER_TTL=1.2, SCAN_BATCH=90, SCAN_YIELD=240,
		-- P2 HUMANIZE
		HUMANIZE=true, TAP_JITTER=0.30, TAP_HOLD_MIN=0.035, TAP_HOLD_MAX=0.075,
		DELAY_JITTER=0.22, WARP_OFFSET=1.1, MICRO_PAUSE=0.015,
		MOVE_MODE="warp", GLIDE_SPEED=110, GLIDE_TIMEOUT=6, GLIDE_ARRIVE=1.8,
		-- P3 FEATURES
		QUEST=true, QUEST_OVERRIDE=true, QUEST_POLL=2.0,
		AVOID_PLAYERS=true, AVOID_RADIUS=70, AVOID_HARD_RADIUS=30, AVOID_FOLLOW_SEC=12,
		BAG=true, BAG_FULL_RATIO=0.96, BAG_POLL=2.0, SELL_TIMEOUT=25,
		-- SAFETY
		AUTO_COLLECT_BUFFS=true, EXTRA_BUFF_WORDS={},
		MAP_LIMIT=0, VOID_LEVEL=-250, VOID_DROP=260, SAFE_MAX_DROP=220,
		SAFE_TTL_OK=25, SAFE_TTL_BAD=45, SAFE_CHECKS_PER_SEC=45,
		ORB_BLACKLIST_TIME=90, EXP_CHECK=false, EXP_FAIL_LIMIT=5,
		AUTO_NOCLIP=true, STATUS_POLL=0.25, RECALL_COOLDOWN=2.5,
		SAVE_FILE="TayJay_AntFarm_V26.json",
		SAVE_FLAGS={"REBIRTH","GUARD","CLAIM","EVOLVE","SKILLS","ROAM","BLOCK_ROBUX",
			"HUMANIZE","QUEST","AVOID_PLAYERS","BAG"},
	}

	local ST = {
		hp=1, everHealthy=false, hpLabel=nil, hpScanAt=-1e9,
		threats={}, guard=false, fleeFrom=nil, fleeAt=0, pad=nil,
		lastRise=0, lastHp=1, resumeReadyAt=nil, cooldownUntil=0,
		note="", noteUntil=0, touchHits=0, touchMiss=0,
		rb=nil, rbScanAt=-1e9, rbTryAt=-1e9, rbLogAt=-1e9, rbOpenAt=-1e9, rbBlockedUntil=0,
		rbLoggedFor="", rbBCount=0, rbBStart=0, rbDbgAt=-1e9, rbReadyPrev=false, rbRowLogged=false,
		evoAt=-1e9, evoClicks=0,
		mt=nil, mBlack=setmetatable({},{__mode="k"}), hot={}, idleSince=nil, roamAt=-1e9, origin=nil,
		skillQAt=-1e9, skillEAt=-1e9, dirty=false, closing=false, mCheckAt=0,
		spawnPoint=nil, inVoid=false, inWater=false,
		voidBlacklist=setmetatable({},{__mode="k"}),
		lastSafePos=nil, lastSafeTime=0, statusAt=0, groundCheckAt=0, groundOK=false,
		recallAt=-1e9, recallCount=0, recallWindow=0, farmPauseUntil=0, lastTarget=nil,
		buyWindows=setmetatable({},{__mode="k"}), buyScanAt=-1e9,
		expLabel=nil, expLabelAt=-1e9, noclipUserOff=false,
		biteBtn=nil, biteBtnAt=-1e9, biteFound=false, biteLogged="",
		skillList={}, skillScanAt=-1e9, skillLogged="",
		lastClaimBtn=nil, lastClaimAt=-1e9, badClaim=setmetatable({},{__mode="k"}),
		claimPauseUntil=0, promptHits=0,
		currentAction="IDLE", lastGroupCount=0, scanRunning=false, renderAt=-1e9, renderQueued=false,
		visibleKeys={}, shownAction=nil, lastStatusAt=0, itemStreak=0, lastWarpAt=0,
		closeArmedAt=-1e9,
		quest=nil, questAt=-1e9, questSig="",
		followName=nil, followSince=0, relocateUntil=0,
		bagMode=false, bagUntil=0, bagRatio=0, sellPoint=nil, sellScanAt=-1e9, sellClicks=0,
		combatOn=false, autoAttackOn=false, selected="ITEM", collapsed=false,
	}

	-- Namespaces to keep Luau register count low
	local F = {}
	local NC = {
		on=false, char=nil, snap={}, safeCF=nil, busy=false,
		descConn=nil, stepConn=nil,
		ignored={LeftFoot=true,RightFoot=true,LeftLeg=true,RightLeg=true,LeftLowerLeg=true,RightLowerLeg=true},
		params=RaycastParams.new(),
	}
	NC.params.FilterType = Enum.RaycastFilterType.Exclude

	local UI = {
		at=-1e9, labels={}, buttons={}, buyRoots=setmetatable({},{__mode="k"}),
		guis={}, nodes=0, suspect={},
	}
	local TAP = {
		events={"Activated","MouseButton1Click","TouchTap","MouseButton1Down"}
	}
	local RADAR = {
		groups={ITEM={},MONSTER={}},
		objectGroup={},
		enabled={},
		known={ITEM={},MONSTER={}},
		itemVisits=setmetatable({},{__mode="k"}),
		pendingAdds={}, pendHead=1, pendTail=0,
		pendSet=setmetatable({},{__mode="k"}),
		rowPool={}, headPool={},
		touchPartCache=setmetatable({},{__mode="k"}),
		hasFireTouch=(typeof(firetouchinterest)=="function"),
	}
	local SAFE = {
		cache=setmetatable({},{__mode="k"}), budget=0, budgetAt=0, params=RaycastParams.new()
	}
	SAFE.params.FilterType = Enum.RaycastFilterType.Exclude

	local K = {
		ITEM_DWELL=0, MONSTER_DWELL=0.1, IDLE_DELAY=0.08, TOUCH_TRIES=2, TOUCH_COOLDOWN=0.12,
		WARP_TRIES=4, WARP_COOLDOWN=0.15/CFG.WARP_SPEED, ITEM_SKIP_SECONDS=2, ITEM_STREAK_LIMIT=120,
		MOVE_COOLDOWN=0.04/CFG.WARP_SPEED, ITEM_NEAR_DISTANCE=2.5, MONSTER_NEAR_DISTANCE=5,
	}
	local GL = {att=nil,lv=nil,goal=nil,kind=nil,active=false,started=0,lastPos=nil,lastProgress=0}
	local MOVE = {}
	-- Canonical Farm state namespace; local names remain aliases for legacy logic.
	TJ.Farm.CFG = CFG
	TJ.Farm.ST = ST
	TJ.Farm.F = F
	TJ.Farm.NC = NC
	TJ.Farm.UI = UI
	TJ.Farm.TAP = TAP
	TJ.Farm.RADAR = RADAR
	TJ.Farm.SAFE = SAFE
	TJ.Farm.K = K
	TJ.Farm.GL = GL
	TJ.Farm.MOVE = MOVE

	-- Shutdown previous instance if running
	pcall(function()
		local g = getgenv and getgenv()
		if g and g.TAYJAY_ANT_SHUTDOWN then g.TAYJAY_ANT_SHUTDOWN() end
	end)

	local GUI_NAME = "TayJay_BugEvolution_RadarV26"
	pcall(function()
		local container = (gethui and gethui()) or CoreGui
		local old = container and container:FindFirstChild(GUI_NAME)
		if old then old:Destroy() end
	end)

	--=========================================================
	-- HELPERS
	--=========================================================
	function F.make(class, props, parent)
		local o = Instance.new(class)
		for k,v in pairs(props) do o[k]=v end
		o.Parent = parent
		return o
	end
	function F.style(o, stroke, radius)
		F.make("UICorner",{CornerRadius=UDim.new(0,radius or 12)},o)
		if stroke then F.make("UIStroke",{Color=stroke,Thickness=2},o) end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name=GUI_NAME; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=100000
	local parented = pcall(function()
		local h = gethui and gethui()
		if h then gui.Parent = h else gui.Parent = CoreGui end
	end)
	if not parented or not gui.Parent then
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	local conns = {}
	function F.bind(signal, fn)
		local c = signal:Connect(fn)
		conns[#conns+1] = c
		return c
	end
	function F.makeDraggable(handle, targetObj)
		local dragOn, dragStart, startPos = false, nil, nil
		handle.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
				dragOn = true
				dragStart = input.Position
				startPos = targetObj.Position
				input.Changed:Connect(function()
					if input.UserInputState==Enum.UserInputState.End then dragOn = false end
				end)
			end
		end)
		F.bind(UIS.InputChanged, function(input)
			if dragOn and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
				local d = input.Position - dragStart
				targetObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end
	function F.setNote(text, sec) ST.note=text; ST.noteUntil=os.clock()+(sec or 4) end
	function F.jitter(base, p)
		if not CFG.HUMANIZE then return base end
		return base * (1 + (RNG:NextNumber()-0.5)*2*(p or CFG.DELAY_JITTER))
	end
	function F.pct(v) return math.floor(v*100+0.5) end
	function F.getRoot()
		local c = player.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	--=========================================================
	-- THEME / GUI SHELL
	--=========================================================
	local FONT = Enum.Font.GothamBold
	local TH = {
		bg=Color3.fromRGB(255,248,229), stroke=Color3.fromRGB(255,190,60),
		head=Color3.fromRGB(70,185,255), headDark=Color3.fromRGB(40,140,230),
		text=Color3.fromRGB(70,55,110), sub=Color3.fromRGB(125,110,160),
		on=Color3.fromRGB(70,205,110), off=Color3.fromRGB(255,140,160),
		btnBlue=Color3.fromRGB(90,160,255), green=Color3.fromRGB(70,205,110), danger=Color3.fromRGB(255,95,105),
		tabItem=Color3.fromRGB(255,170,40), tabMonster=Color3.fromRGB(170,110,255),
		tabSet=Color3.fromRGB(70,185,255), tabOff=Color3.fromRGB(238,228,205),
		row=Color3.fromRGB(255,255,255), rowDim=Color3.fromRGB(246,240,228),
		buff=Color3.fromRGB(255,222,90), rare=Color3.fromRGB(255,190,215), plain=Color3.fromRGB(205,220,255),
		quest=Color3.fromRGB(120,235,200),
	}
	local FW, FH = 400, 540
	do
		local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
		local vx = (vp and vp.X and vp.X > 100) and vp.X or 1000
		local vy = (vp and vp.Y and vp.Y > 100) and vp.Y or 700
		FW = math.min(400, vx - 24)
		FH = math.min(560, vy - 24)
	end
	function F.mkBtn(parent,text,color,size,pos,textSize)
		local b = F.make("TextButton",{Size=size,Position=pos or UDim2.new(0,0,0,0),BackgroundColor3=color,
			Text=text,TextColor3=Color3.new(1,1,1),TextSize=textSize or 15,Font=FONT,BorderSizePixel=0},parent)
		F.style(b,nil,12); return b
	end

	local W = {}
	W.frame = F.make("Frame",{Size=UDim2.fromOffset(FW,FH),Position=UDim2.new(1,-(FW+12),0,12),
		BackgroundColor3=TH.bg,BorderSizePixel=0},gui)
	F.style(W.frame,TH.stroke,18)
	W.head = F.make("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=TH.head,BorderSizePixel=0},W.frame)
	F.style(W.head,nil,18)
	W.title = F.make("TextLabel",{Size=UDim2.new(1,-214,1,0),Position=UDim2.fromOffset(14,0),
		BackgroundTransparency=1,Text="🐜 ANT FARM V26.2",TextColor3=Color3.new(1,1,1),TextSize=19,
		Font=FONT,TextXAlignment=Enum.TextXAlignment.Left,Active=true},W.head)
	F.makeDraggable(W.title, W.frame)

	W.fold = F.mkBtn(W.head,"−",TH.headDark,UDim.fromOffset(38,34),UDim2.new(1,-204,0,7),22)
	W.refresh = F.mkBtn(W.head,"สแกน",TH.green,UDim.fromOffset(54,34),UDim2.new(1,-160,0,7),14)
	W.closeBtn = F.mkBtn(W.head,"ปิดสคริป",TH.danger,UDim.fromOffset(92,34),UDim2.new(1,-102,0,7),14)
	W.status = F.make("TextLabel",{Size=UDim2.new(1,-20,0,20),Position=UDim2.fromOffset(10,52),
		BackgroundTransparency=1,Text="เริ่มสแกน...",TextColor3=TH.sub,TextSize=13,Font=FONT,
		TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},W.frame)
	W.questLine = F.make("TextLabel",{Size=UDim2.new(1,-20,0,18),Position=UDim2.fromOffset(10,72),
		BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(30,150,120),TextSize=12,Font=FONT,
		TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},W.frame)
	W.quick = F.make("Frame",{Size=UDim2.new(1,-20,0,42),Position=UDim2.fromOffset(10,94),BackgroundTransparency=1},W.frame)
	W.combat = F.mkBtn(W.quick,"MONSTER WARP: OFF",TH.off,UDim2.new(.5,-4,1,0),UDim2.new(0,0,0,0),14)
	W.abilityToggle = F.mkBtn(W.quick,"BITE AUTO: OFF",TH.off,UDim2.new(.5,-4,1,0),UDim2.new(.5,4,0,0),14)
	W.tabs = F.make("Frame",{Size=UDim2.new(1,-20,0,40),Position=UDim2.fromOffset(10,142),BackgroundTransparency=1},W.frame)
	W.itemTab = F.mkBtn(W.tabs,"ITEM",TH.tabItem,UDim2.new(1/3,-4,1,0),UDim2.new(0,0,0,0),15)
	W.monsterTab = F.mkBtn(W.tabs,"MONSTER",TH.tabOff,UDim2.new(1/3,-4,1,0),UDim2.new(1/3,2,0,0),15)
	W.settingsTab = F.mkBtn(W.tabs,"SETTINGS",TH.tabOff,UDim2.new(1/3,-4,1,0),UDim2.new(2/3,4,0,0),15)
	W.content = F.make("Frame",{Size=UDim2.new(1,-20,1,-198),Position=UDim2.fromOffset(10,188),BackgroundTransparency=1},W.frame)
	W.listPanel = F.make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},W.content)
	W.searchBox = F.make("TextBox",{Size=UDim2.new(1,-100,0,36),BackgroundColor3=Color3.new(1,1,1),
		BorderSizePixel=0,Text="",PlaceholderText="🔍 ค้นหาชื่อ...",PlaceholderColor3=TH.sub,TextColor3=TH.text,
		TextSize=15,Font=FONT,ClearTextOnFocus=false},W.listPanel)
	F.style(W.searchBox,TH.stroke,12)
	W.allBtn = F.mkBtn(W.listPanel,"ALL ON",TH.btnBlue,UDim.fromOffset(92,36),UDim2.new(1,-92,0,0),14)
	W.list = F.make("ScrollingFrame",{Size=UDim2.new(1,0,1,-44),Position=UDim2.fromOffset(0,44),
		BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.35,BorderSizePixel=0,ScrollBarThickness=6,
		CanvasSize=UDim2.new(0,0,0,0)},W.listPanel)
	F.style(W.list,nil,12)
	W.layout = F.make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},W.list)
	F.make("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},W.list)
	W.settingsPanel = F.make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
		BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0),Visible=false},W.content)

	local SET, SL = {}, {}
	do
		local sList = F.make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},W.settingsPanel)
		sList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			W.settingsPanel.CanvasSize=UDim2.new(0,0,0,sList.AbsoluteContentSize.Y+10)
		end)
		local sliderBox = F.make("Frame",{Size=UDim2.new(1,-8,0,306),BackgroundTransparency=1,LayoutOrder=1},W.settingsPanel)
		F.make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sliderBox)

		local function mkSlider(order,ttl,minV,maxV,step,fmt)
			local S={min=minV,max=maxV,step=step,value=minV}
			local box=F.make("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=TH.row,BorderSizePixel=0,LayoutOrder=order},sliderBox)
			F.style(box,TH.plain,12)
			local label=F.make("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.fromOffset(10,3),
				BackgroundTransparency=1,Text=ttl,TextColor3=TH.text,TextSize=14,Font=FONT,
				TextXAlignment=Enum.TextXAlignment.Left},box)
			local minus=F.mkBtn(box,"−",TH.btnBlue,UDim.fromOffset(34,32),UDim2.new(0,8,0,28),22)
			local plus=F.mkBtn(box,"+",TH.btnBlue,UDim.fromOffset(34,32),UDim2.new(1,-42,0,28),22)
			local track=F.make("Frame",{Size=UDim2.new(1,-100,0,12),Position=UDim2.new(0,50,0,38),
				BackgroundColor3=TH.tabOff,BorderSizePixel=0},box)
			F.style(track,nil,6)
			local fill=F.make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=TH.on,BorderSizePixel=0},track)
			F.style(fill,nil,6)
			local knob=F.make("Frame",{Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(.5,.5),
				Position=UDim2.new(0,0,.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},track)
			F.style(knob,TH.stroke,13)
			local hit=F.make("TextButton",{Size=UDim2.new(1,-100,0,36),Position=UDim2.new(0,50,0,26),
				BackgroundTransparency=1,Text="",AutoButtonColor=false},box)
			function S.set(v,silent)
				v=math.max(minV,math.min(maxV,v))
				if not silent then
					v=math.floor(v/step+0.5)*step
					v=math.max(minV,math.min(maxV,v))
				end
				S.value=v
				local f=(v-minV)/(maxV-minV)
				fill.Size=UDim2.new(f,0,1,0); knob.Position=UDim2.new(f,0,.5,0)
				label.Text=ttl.."    "..fmt(v)
				if not silent and S.onChange then S.onChange(v) end
			end
			function S.setFraction(f) S.set(minV+math.max(0,math.min(1,f))*(maxV-minV)) end
			local dragging=false
			local function fromInput(input)
				local w=hit.AbsoluteSize.X
				if not w or w<=0 then return end
				S.setFraction((input.Position.X-hit.AbsolutePosition.X)/w)
			end
			hit.InputBegan:Connect(function(input)
				if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
					dragging=true; W.settingsPanel.ScrollingEnabled=false; fromInput(input)
					input.Changed:Connect(function()
						if input.UserInputState==Enum.UserInputState.End then
							dragging=false; W.settingsPanel.ScrollingEnabled=true
						end
					end)
				end
			end)
			F.bind(UIS.InputChanged,function(input)
				if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
					fromInput(input)
				end
			end)
			minus.MouseButton1Click:Connect(function() S.set(S.value-step) end)
			plus.MouseButton1Click:Connect(function() S.set(S.value+step) end)
			S.set(minV,true)
			return S
		end

		SL.bite  = mkSlider(1,"⚔ ความไวการกัด",2,15,0.5,function(v) return string.format("%.1f ครั้ง/วิ",v) end)
		SL.warp  = mkSlider(2,"🌀 ความไววาร์ป",0.3,1.5,0.05,function(v) return string.format("x%.2f",v) end)
		SL.glide = mkSlider(3,"🛼 ความไวเคลื่อนที่",40,220,10,function(v) return string.format("%d studs/วิ",v) end)
		SL.jit   = mkSlider(4,"🎲 ความสุ่ม (กันตรวจจับ)",0,60,5,function(v) return string.format("%d%%",v) end)
		F.make("TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,
			Text="⚠ เร็วเกินเสี่ยงโดนเตะ • เปิด HUMANIZE เพื่อสุ่มให้เหมือนคน",
			TextColor3=TH.sub,TextSize=12,Font=FONT,TextWrapped=true,LayoutOrder=5},sliderBox)

		local gridFrame=F.make("Frame",{Size=UDim2.new(1,-8,0,400),BackgroundTransparency=1,LayoutOrder=2},W.settingsPanel)
		W.sGrid=F.make("UIGridLayout",{CellSize=UDim2.new(.5,-4,0,50),CellPadding=UDim2.fromOffset(8,8),
			SortOrder=Enum.SortOrder.LayoutOrder},gridFrame)
		SET.grid=gridFrame
	end
	local function mkSetting(order,text,color)
		local b=F.mkBtn(SET.grid,text,color,UDim2.new(.5,-4,0,50),nil,13)
		b.LayoutOrder=order; return b
	end
	SET.noclip  = mkSetting(1,"NOCLIP: OFF",TH.off)
	SET.robux   = mkSetting(2,"BLOCK ROBUX: ON",TH.on)
	SET.rebirth = mkSetting(3,"REBIRTH: ON",TH.on)
	SET.guard   = mkSetting(4,"GUARD: ON",TH.on)
	SET.claim   = mkSetting(5,"CLAIM: ON",TH.on)
	SET.evolve  = mkSetting(6,"HATCH: ON",TH.on)
	SET.skill   = mkSetting(7,"SKILL AUTO: ON",TH.on)
	SET.roam    = mkSetting(8,"ROAM: ON",TH.on)
	SET.mode    = mkSetting(9,"ตีมอน: ค่าสูงก่อน",TH.btnBlue)
	SET.move    = mkSetting(10,"MOVE: WARP",TH.btnBlue)
	SET.human   = mkSetting(11,"HUMANIZE: ON",TH.on)
	SET.quest   = mkSetting(12,"QUEST: ON",TH.on)
	SET.avoid   = mkSetting(13,"AVOID PLAYER: ON",TH.on)
	SET.bag     = mkSetting(14,"BAG MANAGER: ON",TH.on)
	SET.sell    = mkSetting(15,"📍 ตั้งจุดขาย",TH.btnBlue)

	W.miniAtk = F.make("TextButton",{Name="TayJayMiniAttack",Size=UDim2.fromOffset(66,66),
		Position=UDim2.new(1,-84,0.55,0),BackgroundColor3=TH.off,Text="⚔\nBITE",TextColor3=Color3.new(1,1,1),
		TextSize=14,Font=FONT,BorderSizePixel=0,Active=true},gui)
	F.make("UICorner",{CornerRadius=UDim.new(1,0)},W.miniAtk)
	F.make("UIStroke",{Color=Color3.new(1,1,1),Thickness=3},W.miniAtk)
	F.makeDraggable(W.miniAtk, W.miniAtk)

	function F.paintToggle(button,on,onText,offText)
		button.Text = on and onText or offText
		button.BackgroundColor3 = on and TH.on or TH.off
		ST.dirty=true
	end

	--=========================================================
	-- NOCLIP (STEPPED) + ANTI FALL
	--=========================================================
	function NC.remember(part)
		if not part or not part:IsA("BasePart") or NC.ignored[part.Name] then return end
		if NC.snap[part]==nil then NC.snap[part]=part.CanCollide end
		if part.CanCollide then part.CanCollide=false end
	end
	function NC.restore()
		if NC.stepConn then NC.stepConn:Disconnect(); NC.stepConn=nil end
		if NC.descConn then NC.descConn:Disconnect(); NC.descConn=nil end
		for part,orig in pairs(NC.snap) do
			if part and part.Parent then pcall(function() part.CanCollide=orig end) end
		end
		table.clear(NC.snap)
	end
	function NC.apply()
		local ch=player.Character
		if not ch then return end
		if NC.char~=ch then
			NC.restore(); NC.char=ch; NC.snap={}
			for _,o in ipairs(ch:GetDescendants()) do NC.remember(o) end
			NC.descConn=ch.DescendantAdded:Connect(function(o) if NC.on then NC.remember(o) end end)
			NC.stepConn=RunService.Stepped:Connect(function()
				if not NC.on or not ch.Parent then return end
				for _,o in ipairs(ch:GetDescendants()) do
					if o:IsA("BasePart") and not NC.ignored[o.Name] and o.CanCollide then
						o.CanCollide=false
					end
				end
			end)
		end
	end
	function NC.set(value)
		NC.on=value
		if value then
			local root=F.getRoot()
			local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and hum then
				NC.params.FilterDescendantsInstances={player.Character}
				local floor=Workspace:Raycast(root.Position,Vector3.new(0,-18,0),NC.params)
				if hum.FloorMaterial~=Enum.Material.Air and floor then
					NC.safeCF=root.CFrame
				elseif floor and (root.Position-floor.Position).Magnitude<=9 then
					NC.safeCF=CFrame.new(root.Position,root.Position+root.CFrame.LookVector)
				end
			end
			NC.apply()
			SET.noclip.Text="NOCLIP: ON"; SET.noclip.BackgroundColor3=TH.on
		else
			NC.restore(); NC.char=nil; NC.busy=false
			SET.noclip.Text="NOCLIP: OFF"; SET.noclip.BackgroundColor3=TH.off
		end
	end

	--=========================================================
	-- P1: UI INDEX
	--=========================================================
	function F.buyName(nm)
		local s=string.gsub(string.lower(nm),"[^%a]","")
		return s:find("purchase",1,true) or s:find("buyitem",1,true) or s:find("robux",1,true)
			or s:find("premium",1,true) or s:find("robloxplus",1,true) or s:find("freetrial",1,true)
			or s=="shop" or s=="store"
	end
	function F.buyText(t)
		return t:find("BUY ITEM",1,true) or t:find("ROBUX",1,true) or t:find("R$",1,true)
			or t:find("◎",1,true) or t:find("ROBLOX PLUS",1,true) or t:find("GET FREE TRIAL",1,true)
			or t:find("BUY NOW",1,true)
	end
	function UI.build()
		UI.labels={}; UI.buttons={}; UI.suspect={}; UI.guis={}
		UI.buyRoots=setmetatable({},{__mode="k"})
		UI.at=os.clock()
		local pg=player:FindFirstChildOfClass("PlayerGui")
		if not pg then return end
		local stack={pg,true,false,false,false,false,nil,nil}
		local top=8
		local count=0
		while top>0 do
			local aBtn=stack[top]; local sg=stack[top-1]; local bag=stack[top-2]
			local qst=stack[top-3]; local rb=stack[top-4]; local buy=stack[top-5]
			local shown=stack[top-6]; local o=stack[top-7]
			top=top-8
			for _,c in ipairs(o:GetChildren()) do
				if c~=gui then
					local isGO=c:IsA("GuiObject")
					local isLC=c:IsA("LayerCollector")
					if isGO or isLC then
						local s=shown
						if isGO then s = s and c.Visible end
						if isLC then s = s and c.Enabled end
						local nm=string.lower(c.Name)
						local b = buy or (F.buyName(nm) and true or false)
						local r = rb or (nm:find("rebirth",1,true)~=nil)
						local q = qst or (nm:find("quest",1,true)~=nil) or (nm:find("mission",1,true)~=nil) or (nm:find("task",1,true)~=nil)
						local g = bag or (nm:find("bag",1,true)~=nil) or (nm:find("inventory",1,true)~=nil)
							or (nm:find("storage",1,true)~=nil) or (nm:find("backpack",1,true)~=nil)
						local cs=sg
						if c:IsA("ScreenGui") then cs=c; UI.guis[#UI.guis+1]=c end
						local cb=aBtn
						local raw=""
						if c:IsA("TextLabel") or c:IsA("TextButton") then raw=c.Text or "" end
						local up = raw~="" and string.upper(raw) or ""
						if c:IsA("GuiButton") then
							local ap,as=c.AbsolutePosition,c.AbsoluteSize
							local e={o=c,name=string.upper(c.Name),text=up,shown=s,buy=b,rb=r,quest=q,
								sg=cs,sgn=cs and string.lower(cs.Name) or "",
								pos=ap+as/2,size=as,area=as.X*as.Y}
							UI.buttons[#UI.buttons+1]=e
							cb=e
						end
						if up~="" then
							local ap,as=c.AbsolutePosition,c.AbsoluteSize
							UI.labels[#UI.labels+1]={o=c,raw=raw,text=up,y=ap.Y+as.Y/2,shown=s,buy=b,
								rb=r,quest=q,bag=g,sg=cs}
							if cb then cb.text=cb.text.."  "..up end
							if s and F.buyText(up) then UI.suspect[#UI.suspect+1]=c end
						end
						count=count+1
						top=top+8
						stack[top-7]=c; stack[top-6]=s; stack[top-5]=b; stack[top-4]=r
						stack[top-3]=q; stack[top-2]=g; stack[top-1]=cs; stack[top]=cb
					end
				end
			end
		end
		UI.nodes=count
		local cam=Workspace.CurrentCamera
		local vp=cam and cam.ViewportSize or Vector2.new(1280,800)
		local maxArea=vp.X*vp.Y*0.7
		for _,o in ipairs(UI.suspect) do
			local w=o
			for _=1,5 do
				if w.Parent and w.Parent:IsA("Frame") then w=w.Parent else break end
			end
			if w:IsA("Frame") then
				local sz=w.AbsoluteSize; local area=sz.X*sz.Y
				if area>=18000 and area<=maxArea then UI.buyRoots[w]=true end
			end
		end
		for _,B in ipairs(UI.buttons) do
			if not B.buy then
				if F.buyText(B.text) then B.buy=true
				else
					local p=B.o.Parent
					for _=1,14 do
						if not p then break end
						if UI.buyRoots[p] then B.buy=true; break end
						p=p.Parent
					end
				end
			end
		end
		for _,L in ipairs(UI.labels) do
			if not L.buy then
				local p=L.o.Parent
				for _=1,14 do
					if not p then break end
					if UI.buyRoots[p] then L.buy=true; break end
					p=p.Parent
				end
			end
		end
	end
	function UI.index()
		if os.clock()-UI.at >= CFG.UI_INDEX_TTL then UI.build() end
		return UI
	end
	function F.liveShown(o)
		while o do
			if o:IsA("GuiObject") and not o.Visible then return false end
			if o:IsA("LayerCollector") and not o.Enabled then return false end
			o=o.Parent
		end
		return true
	end

	--=========================================================
	-- P2: EXECUTOR SIGNAL CLICK
	--=========================================================
	function TAP.purchase(o)
		local p=o
		while p do
			if ST.buyWindows[p] or UI.buyRoots[p] then return true end
			if (p:IsA("GuiObject") or p:IsA("LayerCollector")) and F.buyName(p.Name) then return true end
			p=p.Parent
		end
		return false
	end
	function TAP.signals(btn,names)
		local haveGC=(typeof(getconnections)=="function")
		local haveFS=(typeof(firesignal)=="function")
		if not (haveGC or haveFS) then return false end
		local any=false
		for _,name in ipairs(names) do
			local okSig,sig=pcall(function() return btn[name] end)
			if okSig and sig then
				if haveGC then
					local ok,cs=pcall(getconnections,sig)
					if ok and type(cs)=="table" and #cs>0 then
						for _,c in ipairs(cs) do
							if pcall(function() c:Fire() end) then any=true end
						end
					end
				end
				if not any and haveFS then
					if pcall(firesignal,sig) then any=true end
				end
			end
		end
		return any
	end
	function TAP.hard(btn)
		if not (btn and btn.Parent) then return false end
		if TAP.purchase(btn) then return false end
		local fired=TAP.signals(btn,TAP.events)
		if pcall(function() btn:Activate() end) then fired=true end
		return fired
	end
	function F.clickGui(btn)
		if not btn or not btn.Parent then return false end
		if TAP.purchase(btn) then return false end
		return TAP.hard(btn)
	end
	function TAP.findBite()
		UI.index()
		local best,bestScore=nil,0
		for _,B in ipairs(UI.buttons) do
			local o=B.o
			if B.shown and not B.buy and o.Parent then
				local score=0
				if B.name=="BITE" or B.text=="BITE" then score=100
				elseif B.name:find("BITE",1,true) then score=70
				elseif B.text:find("BITE",1,true) then score=45 end
				if score>0 then
					score=score+math.min(20,B.area/900)
					if score>bestScore then best,bestScore=o,score end
				end
			end
		end
		return best
	end
	function TAP.skills()
		local bite=ST.biteBtn
		if not (bite and bite.Parent and F.liveShown(bite)) then return {} end
		local sg=bite:FindFirstAncestorOfClass("ScreenGui")
		if not sg then return {} end
		UI.index()
		local bc=bite.AbsolutePosition+bite.AbsoluteSize/2
		local out={}
		for _,B in ipairs(UI.buttons) do
			local o=B.o
			if B.sg==sg and o~=bite and B.shown and not B.buy and B.size.X>10 and B.size.Y>10 then
				local lbl=B.name.."  "..B.text
				local skip=lbl:find("RUN",1,true) or lbl:find("SPRINT",1,true) or lbl:find("FLY",1,true)
					or lbl:find("JUMP",1,true) or lbl:find("MENU",1,true) or lbl:find("BITE",1,true)
				if not skip and B.pos.Y<bc.Y-8
					and math.abs(B.pos.X-bc.X)<=CFG.SKILL_CLUSTER_DX
					and (B.pos-bc).Magnitude<=CFG.SKILL_CLUSTER_RADIUS then
					out[#out+1]={btn=o,x=B.pos.X,y=B.pos.Y}
				end
			end
		end
		table.sort(out,function(a,b)
			if math.abs(a.y-b.y)>12 then return a.y<b.y end
			return a.x<b.x
		end)
		local res={}
		for i,e in ipairs(out) do res[i]=e.btn end
		return res
	end
	function F.pressBite()
		local now=os.clock()
		local b=ST.biteBtn
		if not (b and b.Parent and F.liveShown(b)) then
			b=nil
			if now-ST.biteBtnAt>=1.2 then
				ST.biteBtnAt=now
				b=TAP.findBite(); ST.biteBtn=b
				if b and ST.biteLogged~=b:GetFullName() then
					ST.biteLogged=b:GetFullName()
					print("[TAYJAY] เจอปุ่มกัด: "..ST.biteLogged)
				end
			end
		end
		ST.biteFound=(b~=nil)
		if b then return TAP.hard(b) end
		return false
	end
	function F.pressSkill(i)
		local now=os.clock()
		local lst=ST.skillList
		local b=lst and lst[i]
		if not (b and b.Parent and F.liveShown(b)) or now-ST.skillScanAt>2.5 then
			ST.skillScanAt=now
			lst=TAP.skills(); ST.skillList=lst; b=lst[i]
			local sig=(lst[1] and lst[1].Name or "-").." / "..(lst[2] and lst[2].Name or "-")
			if sig~=ST.skillLogged then
				ST.skillLogged=sig
				print("[TAYJAY] สกิล Q="..(lst[1] and lst[1]:GetFullName() or "-").." | E="..(lst[2] and lst[2]:GetFullName() or "-"))
			end
		end
		if b then return TAP.hard(b) end
		return false
	end

	--=========================================================
	-- CLASSIFY / RADAR
	--=========================================================
	local DICT = {
		itemWords={"item","drop","orb","void","coin","collect","pickup","egg","gem","chest","fruit","food","loot"},
		monsterWords={"monster","mob","enemy","creature","npc","boss","ant","beetle","caterpillar","spider"},
		itemFolders={"items","drops","orbs","collectibles","pickups","loot"},
		partSuffixes={"_legs"," legs","_leg","_body","_head","_wings","_wing","_arm","_tail","_part"},
		baseNameAliases={antennal="ant",antennar="ant",ant_antenna_l="ant",ant_antenna_r="ant"},
		buffWords={"buff","shield","powerup","power_up","power-up","boost","potion","bubble","bless",
			"aura","magnet","haste","rage","heal","invinc","regen"},
		monsterFamilies={
			{"ant",{"ant","ants","antenna","antennae","antennal","antennar"}},
			{"beetle",{"beetle","beetles"}},
			{"caterpillar",{"caterpillar","caterpillars"}},
			{"spider",{"spider","spiders"}},
		},
		monsterFamilyLookup={},
		RAR={tiers={
			{100,{"secret","exclusive","divine","celestial","cosmic","omega"}},
			{90,{"mythic"}},{80,{"legend"}},{70,{"crown","royal"}},
			{60,{"epic","diamond","rainbow","prism"}},{50,{"gold"}},
			{40,{"rare","gem","crystal"}},{35,{"egg","chest"}},
			{30,{"super","mega","giant","large","big"}},{20,{"uncommon"}},
			{10,{"orb","coin","fruit","food"}}},
			overrides={},TOP=70,cache=setmetatable({},{__mode="k"})},
		MON={tiers={
			{100,{"boss","mantis","queen","king","emperor"}},
			{80,{"elite","giant","mega","hornet","scorpion","tarantula"}},
			{60,{"wasp","spider","beetle","centipede"}},
			{40,{"soldier","warrior"}}},
			overrides={},TOP=90,BIG=55,cache=setmetatable({},{__mode="k"})},
		ROW_HEAD={
			ITEM={[0]="🎯 เป้าหมายเควสต์ — ทำก่อน",[1]="⭐ บัฟ — เก็บก่อนเสมอ",
				[2]="💎 หายาก/ใหญ่",[3]="📦 ไอเท็มทั่วไป"},
			MONSTER={[0]="🎯 เป้าหมายเควสต์ — ตีก่อน",[1]="👑 บอส/อีเวนต์",
				[2]="💪 ตัวใหญ่/แข็ง",[3]="🐜 ตัวทั่วไป"},
		},
		questVerbs={COLLECT="ITEM",GATHER="ITEM",EAT="ITEM",FIND="ITEM",PICK="ITEM",HARVEST="ITEM",
			DEFEAT="MONSTER",KILL="MONSTER",HUNT="MONSTER",DESTROY="MONSTER",FIGHT="MONSTER",ATTACK="MONSTER"},
		questStop={THE=1,A=1,AN=1,OF=1,TO=1,AND=1,FOR=1,YOUR=1,ANY=1,WITH=1,FROM=1,IN=1,ON=1,QUEST=1,MISSION=1},
		sellWords={"sell","deposit","storage","hive","nest","bank","dropoff"},
	}
	for _,fam in ipairs(DICT.monsterFamilies) do
		for _,w in ipairs(fam[2]) do DICT.monsterFamilyLookup[w]=fam[1] end
	end

	function F.hasWord(s,words)
		s=string.lower(s or "")
		for _,w in ipairs(words) do if string.find(s,w,1,true) then return true end end
		return false
	end
	function F.baseName(name)
		local n=string.lower(name or "")
		local changed=true
		while changed do
			changed=false
			for _,sfx in ipairs(DICT.partSuffixes) do
				if #n>#sfx and n:sub(-#sfx)==sfx then n=n:sub(1,#n-#sfx); changed=true end
			end
		end
		return DICT.baseNameAliases[n] or n
	end
	function F.nameTokens(name)
		local s=string.gsub(tostring(name or ""),"(%l)(%u)","%1 %2")
		local t={}
		for w in string.gmatch(string.lower(s),"%a+") do t[#t+1]=w end
		return t
	end
	function F.stripId(name)
		local n=string.lower(name or "")
		local original=n
		local prev
		repeat
			prev=n
			n=string.gsub(n,"%s*%(%d+%)$","")
			n=string.gsub(n,"[%s%-%.#]*%d+$","")
		until n==prev or n==""
		n=string.gsub(n,"[%s%-%.#]+$","")
		if n=="" then return original end
		return n
	end
	function F.groupName(obj,cat)
		if cat=="MONSTER" then
			for _,tk in ipairs(F.nameTokens(obj.Name)) do
				local fam=DICT.monsterFamilyLookup[tk]
				if fam then return fam end
			end
		end
		return F.stripId(F.baseName(F.stripId(obj.Name)))
	end
	function F.isBuffName(n) return F.hasWord(n,DICT.buffWords) or F.hasWord(n,CFG.EXTRA_BUFF_WORDS) end
	function F.insideCharacter(obj)
		if obj:IsA("Model") and Players:GetPlayerFromCharacter(obj) then return true end
		local p=obj.Parent
		while p and p~=Workspace do
			if p:IsA("Model") and Players:GetPlayerFromCharacter(p) then return true end
			p=p.Parent
		end
		return false
	end
	function F.isMonster(obj)
		if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
		if F.insideCharacter(obj) then return false end
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return true end
		return F.hasWord(F.baseName(obj.Name),DICT.monsterWords)
	end
	function F.isItem(obj)
		if obj==Workspace.Terrain or F.isMonster(obj) or F.insideCharacter(obj) then return false end
		if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
		if F.hasWord(obj.Name,DICT.itemWords) or F.isBuffName(obj.Name) then return true end
		local p=obj.Parent
		while p and p~=Workspace do
			if F.hasWord(p.Name,DICT.itemFolders) then return true end
			p=p.Parent
		end
		return false
	end
	function F.category(obj)
		if F.isMonster(obj) then return "MONSTER" end
		if F.isItem(obj) then return "ITEM" end
	end
	function F.getPosition(obj)
		if not obj or not obj.Parent then return nil end
		if obj:IsA("BasePart") then return obj.Position end
		if obj:IsA("Model") then
			local ok,cf=pcall(function() return obj:GetPivot() end)
			if ok then return cf.Position end
		end
		local part=obj:FindFirstChildWhichIsA("BasePart",true)
		return part and part.Position or nil
	end
	function F.rarityOf(text)
		local ln=string.lower(tostring(text or ""))
		local best=0
		for _,t in ipairs(DICT.RAR.tiers) do
			if t[1]>best and F.hasWord(ln,t[2]) then best=t[1] end
		end
		return best
	end
	function F.itemScore(obj,g)
		local now=os.clock()
		local c=DICT.RAR.cache[obj]
		if c and now-c.t<5 then return c.v end
		local base=DICT.RAR.overrides[g.name]
		if not base then
			base=F.rarityOf(obj.Name)
			local ok,attr=pcall(function() return obj:GetAttribute("Rarity") end)
			if ok and type(attr)=="string" then base=math.max(base,F.rarityOf(attr)) end
		end
		local size=0
		pcall(function()
			if obj:IsA("Model") then size=obj:GetExtentsSize().Magnitude else size=obj.Size.Magnitude end
		end)
		local v=base+math.min(30,size*2)
		DICT.RAR.cache[obj]={t=now,v=v}
		return v
	end
	function F.monsterScore(obj,g)
		local now=os.clock()
		local c=DICT.MON.cache[obj]
		if c and now-c.t<5 then return c.v end
		local base=DICT.MON.overrides[g.name]
		if not base then
			base=0
			local ln=string.lower(obj.Name or "")
			for _,t in ipairs(DICT.MON.tiers) do
				if t[1]>base and F.hasWord(ln,t[2]) then base=t[1] end
			end
		end
		local size=0
		pcall(function()
			if obj:IsA("Model") then size=obj:GetExtentsSize().Magnitude else size=obj.Size.Magnitude end
		end)
		local hp=0
		pcall(function()
			local hum=obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.MaxHealth>1 then hp=math.min(20,math.log(hum.MaxHealth,10)*4) end
		end)
		local v=base+math.min(30,size*1.5)+hp
		DICT.MON.cache[obj]={t=now,v=v}
		return v
	end
	function F.monsterRank(sc) return (sc>=DICT.MON.TOP) and 1 or ((sc>=DICT.MON.BIG) and 2 or 3) end
	function F.itemRankBucket(obj,g)
		local sc=F.itemScore(obj,g)
		return (g.buff and 1 or ((sc>=DICT.RAR.TOP) and 2 or 3)), math.floor(sc/5)
	end
	function F.monsterRankBucket(obj,g)
		local sc=F.monsterScore(obj,g)
		return F.monsterRank(sc), math.floor(sc/10)
	end
	function F.groupPriority(g)
		local o=g.objects[1]
		if not (o and o.Parent) then return g.buff and 1 or 3,0 end
		local sc=F.itemScore(o,g)
		return (g.buff and 1 or ((sc>=DICT.RAR.TOP) and 2 or 3)),sc
	end
	function F.monsterGroupPriority(g)
		local o=g.objects[1]
		if not (o and o.Parent) then return 3,0 end
		local sc=F.monsterScore(o,g)
		return F.monsterRank(sc),sc
	end

	function RADAR.noteKnown(cat,key,g)
		local k=RADAR.known[cat][key]
		if not k then
			RADAR.known[cat][key]={key=key,name=g.name,buff=g.buff,rank=g.buff and 1 or 3,pscore=0}
			ST.dirty=true
		elseif g.buff and not k.buff then
			k.buff=true; k.rank=1; ST.dirty=true
		end
	end
	function RADAR.addHotspot(pos,kind)
		if not pos then return end
		local hs=ST.hot
		for _,h in ipairs(hs) do
			if (h.pos-pos).Magnitude<25 then h.t=os.clock(); return end
		end
		hs[#hs+1]={pos=pos,kind=kind,t=os.clock(),visits=0,last=-1e9}
		if #hs>60 then table.remove(hs,1) end
	end
	function RADAR.scheduleRender()
		if ST.renderQueued then return end
		ST.renderQueued=true
		task.delay(CFG.RENDER_TTL,function()
			ST.renderQueued=false
			if gui.Parent and F.render then F.render() end
		end)
	end
	function RADAR.addObject(obj)
		if not obj or not obj.Parent or RADAR.objectGroup[obj] then return false end
		local cat=F.category(obj)
		if not cat then return false end
		local p=obj.Parent
		while p and p~=Workspace do
			if p:IsA("Model") and p~=obj then
				local pk=RADAR.objectGroup[p]
				if pk and string.sub(pk,1,#cat+1)==cat.."|" then return false end
				if F.category(p)==cat then return false end
			end
			p=p.Parent
		end
		local key=cat.."|"..F.groupName(obj,cat)
		local g=RADAR.groups[cat][key]
		if not g then
			g={key=key,name=F.groupName(obj,cat),objects={}}
			if cat=="ITEM" and F.isBuffName(obj.Name) then
				g.buff=true
				if CFG.AUTO_COLLECT_BUFFS and RADAR.enabled[key]==nil then RADAR.enabled[key]=true end
			end
			RADAR.groups[cat][key]=g
			RADAR.noteKnown(cat,key,g)
		end
		table.insert(g.objects,obj)
		RADAR.objectGroup[obj]=key
		return true
	end
	function RADAR.removeObject(obj)
		local key=RADAR.objectGroup[obj]
		if not key then return end
		RADAR.objectGroup[obj]=nil
		local hp=F.getPosition(obj)
		if hp then RADAR.addHotspot(hp,string.sub(key,1,8)=="MONSTER|" and "MONSTER" or "ITEM") end
		if ST.mt and ST.mt.obj==obj then ST.mt=nil end
		if ST.lastTarget==obj then ST.lastTarget=nil end
		local vv=RADAR.itemVisits[obj]
		if vv and vv.touches>0 and vv.warps==0 then ST.touchHits=ST.touchHits+1 end
		RADAR.itemVisits[obj]=nil
		for _,cat in ipairs({"ITEM","MONSTER"}) do
			local g=RADAR.groups[cat][key]
			if g then
				for i=#g.objects,1,-1 do if g.objects[i]==obj then table.remove(g.objects,i) end end
				if #g.objects==0 then RADAR.groups[cat][key]=nil end
			end
		end
		RADAR.scheduleRender()
	end
	function RADAR.queueObject(obj)
		if not obj or RADAR.pendSet[obj] then return end
		RADAR.pendSet[obj]=true; RADAR.pendTail=RADAR.pendTail+1; RADAR.pendingAdds[RADAR.pendTail]=obj
	end
	function RADAR.fullScan()
		if ST.scanRunning or not gui.Parent then return end
		ST.scanRunning=true
		local oldText=W.refresh.Text
		W.refresh.Text="สแกน..."
		RADAR.groups.ITEM={}; RADAR.groups.MONSTER={}; RADAR.objectGroup={}
		local ok,err=pcall(function()
			local stack={Workspace}
			local processed=0
			while #stack>0 and gui.Parent do
				local parent=stack[#stack]; stack[#stack]=nil
				for _,obj in ipairs(parent:GetChildren()) do
					if obj and obj.Parent then
						pcall(RADAR.addObject,obj)
						stack[#stack+1]=obj
					end
					processed=processed+1
					if processed%CFG.SCAN_YIELD==0 then task.wait(0.03) end
				end
			end
		end)
		ST.scanRunning=false
		W.refresh.Text=oldText
		if F.render then F.render() end
		if not ok then warn("[TAYJAY V26.2] Scan: "..tostring(err)) end
	end

	--=========================================================
	-- P1: ROW POOLING
	--=========================================================
	function RADAR.getHead(rank)
		local h=RADAR.headPool[rank]
		if not h then
			h=F.make("TextLabel",{Size=UDim2.new(1,-6,0,30),BackgroundTransparency=1,Text="",
				TextColor3=TH.text,TextSize=15,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left},W.list)
			RADAR.headPool[rank]=h
		end
		return h
	end
	function RADAR.getRow(key)
		local r=RADAR.rowPool[key]
		if r and r.frame.Parent then return r end
		local f=F.make("Frame",{Size=UDim2.new(1,-6,0,54),BackgroundColor3=TH.row,BorderSizePixel=0},W.list)
		F.make("UICorner",{CornerRadius=UDim.new(0,12)},f)
		local stroke=F.make("UIStroke",{Color=TH.plain,Thickness=2},f)
		local nameL=F.make("TextLabel",{Size=UDim2.new(1,-96,0,26),Position=UDim2.fromOffset(12,5),
			BackgroundTransparency=1,Text="",TextColor3=TH.text,TextSize=17,Font=FONT,
			TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},f)
		local subL=F.make("TextLabel",{Size=UDim2.new(1,-96,0,18),Position=UDim2.fromOffset(12,31),
			BackgroundTransparency=1,Text="",TextColor3=TH.sub,TextSize=12,Font=FONT,
			TextXAlignment=Enum.TextXAlignment.Left},f)
		local b=F.mkBtn(f,"OFF",TH.off,UDim.fromOffset(74,38),UDim2.new(1,-82,.5,-19),16)
		r={frame=f,nameL=nameL,subL=subL,btn=b,stroke=stroke,key=key}
		b.MouseButton1Click:Connect(function()
			RADAR.enabled[r.key]=not RADAR.enabled[r.key]
			b.Text=RADAR.enabled[r.key] and "ON" or "OFF"
			b.BackgroundColor3=RADAR.enabled[r.key] and TH.on or TH.off
			ST.dirty=true
		end)
		RADAR.rowPool[key]=r
		return r
	end
	function F.prettyName(n) return (string.gsub(n,"^%l",string.upper)) end

	function F.render()
		if ST.selected=="SET" then return end
		ST.renderAt=os.clock()
		local keepPos=W.list.CanvasPosition
		local q=string.lower(W.searchBox.Text or "")
		local arr={}
		for key,k in pairs(RADAR.known[ST.selected]) do
			local g=RADAR.groups[ST.selected][key]
			local live=0
			if g then
				local objs={}
				for _,o in ipairs(g.objects) do if o and o.Parent then objs[#objs+1]=o end end
				g.objects=objs; live=#objs
			end
			if q=="" or string.find(string.lower(k.name),q,1,true) then
				local rank,score=k.rank or 3,k.pscore or 0
				if g and live>0 then
					if ST.selected=="ITEM" then rank,score=F.groupPriority(g) else rank,score=F.monsterGroupPriority(g) end
					if k.rank~=rank then k.rank=rank; ST.dirty=true end
					k.pscore=score
				end
				if CFG.QUEST and ST.quest and F.questMatch and F.questMatch(k.name)
					and ST.quest.kind==ST.selected and not ST.quest.done then rank=0 end
				arr[#arr+1]={key=key,name=k.name,buff=k.buff,count=live,rank=rank,score=score}
			end
		end
		table.sort(arr,function(a,b)
			if a.rank~=b.rank then return a.rank<b.rank end
			if a.score~=b.score then return a.score>b.score end
			if a.name~=b.name then return a.name<b.name end
			return a.key<b.key
		end)
		local used,usedHead={},{}
		local order,lastRank=0,nil
		ST.visibleKeys={}
		for _,e in ipairs(arr) do
			if e.rank~=lastRank then
				lastRank=e.rank; order=order+1
				local h=RADAR.getHead(e.rank)
				h.Text=DICT.ROW_HEAD[ST.selected][e.rank] or ""
				h.LayoutOrder=order; h.Visible=true
				usedHead[e.rank]=true
			end
			order=order+1
			local r=RADAR.getRow(e.key)
			used[e.key]=true
			r.frame.LayoutOrder=order
			r.frame.Visible=true
			r.frame.BackgroundColor3=(e.count>0) and TH.row or TH.rowDim
			r.stroke.Color=(e.rank==0) and TH.quest or ((e.rank==1) and TH.buff or ((e.rank==2) and TH.rare or TH.plain))
			local badge=""
			if e.rank==0 then badge="🎯 "
			elseif ST.selected=="ITEM" then badge=e.buff and "⭐ " or ((e.rank==2) and "💎 " or "")
			else badge=(e.rank==1) and "👑 " or ((e.rank==2) and "💪 " or "") end
			r.nameL.Text=badge..F.prettyName(e.name)
			r.nameL.TextColor3=(e.count>0) and TH.text or TH.sub
			r.subL.Text=(e.count>0) and ("ในแมพตอนนี้ × "..e.count) or "ไม่เจอตอนนี้ (จำไว้ให้แล้ว)"
			r.btn.Text=RADAR.enabled[e.key] and "ON" or "OFF"
			r.btn.BackgroundColor3=RADAR.enabled[e.key] and TH.on or TH.off
			ST.visibleKeys[#ST.visibleKeys+1]=e.key
		end
		for key,r in pairs(RADAR.rowPool) do if not used[key] then r.frame.Visible=false end end
		for rank,h in pairs(RADAR.headPool) do if not usedHead[rank] then h.Visible=false end end
		ST.lastGroupCount=#arr
		local allOn=#arr>0
		for _,e in ipairs(arr) do if not RADAR.enabled[e.key] then allOn=false break end end
		W.allBtn.Text=allOn and "ALL OFF" or "ALL ON"
		task.defer(function() if W.list.Parent then W.list.CanvasPosition=keepPos end end)
	end

	W.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		W.list.CanvasSize=UDim2.new(0,0,0,W.layout.AbsoluteContentSize.Y+10)
	end)
	W.sGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SET.grid.Size=UDim2.new(1,-8,0,W.sGrid.AbsoluteContentSize.Y)
	end)

	function F.applyLayout()
		for _,o in ipairs({W.status,W.questLine,W.quick,W.tabs,W.content}) do o.Visible=not ST.collapsed end
		W.listPanel.Visible=(ST.selected~="SET")
		W.settingsPanel.Visible=(ST.selected=="SET")
		W.frame.Size=ST.collapsed and UDim2.fromOffset(FW,56) or UDim2.fromOffset(FW,FH)
		W.fold.Text=ST.collapsed and "+" or "−"
	end
	function F.setTab(cat)
		ST.selected=cat
		W.itemTab.BackgroundColor3=(cat=="ITEM") and TH.tabItem or TH.tabOff
		W.monsterTab.BackgroundColor3=(cat=="MONSTER") and TH.tabMonster or TH.tabOff
		W.settingsTab.BackgroundColor3=(cat=="SET") and TH.tabSet or TH.tabOff
		W.itemTab.TextColor3=(cat=="ITEM") and Color3.new(1,1,1) or TH.text
		W.monsterTab.TextColor3=(cat=="MONSTER") and Color3.new(1,1,1) or TH.text
		W.settingsTab.TextColor3=(cat=="SET") and Color3.new(1,1,1) or TH.text
		F.applyLayout()
		if cat~="SET" and F.render then F.render() end
	end

	--=========================================================
	-- PARSERS
	--=========================================================
	function F.parseAmount(str)
		local num,suf=string.match(str,"^([%d%.]+)(%a?)$")
		local n=tonumber(num)
		if not n then return nil end
		local mult={K=1e3,M=1e6,B=1e9,T=1e12}
		return n*(mult[suf] or 1)
	end
	function F.parsePair(text)
		local t=string.upper(tostring(text or ""))
		t=string.gsub(t,"<[^>]->","")
		t=string.gsub(t,",","")
		local a,b=string.match(t,"([%d%.]+%u?)%s*/%s*([%d%.]+%u?)")
		if not a then return nil end
		return F.parseAmount(a),F.parseAmount(b)
	end
	function F.pathOf(o) if o and o.Parent then return o:GetFullName() end return "-" end

	--=========================================================
	-- SAFE / RAYCAST BUDGET
	--=========================================================
	function SAFE.filter(extra)
		local l={}
		local ch=player.Character
		if ch then l[#l+1]=ch end
		if extra then l[#l+1]=extra end
		SAFE.params.FilterDescendantsInstances=l
	end
	function SAFE.voidLevel()
		local ref=ST.spawnPoint and ST.spawnPoint.Y or 0
		return math.min(CFG.VOID_LEVEL,ref-CFG.VOID_DROP)
	end
	function SAFE.inVoid(pos) if not pos then return false end return pos.Y<SAFE.voidLevel() end
	function SAFE.outOfBounds(pos)
		if not pos or CFG.MAP_LIMIT<=0 then return false end
		return math.abs(pos.X)>CFG.MAP_LIMIT or math.abs(pos.Z)>CFG.MAP_LIMIT
	end
	function SAFE.water(pos,depth,extra)
		SAFE.filter(extra)
		local hit=Workspace:Raycast(pos+Vector3.new(0,4,0),Vector3.new(0,-(depth+4),0),SAFE.params)
		return hit~=nil and hit.Material==Enum.Material.Water
	end
	function SAFE.raw(pos,extra)
		if not pos then return false end
		if SAFE.inVoid(pos) or SAFE.outOfBounds(pos) then return false end
		SAFE.filter(extra)
		local hit=Workspace:Raycast(pos+Vector3.new(0,6,0),Vector3.new(0,-(CFG.SAFE_MAX_DROP+6),0),SAFE.params)
		if not hit then return false end
		if hit.Material==Enum.Material.Water then return false end
		return true
	end
	function SAFE.check(obj,pos,kind)
		if not pos then return false end
		if SAFE.inVoid(pos) or SAFE.outOfBounds(pos) then return false end
		local now=os.clock()
		local c=SAFE.cache[obj]
		if c and now<c.exp and (c.pos-pos).Magnitude<10 then return c.ok end
		if now-SAFE.budgetAt>=1 then SAFE.budgetAt=now; SAFE.budget=CFG.SAFE_CHECKS_PER_SEC end
		if SAFE.budget<=0 then return true end
		SAFE.budget=SAFE.budget-1
		local ok
		if kind=="MONSTER" then ok=not SAFE.water(pos,12,obj) else ok=SAFE.raw(pos,obj) end
		SAFE.cache[obj]={pos=pos,ok=ok,exp=now+(ok and CFG.SAFE_TTL_OK or CFG.SAFE_TTL_BAD)}
		return ok
	end
	function SAFE.blacklist(obj,sec,why)
		if not obj then return end
		ST.voidBlacklist[obj]=os.clock()+(sec or CFG.ORB_BLACKLIST_TIME)
		SAFE.cache[obj]=nil
		if ST.mt and ST.mt.obj==obj then ST.mt=nil end
		if ST.lastTarget==obj then ST.lastTarget=nil end
		if why then F.setNote(why,2) end
	end
	function SAFE.groundAt(x,z,y0)
		SAFE.filter()
		local hit=Workspace:Raycast(Vector3.new(x,y0+300,z),Vector3.new(0,-900,0),SAFE.params)
		if not hit or hit.Material==Enum.Material.Water then return nil end
		return hit.Position+Vector3.new(0,4,0)
	end

	--=========================================================
	-- P2: MOVEMENT (Warp + Glide)
	--=========================================================
	function F.applyWarpSpeed()
		K.WARP_COOLDOWN=0.15/CFG.WARP_SPEED
		K.MOVE_COOLDOWN=0.04/CFG.WARP_SPEED
	end
	function GL.stop()
		if GL.lv then pcall(function() GL.lv:Destroy() end) end
		if GL.att then pcall(function() GL.att:Destroy() end) end
		GL.lv,GL.att,GL.goal,GL.active=nil,nil,nil,false
	end
	function GL.begin(root,pos,kind)
		GL.stop()
		local ok=pcall(function()
			local att=Instance.new("Attachment"); att.Name="TJ_GlideAtt"; att.Parent=root
			local lv=Instance.new("LinearVelocity")
			lv.Name="TJ_Glide"; lv.Attachment0=att; lv.MaxForce=math.huge
			lv.RelativeTo=Enum.ActuatorRelativeTo.World
			lv.VectorVelocity=Vector3.zero; lv.Parent=root
			GL.att,GL.lv=att,lv
		end)
		if not ok then GL.stop(); return false end
		GL.goal,GL.kind,GL.active=pos,kind,true
		GL.started=os.clock(); GL.lastPos=root.Position; GL.lastProgress=GL.started
		return true
	end
	function F.warpTo(root,pos)
		local targetPos = (typeof(pos)=="CFrame") and pos.Position or pos
		local ok=pcall(function()
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=CFrame.new(targetPos)
		end)
		return ok
	end
	function MOVE.offset(kind)
		if not CFG.HUMANIZE or CFG.WARP_OFFSET<=0 then return Vector3.zero end
		local r=CFG.WARP_OFFSET*(kind=="ITEM" and 0.35 or 1)
		return Vector3.new(RNG:NextNumber(-r,r),0,RNG:NextNumber(-r,r))
	end
	function MOVE.to(obj,root,kind)
		local pos=F.getPosition(obj)
		if not pos or not root or not root.Parent then return false end
		pos=pos+MOVE.offset(kind)
		local near=(kind=="ITEM") and K.ITEM_NEAR_DISTANCE or K.MONSTER_NEAR_DISTANCE
		if (pos-root.Position).Magnitude<=near then GL.stop(); return true end
		local now=os.clock()
		if CFG.MOVE_MODE=="glide" and not ST.guard then
			if GL.active and GL.goal and (GL.goal-pos).Magnitude<8 then return false end
			GL.begin(root,pos,kind)
			return false
		end
		if now-ST.lastWarpAt<K.MOVE_COOLDOWN then return true end
		GL.stop()
		local ok=F.warpTo(root,pos)
		if ok then ST.lastWarpAt=now end
		return ok
	end

	F.bind(RunService.Heartbeat, function()
		if not GL.active then return end
		local root=F.getRoot()
		if not root or not GL.goal or ST.closing then GL.stop(); return end
		local d=GL.goal-root.Position
		local dist=d.Magnitude
		if dist<=CFG.GLIDE_ARRIVE then GL.stop(); return end
		local now=os.clock()
		if now-GL.started>CFG.GLIDE_TIMEOUT then
			local goal=GL.goal; GL.stop(); F.warpTo(root,goal); return
		end
		if (root.Position-GL.lastPos).Magnitude>4 then GL.lastPos=root.Position; GL.lastProgress=now end
		if now-GL.lastProgress>1.6 then
			local goal=GL.goal; GL.stop(); F.warpTo(root,goal); return
		end
		pcall(function()
			GL.lv.VectorVelocity=d.Unit*math.min(CFG.GLIDE_SPEED,dist*4+10)
		end)
	end)

	--=========================================================
	-- P3: QUEST / THREAT / HP / RECALL / SHOP / BAG
	--=========================================================
	function F.questMatch(name)
		local q=ST.quest
		if not q or not q.tokens then return false end
		local ln=string.lower(name or "")
		for _,tk in ipairs(q.tokens) do
			if ln:find(tk,1,true) then return true end
		end
		return false
	end
	function F.scanQuest()
		UI.index()
		local best,bestScore=nil,0
		for _,L in ipairs(UI.labels) do
			if L.shown and not L.buy and L.o.Parent then
				local t=L.text
				local verb,rest=t:match("^(%a+)%s+(.+)$")
				local kind=verb and DICT.questVerbs[verb]
				if kind and rest then
					local cur,req=t:match("(%d+)%s*/%s*(%d+)")
					cur,req=tonumber(cur),tonumber(req)
					local tokens={}
					local body=rest:gsub("[%d/%.,]"," ")
					for w in body:gmatch("%a+") do
						if #w>=3 and not DICT.questStop[w] then tokens[#tokens+1]=string.lower(w) end
					end
					if #tokens>0 then
						local done=(cur and req and cur>=req) and true or false
						local score=#tokens*10+(L.quest and 20 or 0)+(done and -100 or 0)
						if score>bestScore then
							bestScore=score
							best={kind=kind,tokens=tokens,cur=cur,req=req,done=done,raw=L.raw,label=L.o}
						end
					end
				end
			end
		end
		ST.quest=best
		local sig=best and (best.kind.."|"..table.concat(best.tokens,",").."|"..tostring(best.cur)) or "-"
		if sig~=ST.questSig then
			ST.questSig=sig
			ST.dirty=true
			if best then print("[TAYJAY] 🎯 Quest: "..best.raw) end
			if F.render and ST.selected~="SET" then RADAR.scheduleRender() end
		end
		if best then
			local prog=(best.cur and best.req) and (" "..best.cur.."/"..best.req) or ""
			W.questLine.Text="🎯 "..best.kind..": "..table.concat(best.tokens," "):upper()..prog..(best.done and " ✅ กด CLAIM" or "")
		else
			W.questLine.Text=""
		end
	end

	function F.refreshThreats()
		local t=ST.threats
		table.clear(t)
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=player then
				local ch=p.Character
				local r=ch and ch:FindFirstChild("HumanoidRootPart")
				if r then t[#t+1]={pos=r.Position,name=p.Name,root=r} end
			end
		end
	end
	function F.nearThreat(pos,radius)
		for _,t in ipairs(ST.threats) do
			if (t.pos-pos).Magnitude<=radius then return true end
		end
		return false
	end
	function F.threatAt(pos)
		if not CFG.AVOID_PLAYERS then return 0 end
		local r=CFG.AVOID_RADIUS
		if os.clock()<ST.relocateUntil then r=r*1.6 end
		local worst=0
		for _,t in ipairs(ST.threats) do
			local d=(t.pos-pos).Magnitude
			if d<CFG.AVOID_HARD_RADIUS then return 2 end
			if d<r then worst=1 end
		end
		return worst
	end
	function F.threatVector(pos)
		local v=Vector3.zero
		local n=0
		for _,t in ipairs(ST.threats) do
			local d=pos-t.pos
			local m=d.Magnitude
			if m>0.1 and m<CFG.THREAT_RADIUS*1.5 then
				v=v+d.Unit*(1-m/(CFG.THREAT_RADIUS*1.5)); n=n+1
			end
		end
		if n==0 then return Vector3.zero end
		return v.Unit
	end
	function F.updateFollow()
		local root=F.getRoot()
		if not root or not CFG.AVOID_PLAYERS then return end
		local nearest,nd=nil,math.huge
		for _,t in ipairs(ST.threats) do
			local d=(t.pos-root.Position).Magnitude
			if d<nd then nearest,nd=t,d end
		end
		local now=os.clock()
		if nearest and nd<CFG.AVOID_RADIUS then
			if ST.followName~=nearest.name then ST.followName=nearest.name; ST.followSince=now end
			if now-ST.followSince>CFG.AVOID_FOLLOW_SEC and now>ST.relocateUntil then
				ST.relocateUntil=now+60
				ST.followSince=now
				ST.mt=nil
				F.setNote("👀 มีคนตามนาน - ย้ายโซนฟาร์ม 60 วิ",4)
				local best,bd=nil,0
				for _,h in ipairs(ST.hot) do
					local d=(h.pos-root.Position).Magnitude
					if d>bd and not F.nearThreat(h.pos,CFG.AVOID_RADIUS) then best,bd=h,d end
				end
				if best then
					GL.stop()
					local p=SAFE.groundAt(best.pos.X,best.pos.Z,best.pos.Y) or (best.pos+Vector3.new(0,4,0))
					F.warpTo(root,p)
					ST.origin=p
				end
			end
		else
			ST.followName=nil
		end
	end

	function F.findHPLabel()
		if CFG.HP_TEXT_PATH~="" then
			local o=player
			for seg in string.gmatch(CFG.HP_TEXT_PATH,"[^%.]+") do
				o=o and o:FindFirstChild(seg)
				if not o then break end
			end
			if o and o:IsA("TextLabel") then return o end
		end
		UI.index()
		local cam=Workspace.CurrentCamera
		local vh=cam and cam.ViewportSize.Y or 1000
		local best,bestY=nil,-1
		for _,L in ipairs(UI.labels) do
			if L.shown and L.o.Parent and L.raw:find("/",1,true) then
				local cur,max=F.parsePair(L.raw)
				if cur and max and max>0 and cur<=max then
					if L.y>vh*0.78 and L.y>bestY then best,bestY=L.o,L.y end
				end
			end
		end
		return best
	end
	function F.readHPRatio()
		local ratio=nil
		local lbl=ST.hpLabel
		if not (lbl and lbl.Parent) then
			ST.hpLabel=nil; lbl=nil
			local now=os.clock()
			if now-ST.hpScanAt>=4 then
				ST.hpScanAt=now
				lbl=F.findHPLabel(); ST.hpLabel=lbl; ST.everHealthy=false
			end
		end
		if lbl then
			local cur,max=F.parsePair(lbl.Text)
			if cur and max and max>0 then ratio=math.clamp(cur/max,0,1) end
		end
		local ch=player.Character
		local hum=ch and ch:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health>0 and hum.MaxHealth>0 then
			local hr=hum.Health/hum.MaxHealth
			ratio=ratio and math.min(ratio,hr) or hr
		end
		return ratio
	end
	function F.readCurrentExp()
		local ls=player:FindFirstChild("leaderstats")
		if ls then
			for _,v in ipairs(ls:GetChildren()) do
				if v:IsA("IntValue") or v:IsA("NumberValue") then
					local n=string.lower(v.Name)
					if n:find("exp",1,true) or n:find("power",1,true) then return tonumber(v.Value) end
				end
			end
		end
		local now=os.clock()
		if not (ST.expLabel and ST.expLabel.Parent) or now-ST.expLabelAt>=15 then
			ST.expLabelAt=now
			UI.index()
			for _,L in ipairs(UI.labels) do
				if L.shown and (L.text:find("POWER",1,true) or L.text:find("EXP",1,true))
					and L.raw:find("/",1,true) and L.y<260 then ST.expLabel=L.o break end
			end
		end
		local lbl=ST.expLabel
		if lbl and lbl.Parent then return (F.parsePair(lbl.Text)) end
		return nil
	end
	function F.expGained(before)
		if not before then return nil end
		local after=F.readCurrentExp()
		if not after or after<before then return nil end
		return after>before
	end

	function F.saveSpawnPoint()
		if ST.spawnPoint then return end
		local root=F.getRoot()
		if not root then return end
		local pos=root.Position
		if SAFE.inVoid(pos) then return end
		SAFE.filter()
		local hit=Workspace:Raycast(pos+Vector3.new(0,6,0),Vector3.new(0,-60,0),SAFE.params)
		if hit and hit.Material~=Enum.Material.Water then
			ST.spawnPoint=pos; ST.lastSafePos=pos; ST.lastSafeTime=os.clock()
		end
	end
	function F.emergencyRecall(reason)
		local now=os.clock()
		if now-ST.recallAt<CFG.RECALL_COOLDOWN then return end
		ST.recallAt=now
		if now-ST.recallWindow>30 then ST.recallWindow=now; ST.recallCount=0 end
		ST.recallCount=ST.recallCount+1
		local root=F.getRoot()
		if not root then return end
		GL.stop()
		local bad=ST.lastTarget
		if bad and bad.Parent then
			local bp=F.getPosition(bad)
			if bp and (bp-root.Position).Magnitude<=60 then SAFE.blacklist(bad,60) end
		end
		ST.lastTarget=nil
		local target=ST.spawnPoint or ST.lastSafePos
		if not target then
			SAFE.filter()
			local hit=Workspace:Raycast(root.Position+Vector3.new(0,20,0),Vector3.new(0,-900,0),SAFE.params)
			if hit and hit.Material~=Enum.Material.Water then target=hit.Position end
		end
		if not target then target=Vector3.new(root.Position.X,SAFE.voidLevel()+150,root.Position.Z) end
		F.warpTo(root,target+Vector3.new(0,5,0))
		ST.mt=nil; ST.inVoid=false; ST.inWater=false
		if ST.recallCount>=5 then
			ST.recallCount=0; ST.farmPauseUntil=now+10
			F.setNote("🚨 วาร์ปฉุกเฉินถี่ - พัก 10 วิ",5)
		else
			F.setNote("🚨 "..reason,3)
		end
	end
	function F.checkCharacterStatus()
		local now=os.clock()
		if now-ST.statusAt<CFG.STATUS_POLL then return end
		ST.statusAt=now
		local ch=player.Character
		local root=F.getRoot()
		local hum=ch and ch:FindFirstChildOfClass("Humanoid")
		if not (root and hum and hum.Health>0) then return end
		F.saveSpawnPoint()
		local pos=root.Position
		if SAFE.inVoid(pos) then ST.inVoid=true; F.emergencyRecall("ตก VOID"); return end
		ST.inVoid=false
		if hum:GetState()==Enum.HumanoidStateType.Swimming or hum.FloorMaterial==Enum.Material.Water then
			ST.inWater=true; F.emergencyRecall("จมน้ำ"); return
		end
		ST.inWater=false
		if hum.FloorMaterial~=Enum.Material.Air and pos.Y>SAFE.voidLevel()+20 then
			if now-ST.groundCheckAt>1.0 then
				ST.groundCheckAt=now
				SAFE.filter()
				local hit=Workspace:Raycast(pos+Vector3.new(0,4,0),Vector3.new(0,-16,0),SAFE.params)
				ST.groundOK=hit~=nil and hit.Material~=Enum.Material.Water
			end
			if ST.groundOK then ST.lastSafePos=pos; ST.lastSafeTime=now end
		end
	end

	function F.findCloseButton(rootObj)
		for _,d in ipairs(rootObj:GetDescendants()) do
			if d:IsA("GuiButton") and F.liveShown(d) then
				local t=string.upper(d.Text or "")
				local nm=string.upper(d.Name)
				if t=="X" or t=="✕" or t=="×" or t=="✖" or t=="NO"
					or t:find("CLOSE",1,true) or nm:find("CLOSE",1,true) or nm:find("BACK",1,true)
					or t:find("CANCEL",1,true) or t:find("ยกเลิก",1,true) or t:find("ปิด",1,true) then
					return d
				end
			end
		end
		return nil
	end
	function F.closeShopWindows()
		local now=os.clock()
		if now-ST.buyScanAt<2 then return false end
		ST.buyScanAt=now
		table.clear(ST.buyWindows)
		UI.index()
		local closed=false
		for _,sg in ipairs(UI.guis) do
			if sg~=gui and F.buyName(sg.Name) then
				ST.buyWindows[sg]=true
				local on=false
				pcall(function() on=sg.Enabled end)
				if on then
					local c=F.findCloseButton(sg)
					if c then F.clickGui(c); closed=true end
				end
			end
		end
		for frameObj in pairs(UI.buyRoots) do
			if frameObj.Parent then
				ST.buyWindows[frameObj]=true
				local c=F.findCloseButton(frameObj)
				if c then F.clickGui(c); closed=true end
			end
		end
		return closed
	end

	function F.findSellPoint()
		if ST.sellPoint then return ST.sellPoint end
		local now=os.clock()
		if now-ST.sellScanAt<30 then return nil end
		ST.sellScanAt=now
		local stack={Workspace}
		local n=0
		while #stack>0 do
			local p=stack[#stack]; stack[#stack]=nil
			for _,o in ipairs(p:GetChildren()) do
				if o:IsA("Model") or o:IsA("BasePart") or o:IsA("Folder") then
					local ln=string.lower(o.Name)
					local hit=false
					for _,w in ipairs(DICT.sellWords) do if ln:find(w,1,true) then hit=true break end end
					if hit and not F.insideCharacter(o) then
						local pos=F.getPosition(o)
						if pos and SAFE.raw(pos,o) then
							ST.sellPoint=pos
							print("[TAYJAY] 📍 เจอจุดขาย: "..o:GetFullName())
							return pos
						end
					end
					stack[#stack+1]=o
				end
				n=n+1
				if n%400==0 then task.wait(0.03) end
				if n>12000 then return nil end
			end
		end
		return nil
	end
	function F.bagStatus()
		UI.index()
		for _,L in ipairs(UI.labels) do
			if L.shown and not L.buy and L.o.Parent then
				local t=L.text
				if t:find("FULL",1,true) and (t:find("BAG",1,true) or t:find("INVENTORY",1,true)
					or t:find("STORAGE",1,true) or t:find("CAPACITY",1,true) or L.bag) then
					return true,1
				end
				if L.bag and L.raw:find("/",1,true) then
					local cur,max=F.parsePair(L.raw)
					if cur and max and max>0 and cur/max>=CFG.BAG_FULL_RATIO then return true,cur/max end
				end
			end
		end
		return false,0
	end
	function F.clickSellButtons()
		UI.index()
		local n=0
		for _,B in ipairs(UI.buttons) do
			if B.shown and not B.buy and B.o.Parent then
				local t=B.text
				if (t:find("SELL ALL",1,true) or t:find("SELL",1,true) or t:find("DEPOSIT",1,true))
					and not t:find("ROBUX",1,true) then
					F.clickGui(B.o); n=n+1
					if n>=2 then break end
				end
			end
		end
		return n
	end

	--=========================================================
	-- TARGETING & TOUCH COLLECT
	--=========================================================
	function F.isAlive(obj)
		if not obj or not obj.Parent then return false end
		if obj:IsA("Model") then
			local hum=obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health<=0 then return false end
		end
		return true
	end
	function F.questBoost(kind,name)
		if not CFG.QUEST then return false end
		local q=ST.quest
		if not q or q.done or q.kind~=kind then return false end
		return F.questMatch(name)
	end
	function F.nearestEnabled(kind,rootPos)
		local best,bestRank,bestBucket,bestDist=nil,math.huge,-math.huge,math.huge
		local now=os.clock()
		local avoid=CFG.GUARD and ST.hp<CFG.CAUTION_HP
		for key,g in pairs(RADAR.groups[kind]) do
			local qBoost=F.questBoost(kind,g.name)
			if RADAR.enabled[key] or (qBoost and CFG.QUEST_OVERRIDE) then
				for _,obj in ipairs(g.objects) do
					local bl=ST.voidBlacklist[obj]
					if obj and obj.Parent and not (bl and now<bl) then
						local rawName=string.lower(obj.Name or "")
						local whole=(kind~="MONSTER") or (F.isAlive(obj) and F.baseName(rawName)==rawName)
						if whole then
							local canVisit=true
							if kind=="ITEM" then
								local v=RADAR.itemVisits[obj]
								if v and (v.skipUntil>now or v.cool>now) then canVisit=false end
							else
								local mb=ST.mBlack[obj]
								if mb and mb>now then canVisit=false end
							end
							if canVisit then
								local pos=F.getPosition(obj)
								if pos and SAFE.check(obj,pos,kind)
									and not (avoid and F.nearThreat(pos,CFG.CAUTION_RADIUS))
									and F.threatAt(pos)<2 then
									local d=(pos-rootPos).Magnitude
									local rank,bucket=1,0
									if kind=="ITEM" then rank,bucket=F.itemRankBucket(obj,g)
									elseif CFG.MONSTER_MODE=="value" then rank,bucket=F.monsterRankBucket(obj,g) end
									if qBoost then rank=0 end
									if CFG.AVOID_PLAYERS and F.threatAt(pos)>0 and not qBoost then rank=rank+0.5 end
									if rank<bestRank or (rank==bestRank and (bucket>bestBucket
										or (bucket==bestBucket and d<bestDist))) then
										best,bestRank,bestBucket,bestDist=obj,rank,bucket,d
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
	function F.monsterTarget(rootPos)
		local now=os.clock()
		local t=ST.mt
		if t then
			local o=t.obj
			local grpKey=o and RADAR.objectGroup[o] or ""
			local gObj=RADAR.groups.MONSTER[grpKey]
			local isQBoost=gObj and F.questBoost("MONSTER",gObj.name) and CFG.QUEST_OVERRIDE
			if not (o and o.Parent and F.isAlive(o)) then ST.mt=nil
			elseif now-t.since>CFG.MONSTER_TIMEOUT then
				ST.mBlack[o]=now+CFG.MONSTER_BLACKLIST; ST.mt=nil
			elseif not RADAR.enabled[grpKey] and not isQBoost then ST.mt=nil
			elseif CFG.MONSTER_MODE=="value" and now-ST.mCheckAt>=1.0 then
				ST.mCheckAt=now
				local best=F.nearestEnabled("MONSTER",rootPos)
				if best and best~=o then
					local g1=RADAR.groups.MONSTER[RADAR.objectGroup[best] or ""]
					local g0=RADAR.groups.MONSTER[grpKey]
					if g1 and g0 and F.monsterRankBucket(best,g1)<F.monsterRankBucket(o,g0) then
						ST.mt={obj=best,since=now}
					end
				end
			end
		end
		if not ST.mt then
			local m=F.nearestEnabled("MONSTER",rootPos)
			if m then ST.mt={obj=m,since=now} end
		end
		return ST.mt and ST.mt.obj or nil
	end
	function F.anyEnabledTarget()
		for key,on in pairs(RADAR.enabled) do
			if on then
				if string.sub(key,1,5)=="ITEM|" then return true end
				if ST.combatOn and string.sub(key,1,8)=="MONSTER|" then return true end
			end
		end
		if CFG.QUEST and ST.quest and not ST.quest.done then return true end
		return false
	end
	function F.pickHotspot(fromPos)
		local best,bestScore=nil,nil
		local now=os.clock()
		for _,h in ipairs(ST.hot) do
			if (h.pos-fromPos).Magnitude>40 and not (CFG.AVOID_PLAYERS and F.nearThreat(h.pos,CFG.AVOID_RADIUS)) then
				local sc=h.visits*1000-math.min(900,now-h.last)
				if not bestScore or sc<bestScore then best,bestScore=h,sc end
			end
		end
		return best
	end
	function F.roamStep(root)
		local now=os.clock()
		if now-ST.roamAt<CFG.ROAM_INTERVAL then return false end
		ST.roamAt=now
		local pos=nil
		local h=F.pickHotspot(root.Position)
		if h then
			h.visits=h.visits+1; h.last=now
			local cand=h.pos+Vector3.new(0,3,0)
			if SAFE.raw(cand) then pos=cand end
		else
			local o=ST.origin or root.Position
			local ang=RNG:NextNumber(0,math.pi*2)
			local r=RNG:NextNumber(80,260)
			pos=SAFE.groundAt(o.X+math.cos(ang)*r,o.Z+math.sin(ang)*r,root.Position.Y)
		end
		if not pos then return false end
		if CFG.MOVE_MODE=="glide" then GL.begin(root,pos,"ROAM")
		else F.warpTo(root,pos) end
		task.spawn(function() pcall(function() player:RequestStreamAroundAsync(pos) end) end)
		return true
	end

	function RADAR.getTouchParts(obj)
		local c=RADAR.touchPartCache[obj]
		if c and c[1] and c[1].Parent then return c end
		local l={}
		if obj:IsA("BasePart") then l[1]=obj
		else
			local first=nil
			for _,d in ipairs(obj:GetDescendants()) do
				if d:IsA("BasePart") then
					first=first or d
					if #l<6 and d:FindFirstChildWhichIsA("TouchTransmitter") then l[#l+1]=d end
				end
			end
			if #l==0 and first then l[1]=first end
		end
		RADAR.touchPartCache[obj]=l
		return l
	end
	function RADAR.touchUseful()
		local n=ST.touchHits+ST.touchMiss
		return n<8 or ST.touchHits/n>=0.25
	end
	function RADAR.fireTouch(obj,root)
		if not RADAR.hasFireTouch or not RADAR.touchUseful() then return false end
		local fired=false
		for _,p in ipairs(RADAR.getTouchParts(obj)) do
			if p.Parent then
				pcall(firetouchinterest,root,p,0)
				pcall(firetouchinterest,root,p,1)
				fired=true
			end
		end
		return fired
	end
	function RADAR.visitItem(obj,root)
		local now=os.clock()
		local v=RADAR.itemVisits[obj]
		if not v then v={touches=0,warps=0,skipUntil=0,cool=0,failCount=0}; RADAR.itemVisits[obj]=v end
		if v.skipUntil>now or v.cool>now then return false end
		local bl=ST.voidBlacklist[obj]
		if bl and now<bl then return false end
		local pos=F.getPosition(obj)
		local g=RADAR.groups.ITEM[RADAR.objectGroup[obj] or ""]
		local isBuff=(g and g.buff) or false
		local function snap()
			if CFG.EXP_CHECK and not isBuff then return F.readCurrentExp() end
			return nil
		end
		local function expWatch(before)
			if not before then return end
			task.delay(1.2,function()
				if not obj.Parent then return end
				local gained=F.expGained(before)
				if gained==true then v.failCount=0
				elseif gained==false then
					v.failCount=v.failCount+1
					if v.failCount>=CFG.EXP_FAIL_LIMIT then
						v.failCount=0
						SAFE.blacklist(obj,CFG.ORB_BLACKLIST_TIME,"⚠️ Orb ไม่ได้ EXP - พักชั่วคราว")
					end
				end
			end)
		end
		if GL.active then return false end
		if v.touches<K.TOUCH_TRIES and RADAR.fireTouch(obj,root) then
			v.touches=v.touches+1
			v.cool=now+F.jitter(K.TOUCH_COOLDOWN)
			expWatch(snap())
			return true
		end
		v.warps=v.warps+1
		if v.warps==1 and v.touches>0 then ST.touchMiss=ST.touchMiss+1 end
		if v.warps>K.WARP_TRIES then
			v.warps=0; v.touches=0; v.skipUntil=now+K.ITEM_SKIP_SECONDS
			return false
		end
		if pos and not SAFE.check(obj,pos,"ITEM") then
			SAFE.blacklist(obj,CFG.ORB_BLACKLIST_TIME,"⚠️ Orb นอกแมพ/ในน้ำ - ข้าม")
			v.skipUntil=now+30
			return false
		end
		local before=snap()
		local ok=MOVE.to(obj,root,"ITEM")
		if ok then
			RADAR.fireTouch(obj,root)
			v.cool=now+F.jitter(K.WARP_COOLDOWN)
			expWatch(before)
		end
		return ok
	end
	function F.nextEnabledTarget(rootPos)
		if ST.combatOn and ST.itemStreak>=K.ITEM_STREAK_LIMIT then
			local m=F.monsterTarget(rootPos)
			if m then ST.itemStreak=0; return "MONSTER",m end
		end
		local item=F.nearestEnabled("ITEM",rootPos)
		if item then ST.itemStreak=ST.itemStreak+1; return "ITEM",item end
		if ST.combatOn then
			local m=F.monsterTarget(rootPos)
			if m then ST.itemStreak=0; return "MONSTER",m end
		end
		return nil,nil
	end

	--=========================================================
	-- GUARD
	--=========================================================
	function F.showAction()
		local now=os.clock()
		if ST.shownAction~=ST.currentAction and now-ST.lastStatusAt>=0.12 then
			ST.shownAction=ST.currentAction
			ST.lastStatusAt=now
			W.status.Text="HP "..F.pct(ST.hp).."% • กัด: "..(ST.biteFound and "✓" or "✗")
				.." • "..(CFG.MOVE_MODE=="glide" and "🛼" or "🌀").." "..ST.currentAction
		end
	end
	function F.enterSafe(root)
		GL.stop()
		ST.guard=true
		ST.fleeFrom=root.Position
		ST.fleeAt=os.clock()
		ST.lastRise=ST.fleeAt
		ST.lastHp=ST.hp
		ST.resumeReadyAt=nil
		NC.set(false)
		local away=F.threatVector(root.Position)
		local padPos=ST.fleeFrom+Vector3.new(0,CFG.SAFE_HEIGHT,0)+away*60
		if not (ST.pad and ST.pad.Parent) then
			local pad=Instance.new("Part")
			pad.Name="SafeZonePad_TJ"; pad.Anchored=true; pad.CanCollide=true
			pad.Size=Vector3.new(30,2,30); pad.Transparency=0.6; pad.Parent=Workspace
			ST.pad=pad
		end
		ST.pad.CFrame=CFrame.new(padPos)
		F.warpTo(root,padPos+Vector3.new(0,4,0))
	end
	function F.exitSafe(reason,cooldown)
		ST.guard=false; ST.resumeReadyAt=nil
		ST.cooldownUntil=os.clock()+(cooldown or 3)
		NC.safeCF=nil
		local root=F.getRoot()
		if root and ST.fleeFrom then
			GL.stop()
			F.warpTo(root,ST.fleeFrom+Vector3.new(0,3,0))
		end
		if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad=nil end
		F.setNote(reason,5)
	end

	--=========================================================
	-- WORKERS
	--=========================================================
	task.spawn(function()
		while gui.Parent do
			F.refreshThreats()
			F.updateFollow()
			local r=F.readHPRatio()
			if r then
				ST.hp=r
				if r>=0.5 then ST.everHealthy=true end
			end
			local root=F.getRoot()
			local now=os.clock()
			F.checkCharacterStatus()
			if ST.guard and not CFG.GUARD then
				F.exitSafe("ปิดระบบหลบ - กลับไปเก็บของ",0)
			elseif CFG.GUARD and root and r then
				if not ST.guard then
					if r<CFG.HP_LOW and ST.everHealthy and now>=ST.cooldownUntil then F.enterSafe(root) end
				else
					if r>ST.lastHp+0.005 then ST.lastRise=now end
					ST.lastHp=r
					if r>=CFG.HP_RESUME then
						ST.resumeReadyAt=ST.resumeReadyAt or now
						if not F.nearThreat(ST.fleeFrom,CFG.THREAT_RADIUS) then
							F.exitSafe("เลือดฟื้นแล้ว ไม่มีศัตรู",3)
						elseif now-ST.resumeReadyAt>CFG.THREAT_WAIT_MAX then
							F.exitSafe("รอศัตรูนานเกินไป",10)
						end
					else
						ST.resumeReadyAt=nil
						if now-ST.lastRise>CFG.NO_REGEN_TIMEOUT then
							F.exitSafe("เลือดไม่ฟื้น - เลิกรอ",CFG.GUARD_COOLDOWN)
						end
					end
				end
			end
			task.wait(0.12)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			if NC.on then
				local ch=player.Character
				local root=F.getRoot()
				local hum=ch and ch:FindFirstChildOfClass("Humanoid")
				if ch and root and hum and hum.Health>0 then
					if NC.char~=ch then NC.apply() end
					NC.params.FilterDescendantsInstances={ch}
					local floorNear=Workspace:Raycast(root.Position,Vector3.new(0,-9,0),NC.params)
					if hum.FloorMaterial~=Enum.Material.Air and floorNear then
						NC.safeCF=root.CFrame
					elseif NC.safeCF and not NC.busy then
						local vel=root.AssemblyLinearVelocity
						local tooLow=root.Position.Y<NC.safeCF.Position.Y-32
						local falling=vel.Y<-48 and not floorNear
						if tooLow or falling then
							NC.busy=true
							local safe=NC.safeCF
							GL.stop(); NC.set(false)
							local cur=F.getRoot()
							if cur and safe then F.warpTo(cur,safe.Position+Vector3.new(0,4,0)) end
							task.wait(0.6)
							NC.busy=false
						end
					end
				end
			end
			task.wait(0.25)
		end
	end)

	-- REBIRTH / EVOLVE WORKER
	do
		local PURE_PAIR="^%s*%a*%s*[%d%.,]+%s*[KkMmBbTt]?%s*/%s*[%d%.,]+%s*[KkMmBbTt]?%s*$"
		local function scanRebirthUI()
			UI.index()
			local ui={rowTexts={}}
			local cam=Workspace.CurrentCamera
			local vh=cam and cam.ViewportSize.Y or 1000
			for _,L in ipairs(UI.labels) do
				if L.o.Parent then
					local t=L.text
					if L.rb and L.raw~="" and #ui.rowTexts<8 then ui.rowTexts[#ui.rowTexts+1]=L.raw end
					if L.raw:find("/",1,true) then
						local cur,req=F.parsePair(L.raw)
						if cur and req and req>0 then
							if L.rb and t:find("POWER",1,true) then ui.power=ui.power or L.o end
							if not ui.top and string.find(L.raw,PURE_PAIR) and L.shown and L.y<vh*0.18 then ui.top=L.o end
						end
					end
					if not ui.readyLbl and L.rb and t:find("READY TO REBIRTH",1,true) then ui.readyLbl=L.o end
				end
			end
			for _,B in ipairs(UI.buttons) do
				if B.o.Parent and not B.buy then
					local ln=string.lower(B.o.Name)
					if ln:find("evolve",1,true) then
						if B.sgn:find(CFG.EVOLVE_GUI_WORD,1,true) then
							if not ui.evo or (B.shown and not F.liveShown(ui.evo)) then ui.evo=B.o end
						end
					else
						local all=B.text
						if all:find("REBIRTH",1,true) or all:find("TAP AGAIN",1,true) or ln:find("rebirth",1,true) then
							local isB=all:find("TAP AGAIN",1,true)~=nil
							local isA=(not isB) and (all:find("REBIRTH%sX%s%d")~=nil or (B.rb and all:find("REBIRTH",1,true)~=nil))
							local key=isB and "b" or (isA and "a" or "opener")
							local cur=ui[key]
							if not cur or (B.shown and not F.liveShown(cur)) then ui[key]=B.o end
						end
					end
				end
			end
			return ui
		end
		local function evoText(ui)
			local e=ui.evo
			if e and e.Parent and F.liveShown(e) then
				local s=string.upper(e.Text or "")
				for _,d in ipairs(e:GetDescendants()) do
					if d:IsA("TextLabel") or d:IsA("TextButton") then s=s.."  "..string.upper(d.Text or "") end
				end
				return s
			end
			return ""
		end
		local function rebirthReady(ui)
			if evoText(ui):find("REBIRTH",1,true) then return true end
			if ui.power and ui.power.Parent then
				local cur,req=F.parsePair(ui.power.Text)
				if cur and req and req>0 then return cur>=req end
			end
			if ui.readyLbl and ui.readyLbl.Parent then
				return not string.upper(ui.readyLbl.Text):find("NOT",1,true)
			end
			if ui.top and ui.top.Parent and string.find(ui.top.Text,PURE_PAIR) then
				local cur,req=F.parsePair(ui.top.Text)
				if cur and req and req>0 then return cur>=req end
			end
			return false
		end
		local function rebirthCount()
			local ls=player:FindFirstChild("leaderstats")
			if ls then
				for _,v in ipairs(ls:GetChildren()) do
					if v:IsA("ValueBase") and string.lower(v.Name):find("rebirth",1,true) then return tonumber(v.Value) end
				end
			end
			return nil
		end
		task.spawn(function()
			local fails=0
			while gui.Parent do
				local now=os.clock()
				if CFG.REBIRTH or CFG.EVOLVE then
					local inSeq=now-ST.rbTryAt<6
					if now-ST.rbScanAt>=(inSeq and 0.3 or 1.5) then
						ST.rbScanAt=now
						ST.rb=scanRebirthUI()
					end
					local ui=ST.rb
					if CFG.REBIRTH and ui and now>=ST.rbBlockedUntil
						and now-ST.rbTryAt>=F.jitter(CFG.REBIRTH_STEP_DELAY,0.15) and rebirthReady(ui) then
						local opener=ui.opener
						if evoText(ui):find("REBIRTH",1,true) then opener=ui.evo end
						local pick,stage=nil,1
						if ui.b and ui.b.Parent then pick,stage=ui.b,3
						elseif ui.a and ui.a.Parent then
							if F.liveShown(ui.a) then pick,stage=ui.a,2
							elseif opener and opener.Parent and now-ST.rbOpenAt>=6 then
								pick,stage=opener,1; ST.rbOpenAt=now
							elseif now-ST.rbOpenAt>=2.5 then pick,stage=ui.a,2 end
						elseif opener and opener.Parent and now-ST.rbOpenAt>=6 then
							pick,stage=opener,1; ST.rbOpenAt=now
						end
						if pick then
							ST.rbTryAt=now
							F.clickGui(pick)
							F.setNote("REBIRTH ขั้น "..stage.."/3",3)
							if stage==3 then
								if now-ST.rbBStart>40 then ST.rbBStart=now; ST.rbBCount=0 end
								ST.rbBCount=ST.rbBCount+1
								if ST.rbBCount>4 then ST.rbBCount=0; ST.rbBlockedUntil=now+60 end
								local before=rebirthCount()
								if before then
									task.delay(4,function()
										local after=rebirthCount()
										if after and after>before then fails=0
										else
											fails=fails+1
											if fails>=3 then fails=0; ST.rbBlockedUntil=os.clock()+120 end
										end
									end)
								end
							end
						end
					end
					if CFG.EVOLVE and ui and ui.evo and ui.evo.Parent
						and now-ST.evoAt>=CFG.EVOLVE_COOLDOWN and now-ST.rbTryAt>=8 then
						local txt=evoText(ui)
						if txt~="" and not txt:find("REBIRTH",1,true) then
							ST.evoAt=now; ST.evoClicks=ST.evoClicks+1
							F.clickGui(ui.evo)
							F.setNote("EVOLVE",2)
						end
					end
				end
				task.wait(CFG.REBIRTH_POLL)
			end
		end)
	end

	-- CLAIM / QUEST / BAG WORKERS
	task.spawn(function()
		local lastClaim=setmetatable({},{__mode="k"})
		local attempts=setmetatable({},{__mode="k"})
		local blocked=setmetatable({},{__mode="k"})
		while gui.Parent do
			if CFG.CLAIM and os.clock()>=ST.claimPauseUntil then
				if CFG.BLOCK_ROBUX then F.closeShopWindows() end
				UI.index()
				for _,B in ipairs(UI.buttons) do
					if B.shown and not B.buy and B.o.Parent and not ST.badClaim[B.o] then
						local txt=B.text
						local isQuest=B.quest and (txt:find("CLAIM",1,true) or txt:find("COMPLETE",1,true) or txt:find("REWARD",1,true))
						if (string.find(txt,"%f[%a]CLAIM%f[%A]") or isQuest)
							and not txt:find("BUY",1,true) and not txt:find("PURCHASE",1,true)
							and not txt:find("ROBUX",1,true) and not txt:find("R$",1,true)
							and not txt:find("◎",1,true) and not txt:find("ALL 7",1,true) then
							local btn=B.o
							local now=os.clock()
							if btn.Parent and now>=(blocked[btn] or 0)
								and (not lastClaim[btn] or now-lastClaim[btn]>=CFG.CLAIM_RETRY) then
								lastClaim[btn]=now
								ST.lastClaimBtn=btn; ST.lastClaimAt=now
								attempts[btn]=(attempts[btn] or 0)+1
								if attempts[btn]>=3 then attempts[btn]=0; blocked[btn]=now+600 end
								F.clickGui(btn)
								F.setNote("CLAIM",2)
								task.wait(F.jitter(0.4,0.3))
							end
						end
					end
				end
			end
			task.wait(CFG.CLAIM_POLL)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			if CFG.QUEST then pcall(F.scanQuest) else ST.quest=nil; W.questLine.Text="" end
			task.wait(CFG.QUEST_POLL)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			if CFG.BAG and not ST.guard then
				local full,ratio=F.bagStatus()
				ST.bagRatio=ratio
				if full and not ST.bagMode then
					ST.bagMode=true
					ST.bagUntil=os.clock()+CFG.SELL_TIMEOUT
					ST.sellClicks=0
					F.setNote("🎒 ของเต็ม - ไปขาย",4)
					F.findSellPoint()
				elseif ST.bagMode then
					if not full or os.clock()>ST.bagUntil then
						ST.bagMode=false
						if full then F.setNote("🎒 ขายไม่สำเร็จ - กลับไปฟาร์ม",3) end
					end
				end
			else
				ST.bagMode=false
			end
			task.wait(CFG.BAG_POLL)
		end
	end)

	-- MAIN FARM WORKER
	task.spawn(function()
		task.wait(0.5)
		F.saveSpawnPoint()
		while gui.Parent do
			local root=F.getRoot()
			if root then
				ST.origin=ST.origin or root.Position
				F.checkCharacterStatus()
				local now=os.clock()
				if now<ST.farmPauseUntil then
					ST.currentAction="⏸ พักกันวาร์ปวน "..math.ceil(ST.farmPauseUntil-now).." วิ"
					F.showAction(); task.wait(0.3)
				elseif ST.guard then
					ST.currentAction="[GUARD] HP "..F.pct(ST.hp).."% รอ "..F.pct(CFG.HP_RESUME).."%"
					F.showAction(); task.wait(0.15)
				elseif ST.bagMode then
					local sp=ST.sellPoint or ST.spawnPoint
					if sp then
						if (sp-root.Position).Magnitude>6 then
							if CFG.MOVE_MODE=="glide" then
								if not GL.active then GL.begin(root,sp+Vector3.new(0,3,0),"SELL") end
							else
								F.warpTo(root,sp+Vector3.new(0,3,0))
							end
						else
							F.clickSellButtons()
							ST.sellClicks=ST.sellClicks+1
						end
					else
						F.clickSellButtons()
					end
					ST.currentAction="🎒 ไปขายของ ("..F.pct(ST.bagRatio).."%)"
					F.showAction(); task.wait(0.4)
				else
					if CFG.AUTO_NOCLIP and not NC.on and not ST.noclipUserOff then NC.set(true) end
					local kind,target=F.nextEnabledTarget(root.Position)
					ST.lastTarget=target
					if kind and target then
						ST.idleSince=nil
						local ok
						if kind=="ITEM" then ok=RADAR.visitItem(target,root) else ok=MOVE.to(target,root,"MONSTER") end
						if GL.active then
							ST.currentAction="🛼 "..kind.." → "..F.groupName(target,kind)
						elseif ok then
							ST.currentAction=kind.." • "..F.groupName(target,kind)
						else
							ST.currentAction="ค้นหาเป้าหมายถัดไป..."
						end
						if os.clock()<ST.noteUntil then ST.currentAction=ST.note.." | "..ST.currentAction end
						F.showAction()
						local dwell=(kind=="ITEM") and K.ITEM_DWELL or K.MONSTER_DWELL
						if CFG.HUMANIZE and CFG.MICRO_PAUSE>0 and RNG:NextNumber()<CFG.MICRO_PAUSE then
							task.wait(RNG:NextNumber(0.25,0.8))
						end
						task.wait(GL.active and 0.06 or F.jitter(dwell))
					else
						ST.idleSince=ST.idleSince or now
						ST.currentAction="รอเป้าหมาย..."
						if CFG.ROAM and now-ST.idleSince>=CFG.ROAM_AFTER and F.anyEnabledTarget() then
							if F.roamStep(root) then
								ST.currentAction="เดินสำรวจหาเป้าหมาย..."
								F.showAction(); task.wait(F.jitter(0.7))
							end
						end
						if os.clock()<ST.noteUntil then ST.currentAction=ST.note.." | "..ST.currentAction end
						F.showAction(); task.wait(F.jitter(K.IDLE_DELAY))
					end
				end
			else
				GL.stop()
				ST.currentAction="รอตัวละคร..."
				F.showAction(); task.wait(0.3)
			end
		end
	end)

	-- COMBAT WORKER
	task.spawn(function()
		while gui.Parent do
			local busy=false
			local root=F.getRoot()
			if root and not ST.guard and not ST.closing then
				local now=os.clock()
				if ST.autoAttackOn and now-(ST.biteAt or -1e9)>=F.jitter(CFG.BITE_INTERVAL) then
					ST.biteAt=now
					F.pressBite()
					busy=true
				end
				if CFG.SKILLS then
					local go=true
					if CFG.SKILL_NEED_ENEMY then go=(ST.mt~=nil) end
					if go then
						if now-ST.skillQAt>=F.jitter(CFG.SKILL_Q_INTERVAL,0.15) then
							ST.skillQAt=now; F.pressSkill(1); busy=true
						end
						if now-ST.skillEAt>=F.jitter(CFG.SKILL_E_INTERVAL,0.15) then
							ST.skillEAt=now; F.pressSkill(2); busy=true
						end
					end
				end
			end
			task.wait(busy and 0.03 or 0.2)
		end
	end)

	-- SHOP POPUP WATCH & QUEUE WORKERS
	task.spawn(function()
		while gui.Parent do
			if CFG.BLOCK_ROBUX then
				if F.closeShopWindows() then
					ST.promptHits=ST.promptHits+1
					local now=os.clock()
					local b=ST.lastClaimBtn
					if b and now-ST.lastClaimAt<3 then
						ST.badClaim[b]=true; ST.lastClaimBtn=nil
					end
					ST.claimPauseUntil=now+CFG.CLAIM_PAUSE_AFTER_PROMPT
					F.setNote("⛔ ปิดหน้าต่างร้านค้า/Robux",3)
				end
			end
			task.wait(CFG.PURCHASE_POLL)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			local processed,changed=0,false
			while not ST.scanRunning and RADAR.pendHead<=RADAR.pendTail and processed<CFG.SCAN_BATCH do
				local obj=RADAR.pendingAdds[RADAR.pendHead]
				RADAR.pendingAdds[RADAR.pendHead]=nil; RADAR.pendHead=RADAR.pendHead+1
				if obj then
					RADAR.pendSet[obj]=nil
					if RADAR.addObject(obj) then changed=true end
				end
				processed=processed+1
			end
			if RADAR.pendHead>RADAR.pendTail then RADAR.pendingAdds={}; RADAR.pendHead,RADAR.pendTail=1,0 end
			if changed then RADAR.scheduleRender() end
			task.wait(0.08)
		end
	end)

	--=========================================================
	-- SAVE / LOAD
	--=========================================================
	function F.saveState()
		if typeof(writefile)~="function" then return end
		local d={v=262,enabled={},known={ITEM={},MONSTER={}},cfg={},
			sell=ST.sellPoint and {ST.sellPoint.X,ST.sellPoint.Y,ST.sellPoint.Z} or nil}
		for k,v in pairs(RADAR.enabled) do d.enabled[k]=v and true or false end
		for _,cat in ipairs({"ITEM","MONSTER"}) do
			for key,k in pairs(RADAR.known[cat]) do
				d.known[cat][key]={name=k.name,buff=k.buff and true or false,rank=k.rank,pscore=k.pscore}
			end
		end
		for _,f in ipairs(CFG.SAVE_FLAGS) do d.cfg[f]=CFG[f] and true or false end
		d.cfg.MONSTER_MODE=CFG.MONSTER_MODE
		d.cfg.MOVE_MODE=CFG.MOVE_MODE
		d.cfg.BITE_INTERVAL=CFG.BITE_INTERVAL
		d.cfg.WARP_SPEED=CFG.WARP_SPEED
		d.cfg.GLIDE_SPEED=CFG.GLIDE_SPEED
		d.cfg.TAP_JITTER=CFG.TAP_JITTER
		pcall(function() writefile(CFG.SAVE_FILE,HS:JSONEncode(d)) end)
	end
	function F.loadState()
		if typeof(readfile)~="function" or typeof(isfile)~="function" then return end
		local ok,d=pcall(function()
			if not isfile(CFG.SAVE_FILE) then return nil end
			return HS:JSONDecode(readfile(CFG.SAVE_FILE))
		end)
		if not ok or type(d)~="table" then return end
		if type(d.enabled)=="table" then
			for k,v in pairs(d.enabled) do RADAR.enabled[k]=(v==true) end
		end
		if type(d.known)=="table" then
			for _,cat in ipairs({"ITEM","MONSTER"}) do
				local src=d.known[cat]
				if type(src)=="table" then
					for key,k in pairs(src) do
						if type(k)=="table" and type(k.name)=="string" then
							RADAR.known[cat][key]={key=key,name=k.name,buff=(k.buff==true),
								rank=tonumber(k.rank) or 3,pscore=tonumber(k.pscore) or 0}
						end
					end
				end
			end
		end
		if type(d.cfg)=="table" then
			for _,f in ipairs(CFG.SAVE_FLAGS) do
				if type(d.cfg[f])=="boolean" then CFG[f]=d.cfg[f] end
			end
			if d.cfg.MONSTER_MODE=="value" or d.cfg.MONSTER_MODE=="near" then CFG.MONSTER_MODE=d.cfg.MONSTER_MODE end
			if d.cfg.MOVE_MODE=="warp" or d.cfg.MOVE_MODE=="glide" then CFG.MOVE_MODE=d.cfg.MOVE_MODE end
			local bi=tonumber(d.cfg.BITE_INTERVAL)
			if bi and bi>=0.05 and bi<=0.6 then CFG.BITE_INTERVAL=bi end
			local ws=tonumber(d.cfg.WARP_SPEED)
			if ws and ws>=0.2 and ws<=2 then CFG.WARP_SPEED=ws; F.applyWarpSpeed() end
			local gs=tonumber(d.cfg.GLIDE_SPEED)
			if gs and gs>=40 and gs<=220 then CFG.GLIDE_SPEED=gs end
			local tj=tonumber(d.cfg.TAP_JITTER)
			if tj and tj>=0 and tj<=0.6 then CFG.TAP_JITTER=tj end
		end
		if type(d.sell)=="table" and #d.sell==3 then
			ST.sellPoint=Vector3.new(d.sell[1],d.sell[2],d.sell[3])
		end
	end
	task.spawn(function()
		while gui.Parent do
			task.wait(4)
			if ST.dirty and not ST.closing then ST.dirty=false; F.saveState() end
		end
	end)

	--=========================================================
	-- SETTINGS WIRING & SHUTDOWN
	--=========================================================
	function F.paintMode()
		SET.mode.Text=(CFG.MONSTER_MODE=="value") and "ตีมอน: ค่าสูงก่อน" or "ตีมอน: ใกล้สุดก่อน"
		SET.mode.BackgroundColor3=TH.btnBlue
	end
	function F.paintMove()
		SET.move.Text=(CFG.MOVE_MODE=="glide") and "MOVE: GLIDE 🛼" or "MOVE: WARP 🌀"
		SET.move.BackgroundColor3=(CFG.MOVE_MODE=="glide") and TH.quest or TH.btnBlue
	end
	function F.repaintSettings()
		SL.bite.set(1/CFG.BITE_INTERVAL,true)
		SL.warp.set(CFG.WARP_SPEED,true)
		SL.glide.set(CFG.GLIDE_SPEED,true)
		SL.jit.set(CFG.TAP_JITTER*100,true)
		F.paintToggle(SET.robux,CFG.BLOCK_ROBUX,"BLOCK ROBUX: ON","BLOCK ROBUX: OFF")
		F.paintToggle(SET.rebirth,CFG.REBIRTH,"REBIRTH: ON","REBIRTH: OFF")
		F.paintToggle(SET.guard,CFG.GUARD,"GUARD: ON","GUARD: OFF")
		F.paintToggle(SET.claim,CFG.CLAIM,"CLAIM: ON","CLAIM: OFF")
		F.paintToggle(SET.evolve,CFG.EVOLVE,"HATCH: ON","HATCH: OFF")
		F.paintToggle(SET.skill,CFG.SKILLS,"SKILL AUTO: ON","SKILL AUTO: OFF")
		F.paintToggle(SET.roam,CFG.ROAM,"ROAM: ON","ROAM: OFF")
		F.paintToggle(SET.human,CFG.HUMANIZE,"HUMANIZE: ON","HUMANIZE: OFF")
		F.paintToggle(SET.quest,CFG.QUEST,"QUEST: ON","QUEST: OFF")
		F.paintToggle(SET.avoid,CFG.AVOID_PLAYERS,"AVOID PLAYER: ON","AVOID PLAYER: OFF")
		F.paintToggle(SET.bag,CFG.BAG,"BAG MANAGER: ON","BAG MANAGER: OFF")
		SET.sell.Text=ST.sellPoint and "📍 จุดขาย ✓ (แตะ=ตั้งใหม่)" or "📍 ตั้งจุดขาย"
		F.paintMode(); F.paintMove()
	end
	SL.bite.onChange=function(v) CFG.BITE_INTERVAL=1/v; ST.dirty=true end
	SL.warp.onChange=function(v) CFG.WARP_SPEED=v; F.applyWarpSpeed(); ST.dirty=true end
	SL.glide.onChange=function(v) CFG.GLIDE_SPEED=v; ST.dirty=true end
	SL.jit.onChange=function(v) CFG.TAP_JITTER=v/100; CFG.DELAY_JITTER=v/200; ST.dirty=true end

	function F.setCombat(value)
		ST.combatOn=value
		F.paintToggle(W.combat,value,"MONSTER WARP: ON","MONSTER WARP: OFF")
		if value and not ST.autoAttackOn then
			ST.autoAttackOn=true
			F.paintToggle(W.abilityToggle,true,"BITE AUTO: ON","BITE AUTO: OFF")
			if W.miniAtk then F.paintToggle(W.miniAtk,true,"⚔\nON","⚔\nBITE") end
		end
	end
	W.combat.MouseButton1Click:Connect(function() F.setCombat(not ST.combatOn) end)
	W.abilityToggle.MouseButton1Click:Connect(function()
		ST.autoAttackOn=not ST.autoAttackOn
		F.paintToggle(W.abilityToggle,ST.autoAttackOn,"BITE AUTO: ON","BITE AUTO: OFF")
		if W.miniAtk then F.paintToggle(W.miniAtk,ST.autoAttackOn,"⚔\nON","⚔\nBITE") end
	end)
	W.miniAtk.MouseButton1Click:Connect(function()
		ST.autoAttackOn=not ST.autoAttackOn
		F.paintToggle(W.miniAtk,ST.autoAttackOn,"⚔\nON","⚔\nBITE")
		F.paintToggle(W.abilityToggle,ST.autoAttackOn,"BITE AUTO: ON","BITE AUTO: OFF")
	end)
	SET.noclip.MouseButton1Click:Connect(function()
		NC.set(not NC.on); ST.noclipUserOff=not NC.on
	end)
	SET.robux.MouseButton1Click:Connect(function()
		CFG.BLOCK_ROBUX=not CFG.BLOCK_ROBUX
		F.paintToggle(SET.robux,CFG.BLOCK_ROBUX,"BLOCK ROBUX: ON","BLOCK ROBUX: OFF")
		if not CFG.BLOCK_ROBUX then ST.claimPauseUntil=0 end
	end)
	local function simpleToggle(btn,key,onT,offT)
		btn.MouseButton1Click:Connect(function()
			CFG[key]=not CFG[key]
			F.paintToggle(btn,CFG[key],onT,offT)
		end)
	end
	simpleToggle(SET.rebirth,"REBIRTH","REBIRTH: ON","REBIRTH: OFF")
	simpleToggle(SET.guard,"GUARD","GUARD: ON","GUARD: OFF")
	simpleToggle(SET.claim,"CLAIM","CLAIM: ON","CLAIM: OFF")
	simpleToggle(SET.evolve,"EVOLVE","HATCH: ON","HATCH: OFF")
	simpleToggle(SET.skill,"SKILLS","SKILL AUTO: ON","SKILL AUTO: OFF")
	simpleToggle(SET.roam,"ROAM","ROAM: ON","ROAM: OFF")
	simpleToggle(SET.human,"HUMANIZE","HUMANIZE: ON","HUMANIZE: OFF")
	simpleToggle(SET.quest,"QUEST","QUEST: ON","QUEST: OFF")
	simpleToggle(SET.avoid,"AVOID_PLAYERS","AVOID PLAYER: ON","AVOID PLAYER: OFF")
	simpleToggle(SET.bag,"BAG","BAG MANAGER: ON","BAG MANAGER: OFF")
	SET.mode.MouseButton1Click:Connect(function()
		CFG.MONSTER_MODE=(CFG.MONSTER_MODE=="value") and "near" or "value"
		ST.mt=nil; ST.dirty=true; F.paintMode()
	end)
	SET.move.MouseButton1Click:Connect(function()
		CFG.MOVE_MODE=(CFG.MOVE_MODE=="warp") and "glide" or "warp"
		GL.stop(); ST.dirty=true; F.paintMove()
		F.setNote(CFG.MOVE_MODE=="glide" and "🛼 เคลื่อนที่แบบลื่น (ปลอดภัยกว่า)" or "🌀 วาร์ปทันที (เร็วกว่า)",3)
	end)
	SET.sell.MouseButton1Click:Connect(function()
		local root=F.getRoot()
		if root then
			ST.sellPoint=root.Position
			ST.dirty=true
			SET.sell.Text="📍 จุดขาย ✓ (แตะ=ตั้งใหม่)"
			F.setNote("📍 ตั้งจุดขายที่นี่แล้ว",3)
		end
	end)

	function F.shutdownAll()
		if ST.closing then return end
		ST.closing=true
		pcall(F.saveState)
		ST.combatOn=false; ST.autoAttackOn=false
		CFG.GUARD=false; CFG.REBIRTH=false; CFG.CLAIM=false
		CFG.EVOLVE=false; CFG.SKILLS=false; CFG.ROAM=false
		CFG.QUEST=false; CFG.BAG=false
		GL.stop()
		if ST.guard then pcall(F.exitSafe,"ปิดสคริป - ลงจากแท่น",0) end
		ST.guard=false
		if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad=nil end
		pcall(function() NC.set(false) end)
		pcall(NC.restore)
		for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		conns={}
		ST.mt=nil
		table.clear(ST.hot); table.clear(ST.mBlack)
		table.clear(RADAR.groups.ITEM); table.clear(RADAR.groups.MONSTER)
		table.clear(RADAR.objectGroup); table.clear(RADAR.enabled)
		table.clear(RADAR.known.ITEM); table.clear(RADAR.known.MONSTER)
		table.clear(RADAR.itemVisits); table.clear(RADAR.pendingAdds); RADAR.pendHead,RADAR.pendTail=1,0
		table.clear(ST.voidBlacklist); table.clear(SAFE.cache); table.clear(ST.buyWindows)
		table.clear(ST.badClaim); table.clear(ST.skillList); table.clear(ST.threats)
		table.clear(RADAR.rowPool); table.clear(RADAR.headPool)
		pcall(function()
			local g=getgenv and getgenv()
			if g and g.TAYJAY_ANT_SHUTDOWN==F.shutdownAll then g.TAYJAY_ANT_SHUTDOWN=nil end
		end)
		pcall(function() gui:Destroy() end)
		print("[TAYJAY] ปิดสคริปแล้ว - ล้างสถานะเรียบร้อย")
	end

	W.closeBtn.MouseButton1Click:Connect(function()
		local now=os.clock()
		if now-ST.closeArmedAt<3 then F.shutdownAll()
		else
			ST.closeArmedAt=now
			W.closeBtn.Text="แตะอีกครั้ง!"
			task.delay(3,function()
				if gui.Parent and os.clock()-ST.closeArmedAt>=2.9 then W.closeBtn.Text="ปิดสคริป" end
			end)
		end
	end)
	W.itemTab.MouseButton1Click:Connect(function() F.setTab("ITEM") end)
	W.monsterTab.MouseButton1Click:Connect(function() F.setTab("MONSTER") end)
	W.settingsTab.MouseButton1Click:Connect(function() F.setTab("SET") end)
	W.refresh.MouseButton1Click:Connect(RADAR.fullScan)
	W.fold.MouseButton1Click:Connect(function() ST.collapsed=not ST.collapsed; F.applyLayout() end)
	W.searchBox:GetPropertyChangedSignal("Text"):Connect(function() if F.render then F.render() end end)
	W.allBtn.MouseButton1Click:Connect(function()
		local keys=ST.visibleKeys or {}
		local allOn=#keys>0
		for _,k in ipairs(keys) do if not RADAR.enabled[k] then allOn=false break end end
		for _,k in ipairs(keys) do RADAR.enabled[k]=not allOn end
		ST.dirty=true; F.render()
	end)

	F.bind(Workspace.DescendantAdded,RADAR.queueObject)
	F.bind(Workspace.DescendantRemoving,RADAR.removeObject)
	F.bind(player.CharacterAdded,function()
		GL.stop()
		ST.guard=false; ST.resumeReadyAt=nil; ST.everHealthy=false; ST.hp=1; ST.mt=nil
		ST.lastTarget=nil; ST.inVoid=false; ST.inWater=false; ST.groundOK=false
		ST.biteBtn=nil; ST.biteLogged=""; ST.skillLogged=""; table.clear(ST.skillList)
		ST.bagMode=false
		NC.safeCF=nil
		if ST.pad then pcall(function() ST.pad:Destroy() end); ST.pad=nil end
		task.wait(0.6)
		if NC.on and gui.Parent then NC.apply() end
		task.wait(0.5)
		if gui.Parent then F.render() end
	end)
	gui.Destroying:Connect(function() F.shutdownAll() end)

	--=========================================================
	-- INIT
	--=========================================================
	F.loadState()
	F.repaintSettings()
	F.setTab("ITEM")
	task.spawn(function() task.wait(1); RADAR.fullScan() end)
	pcall(function()
		local g=getgenv and getgenv()
		if g then g.TAYJAY_ANT_SHUTDOWN=F.shutdownAll end
	end)
	print("[TAYJAY ANT EVOLUTION RADAR V26.2 DELTA-PURE] Loaded | firetouchinterest="..tostring(RADAR.hasFireTouch))
end, debug.traceback)

if not okRun then
	warn("[TAYJAY V26.2 ERROR]: " .. tostring(errRun))
end
