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

function Icon.new(buffWatch, configForm, xmlDoc)
	local self = setmetatable({}, Icon)

	self.iconForm = iconForm
	self.buffWatch = buffWatch
	self.icon = Apollo.LoadForm("AuraMastery.xml", "AM_Icon", nil, self)
	self.iconName = ""
    self.description = ""
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
	self.MaxCharges = 0

	self.showWhen = "Always"
	self.playSoundWhen = "None"
    self.group = '00000000-0000-0000-0000-000000000000'

	self.onlyInCombat = false

    self.active = {
        inCombat = true,
        notInCombat = true,
        solo = true,
        inGroup = true,
        inRaid = true,
        pvpFlagged = true,
        notPvpFlagged = true
    }

	self.soundPlayed = true
	self.isInCombat = false

	self.SimpleMode = false

	GeminiPackages:Require("AuraMastery:IconOverlay", function(iconOverlay)
		local IconOverlay = iconOverlay
		self.iconOverlay = IconOverlay.new(self)
	end)

	GeminiPackages:Require("AuraMastery:TrackLineGroup", function(trackLineGroup)
		self.trackLine = trackLineGroup.new(self)
	end)

	GeminiPackages:Require("AuraMastery:InWorldIcon", function(inWorldIcon)
		self.inWorldIcon = inWorldIcon.new(self, xmlDoc)
	end)

	return self
end

function Icon:SetConfigElement(configElement)
	self.configElement = configElement
end

function Icon:Load(saveData)
	if saveData ~= nil then
		self.iconName = saveData.iconName
        self.description = saveData.description or ""
        self.customSound = saveData.customSound or false
		self.iconSound = saveData.iconSound
		self.iconBackground = saveData.iconBackground == nil or saveData.iconBackground
		saveData.iconPostion = saveData.iconPosition or { left = 0, top = 0 }
		self.iconScale = saveData.iconScale or 1
        self:SetPosition(saveData.iconPosition.left, saveData.iconPosition.top)
		if saveData.iconColor ~= nil then
			self.iconColor = CColor.new(saveData.iconColor[1], saveData.iconColor[2], saveData.iconColor[3], saveData.iconColor[4])
		end

		if saveData.onlyInCombat ~= nil then
            self.active.inCombat = true
            self.active.notInCombat = not saveData.onlyInCombat
		end

        if saveData.active ~= nil then
            self.active = saveData.active
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

        self.group = saveData.group or '00000000-0000-0000-0000-000000000000'

		self.iconOverlay:Load(saveData.iconOverlay)

		self:UpdateDefaultIcon()

		if saveData.showWhen == nil then
			if saveData.iconShown == "Both" then
				self.showWhen = "Always"
			elseif saveData.iconShown == "Active" then
				self.showWhen = "All"
			else
				self.showWhen = "None"
			end
		else
			self.showWhen = saveData.showWhen
		end
		self.playSoundWhen = saveData.playSoundWhen or "None"

		self.enabled = saveData.iconEnabled == nil or saveData.iconEnabled

		if saveData.SimpleMode == nil then
			self.SimpleMode = false
		else
			self.SimpleMode = saveData.SimpleMode
		end


		GeminiPackages:Require("AuraMastery:IconTrigger", function(iconTrigger)
			if saveData.Triggers ~= nil then
				for _, triggerData in pairs(saveData.Triggers) do
					local trigger = iconTrigger.new(self, self.buffWatch)
					trigger:Load(triggerData)
					table.insert(self.Triggers, trigger)
				end
			end

			if saveData.iconType ~= nil then
				if saveData.criticalRequired ~= nil and saveData.criticalRequired then
					local trigger = iconTrigger.new(self, self.buffWatch)
					trigger.Name = "OnCritical"
					trigger.Type = "On Critical"
					table.insert(self.Triggers, trigger)
				end

				local trigger = iconTrigger.new(self, self.buffWatch)
				self:ConvertTriggerFromOldFormat(trigger, saveData)
				table.insert(self.Triggers, trigger)
			end
		end)

        if self.trackLine ~= nil then
            self.trackLine:Load(saveData.trackLine)
        end

        if self.inWorldIcon ~= nil then
            self.inWorldIcon:Load(saveData.inWorldIcon)
        end
	end

	self:ChangeActionSet(AbilityBook.GetCurrentSpec())
end

function Icon:ConvertTriggerFromOldFormat(trigger, saveData)
	if saveData.iconType == "Cooldown" then
		trigger.Name = "CD:" .. self.iconName
		trigger.Type = "Cooldown"
		trigger.TriggerDetails = {
			SpellName = self.iconName
		}
	elseif saveData.iconType == "Buff" then
		trigger.Name = "Buff:" .. self.iconName
		trigger.Type = "Buff"
		trigger.TriggerDetails = {
			BuffName = self.iconName,
			Target = {
				Player = saveData.iconTarget == "Player" or saveData.iconTarget == "Both",
				Target = saveData.iconTarget == "Target" or saveData.iconTarget == "Both"
			}
		}
	elseif saveData.iconType == "Debuff" then
		trigger.Name = "Debuff:" .. self.iconName
		trigger.Type = "Debuff"
		trigger.TriggerDetails = {
			DebuffName = self.iconName,
			Target = {
				Player = saveData.iconTarget == "Player" or saveData.iconTarget == "Both",
				Target = saveData.iconTarget == "Target" or saveData.iconTarget == "Both"
			}
		}
	end
end

function Icon:UpdateDefaultIcon()
	self.defaultIcon = self:GetSpellIconByName(self.iconName)
	self.iconOverlay:UpdateOverlaySprite()
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
	saveData.description = self.description
    saveData.customSound = self.customSound
	saveData.iconSound = self.iconSound
	saveData.iconBackground = self.iconBackground
    saveData.active = self.active
	saveData.iconScale = self.iconScale
	saveData.iconBorder = self.iconBorder
	saveData.iconColor = { self.iconColor.r, self.iconColor.g, self.iconColor.b, self.iconColor.a }
	saveData.iconSprite = self.iconSprite
	saveData.iconEnabled = self.enabled
	saveData.actionSets = self.actionSets
	saveData.SimpleMode = self.SimpleMode
    saveData.group = self.group

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

	saveData.Triggers = {}

	for _, trigger in pairs(self.Triggers) do
		table.insert(saveData.Triggers, trigger:Save())
	end

	saveData.showWhen = self.showWhen
	saveData.playSoundWhen = self.playSoundWhen

    if self.trackLine ~= nil then
        saveData.trackLine = self.trackLine:Save()
    end

    if self.inWorldIcon ~= nil then
        saveData.inWorldIcon = self.inWorldIcon:Save()
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
	for _, trigger in pairs(self.Triggers) do
		trigger:RemoveFromBuffWatch()
	end
	self.icon:Destroy()
end

function Icon:SetIcon(configWnd)
	if self.SimpleMode then
        self.iconName = configWnd:FindChild("AuraSpellNameList"):GetData():GetText()
		self.description = configWnd:FindChild("Description"):GetText()
		self.onlyInCombat = configWnd:FindChild("AuraOnlyInCombat"):IsChecked()
		self.actionSets = {
			configWnd:FindChild("AuraActionSet1"):IsChecked(),
			configWnd:FindChild("AuraActionSet2"):IsChecked(),
			configWnd:FindChild("AuraActionSet3"):IsChecked(),
			configWnd:FindChild("AuraActionSet4"):IsChecked()
		}
		self.iconSound = configWnd:FindChild("AuraSoundSelect"):GetData():GetData()
		self.showWhen = configWnd:FindChild("AuraAlwaysShow"):IsChecked() and "Always" or "All"
		local selectedSprite = configWnd:FindChild("AuraIconSelect"):GetData()
		if selectedSprite:GetName() == "AuraSprite_Default" then
			self.iconSprite = ""
		else
			self.iconSprite = selectedSprite:FindChild("SpriteItemIcon"):GetSprite()
		end

		self.iconOverlay:SetConfig(configWnd)
		if #self.Triggers == 0 then
			GeminiPackages:Require('AuraMastery:IconTrigger', function(iconTrigger)
				local trigger = iconTrigger.new(self, self.buffWatch)
				trigger.Name = "Trigger 1"
				trigger.TriggerDetails = { SpellName = "" }
				table.insert(self.Triggers, trigger)
				trigger:SetConfig(configWnd)
			end)
		else
			self.Triggers[1]:SetConfig(configWnd)
		end
	else
		self.iconName = configWnd:FindChild("BuffName"):GetText()
        self.description = configWnd:FindChild("Description"):GetText()
		self.showWhen = configWnd:FindChild("BuffShowWhen"):GetText()
		self.playSoundWhen = configWnd:FindChild("BuffPlaySoundWhen"):GetText()
		self.iconBackground = configWnd:FindChild("BuffBackgroundShown"):IsChecked()

        self.active.inCombat = configWnd:FindChild("BuffShowInCombat"):IsChecked()
        self.active.notInCombat = configWnd:FindChild("BuffShowNotInCombat"):IsChecked()
        self.active.solo = configWnd:FindChild("BuffShowSolo"):IsChecked()
        self.active.inGroup = configWnd:FindChild("BuffShowInGroup"):IsChecked()
        self.active.inRaid = configWnd:FindChild("BuffShowInRaid"):IsChecked()
        self.active.pvpFlagged = configWnd:FindChild("BuffShowPvpFlagged"):IsChecked()
        self.active.notPvpFlagged = configWnd:FindChild("BuffShowNotPvpFlagged"):IsChecked()

		self:SetScale(configWnd:FindChild("BuffScale"):GetValue())

		self.iconBorder = configWnd:FindChild("BuffBorderShown"):IsChecked()
		self.icon:SetStyle("Border", self.iconBorder)

        self.customSound = configWnd:FindChild("CustomSoundEnabled"):IsChecked()
        if self.customSound then
            self.iconSound = configWnd:FindChild("CustomSoundName"):GetText()
        else
    		if configWnd:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetData() ~= nil then
    			self.iconSound = configWnd:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetData():GetData()
    		else
    			self.iconSound = nil
    		end
        end
		self.iconSprite = configWnd:FindChild("SelectedSprite"):GetText()

		for iconTextId, iconText in pairs(self.iconText) do
			iconText:SetConfig(configWnd:FindChild("TextList"):GetChildren()[iconTextId])
		end

		self.iconOverlay:SetConfig(configWnd)

        if self.trackLine ~= nil then
            self.trackLine:SetConfig(configWnd:FindChild("TrackLine"))
        end

        if self.inWorldIcon ~= nil then
            self.inWorldIcon:SetConfig(configWnd:FindChild("TrackLine"))
        end

		self.enabled = configWnd:FindChild("BuffEnabled"):IsChecked()
		self.actionSets = {
			configWnd:FindChild("BuffActionSet1"):IsChecked(),
			configWnd:FindChild("BuffActionSet2"):IsChecked(),
			configWnd:FindChild("BuffActionSet3"):IsChecked(),
			configWnd:FindChild("BuffActionSet4"):IsChecked()
		}

		local editor = configWnd:FindChild("TriggerWindow")
		if editor ~= nil then
			local trigger = editor:GetData()
			if trigger ~= nil then
				trigger:SetConfig(editor)
			end
		end
	end

	self:ChangeActionSet(AbilityBook.GetCurrentSpec())
	self:UpdateDefaultIcon()
end

function Icon:GetName()
	return self.iconName
end

function Icon:PreUpdate(deltaTime)
	self.isSet = false
	for _, trigger in pairs(self.Triggers) do
		trigger:ResetTrigger(deltaTime)
	end
end

function Icon:PostUpdate()
	local showIcon = nil
	local playSound = nil

	self.Sprite = nil
	self.duration = 0
	self.maxDuration = 0
	self.Stacks = 0
	self.Charges = 0
	self.MaxCharges = 0
	self.LastUnsetSprite = nil

	for i = #self.Triggers, 1, -1 do
		local trigger = self.Triggers[i]

		local triggerSet = trigger:IsSet()

		if self.showWhen ~= "Always" then
			if showIcon == nil then
				if self.showWhen == "None" then
					showIcon = not triggerSet
				else
					showIcon = triggerSet
				end
			elseif self.showWhen == "All" then
				showIcon = showIcon and triggerSet
			else
				showIcon = showIcon or triggerSet
			end
		end

		if playSound == nil then
			if self.playSoundWhen == "None" then
				playSound = not triggerSet
			else
				playSound = triggerSet
			end
		elseif self.playSoundWhen == "All" then
			playSound = playSound and triggerSet
		elseif self.playSoundWhen == "None" then
			playSound = playSound and not triggerSet
		else
			playSound = playSound or triggerSet
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

			if trigger.Resources ~= nil then
				self.Resources = trigger.Resources
			end

			if trigger.MaxCharges ~= nil then
				self.MaxCharges = trigger.MaxCharges
			end

			if trigger.Sprite ~= nil then
				self.Sprite = trigger.Sprite
			end
		else
			if trigger.Sprite ~= nil then
				self.LastUnsetSprite = trigger.Sprite
			end
		end
	end

	local showIcon = self:VisibilityCheck() and (showIcon or self.showWhen == "Always")

	local isMoveable = self.icon:IsStyleOn("Moveable")
	if showIcon or isMoveable then
		self.icon:Show(true, true)
		self:SetSprite(self:GetSprite())
		self.icon:SetBGColor(self.iconColor)
	else
		self.icon:Show(false, true)
	end

	if playSound and not self.soundPlayed and self.iconSound ~= -1 then
        if type(self.iconSound) == "string" then
            Sound.PlayFile("Sounds\\" .. self.iconSound)
        else
	        Sound.Play(self.iconSound)
        end
	end
	self.soundPlayed = playSound

	for _, iconText in pairs(self.iconText) do
		iconText:Update()
	end

	if self.iconOverlay ~= nil then
		self.iconOverlay:Update()
	end

    if self.trackLine ~= nil then
        self.trackLine:Update()
    end

    if self.inWorldIcon ~= nil then
        self.inWorldIcon:Update()
    end

	if showIcon then
		for i = #self.Triggers, 1, -1 do
			local trigger = self.Triggers[i]
			trigger:ProcessEffects()
		end
	else
		for i = #self.Triggers, 1, -1 do
			local trigger = self.Triggers[i]
			trigger:StopEffects()
		end
	end
end

function Icon:SetSprite(sprite)
	if self.currentSprite ~= sprite then
		self.icon:SetSprite(sprite)
		self.currentSprite = sprite
	end
end

function Icon:GetSprite()
	if self.iconSprite ~= "" then
		return self.iconSprite
	elseif self.Sprite ~= nil and self.Sprite ~= "" then
		return self.Sprite
	elseif self.LastUnsetSprite ~= nil and self.LastUnsetSprite ~= "" then
		return self.LastUnsetSprite
	else
		return self.defaultIcon
	end
end

function Icon:VisibilityCheck()
    return self:InCombatCheck()
    and self:GroupCheck()
    and self:PvpFlagCheck()
end

function Icon:InCombatCheck()
    if self.isInCombat then
        return self.active.inCombat
    else
        return self.active.notInCombat
    end
end

function Icon:GroupCheck()
    if self.isInRaid then
        return self.active.inRaid
    elseif self.isInGroup then
        return self.active.inGroup
    else
        return self.active.solo
    end
end

function Icon:PvpFlagCheck()
    if self.isPvpFlagged then
        return self.active.pvpFlagged
    else
        return self.active.notPvpFlagged
    end
end

function Icon:GetAbilitiesList()
	return _G["AuraMasteryLibs"]["GetAbilitiesList"]()
end

function Icon:GetSpellIconByName(spellName)
	local abilities = self:GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	for _, s in pairs(GameLib.GetClassInnateAbilitySpells().tSpells) do
		if s:GetName() == spellName then
			return s:GetIcon()
		end
	end
	return ""
end

function Icon:Unlock()
	self.icon:SetStyle("Moveable", true)
	self.icon:FindChild("UnlockedIcon"):Show(true)
end

function Icon:Lock()
	self.icon:SetStyle("Moveable", false)
	self.icon:FindChild("UnlockedIcon"):Show(false)
end

function Icon:SetScale(scale)
	self.iconScale = scale
	local left, top, right, bottom = self.icon:GetAnchorOffsets()
	self.icon:SetAnchorOffsets(left, top, left + (self.iconScale * self.defaultSize.width),  top + (self.iconScale * self.defaultSize.height))
end

function Icon:GetPosition()
    return self.icon:GetAnchorOffsets()
end

function Icon:SetPosition(x, y)
    self.icon:SetAnchorOffsets(x, y, x + (self.iconScale * self.defaultSize.width),  y + (self.iconScale * self.defaultSize.height))
end

function Icon:SetIconColor(color)
	self.icon:SetBGColor(color)
end

function Icon:GetTargets()
    for _, trigger in pairs(self.Triggers) do
        local targets = trigger:GetTargets()

        if targets ~= nil then
            return targets
        end
    end
end

if _G["AuraMasteryLibs"] == nil then
	_G["AuraMasteryLibs"] = { }
end
_G["AuraMasteryLibs"]["Icon"] = Icon
