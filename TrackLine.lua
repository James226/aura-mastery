require "Window"

local TrackLine  = {}

setmetatable(TrackLine, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

TrackLine.TrackMode = {
	Line = 1,
	Circle = 2
}

function TrackLine.new(parent)
	local self = setmetatable({}, { __index = TrackLine })

    self.Enabled = false
    self.parent = parent
	self.bgColor = CColor.new(0,1,0,1)
	self.intermediateColor = CColor.new(0, 0, 1, 1)
	self.complementaryColor = CColor.new(1, 0, 1, 1)
	self.clearDistance = 0 --20
	self.target = nil
	self.Sprite = "Icons:Arrow"
	self.trackMode = TrackLine.TrackMode.Line
    --self.trackMode = TrackLine.TrackMode.Circle

	self.rotation = 0
	self.updateRotation = true
	self.isVisible = false
	self.distance = 10
	self.distanceMarker = 2
	self.showDistanceMarker = true


	self.marker = {}
	for i = 0, 20 do
		self.marker[i] = Apollo.LoadForm("AuraMastery.xml", "TrackMarker", "InWorldHudStratum", self)
		self.marker[i]:Show(false, false)
	end
	self:CacheMarkerOffsets()

	return self
end

function TrackLine:Destroy()
    for i = 0, 20 do
        self.marker[i]:DestroyChildren()
    end
end

function TrackLine:Load(saveData)
	if saveData ~= nil then
        self.Enabled = saveData.Enabled
		self:SetBGColor(CColor.new(saveData.bgColor[1], saveData.bgColor[2], saveData.bgColor[3], saveData.bgColor[4]))
		self.Sprite = saveData.Sprite

		if saveData.trackMode ~= nil then
			self:SetTrackMode(saveData.trackMode)
		end

		if saveData.distance ~= nil then
			self:SetDistance(saveData.distance)
		end

		if saveData.showDistanceMarker ~= nil then
			self.showDistanceMarker = saveData.showDistanceMarker
		end

		for i = 0, 20 do
			if self.showDistanceMarker and i == self.distanceMarker then
				self.marker[i]:FindChild("Distance"):Show(true, true)
				self.marker[i]:FindChild("Distance"):SetTextColor(self.bgColor)
				self.marker[i]:SetSprite("")
			else
				self.marker[i]:SetSprite(self.Sprite)
			end
		end
		self:CacheMarkerOffsets()
	end
end

function TrackLine:Save()
	local saveData = { }
    saveData.Enabled = self.Enabled
	saveData.Sprite = self.Sprite
	saveData.bgColor = { self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a }
	saveData.trackMode = self.trackMode
	saveData.distance = self.distance
	saveData.showDistanceMarker = self.showDistanceMarker
	return saveData
end

function TrackLine:SetConfig(configWnd)
    self.Enabled = configWnd:FindChild("TrackLineEnabled"):IsChecked()
end

function TrackLine:SetSprite(sprite)
	self.Sprite = sprite
	for i = 0, 20 do
		self.marker[i]:SetSprite(sprite)
	end
end

function TrackLine:SetTarget(target, clearDistance)
    self.target = target
end

local function indexOf(table, item)
	for key, value in pairs(table) do
		if (item == value) then
			return key
		end
	end
end

function TrackLine.GetDistanceFunction()
	if GameLib.GetPlayerUnit() ~= nil then
		local playerPos = GameLib.GetPlayerUnit():GetPosition()
		local playerVec = Vector3.New(playerPos.x, playerPos.y, playerPos.z)
		return function (target)
			if Vector3.Is(target) then
				return (playerVec - target):Length()
			elseif Unit.is(target) then
				local targetPos = target:GetPosition()
				if targetPos == nil then
					return 0 -- Uh, no clue
				end
				local targetVec = Vector3.New(targetPos.x, targetPos.y, targetPos.z)
				return (playerVec - targetVec):Length()
			else
				local targetVec = Vector3.New(target.x, target.y, target.z)
				return (playerVec - targetVec):Length()
			end
		end
	else
		return function (target)
			return 0 -- Probably should throw an error here
		end
	end
end

function TrackLine:Update()
    if not self.Enabled then return end
	self:UpdateLine()
end

function TrackLine:UpdateTarget()
	self.target = self.parent:GetTarget()
end

function TrackLine:UpdateLine()
	if GameLib.GetPlayerUnit() ~= nil and self.target ~= nil then
		local curTarget = nil
		if self.target ~= nil then
			curTarget = self.target
			if self.clearDistance ~= -1 then
				local distanceToPlayer = TrackLine.GetDistanceFunction()
				local distance = distanceToPlayer(curTarget)
				if distance < self.clearDistance then
					self:SetTarget(nil)
					curTarget = nil
				end
			end
		end
		if curTarget ~= nil then
			self:DrawTracker(curTarget)
		else
			self:HideLine()
		end
	else
		self:HideLine()
	end
end

function TrackLine:DrawTracker(target)
	self.isVisible = true
	if GameLib.GetPlayerUnit() ~= nil then
		local player = GameLib.GetPlayerUnit()
		local playerPos = GameLib.GetPlayerUnit():GetPosition()
		local playerVec = Vector3.New(playerPos.x, playerPos.y, playerPos.z)
		local targetVec = nil
		if Vector3.Is(target) then
			targetVec = target
		elseif Unit.is(target) then
			local targetPos = target:GetPosition()
			if targetPos then
				targetVec = Vector3.New(targetPos.x, targetPos.y, targetPos.z)
			end
		end
		if targetVec ~= nil then
			if self.trackMode == TrackLine.TrackMode.Line then
				self:DrawLineBetween(playerVec, targetVec)
			elseif self.trackMode == TrackLine.TrackMode.Circle then
				self:DrawCircleAround(playerVec, targetVec)
			end
		else
			self:HideLine()
		end
	else
		self:HideLine()
	end

end

function TrackLine:DrawLineBetween(playerVec, targetVec)
	if self.updateRotation then
		self.rotation = self:CalculateRotation(targetVec, playerVec)
		self.updateRotation = false
	end

	local totalDistance = (playerVec - targetVec):Length()
	local color
	for i = 0, 20 do
		local fraction = (i+1)/21

		self.marker[i]:SetWorldLocation(Vector3.InterpolateLinear(playerVec, targetVec, fraction))
		if not self.marker[i]:IsOnScreen() then
			self.marker[i]:Show(false, true)
		else
			self.marker[i]:Show(true, true)

			if self.showDistanceMarker and i == self.distanceMarker then
				self.marker[i]:FindChild("Distance"):SetText(string.format("%i", totalDistance))
			else
				local blobDistance = totalDistance * fraction
				if blobDistance  <= 25 then
					color = self.bgColor
				elseif blobDistance <= 35 then
					color = self.intermediateColor
				else
					color = self.complementaryColor
				end

				self.marker[i]:SetBGColor(color)
				self.marker[i]:SetRotation(self.rotation)
			end
		end
	end
end

function TrackLine:DrawCircleAround(playerVec, targetVec)
	local totalDistance = (playerVec - targetVec):Length()

	for i = 0, 20 do
		local pos = targetVec + self.marker[i]:GetData()

		self.marker[i]:SetWorldLocation(pos)
		if not self.marker[i]:IsOnScreen() then
			self.marker[i]:Show(false, true)
		else
			self.marker[i]:Show(true, true)
			self.marker[i]:SetBGColor(self.bgColor)
			if self.updateRotation then
				self.marker[i]:SetRotation(self:CalculateRotation(targetVec, pos))
			end
		end
	end
	self.updateRotation = false
end

function TrackLine:CacheMarkerOffsets()
	for i = 0, 20 do
		self.marker[i]:SetData(Vector3.New(
			self.distance * math.cos(((2 * math.pi) / 20) * i),
			0,
			self.distance * math.sin(((2 * math.pi) / 20) * i)))
	end
end

function TrackLine:CalculateRotation(target, player)
	return self:OffsetPlayerHeading(math.atan2(target.z - player.z, target.x - player.x))
end

function TrackLine:UpdateRotation()
	self.updateRotation = true
end

function TrackLine:OffsetPlayerHeading(rotation)
	local playerHeading = GameLib.GetPlayerUnit():GetHeading()
	if playerHeading < 0 then
		playerHeading = playerHeading * -1
	else
		playerHeading = 2 * math.pi - playerHeading
	end
	return math.deg(rotation - playerHeading) + 90
end

function TrackLine:HideLine()
	if self.isVisible then
		self.isVisible = false
		for i = 0, 20 do
			self.marker[i]:Show(false, true)
		end
	end
end

function TrackLine:SetBGColor(color)
	self.bgColor = color
    self.intermediateColor = color
    self.complementaryColor = color
	--self.intermediateColor = self.trackMaster.colorPicker:GetComplementaryOffset(self.bgColor)
	--self.complementaryColor = self.trackMaster.colorPicker:GetComplementary(self.bgColor)
	self.marker[self.distanceMarker]:FindChild("Distance"):SetTextColor(color)
end

function TrackLine:SetTrackMode(mode)
	self.trackMode = mode
	self:CacheMarkerOffsets()
end

function TrackLine:SetDistance(distance)
	self.distance = distance
	self:CacheMarkerOffsets()
end

function TrackLine:SetShowDistanceMarker(isShown)
	self.showDistanceMarker = isShown

	if self.showDistanceMarker then
		self.marker[self.distanceMarker]:FindChild("Distance"):Show(true, true)
		self.marker[self.distanceMarker]:FindChild("Distance"):SetTextColor(self.bgColor)
		self.marker[self.distanceMarker]:SetSprite("")
		self.marker[self.distanceMarker]:SetRotation(0)
	else
		self.marker[self.distanceMarker]:SetSprite(self.Sprite)
		self.marker[self.distanceMarker]:FindChild("Distance"):Show(false, true)
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(TrackLine, "AuraMastery:TrackLine", 1)
