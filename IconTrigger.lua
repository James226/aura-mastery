require "Window"

local IconTrigger  = {} 
IconTrigger .__index = IconTrigger

setmetatable(IconTrigger, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function IconTrigger.new(buffWatch)
	local self = setmetatable({}, IconTrigger)

	self.buffWatch = buffWatch

	self.Name = ""
	self.Type = "Cooldown"
	self.TriggerDetails = {}

	self.isSet = false

	return self
end

function IconTrigger:Load(saveData)
	if saveData ~= nil then
		self.Name = saveData.Name
		self.Type = saveData.Type
		self.TriggerDetails = saveData.TriggerDetails

		self:AddToBuffWatch()
	end
end

function IconTrigger:Save()
	local saveData = { }
	saveData.Name = self.Name
	saveData.Type = self.Type
	saveData.TriggerDetails = self.TriggerDetails
	return saveData
end

function IconTrigger:SetConfig(editor)
	self:RemoveFromBuffWatch()

	self.Name = editor:FindChild("TriggerName"):GetText()
	self.Type = editor:FindChild("TriggerType"):GetText()

	if self.Type == "Action Set" then
		self.selfDetails = {	
			ActionSets = {
				editor:FindChild("ActionSet1"):IsChecked(),
				editor:FindChild("ActionSet2"):IsChecked(),
				editor:FindChild("ActionSet3"):IsChecked(),
				editor:FindChild("ActionSet4"):IsChecked()
			}
		}
	elseif self.Type == "Cooldown" then
		self.TriggerDetails = {
			SpellName = editor:FindChild("SpellName"):GetText()
		}
	elseif self.Type == "Buff" then
		self.TriggerDetails = {
			BuffName = editor:FindChild("BuffName"):GetText(),
			Target = {
				Player = editor:FindChild("TargetPlayer"):IsChecked(),
				Target = editor:FindChild("TargetTarget"):IsChecked()
			}
		}
	elseif self.Type == "Debuff" then
		self.TriggerDetails = {
			DebuffName = editor:FindChild("DebuffName"):GetText(),
			Target = {
				Player = editor:FindChild("TargetPlayer"):IsChecked(),
				Target = editor:FindChild("TargetTarget"):IsChecked()
			}
		}
	end

	self:AddToBuffWatch()
end

function IconTrigger:AddToBuffWatch()
	if self.Type == "Cooldown" then
		self:AddCooldownToBuffWatch(self.TriggerDetails.SpellName)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
		if self.TriggerDetails.Target.Player then
			self:AddBuffToBuffWatch("Player", self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName)
		end
		
		if self.TriggerDetails.Target.Target then
			self:AddBuffToBuffWatch("Target", self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName)
		end
	elseif self.Type == "On Critical" then
		self:AddBasicToBuffWatch()
	end
end

function IconTrigger:AddCooldownToBuffWatch(option)
	if self.buffWatch[self.Type][option] == nil then
		self.buffWatch[self.Type][option] = {}
	end
	self.buffWatch[self.Type][option][tostring(self)] = function(buff) self:ProcessSpell(buff) end
end

function IconTrigger:AddBasicToBuffWatch()
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType] == nil then
		self.buffWatch[triggerType] = {}
	end
	self.buffWatch[triggerType][tostring(self)] = function() self:ProcessEvent() end
end

function IconTrigger:AddBuffToBuffWatch(target, option)
	if self.buffWatch[self.Type][target][option] == nil then
		self.buffWatch[self.Type][target][option] = {}
	end
	self.buffWatch[self.Type][target][option][tostring(self)] = function(spell) self:ProcessBuff(spell) end
end

function IconTrigger:RemoveFromBuffWatch()
	if self.Type == "Cooldown" then
		self:RemoveCooldownFromBuffWatch(self.TriggerDetails.SpellName)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
		if self.TriggerDetails.Target.Player then
			self:RemoveBuffFromBuffWatch("Player", self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName)
		end
		
		if self.TriggerDetails.Target.Target then
			self:RemoveBuffFromBuffWatch("Target", self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName)
		end
	end
end

function IconTrigger:RemoveBasicFromBuffWatch()
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType] ~= nil then
		self.buffWatch[triggerType][tostring(self)] = nil
	end
end

function IconTrigger:RemoveCooldownFromBuffWatch(option)
	if self.buffWatch[self.Type][option] ~= nil then
		self.buffWatch[self.Type][option][tostring(self)] = nil
	end
end

function IconTrigger:RemoveBuffFromBuffWatch(target, option)
	if self.buffWatch[self.Type][target][option] ~= nil then
		self.buffWatch[self.Type][target][option][tostring(self)] = nil
	end
end

function IconTrigger:ResetTrigger()
	self.isSet = false
end

function IconTrigger:IsSet()
	return self.isSet
end

function IconTrigger:GetSpellCooldown(spell)
	local charges = spell:GetAbilityCharges()
	if charges and charges.nChargesMax > 0 then
		return charges.fRechargePercentRemaining * charges.fRechargeTime, charges.fRechargeTime, charges.nChargesRemaining
	else
		return spell:GetCooldownRemaining(), spell:GetCooldownTime(), 0
	end
end

function IconTrigger:ProcessSpell(spell)
	local cdRemaining, cdTotal, chargesRemaining = self:GetSpellCooldown(spell)
	self.chargesRemaining = chargesRemaining
	if chargesRemaining > 0 or cdRemaining == 0 then
		self.isSet = false
		self.Time = 0
	else
		self.isSet = true
		self.Time = cdRemaining
		self.MaxDuration = cdTotal
	end
end

function IconTrigger:ProcessBuff(buff)
	self.isSet = true
	self.Time = buff.fTimeRemaining
	if self.MaxDuration == nil or self.MaxDuration < self.Time then
		self.MaxDuration = self.Time
	end
end

function IconTrigger:ProcessEvent()
	self.isSet = true
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)