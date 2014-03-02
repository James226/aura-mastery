-----------------------------------------------------------------------------------------------
-- Client Lua Script for AuraMastery
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local GeminiPackages = _G["GeminiPackages"]   

local Icon  = {} 
Icon.__index = Icon

setmetatable(Icon, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local EmptyBuffIcon = "CRB_ActionBarFrameSprites:sprActionBarFrame_VehicleIconBG"
local IconText

function Icon.new(buffWatch, configForm)
	local self = setmetatable({}, Icon)
	
	self.iconForm = iconForm
	self.buffWatch = buffWatch
	self.icon = Apollo.LoadForm("AuraMastery.xml", "AM_Icon", nil, self)
	self.iconType = "Buff"
	self.iconName = ""
	self.iconTarget = "Player"
	self.iconShown = "Active"
	self.iconSound = -1
	self.iconBackground = true
	self.buffStart = 0
	self.iconBorder = true
	self.iconColor = CColor.new(1, 1, 1, 1)
	self.iconSprite = ""
	self.iconScale = 1
	self.defaultSize = { width = self.icon:GetWidth(), height = self.icon:GetHeight() }
	self.duration = 0
	self.maxDuration = 0
	self.criticalRequired = false
	self.criticalRequirementPassed = true
	self.chargesRemaining = 0
	self.iconId = 0
	self.enabled = true
	self.defaultIcon = ""

	self.Triggers = {}
	
	self.buff = nil
	self.spell = nil
	
	self.isEnabled = true
	
	self.isActive = true
	
	self.actionSets = { true, true, true, true }
	
	self.iconText = {}

	self.Stacks = 0
	self.Charges = 0

	self.showWhen = "All"
		
	GeminiPackages:Require("AuraMastery:IconOverlay", function(iconOverlay)
		local IconOverlay = iconOverlay
		self.iconOverlay = IconOverlay.new(self)
	end)
	
	return self
end

function Icon:SetConfigElement(configElement)
	self.configElement = configElement
end

function Icon:Load(saveData)
	if saveData ~= nil then
		self.iconType = saveData.iconType
		self.iconName = saveData.iconName
		self.iconTarget = saveData.iconTarget
		self.iconShown = saveData.iconShown
		self.iconSound = saveData.iconSound
		self.iconBackground = saveData.iconBackground == nil or saveData.iconBackground
		saveData.iconPostion = saveData.iconPosition or { left = 0, top = 0 }
		self.iconScale = saveData.iconScale or 1
		self.icon:SetAnchorOffsets(saveData.iconPosition.left, saveData.iconPosition.top, saveData.iconPosition.left + (self.iconScale * self.defaultSize.width),  saveData.iconPosition.top + (self.iconScale * self.defaultSize.height))
		if saveData.iconColor ~= nil then
			self.iconColor = CColor.new(saveData.iconColor[1], saveData.iconColor[2], saveData.iconColor[3], saveData.iconColor[4])
		end

		self.iconSprite = saveData.iconSprite or ""
		self.iconBorder = saveData.iconBorder
		self.icon:SetStyle("Border", self.iconBorder)
		if saveData.iconText ~= nil then
			GeminiPackages:Require("AuraMastery:IconText", function(iconText)
				local IconText = iconText
				for textId, iconText in pairs(saveData.iconText) do
					self.iconText[textId] = IconText.new(self)
					self.iconText[textId]:Load(saveData.iconText[textId])
				end
			end)
		end
		
		if saveData.actionSets ~= nil then
			self.actionSets = saveData.actionSets
		end
		
		self.iconOverlay:Load(saveData.iconOverlay)
		
		if saveData.criticalRequired ~= nil then
			self.criticalRequired = saveData.criticalRequired
		end

		self.defaultIcon = self:GetSpellIconByName(self.iconName)
	end
	
	self.enabled = saveData.iconEnabled == nil or saveData.iconEnabled

	if saveData.Triggers ~= nil then
		GeminiPackages:Require("AuraMastery:IconTrigger", function(iconTrigger)
			for _, triggerData in pairs(saveData.Triggers) do
				local trigger = iconTrigger.new(self.buffWatch)
				trigger:Load(triggerData)
				table.insert(self.Triggers, trigger)
			end
		end)
	end
	
	self:ChangeActionSet(AbilityBook.GetCurrentSpec())
end

function Icon:ChangeActionSet(newActionSet)
	if self.enabled and self.actionSets[newActionSet] then
		self:Enable()
	else
		self:Disable()
	end
end

function Icon:GetSaveData()
	local saveData = { }
	saveData.iconName = self.iconName
	saveData.iconType = self.iconType 
	saveData.iconShown = self.iconShown 
	saveData.iconTarget = self.iconTarget 
	saveData.iconSound = self.iconSound 
	saveData.iconBackground = self.iconBackground
	saveData.iconScale = self.iconScale
	saveData.iconBorder = self.iconBorder
	saveData.iconColor = { self.iconColor.r, self.iconColor.g, self.iconColor.b, self.iconColor.a }
	saveData.iconSprite = self.iconSprite
	saveData.iconEnabled = self.enabled
	saveData.actionSets = self.actionSets
	
	saveData.iconText = {}
	for iconTextId, iconText in pairs(self.iconText) do
		saveData.iconText[iconTextId] = iconText:Save()
	end

	local left, top, right, bottom = self.icon:GetAnchorOffsets()
	saveData.iconPosition = {
		left = left,
		top = top
	}
	
	saveData.iconOverlay = self.iconOverlay:Save()
	saveData.criticalRequired = self.criticalRequired

	saveData.Triggers = {}

	for _, trigger in pairs(self.Triggers) do
		table.insert(saveData.Triggers, trigger:Save())
		--saveData.Triggers[#saveData.Triggers] = trigger:Save()
	end
	
	return saveData
end

function Icon:Enable()
	self.isEnabled = true
	self.icon:Show(true)
	self.isActive = false
	self.isSet = false
end

function Icon:Disable()
	self.isEnabled = false
	self.icon:Show(false)
end

function Icon:Delete()
	self.icon:Destroy()
end

function Icon:SetIcon(configWnd)
	self.iconName = configWnd:FindChild("BuffName"):GetText()
	self.iconType = configWnd:FindChild("BuffType"):GetText()
	self.iconTarget = configWnd:FindChild("BuffTarget"):GetText()
	self.iconShown = configWnd:FindChild("BuffShown"):GetText()
	self.iconBackground = configWnd:FindChild("BuffBackgroundShown"):IsChecked()
	self.criticalRequired = configWnd:FindChild("BuffCriticalRequired"):IsChecked()
	
	self:SetScale(configWnd:FindChild("BuffScale"):GetValue())
	
	self.iconBorder = configWnd:FindChild("BuffBorderShown"):IsChecked()
	self.icon:SetStyle("Border", self.iconBorder)
	
	if configWnd:FindChild("SoundSelect"):FindChild("SelectedSound") ~= nil then
		self.iconSound = tonumber(configWnd:FindChild("SoundSelect"):FindChild("SelectedSound"):GetText())
	else
		self.iconSound = nil
	end
	self.iconSprite = configWnd:FindChild("SelectedSprite"):GetText()
	
	for iconTextId, iconText in pairs(self.iconText) do
		iconText:SetConfig(configWnd:FindChild("TextList"):GetChildren()[iconTextId])
	end
	
	self.iconOverlay:SetConfig(configWnd)
	
	self.enabled = configWnd:FindChild("BuffEnabled"):IsChecked()
	
	self.actionSets = {
		configWnd:FindChild("BuffActionSet1"):IsChecked(),
		configWnd:FindChild("BuffActionSet2"):IsChecked(),
		configWnd:FindChild("BuffActionSet3"):IsChecked(),
		configWnd:FindChild("BuffActionSet4"):IsChecked()
	}
	
	self:ChangeActionSet(AbilityBook.GetCurrentSpec())

	self.defaultIcon = self:GetSpellIconByName(self.iconName)

	local editor = configWnd:FindChild("TriggerEditor")
	local trigger = editor:GetData()
	trigger:SetConfig(editor)
end

function Icon:GetName()
	return self.iconName
end

function Icon:PreUpdate()
	self.isSet = false
	for _, trigger in pairs(self.Triggers) do
		trigger:ResetTrigger()
	end
end

function Icon:PostUpdate()
	local showIcon = nil

	for i = #self.Triggers, 1, -1 do
		local trigger = self.Triggers[i]

		if showIcon == nil then
			showIcon = trigger:IsSet()
		elseif self.showWhen == "All" then
			showIcon = showIcon and trigger:IsSet()
			if not showIcon then break end
		else
			showIcon = showIcon or trigger:IsSet()
		end


		if trigger:IsSet() then
			if trigger.Time ~= nil then
				self.duration = trigger.Time
			end

			if trigger.MaxDuration ~= nil then
				self.maxDuration = trigger.MaxDuration
			end

			if trigger.Stacks ~= nil then
				self.Stacks = trigger.Stacks
			end

			if trigger.Charges ~= nil then
				self.Charges = trigger.Charges
			end
		end
	end

	if showIcon then
		self.icon:Show(true)
		self.icon:SetSprite(self.iconSprite == "" and self.defaultIcon or self.iconSprite)
		self.icon:SetBGColor(self.iconColor)
	else
		self.icon:Show(false)
	end
	
	for _, iconText in pairs(self.iconText) do
		iconText:Update()
	end
	
	if self.iconOverlay ~= nil then
		self.iconOverlay:Update()
	end
end

function Icon:GetSpellIconByName(spellName)
	local abilities = AbilityBook.GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	return ""
end

function Icon:Unlock()
	self.icon:SetStyle("Moveable", true)
end

function Icon:Lock()
	self.icon:SetStyle("Moveable", false)
end

function Icon:SetScale(scale)
	self.iconScale = scale
	local left, top, right, bottom = self.icon:GetAnchorOffsets()
	self.icon:SetAnchorOffsets(left, top, left + (self.iconScale * self.defaultSize.width),  top + (self.iconScale * self.defaultSize.height))
end

if _G["AuraMasteryLibs"] == nil then
	_G["AuraMasteryLibs"] = { }
end
_G["AuraMasteryLibs"]["Icon"] = Icon