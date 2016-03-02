require "Window"

local IconTrigger  = {}
IconTrigger .__index = IconTrigger

setmetatable(IconTrigger, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function IndexOf(table, item)
    for idx, val in pairs(table) do
        if item == val then
            return idx
        end
    end
end

local function CatchError(func)
    local status, error = pcall(func)

    if not status then
        Print("[AuraMastery] An error has occured")
        Print(error)
    end
end

function IconTrigger.new(icon, buffWatch)
	local self = setmetatable({}, IconTrigger)

	self.buffWatch = buffWatch

	self.Name = ""
	self.Type = "Cooldown"
	self.Behaviour = "Pass"
    self.TriggerDetails = {
        SpellName = "",
        Charges = {
            Enabled = false,
            Operator = "==",
            Value = 1
        }
    }
	self.TriggerEffects = {}
	self.Icon = icon

	self.isSet = false

	self.lastKeypress = 0
    self.Time = 0
    self.Stacks = 0
    self.LastEvent = 0

    self.Units = {}

	return self
end

function IconTrigger:Load(saveData)
	if saveData ~= nil then
		self.Name = (not string.match(saveData.Name, "Trigger ([0-9]+)")) and saveData.Name or ""
		self.Type = saveData.Type
		self.Behaviour = saveData.Behaviour or "Pass"
		self.TriggerDetails = saveData.TriggerDetails

		if self.Type == "Buff" or self.Type == "Debuff" then
			if not self.TriggerDetails.Stacks then
				self.TriggerDetails.Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			end
		elseif self.Type == "Cooldown" then
			if not self.TriggerDetails.Charges then
				self.TriggerDetails.Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			end
		elseif self.Type == "Keybind" then
			if self.TriggerDetails.Key ~= nil then
				self.TriggerDetails.Input = {
					Key = self.TriggerDetails.Key,
					Shift = false,
					Control = false,
					Alt = false
				}
				self.TriggerDetails.Key = nil
			end
		end

		if saveData.TriggerEffects ~= nil then
			GeminiPackages:Require('AuraMastery:TriggerEffect', function(TriggerEffect)
				for _, triggerEffectData in pairs(saveData.TriggerEffects) do
					local triggerEffect = TriggerEffect.new(self)
					triggerEffect:Load(triggerEffectData)
					table.insert(self.TriggerEffects, triggerEffect)
				end
			end)
		end

		self:AddToBuffWatch()
	end
end

function IconTrigger:Save()
	local saveData = { }
	saveData.Name = self.Name
	saveData.Type = self.Type
	saveData.Behaviour = self.Behaviour
	saveData.TriggerDetails = self.TriggerDetails
	saveData.TriggerEffects = {}
	for _, triggerEffect in pairs(self.TriggerEffects) do
		table.insert(saveData.TriggerEffects, triggerEffect:Save())
	end
	return saveData
end

function IconTrigger:SetConfig(editor)
	self:RemoveFromBuffWatch()
	if self.Icon.SimpleMode then
		self.Type = string.sub(editor:FindChild("AuraType"):GetData():GetName(), 10)
		self.Name = self.Type .. ":" .. self.Icon.iconName

		if self.Type == "Cooldown" then
			self.TriggerDetails = {
				SpellName = self.Icon.iconName,
				Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		elseif self.Type == "Buff" then
			self.TriggerDetails = {
				BuffName = self.Icon.iconName,
				Target = {
					Player = editor:FindChild("AuraBuffUnit_Player"):IsChecked(),
					Target = editor:FindChild("AuraBuffUnit_Target"):IsChecked()
				},
				Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		elseif self.Type == "Debuff" then
			self.TriggerDetails = {
				DebuffName = self.Icon.iconName,
				Target = {
					Player = editor:FindChild("AuraBuffUnit_Player"):IsChecked(),
					Target = editor:FindChild("AuraBuffUnit_Target"):IsChecked()
				},
				Stacks = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
		end
	else
		self.Name = editor:FindChild("TriggerName"):GetText()
		self.Type = editor:FindChild("TriggerType"):GetText()
		self.Behaviour = editor:FindChild("TriggerBehaviour"):GetText()
		local selectedTriggerEffectItem = editor:FindChild("TriggerEffectsList"):GetData()
		if selectedTriggerEffectItem ~= nil and selectedTriggerEffectItem:GetData() ~= nil then
			selectedTriggerEffectItem:GetData():SetConfig(editor:FindChild("TriggerEffects"))
		end

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
				SpellName = editor:FindChild("SpellName"):GetText(),
				Charges = {
					Enabled = editor:FindChild("ChargesEnabled"):IsChecked(),
					Operator = editor:FindChild("Charges"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Charges"):FindChild("ChargesValue"):GetText())
				}
			}
		elseif self.Type == "Buff" then
			self.TriggerDetails = {
				BuffName = editor:FindChild("BuffName"):GetText(),
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
                    Target = editor:FindChild("TargetTarget"):IsChecked(),
                    TargetOfTarget = editor:FindChild("TargetTargetOfTarget"):IsChecked(),
                    FocusTarget = editor:FindChild("TargetFocusTarget"):IsChecked(),
                    FocusTargetTarget = editor:FindChild("TargetFocusTargetTarget"):IsChecked(),
                    Tank = editor:FindChild("TargetTank"):IsChecked(),
                    Healer = editor:FindChild("TargetHealer"):IsChecked(),
                    DPS = editor:FindChild("TargetDPS"):IsChecked(),
                    Friendly = editor:FindChild("TargetFriendly"):IsChecked(),
                    Hostile = editor:FindChild("TargetHostile"):IsChecked(),
                    Named = editor:FindChild("TargetNamed"):IsChecked(),
					NamedUnit = editor:FindChild("TargetNamedUnit"):GetText()
				},
				Stacks = {
					Enabled = editor:FindChild("StacksEnabled"):IsChecked(),
					Operator = editor:FindChild("Stacks"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Stacks"):FindChild("StacksValue"):GetText())
				}
			}
		elseif self.Type == "Debuff" then
			self.TriggerDetails = {
				DebuffName = editor:FindChild("DebuffName"):GetText(),
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
					Target = editor:FindChild("TargetTarget"):IsChecked(),
                    TargetOfTarget = editor:FindChild("TargetTargetOfTarget"):IsChecked(),
                    FocusTarget = editor:FindChild("TargetFocusTarget"):IsChecked(),
                    FocusTargetTarget = editor:FindChild("TargetFocusTargetTarget"):IsChecked(),
                    Tank = editor:FindChild("TargetTank"):IsChecked(),
                    Healer = editor:FindChild("TargetHealer"):IsChecked(),
                    DPS = editor:FindChild("TargetDPS"):IsChecked(),
                    Friendly = editor:FindChild("TargetFriendly"):IsChecked(),
					Hostile = editor:FindChild("TargetHostile"):IsChecked(),
                    Named = editor:FindChild("TargetNamed"):IsChecked(),
					NamedUnit = editor:FindChild("TargetNamedUnit"):GetText()
				},
				Stacks = {
					Enabled = editor:FindChild("StacksEnabled"):IsChecked(),
					Operator = editor:FindChild("Stacks"):FindChild("Operator"):GetText(),
					Value = tonumber(editor:FindChild("Stacks"):FindChild("StacksValue"):GetText())
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
                    Target = editor:FindChild("TargetTarget"):IsChecked(),
                    TargetOfTarget = editor:FindChild("TargetTargetOfTarget"):IsChecked(),
                    FocusTarget = editor:FindChild("TargetFocusTarget"):IsChecked(),
                    FocusTargetTarget = editor:FindChild("TargetFocusTargetTarget"):IsChecked(),
                    Tank = editor:FindChild("TargetTank"):IsChecked(),
                    Healer = editor:FindChild("TargetHealer"):IsChecked(),
                    DPS = editor:FindChild("TargetDPS"):IsChecked(),
                    Friendly = editor:FindChild("TargetFriendly"):IsChecked(),
                    Hostile = editor:FindChild("TargetHostile"):IsChecked(),
                    Named = editor:FindChild("TargetNamed"):IsChecked(),
					NamedUnit = editor:FindChild("TargetNamedUnit"):GetText()
                },
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
		elseif self.Type == "Limited Action Set Checker" then
			self.TriggerDetails = {
				AbilityName = editor:FindChild("AbilityName"):GetText()
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
		elseif self.Type == "Keybind" then
			self.TriggerDetails = {
				Input = editor:FindChild("KeybindTracker_KeySelect"):GetData(),
				Duration = tonumber(editor:FindChild("KeybindTracker_Duration"):GetText()) or 1
			}
			editor:FindChild("KeybindTracker_Duration"):SetText(tostring(self.TriggerDetails.Duration))
		elseif self.Type == "Gadget" then
			self.TriggerDetails = {
				Charges = {
					Enabled = false,
					Operator = "==",
					Value = 0
				}
			}
        elseif self.Type == "Cast" then
            self.TriggerDetails = {
				SpellName = editor:FindChild("SpellName"):GetText(),
				Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
                    Target = editor:FindChild("TargetTarget"):IsChecked(),
                    FocusTarget = editor:FindChild("TargetFocusTarget"):IsChecked(),
                    Named = editor:FindChild("TargetNamed"):IsChecked(),
					NamedUnit = editor:FindChild("TargetNamedUnit"):GetText()
				},
            }
        elseif self.Type == "ICD" then
            self.TriggerDetails = {
                SpellName = editor:FindChild("SpellName"):GetText(),
                Duration = tonumber(editor:FindChild("Duration"):GetText()),
                EventType = editor:FindChild("EventType"):GetData(),
                Target = {
					Player = editor:FindChild("TargetPlayer"):IsChecked(),
                    Target = editor:FindChild("TargetTarget"):IsChecked(),
                    FocusTarget = editor:FindChild("TargetFocusTarget"):IsChecked(),
				},
            }
		end
	end
	self:AddToBuffWatch()
end

function IconTrigger:RemoveEffect(effect)
	for triggerId, triggerEffect in pairs(self.TriggerEffects) do
		if triggerEffect == effect then
			table.remove(self.TriggerEffects, triggerId)
			break
		end
	end
end

function IconTrigger:AddUnit(unit)
    if unit ~= nil then
        self.Units[unit:GetId()] = { Unit = unit }
    end
end

function IconTrigger:RemoveUnit(unit)
    if unit ~= nil then
        self.Units[unit:GetId()] = nil
    end
end

function IconTrigger:AddToBuffWatch()
    self.Units = {}
	if self.Type == "Cooldown" then
		self.currentSpell = self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName
		self:AddCooldownToBuffWatch(self.currentSpell)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
        Print("Add: " .. self.Icon.iconName)
		self.buffName = self.Type == "Buff" and self.TriggerDetails.BuffName or self.TriggerDetails.DebuffName
		if self.buffName == "" then
			self.buffName = self.Icon.iconName
		end

        for target, val in pairs(self.TriggerDetails.Target) do
            if val then
                if target == "Named" then
                elseif target == "NamedUnit" then
                    self:AddBuffToBuffWatch(val, self.buffName)
                else
                    self:AddBuffToBuffWatch(target, self.buffName)
                end
            end
        end
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" or self.Type == "Gadget" then
		self:AddBasicToBuffWatch()
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
        for target, val in pairs(self.TriggerDetails.Target) do
            if val then
                if target == "Named" then
                elseif target == "NamedUnit" then
                    self:AddCooldownToBuffWatch(val)
                else
                    self:AddCooldownToBuffWatch(target)
                end
            end
        end
	elseif self.Type == "Keybind" then
		self:AddCooldownToBuffWatch(self.TriggerDetails.Input.Key)
	elseif self.Type == "Limited Action Set Checker" then
		self.currentSpell = self.TriggerDetails.AbilityName == "" and self.Icon.iconName or self.TriggerDetails.AbilityName
		self:AddCooldownToBuffWatch(self.currentSpell)
	elseif self.Type == "Cast" then
        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
        if self.TriggerDetails.Target.Player then
            self:AddUnit(GameLib.GetPlayerUnit())
        end
        if self.TriggerDetails.Target.Target then
            local target = GameLib.GetTargetUnit()
            if target ~= nil then
                self:OnTargetChanged(target)
            end
        	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetChanged", self)
        end
        if self.TriggerDetails.Target.FocusTarget then
            local focus = GameLib.GetPlayerUnit():GetAlternateTarget()
            if focus ~= nil then
                self:OnAlternateTargetUnitChanged(focus)
            end
            Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)
        end
    elseif self.Type == "ICD" then
        if self.TriggerDetails.EventType == "DamageDone" then
            Apollo.RegisterEventHandler("CombatLogDamage", "OnICDDamageDone", self)
        elseif self.TriggerDetails.EventType == "HealingDone" then
            Apollo.RegisterEventHandler("CombatLogHeal", "OnICDDamageDone", self)
        elseif self.TriggerDetails.EventType == "Buff" or self.TriggerDetails.EventType == "Debuff" then
            Apollo.RegisterEventHandler("BuffAdded", "OnICDBuff", self)
        elseif self.TriggerDetails.EventType == "ResourceGain" then
            Apollo.RegisterEventHandler("CombatLogVitalModifier", "OnICDResourceGain", self)
        end
    end
end

function IconTrigger:OnICDDamageDone(data)
    CatchError(function()
        if data.unitCaster:IsThePlayer() then
            local spell = data.splCallingSpell
            local spellName = self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName
            if spell:GetName() == spellName or spell:GetId() == spellName then
                self.LastEvent = os.clock()
            end
        end
    end)
end

function IconTrigger:OnICDBuff(unit, buff)
    CatchError(function()
        if unit:IsThePlayer() then
            local spell = buff.splEffect
            local spellName = self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName
            if (spell:GetName() == spellName or spell:GetId() == spellName) and spell:IsBeneficial() == (self.TriggerDetails.EventType == "Buff") then
                self.LastEvent = os.clock()
            end
        end
    end)
end

function IconTrigger:OnICDResourceGain(data)
    CatchError(function()
        SendVarToRover("Resource", data)
        if data.unitCaster:IsThePlayer() then
            local spell = data.splCallingSpell
            local spellName = self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName
            if spell:GetName() == spellName or spell:GetId() == spellName then
                self.LastEvent = os.clock()
            end
        end
    end)
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
	if self.buffWatch[triggerType][target] == nil then
		self.buffWatch[triggerType][target] = {}
	end
	if self.buffWatch[triggerType][target][option] == nil then
		self.buffWatch[triggerType][target][option] = {}
	end
	self.buffWatch[triggerType][target][option][tostring(self)] = function(spell) self:ProcessBuff(spell) end
    table.insert(self.buffWatch.Refresh, { Type = triggerType, Target = target })
end

function IconTrigger:RemoveFromBuffWatch()
	if self.Type == "Cooldown" or self.Type == "Limited Action Set Checker" then
		self:RemoveCooldownFromBuffWatch(self.currentSpell)
	elseif self.Type == "Buff" or self.Type == "Debuff" then
        Print("Remove: " .. self.Icon.iconName)
		if self.TriggerDetails.Target.Player then
			self:RemoveBuffFromBuffWatch("Player", self.buffName)
		end

		if self.TriggerDetails.Target.Target then
			self:RemoveBuffFromBuffWatch("Target", self.buffName)
		end
	elseif self.Type == "On Critical" or self.Type == "On Deflect" or self.Type == "Action Set" or self.Type == "Resources" or self.Type == "Gadget" then
		self:RemoveBasicFromBuffWatch()
	elseif self.Type == "Health" or self.Type == "Moment Of Opportunity" then
		if self.TriggerDetails.Target.Player then
			self:RemoveCooldownFromBuffWatch("Player")
		end
		if self.TriggerDetails.Target.Target then
			self:RemoveCooldownFromBuffWatch("Target")
		end
	elseif self.Type == "Keybind" then
		self:RemoveCooldownFromBuffWatch(self.TriggerDetails.Input.Key)
    end
    Apollo.RemoveEventHandler("TargetUnitChanged", self)
    Apollo.RemoveEventHandler("AlternateTargetUnitChanged", self)
    Apollo.RemoveEventHandler("UnitCreated", self)
    Apollo.RemoveEventHandler("UnitDestroyed", self)
    Apollo.RemoveEventHandler("CombatLogDamage", self)
    Apollo.RemoveEventHandler("CombatLogHeal", self)
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

function IconTrigger:ResetTrigger(deltaTime)
    -- for _, u in pairs(self.Units) do
    --     for _, b in pairs(u.Buffs) do
    --         b.fTimeRemaining = b.fTimeRemaining - deltaTime
    --     end
    -- end

    if self.Type == "Buff" or self.Type == "Debuff" then
        if self.Time == nil then
            self.Time = 0
        end
        self.Time = math.max(self.Time - deltaTime, 0)
        return
    end
	self.Stacks = nil
	self.Time = nil
	if self.Type ~= "Action Set" and self.Type ~= "Limited Action Set Checker" and self.Type ~= "Health" then
		self.isSet = false
	end

    if self.Type == "Health" then
        for key, target in pairs(self.Units) do
            if (target.LastUpdate or 0) > 1 then
                local unit = target.Unit
                local data = {
                    Action = "Update",
                    Id = key,
                    Unit = unit,
                    Health = unit:GetHealth(),
                    MaxHealth = unit:GetMaxHealth(),
                    Shield = unit:GetShieldCapacity(),
                    MaxShield = unit:GetShieldCapacityMax()
                }
                self:ProcessHealth(data)
                target.LastUpdate = 0
            else
                target.LastUpdate = (target.LastUpdate or 0) + deltaTime
            end
        end
    elseif self.Type == "Cast" then
        for _, unit in pairs(self.Units) do
            if unit.Unit:GetCastName() == (self.TriggerDetails.SpellName == "" and self.Icon.iconName or self.TriggerDetails.SpellName) then
                self.MaxDuration = unit.Unit:GetCastDuration() / 1000
                self.Time = self.MaxDuration - (unit.Unit:GetCastElapsed() / 1000)
                self.isSet = self.Time > 0
            end
        end
    end
end

function IconTrigger:OnUnitCreated(unit)

    if (self.TriggerDetails.Target and unit == GameLib.GetTargetUnit()) then
        return self:OnTargetChanged(nil)
    end

    if (self.TriggerDetails.FocusTarget and unit == GameLib.GetPlayerUnit():GetAlternateTarget()) then
        return self:OnAlternateTargetUnitChanged(nil)
    end

    local disposition = unit:GetDispositionTo(GameLib.GetPlayerUnit())
    if (self.TriggerDetails.Player and unit:IsThePlayer()) or
        (self.TriggerDetails.Friendly and disposition == Unit.CodeEnumDisposition.Friendly) or
        (self.TriggerDetails.Hostile and disposition ~= Unit.CodeEnumDisposition.Friendly) or
        (self.TriggerDetails.Named and unit:GetName() == self.TriggerDetails.NamedUnit) then
        self:AddUnit(unit)
    end
end

function IconTrigger:OnUnitDestroyed(unit)

    if (self.TriggerDetails.Target and unit == GameLib.GetTargetUnit()) then
        return self:OnTargetChanged(nil)
    end

    if (self.TriggerDetails.FocusTarget and unit == GameLib.GetPlayerUnit():GetAlternateTarget()) then
        return self:OnAlternateTargetUnitChanged(nil)
    end

    local disposition = unit:GetDispositionTo(GameLib.GetPlayerUnit())
    if (self.TriggerDetails.Player and unit:IsThePlayer()) or
        (self.TriggerDetails.Friendly and disposition == Unit.CodeEnumDisposition.Friendly) or
        (self.TriggerDetails.Hostile and disposition ~= Unit.CodeEnumDisposition.Friendly) or
        (self.TriggerDetails.Named and unit:GetName() == self.TriggerDetails.NamedUnit) then
        self:RemoveUnit(unit)
    end
end

function IconTrigger:OnTargetChanged(unit)
    if self.targetUnit ~= nil then
        self:RemoveUnit(self.targetUnit)
    end
    if unit ~= nil then
        self:AddUnit(unit)
    end
    self.targetUnit = unit
end

function IconTrigger:OnAlternateTargetUnitChanged(unit)
    if self.focusTarget ~= nil then
        self:RemoveUnit(self.focusTarget)
    end
    if unit ~= nil then
        self:AddUnit(unit)
    end
    self.focusTarget = unit
end

function IconTrigger:GetTargets()
    local targets = {}
    if self.TriggerDetails.Player then
        table.insert(targets, GameLib.GetPlayerUnit())
    end
    if self.TriggerDetails.Target then
        table.insert(targets, GameLib.GetTargetUnit())
    end
    if self.TriggerDetails.TargetOfTarget then
        table.insert(targets, GameLib.GetPlayerUnit())
    end
    if self.TriggerDetails.FocusTarget then
        table.insert(targets, GameLib.GetPlayerUnit())
    end
    if self.TriggerDetails.Player then
        table.insert(targets, GameLib.GetPlayerUnit())
    end
    if self.TriggerDetails.Player then
        table.insert(targets, GameLib.GetPlayerUnit())
    end
end

function IconTrigger:IsPass()
	if self.Behaviour == "Pass" then
		return self.isSet
	elseif self.Behaviour == "Fail" then
		return not self.isSet
	elseif self.Behaviour == "Ignore" then
		return true
	end
	return false
end

function IconTrigger:IsSet()
	if self.Type == "Scriptable" then
		self:ProcessScriptable()
	elseif self.Type == "Keybind" then
		local timeSinceKeypress = (Apollo.GetTickCount() - self.lastKeypress) / 1000
		self.isSet = timeSinceKeypress < self.TriggerDetails.Duration
		if self.isSet then
			self.Time = self.TriggerDetails.Duration - timeSinceKeypress
			self.MaxDuration = self.TriggerDetails.Duration
		end
    elseif self.Type == "ICD" then
        local currentTime = os.clock()
        local activeTime = self.TriggerDetails.Duration
        if self.LastEvent + activeTime > currentTime then
            self.isSet = true
            self.Time = (self.LastEvent + activeTime) - currentTime
            self.MaxDuration = activeTime
        end
	end

	self.isPass = self:IsPass()
	return self.isPass
end

function IconTrigger:ProcessEffects()
	for _, triggerEffect in pairs(self.TriggerEffects) do
		triggerEffect:Update(self.isPass)
	end
end

function IconTrigger:StopEffects()
	for _, triggerEffect in pairs(self.TriggerEffects) do
		triggerEffect:EndTimed()
	end
end

function IconTrigger:GetSpellCooldown(spell)
	local charges = spell:GetAbilityCharges()
	if charges and charges.nChargesMax > 0 then
		return charges.fRechargePercentRemaining * charges.fRechargeTime, charges.fRechargeTime, charges.nChargesRemaining, charges.nChargesMax
	else
		return spell:GetCooldownRemaining(), spell:GetCooldownTime(), 0, 0
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
	elseif self.Type == "Keybind" then
		self:ProcessKeybind(result)
	elseif self.Type == "Limited Action Set Checker" then
		self:ProcessLASChange(result)
	end
end

function IconTrigger:ProcessSpell(spell)
	local cdRemaining, cdTotal, chargesRemaining, chargesMax = self:GetSpellCooldown(spell)
	self.Charges = chargesRemaining
	self.Sprite = spell:GetIcon()
	if not (self.Time and self.Time > cdRemaining) then
		self.Time = cdRemaining
		self.MaxDuration = math.max(cdRemaining, cdTotal)
		self.MaxCharges = chargesMax
		if ((not self.TriggerDetails.Charges.Enabled) and (cdRemaining == 0 or chargesRemaining > 0))
			or (self.TriggerDetails.Charges.Enabled and self:IsOperatorSatisfied(chargesRemaining, self.TriggerDetails.Charges.Operator, self.TriggerDetails.Charges.Value)) then
			self.isSet = false
			if cdRemaining == 0 then
				self.Time = 0
			end
		else
			self.isSet = true
		end
	end
end

local function HasProperties(table)
    for key, val in pairs(table) do
        if val ~= nil then
            return true
        end
    end
    return false
end

local function First(table)
    for k, v in pairs(table) do
        if v ~= nil then
            return v
        end
    end
end

function IconTrigger:RemoveBuffFromTarget(unit, buff)
    local unitId = unit:GetId()
    if buff ~= nil then
        self.Units[unitId].Buffs[buff.idBuff] = nil

        if not HasProperties(self.Units[unitId].Buffs) then
            self.Units[unitId] = nil
        end
    else
        self.Units[unitId] = nil
    end
end

function IconTrigger:ProcessBuff(data)
    local action = data.action
    local buff = data.data
    local unitId = data.unit:GetId()

    if action == "Remove" then
        if data.unit == nil then
            self.Units = {}
        elseif self.Units[unitId] ~= nil then
            self:RemoveBuffFromTarget(data.unit, buff)
        end
    end

    if action == "Add" then
        if not self.TriggerDetails.Stacks.Enabled or self:IsOperatorSatisfied(buff.nCount, self.TriggerDetails.Stacks.Operator, self.TriggerDetails.Stacks.Value) then
            if self.Units[unitId] == nil then
                self.Units[unitId] = { Unit = data.unit, LastUpdate = 0, Buffs = {} }
            end
            buff.LastUpdate = os.clock()
            self.Units[unitId].Buffs[buff.idBuff] = buff

        else
            self.Units[unitId] = nil
        end
    end

    self.isSet = HasProperties(self.Units)

    local firstTarget = First(self.Units)
    if firstTarget ~= nil then
        local firstBuff = First(firstTarget.Buffs)
        if firstBuff ~= nil then
        	self.Time = firstBuff.fTimeRemaining - (os.clock() - firstBuff.LastUpdate)
            self.Stacks = firstBuff.nCount
        	if self.MaxDuration == nil or self.MaxDuration < self.Time then
        		self.MaxDuration = self.Time
        	end
        	self.Sprite = buff.splEffect:GetIcon()

            if self.Time < 0 then
                self.Units = {}
                self.isSet = false
            end
        end
    end
end

function IconTrigger:ProcessEvent(result)
	if self.Type == "Action Set" then
		self.isSet = self.TriggerDetails.ActionSets[result]
	elseif self.Type == "Resources" then
		return self:ProcessResources(result)
	elseif self.Type == "Gadget" then
		self:ProcessSpell(result)
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

	self.Resources = result
end

function IconTrigger:ProcessHealth(result)
    local isSet = (result.Action == "Update")
    if result.Action == "Update" then
        if self.TriggerDetails["Health"] ~= nil then
    		isSet = isSet and self:ProcessResource(self.TriggerDetails.Health, result.Health, result.MaxHealth)
    	end

    	if self.TriggerDetails["Shield"] ~= nil then
    		isSet = isSet and self:ProcessResource(self.TriggerDetails.Shield, result.Shield, result.MaxShield)
    	end
    end

    if isSet then
        self.Units[result.Id] = { Unit = result.Unit, LastUpdate = 0, Buffs = {} }
    else
        self.Units[result.Id] = nil
    end
	self.isSet = HasProperties(self.Units)
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

function IconTrigger:ProcessKeybind(iKey)
	if (self.TriggerDetails.Input.Shift and not Apollo.IsShiftKeyDown()) or
		(self.TriggerDetails.Input.Control and not Apollo.IsControlKeyDown()) or
		(self.TriggerDetails.Input.Alt and not Apollo.IsAltKeyDown()) then
		return
	end
	self.lastKeypress = Apollo.GetTickCount()
end

function IconTrigger:ProcessLASChange(result)
	self.isSet = result
end

function IconTrigger:IsOperatorSatisfied(value, operator, compValue)
	if operator == "==" then
		return value == compValue
	elseif operator == "!=" then
		return value ~= compValue
	elseif operator == ">" then
		return value > compValue
	elseif operator == "<" then
		return value < compValue
	elseif operator == ">=" then
		return value >= compValue
	elseif operator == "<=" then
		return value <= compValue
	end
end

function IconTrigger:GetTargets()
    if self.isSet then
        return self.Units
        -- if self.Type == "Buff" or self.Type == "Debuff" then
        --     if self.TriggerDetails.Target.Player then
        --         return GameLib:GetPlayerUnit()
        --     elseif self.TriggerDetails.Target.Target then
        --         return GameLib:GetTargetUnit()
        --     end
        -- else
        --     return GameLib:GetPlayerUnit()
        -- end
    end
    return nil
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)
