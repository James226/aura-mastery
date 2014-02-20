require "Window"

local AuraMasteryConfig  = {} 
AuraMasteryConfig .__index = AuraMasteryConfig

setmetatable(AuraMasteryConfig, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function AuraMasteryConfig.new(auraMastery, xmlDoc)
	local self = setmetatable({}, AuraMasteryConfig)
	self.auraMastery = auraMastery
	self.configForm = Apollo.LoadForm(xmlDoc, "AuraMasteryForm", nil, self)
	self:Init()
	return self
end

function AuraMasteryConfig:Init()
	for _, tab in pairs(self.configForm:FindChild("BuffEditor"):GetChildren()) do
		tab:Show(false)
	end
	self.configForm:FindChild("GeneralTabButton"):SetCheck(true)
	self.configForm:FindChild("BuffEditor"):FindChild("GeneralTab"):Show(true)
	
	self.configForm:FindChild("BuffType"):AddItem("Buff", "", 1)
	self.configForm:FindChild("BuffType"):AddItem("Debuff", "", 2)
	self.configForm:FindChild("BuffType"):AddItem("Cooldown", "", 3)
	
	self.configForm:FindChild("BuffTarget"):AddItem("Player", "", 1)
	self.configForm:FindChild("BuffTarget"):AddItem("Target", "", 2)
	self.configForm:FindChild("BuffTarget"):AddItem("Both", "", 3)
	
		
	self.configForm:FindChild("BuffShown"):AddItem("Active", "", 1)
	self.configForm:FindChild("BuffShown"):AddItem("Inactive", "", 2)
	self.configForm:FindChild("BuffShown"):AddItem("Both", "", 3)
	
	local soundList = self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList")
	local nextItem = 0
	
	local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)
	soundItem:SetAnchorPoints(0, 0, 1, 0)
	soundItem:SetAnchorOffsets(0, nextItem, 0, nextItem + 40) 
	nextItem = nextItem + 40

	soundItem:FindChild("Id"):SetText(-1)
	soundItem:FindChild("Label"):SetText("None")

			
	for sound, soundNo in pairs(Sound) do
		if type(soundNo) == "number" then
			local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)
			soundItem:SetAnchorPoints(0, 0, 1, 0)
			soundItem:SetAnchorOffsets(0, nextItem, 0, nextItem + 40)
			nextItem = nextItem + 40

			soundItem:FindChild("Id"):SetText(soundNo)
			soundItem:FindChild("Label"):SetText(sound)
		end
	end
	soundList:SetAnchorOffsets(0, 0, -15, nextItem)
	
	local soundSelectHeight = self.configForm:FindChild("SoundSelect"):GetHeight()
	self.configForm:FindChild("SoundSelect"):SetVScrollInfo(nextItem - soundSelectHeight, soundSelectHeight, soundSelectHeight)
	
	self:LoadSpriteIcons()
	
	self.textEditor = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor", self.configForm:FindChild("TextTab"), self)
	self:LoadFontSelector()
	
	self.configForm:FindChild("SolidOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("SolidOverlay"):FindChild("ProgressBar"):SetProgress(75)
	
	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetProgress(75)
	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetFullSprite("icon_Crosshair")
	
	self.configForm:FindChild("LinearOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("LinearOverlay"):FindChild("ProgressBar"):SetProgress(75)
	
	self.configForm:FindChild("RadialOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("RadialOverlay"):FindChild("ProgressBar"):SetProgress(75)
	
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetMax(100)
	
	self:CreateControls()
	self:SelectFirstIcon()
end

function AuraMasteryConfig:GetAbilitiesList()
	if self.abilitiesList == nil then
		self.abilitiesList = AbilityBook.GetAbilitiesList()
	end
	return self.abilitiesList
end

function AuraMasteryConfig:GetSpellIconByName(spellName)
	local abilities = self:GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	return ""
end

function AuraMasteryConfig:OnOpenConfig()
	if self.auraMastery == nil then
		self.auraMastery = Apollo.GetAddon("AuraMastery")
	end

	if self.configForm == nil then
		Print("Not Loaded")
		
	end
	self.configForm:Show(true)

end

-----------------------------------------------------------------------------------------------
-- AuraMasteryForm Functions
-----------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnOK()	
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	
	icon:SetIcon(self.configForm)
	
	self:UpdateControls()
end

function AuraMasteryConfig:OnCancel()
	self.configForm:Show(false) -- hide the window
end



function AuraMasteryConfig:LoadSpriteIcons()
	local spriteList = self.configForm:FindChild("BuffEditor"):FindChild("AppearanceTab"):FindChild("SpriteItemList")
	
	local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
	spriteItem:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(self.configForm:FindChild("BuffName"):GetText()))
	spriteItem:FindChild("SpriteItemText"):SetText("Spell Icon")
	spriteItem:SetAnchorOffsets(0, 0, spriteItem:GetWidth(), spriteItem:GetHeight())
	
	local iconsPerRow = math.floor(spriteList:GetWidth() / 110)
	local currentPos = 1
	
	for spriteName, spriteIcon in pairs(self.auraMastery.spriteIcons) do
		local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
		spriteItem:FindChild("SpriteItemIcon"):SetSprite(spriteIcon)
		spriteItem:FindChild("SpriteItemText"):SetText(spriteName)
		local x = math.floor(currentPos % iconsPerRow) * 110
		local y = math.floor(currentPos / iconsPerRow) * 140
		spriteItem:SetAnchorOffsets(x, y, x + spriteItem:GetWidth(), y + spriteItem:GetHeight())
		currentPos = currentPos + 1
	end
end

function AuraMasteryConfig:CreateControls()
	for i, icon in pairs(self.auraMastery.Icons) do
		self:CreateIconItem(icon.iconId, icon)
	end
end

function AuraMasteryConfig:CreateIconItem(i, icon)
	local iconList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
	local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
	iconItem:SetAnchorOffsets(0, (i-1) * 40, 500, (i-1) * 40 + 40)
	iconItem:FindChild("Id"):SetText(i)
	iconItem:FindChild("Label"):SetText(icon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	icon:SetConfigElement(iconItem)
	return iconItem
end

function AuraMasteryConfig:UpdateControls()
	for _, iconItem in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		local icon = self.auraMastery.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
		iconItem:FindChild("Label"):SetText(icon:GetName())
	end
end

function AuraMasteryConfig:SelectFirstIcon()
	for _, icon in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		if icon ~= nil then
			self:SelectIcon(icon)
			break
		end
	end
end

function AuraMasteryConfig:OnLockIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
	if self.auraMastery.Icons[iconId] ~= nil then
		self.auraMastery.Icons[iconId]:Lock()
	end
end

function AuraMasteryConfig:OnUnlockIcon( wndHandler, wndControl, eMouseButton )
	self.BarLocked = false
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
	if self.auraMastery.Icons[iconId] ~= nil then
		self.auraMastery.Icons[iconId]:Unlock()
	end
end

function AuraMasteryConfig:OnSoundPlay( wndHandler, wndControl, eMouseButton )
	local soundNo = tonumber(self.configForm:FindChild("SoundNo"):GetText())
	Sound.Play(soundNo)
end

function AuraMasteryConfig:OnAddIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local icon = self.auraMastery:AddIcon()
		self:CreateIconItem(icon.iconId, icon)
	end
end

function AuraMasteryConfig:OnRemoveIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		self:RemoveIcon(self.selectedIcon)
	end
end

function AuraMasteryConfig:AddIcon()
	local newIcon = Icon.new(self.buffWatch, self.configForm)
	newIcon:SetScale(1)
	
	local iconList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
	local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
	iconItem:SetAnchorOffsets(0, (self.nextIconId-1) * 40, 0, (self.nextIconId-1) * 40 + 40)
	iconItem:FindChild("Id"):SetText(tostring(self.nextIconId))
	iconItem:FindChild("Label"):SetText(newIcon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	newIcon:SetConfigElement(iconItem)
	self.auraMastery.Icons[self.nextIconId] = newIcon
	self.nextIconId = self.nextIconId + 1
	
	local windowHeight = iconList:GetHeight()
	iconList:SetVScrollInfo(self:NumIcons() * 40 - windowHeight, windowHeight, windowHeight)
	
	return newIcon
end

function AuraMasteryConfig:RemoveIcon(icon)
	local iconId = tonumber(icon:FindChild("Id"):GetText())
	icon:Destroy()
	
	self.auraMastery.Icons[iconId]:Delete()
	self.auraMastery.Icons[iconId] = nil
	self:SelectFirstIcon()
	
	local currentPos = 0
	for _, iconItem in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		iconItem:SetAnchorOffsets(0, currentPos, 0, currentPos + iconItem:GetHeight())
		currentPos = currentPos + iconItem:GetHeight()
	end
	

	local windowHeight = self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetHeight()
	self.configForm:FindChild("IconListHolder"):FindChild("IconList"):SetVScrollInfo(self:NumIcons() * 40 - windowHeight, windowHeight, windowHeight)
end

function AuraMasteryConfig:NumIcons()
	local numIcons = 0
	for _, icon in pairs(self.auraMastery.Icons) do
		if icon ~= nil then
			numIcons = numIcons + 1
		end
	end
	return numIcons
end

function AuraMasteryConfig:OnIconScale( wndHandler, wndControl, fNewValue, fOldValue )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	
	icon:SetScale(fNewValue)
end

function AuraMasteryConfig:OnTabSelected( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("BuffEditor"):FindChild(wndHandler:GetText() .. "Tab"):Show(true)
	
	if wndHandler:GetText() == "Appearance" then
		Apollo.RegisterTimerHandler("AuraMastery_IconPreview", "OnIconPreview", self)
		Apollo.CreateTimer("AuraMastery_IconPreview", 0.1, true)
	end
end

function AuraMasteryConfig:OnTabUnselected( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("BuffEditor"):FindChild(wndHandler:GetText() .. "Tab"):Show(false)
	
	if wndHandler:GetText() == "Appearance" then
		Apollo.StopTimer("AuraMastery_IconPreview")
	end
end

function AuraMasteryConfig:OnIconPreview()
	self.currentSampleNum = (self.currentSampleNum + 2) % 100
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetProgress(self.currentSampleNum)
end

function AuraMasteryConfig:OnColorUpdate()
	self.configForm:FindChild("BuffColorSample"):SetBGColor(self.selectedColor)
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetBGColor(self.selectedColor)
	for _, icon in pairs(self.configForm:FindChild("SpriteItemList"):GetChildren()) do
		icon:FindChild("SpriteItemIcon"):SetBGColor(self.selectedColor)
	end
end

function AuraMasteryConfig:OnColorSelect( wndHandler, wndControl, eMouseButton )
	if ColorPicker ~= nil then
		ColorPicker.AdjustCColor(self.selectedColor, true, function() self:OnColorUpdate() end)
	end
end

function AuraMasteryConfig:OnSpellNameChanged( wndHandler, wndControl, strText )
	self.configForm:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(strText))
end

function AuraMasteryConfig:OnOverlaySelection( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		local overlaySelection = wndHandler:FindChild("OverlayIconText"):GetText()
		
		if overlaySelection == "Solid" then
			self.configForm:FindChild("SolidOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("IconOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			
		elseif overlaySelection == "Icon" then
			self.configForm:FindChild("SolidOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("IconOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
		end
		
		if overlaySelection == "Linear" then
			self.configForm:FindChild("LinearOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("RadialOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", false)
		elseif overlaySelection == "Radial" then
			self.configForm:FindChild("LinearOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("RadialOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", true)
		end
	end    
end

function AuraMasteryConfig:OnOverlayColorUpdate()
	self.configForm:FindChild("OverlayColorSample"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBarColor(self.selectedOverlayColor)
end

function AuraMasteryConfig:OnOverlayColorSelect( wndHandler, wndControl, eMouseButton )
	if ColorPicker ~= nil then
		ColorPicker.AdjustCColor(self.selectedOverlayColor, true, function() self:OnOverlayColorUpdate() end)
	end
end

--------------------------------------------------------------------------------------------
-- IconListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnListItemSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self:SelectIcon(wndHandler)
	end
end

function AuraMasteryConfig:SelectIcon(iconItem)
	local icon = self.auraMastery.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
	if icon ~= nil then
		self.configForm:FindChild("BuffId"):SetText(tonumber(iconItem:FindChild("Id"):GetText()))
		self.configForm:FindChild("BuffName"):SetText(icon.iconName)
		self.configForm:FindChild("BuffType"):SetText(icon.iconType)
		self.configForm:FindChild("BuffTarget"):SetText(icon.iconTarget)
		self.configForm:FindChild("BuffShown"):SetText(icon.iconShown)
		self.configForm:FindChild("SelectedSound"):SetText(icon.iconSound)
		self.configForm:FindChild("BuffScale"):SetValue(icon.iconScale)
		self.configForm:FindChild("BuffBackgroundShown"):SetCheck(icon.iconBackground)
		self.configForm:FindChild("BuffBorderShown"):SetCheck(icon.iconBorder)
		self.configForm:FindChild("BuffCriticalRequired"):SetCheck(icon.criticalRequired)
		self.configForm:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(icon.iconName))
		self.selectedColor = icon.iconColor
		self.selectedOverlayColor = icon.iconOverlay.overlayColor
		self.selectedFontColor = icon.iconText.textFontColor
		self:OnColorUpdate()
		
		for _, spriteIcon in pairs(self.configForm:FindChild("SpriteItemList"):GetChildren()) do
			if (icon.iconSprite == "" and spriteIcon:FindChild("SpriteItemText"):GetText() == "Spell Icon") or spriteIcon:FindChild("SpriteItemIcon"):GetSprite() == icon.iconSprite then
				self:SelectSpriteIcon(spriteIcon)
				break
			end
		end
		
		if self.selectedIcon ~= nil then
			self.selectedIcon:SetBGColor(ApolloColor.new(1, 1, 1, 1))
		end
		self.selectedIcon = iconItem
		self.selectedIcon:SetBGColor(ApolloColor.new(1, 0, 1, 1))
		
		if self.selectedSound ~= nil then
			self.selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
		end
		
		for _, sound in pairs(self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetChildren()) do
			if tonumber(sound:FindChild("Id"):GetText()) == icon.iconSound then
				self.selectedSound = sound
				self.selectedSound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
				
				local left, top, right, bottom = sound:GetAnchorOffsets()
				self.configForm:FindChild("SoundSelect"):SetVScrollPos(top)
				break
			end
		end
		for _, anchor in pairs(self.configForm:FindChild("TextTab"):FindChild("AnchorSelector"):GetChildren()) do
			anchor:SetCheck(false)
		end
		
		local selectedTextAnchor = self.configForm:FindChild("TextTab"):FindChild("AnchorPosition_" .. icon.iconText.textAnchor)
		if selectedTextAnchor ~= nil then
			selectedTextAnchor:SetCheck(true)
		end
		
		for _, font in pairs(self.configForm:FindChild("TextTab"):FindChild("FontSelector"):GetChildren()) do
			if font:GetText() == icon.iconText.textFont then
				self:SelectFont(font)
				local left, top, right, bottom = font:GetAnchorOffsets()
				self.configForm:FindChild("TextTab"):FindChild("FontSelector"):SetVScrollPos(top)
				break
			end
		end
		self.configForm:FindChild("TextTab"):FindChild("FontColorSample"):SetBGColor(icon.iconText.textFontColor)
		self.configForm:FindChild("TextTab"):FindChild("FontSample"):SetTextColor(icon.iconText.textFontColor)
		self.configForm:FindChild("TextTab"):FindChild("TextString"):SetText(icon.iconText.textString)
		
		self.configForm:FindChild("OverlayColorSample"):SetBGColor(icon.iconOverlay.overlayColor)
		if icon.iconOverlay.overlayShape == "Icon" then
			self.configForm:FindChild("IconOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
			self.configForm:FindChild("SolidOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
		else
			self.configForm:FindChild("SolidOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
			self.configForm:FindChild("IconOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
		end
		
		if icon.iconOverlay.overlayStyle == "Radial" then
			self.configForm:FindChild("RadialOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
			self.configForm:FindChild("LinearOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
		else
			self.configForm:FindChild("LinearOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
			self.configForm:FindChild("RadialOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
		end
	end
end

function AuraMasteryConfig:SelectFont(fontElement)
	if self.selectedFont ~= nil then
		self.selectedFont:SetBGColor(CColor.new(1,1,1,1))
	end
	self.configForm:FindChild("FontSample"):SetFont(fontElement:GetText())
	self.configForm:FindChild("SelectedFont"):SetText(fontElement:GetText())
	self.selectedFont = fontElement
	self.selectedFont:SetBGColor(CColor.new(1,0,1,1))
end

---------------------------------------------------------------------------------------------------
-- SoundListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnSoundItemSelected( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.selectedSound ~= nil then
			self.selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
		end
		self.selectedSound = wndHandler
		self.selectedSound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
		local soundId = tonumber(wndHandler:FindChild("Id"):GetText())
		self.configForm:FindChild("SoundSelect"):FindChild("SelectedSound"):SetText(soundId)
		Sound.Play(soundId)
	end
end

---------------------------------------------------------------------------------------------------
-- SpriteItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnSpriteIconSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectSpriteIcon(wndHandler)
	end
end

function AuraMasteryConfig:SelectSpriteIcon(spriteIcon)
	if self.selectedSprite ~= nil then
		self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
	end
	self.selectedSprite = spriteIcon
	if self.selectedSprite:FindChild("SpriteItemText"):GetText() == "Spell Icon" then
		self.configForm:FindChild("SelectedSprite"):SetText("")
	else
		self.configForm:FindChild("SelectedSprite"):SetText(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
	end
	self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
	self.selectedSprite:SetText("")
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
end

function AuraMasteryConfig:LoadFontSelector()
	local fontSelector = self.configForm:FindChild("FontSelector")
	local currentIdx = 0
	for _, font in pairs(Apollo.GetGameFonts()) do
		local fontItem = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor_Font", fontSelector, self)
		fontItem:SetAnchorOffsets(0, currentIdx * fontItem:GetHeight(), 0, currentIdx * fontItem:GetHeight() + fontItem:GetHeight())
		fontItem:SetText(font.name)
		currentIdx = currentIdx + 1
	end	
end

---------------------------------------------------------------------------------------------------
-- AM_Config_TextEditor_Font Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnFontSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectFont(wndHandler)
	end
end

function AuraMasteryConfig:SelectFont(fontElement)
	if self.selectedFont ~= nil then
		self.selectedFont:SetBGColor(CColor.new(1,1,1,1))
	end
	self.configForm:FindChild("FontSample"):SetFont(fontElement:GetText())
	self.configForm:FindChild("SelectedFont"):SetText(fontElement:GetText())
	self.selectedFont = fontElement
	self.selectedFont:SetBGColor(CColor.new(1,0,1,1))
end

function AuraMasteryConfig:OnFontColorSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl and ColorPicker ~= nil then
		ColorPicker.AdjustCColor(self.selectedFontColor, true, function() self:OnFontColorUpdate() end)
	end
end

function AuraMasteryConfig:OnFontColorUpdate()
	self.configForm:FindChild("FontColorSample"):SetBGColor(self.selectedFontColor)
	self.configForm:FindChild("FontSample"):SetTextColor(self.selectedFontColor)
end


local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(AuraMasteryConfig, "AuraMastery:Config", 1)