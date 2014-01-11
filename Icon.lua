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
	
	self.isActive = true
	
	GeminiPackages:Require("AuraMastery:IconText", function(iconText)
		IconText = iconText
		self.iconText = IconText.new(self)
	end)
		
	GeminiPackages:Require("AuraMastery:IconOverlay", function(iconOverlay)
		IconOverlay = iconOverlay
		self.iconOverlay = IconOverlay.new(self)
	end)
	
	self:AddToBuffWatch()
	
	return self
end

function Icon:SetConfigElement(configElement)
	self.configElement = configElement
end

function Icon:Load(saveData)
	self:RemoveFromBuffWatch()
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
			self.iconText:Load(saveData.iconText[1])
		end
		
		self.iconOverlay:Load(saveData.iconOverlay)
	end
	self:AddToBuffWatch()
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
	saveData.iconText = { self.iconText:Save() }
	local left, top, right, bottom = self.icon:GetAnchorOffsets()
	saveData.iconPosition = {
		left = left,
		top = top
	}
	
	saveData.iconOverlay = self.iconOverlay:Save()
	
	return saveData
end

function Icon:Delete()
	self:RemoveFromBuffWatch()
	self.icon:Destroy()
end

function Icon:AddToBuffWatch()
	if self.iconType == "Cooldown" then
		self:AddCooldownToBuffWatch(self.iconType)
	else
		if self.iconTarget == "Player" or self.iconTarget == "Both" then
			self:AddBuffToBuffWatch(self.iconType, "Player")
		end
		
		if self.iconTarget == "Target" or self.iconTarget == "Both" then
			self:AddBuffToBuffWatch(self.iconType, "Target")
		end
	end
end

function Icon:AddCooldownToBuffWatch(type)
	if self.buffWatch[type][self.iconName] == nil then
		self.buffWatch[type][self.iconName] = {}
	end
	self.buffWatch[type][self.iconName][tostring(self)] = self
end

function Icon:AddBuffToBuffWatch(type, target)
	if self.buffWatch[type][target][self.iconName] == nil then
		self.buffWatch[type][target][self.iconName] = {}
	end
	self.buffWatch[type][target][self.iconName][tostring(self)] = self
end

function Icon:RemoveFromBuffWatch()
	if self.iconType == "Cooldown" then
		self:RemoveCooldownFromBuffWatch(self.iconType)
	else
		if self.iconTarget == "Player" or self.iconTarget == "Both" then
			self:RemoveBuffFromBuffWatch(self.iconType, "Player")
		end
		
		if self.iconTarget == "Target" or self.iconTarget == "Both" then
			self:RemoveBuffFromBuffWatch(self.iconType, "Target")
		end
	end
end

function Icon:RemoveCooldownFromBuffWatch(type, target)
	self.buffWatch[type][self.iconName][tostring(self)] = nil
end

function Icon:RemoveBuffFromBuffWatch(type, target)
	self.buffWatch[type][target][self.iconName][tostring(self)] = nil
end

function Icon:GetSpellCooldown(spell)
	local charges = spell:GetAbilityCharges()
	if charges and charges.chargesMax > 0 then
		if charges.rechargePercentRemaining and charges.rechargePercentRemaining > 0 then
			return charges.rechargePercentRemaining * charges.rechargeTime, charges.rechargeTime, tostring(charges.chargesRemaining)
		end
	else
		local cooldown = spell:GetCooldownRemaining()
		if cooldown and cooldown > 0 then
			return cooldown, spell:GetCooldownTime(), 0
		end
	end
	return 0, 0, 0
end

function Icon:ProcessSpell(spell)
	local cdRemaining, cdTotal, chargesRemaining = self:GetSpellCooldown(spell)

	if (chargesRemaining > 0 or cdRemaining == 0) then
		if self.iconShown == "Inactive" or self.iconShown == "Both" then
			if self.isActive then
				self.isActive = false
				if self.iconSound ~= nil then
					Sound.Play(self.iconSound)
				end
			end
			self:SetSpell(spell, cdRemaining, cdTotal, chargesRemaining)
		else
			self:ClearBuff()
		end
	else
		self.isActive = true
		self.icon:SetBGColor(ApolloColor.new(1, 0, 0, 1))
		if self.iconShown == "Active" or self.iconShown == "Both" then
			self:SetSpell(spell, cdRemaining, cdTotal, chargesRemaining)
		else
			self:ClearBuff()
		end
	end
end

function Icon:SetIcon(configWnd)
	self:RemoveFromBuffWatch()
	self.iconName = configWnd:FindChild("BuffName"):GetText()
	self.iconType = configWnd:FindChild("BuffType"):GetText()
	self.iconTarget = configWnd:FindChild("BuffTarget"):GetText()
	self.iconShown = configWnd:FindChild("BuffShown"):GetText()
	self.iconBackground = configWnd:FindChild("BuffBackgroundShown"):IsChecked()
	self:SetScale(configWnd:FindChild("BuffScale"):GetValue())
	
	self.iconBorder = configWnd:FindChild("BuffBorderShown"):IsChecked()
	self.icon:SetStyle("Border", self.iconBorder)
	
	if configWnd:FindChild("SoundSelect"):FindChild("SelectedSound") ~= nil then
		self.iconSound = tonumber(configWnd:FindChild("SoundSelect"):FindChild("SelectedSound"):GetText())
	else
		self.iconSound = nil
	end
	self.iconSprite = configWnd:FindChild("SelectedSprite"):GetText()
	
	self.iconText:SetConfig(configWnd:FindChild("AM_Config_TextEditor"))
	self.iconOverlay:SetConfig(configWnd)
	self:AddToBuffWatch()
end

function Icon:SetName(name)
	self:RemoveFromBuffWatch()
	self.iconName = name
	self:AddToBuffWatch()
end

function Icon:GetName()
	return self.iconName
end

function Icon:PreUpdate()
	self.isSet = false
end

function Icon:PostUpdate()
	if not self.isSet then
		self:ClearBuff()
	end
	
	if self.iconText ~= nil then
		self.iconText:Update()
	end
	
	if self.iconOverlay ~= nil then
		self.iconOverlay:Update()
	end
end

function Icon:SetSprite(spriteIcon)
	self.icon:SetBGColor(self.iconColor)
	if self.iconSprite ~= "" and spriteIcon ~= EmptyBuffIcon then
		self.icon:SetSprite(self.iconSprite)
	else
		self.icon:SetSprite(spriteIcon)
	end
	self.iconOverlay:UpdateOverlaySprite()
end

function Icon:SetSpell(spell, remaining, total, charges)
	self:SetSprite(spell:GetIcon())
	self.icon:Show(true)	
	
	self.duration = remaining
	self.maxDuration = total
	
	self.isSet = true
end

function Icon:SetBuff(buff)
	if not self.isActive or buff.fTimeRemaining > self.buffStart then
		self.isActive = true
		self.buffStart = buff.fTimeRemaining
	end
	self.lastSprite = buff.spell:GetIcon()
	
	if self.iconShown == "Active" or self.iconShown == "Both" then
		self:SetSprite(buff.spell:GetIcon())
		self.icon:Show(true)
		
		self.duration = buff.fTimeRemaining
		self.maxDuration = self.buffStart
	else
		if self.iconBackground then
			self.icon:SetSprite(EmptyBuffIcon)
		else
			self.icon:Show(false)
		end
	end
	self.isSet = true
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

function Icon:ClearBuff()
	if self.isActive then
		if self.iconType ~= "Cooldown" then
			Sound.Play(self.iconSound)
		end
		local spriteIcon = self.iconBackground and EmptyBuffIcon or ""
		if self.iconType ~= "Cooldown" and (self.iconShown == "Inactive" or self.iconShown == "Both") then
			if self.lastSprite == nil or self.lastSprite == "" then
				self.lastSprite = self:GetSpellIconByName(self.iconName)
			end
			spriteIcon = self.lastSprite
			self.icon:Show(true)
		end
		self.duration = 0
		
		if spriteIcon == "" then
			self.icon:Show(false)
		else
			self:SetSprite(spriteIcon)
		end
		self.icon:SetBGColor(ApolloColor.new(1, 0, 0, 1))
		self.icon:FindChild("IconText"):SetText("")
		self.isActive = false
	end
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