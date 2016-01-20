require "Window"

local IconGroup  = {}
IconGroup .__index = IconGroup

setmetatable(IconGroup, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function IconGroup.new()
	local self = setmetatable({}, IconGroup)
    self.id = '00000000-0000-0000-0000-000000000000'
    self.name = ""
	return self
end

function IconGroup:Load(saveData)
	if saveData ~= nil then
        self.id = saveData.id
        self.name = saveData.name or ""
	end
end

function IconGroup:Save()
	return {
        id = self.id,
        name = self.name
    }
end

function IconGroup:SetConfig(configWnd)
	self.name = configWnd:FindChild("Name")
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconGroup, "AuraMastery:IconGroup", 1)
