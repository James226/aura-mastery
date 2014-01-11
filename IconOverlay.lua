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
	self.overlayColor = CColor.new(1, 0, 0, 1)
	self.overlayElement = self.icon.icon:FindChild("IconOverlay")
	self.overlayElement:SetBarColor(self.overlayColor)
	self.overlayElement:SetMax(100)
	return self
end

function IconOverlay:Load(saveData)

end

function IconOverlay:Save(saveData)

end

function IconOverlay:UpdateOverlaySprite()
	if self.overlayStyle == "Icon" then
		self.overlayElement:SetFullSprite(self.icon.icon:GetSprite())
	else
		self.overlayElement:SetFullSprite("ActionSetBuilder_TEMP:spr_TEMP_ActionSetBottomTierBG")
	end
end

function IconOverlay:SetConfig(configWnd)
	self.overlayStyle = (configWnd:FindChild("IconOverlay"):GetSprite() == "kitBase_HoloOrange_TinyNoGlow") and "Icon" or "Solid"
		
	self:UpdateOverlaySprite()
	
	self.radialOverlay = (configWnd:FindChild("RadialOverlay"):GetSprite() == "kitBase_HoloOrange_TinyNoGlow")
	self.overlayElement:SetStyleEx("RadialBar", self.radialOverlay)
	
	
	self.overlayElement:SetBarColor(configWnd:FindChild("OverlayColor"):FindChild("OverlayColorSample"):GetBGColor())
	self.overlayElement:SetBGColor(configWnd:FindChild("OverlayColor"):FindChild("OverlayColorSample"):GetBGColor())
end

function IconOverlay:Update()
	if self.icon.duration > 0 then
		self.overlayElement:SetProgress(((self.icon.duration / self.icon.maxDuration)) * 100)
	else
		self.overlayElement:SetProgress(0)
	end
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconOverlay, "AuraMastery:IconOverlay", 1)