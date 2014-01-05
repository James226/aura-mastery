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
	return self
end

function IconOverlay:Update()
	local overlayElement = self.icon.icon:FindChild("IconOverlay")
	overlayElement:SetAnchorPoints(0, 1 - (self.icon.duration / self.icon.maxDuration), 1, 1)
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconOverlay, "AuraMastery:IconOverlay", 1)