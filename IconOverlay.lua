require "Window"

local IconOverlay  = {} 
IconOverlay .__index = IconOverlay

setmetatable(IconOverlay, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function IconOverlay.new(icon)
	local self = setmetatable({}, IconOverlay)
	self.icon = icon
	self.overlayColor = CColor.new(1, 0, 0, 0.75)
	self.overlayStyle = "Radial"
	self.overlayShape = "Solid"
	self.overlayElement = self.icon.icon:FindChild("IconOverlay")
	self.overlayElement:SetBarColor(self.overlayColor)
	self.overlayElement:SetBGColor(self.overlayColor)
	self.overlayElement:SetMax(100)
	return self
end

function IconOverlay:Load(saveData)
	if saveData ~= nil then
		self.overlayShape = saveData.overlayShape or "Solid"
		
		if saveData.overlayColor ~= nil then
			self.overlayColor = CColor.new(saveData.overlayColor[1], saveData.overlayColor[2], saveData.overlayColor[3], saveData.overlayColor[4])
		end
		
		self.overlayStyle = saveData.overlayStyle or "Linear"
		
		self:UpdateOverlaySprite()
	end
end

function IconOverlay:Save()
	local saveData = { }
	saveData.overlayShape = self.overlayShape
	saveData.overlayColor = { self.overlayColor.r, self.overlayColor.g, self.overlayColor.b, self.overlayColor.a }
	saveData.overlayStyle = self.overlayStyle
	return saveData
end

function IconOverlay:UpdateOverlaySprite()
	if self.overlayShape == "Icon" then
		self.overlayElement:SetFullSprite(self.icon:GetSprite())
	else
		self.overlayElement:SetFullSprite("ActionSetBuilder_TEMP:spr_TEMP_ActionSetBottomTierBG")
	end
	
	self.overlayElement:SetStyleEx("RadialBar", self.overlayStyle == "Radial")
	
	self.overlayElement:SetBarColor(self.overlayColor)
	self.overlayElement:SetBGColor(self.overlayColor)
end

function IconOverlay:SetConfig(configWnd)
	if self.icon.SimpleMode then
		self.overlayShape = self.icon.iconSprite == "" and "Solid" or "Icon"
		self.overlayStyle = "Linear"
	else
		self.overlayShape = (configWnd:FindChild("IconOverlay"):GetSprite() == "kitBase_HoloOrange_TinyNoGlow") and "Icon" or "Solid"
		self.overlayColor = configWnd:FindChild("OverlayColor"):FindChild("OverlayColorSample"):GetBGColor()	
		self.overlayStyle = (configWnd:FindChild("RadialOverlay"):GetSprite() == "kitBase_HoloOrange_TinyNoGlow" and "Radial" or "Linear")
	end
	
	self:UpdateOverlaySprite()
end

function IconOverlay:Update()
	if self.icon.duration > 0 then
		self.overlayElement:SetProgress(((self.icon.duration / self.icon.maxDuration)) * 100)
	elseif not self.icon.criticalRequirementPassed then
		self.overlayElement:SetProgress(self.overlayStyle == "Linear" and 100 or 99.999)
	else
		self.overlayElement:SetProgress(0)
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconOverlay, "AuraMastery:IconOverlay", 1)