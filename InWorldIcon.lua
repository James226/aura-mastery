require "Window"

local InWorldIcon  = {}

setmetatable(InWorldIcon, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function InWorldIcon.new(parent, xmlDoc)
	local self = setmetatable({}, { __index = InWorldIcon })

    self.Enabled = false
    self.parent = parent
    self.xmlDoc = xmlDoc
	self.Icons = {}

	return self
end

function InWorldIcon:Load(saveData)
	if saveData ~= nil then
        self.Enabled = saveData.Enabled

	end
end

function InWorldIcon:Save()
	local saveData = { }
    saveData.Enabled = self.Enabled
	return saveData
end

function InWorldIcon:SetConfig(configWnd)
    self.Enabled = configWnd:FindChild("InWorldIconEnabled"):IsChecked()
    if not self.Enabled then
        for _, icon in pairs(self.Icons) do
            icon:Destroy()
        end
        self.Icons = {}
    end

end

function InWorldIcon:Update()
    if not self.Enabled then return end

	self:UpdateTarget()
end

function InWorldIcon:UpdateTarget()
    local targets = self.parent:GetTargets() or {}
    local i = 1
    for _, target in pairs(targets) do
        if self.Icons[i] == nil then
            SendVarToRover("Doc", self.xmlDoc)
            self.Icons[i] = Apollo.LoadForm(self.xmlDoc, "InWorldIcon", "InWorldHudStratum", self)
            self.Icons[i]:FindChild("IconOverlay"):SetMax(100)
        end
        self.Icons[i]:Show(true, true)
        self.Icons[i]:FindChild("Background"):SetSprite(self.parent:GetSprite())
	    self.Icons[i]:SetUnit(target.Unit, 0)
        self.Icons[i]:FindChild("IconOverlay"):SetProgress(((self.parent.duration / self.parent.maxDuration)) * 100)
        self.Icons[i]:FindChild("Timer"):SetText(string.format("%.2fs", self.parent.duration))
        -- 0 = Underfoot
        -- 1 = Above Head
        -- 2 = Left Arm
        -- 3 = Right Arm
        -- 4 = Back
        i = i + 1
    end
    local numOfLines = #self.Icons
    for i = i, numOfLines, 1 do
        self.Icons[i]:Show(false, true)
        self.Icons[i]:SetUnit(nil)
    end
end

function InWorldIcon:SetBGColor(color)
	self.bgColor = color
    self.intermediateColor = color
    self.complementaryColor = color
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(InWorldIcon, "AuraMastery:InWorldIcon", 1)
