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
				Operator = resourceEditor:FindChild("Operator"):GetText(),
				Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
				Percent = resourceEditor:FindChild("Percent"):IsChecked()
			}
		end
		if editor:FindChild("ResourceEnabled"):IsChecked() then
			local resourceEditor = editor:FindChild("Resource")
			self.TriggerDetails.Resource = {
				Operator = resourceEditor:FindChild("Operator"):GetText(),
				Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
				Percent = resourceEditor:FindChild("Percent"):IsChecked()
			}
		end
	elseif self.Type == "Health" then
		self.TriggerDetails = { 
			Target = {
				Player = editor:FindChild("TargetPlayer"):IsChecked(),
				Target = editor:FindChild("TargetTarget"):IsChecked()
			}
		}
		if editor:FindChild("HealthEnabled"):IsChecked() then
			local resourceEditor = editor:FindChild("Health")
			self.TriggerDetails.Health = {
				Operator = resourceEditor:FindChild("Operator"):GetText(),
				Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
				Percent = resourceEditor:FindChild("Percent"):IsChecked()
			}
		end
		if editor:FindChild("ShieldEnabled"):IsChecked() then
			local resourceEditor = editor:FindChild("Shield")
			self.TriggerDetails.Shield = {
				Operator = resourceEditor:FindChild("Operator"):GetText(),
				Value = tonumber(resourceEditor:FindChild("Value"):GetText()) or 0,
				Percent = resourceEditor:FindChild("Percent"):IsChecked()
			}
		end
	elseif self.Type == "Moment Of Opportunity" then
		self.TriggerDetails = { 
			Target = {
				Player = editor:FindChild("TargetPlayer"):IsChecked(),
				Target = editor:FindChild("TargetTarget"):IsChecked()
			}
		}
	elseif self.Type == "Scriptable" then
		self.TriggerDetails = {
			Script = editor:FindChild("Script"):GetText()
		}
		editor:FindChild("ScriptErrors"):SetText("")
		local script, loadScriptError = loadstring("local trigger = ...\n" .. self.TriggerDetails.Script)
		if script ~= nil then
			local status, result = pcall(script, self)
			if not status then
				editor:FindChild("ScriptErrors"):SetText(tostring(result))
			end
		else
			editor:FindChild("ScriptErrors"):SetText("Unable to load script due to a syntax error: " .. tostring(loadScriptError))
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
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
		if self.TriggerDetails.Target.Player then
			self:AddCooldownToBuffWatch("Player")
		end
		if self.TriggerDetails.Target.Target then
			self:AddCooldownToBuffWatch("Target")
		end
	end
end

function IconTrigger:AddCooldownToBuffWatch(option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][option] == nil then
		self.buffWatch[triggerType][option] = {}
	end
	self.buffWatch[triggerType][option][tostring(self)] = function(result) self:ProcessOptionEvent(result) end
end

function IconTrigger:AddBasicToBuffWatch()
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType] == nil then
		self.buffWatch[triggerType] = {}
	end
	self.buffWatch[triggerType][tostring(self)] = function(result) self:ProcessEvent(result) end
end

function IconTrigger:AddBuffToBuffWatch(target, option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][target][option] == nil then
		self.buffWatch[triggerType][target][option] = {}
	end
	self.buffWatch[triggerType][target][option][tostring(self)] = function(spell) self:ProcessBuff(spell) end
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
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" then
		self:RemoveBasicFromBuffWatch()
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
		if self.TriggerDetails.Target.Player then
			self:RemoveCooldownFromBuffWatch("Player")
		end
		if self.TriggerDetails.Target.Target then
			self:RemoveCooldownFromBuffWatch("Target")
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
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][option] ~= nil then
		self.buffWatch[triggerType][option][tostring(self)] = nil
	end
end

function IconTrigger:RemoveBuffFromBuffWatch(target, option)
	local triggerType = string.gsub(self.Type, " ", "")
	if self.buffWatch[triggerType][target][option] ~= nil then
		self.buffWatch[triggerType][target][option][tostring(self)] = nil
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
	if self.Type == "Scriptable" then
		self:ProcessScriptable()
	end

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

function IconTrigger:ProcessScriptable()
	local script = loadstring("local trigger = ...\n" .. self.TriggerDetails.Script)
	if script ~= nil then
		local status, result = pcall(script, self)
		if status then
			self.isSet = result
		end
	end
end

function IconTrigger:ProcessOptionEvent(result)
	if self.Type == "Cooldown" then
		self:ProcessSpell(result)
	elseif self.Type == "Health" then
		self:ProcessHealth(result)
	elseif self.Type == "Moment Of Opportunity" then
		self:ProcessMOO(result)
	end
end

function IconTrigger:ProcessSpell(spell)
	local cdRemaining, cdTotal, chargesRemaining = self:GetSpellCooldown(spell)

	self.Charges = chargesRemaining
	self.Time = cdRemaining
	self.MaxDuration = cdTotal
	self.Sprite = spell:GetIcon()

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
	self.Sprite = buff.splEffect:GetIcon()
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

function IconTrigger:ProcessHealth(result)
	self.isSet = true
	if self.TriggerDetails["Health"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Health, result.Health, result.MaxHealth)
	end

	if self.TriggerDetails["Shield"] ~= nil then
		self.isSet = self.isSet and self:ProcessResource(self.TriggerDetails.Shield, result.Shield, result.MaxShield)
	end
end

function IconTrigger:ProcessResource(operation, resource, maxResource)
	local resourceValue = 0
	if resource ~= nil then
		if operation.Percent then
			resourceValue = (resource / maxResource) * 100
		else
			resourceValue = resource
		end

		if operation.Operator == "==" then
			return resourceValue == operation.Value
		elseif operation.Operator == "!=" then
			return resourceValue ~= operation.Value
		elseif operation.Operator == ">" then
			return resourceValue > operation.Value
		elseif operation.Operator == "<" then
			return resourceValue < operation.Value
		elseif operation.Operator == ">=" then
			return resourceValue >= operation.Value
		elseif operation.Operator == "<=" then
			return resourceValue <= operation.Value
		end
	end
end

function IconTrigger:ProcessMOO(result)
	if result.TimeRemaining > 0 then
		self.isSet = true
		self.Time = result.TimeRemaining
		if self.MaxDuration == nil or self.MaxDuration < self.Time then
			self.MaxDuration = self.Time
		end
	else
		self.MaxDuration = nil
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)