-- ESP Utility (customized for Gakuran)
-- Reads settings from _G.GakuranEspSettings
-- Original by artxficial, modified by afraidly

local RunService = game:GetService("RunService")
local ESP_Utility = {}
local UpdateThread = nil
ESP_Utility.__index = ESP_Utility

ESP_Utility.TrackersToUpdate = {}

if _G.GakranEspCleanup then
	pcall(_G.GakranEspCleanup)
end

local function getSettings()
	return _G.GakuranEspSettings or {
		BoxMode = "bounding",
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
end

local cachedSettings = nil
local cachedSettingsTime = 0
local function getSettingsCached()
	local now = os.clock()
	if not cachedSettings or now - cachedSettingsTime > 0.5 then
		cachedSettings = getSettings()
		cachedSettingsTime = now
	end
	return cachedSettings
end

local function magnitude(p1, p2)
	local dx = p2.X - p1.X
	local dy = p2.Y - p1.Y
	local dz = p2.Z - p1.Z
	return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local BasePartTypes = {
	["Part"] = "BasePart",
	["MeshPart"] = "BasePart",
	["UnionOperation"] = "BasePart",
	["Model"] = "Model",
}

local function IsValidObject(Object)
	if type(Object) == "userdata" and Object and Object.ClassName then
		local Type = BasePartTypes[Object.ClassName]
		return Type
	end
	return nil
end

local function GetObjectFromModel(Model)
	local CommonNames = {"HumanoidRootPart","Root", "RootPart", "Core"}
	local Children = Model:GetChildren()

	for _, Name in CommonNames do
		for _, Child in Children do
			if string.lower(Child.Name) == string.lower(Name) and BasePartTypes[Child.ClassName] == "BasePart" then
				return Child
			end
		end
	end

	if Model.ClassName == "Model" then
		local PrimaryPart = Model.PrimaryPart
		return PrimaryPart
	end

	local LargestPart = nil
	local MaxVolume = 0

	for _, Child in ipairs(Model:GetChildren()) do
		if BasePartTypes[Child.ClassName] then
			local Volume = Child.Size.X * Child.Size.Y * Child.Size.Z
			if Volume > MaxVolume then
				MaxVolume = Volume
				LargestPart = Child
			end
		end
	end

	return LargestPart
end

function ESP_Utility.NewTracker(Object, CustomName, Color)
	local ObjectType = IsValidObject(Object)
	if not ObjectType then
		warn("[ERROR] The tracker only accepts models, baseparts, meshparts, or unions. || Received: ", Object)
		return
	end

	if ObjectType == "Model" then
		local Model = Object
		CustomName = CustomName or Object.Name
		Object = GetObjectFromModel(Model)
		if Object == nil then
			warn(string.format("[ERROR] Could not add Model: %s because it had no valid parts inside of it", Model.Name))
			return
		end
	end

	if ESP_Utility.TrackersToUpdate[Object.Address] then
		return ESP_Utility.TrackersToUpdate[Object.Address]
	end

	local self = setmetatable({}, ESP_Utility)
	self.Name = CustomName or Object.Name
	self.Object = Object
	self.Color = Color or Color3.fromRGB(255,255,255)
	self.Drawings = {}
	self.ObjectType = ObjectType
	self.DrawingOrder = {}
	self.Visible = true
	self.TrackerOffScreen = false

	self:BuildVisualTracker()

	ESP_Utility.TrackersToUpdate[Object.Address] = self
	return self
end

function ESP_Utility:_IsAlive()
	if not self.Object then return false end
	return self.Object.Parent ~= nil
end

local CORNER_OFFSETS = {
	Vector3.new(-1, -1, -1), Vector3.new( 1, -1, -1),
	Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
	Vector3.new(-1,  1, -1), Vector3.new( 1,  1, -1),
	Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
}

function ESP_Utility:_Get2D_Bounds()
	local S = getSettingsCached()
	local position = self.Object.Position
	local size = self.Object.Size

	if S.BoxMode == "static" then
		local ScreenCenter, CenterVisible = WorldToScreen(position)
		if not ScreenCenter then return nil end
		local cam = game.Workspace.CurrentCamera
		local dist = cam and (cam.CFrame.Position - position).Magnitude or 10
		local boxHeight = math.clamp(800 / dist, 20, 300)
		local boxWidth = boxHeight * 0.6
		local halfW = boxWidth * 0.5
		local halfH = boxHeight * 0.5
		return ScreenCenter.X - halfW, ScreenCenter.Y - halfH, ScreenCenter.X + halfW, ScreenCenter.Y + halfH
	end

	if self.ObjectType ~= "Model" then
		local half = size * 0.5
		local minX, minY =  math.huge,  math.huge
		local maxX, maxY = -math.huge, -math.huge

		for i = 1, 8 do
			local offset = CORNER_OFFSETS[i]
			local worldPos = Vector3.new(
				position.X + offset.X * half.X,
				position.Y + offset.Y * half.Y,
				position.Z + offset.Z * half.Z
			)

			local screenPos, onScreen = WorldToScreen(worldPos)
			if not onScreen then return nil end

			if screenPos.X < minX then minX = screenPos.X end
			if screenPos.Y < minY then minY = screenPos.Y end
			if screenPos.X > maxX then maxX = screenPos.X end
			if screenPos.Y > maxY then maxY = screenPos.Y end
		end
		return minX, minY, maxX, maxY
	end

	local ScreenCenter, CenterVisible = WorldToScreen(position)
	local ScreenTop, TopVisible = WorldToScreen(position + Vector3.new(0, size.Y * 0.5, 0))

	if not CenterVisible or not TopVisible then return nil end

	local Height = math.abs(ScreenCenter.Y - ScreenTop.Y) * 5
	local Width  = Height * 1.2
	local halfW  = Width  * 0.5
	local halfH  = Height * 0.5

	return
		ScreenCenter.X - halfW,
		ScreenCenter.Y - halfH,
		ScreenCenter.X + halfW,
		ScreenCenter.Y + halfH
end

function ESP_Utility:_GetDistance()
	local Character = game.Players.LocalPlayer.Character
	if not Character then return 0 end

	local HRP = Character.HumanoidRootPart
	if not HRP or not HRP.Parent then return 0 end

	return magnitude(HRP.Position, self.Object.Position)
end

function ESP_Utility:_Position(DrawingObject, Y_Offset)
	local Session = self.Session
	local S = getSettingsCached()
	local FontSize = S.TextSize or 20
	local Padding = 5

	local textLength = 0
	for line in string.gmatch(DrawingObject.Text, "[^\n]+") do
		local length = #line
		if length > textLength then
			textLength = length
		end
	end

	local estimatedWidth = textLength * (FontSize * 0.45)
	local manualCenterX = Session.CenterX - (estimatedWidth / 2)

	local FinalY = Session.TopY - Padding - ((Y_Offset + 1) * FontSize)

	DrawingObject.Center = false
	DrawingObject.Position = Vector2.new(manualCenterX, FinalY)
	DrawingObject.Size = FontSize
end

function ESP_Utility:_DetermineVisibility()
	local S = getSettingsCached()
	local isOffScreen = self.TrackerOffScreen
	local isVisible = self.Visible
	local shouldRender = isVisible and not isOffScreen

	for drawingName, data in self.Drawings do
		local DrawingObject = (type(data) == "table" and data.Drawing) or data

		if not shouldRender then
			DrawingObject.Visible = false
			continue
		end

		local visible = data.Visible

		if drawingName == "Name" and not S.ShowName then
			DrawingObject.Visible = false
			continue
		end
		if drawingName == "Distance" and not S.ShowDistance then
			DrawingObject.Visible = false
			continue
		end
		if drawingName == "HealthBar" and not S.ShowHealth then
			DrawingObject.Visible = false
			continue
		end
		if drawingName == "HealthBg" and not S.ShowHealth then
			DrawingObject.Visible = false
			continue
		end

		DrawingObject.Visible = visible
	end

	return shouldRender
end

function ESP_Utility:_Update()
	if not self or not self.Name or not self._IsAlive or not self._Get2D_Bounds then
		return
	end

	if not self:_IsAlive() or not self.ObjectType then
		if self.Destroy then
			self:Destroy()
		end
		return
	end

	local min_x, min_y, max_x, max_y = self:_Get2D_Bounds()
	self.TrackerOffScreen = (min_x == nil)

	if not self._DetermineVisibility then return end
	local ShouldRender = self:_DetermineVisibility()
	if not ShouldRender then return end

	local S = getSettingsCached()
	local boxWidth = max_x - min_x
	self.Session = {
		CenterX = min_x + (boxWidth / 2),
		TopY = min_y
	}

	if not self.Drawings or not self.Drawings["Square"] then return end
	local Square = self.Drawings["Square"].Drawing
	Square.Position = Vector2.new(min_x, min_y)
	Square.Size = Vector2.new(boxWidth, max_y - min_y)
	Square.Thickness = S.BoxThickness or 1
	Square.Color = S.BoxColor or self.Color

	if self.HealthBar and S.ShowHealth then
		local char = self.Object.Parent
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		local hp = hum and hum.Health or 0
		local maxHp = hum and hum.MaxHealth or 100
		local ratio = math.clamp(hp / maxHp, 0, 1)
		local barW = 3
		local barH = (max_y - min_y)
		local hpH = barH * ratio
		self.HealthBg.Position = Vector2.new(min_x - barW - 2, min_y)
		self.HealthBg.Size = Vector2.new(barW, barH)
		self.HealthBg.Visible = true
		self.HealthBar.Position = Vector2.new(min_x - barW - 2, min_y + (barH - hpH))
		self.HealthBar.Size = Vector2.new(barW, hpH)
		self.HealthBar.Visible = true
		if ratio > 0.5 then
			self.HealthBar.Color = Color3.fromRGB(50, 255, 50)
		elseif ratio > 0.25 then
			self.HealthBar.Color = Color3.fromRGB(255, 200, 50)
		else
			self.HealthBar.Color = Color3.fromRGB(255, 50, 50)
		end
	elseif self.HealthBar then
		self.HealthBar.Visible = false
		self.HealthBg.Visible = false
	end

	if not self.DrawingOrder then return end
	for _, TextReference in ipairs(self.DrawingOrder) do
		local Data = self.Drawings[TextReference]
		if not Data then continue end

		local DrawingObject = Data.Drawing
		local Callback = Data.Function

		if Callback then
			DrawingObject.Text = Callback()
		end

		if TextReference == "Name" then
			DrawingObject.Color = S.NameColor or self.Color
		elseif TextReference == "Distance" then
			DrawingObject.Color = S.DistanceColor or Color3.fromRGB(180, 180, 180)
		end

		if not self._Position then return end
		self:_Position(DrawingObject, Data.Y_Offset)
	end
end

function ESP_Utility:_CreateSquare()
	local S = getSettings()
	local NewSquare = Drawing.new("Square")
	NewSquare.Size = Vector2.new(10,10)
	NewSquare.Color = S.BoxColor or self.Color
	NewSquare.Filled = false
	NewSquare.Thickness = S.BoxThickness or 1
	if self.ObjectType == "Model" then NewSquare.Visible = false end
	self.Drawings["Square"] = {
		Drawing = NewSquare,
		Visible = true,
	}
end

local function GetLineCount(text)
	local _, count = string.gsub(tostring(text or ""), "\n", "")
	return count + 1
end

function ESP_Utility:RecalculateOffsets()
	local S = getSettings()
	local totalLines = 0
	local FontSize = S.TextSize or 12

	for _, reference in ipairs(self.DrawingOrder) do
		local data = self.Drawings[reference]
		if data and data.LineCount then
			data.Y_Offset = totalLines + data.LineCount - 1
			totalLines = totalLines + data.LineCount
		end
	end
end

function ESP_Utility:AddText(Reference, NewColor, Value, Callback)
	if self.Drawings[Reference] then
		return
	end

	if not self.DrawingOrder then
		self.DrawingOrder = {}
	end

	local S = getSettings()
	local NewText = Drawing.new("Text")
	NewText.Text = Value or "Callback passed, uninitialized"
	NewText.Center = false
	NewText.Outline = true
	NewText.Color = NewColor or Color3.fromRGB(200, 200, 200)
	NewText.Size = S.TextSize or 12

	local currentText = tostring((Callback and Callback()) or Value or "")
	local currentLineCount = GetLineCount(currentText)

	self.Drawings[Reference] = {
		Drawing = NewText,
		Function = Callback,
		Y_Offset = 0,
		LineCount = currentLineCount,
		Visible = true,
	}

	table.insert(self.DrawingOrder, Reference)

	self:RecalculateOffsets()
end

function ESP_Utility:ChangeText(Reference, Value, NewColor)
	local TextData = self.Drawings[Reference]

	if not TextData or not TextData.LineCount then
		warn("Attempting to change text of a non-text object")
		return
	end

	if TextData.Function ~= nil then
		warn(string.format(
			"TEXT: %s already has a callback assigned, remove it to use :ChangeText",
			Reference
		))
		return
	end

	local TextDrawing = TextData.Drawing

	if Value then
		TextDrawing.Text = Value
		TextData.LineCount = GetLineCount(Value)
		self:RecalculateOffsets()
	end

	if NewColor then
		TextDrawing.Color = NewColor
	end
end

function ESP_Utility:BuildVisualTracker()
	self:_CreateSquare()

	local S = getSettings()

	self:AddText("Distance", S.DistanceColor or Color3.fromRGB(180, 180, 180), "ok", function()
		return "["..math.floor(self:_GetDistance()).."m]"
	end)

	local NameString = self.Name..(self.ObjectType == "Model" and " [M]" or "")
	self:AddText("Name", S.NameColor or self.Color, NameString)

	local healthBar = Drawing.new("Square")
	healthBar.Filled = true
	healthBar.Color = S.HealthColor or Color3.fromRGB(100, 255, 100)
	healthBar.Visible = false
	healthBar.ZIndex = 10
	self.HealthBar = healthBar

	local healthBg = Drawing.new("Square")
	healthBg.Filled = true
	healthBg.Color = Color3.fromRGB(0, 0, 0)
	healthBg.Transparency = 0.5
	healthBg.Visible = false
	healthBg.ZIndex = 9
	self.HealthBg = healthBg
end

function ESP_Utility:Destroy()
	ESP_Utility.TrackersToUpdate[self.Object.Address] = nil

	for Name, Drawing in pairs(self.Drawings) do
		if type(Drawing) == "table" then
			Drawing.Drawing:Remove()
		else
			Drawing:Remove()
		end
	end

	if self.HealthBar then pcall(function() self.HealthBar:Remove() end) end
	if self.HealthBg then pcall(function() self.HealthBg:Remove() end) end

	for key, value in self do
		self[key] = nil
	end
	setmetatable(self, nil)
end

local espLastUpdate = 0
UpdateThread = RunService.RenderStepped:Connect(function(dt)
	if not next(ESP_Utility.TrackersToUpdate) then return end
	local now = os.clock()
	if now - espLastUpdate < 0.05 then return end
	espLastUpdate = now

	for i, v in pairs(ESP_Utility.TrackersToUpdate) do
		if v then
			if not v.Name then
				ESP_Utility.TrackersToUpdate[i] = nil
				continue
			end
			v:_Update()
		end
	end
end)

function ESP_Utility:CleanupAll()
	if UpdateThread then
		pcall(function() UpdateThread:Disconnect() end)
		UpdateThread = nil
	end
	for i, v in pairs(ESP_Utility.TrackersToUpdate) do
		if v and v.Destroy then
			pcall(function() v:Destroy() end)
		end
		ESP_Utility.TrackersToUpdate[i] = nil
	end
end

_G.GakranEspCleanup = function()
	pcall(function() ESP_Utility:CleanupAll() end)
end

print("[ESP_Utility] Functions were imported v2.0 (Gakuran customized)")

_G.ESP_Utility = ESP_Utility
return ESP_Utility
