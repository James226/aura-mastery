require "Window"

local TriggerEffect  = {} 
TriggerEffect .__index = TriggerEffect

setmetatable(TriggerEffect, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TriggerEffect.new(trigger, effectType)
	local self = setmetatable({}, TriggerEffect)
	self.Trigger = trigger
	self.Type = effectType or "Icon Color"
	self.When = "Pass"
	self.triggerStarted = true
	self.triggerTime = 0
	self.isTimed = false
	self.timerLength = 0

	self:SetDefaultConfig()

	self:Init()
	return self
end

function TriggerEffect:SetDefaultConfig()
	if self.Type == "Icon Color" then
		self.EffectDetails = {
		Color = { r = 1, g = 0, b = 0, a = 1 }
		}
	elseif self.Type == "Activation Border" then
		self.EffectDetails = {
			BorderSprite = "sprActionBar_YellowBorder"
		}
	end
end

function TriggerEffect:Load(saveData)
	if saveData ~= nil then
		self.Type = saveData.Type
		self.EffectDetails = saveData.EffectDetails
		self.When = saveData.When
		
		if saveData.isTimed ~= nil then
			self.isTimed = saveData.isTimed
		end
		if saveData.timerLength ~= nil then
			self.timerLength = saveData.timerLength
		end

		self:Init()
	end
end

function TriggerEffect:Init()
	if self.Type == "Activation Border" then
		self.activationBorder = Apollo.LoadForm("AuraMastery.xml", "IconEffectModifiers.ActivationBorder", self.Trigger.Icon.icon, self)
		self.activationBorder:SetSprite(self.EffectDetails.BorderSprite)
		self.activationBorder:Show(false)
	end
end

function TriggerEffect:Save()
	local saveData = { }
	saveData.Type = self.Type
	saveData.When = self.When
	saveData.isTimed = self.isTimed
	saveData.timerLength = self.timerLength
	saveData.EffectDetails = self.EffectDetails
	return saveData
end

function TriggerEffect:SetConfig(configWnd)
	if configWnd:FindChild("TriggerEffectOnFail"):IsChecked() then
		self.When = "Fail"
	else
		self.When = "Pass"
	end

	self.isTimed = configWnd:FindChild("TriggerEffectIsTimed"):IsChecked()
	self.timerLength = tonumber(configWnd:FindChild("TriggerEffectTimerLength"):GetText())

	if self.Type == "Icon Color" then
		self.EffectDetails = {
			Color = configWnd:FindChild("TriggerEffectEditor"):FindChild("IconColor"):FindChild("ColorSample"):GetBGColor():ToTable()
		}
	elseif self.Type == "Activation Border" then
		for _, border in pairs(configWnd:FindChild("BorderSelect"):GetChildren()) do
			if border:IsChecked() then
				self.EffectDetails = {
					BorderSprite = border:FindChild("Window"):GetSprite()
				}
				self.activationBorder:SetSprite(self.EffectDetails.BorderSprite)
				break
			end
		end
	end
end

function TriggerEffect:Update(triggerPassed)
	if (self.When == "Pass" and triggerPassed) or (self.When == "Fail" and not triggerPassed) then
		if self.isTimed then
			self:UpdateTimed()
		else
			self:UpdateEffect()
		end
	else
		self:StopEffect()
		if self.isTimed then
			self:EndTimed()
		end
	end
end

function TriggerEffect:UpdateTimed()
	if not self.triggerStarted then
		self.triggerStarted = true
		self.triggerTime = os.clock()
	end

	if os.clock() - self.triggerTime < self.timerLength then
		self:UpdateEffect()
	else
		self:StopEffect()
	end
end

function TriggerEffect:UpdateEffect()
	if self.Type == "Icon Color" then
			self:UpdateIconColor()
	elseif self.Type == "Flash" then
		self:UpdateFlash()
	elseif self.Type == "Activation Border" then
		self:UpdateActivationBorder()
	end
end

function TriggerEffect:StopEffect()
	if self.Type == "Activation Border" then
		self:StopActivationBorder()
	end
end

function TriggerEffect:UpdateIconColor()
	self.Trigger.Icon:SetIconColor(self.EffectDetails.Color)
end

function TriggerEffect:UpdateFlash()
	local iconColor = self.Trigger.Icon.icon:GetBGColor():ToTable()
	iconColor.a = math.abs(math.sin((os.clock() - self.triggerTime)*2))
	self.Trigger.Icon:SetIconColor(iconColor)
end

function TriggerEffect:UpdateActivationBorder()
	self.activationBorder:Show(true)
end

function TriggerEffect:StopActivationBorder()
	self.activationBorder:Show(false)
end

function TriggerEffect:EndTimed()
	self.triggerStarted = false
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(TriggerEffect, "AuraMastery:TriggerEffect", 1)