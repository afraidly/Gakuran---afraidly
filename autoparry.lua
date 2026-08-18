-- Gakuran Auto-Parry Module (separate from autoplay)
-- Based on the original gakran.lua by artxficial
-- Loaded by autoplay.lua via loadstring

local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Lib = _G.GakuranLib
local Win = _G.GakuranWin
if not Lib or not Win then
	warn("[AutoParry] No shared UI found - load autoplay.lua first")
	return
end

if _G.GakuranParryCleanup then
	pcall(_G.GakuranParryCleanup)
end

print("[AutoParry] Module loaded")

-- ==========================================
-- Game Configuration
-- ==========================================

local IgnoreIds = {
	73766443218740,
	111699625251889,
	85823794654077,
	99661732639863,
	106268941365574,
	109816855387997,
	122561749929324,
	129805948180599,
	90752347516770,
	135133599113049,
	132695091086148,
	137015026151472,
	114511731321756,
	100794890036133,
	109303037515668,
	117293898907979,
	74690341409113,
	73090768467054,
	72284079162560,
	89016181362524,
	76945839486275,
	101161965631044,
	128307941333158,
	85931837451298,
	91352556581859,
	77911299793653,
	129335968179665,
	122384188141033,
	132695766056641,
	113331696487725,
	124220338099067,
	99799500309776,
	108636808436488,
	90015977935891,
	87932588807124,
	132477488202815,
	102982320608759,
	109278619250401,
	79971841883936,
	97783129267001,
	72822821848529,
	79974955602012,
	77798715679680,
	85845666927963,
	108862846290180,
	108045962864902,
	93184693099565,
	120399899079666,
	99958962160522,
	134968158802175,
	99309341097380,
	83600639547203,
	79688890917324,
	71385851727754,
	108803307415813,
}

local ParriedAnimation = {
	"rbxassetid://100773926241456",
	"rbxassetid://102823909334302",
	"rbxassetid://96304721384743",
	"rbxassetid://82979105739696",
	"rbxassetid://96600699015093",
	"rbxassetid://138519505081692",
}
local StunnedAnimation = {
	"rbxassetid://122541287927198",
	"rbxassetid://83600639547203",
	"rbxassetid://80309578200579",
	"rbxassetid://92787945841620",
	"rbxassetid://108045962864902",
	"rbxassetid://104407197874289",
}
local ParryingAnimation = {
	"rbxassetid://118147060185189",
	"rbxassetid://80135556847061",
	"rbxassetid://88718564310179",
}
local ParryFailed = {
	"rbxassetid://4210597123",
}

local RawConfig = {
	KarateAnims = {
		["rbxassetid://137837926745158"] = { DisplayName = "1stM1", ReactionTime = 0.15 },
		["rbxassetid://100981571094705"] = { DisplayName = "2ndM1", ReactionTime = 0.15 },
		["rbxassetid://130865087635587"] = { DisplayName = "3rdM1", ReactionTime = 0.15 },
		["rbxassetid://86495068205420"] = { DisplayName = "4thM1", ReactionTime = 0.15 },
		["rbxassetid://120393553812903"] = { DisplayName = "M2", ReactionTime = 0.3 },
	},
	AliAnims = {
		["rbxassetid://137247073345979"] = { DisplayName = "1stM1", ReactionTime = 0.12 },
		["rbxassetid://102632933427597"] = { DisplayName = "2ndM1", ReactionTime = 0.17 },
		["rbxassetid://119814294807778"] = { DisplayName = "3rdM1", ReactionTime = 0.21 },
		["rbxassetid://74315946602284"] = { DisplayName = "4thM1", ReactionTime = 0.11 },
		["rbxassetid://128315752013166"] = { DisplayName = "M2", ReactionTime = 0.3 },
		["rbxassetid://70642098724811"] = { DisplayName = "M2Right", ReactionTime = 0.3 },
	},
	BasicAnims = {
		["rbxassetid://83491849294956"] = { DisplayName = "1stM1" },
		["rbxassetid://89420531853362"] = { DisplayName = "2ndM1" },
		["rbxassetid://83730275893449"] = { DisplayName = "3rdM1" },
		["rbxassetid://106980660082799"] = { DisplayName = "4thM1" },
		["rbxassetid://78888626472394"] = { DisplayName = "M2", ReactionTime = 0.3 },
		M1Time = 0.14,
	},
	WrestlingAnims = {
		["rbxassetid://91485623489753"] = { DisplayName = "4thM1" },
		["rbxassetid://73748315742870"] = { DisplayName = "M2", ReactionTime = 0.3 },
		["rbxassetid://82903450925391"] = { DisplayName = "1stM1" },
		["rbxassetid://119685134442395"] = { DisplayName = "2ndM1" },
		["rbxassetid://107464726433388"] = { DisplayName = "3rdM1" },
		M1Time = 0.15,
	},
	MuayThaiAnims = {
		["rbxassetid://137034747040618"] = { DisplayName = "M2", ReactionTime = 0.3 },
		["rbxassetid://74960202100098"] = { DisplayName = "4thM1", ReactionTime = 0.08 },
		["rbxassetid://104515319350296"] = { DisplayName = "3rdM1", ReactionTime = 0.08 },
		["rbxassetid://139911027872047"] = { DisplayName = "2ndM1", ReactionTime = 0.08 },
		["rbxassetid://96726284968458"] = { DisplayName = "1stM1", ReactionTime = 0.08 },
		M1Time = 0.1,
	},
	BoxingAnims = {
		["rbxassetid://137980914350618"] = { DisplayName = "1stM1", ReactionTime = 0.17 },
		["rbxassetid://100408082509740"] = { DisplayName = "2ndM1", ReactionTime = 0.17 },
		["rbxassetid://94803478352691"] = { DisplayName = "3rdM1", ReactionTime = 0.17 },
		["rbxassetid://78695517680318"] = { DisplayName = "4thM1", ReactionTime = 0.17 },
		["rbxassetid://132022052139564"] = {
			DisplayName = "M2",
			ReactionTime = 0.3,
			ParryFunction = "BoxingM2",
		},
	},
	HakariAnims = {
		["rbxassetid://82855179231529"] = { DisplayName = "MomentumM2" },
		["rbxassetid://92865171012109"] = { DisplayName = "1stM1", ReactionTime = 0.15 },
		["rbxassetid://103026596903060"] = { DisplayName = "2ndM1", ReactionTime = 0.17 },
		["rbxassetid://86626533783115"] = { DisplayName = "3rdM1", ReactionTime = 0.15 },
		["rbxassetid://103100834246116"] = { DisplayName = "4thM1", ReactionTime = 0.21 },
		["rbxassetid://103359839046574"] = { DisplayName = "M2", ReactionTime = 0.19 },
	},
	CapoeiraAnims = {
		["rbxassetid://125976167173936"] = { DisplayName = "1stM1", ReactionTime = 0.15 },
		["rbxassetid://134945199381140"] = { DisplayName = "2ndM1", ReactionTime = 0.22 },
		["rbxassetid://117877243065533"] = { DisplayName = "3rdM1", ReactionTime = 0.16 },
		["rbxassetid://106965238908791"] = { DisplayName = "4thM1", ReactionTime = 0.16 },
		["rbxassetid://131071815103338"] = { DisplayName = "Whirlwind", ReactionTime = 0.32 },
	},
	SluggerAnims = {
		["rbxassetid://134829666925953"] = { DisplayName = "1stM1", ReactionTime = 0.24 },
		["rbxassetid://104867156139010"] = { DisplayName = "2ndM1", ReactionTime = 0.22 },
		["rbxassetid://112759168172605"] = { DisplayName = "3rdM1", ReactionTime = 0.22 },
		["rbxassetid://114647502301740"] = { DisplayName = "4thM1", ReactionTime = 0.19 },
		["rbxassetid://118943955490014"] = { DisplayName = "M2", ReactionTime = 0.65 },
	},
	KureAnims = {
		["rbxassetid://71676634048602"] = { DisplayName = "4thM1", ReactionTime = 0.16 },
		["rbxassetid://102407060635393"] = { DisplayName = "Ook", ReactionTime = 0.1 },
		["rbxassetid://82904229252991"] = { DisplayName = "1stM1", ReactionTime = 0.16 },
		["rbxassetid://103732110215321"] = { DisplayName = "2ndM1", ReactionTime = 0.16 },
		["rbxassetid://103964436023727"] = { DisplayName = "3rdM1", ReactionTime = 0.16 },
	},
	WingChun = {
		["rbxassetid://81810173569294"] = { DisplayName = "4thM1", ReactionTime = 0.52 },
		["rbxassetid://82196924299426"] = { DisplayName = "M2", ReactionTime = 0.06 },
		["rbxassetid://71178147313608"] = { DisplayName = "1stM1", ReactionTime = 0.16 },
		["rbxassetid://117898175201201"] = { DisplayName = "2ndM1", ReactionTime = 0.16 },
		["rbxassetid://121315597867666"] = { DisplayName = "3rdM1", ReactionTime = 0.16 },
	},
	StrikerAnims = {
		["rbxassetid://116642061934550"] = { DisplayName = "1stM1" },
		["rbxassetid://115234849770695"] = { DisplayName = "2ndM1" },
		["rbxassetid://85554794950365"] = { DisplayName = "3rdM1" },
		["rbxassetid://73777821288331"] = { DisplayName = "4thM1" },
		["rbxassetid://86740216609625"] = { DisplayName = "M2", ReactionTime = 0.3 },
		["rbxassetid://91433537350586"] = { DisplayName = "M2", ReactionTime = 0.3 },
		["rbxassetid://127159892882325"] = { DisplayName = "M2", ReactionTime = 0.3 },
		M1Time = 0.15,
	},
	HakariOtherAnims = {
		["rbxassetid://126612786608030"] = { DisplayName = "1stM1" },
		["rbxassetid://113719263885794"] = { DisplayName = "2ndM1" },
		["rbxassetid://136305578634960"] = { DisplayName = "3rdM1" },
		["rbxassetid://89039586375625"] = { DisplayName = "4thM1" },
		["rbxassetid://82855179231529"] = { DisplayName = "MomentumM2" },
		["rbxassetid://101619248052969"] = { DisplayName = "M2" },
		M1Time = 0.15,
	},
	DebugAnims = {
		["http://www.roblox.com/asset/?id=125750702"] = { DisplayName = "M1", ReactionTime = 0.3 },
	},
}

local GameConfig = {}
for styleName, assets in pairs(RawConfig) do
	for assetId, data in pairs(assets) do
		if assetId == "M1Time" then
			continue
		end
		local flat = {}
		for k, v in pairs(data) do
			flat[k] = v
		end
		flat.Style = styleName
		if data.DisplayName ~= "M2" and assets.M1Time then
			flat.ReactionTime = assets.M1Time
		elseif not data.ReactionTime then
			flat.ReactionTime = 0.1
		end
		GameConfig[assetId] = flat
	end
end

-- ==========================================
-- Config variables
-- ==========================================

local SelectedFolder = nil
local AutoParryRange = 40
local MaxCycleRange = 80
local ParryWindow = 0.2
local ProbabilityToParry = 100
local DefaultReactionTime = 0.1
local ParryOffset = 0
local BlockHoldTime = 0.27
local IncludeLocalCharacter = false

local PARRY_KEY = string.byte("F")
local DODGE_KEY = string.byte("Q")
local PARRY_DISTANCE = 15

-- ==========================================
-- ESP Utility
-- ==========================================

local ESP_Utility = nil
pcall(function()
	local url = "https://raw.githubusercontent.com/afraidly/Gakuran---afraidly/refs/heads/main/esp_utility.lua"
	local src = game:HttpGet(url)
	if src and #src > 100 then
		loadstring(src)()
	end
end)
ESP_Utility = _G.ESP_Utility or ESP_Utility
if ESP_Utility then
	print("[AutoParry] ESP Utility loaded")
else
	warn("[AutoParry] ESP Utility failed to load")
end

-- ==========================================
-- Animation Tracker
-- ==========================================

local AnimationTracker = _G.AnimationTracker
if not AnimationTracker then
	pcall(function()
		local url = "https://raw.githubusercontent.com/afraidly/Gakuran---afraidly/refs/heads/main/animationtracker.lua"
		loadstring(game:HttpGet(url))()
	end)
	AnimationTracker = _G.AnimationTracker
end

if not AnimationTracker then
	warn("[AutoParry] AnimationTracker not found")
	return
end

local Tracker = AnimationTracker.new(IgnoreIds)
local LocalTracker = AnimationTracker.new(IgnoreIds)

-- ==========================================
-- Scheduler
-- ==========================================

local pendingTasks = {}
local function schedulerDelay(delay, callback)
	table.insert(pendingTasks, { executeAt = os.clock() + delay, callback = callback })
end
local function schedulerUpdate()
	local now = os.clock()
	for i = #pendingTasks, 1, -1 do
		if now >= pendingTasks[i].executeAt then
			local cb = pendingTasks[i].callback
			table.remove(pendingTasks, i)
			coroutine.wrap(cb)()
		end
	end
end

-- ==========================================
-- State Machine
-- ==========================================

local ParryState = {
	IDLE = 0,
	INPUT_PENDING = 1,
	PARRYING = 2,
	PARRYING_FAILED = 3,
	STUNNED = 4,
	WINDOW_EXCEEDED = 5,
	SUCCESS = 6,
}

local CurrentParryState = ParryState.IDLE
local KeyHeld = false
local ReleaseDeadline = 0
local InputRegisteredTime = nil
local ParryRegisteredTime = nil
local InputLatency = 0
local LastPendingRegData = nil
local AnimationRegistry = {}
local TargetCharacters = {}
local EspTrackers = {}
local CurrentIndex = 1

local EspSettings = {
	BoxMode = "static",
	ShowName = true,
	ShowDistance = true,
	ShowHealth = false,
	BoxThickness = 1,
	BoxColor = Color3.fromRGB(255, 50, 50),
	NameColor = Color3.fromRGB(255, 255, 255),
	DistanceColor = Color3.fromRGB(180, 180, 180),
	HealthColor = Color3.fromRGB(100, 255, 100),
	TextSize = 12,
}
_G.GakuranEspSettings = EspSettings

local COLOR_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_RED = Color3.fromRGB(255, 50, 50)
local COLOR_GREEN = Color3.fromRGB(50, 255, 50)

-- ==========================================
-- Helpers
-- ==========================================

local function safeGet(fn)
	local ok, v = pcall(fn)
	if ok then
		return v
	end
	return nil
end

local function GetPingValue()
	local ok, val = pcall(function()
		return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and val or 0
end

local function GetLocalHRP()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local mouse = nil
pcall(function()
	mouse = LocalPlayer:GetMouse()
end)

local function IsCombatCharacter(model)
	if not model then return false end
	local class = model.ClassName
	if class ~= "Model" then return false end
	local hum = model:FindFirstChildWhichIsA("Humanoid")
	if not hum then return false end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local maxHP = hum.MaxHealth or 0
	if maxHP < 50 then return false end
	return true
end

local function GetAllFoldersInWorkspace()
	local folders = {}
	pcall(function()
		for _, f in ipairs(Workspace:GetChildren()) do
			if f.ClassName == "Folder" then
				local hasCombatChar = false
				for _, child in ipairs(f:GetChildren()) do
					if IsCombatCharacter(child) then
						hasCombatChar = true
						break
					end
				end
				if hasCombatChar then
					table.insert(folders, f.Name)
				end
			end
		end
	end)
	return folders
end

local function GetAllCharactersInFolder()
	if not SelectedFolder then
		return {}
	end
	local folderInst = Workspace:FindFirstChild(SelectedFolder)
	if not folderInst then
		return {}
	end
	local localChar = LocalPlayer.Character
	local localAddr = localChar and localChar.Address
	local chars = {}
	for _, child in ipairs(folderInst:GetChildren()) do
		if IsCombatCharacter(child) then
			if not IncludeLocalCharacter and child.Address == localAddr then
				continue
			end
			table.insert(chars, child)
		end
	end
	return chars
end

local function GetHeightMultiplierForCharacter(targetChar)
	local ok, h = pcall(function()
		local sf = targetChar and targetChar:FindFirstChild("PlayerData")
		return sf and sf:GetAttribute("CurrentHeight") or 1
	end)
	return ok and h or 1
end

local function GetActiveAnimsDict(character)
	local result = {}
	local tracks = Tracker:Update(character)
	if not tracks or #tracks == 0 then
		return result
	end
	for _, anim in ipairs(tracks) do
		if anim.AnimationId then
			result[anim.AnimationId] = anim
		end
	end
	return result
end

-- ==========================================
-- Block / Dodge
-- ==========================================

local AutoParryEnabled = false
local DebugAnimsEnabled = false
local DebugPrintedAnims = {}
local LogAllAnims = false
local LoggedAnimIds = {}

local function Dodge()
	KeyHeld = false
	keyrelease(PARRY_KEY)
	for i = 1, 12 do
		keypress(DODGE_KEY)
		keyrelease(DODGE_KEY)
	end
end

local function BlockStart(startTime, holdFor)
	if not startTime then
		return
	end
	if CurrentParryState ~= ParryState.IDLE then
		CurrentParryState = ParryState.IDLE
	end
	local hold = holdFor or BlockHoldTime
	ReleaseDeadline = startTime + hold
	if KeyHeld and AutoParryEnabled then
		keyrelease(PARRY_KEY)
	end
	KeyHeld = true
	if AutoParryEnabled then
		keypress(PARRY_KEY)
	end
end

local function BlockEnd()
	KeyHeld = false
	if AutoParryEnabled then
		keyrelease(PARRY_KEY)
	end
end

local function ResetParryState()
	KeyHeld = false
	ReleaseDeadline = 0
	BlockEnd()
end

-- ==========================================
-- Parry Timing
-- ==========================================

local PingCompensate = true
local HeightToggle = false

local function CalculateParryTiming(attackConfig, startTime, targetChar)
	local optimalReactionTime = attackConfig.ReactionTime or DefaultReactionTime
	local heightMultiplier = 1
	if HeightToggle then
		heightMultiplier = GetHeightMultiplierForCharacter(targetChar) or 1
	end
	if PingCompensate then
		local pingMs = GetPingValue()
		optimalReactionTime = optimalReactionTime - (pingMs / 1000) * 0.5
	end
	local adjusted = (optimalReactionTime * heightMultiplier) + ParryOffset
	return startTime + adjusted, startTime + adjusted + ParryWindow
end

-- ==========================================
-- Direction Check
-- ==========================================

local TargetFacingYou = false
local YouFacingTarget = true

local function CheckDirection(character, localChar, localRoot, targetRoot, attackConfig)
	if character.Address == localChar.Address then
		return true
	end
	local offset = targetRoot.Position - localRoot.Position
	local distance = offset.Magnitude
	if distance < 0.1 then return true end
	local isHeavy = attackConfig.DisplayName == "M2" or attackConfig.DisplayName == "Heavy"
	if not isHeavy then
		local localForward = localRoot.CFrame.LookVector
		local targetForward = targetRoot.CFrame.LookVector
		local dirUnit = offset / distance
		if YouFacingTarget then
			local forwardDist = localForward:Dot(dirUnit)
			local rightVector = Vector3.new(localForward.Z, 0, -localForward.X).Unit
			local sideDist = math.abs(rightVector:Dot(dirUnit))
			local maxSide = math.clamp(distance * 0.6, 3, 12)
			if forwardDist < 0 or sideDist > maxSide then
				return false
			end
		end
		if TargetFacingYou then
			local targetDir = -dirUnit
			local tForwardDist = targetForward:Dot(targetDir)
			local tRightVector = Vector3.new(targetForward.Z, 0, -targetForward.X).Unit
			local tSideDist = math.abs(tRightVector:Dot(targetDir))
			local tMaxSide = math.clamp(distance * 0.6, 3, 12)
			if tForwardDist < 0 or tSideDist > tMaxSide then
				return false
			end
		end
	end
	return true
end

-- ==========================================
-- Parry Evaluation
-- ==========================================

local ConstLatency = 0.018
local EXECUTE_DEBOUNCE = 0.15
local AutoDodgeEnabled = true

local function UpdateAnimationRegistry(animKey, anim, now, currentTrackTime, attackConfig, targetChar)
	local reg = AnimationRegistry[animKey]

	if reg and reg.AnimationId ~= anim.AnimationId then
		reg = nil
		AnimationRegistry[animKey] = nil
	end

	if not reg then
		local adjustedNow = now - ConstLatency
		local blockStart, blockExpire = CalculateParryTiming(attackConfig, adjustedNow, targetChar)
		reg = {
			StartTime = adjustedNow,
			Processed = false,
			CurrentTrackTime = currentTrackTime,
			AnimationId = anim.AnimationId,
			DidALoop = false,
			BlockStart = blockStart,
			BlockExpire = blockExpire,
			RandomNum = math.random(1, 100),
			LastExecuteTime = 0,
		}
		AnimationRegistry[animKey] = reg
	end

	if reg.CurrentTrackTime and (currentTrackTime < reg.CurrentTrackTime) then
		local blockStart, blockExpire = CalculateParryTiming(attackConfig, now - currentTrackTime, targetChar)
		reg.Processed = false
		reg.DidALoop = true
		reg.BlockStart = blockStart
		reg.BlockExpire = blockExpire
		reg.StartTime = now - ConstLatency
	end
	reg.CurrentTrackTime = currentTrackTime
	return reg
end

local function ExecuteParry(reg, attackConfig, animIdStr)
	local now = os.clock()
	if (now - reg.LastExecuteTime) < EXECUTE_DEBOUNCE then
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | DEBOUNCE_SKIP | %.3fs since last | %s",
				attackConfig.DisplayName, now - reg.LastExecuteTime, animIdStr))
		end
		return
	end
	reg.LastExecuteTime = now

	local isHeavy = attackConfig.DisplayName == "M2" or attackConfig.DisplayName == "Heavy"

	if isHeavy and AutoDodgeEnabled then
		if AutoParryEnabled then
			Dodge()
			if LogAllAnims then
				print(string.format("[AutoParry ACTION] %s | DODGE | %s | %s",
					attackConfig.DisplayName, animIdStr, attackConfig.Style))
			end
		end
	else
		if LastPendingRegData ~= reg then
			LastPendingRegData = reg
			BlockStart(reg.BlockStart)
			if LogAllAnims then
				print(string.format("[AutoParry ACTION] %s | BLOCK | %s | %s",
					attackConfig.DisplayName, animIdStr, attackConfig.Style))
			end
		elseif reg.DidALoop then
			reg.DidALoop = false
			BlockStart(reg.BlockStart)
			if LogAllAnims then
				print(string.format("[AutoParry ACTION] %s | BLOCK (loop) | %s | %s",
					attackConfig.DisplayName, animIdStr, attackConfig.Style))
			end
		end
	end
end

local function BoxingM2Parry(reg)
	if reg.Processed then
		return
	end
	reg.Processed = true
	if LogAllAnims then
		print("[AutoParry ACTION] BoxingM2 | CUSTOM PARRY (block + dodge)")
	end
	schedulerDelay(0.4, function()
		BlockStart(os.clock(), 0.5)
		schedulerDelay(0.3, function()
			Dodge()
		end)
	end)
end

local function EvaluateAnimation(anim, character, localChar, localRoot, targetRoot, currentActiveIds)
	if not anim.AnimationId then
		return
	end
	local animIdStr = tostring(anim.AnimationId)
	local attackConfig = GameConfig[animIdStr]
	if not attackConfig then
		if DebugAnimsEnabled then
			local charName = character and character.Name or "?"
			local key = charName .. animIdStr
			if not DebugPrintedAnims[key] then
				DebugPrintedAnims[key] = true
				print(string.format("[AutoParry DEBUG] Unknown anim on %s: %s (Name: %s, TimePos: %.2f)",
					charName, animIdStr, tostring(anim.Name), anim.TimePosition or 0))
			end
		end
		if LogAllAnims then
			local charName = character and character.Name or "?"
			local key = charName .. animIdStr
			if not LoggedAnimIds[key] then
				LoggedAnimIds[key] = true
				print(string.format("[AutoParry ALL] %s | ID: %s | Name: %s | TimePos: %.3f | UNKNOWN",
					charName, animIdStr, tostring(anim.Name), anim.TimePosition or 0))
			end
		end
		return
	end

	if LogAllAnims then
		local charName = character and character.Name or "?"
		local key = charName .. animIdStr
		if not LoggedAnimIds[key] then
			LoggedAnimIds[key] = true
			print(string.format("[AutoParry ALL] %s | ID: %s | Name: %s | TimePos: %.3f | %s | RT: %.2fs",
				charName, animIdStr, tostring(anim.Name), anim.TimePosition or 0,
				attackConfig.Style, attackConfig.ReactionTime or DefaultReactionTime))
		end
	end

	local animKey = anim.Address or anim
	currentActiveIds[animKey] = true

	local now = os.clock()
	local reg = UpdateAnimationRegistry(animKey, anim, now, anim.TimePosition or 0, attackConfig, character)
	if reg.Processed then
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | SKIP (already processed) | %s | %s",
				attackConfig.DisplayName, animIdStr, attackConfig.Style))
		end
		return
	end

	local dist = (targetRoot.Position - localRoot.Position).Magnitude
	if dist > AutoParryRange then
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | SKIP (out of range %.1f > %d) | %s | %s",
				attackConfig.DisplayName, dist, AutoParryRange, animIdStr, attackConfig.Style))
		end
		return
	end

	if attackConfig.ParryFunction == "BoxingM2" then
		if (now - reg.StartTime) <= (attackConfig.ReactionTime or DefaultReactionTime) + ParryWindow / 2 then
			if AutoParryEnabled then
				BoxingM2Parry(reg)
			end
		end
		return
	end

	if not CheckDirection(character, localChar, localRoot, targetRoot, attackConfig) then
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | SKIP (wrong direction) | %s | %s",
				attackConfig.DisplayName, animIdStr, attackConfig.Style))
		end
		return
	end

	if reg.RandomNum > ProbabilityToParry then
		reg.Processed = true
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | SKIP (probability %d > %d) | %s | %s",
				attackConfig.DisplayName, reg.RandomNum, ProbabilityToParry, animIdStr, attackConfig.Style))
		end
		return
	end

	local blockExpireTimer = reg.BlockExpire - now
	if now >= reg.BlockStart and blockExpireTimer >= 0 then
		ExecuteParry(reg, attackConfig, animIdStr)
	else
		if LogAllAnims then
			print(string.format("[AutoParry ACTION] %s | SKIP (not in block window: now=%.3f start=%.3f expire=%.3f) | %s | %s",
				attackConfig.DisplayName, now, reg.BlockStart, reg.BlockExpire, animIdStr, attackConfig.Style))
		end
	end
end

local lastLogScan = 0
local function LogTargetAnimations()
	if not SelectedFolder then return end
	local now = os.clock()
	if now - lastLogScan < 0.016 then return end
	lastLogScan = now

	local folderInst = Workspace:FindFirstChild(SelectedFolder)
	if not folderInst then return end

	for _, character in ipairs(folderInst:GetChildren()) do
		if not character or not character.Parent then continue end
		if not IsCombatCharacter(character) then continue end

		local activeAnims = GetActiveAnimsDict(character)
		for _, anim in pairs(activeAnims) do
			if not anim.AnimationId then continue end
			local animIdStr = tostring(anim.AnimationId)
			local charName = character.Name or "?"
			local key = charName .. animIdStr
			if LoggedAnimIds[key] then continue end
			LoggedAnimIds[key] = true

			local attackConfig = GameConfig[animIdStr]
			if attackConfig then
				print(string.format("[AutoParry ALL] %s | ID: %s | Name: %s | TimePos: %.3f | %s | %s | RT: %.2fs",
					charName, animIdStr, tostring(anim.Name), anim.TimePosition or 0,
					attackConfig.Style, attackConfig.DisplayName, attackConfig.ReactionTime or DefaultReactionTime))
			else
				print(string.format("[AutoParry ALL] %s | ID: %s | Name: %s | TimePos: %.3f | UNKNOWN",
					charName, animIdStr, tostring(anim.Name), anim.TimePosition or 0))
			end
		end
	end
end

local function EvaluateParryTriggers()
	local localChar = LocalPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	LocalTracker:Update(localChar)

	local localAnimIds = {}
	for _, anim in ipairs(LocalTracker:Update(localChar)) do
		if anim.AnimationId then
			localAnimIds[tostring(anim.AnimationId)] = true
		end
	end

	local currentActiveIds = {}
	for _, character in ipairs(TargetCharacters) do
		if not character or not character.Parent then
			continue
		end
		local targetRoot = character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			continue
		end

		local dist = (targetRoot.Position - localRoot.Position).Magnitude
		local tracker = EspTrackers[character]
		if tracker and tracker.ChangeText then
			if dist <= AutoParryRange then
				tracker:ChangeText("Name", character.Name .. " IN RANGE", COLOR_GREEN)
			else
				tracker:ChangeText("Name", character.Name, EspSettings.NameColor)
			end
		end

		local activeAnims = GetActiveAnimsDict(character)
		for animKey, anim in pairs(activeAnims) do
			currentActiveIds[animKey] = true
			local animIdStr = tostring(anim.AnimationId)
			if not localAnimIds[animIdStr] then
				EvaluateAnimation(anim, character, localChar, localRoot, targetRoot, currentActiveIds)
			else
				if LogAllAnims then
					local key = character.Name .. animIdStr
					if not LoggedAnimIds[key] then
						LoggedAnimIds[key] = true
						print(string.format("[AutoParry ALL] %s | ID: %s | Name: %s | TimePos: %.3f | SHARED (on local too)",
							character.Name, animIdStr, tostring(anim.Name), anim.TimePosition or 0))
					end
				end
			end
		end
	end

	for key, val in pairs(AnimationRegistry) do
		if not currentActiveIds[key] then
			AnimationRegistry[key] = nil
			if LastPendingRegData == val then
				LastPendingRegData = nil
			end
		end
	end
end

-- ==========================================
-- Parry State Machine
-- ==========================================

local function OnInputF()
	if CurrentParryState == ParryState.IDLE then
		InputRegisteredTime = os.clock()
		CurrentParryState = ParryState.INPUT_PENDING
	end
end

local function OnParryingAnimationSuccess()
	if CurrentParryState == ParryState.INPUT_PENDING then
		ParryRegisteredTime = os.clock()
		InputLatency = os.clock() - InputRegisteredTime
		CurrentParryState = ParryState.PARRYING
	end
end

local function OnSuccessfulParry()
	if CurrentParryState == ParryState.PARRYING then
		if LastPendingRegData then
			local attackConfig = GameConfig[LastPendingRegData.AnimationId]
			if attackConfig then
				pcall(function()
					Lib:Notify(
						"Parry Success",
						string.format("%s %s", attackConfig.Style, attackConfig.DisplayName),
						2,
						"success"
					)
				end)
			end
		end
		ResetParryState()
		CurrentParryState = ParryState.IDLE
	end
end

local function onLocalAnimationAdded(anim)
	local animId = anim.AnimationId
	if table.find(ParriedAnimation, animId) then
		OnSuccessfulParry()
	end
	if table.find(ParryingAnimation, animId) then
		if InputRegisteredTime then
			OnParryingAnimationSuccess()
		end
	end
	if table.find(ParryFailed, animId) then
		if CurrentParryState == ParryState.PARRYING or CurrentParryState == ParryState.INPUT_PENDING then
			BlockEnd()
			CurrentParryState = ParryState.IDLE
		end
	end
	if GameConfig[animId] then
		if CurrentParryState ~= ParryState.STUNNED then
			CurrentParryState = ParryState.STUNNED
		end
		schedulerDelay(0.4, function()
			BlockEnd()
			CurrentParryState = ParryState.IDLE
		end)
	end
end

local animAddedConn = LocalTracker.AnimationAdded:Connect(onLocalAnimationAdded)

local function ParryTask()
	local now = os.clock()
	if KeyHeld and now > ReleaseDeadline then
		BlockEnd()
	end

	if CurrentParryState == ParryState.INPUT_PENDING then
		local maxLatency = 0.5
		local timePassed = now - InputRegisteredTime

		local activeAnims = GetActiveAnimsDict(LocalPlayer.Character)
		for _, v in pairs(activeAnims) do
			if table.find(ParryingAnimation, v.AnimationId) then
				OnParryingAnimationSuccess()
				break
			end
		end

		if not iskeypressed(PARRY_KEY) then
			ResetParryState()
			CurrentParryState = ParryState.IDLE
		end

		if timePassed > maxLatency then
			CurrentParryState = ParryState.IDLE
		end
	elseif CurrentParryState == ParryState.PARRYING then
		local windowEnd = ParryRegisteredTime + ParryWindow + 0.3
		if now > windowEnd then
			CurrentParryState = ParryState.IDLE
		end
	end
end

-- ==========================================
-- Target Cycling & ESP
-- ==========================================

local function ClearAllEspTrackers()
	if not ESP_Utility then return end
	for char, tracker in pairs(EspTrackers) do
		if tracker and tracker.Object and tracker.Object.Address then
			ESP_Utility.TrackersToUpdate[tracker.Object.Address] = nil
		end
		if tracker and tracker.Destroy then
			pcall(function() tracker:Destroy() end)
		end
	end
	EspTrackers = {}
end

local function UpdateTargetCharacters(charactersList)
	ClearAllEspTrackers()
	TargetCharacters = {}
	for _, character in ipairs(charactersList) do
		table.insert(TargetCharacters, character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and ESP_Utility then
			pcall(function()
				local tracker = ESP_Utility.NewTracker(hrp, character.Name, EspSettings.BoxColor)
				if tracker then
					if tracker.Drawings and tracker.Drawings["Square"] then
						tracker.Drawings["Square"].Drawing.Thickness = EspSettings.BoxThickness
					end
					tracker:AddText("CurrentlyPlaying", nil, "???")
				end
				EspTrackers[character] = tracker
			end)
		end
	end
end

local AutoTargetNearest = false
local MultiTarget = true
local UseMouseTarget = true

local function GetMouseWorldPos()
	if not mouse then return nil end
	local ok, hit = pcall(function() return mouse.Hit end)
	if not ok or not hit then return nil end
	return hit.Position
end

local function IsAlreadyTargeted(char)
	for _, existing in ipairs(TargetCharacters) do
		if existing == char then return true end
	end
	return false
end

local function CycleEvent()
	local allCharacters = GetAllCharactersInFolder()
	if not SelectedFolder or #allCharacters == 0 then
		if #TargetCharacters > 0 then
			UpdateTargetCharacters({})
		end
		if not AutoTargetNearest then
			pcall(function() Lib:Notify("Cycle", "No targets found", 2, "warning") end)
		end
		return
	end

	local localChar = LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	local valid = {}
	for _, char in ipairs(allCharacters) do
		local targetRoot = char:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			local dist = (localRoot.Position - targetRoot.Position).Magnitude
			if dist <= MaxCycleRange then
				table.insert(valid, { Character = char, Distance = dist, Root = targetRoot })
			end
		end
	end

	if #valid == 0 then
		if #TargetCharacters > 0 then
			CurrentIndex = 1
			UpdateTargetCharacters({})
		end
		if not AutoTargetNearest then
			pcall(function() Lib:Notify("Cycle", "No targets in range [" .. MaxCycleRange .. " studs]", 2, "warning") end)
		end
		return
	end

	if AutoTargetNearest then
		table.sort(valid, function(a, b) return a.Distance < b.Distance end)
		if MultiTarget then
			local finalTargets = {}
			for i = 1, math.min(3, #valid) do
				table.insert(finalTargets, valid[i].Character)
			end
			local sameSet = #finalTargets == #TargetCharacters
			if sameSet then
				local existing = {}
				for _, c in ipairs(TargetCharacters) do existing[c] = true end
				for _, c in ipairs(finalTargets) do
					if not existing[c] then sameSet = false break end
				end
			end
			if not sameSet then
				UpdateTargetCharacters(finalTargets)
			end
		else
			local nearest = valid[1].Character
			if IsAlreadyTargeted(nearest) then return end
			UpdateTargetCharacters({ nearest })
		end
		return
	end

	if UseMouseTarget and not MultiTarget then
		local mouseWorldPos = GetMouseWorldPos()
		if mouseWorldPos then
			local bestChar = nil
			local bestDist = math.huge
			for _, v in ipairs(valid) do
				local charPos = v.Root.Position
				local md = (charPos - mouseWorldPos).Magnitude
				if md < bestDist then
					bestDist = md
					bestChar = v.Character
				end
			end
			if bestChar then
				if IsAlreadyTargeted(bestChar) then
					for i, v in ipairs(valid) do
						if v.Character == bestChar then CurrentIndex = i break end
					end
					local nextIdx = (CurrentIndex % #valid) + 1
					bestChar = valid[nextIdx].Character
				end
				UpdateTargetCharacters({ bestChar })
				pcall(function() Lib:Notify("Cycle", "Locked: " .. bestChar.Name, 2, "info") end)
				return
			end
		end
	end

	table.sort(valid, function(a, b) return a.Distance < b.Distance end)

	if MultiTarget then
		local finalTargets = {}
		for i = 1, math.min(3, #valid) do
			table.insert(finalTargets, valid[i].Character)
		end
		UpdateTargetCharacters(finalTargets)
		pcall(function() Lib:Notify("Cycle", string.format("%d targets locked", #finalTargets), 2, "success") end)
	else
		CurrentIndex = (CurrentIndex % #valid) + 1
		local selected = valid[CurrentIndex].Character
		UpdateTargetCharacters({ selected })
		pcall(function() Lib:Notify("Cycle", "Locked: " .. selected.Name, 2, "info") end)
	end
end

-- ==========================================
-- Orb Listener
-- ==========================================

local orbConnection = nil
local lastOrbParry = 0
local lastOrbCheck = 0

local function StartOrbListener()
	if orbConnection then
		return
	end
	orbConnection = RS.Heartbeat:Connect(function()
		if not AutoParryEnabled then return end
		local now = os.clock()
		if now - lastOrbCheck < 0.1 then return end
		lastOrbCheck = now

		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local myPos = hrp.Position
		local thrown = Workspace:FindFirstChild("Thrown")
		if not thrown then return end
		for _, v in ipairs(thrown:GetChildren()) do
			if (v.name == "ArdourBall2" or v.name == "ArdourBall") and v:IsA("BasePart") then
				local dist = (myPos - v.Position).Magnitude
				if dist <= PARRY_DISTANCE and (tick() - lastOrbParry >= 0.08) then
					lastOrbParry = tick()
					BlockStart(os.clock(), 0.3)
					BlockEnd()
					break
				end
			end
		end
	end)
end

-- ==========================================
-- UI
-- ==========================================

Lib:Category("COMBAT")
local combatTab = Win:Tab("Combat", "swords")

local apParrySub = combatTab:Sub("Auto-Parry", "shield")
local apSetSec = apParrySub:Section("Settings", "Left")
local apCondSec = apParrySub:Section("Conditions", "Left")
local apFolSec = apParrySub:Section("Folders", "Right")
local apLogSec = apParrySub:Section("Logging", "Right")

apSetSec:Label("X = target who you're looking at | F = manual parry")

local apToggle = apSetSec:Toggle("auto parry", false, function(v)
	AutoParryEnabled = v
	if v then
		CycleEvent()
	else
		BlockEnd()
		CurrentParryState = ParryState.IDLE
		UpdateTargetCharacters({})
	end
end)

apToggle:AddKeybind(nil, "Toggle", function(state)
	apToggle:Set(state)
end)

apSetSec:Toggle("auto dodge", true, function(v)
	AutoDodgeEnabled = v
end)

apSetSec:Toggle("multiple targets", true, function(v)
	MultiTarget = v
	if v then
		CycleEvent()
	end
end)

apSetSec:Toggle("auto target nearest", false, function(v)
	AutoTargetNearest = v
	if v then
		CycleEvent()
	end
end)

apSetSec:Toggle("mouse targeting", true, function(v)
	UseMouseTarget = v
end)

apCondSec:Toggle("target facing you", false, function(v)
	TargetFacingYou = v
end)

apCondSec:Toggle("you facing target", true, function(v)
	YouFacingTarget = v
end)

apCondSec:Toggle("height multiplier", false, function(v)
	HeightToggle = v
end)

apCondSec:Toggle("ping compensate", true, function(v)
	PingCompensate = v
end)

apFolSec:Label("Target Pool: None")

local folderNames = GetAllFoldersInWorkspace()
apFolSec:Dropdown("live folder", nil, folderNames, false, function(list)
	if list and list[1] then
		SelectedFolder = list[1]
	end
end)

if table.find(folderNames, "Players") then
	SelectedFolder = "Players"
elseif table.find(folderNames, "Live") then
	SelectedFolder = "Live"
elseif #folderNames > 0 then
	SelectedFolder = folderNames[1]
end

apFolSec:Slider("parry range", 40, 1, 3, 80, "", function(v)
	AutoParryRange = v
end)

apFolSec:Slider("max cycle range", 80, 1, 5, 100, "", function(v)
	MaxCycleRange = v
end)

apFolSec:Slider("parry window", 20, 1, 5, 100, "%", function(v)
	ParryWindow = v / 100
end)

apFolSec:Slider("block hold time", 27, 1, 10, 80, "%", function(v)
	BlockHoldTime = v / 100
end)

apFolSec:Slider("probability", 100, 1, 1, 100, "%", function(v)
	ProbabilityToParry = v
end)

apFolSec:Toggle("include local char", false, function(v)
	IncludeLocalCharacter = v
end)

-- Visuals sub-tab
local visSub = combatTab:Sub("Visuals", "eye")
local espBoxSec = visSub:Section("Box", "Left")
local espTextSec = visSub:Section("Text", "Left")
local espColSec = visSub:Section("Colors", "Right")
local miscSec = visSub:Section("Misc", "Right")

espBoxSec:Slider("box thickness", 1, 1, 1, 5, "", function(v)
	EspSettings.BoxThickness = v
end)

espTextSec:Toggle("show name", true, function(v)
	EspSettings.ShowName = v
end)

espTextSec:Toggle("show distance", true, function(v)
	EspSettings.ShowDistance = v
end)

espTextSec:Toggle("show health bar", false, function(v)
	EspSettings.ShowHealth = v
end)

espTextSec:Slider("text size", 12, 1, 8, 24, "", function(v)
	EspSettings.TextSize = v
end)

espColSec:Colorpicker("box color", Color3.fromRGB(255, 50, 50), function(c)
	EspSettings.BoxColor = c
end)

espColSec:Colorpicker("name color", Color3.fromRGB(255, 255, 255), function(c)
	EspSettings.NameColor = c
end)

espColSec:Colorpicker("distance color", Color3.fromRGB(180, 180, 180), function(c)
	EspSettings.DistanceColor = c
end)

local FovEnabled = false
local FovValue = 70
local defaultFov = 70

pcall(function()
	local cam = Workspace.CurrentCamera
	if cam then defaultFov = cam.FieldOfView or 70 end
end)

miscSec:Toggle("custom fov", false, function(v)
	FovEnabled = v
	if v then
		pcall(function()
			Workspace.CurrentCamera.FieldOfView = FovValue
		end)
	else
		pcall(function()
			Workspace.CurrentCamera.FieldOfView = defaultFov
		end)
	end
end)

miscSec:Slider("fov", 70, 1, 1, 120, "", function(v)
	FovValue = v
	if FovEnabled then
		pcall(function()
			Workspace.CurrentCamera.FieldOfView = v
		end)
	end
end)

-- Style config tab
local styleSub = combatTab:Sub("Styles", "crown")
local defSec = styleSub:Section("Default Configuration", "Left")

defSec:Slider("parry offset", 0, 0.01, -0.1, 0.1, "s", function(v)
	ParryOffset = v
end)
defSec:Label("Negative = parry earlier, Positive = parry later")

local groupedStyles = {}
for assetId, info in pairs(GameConfig) do
	local styleName = info.Style or "Unknown"
	if not groupedStyles[styleName] then
		groupedStyles[styleName] = {}
	end
	groupedStyles[styleName][assetId] = info
end

local counter = 1
for styleName, animations in pairs(groupedStyles) do
	local side = (counter % 2 == 1) and "Left" or "Right"
	local styleSec = styleSub:Section(styleName, side)
	for assetId, info in pairs(animations) do
		local name = info.DisplayName or tostring(assetId)
		if info.ParryFunction then
			styleSec:Label(name .. " (uses custom function)")
			continue
		end
		local rt = info.ReactionTime or DefaultReactionTime
		styleSec:Slider("RT: " .. name, rt, 0.01, 0, 1, "s", function(v)
			if v ~= DefaultReactionTime then
				info.ReactionTime = v
			end
		end)
	end
	counter = counter + 1
end

local debugSec = styleSub:Section("Debug", "Left")
debugSec:Toggle("log unknown anims", false, function(v)
	DebugAnimsEnabled = v
	DebugPrintedAnims = {}
end)
debugSec:Toggle("log all target anims", false, function(v)
	LogAllAnims = v
	LoggedAnimIds = {}
end)
debugSec:Button("clear log cache", function()
	DebugPrintedAnims = {}
	LoggedAnimIds = {}
end)

-- ==========================================
-- Input
-- ==========================================

local lastXCycle = 0

local inputBeganConn = UIS.InputBegan:Connect(function(input, gameProcessed)
	local pg = LocalPlayer.PlayerGui
	if pg and pg:FindFirstChild("RhythmServiceUI") then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		local localChar = LocalPlayer.Character
		if localChar then
			LocalTracker:Update(localChar)
		end
		OnInputF()
	end
end)

-- ==========================================
-- Main Loop
-- ==========================================

local lastCycleCheck = 0

local parryConn = RS.Heartbeat:Connect(function()
	if not isrbxactive() then return end

	if iskeypressed(0x58) then
		local now = os.clock()
		if now - lastXCycle > 0.3 then
			lastXCycle = now
			CycleEvent()
		end
	end

	if LogAllAnims or DebugAnimsEnabled then
		LogTargetAnimations()
	end

	if not AutoParryEnabled then return end

	local pg = LocalPlayer.PlayerGui
	if pg and pg:FindFirstChild("RhythmServiceUI") then return end

	EvaluateParryTriggers()
	ParryTask()
	schedulerUpdate()

	local now = os.clock()
	if now - lastCycleCheck >= 0.5 then
		lastCycleCheck = now
		if AutoTargetNearest then
			CycleEvent()
		end
	end
end)

-- Start orb listener
pcall(function()
	StartOrbListener()
end)

-- ==========================================
-- Cleanup
-- ==========================================

_G.GakuranParryCleanup = function()
	pcall(function() parryConn:Disconnect() end)
	pcall(function()
		if orbConnection then orbConnection:Disconnect() end
	end)
	pcall(function()
		if animAddedConn then animAddedConn:Disconnect() end
	end)
	pcall(function()
		if inputBeganConn then inputBeganConn:Disconnect() end
	end)
	pcall(function()
		if _G.GakranEspCleanup then _G.GakranEspCleanup() end
	end)
	if FovEnabled then
		pcall(function()
			Workspace.CurrentCamera.FieldOfView = defaultFov
		end)
	end
	BlockEnd()
	ClearAllEspTrackers()
	TargetCharacters = {}
	AnimationRegistry = {}
end

print("[AutoParry] Module initialized")
