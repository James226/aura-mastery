-----------------------------------------------------------------------------------------------
-- Client Lua Script for AuraMastery
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local Icon  = {} 
Icon.__index = Icon

setmetatable(Icon, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local EmptyBuffIcon = "CRB_ActionBarFrameSprites:sprActionBarFrame_VehicleIconBG"

function Icon.new(buffWatch, iconForm, saveData, position)
	if position == nil then
		position = 0
	end
	local self = setmetatable({}, Icon)
	self.iconForm = iconForm
	self.buffWatch = buffWatch
	self.icon = Apollo.LoadForm("AuraMastery.xml", "Icon", self.iconForm, self)
	self.icon:SetAnchorOffsets((position  - 1)*50, 0, ((position - 1)*50)+50, 50)
	
	self.iconType = "Buff"
	self.iconName = ""
	self.iconTarget = "Player"
	self.iconShown = "Active"
	self.iconSound = -1
	self.iconBackground = true
	self.buffStart = 0
	
	--self:Load(saveData)
	
	self.isActive = true
	
	self:AddToBuffWatch()
	
	return self
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
	return saveData
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
	if chargesRemaining > 0 or cdRemaining == 0 then
		self.icon:SetBGColor(ApolloColor.new(1, 1, 1, 1))
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
	if configWnd:FindChild("SoundSelect"):FindChild("SelectedSound") ~= nil then
		self.iconSound = tonumber(configWnd:FindChild("SoundSelect"):FindChild("SelectedSound"):GetText())
	else
		self.iconSound = nil
	end
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
end

function Icon:SetSpell(spell, remaining, total, charges)
	self.icon:SetSprite(spell:GetIcon())
	self.icon:Show(true)
	self.icon:FindChild("IconOverlay"):SetAnchorPoints(0, 1 - (remaining / total), 1, 1)
	
	if remaining == 0 then
		self.icon:SetText("")
	else	
		if remaining > 60 then	
			self.icon:SetText(string.format("%i:%02d", math.floor(remaining / 60), math.floor(remaining % 60)))
		else
			self.icon:SetText(string.format("%.2fs", remaining))
		end		
	end
	self.isSet = true
end

function Icon:SetBuff(buff)
	if not self.isActive or buff.fTimeRemaining > self.buffStart then
		self.isActive = true
		self.buffStart = buff.fTimeRemaining
		self.icon:SetBGColor(ApolloColor.new(1, 1, 1, 1))
	end
	self.lastSprite = buff.spell:GetIcon()
	
	if self.iconShown == "Active" or self.iconShown == "Both" then
		self.icon:SetSprite(buff.spell:GetIcon())
		self.icon:Show(true)
		self.icon:FindChild("IconOverlay"):SetAnchorPoints(0, 1 - (buff.fTimeRemaining / self.buffStart), 1, 1)
		
		if buff.fTimeRemaining > 0 then
			if buff.fTimeRemaining > 60 then
				self.icon:SetText(string.format("%i:%02d", math.floor(buff.fTimeRemaining / 60), math.floor(buff.fTimeRemaining % 60)))
			else
				self.icon:SetText(string.format("%.2fs", buff.fTimeRemaining))
			end
		end
	else
		if self.iconBackground then
			self.icon:SetSprite(EmptyBuffIcon)
		else
			self.icon:Show(false)
		end
	end
	self.isSet = true
end

function Icon:ClearBuff()
	if self.isActive then
		if self.iconType ~= "Cooldown" then
			Sound.Play(self.iconSound)
		end
		local spriteIcon = self.iconBackground and EmptyBuffIcon or ""
		if self.lastSprite ~= nil and self.iconType ~= "Cooldown" and (self.iconShown == "Inactive" or self.iconShown == "Both") then
			spriteIcon = self.lastSprite
			self.icon:Show(true)
		end
		self.icon:FindChild("IconOverlay"):SetAnchorPoints(0, 0, 1, 0)
		self.icon:SetBGColor(ApolloColor.new(1, 0, 0, 1))
		self.icon:SetSprite(spriteIcon)
		if spriteIcon == "" then
			self.icon:Show(false)
		end
		self.icon:SetText("")
		self.isActive = false
	end
end


if _G["AuraMasteryLibs"] == nil then
	_G["AuraMasteryLibs"] = { }
end
_G["AuraMasteryLibs"]["Icon"] = Icon