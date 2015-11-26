require "Window"

local TrackLineGroup  = {}

setmetatable(TrackLineGroup, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

TrackLineGroup.TrackMode = {
	Line = 1,
	Circle = 2
}

function TrackLineGroup.new(parent)
	local self = setmetatable({}, { __index = TrackLineGroup })

    self.Enabled = false
    self.parent = parent
	self.bgColor = CColor.new(0,1,0,1)
	self.intermediateColor = CColor.new(0, 0, 1, 1)
	self.complementaryColor = CColor.new(1, 0, 1, 1)
	self.clearDistance = 0 --20
	self.target = nil
	self.Sprite = "Icons:Arrow"
	self.trackMode = TrackLineGroup.TrackMode.Line
    --self.trackMode = TrackLine.TrackMode.Circle

	self.rotation = 0
	self.updateRotation = true
	self.isVisible = false
	self.distance = 10
	self.distanceMarker = 2
	self.showDistanceMarker = true
    self.TrackLines = {}

	return self
end

function TrackLineGroup:Load(saveData)
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

        GeminiPackages:Require("AuraMastery:TrackLine", function(trackLine)
            for i = 1, saveData.numberOfTrackLines or 0, 1 do
                local line = trackLine.new(self)
                line:Load(saveData)
                table.insert(self.TrackLines, line)
            end
    	end)
	end
end

function TrackLineGroup:Save()
	local saveData = { }
    saveData.Enabled = self.Enabled
	saveData.Sprite = self.Sprite
	saveData.bgColor = { self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a }
	saveData.trackMode = self.trackMode
	saveData.distance = self.distance
	saveData.showDistanceMarker = self.showDistanceMarker
    saveData.numberOfTrackLines = #self.TrackLines
	return saveData
end

function TrackLineGroup:SetConfig(configWnd)
    self.Enabled = configWnd:FindChild("TrackLineEnabled"):IsChecked()
    local numberOfTrackLines = tonumber(configWnd:FindChild("TrackLineNumberOfLines"):GetText())
    if #self.TrackLines < numberOfTrackLines then
        for i = #self.TrackLines + 1, numberOfTrackLines, 1 do
            GeminiPackages:Require("AuraMastery:TrackLine", function(trackLine)
                local line = trackLine.new(self)
                line:Load(self:Save())
                table.insert(self.TrackLines, line)
            end)
        end
    elseif #self.TrackLines > numberOfTrackLines then
        for i = #self.TrackLines, numberOfTrackLines + 1, -1 do
            self.TrackLines[i]:Destroy()
            table.remove(self.TrackLines, i)
        end
    end
end

function TrackLineGroup:Update()
    if not self.Enabled then return end

	self:UpdateTarget()
    for _, trackLine in pairs(self.TrackLines) do
        trackLine:Update()
    end
end

function TrackLineGroup:UpdateTarget()
    local units = self.parent:GetTargets() or {}
    local i = 1
    for _, unit in pairs(units) do
        if self.TrackLines[i] == nil then return end
	    self.TrackLines[i]:SetTarget(unit)
        i = i + 1
    end
    local numOfLines = #self.TrackLines
    for i = i, numOfLines, 1 do
        self.TrackLines[i]:SetTarget(nil)
    end
end

function TrackLineGroup:DrawTracker(target)
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

function TrackLineGroup:SetBGColor(color)
	self.bgColor = color
    self.intermediateColor = color
    self.complementaryColor = color
	--self.intermediateColor = self.trackMaster.colorPicker:GetComplementaryOffset(self.bgColor)
	--self.complementaryColor = self.trackMaster.colorPicker:GetComplementary(self.bgColor)
	--self.marker[self.distanceMarker]:FindChild("Distance"):SetTextColor(color)
end

function TrackLineGroup:SetTrackMode(mode)
	self.trackMode = mode
end

function TrackLineGroup:SetDistance(distance)
	self.distance = distance
end

function TrackLineGroup:SetShowDistanceMarker(isShown)
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
GeminiPackages:NewPackage(TrackLineGroup, "AuraMastery:TrackLineGroup", 1)
