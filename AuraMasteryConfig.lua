require "Window"

local AuraMasteryConfig  = {} 
AuraMasteryConfig .__index = AuraMasteryConfig

local IconText = nil

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

function AuraMasteryConfig:Show()
	self.configForm:FindChild("ShareConfirmDialog"):Show(false)
	self.configForm:Show(true)
end

function AuraMasteryConfig:Init()
	for _, tab in pairs(self.configForm:FindChild("BuffEditor"):GetChildren()) do
		tab:Show(false)
	end
	self.shareChannel = ICCommLib.JoinChannel("AuraMastery", "OnShareMsg", nil)
	self.configForm:FindChild("GeneralTabButton"):SetCheck(true)
	self.configForm:FindChild("BuffEditor"):FindChild("GeneralTab"):Show(true)	
		
	self.configForm:FindChild("BuffShowWhen"):AddItem("Always", "", 1)
	self.configForm:FindChild("BuffShowWhen"):AddItem("All", "", 2)
	self.configForm:FindChild("BuffShowWhen"):AddItem("Any", "", 3)
	self.configForm:FindChild("BuffShowWhen"):AddItem("None", "", 4)

	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("All", "", 1)
	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("Any", "", 2)
	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("None", "", 3)
	
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
	self.iconTextEditor = {}	
	
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

	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)
	
	self:CreateControls()
	self:SelectFirstIcon()
	
	GeminiPackages:Require("AuraMastery:IconText", function(iconText)
		IconText = iconText
	end)
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
	iconItem:FindChild("Id"):SetText(i)
	iconItem:FindChild("Label"):SetText(icon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	icon:SetConfigElement(iconItem)
	iconList:ArrangeChildrenVert()
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
		local timeText = self:AddIconText(icon)
		timeText.textAnchor = "OB"
		timeText.textString = "{time}"
		local stacksText = self:AddIconText(icon)
		stacksText.textAnchor = "IBR"
		stacksText.textString = "{stacks}"
		local chargesText = self:AddIconText(icon)
		timeText.textAnchor = "ITL"
		timeText.textString = "{charges}"
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
	iconItem:FindChild("Id"):SetText(tostring(self.nextIconId))
	iconItem:FindChild("Label"):SetText(newIcon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	newIcon:SetConfigElement(iconItem)
	self.auraMastery.Icons[self.nextIconId] = newIcon
	self.nextIconId = self.nextIconId + 1

	iconList:ArrangeChildrenVert()
	
	return newIcon
end

function AuraMasteryConfig:RemoveIcon(icon)
	local iconId = tonumber(icon:FindChild("Id"):GetText())
	icon:Destroy()
	
	self.auraMastery.Icons[iconId]:Delete()
	self.auraMastery.Icons[iconId] = nil
	self:SelectFirstIcon()

	self.configForm:FindChild("IconListHolder"):FindChild("IconList"):ArrangeChildrenVert()
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
		self.configForm:FindChild("BuffShowWhen"):SetText(icon.showWhen)
		self.configForm:FindChild("BuffPlaySoundWhen"):SetText(icon.playSoundWhen)
		self.configForm:FindChild("SelectedSound"):SetText(icon.iconSound)
		self.configForm:FindChild("BuffScale"):SetValue(icon.iconScale)
		self.configForm:FindChild("BuffBackgroundShown"):SetCheck(icon.iconBackground)
		self.configForm:FindChild("BuffBorderShown"):SetCheck(icon.iconBorder)
		self.configForm:FindChild("BuffOnlyInCombat"):SetCheck(icon.onlyInCombat)
		self.configForm:FindChild("BuffEnabled"):SetCheck(icon.enabled)
		self.configForm:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(icon.iconName))
		self.selectedColor = icon.iconColor
		self.selectedOverlayColor = icon.iconOverlay.overlayColor
		
		self.configForm:FindChild("BuffActionSet1"):SetCheck(icon.actionSets[1])
		self.configForm:FindChild("BuffActionSet2"):SetCheck(icon.actionSets[2])
		self.configForm:FindChild("BuffActionSet3"):SetCheck(icon.actionSets[3])
		self.configForm:FindChild("BuffActionSet4"):SetCheck(icon.actionSets[4])

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
		
		
		for textEditorId, textEditor in pairs(self.iconTextEditor) do
			textEditor:Destroy()
			self.iconTextEditor[textEditorId] = nil
		end
		
		for iconTextId, iconText in pairs(icon.iconText) do
			self:AddIconTextEditor()
			
			local textEditor = self.configForm:FindChild("TextList"):GetChildren()[iconTextId]
			
			for _, anchor in pairs(textEditor:FindChild("AnchorSelector"):GetChildren()) do
				anchor:SetCheck(false)
			end
			local selectedTextAnchor = textEditor:FindChild("AnchorPosition_" .. icon.iconText[iconTextId].textAnchor)
			if selectedTextAnchor ~= nil then
				selectedTextAnchor:SetCheck(true)
			end
			
			for _, font in pairs(textEditor:FindChild("FontSelector"):GetChildren()) do
				if font:GetText() == icon.iconText[iconTextId].textFont then
					self:SelectFont(font)
					local left, top, right, bottom = font:GetAnchorOffsets()
					textEditor:FindChild("FontSelector"):SetVScrollPos(top)
					break
				end
			end
			textEditor:FindChild("FontColorSample"):SetBGColor(icon.iconText[iconTextId].textFontColor)
			textEditor:FindChild("FontSample"):SetTextColor(icon.iconText[iconTextId].textFontColor)
			textEditor:FindChild("TextString"):SetText(icon.iconText[iconTextId].textString)
		end
			
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

		self.configForm:FindChild("ShareForm"):Show(false)

		self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
		self:PopulateTriggers(icon)
	end
end

function AuraMasteryConfig:SelectFont(fontElement)
	local textEditor = fontElement:GetParent():GetParent()
	local editorData = textEditor:GetData()
	if editorData.selectedFont ~= nil then
		editorData.selectedFont:SetBGColor(CColor.new(1,1,1,1))
	end
	textEditor:FindChild("FontSample"):SetFont(fontElement:GetText())
	textEditor:FindChild("SelectedFont"):SetText(fontElement:GetText())
	editorData.selectedFont = fontElement
	editorData.selectedFont:SetBGColor(CColor.new(1,0,1,1))
	
	textEditor:SetData(editorData)
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

function AuraMasteryConfig:AddIconTextEditor()
	local nextIconTextId = # self.iconTextEditor + 1
	local textEditor = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor", self.configForm:FindChild("TextList"), self)
	textEditor:FindChild("IconTextId"):SetText(tostring(nextIconTextId))
	self.iconTextEditor[nextIconTextId] = textEditor
	local left, top, right, bottom = textEditor:GetAnchorOffsets()
	textEditor:SetAnchorOffsets(left, top + ((nextIconTextId - 1) * textEditor:GetHeight()), right, bottom + (nextIconTextId - 1) * textEditor:GetHeight())
	textEditor:SetData({selectedFont = nil})
	self:LoadFontSelector(nextIconTextId)
end

function AuraMasteryConfig:LoadFontSelector(textId)
	local fontSelector = self.iconTextEditor[textId]:FindChild("FontSelector")
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

function AuraMasteryConfig:OnIconTextAdd( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	self:AddIconText(icon)
	self:AddIconTextEditor()
end

function AuraMasteryConfig:AddIconText(icon)
	local iconText = IconText.new(icon)
	icon.iconText[#icon.iconText + 1] = iconText
	return iconText
end


function AuraMasteryConfig:OnFontSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectFont(wndHandler)
	end
end

function AuraMasteryConfig:OnFontColorSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		if ColorPicker ~= nil then
			local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
			local icon = self.auraMastery.Icons[iconId]
			local iconTextId = tonumber(wndHandler:GetParent():FindChild("IconTextId"):GetText())
			self.selectedFontColor = icon.iconText[iconTextId].textFontColor
			ColorPicker.AdjustCColor(self.selectedFontColor, true, function() self:OnFontColorUpdate(wndHandler:GetParent()) end)
		else
			Print("ColorPicker addon must be loaded to edit colors.")
		end
	end
end

function AuraMasteryConfig:OnFontColorUpdate(textEditor)
	textEditor:FindChild("FontColorSample"):SetBGColor(self.selectedFontColor)
	textEditor:FindChild("FontSample"):SetTextColor(self.selectedFontColor)
end

function AuraMasteryConfig:OnIconTextRemove( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		local iconTextId = tonumber(wndHandler:GetParent():FindChild("IconTextId"):GetText())
		table.remove(icon.iconText, iconTextId)
		
		self.iconTextEditor[iconTextId]:Destroy()
		table.remove(self.iconTextEditor, iconTextId)
	end
end

---------------------------------------------------------------------------------------------------
-- Trigger Tab Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:PopulateTriggers(icon)
	local triggerSelectDropdown = self.configForm:FindChild("TriggerSelectDropdown")

	triggerSelectDropdown:DestroyChildren()

	local firstTrigger = true
	for _, trigger in pairs(icon.Triggers) do
		local triggerItem = self:AddTriggerDropdown(triggerSelectDropdown, trigger)
		if firstTrigger then
			self:SelectTrigger(triggerItem)
			firstTrigger = false
		end
	end

	if firstTrigger then
		self.configForm:FindChild("TriggerSelectButton"):SetText("")
		self:SelectTrigger(nil)	
	end
end

function AuraMasteryConfig:AddTriggerDropdown(triggerSelectDropdown, trigger)
	local numChildren = # triggerSelectDropdown:GetChildren()
	local triggerDropdownItem = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.TriggersTab.TriggerSelectDropdown.TriggerItem", triggerSelectDropdown, self)
	triggerDropdownItem:SetAnchorOffsets(10, 10 + numChildren * 45, -10, 10 + numChildren * 45 + 45)
	triggerDropdownItem:FindChild("TriggerName"):SetText(trigger.Name)
	triggerDropdownItem:SetData(trigger)
	return triggerDropdownItem
end

function AuraMasteryConfig:OnCheckTriggerSelectButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEditor"):Enable(false)
	self.configForm:FindChild("TriggerSelectDropdown"):Show(true)
	self.configForm:FindChild("TriggerSelectDropdown"):BringToFront()
end

function AuraMasteryConfig:OnUncheckTriggerSelectButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerSelectDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerSelectButton"):SetCheck(false)
	self.configForm:FindChild("TriggerEditor"):Enable(true)
end

function AuraMasteryConfig:OnTriggerSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
		self:SelectTrigger(wndHandler)
	end
end

function AuraMasteryConfig:SelectTrigger(triggerDropdownItem)
	local editor = self.configForm:FindChild("TriggerEditor")

	if triggerDropdownItem == nil then
		editor:Show(false)
	else
		editor:Show(true)
		local trigger = triggerDropdownItem:GetData()
		editor:SetData(trigger)
		self.configForm:FindChild("TriggerSelectButton"):SetText(trigger.Name)
		editor:FindChild("TriggerName"):SetText(trigger.Name)
		editor:FindChild("TriggerType"):SetText(trigger.Type)
		editor:FindChild("TriggerBehaviour"):SetText(trigger.Behaviour)

		self:PopulateTriggerDetails(trigger.Type)

		if trigger.Type == "Action Set" then
			editor:FindChild("ActionSet1"):SetCheck(trigger.TriggerDetails.ActionSets[1])
			editor:FindChild("ActionSet2"):SetCheck(trigger.TriggerDetails.ActionSets[2])
			editor:FindChild("ActionSet3"):SetCheck(trigger.TriggerDetails.ActionSets[3])
			editor:FindChild("ActionSet4"):SetCheck(trigger.TriggerDetails.ActionSets[4])
		elseif trigger.Type == "Cooldown" then
			editor:FindChild("SpellName"):SetText(trigger.TriggerDetails.SpellName)
		elseif trigger.Type == "Buff" then
			editor:FindChild("BuffName"):SetText(trigger.TriggerDetails.BuffName)
			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
		elseif trigger.Type == "Debuff" then
			editor:FindChild("DebuffName"):SetText(trigger.TriggerDetails.DebuffName)
			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
		elseif trigger.Type == "Resources" then
			self:InitializeTriggerDetailsWindow(trigger.Type, self.configForm)

			self:PopulateValueBasedEditor(trigger, editor, "Mana")
			self:PopulateValueBasedEditor(trigger, editor, "Resource")
		elseif trigger.Type == "Health" then
			self:InitializeTriggerDetailsWindow(trigger.Type, self.configForm)

			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)

			self:PopulateValueBasedEditor(trigger, editor, "Health")
			self:PopulateValueBasedEditor(trigger, editor, "Shield")
		elseif trigger.Type == "Moment Of Opportunity" then
			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
		end

		self.configForm:FindChild("TriggerTypeDropdown"):Show(false)
	end
end

function AuraMasteryConfig:PopulateValueBasedEditor(trigger, editor, resourceType)
	local resourceEditor = editor:FindChild(resourceType)
	
	if trigger.TriggerDetails[resourceType] ~= nil then
		editor:FindChild(resourceType .. "Enabled"):SetCheck(true)
		self:ToggleResourceEditor(resourceEditor, true)
		resourceEditor:FindChild("Operator"):SetText(trigger.TriggerDetails[resourceType].Operator)
		resourceEditor:FindChild("Value"):SetText(trigger.TriggerDetails[resourceType].Value)
		resourceEditor:FindChild("Percent"):SetCheck(trigger.TriggerDetails[resourceType].Percent)
	else
		editor:FindChild(resourceType .. "Enabled"):SetCheck(false)
		self:ToggleResourceEditor(resourceEditor, false)
		resourceEditor:FindChild("Operator"):SetText(">")
		resourceEditor:FindChild("Value"):SetText("")
		resourceEditor:FindChild("Percent"):SetCheck(false)
	end
end

function AuraMasteryConfig:OnAddTrigger( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local triggerSelectDropdown = self.configForm:FindChild("TriggerSelectDropdown")

		GeminiPackages:Require('AuraMastery:IconTrigger', function(iconTrigger) 
			local trigger = iconTrigger.new(icon.buffWatch)
			trigger.Name = "Trigger " .. tostring(# triggerSelectDropdown:GetChildren() + 1)
			trigger.TriggerDetails = { SpellName = "" }
			table.insert(icon.Triggers, trigger)
			
			local triggerDropdownItem = self:AddTriggerDropdown(triggerSelectDropdown, trigger)

			self:SelectTrigger(triggerDropdownItem)
		end)
	end
end

function AuraMasteryConfig:OnDeleteTrigger( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				table.remove(icon.Triggers, triggerId)
				self:PopulateTriggers(icon)
				break
			end
		end
	end
end

function AuraMasteryConfig:OnTriggerMoveUp( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				if triggerId > 1 then
					icon.Triggers[triggerId] = icon.Triggers[triggerId-1]
					icon.Triggers[triggerId-1] = trigger

					self:PopulateTriggers(icon)
				end
				break
			end
		end
	end
end

function AuraMasteryConfig:OnTriggerMoveDown( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				if triggerId < # icon.Triggers then
					icon.Triggers[triggerId] = icon.Triggers[triggerId+1]
					icon.Triggers[triggerId+1] = trigger

					self:PopulateTriggers(icon)
				end
				break
			end
		end
	end
end

function AuraMasteryConfig:OnTriggerType( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerType"):SetText(wndHandler:GetText())
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)

	self:PopulateTriggerDetails(wndHandler:GetText())
end

function AuraMasteryConfig:PopulateTriggerDetails(triggerType)
	local editor = self.configForm:FindChild("TriggerEditor")
	local triggerDetails = editor:FindChild("TriggerDetails")
	if triggerDetails ~= nil then
		triggerDetails:Destroy()
	end

	local triggerEffects = self.configForm:FindChild("TriggerEffects")

	local detailsEditor = Apollo.LoadForm("AuraMastery.xml", "TriggerDetails." .. triggerType, editor, self)
	if detailsEditor ~= nil then
		detailsEditor:SetName("TriggerDetails")
		detailsEditor:SetAnchorOffsets(0, 150, 0, 150 + detailsEditor:GetHeight())
		triggerEffects:SetAnchorOffsets(0, 150 + detailsEditor:GetHeight(), 0, 150 + detailsEditor:GetHeight() + triggerEffects:GetHeight())

		self:InitializeTriggerDetailsWindow(triggerType, self.configForm)
	else
		triggerEffects:SetAnchorOffsets(0, 150, 0, triggerEffects:GetHeight())
	end
end

function AuraMasteryConfig:InitializeTriggerDetailsWindow(triggerType, detailsEditor)
	detailsEditor:FindChild("TriggerTypeDropdown"):Show(false)
	if triggerType == "Resources" then
		self:InitializeResourceEditor(detailsEditor:FindChild("Mana"))
		self:InitializeResourceEditor(detailsEditor:FindChild("Resource"))
	elseif triggerType == "Health" then
		self:InitializeResourceEditor(detailsEditor:FindChild("Health"))
		self:InitializeResourceEditor(detailsEditor:FindChild("Shield"))
	end
end

function AuraMasteryConfig:InitializeResourceEditor(editor)
	editor:FindChild("Operator"):AddItem("==", "", 1)
	editor:FindChild("Operator"):AddItem("!=", "", 2)
	editor:FindChild("Operator"):AddItem(">", "", 3)
	editor:FindChild("Operator"):AddItem("<", "", 4)
	editor:FindChild("Operator"):AddItem(">=", "", 5)
	editor:FindChild("Operator"):AddItem("<=", "", 6)
end

function AuraMasteryConfig:OnCheckTriggerTypeButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEditor"):Enable(false)
	self.configForm:FindChild("TriggerTypeDropdown"):Show(true)
end

function AuraMasteryConfig:OnUncheckTriggerTypeButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerTypeDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerType"):SetCheck(false)
	self.configForm:FindChild("TriggerEditor"):Enable(true)
end

function AuraMasteryConfig:OnTriggerBehaviour( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerBehaviour"):SetText(wndHandler:GetText())
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerBehaviourDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerBehaviour"):SetCheck(false)
	self.configForm:FindChild("TriggerEditor"):Enable(true)
end

function AuraMasteryConfig:OnCheckTriggerBehaviourButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEditor"):Enable(false)
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(true)
end

function AuraMasteryConfig:OnUncheckTriggerBehaviourButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)
end

function AuraMasteryConfig:OnResourceStateToggle( wndHandler, wndControl, eMouseButton )
	local resourceName = string.sub(wndControl:GetName(), 0, -8)
	local editor = wndControl:GetParent():FindChild(resourceName)
	if editor ~= nil then
		self:ToggleResourceEditor(editor, wndControl:IsChecked())
	end
end

function AuraMasteryConfig:ToggleResourceEditor(editor, enabled)
	editor:Enable(enabled)
	editor:SetSprite(enabled and "CRB_Basekit:kitBase_HoloOrange_TinyNoGlow" or "CRB_Basekit:kitBase_HoloBlue_TinyNoGlow")
end

function AuraMasteryConfig:OnImportIcon( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("ClipboardExport"):PasteTextFromClipboard()
	local iconData = self.configForm:FindChild("ClipboardExport"):GetText()

	
	loadstring("icon = " .. iconData)()
	if icon ~= nil and icon.iconName ~= nil then
		local newIcon = self.auraMastery:AddIcon()
		newIcon:Load(icon)
		self:CreateIconItem(newIcon.iconId, newIcon)
	else
		Print("Failed to import icon, invalid load data in clipboard.")
	end
end

function AuraMasteryConfig:OnExportIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		self.configForm:FindChild("ClipboardExport"):SetText(self:Serialize(icon:GetSaveData()))
		self.configForm:FindChild("ClipboardExport"):CopyTextToClipboard()
	end
end

function AuraMasteryConfig:OnSharingMessageReceived(channel, msg)
	if msg.Icon ~= nil then
		if not self.configForm:FindChild("ShareConfirmDialog"):IsShown() then
			self.configForm:FindChild("ShareConfirmDialog"):SetData(msg.Icon)
			self.configForm:FindChild("ShareConfirmDialog"):Show(true)
			self.configForm:FindChild("ShareConfirmDialog"):FindChild("ShareConfirmMessage"):SetText(msg.Sender .. " would like to share the icon '" .. msg.Icon.iconName .. "' with you.\n\nWould you like to accept this icon?")
		end
	end
end

function AuraMasteryConfig:OnAcceptIconShare( wndHandler, wndControl, eMouseButton )
	local shareConfirmDialog = self.configForm:FindChild("ShareConfirmDialog")
	local icon = shareConfirmDialog:GetData()
	if icon ~= nil then
		local newIcon = self.auraMastery:AddIcon()	
		newIcon:Load(icon)
		self:CreateIconItem(newIcon.iconId, newIcon)

		shareConfirmDialog:Show(false)
		shareConfirmDialog:SetData(nil)
	end
end

function AuraMasteryConfig:OnIgnoreIconShare( wndHandler, wndControl, eMouseButton )
	local shareConfirmDialog = self.configForm:FindChild("ShareConfirmDialog")
	shareConfirmDialog:Show(false)
	shareConfirmDialog:SetData(nil)
end

function AuraMasteryConfig:OnFormHide( wndHandler, wndControl )
	if wndControl == wndHandler then
		self.auraMastery.sharingCallback = nil
		self.configForm:FindChild("ShareForm"):FindChild("AllowShareRequests"):SetCheck(false)
		self.configForm:FindChild("ShareButton"):SetBGColor("ffffffff")
	end
end

function AuraMasteryConfig:OnShareIcon( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("ShareForm"):Show(true)
end

function AuraMasteryConfig:OnSendIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local msg = {}
		msg.Icon = icon:GetSaveData()
		self.auraMastery:SendCommsMessageToPlayer(self.configForm:FindChild("ShareForm"):FindChild("Name"):GetText(), msg)
	end
end

function AuraMasteryConfig:OnSendIconToGroup( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local msg = {}
		msg.Icon = icon:GetSaveData()
		self.auraMastery:SendCommsMessageToGroup(msg)
	end
end

function AuraMasteryConfig:OnEnableShareRequests( wndHandler, wndControl, eMouseButton )
	self.auraMastery.sharingCallback = function(chan, msg) self:OnSharingMessageReceived(chan, msg) end
	self.configForm:FindChild("ShareButton"):SetBGColor("ffffff00")
end

function AuraMasteryConfig:OnDisableShareRequests( wndHandler, wndControl, eMouseButton )
	self.auraMastery.sharingCallback = nil
	self.configForm:FindChild("ShareButton"):SetBGColor("ffffffff")
end

function AuraMasteryConfig:Serialize(val, name)
	local tmp = ""
    if name then 
		if type(name) == "number" then
			tmp = tmp .. "[" .. name .. "]" .. " = "
		else
			tmp = tmp .. "['" .. name .. "']" .. " = "
		end
	end

    if type(val) == "table" then
        tmp = tmp .. "{"

        for k, v in pairs(val) do
            tmp =  tmp .. self:Serialize(v, k) .. ","
        end

        tmp = tmp .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

-- inspect loadstring("icon = " .. Serialize(Apollo.GetAddon("AuraMastery").Icons[1]:GetSaveData()))()

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(AuraMasteryConfig, "AuraMastery:Config", 1)