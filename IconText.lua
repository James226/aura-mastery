require "Window"

local IconText  = {}
IconText.__index = IconText

setmetatable(IconText, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function IconText.new(icon)
	local self = setmetatable({}, IconText)

	self.icon = icon
	self.textElement = Apollo.LoadForm("AuraMastery.xml", "AM_IconText", icon.icon, self)
	self.textAnchor = "OB"
	self.textFont = "CRB_FloaterSmall"
	self.textSize = { height = 40, width = 300 }
	self:SetFont(self.textFont)
	self:UpdateTextPosition()
	self.textFontColor = CColor.new(1, 1, 1, 1)
	self.textElement:SetTextColor(self.textFontColor)
	self.textString = "{time}"

	return self
end

function IconText:SetFont(fontName)
	self.textFont = fontName
	self.textElement:SetFont(fontName)

	for _, font in pairs(Apollo.GetGameFonts()) do
		if font.name == fontName then
			self.textSize.height = font.size * 1.5
			break
		end
	end
end

function IconText:Load(data)
	self.textAnchor = data.textAnchor or "OB"
	self.textFont = data.textFont or "Default"
	self:SetFont(self.textFont)
	self:UpdateTextPosition()
	if data.textFontColor ~= nil then
		self.textFontColor = CColor.new(data.textFontColor[1], data.textFontColor[2], data.textFontColor[3], data.textFontColor[4])
		self.textElement:SetTextColor(self.textFontColor)
	end
	self.textString = data.textString or "{time}"
end

function IconText:Save()
	local saveData = { }
	saveData.textAnchor = self.textAnchor
	saveData.textFont = self.textFont
	saveData.textFontColor = { self.textFontColor.r, self.textFontColor.g, self.textFontColor.b, self.textFontColor.a }
	saveData.textString = self.textString
	return saveData
end

function IconText:Update()
	self.textElement:SetText(string.gsub(self.textString, "{(.-)}", function(t) return self:GetTagText(t) end))
end

local function First(table)
    for _, val in pairs(table) do
        return val
    end
    return nil
end

function IconText:GetTagText(tag)
	if tag == "time" then
		return self:GetTimeText()
	elseif tag == 'charges' then
		return self.icon.MaxCharges > 0 and self.icon.Charges > 0 and tostring(self.icon.Charges) or ""
	elseif tag == 'stacks' then
		return self.icon.Stacks > 1 and tostring(self.icon.Stacks) or ""
    elseif tag == 'unit' then
        local target = First(self.icon:GetTargets() or {})
        if target ~= nil then
            return target:GetName()
        end
        return ""
	elseif tag:sub(1, 9) == 'resource.' then
		if self.icon.Resources ~= nil then
			local resourceType = tag:sub(10)
			if resourceType == 'primary' then
				return tostring(self.icon.Resources.Resource)
			elseif resourceType == 'focus' then
				return tostring(self.icon.Resources.Mana)
			end
		else
			return 'Add Resource Trigger'
		end
	else
		Print(tag:sub(1, 9))
	end
	return '{' .. tag .. '}'
end

function IconText:GetTimeText()
	local duration = self.icon.duration
	if duration == 0 then
		return ""
	else
		if duration > 60 then
			return string.format("%i:%02d", math.floor(duration / 60), math.floor(duration % 60))
		else
			return string.format("%.2fs", duration)
		end
	end
end

function IconText:SetConfig(configForm)
	local anchorSelector = configForm:FindChild("AnchorSelector")
	local selectedAnchorButton

	local fontElement = configForm:FindChild("SelectedFont")
	if fontElement ~= nil then
		self.textFont = fontElement:GetText()
		self:SetFont(self.textFont)
	end

	for _, anchorButton in pairs(anchorSelector:GetChildren()) do
		if anchorButton:IsChecked() then
			selectedAnchorButton = anchorButton
			break
		end
	end
	if selectedAnchorButton then
		self.textAnchor = string.sub(selectedAnchorButton:GetName(), 16)
		self:UpdateTextPosition()
	end

	self.textFontColor = configForm:FindChild("FontColorSample"):GetBGColor()
	self.textElement:SetTextColor(self.textFontColor)
	self.textString = configForm:FindChild("TextString"):GetText()
end

function IconText:UpdateTextPosition()
	self.anchor = { x = 0.5, y = 0.5 }
	if not self.textAnchor:match("C") then
		self.anchor.y = self.textAnchor:match("T") and 0 or self.textAnchor:match("B") and 1 or 0.5
		self.anchor.x = self.textAnchor:match("L") and 0 or self.textAnchor:match("R") and 1 or 0.5
	end
	self.offset = self:CalculateTextOffsets(self.anchor, self.textAnchor:match("I") ~= nil)

	self.textElement:SetAnchorPoints(self.anchor.x, self.anchor.y, self.anchor.x, self.anchor.y)
	self.textElement:SetAnchorOffsets(self.offset.left * self.textSize.width, self.offset.top * self.textSize.height, self.offset.right * self.textSize.width, self.offset.bottom * self.textSize.height)
	self.textElement:SetTextFlags("DT_CENTER", self.offset.left == -0.5)
	self.textElement:SetTextFlags("DT_RIGHT", self.offset.right == 0)
end

function IconText:CalculateTextOffsets(anchor, inside)
	local offsets = { }

	offsets.left = inside and -1 * anchor.x or anchor.x - 1
	offsets.right = inside and -1 * (anchor.x - 1) or anchor.x
	offsets.top = inside and -1 * anchor.y or anchor.y - 1
	offsets.bottom = inside and -1 * (anchor.y - 1) or anchor.y

	return offsets
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(IconText, "AuraMastery:IconText", 1)
