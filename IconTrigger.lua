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
	self.Behaviour = "Pass"
	self.TriggerDetails = {}

	self.isSet = false

	return self
end

function IconTrigger:Load(saveData)
	if saveData ~= nil then
		self.Name = saveData.Name
		self.Type = saveData.Type
		self.Behaviour = saveData.Behaviour or "Pass"
		self.TriggerDetails = saveData.TriggerDetails

		self:AddToBuffWatch()
	end
end

function IconTrigger:Save()
	local saveData = { }
	saveData.Name = self.Name
	saveData.Type = self.Type
	saveData.Behaviour = self.Behaviour
	saveData.TriggerDetails = self.TriggerDetails
	return saveData
end

function IconTrigger:SetConfig(editor)
	self:RemoveFromBuffWatch()

	self.Name = editor:FindChild("TriggerName"):GetText()
	self.Type = editor:FindChild("TriggerType"):GetText()
	self.Behaviour = editor:FindChild("TriggerBehaviour"):GetText()

	if self.Type == "Action Set" then
		self.TriggerDetails = {	
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
	elseif self.Type == "Resources" then
		self.TriggerDetails = { }
		if editor:FindChild("ManaEnabled"):IsChecked() then
			local resourceEditor = editor:FindChild("Mana")
			self.TriggerDetails.Mana = {
				Operator = ">",
				Value = tonumber(resourceEditor:FindChild("Value"):GetText())
			}
		end
		if editor:FindChild("ResourceEnabled"):IsChecked() then
			local resourceEditor = editor:FindChild("Resource")
			self.TriggerDetails.Resource = {
				Operator = ">",
				Value = tonumber(resourceEditor:FindChild("Value"):GetText())
			}
		end
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
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" then
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
	self.buffWatch[triggerType][tostring(self)] = function(result) self:ProcessEvent(result) end
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
	self.Stacks = nil
	self.Time = nil
	if self.Type ~= "Action Set" then
		self.isSet = false
	end
end

function IconTrigger:IsSet()
	if self.Behaviour == "Pass" then
		return self.isSet
	elseif self.Behaviour == "Fail" then
		return not self.isSet
	elseif self.Behaviour == "Ignore" then
		return true
	end
	return false
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

	self.Charges = chargesRemaining
	self.Time = cdRemaining
	self.MaxDuration = cdTotal

	if chargesRemaining > 0 or cdRemaining == 0 then
		self.isSet = false
		if cdRemaining == 0 then
			self.Time = 0
		end
	else
		self.isSet = true
	end
end

function IconTrigger:ProcessBuff(buff)
	self.isSet = true
	self.Time = buff.fTimeRemaining
	if self.MaxDuration == nil or self.MaxDuration < self.Time then
		self.MaxDuration = self.Time
	end
	self.Stacks = buff.nCount
end

function IconTrigger:ProcessEvent(result)
	if self.Type == "Action Set" then
		self.isSet = self.TriggerDetails.ActionSets[result]
	elseif self.Type == "Resources" then
		return self:ProcessResources(result)
	else
		self.isSet = true
	end
end

function IconTrigger:ProcessResources(result)
	self.isSet = true
	if self.TriggerDetails["Mana"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Mana, result.Mana, result.MaxMana)
	end

	if self.TriggerDetails["Resource"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Resource, result.Resource, result.MaxResource)
	end
end

function IconTrigger:ProcessResource(operation, resource, maxResource)
	if operation.Operator == "==" then
		return resource == operation.Value
	elseif operation.Operator == "!=" then
		return resource ~= operation.Value
	elseif operation.Operator == ">" then
		return resource > operation.Value
	elseif operation.Operator == "<" then
		return resource < operation.Value
	elseif operation.Operator == ">=" then
		return resource >= operation.Value
	elseif operation.Operator == "<=" then
		return resource <= operation.Value
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)