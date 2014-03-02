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
end

function IconTrigger:ResetTrigger()
	self.isSet = false
end

function IconTrigger:IsSet()
	return isSet
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconTrigger, "AuraMastery:IconTrigger", 1)