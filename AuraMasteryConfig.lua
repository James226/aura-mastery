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
	self.colorPicker = Apollo.LoadForm(xmlDoc, "ColorPicker", nil, self)
	self.colorPicker:Show(false, true)
	Apollo.LoadSprites("Sprites.xml")
	self.colorPicker:FindChild("Color"):SetSprite("ColorPicker_Colors")
	self.colorPicker:FindChild("Gradient"):SetSprite("ColorPicker_Gradient")
	self:Init()
	return self
end

function AuraMasteryConfig:Show()
	self.configForm:FindChild("ShareConfirmDialog"):Show(false)
	self.timer = ApolloTimer.Create(0.1, true, "OnIconPreview", self)
	self.configForm:Show(true)
end

function AuraMasteryConfig:Init()
	for _, tab in pairs(self.configForm:FindChild("BuffEditor"):GetChildren()) do
		tab:Show(false)
	end
	self.shareChannel = ICCommLib.JoinChannel("AuraMastery", "OnShareMsg", nil)
	self:SelectTab("General")
		
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

	soundItem:FindChild("Id"):SetText(-1)
	soundItem:FindChild("Label"):SetText("None")
			
	for sound, soundNo in pairs(Sound) do
		if type(soundNo) == "number" then
			local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)
			soundItem:FindChild("Id"):SetText(soundNo)
			soundItem:FindChild("Label"):SetText(sound)
		end
	end
	soundList:ArrangeChildrenVert()
	
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
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetMax(100)

	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)

	self.configForm:FindChild("SimpleTabButton"):Show(false)
	self.configForm:FindChild("NoAurasTab"):Show(true)
	self.configForm:FindChild("BuffEditor"):Enable(false)
	
	self:CreateControls()
	self:SelectFirstIcon()

	self.configForm:FindChild("ShareForm"):Show(false)
	self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)
	self.configForm:FindChild("TriggerEffectsDropdown"):Show(false)

	self.configForm:FindChild("TriggerEffectsDropdownList"):ArrangeChildrenVert()

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
	self:Show()
end

-----------------------------------------------------------------------------------------------
-- AuraMasteryForm Functions
-----------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnOK()
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]

	icon:SetIcon(self.configForm)
	self.configForm:FindChild("ExportButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, self:Serialize(icon:GetSaveData()))
	self:UpdateControls()
	self:PopulateTriggers(icon)
end

function AuraMasteryConfig:OnCancel()
	self.timer:Stop()
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

	spriteIcons = {}
    for n in pairs(self.auraMastery.spriteIcons) do table.insert(spriteIcons, n) end
    table.sort(spriteIcons)

	for i, spriteName in pairs(spriteIcons) do
		local spriteIcon = self.auraMastery.spriteIcons[spriteName]
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
	self:PopulateAuraSpellNameList()
	self:PopulateAuraNameList()
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

function AuraMasteryConfig:PopulateAuraNameList()
	local spellNameList = self.configForm:FindChild("AuraNameList")
	spellNameList:DestroyChildren()

	for _, ability in pairs(self:GetAbilitiesList()) do
		local abilityOption = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.GeneralTab.AuraSpellName.AuraNameList.AuraNameButton", spellNameList, self)
		abilityOption:SetText(ability.strName)
		abilityOption:SetData(ability)
	end
	spellNameList:ArrangeChildrenVert()
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
		local iconItem = self:CreateIconItem(icon.iconId, icon)
		local timeText = self:AddIconText(icon)
		timeText.textAnchor = "OB"
		timeText.textString = "{time}"
		local stacksText = self:AddIconText(icon)
		stacksText.textAnchor = "IBR"
		stacksText.textString = "{stacks}"
		local chargesText = self:AddIconText(icon)
		timeText.textAnchor = "ITL"
		timeText.textString = "{charges}"
		self:SelectIcon(iconItem)
		self:OnAddTrigger()
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
	local iconList = icon:GetParent()
	local iconId = tonumber(icon:FindChild("Id"):GetText())
	icon:Destroy()
	iconList:ArrangeChildrenVert()

	self.selectedIcon = nil
	
	self.auraMastery.Icons[iconId]:Delete()
	self.auraMastery.Icons[iconId] = nil

	self.configForm:FindChild("NoAurasTab"):Show(true)
	self.configForm:FindChild("BuffEditor"):Enable(false)

	self:SelectFirstIcon()
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
	
	fNewValue = tonumber(string.format("%.1f", fNewValue))
	icon:SetScale(fNewValue)
	self.configForm:FindChild("BuffScaleValue"):SetText(string.format("%.1f", fNewValue))
end

function AuraMasteryConfig:OnScaleValueChanged( wndHandler, wndControl, strText )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	local value = tonumber(strText)

	if value == nil then
		value = tonumber(string.format("%.1f", self.configForm:FindChild("BuffScale"):GetValue()))
	end

	self.configForm:FindChild("BuffScaleValue"):SetText(tostring(value))
	icon:SetScale(value)
	self.configForm:FindChild("BuffScale"):SetValue(value)
end

function AuraMasteryConfig:OnShownChanged( wndHandler, wndControl, selectedIndex )
	self:SetShownDescription(selectedIndex)
end

function AuraMasteryConfig:SetShownDescription(selectedIndex)
	local shownMsg = ""
	if selectedIndex == 1 then
		shownMsg = "This aura will always be shown."
	elseif selectedIndex == 2 then
		shownMsg = "This aura will be shown when all triggers pass."
	elseif selectedIndex == 3 then
		shownMsg = "This aura will be shown when any trigger passes."
	elseif selectedIndex == 4 then
		shownMsg = "This aura will be shown when all triggers fail."
	end
	self.configForm:FindChild("ShownDescription"):SetText(shownMsg)
end

function AuraMasteryConfig:OnPlaySoundChanged( wndHandler, wndControl, selectedIndex )
	self:SetPlayWhenDescription(selectedIndex)
end

function AuraMasteryConfig:SetPlayWhenDescription(selectedIndex)
	local playSoundDesc = ""
	if selectedIndex == 1 then
		playSoundDesc = "This sound will be played when all triggers pass."
	elseif selectedIndex == 2 then
		playSoundDesc = "This sound will be played when any trigger passes."
	elseif selectedIndex == 3 then
		playSoundDesc = "This sound will be played when all triggers fail."
	end

	self.configForm:FindChild("PlaySoundDescription"):SetText(playSoundDesc)
end

function AuraMasteryConfig:OnTabSelected( wndHandler, wndControl, eMouseButton )
	self:SelectTab(wndHandler:GetName():sub(0, -10))
end

function AuraMasteryConfig:OnTabUnselected( wndHandler, wndControl, eMouseButton )	
end

function AuraMasteryConfig:SelectTab(tabName)
	if self.currentTab ~= nil then
		self.configForm:FindChild(self.currentTab .. "TabButton"):SetCheck(false)
		self.configForm:FindChild("BuffEditor"):FindChild(self.currentTab .. "Tab"):Show(false)
	end

	self.currentTab = tabName
	self.configForm:FindChild("BuffEditor"):FindChild(tabName .. "Tab"):Show(true)
	self.configForm:FindChild(tabName .. "TabButton"):SetCheck(true)
end

function AuraMasteryConfig:OnIconPreview()
	self.currentSampleNum = (self.currentSampleNum + 2) % 100
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetProgress(self.currentSampleNum)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetProgress(self.currentSampleNum)
end

function AuraMasteryConfig:OnColorUpdate()
	self.configForm:FindChild("BuffColorSample"):SetBGColor(self.selectedColor)
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetBGColor(self.selectedColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetBGColor(self.selectedColor)
	for _, icon in pairs(self.configForm:FindChild("SpriteItemList"):GetChildren()) do
		icon:FindChild("SpriteItemIcon"):SetBGColor(self.selectedColor)
	end
end

function AuraMasteryConfig:OnColorSelect( wndHandler, wndControl, eMouseButton )
	self:OpenColorPicker(self.selectedColor, function() self:OnColorUpdate() end)
end

function AuraMasteryConfig:OnSpellNameChanged( wndHandler, wndControl, strText )
	self.configForm:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(strText))
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
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
			self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", false)
		elseif overlaySelection == "Radial" then
			self.configForm:FindChild("LinearOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("RadialOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", true)
			self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", true)
		end
	end    
end

function AuraMasteryConfig:OnOverlayColorUpdate()
	self.configForm:FindChild("OverlayColorSample"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBarColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetBarColor(self.selectedOverlayColor)
end

function AuraMasteryConfig:OnOverlayColorSelect( wndHandler, wndControl, eMouseButton )
	self:OpenColorPicker(self.selectedOverlayColor, function() self:OnOverlayColorUpdate() end)
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
	self.configForm:FindChild("NoAurasTab"):Show(false)
	self.configForm:FindChild("BuffEditor"):Enable(true)
	local icon = self.auraMastery.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
	if icon ~= nil then
		self.configForm:FindChild("BuffId"):SetText(tonumber(iconItem:FindChild("Id"):GetText()))

		if self.selectedIcon ~= nil then
			self.selectedIcon:FindChild("Background"):SetBGColor(ApolloColor.new(0.03, 0.16, 0.24, 1))
		end
		self.selectedIcon = iconItem
		self.selectedIcon:FindChild("Background"):SetBGColor(ApolloColor.new(0.03, 0.5, 0.61, 1))
		self.configForm:FindChild("ExportButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, self:Serialize(icon:GetSaveData()))

		if icon.SimpleMode then
			self:SelectTab("Simple")
			self.configForm:FindChild("GeneralTabButton"):Show(false)
			self.configForm:FindChild("AppearanceTabButton"):Show(false)
			self.configForm:FindChild("TextTabButton"):Show(false)
			self.configForm:FindChild("SimpleTabButton"):Show(true)

			self.configForm:FindChild("AuraEnabled"):SetCheck(icon.enabled)
			self.configForm:FindChild("AuraOnlyInCombat"):SetCheck(icon.onlyInCombat)
			self.configForm:FindChild("AuraActionSet1"):SetCheck(icon.actionSets[1])
			self.configForm:FindChild("AuraActionSet2"):SetCheck(icon.actionSets[2])
			self.configForm:FindChild("AuraActionSet3"):SetCheck(icon.actionSets[3])
			self.configForm:FindChild("AuraActionSet4"):SetCheck(icon.actionSets[4])
			self.configForm:FindChild("AuraAlwaysShow"):SetCheck(icon.showWhen == "Always")
			self.configForm:FindChild("AuraSpriteScaleSlider"):SetValue(icon.iconScale)
			self.configForm:FindChild("AuraSpriteScaleText"):SetText(string.format("%.1f", icon.iconScale))
			self.configForm:FindChild("AuraSpellNameFilter"):SetText(icon.iconName)
			self:SetAuraSpellNameFilter(icon.iconName)
			self.configForm:FindChild("AuraSpellName_FilterOption"):SetCheck(true)
			self.configForm:FindChild("AuraSpellNameList"):SetData(self.configForm:FindChild("AuraSpellName_FilterOption"))
			self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(icon.iconName))
			local spellList = self.configForm:FindChild("AuraSpellNameList")
			for _, spell in pairs(spellList:GetChildren()) do
				if spell:GetName() == "AuraSpellName_FilterOption" then
					spell:SetCheck(true)
				else
					spell:SetCheck(false)
				end
			end

			local simpleTab = self.configForm:FindChild("SimpleTab")
			for _, auraType in pairs(simpleTab:FindChild("AuraType"):GetChildren()) do
				auraType:SetCheck(false)
			end

			if #icon.Triggers == 0 then
				simpleTab:FindChild("AuraType_Cooldown"):SetCheck(true)
				self.configForm:FindChild("AuraBuffDetails"):Show(false)
				simpleTab:FindChild("AuraType"):SetData(simpleTab:FindChild("AuraType_Cooldown"))
			else
				simpleTab:FindChild("AuraType_" .. icon.Triggers[1].Type):SetCheck(true)				
				simpleTab:FindChild("AuraType"):SetData(simpleTab:FindChild("AuraType_" .. icon.Triggers[1].Type))
				if icon.Triggers[1].Type == "Buff" or icon.Triggers[1].Type == "Debuff" then
					self.configForm:FindChild("AuraBuffDetails"):Show(true)
					self.configForm:FindChild("AuraBuffUnit_Player"):SetCheck(icon.Triggers[1].TriggerDetails.Target.Player)
					self.configForm:FindChild("AuraBuffUnit_Target"):SetCheck(icon.Triggers[1].TriggerDetails.Target.Target)
				else
					self.configForm:FindChild("AuraBuffDetails"):Show(false)
					self.configForm:FindChild("AuraBuffUnit_Player"):SetCheck(false)
					self.configForm:FindChild("AuraBuffUnit_Target"):SetCheck(false)					
				end
			end

			local soundSelect = self.configForm:FindChild("AuraSoundSelect")
			if soundSelect:GetData() ~= nil then
				soundSelect:GetData():SetCheck(false)
			end
			
			for _, sound in pairs(self.configForm:FindChild("AuraSoundSelect"):GetChildren()) do
				if tonumber(sound:GetData()) == icon.iconSound then
					sound:SetCheck(true)
					soundSelect:SetData(sound)
					
					local left, top, right, bottom = sound:GetAnchorOffsets()
					soundSelect:SetVScrollPos(top)
					break
				end
			end

			local spriteSelect = self.configForm:FindChild("AuraIconSelect")
			if spriteSelect:GetData() ~= nil then
				spriteSelect:GetData():SetCheck(false)
			end

			if icon.iconSprite == "" then
				self.configForm:FindChild("AuraSprite_Default"):SetCheck(true)
				self.configForm:FindChild("AuraIconSelect"):SetData(self.configForm:FindChild("AuraSprite_Default"))
			else
				for _, sprite in pairs(self.configForm:FindChild("AuraIconSelect"):GetChildren()) do
					if sprite:FindChild("SpriteItemIcon"):GetSprite() == icon.iconSprite then
						sprite:SetCheck(true)
						spriteSelect:SetData(sprite)
						
						local left, top, right, bottom = sprite:GetAnchorOffsets()
						spriteSelect:SetVScrollPos(top)
						break
					end
				end
			end
		else
			if self.currentTab == "Simple" then
				self:SelectTab("General")
			end
			self.configForm:FindChild("GeneralTabButton"):Show(true)
			self.configForm:FindChild("AppearanceTabButton"):Show(true)
			self.configForm:FindChild("TextTabButton"):Show(true)
			self.configForm:FindChild("SimpleTabButton"):Show(false)

			self.configForm:FindChild("BuffName"):SetText(icon.iconName)
			self:SetAuraNameFilter(icon.iconName)
			self.configForm:FindChild("BuffShowWhen"):SelectItemByText(icon.showWhen)
			self:SetShownDescription(self.configForm:FindChild("BuffShowWhen"):GetSelectedIndex() + 1)
			self.configForm:FindChild("BuffPlaySoundWhen"):SelectItemByText(icon.playSoundWhen)
			self:SetPlayWhenDescription(self.configForm:FindChild("BuffPlaySoundWhen"):GetSelectedIndex() + 1)
			self.configForm:FindChild("SelectedSound"):SetText(icon.iconSound)
			self.configForm:FindChild("BuffScale"):SetValue(icon.iconScale)
			self.configForm:FindChild("BuffScaleValue"):SetText(string.format("%.1f", icon.iconScale))
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
			
			
			
			if self.selectedSound ~= nil then
				self.selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
			end
			
			for _, sound in pairs(self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetChildren()) do
				if tonumber(sound:FindChild("Id"):GetText()) == icon.iconSound then
					self.selectedSound = sound
					self.selectedSound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
					
					local left, top, right, bottom = sound:GetAnchorOffsets()
					self.configForm:FindChild("SoundSelectList"):SetVScrollPos(top)
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

			self:PopulateTriggers(icon)
		end
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
	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
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
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		local iconTextId = tonumber(wndHandler:GetParent():FindChild("IconTextId"):GetText())
		self.selectedFontColor = icon.iconText[iconTextId].textFontColor
		self:OpenColorPicker(self.selectedFontColor, function() self:OnFontColorUpdate(wndHandler:GetParent()) end)
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
	local triggerDropdownItem = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.GeneralTab.TriggersPane.TriggerSelectDropdown.TriggerItem", triggerSelectDropdown, self)
	triggerDropdownItem:SetAnchorOffsets(10, 10 + numChildren * 45, -10, 10 + numChildren * 45 + 45)
	triggerDropdownItem:FindChild("TriggerName"):SetText(trigger.Name)
	triggerDropdownItem:SetData(trigger)
	return triggerDropdownItem
end

function AuraMasteryConfig:OnCheckTriggerSelectButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerWindow"):Enable(false)
	self.configForm:FindChild("TriggerSelectDropdown"):Show(true)
	self.configForm:FindChild("TriggerSelectDropdown"):BringToFront()
end

function AuraMasteryConfig:OnUncheckTriggerSelectButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerSelectDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerSelectButton"):SetCheck(false)
	self.configForm:FindChild("TriggerWindow"):Enable(true)
end

function AuraMasteryConfig:OnTriggerSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.configForm:FindChild("TriggerSelectDropdown"):Show(false)
		self:SelectTrigger(wndHandler)
	end
end

function AuraMasteryConfig:SelectTrigger(triggerDropdownItem)
	local editor = self.configForm:FindChild("TriggerWindow")

	if triggerDropdownItem == nil then
		editor:FindChild("TriggerEditor"):Show(false)
		editor:FindChild("GeneralTriggerControls"):Show(false)
	else
		editor:FindChild("TriggerEditor"):Show(true)
		editor:FindChild("GeneralTriggerControls"):Show(true)
		local trigger = triggerDropdownItem:GetData()
		editor:SetData(trigger)
		self.configForm:FindChild("TriggerSelectButton"):SetText(trigger.Name)
		editor:FindChild("TriggerName"):SetText(trigger.Name)
		editor:FindChild("TriggerName"):FindChild("Placeholder"):Show(trigger.Name == "")
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
			editor:FindChild("SpellName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.SpellName == "")
			editor:FindChild("ChargesEnabled"):SetCheck(trigger.TriggerDetails.Charges.Enabled)
			editor:FindChild("Charges"):Enable(trigger.TriggerDetails.Charges.Enabled)
			editor:FindChild("Charges"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Charges.Operator)
			editor:FindChild("Charges"):FindChild("ChargesValue"):SetTextRaw(trigger.TriggerDetails.Charges.Value)
		elseif trigger.Type == "Buff" then
			editor:FindChild("BuffName"):SetText(trigger.TriggerDetails.BuffName)
			editor:FindChild("BuffName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.BuffName == "")
			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
			editor:FindChild("StacksEnabled"):SetCheck(trigger.TriggerDetails.Stacks.Enabled)
			editor:FindChild("Stacks"):Enable(trigger.TriggerDetails.Stacks.Enabled)
			editor:FindChild("Stacks"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Stacks.Operator)
			editor:FindChild("Stacks"):FindChild("StacksValue"):SetTextRaw(trigger.TriggerDetails.Stacks.Value)
		elseif trigger.Type == "Debuff" then
			editor:FindChild("DebuffName"):SetText(trigger.TriggerDetails.DebuffName)
			editor:FindChild("DebuffName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.DebuffName == "")
			editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
			editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
			editor:FindChild("StacksEnabled"):SetCheck(trigger.TriggerDetails.Stacks.Enabled)
			editor:FindChild("Stacks"):Enable(trigger.TriggerDetails.Stacks.Enabled)
			editor:FindChild("Stacks"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Stacks.Operator)
			editor:FindChild("Stacks"):FindChild("StacksValue"):SetTextRaw(trigger.TriggerDetails.Stacks.Value)
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
		elseif trigger.Type == "Scriptable" then
			editor:FindChild("Script"):SetText(trigger.TriggerDetails.Script)
		elseif trigger.Type == "Keybind" then
			editor:FindChild("KeybindTracker_Key"):SetText(trigger.TriggerDetails.Key)
			editor:FindChild("KeybindTracker_Duration"):SetText(trigger.TriggerDetails.Duration)
		elseif trigger.Type == "Limited Action Set Checker" then
			editor:FindChild("AbilityName"):SetText(trigger.TriggerDetails.AbilityName)
			if trigger.TriggerDetails.AbilityName ~= "" then
				editor:FindChild("AbilityName"):FindChild("Placeholder"):Show(false, false)
			end
		end

		self.configForm:FindChild("TriggerTypeDropdown"):Show(false)

		self.configForm:FindChild("TriggerEffectsList"):DestroyChildren()
		for _, triggerEffect in pairs(trigger.TriggerEffects) do
			self:AddTriggerEffect(triggerEffect)
		end

		local effectItems = self.configForm:FindChild("TriggerEffectsList"):GetChildren()
		if #effectItems > 0 then
			effectItems[1]:SetCheck(true)
			self:OnTriggerEffectSelect(effectItems[1], effectItems[1])
		else
			self.configForm:FindChild("TriggerEffectContainer"):Show(false)
		end
	end
end

function AuraMasteryConfig:PopulateValueBasedEditor(trigger, editor, resourceType)
	local resourceEditor = editor:FindChild(resourceType)
	
	if trigger.TriggerDetails[resourceType] ~= nil then
		editor:FindChild(resourceType .. "Enabled"):SetCheck(true)
		self:ToggleResourceEditor(resourceEditor, true)
		resourceEditor:FindChild("Operator"):SetTextRaw(trigger.TriggerDetails[resourceType].Operator)
		resourceEditor:FindChild("Value"):SetText(trigger.TriggerDetails[resourceType].Value)
		resourceEditor:FindChild("Percent"):SetCheck(trigger.TriggerDetails[resourceType].Percent)
	else
		editor:FindChild(resourceType .. "Enabled"):SetCheck(false)
		self:ToggleResourceEditor(resourceEditor, false)
		resourceEditor:FindChild("Operator"):SetTextRaw(">")
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
			local trigger = iconTrigger.new(icon, icon.buffWatch)
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
				trigger:RemoveFromBuffWatch()
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
	self.configForm:FindChild("TriggerType"):SetText(wndHandler:GetName():sub(12))
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)

	self:PopulateTriggerDetails(wndHandler:GetName():sub(12))
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
		detailsEditor:SetAnchorOffsets(0, 10, 0, 10 + detailsEditor:GetHeight())
		triggerEffects:SetAnchorOffsets(0, 10 + detailsEditor:GetHeight(), 0, 10 + detailsEditor:GetHeight() + triggerEffects:GetHeight())

		self:InitializeTriggerDetailsWindow(triggerType, self.configForm)
	else
		triggerEffects:SetAnchorOffsets(0, 10, 0, 10 + triggerEffects:GetHeight())
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
	elseif triggerType == "Cooldown" then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("SpellName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Buff" then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("BuffName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Debuff" then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("DebuffName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Limited Action Set Checker" then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("AbilityName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
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
	self.configForm:FindChild("TriggerBehaviour"):SetText(wndHandler:GetName():sub(17))
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
	self.configForm:FindChild("ClipboardExport"):SetText("")
	self.configForm:FindChild("ClipboardExport"):PasteTextFromClipboard()
	local iconData = self.configForm:FindChild("ClipboardExport"):GetText()

	local iconScript, loadStringError = loadstring("return " .. iconData)
	if iconScript then
		local status, result = pcall(iconScript)
		if status then
			if result ~= nil and result.iconName ~= nil then
				local newIcon = self.auraMastery:AddIcon()
				newIcon:Load(result)
				self:CreateIconItem(newIcon.iconId, newIcon)
			else
				Print("Failed to import icon. Data deserialized but was invalid.")
			end
		else
			Print("Failed to import icon, invalid load data in clipboard: " .. tostring(result))
		end
	else
		Print("Failed to import icon, invalid load data in clipboard: " .. tostring(loadStringError))
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

function AuraMasteryConfig:OpenColorPicker(color, callback)
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
	self.editingColor = color
	self.originalColor = CColor.new(color.r, color.g, color.b, color.a)
	self.onColorChange = callback

	self.colorPicker:FindChild("PreviewOld"):SetBGColor(self.originalColor)
	self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)

	self.colorPicker:FindChild("Red"):SetText(string.format("%.f", math.max(0, color.r * 255)))
	self.colorPicker:FindChild("Green"):SetText(string.format("%.f", math.max(0, color.g * 255)))
	self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", math.max(0, color.b * 255)))
	self.colorPicker:FindChild("AlphaText"):SetText(string.format("%.f", math.max(0, color.a * 100)))
	self.colorPicker:FindChild("AlphaSlider"):SetValue(string.format("%.f", math.max(0, color.a * 100)))
	self:UnpackColor()
end

function AuraMasteryConfig:OnCloseColorPicker( wndHandler, wndControl, eMouseButton )
	self.editingColor.r, self.editingColor.g, self.editingColor.b = self.originalColor.r, self.originalColor.g ,self.originalColor.b
	self.onColorChange()
	self.colorPicker:Show(false)
end

function AuraMasteryConfig:OnColorPickerOk( wndHandler, wndControl, eMouseButton )
	self.editingColor = nil
	self.originalColor = nil
	self.colorPicker:Show(false)
end

function AuraMasteryConfig:OnColorPickerColorStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self.colorPickerColorSelected = true
		self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
	end
end

function AuraMasteryConfig:OnColorPickerColorStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.colorPickerColorSelected = false
	end
end

function AuraMasteryConfig:OnColorPickerColorMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.colorPickerColorSelected then
			self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
		end
	end
end

function AuraMasteryConfig:OnColorMove(x, y)
	local indicator = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator")
	local offset = math.max(0, math.min(1, y / self.colorPicker:FindChild("Color"):GetHeight()))
	indicator:SetAnchorPoints(0, offset, 1, offset)
	self:UpdateColorPicker()
end

local function ConvertRGBToHSV(r, g, b)
    local h, s, v
    local min, max, delta

    min = math.min(r, g, b)
    max = math.max(r, g, b)

    v = max;
    delta = max - min;
    if max > 0.0 then
        s = (delta / max)
    else
        r, g ,b = 0, 0, 0
        s = 0.0
        h = nil
        return h, s, v
    end
    if r >= max then
        h = ( g - b ) / delta
    else
	    if g >= max then
	        h = 2.0 + ( b - r ) / delta
	    else
	        h = 4.0 + ( r - g ) / delta
	    end
	end

    h = h * 60.0

    if h < 0.0 then
        h = h + 360.0
    end

    return h, s, v
end

local function ConvertHSVToRGB(h, s, v)
    local hh, p, q, t, ff
    local i
    local r, g, b

    if s <= 0.0 then
        r, g, b = v, v, v
        return r, g, b
    end

    hh = h
    if hh >= 360.0 then hh = 0.0 end
    hh = hh / 60.0
    i = math.floor(hh)
    ff = hh - i;
    p = v * (1.0 - s);
    q = v * (1.0 - (s * ff));
    t = v * (1.0 - (s * (1.0 - ff)));

    if i == 0 then
    	r, g, b = v, t, p
    elseif i == 1 then
    	r, g, b = q, v, p
    elseif i == 2 then
    	r, g, b = p, v, t
    elseif i == 3 then
    	r, g, b = p, q, v
    elseif i == 4 then
    	r, g, b = t, p, v
    else
    	r, g, b = v, p, q
    end
    return r, g, b    
end

function AuraMasteryConfig:UpdateColorPicker()
	local colorOffsetX, h = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):GetAnchorPoints()
	local s, v = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):GetAnchorPoints()

	h = math.max(0, math.min(1, h))
	s = math.max(0, math.min(1, s))
	v = math.max(0, math.min(1, v))

	h = (1 - h) * 360
	v = (1 - v) * 255
	local r, g, b = ConvertHSVToRGB(h, s, v)

	self.colorPicker:FindChild("Red"):SetText(string.format("%.f", r))
	self.colorPicker:FindChild("Green"):SetText(string.format("%.f", g))
	self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", b))
	local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
	self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

	self.editingColor.r = r / 255
	self.editingColor.g = g / 255
	self.editingColor.b = b / 255
	self:UpdateColor()
end

function AuraMasteryConfig:	UnpackColor()
	local r = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Red"):GetText()) or 0))
	local g = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Green"):GetText()) or 0))
	local b = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Blue"):GetText()) or 0))

	local h, s, v = ConvertRGBToHSV(r, g, b)
	local gradOffsetY = 1 - (v / 255)

	local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
	self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

	self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):SetAnchorPoints(s, gradOffsetY, s, gradOffsetY)
	local colorPos = 1 - (h / 360)
	self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):SetAnchorPoints(0, colorPos, 1, colorPos)

	self.editingColor.r = r / 255
	self.editingColor.g = g / 255
	self.editingColor.b = b / 255

	self:UpdateColor()
end

function AuraMasteryConfig:UpdateColor()
	self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)
	self.colorPicker:FindChild("HexCode"):SetText(string.format("%02x%02x%02x%02x", self.editingColor.r * 255, self.editingColor.g * 255, self.editingColor.b * 255, self.editingColor.a * 255))

	self.onColorChange()
end

function AuraMasteryConfig:OnColorChange( wndHandler, wndControl, strText )
	self:UnpackColor()
end

function AuraMasteryConfig:OnColorPickerGradientStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.colorPickerGradientSelected = true
		self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
	end
end

function AuraMasteryConfig:OnColorPickerGradientStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self.colorPickerGradientSelected = false
	end
end

function AuraMasteryConfig:OnColorPickerGradientMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.colorPickerGradientSelected then
			self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
		end
	end
end

function AuraMasteryConfig:UpdateGradientPosition(x, y)
	local indicator = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator")
	local offsetX = math.max(0, math.min(1, x / self.colorPicker:FindChild("Gradient"):GetWidth()))
	local offsetY = math.max(0, math.min(1, y / self.colorPicker:FindChild("Gradient"):GetHeight()))

	indicator:SetAnchorPoints(offsetX, offsetY, offsetX, offsetY)

	self:UpdateColorPicker()
end

function AuraMasteryConfig:OnAlphaSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", fNewValue))
	self.editingColor.a = fNewValue / 100
	self:UpdateColor()
end

function AuraMasteryConfig:OnAlphaTextChanged( wndHandler, wndControl, strText )
	local alpha = math.min(255, math.max(0, self.colorPicker:FindChild("AlphaText"):GetText() or 0))
	self.colorPicker:FindChild("AlphaSlider"):SetValue(alpha)
	self.editingColor.a = alpha / 100
	self:UpdateColor()
end

function AuraMasteryConfig:OnHexCodeChanged( wndHandler, wndControl, strText )
	if string.len(strText) == 8 then
		local r = tonumber(string.sub(strText, 1, 2), 16)
		local g = tonumber(string.sub(strText, 3, 4), 16)
		local b = tonumber(string.sub(strText, 5, 6), 16)
		local a = tonumber(string.sub(strText, 7, 8), 16)
		self.editingColor.r, self.editingColor.g, self.editingColor.b, self.editingColor.a = r / 255, g / 255, b / 255, a / 255
		

		self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", self.editingColor.a * 100))
		self.colorPicker:FindChild("AlphaSlider"):SetValue(self.editingColor.a * 100)

		self:UpdateColor()
	end
end

function AuraMasteryConfig:OnPlaceholderEditorChanged( wndHandler, wndControl, strText )
	if wndHandler == wndControl then
		wndHandler:FindChild("Placeholder"):Show(strText == "")
	end
end

---------------------------------------------------------------------------------------------------
-- Trigger Effect Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnColorChanger( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local oldColor = wndHandler:FindChild("ColorSample"):GetBGColor()
		local color = CColor.new(oldColor.r, oldColor.g, oldColor.b, oldColor.a)
		wndHandler:FindChild("ColorSample"):SetBGColor(color)
		self:OpenColorPicker(color, function() wndHandler:FindChild("ColorSample"):SetBGColor(color) end)
	end
end

function AuraMasteryConfig:OnCheckAddTriggerEffect( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(true)
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList"):Enable(false)
end

function AuraMasteryConfig:OnUncheckAddTriggerEffect( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerEffectDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerEffects"):FindChild("AddTriggerEffect"):SetCheck(false)
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList"):Enable(true)
end

function AuraMasteryConfig:OnAddTriggerEffect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(false)
	local triggerEffectsList = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList")
	triggerEffectsList:Enable(true)
	GeminiPackages:Require("AuraMastery:TriggerEffect", function(TriggerEffect)
		local selectedTrigger = self.configForm:FindChild("TriggerWindow"):GetData()
		if selectedTrigger ~= nil then	
			local triggerEffect = TriggerEffect.new(selectedTrigger, wndHandler:GetText())
			table.insert(selectedTrigger.TriggerEffects, triggerEffect)			
			self:AddTriggerEffect(triggerEffect)
		end
	end)
end

function AuraMasteryConfig:AddTriggerEffect(triggerEffect)
	local triggerEffectsList = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList")
	local option = Apollo.LoadForm("AuraMastery.xml", "TriggerEffects.TriggerEffectOption", triggerEffectsList, self)
	triggerEffectsList:ArrangeChildrenVert()
	option:SetText(triggerEffect.Type)
	option:SetData(triggerEffect)
end

function AuraMasteryConfig:GetNextEffect(selectedEffectItem)
	local currentEffect, lastEffect
	local found
	for id, effect in pairs(self.configForm:FindChild("TriggerEffectsList"):GetChildren()) do
		lastEffect = currentEffect
		currentEffect = effect
		if found then
			return effect
		end
		if selectedEffectItem == effect then
			found = true
		end
	end
	
	if selectedEffectItem == currentEffect then
		return lastEffect
	else
		return nil
	end
end
function AuraMasteryConfig:OnRemoveTriggerEffect( wndHandler, wndControl, eMouseButton )
	local selectedTrigger = self.configForm:FindChild("TriggerWindow"):GetData()
	if selectedTrigger ~= nil then
		local selectedEffectItem = self.configForm:FindChild("TriggerEffectsList"):GetData()
		if selectedEffectItem ~= nil then
			local selectedEffect = selectedEffectItem:GetData()
			selectedTrigger:RemoveEffect(selectedEffect)
			local nextEffect = self:GetNextEffect(selectedEffectItem)
			selectedEffectItem:Destroy()
			local numEffects = #self.configForm:FindChild("TriggerEffectsList"):GetChildren()
			if numEffects > 0 then
				self.configForm:FindChild("TriggerEffectsList"):ArrangeChildrenVert()
				nextEffect:SetCheck(true)
				self:OnTriggerEffectSelect(nextEffect, nextEffect, 1)
			else
				triggerEffects:FindChild("TriggerEffectContainer"):Show(true)
			end
		end
	end
end

function AuraMasteryConfig:OnTriggerEffectSelect( wndHandler, wndControl, eMouseButton )
	local triggerEffects = self.configForm:FindChild("TriggerEffects")
	local triggerEffectEditor = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectEditor")
	if triggerEffectEditor ~= nil then
		triggerEffectEditor:Destroy()
	end
	self.configForm:FindChild("TriggerEffectsList"):SetData(wndHandler)
	triggerEffectEditor = Apollo.LoadForm("AuraMastery.xml", "TriggerEffects." .. wndHandler:GetText(), self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectOptions"), self)
	if triggerEffectEditor ~= nil then
		triggerEffectEditor:SetName("TriggerEffectEditor")
	end
	local triggerEffect = wndHandler:GetData()
	if triggerEffect ~= nil then
		if triggerEffect.When == "Pass" then
			triggerEffects:FindChild("TriggerEffectOnPass"):SetCheck(true)
			triggerEffects:FindChild("TriggerEffectOnFail"):SetCheck(false)
		else
			triggerEffects:FindChild("TriggerEffectOnPass"):SetCheck(false)
			triggerEffects:FindChild("TriggerEffectOnFail"):SetCheck(true)
		end
		triggerEffects:FindChild("TriggerEffectIsTimed"):SetCheck(triggerEffect.isTimed)
		triggerEffects:FindChild("TriggerEffectTimerLength"):SetText(triggerEffect.timerLength)
		if triggerEffect.Type == "Icon Color" then
			local color = CColor.new(triggerEffect.EffectDetails.Color.r, triggerEffect.EffectDetails.Color.g, triggerEffect.EffectDetails.Color.b, triggerEffect.EffectDetails.Color.a)
			triggerEffectEditor:FindChild("IconColor"):FindChild("ColorSample"):SetBGColor(color)
		elseif triggerEffect.Type == "Activation Border" then
			for _, border in pairs(triggerEffectEditor:FindChild("BorderSelect"):GetChildren()) do
				if border:FindChild("Window"):GetSprite() == triggerEffect.EffectDetails.BorderSprite then
					border:SetCheck(true)
				else
					border:SetCheck(false)
				end
			end
		end
	end
	triggerEffects:FindChild("TriggerEffectContainer"):Show(true)
end

function AuraMasteryConfig:OnCooldownChargesToggle( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():FindChild("Charges"):Enable(wndHandler:IsChecked())
	end
end

function AuraMasteryConfig:OnTriggerDetailsStacksToggle( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():FindChild("Stacks"):Enable(wndHandler:IsChecked())
	end
end

---------------------------------------------------------------------------------------------------
---- Simple Tab
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnAuraTypeSelect( wndHandler, wndControl, eMouseButton )
	local auraType = string.sub(wndHandler:GetName(), 10)
	wndHandler:GetParent():SetData(wndHandler)
	if auraType == "Buff" or auraType == "Debuff" then
		self.configForm:FindChild("AuraBuffDetails"):Show(true)
	else
		self.configForm:FindChild("AuraBuffDetails"):Show(false)
	end
end

function AuraMasteryConfig:PopulateAuraSpellNameList()
	local spellNameList = self.configForm:FindChild("AuraSpellNameList")

	local filterOption = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSpellName_Template", spellNameList, self)
	filterOption:SetName("AuraSpellName_FilterOption")
	filterOption:SetText("")

	for _, ability in pairs(self:GetAbilitiesList()) do
		local abilityOption = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSpellName_Template", spellNameList, self)
		abilityOption:SetText(ability.strName)
		abilityOption:SetData(ability)
	end
	spellNameList:ArrangeChildrenVert()

	local spriteList = self.configForm:FindChild("AuraIconSelect")
	
	local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSprite_Template", spriteList, self)
	spriteItem:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(self.configForm:FindChild("BuffName"):GetText()))
	spriteItem:SetName("AuraSprite_Default")
	spriteItem:FindChild("SpriteItemText"):SetText("Spell Icon")

	for spriteName, spriteIcon in pairs(self.auraMastery.spriteIcons) do
		local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSprite_Template", spriteList, self)
		spriteItem:FindChild("SpriteItemIcon"):SetSprite(spriteIcon)
		spriteItem:FindChild("SpriteItemText"):SetText(spriteName)
	end
	spriteList:ArrangeChildrenTiles()

	local soundList = self.configForm:FindChild("AuraSoundSelect")
	
	local soundItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSound_Template", soundList, self)
	soundItem:SetData(-1)
	soundItem:SetText("None")
			
	for sound, soundNo in pairs(Sound) do
		if type(soundNo) == "number" then
			local soundItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSound_Template", soundList, self)
			soundItem:SetData(soundNo)
			soundItem:SetText(sound)
		end
	end
	soundList:ArrangeChildrenVert()
end

function AuraMasteryConfig:OnAuraSpellNameFilterChanged( wndHandler, wndControl, filterText )
	self:SetAuraSpellNameFilter(filterText)
end

function AuraMasteryConfig:SetAuraSpellNameFilter(filterText)
	if filterText ~= "" then
		self.configForm:FindChild("AuraSpellNameFilter"):FindChild("Placeholder"):Show(false)
	else
		self.configForm:FindChild("AuraSpellNameFilter"):FindChild("Placeholder"):Show(true)
	end

	local spellNameList = self.configForm:FindChild("AuraSpellNameList")
	for _, abilityOption in pairs(spellNameList:GetChildren()) do
		if abilityOption:GetName() == "AuraSpellName_FilterOption" then
			abilityOption:SetText(filterText)
		elseif abilityOption:GetText():lower():find(filterText:lower()) ~= nil then
			abilityOption:Show(true)
		else
			abilityOption:Show(false)
		end
	end
	spellNameList:ArrangeChildrenVert()

	if self.configForm:FindChild("AuraSpellName_FilterOption"):IsChecked() then
		self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(filterText))
	end
end

function AuraMasteryConfig:OnAuraNameFilterChanged( wndHandler, wndControl, filterText )
	self:SetAuraNameFilter(filterText)
end

function AuraMasteryConfig:SetAuraNameFilter(filterText)
	if filterText ~= "" then
		self.configForm:FindChild("BuffName"):FindChild("Placeholder"):Show(false)
	else
		self.configForm:FindChild("BuffName"):FindChild("Placeholder"):Show(true)
	end

	local spellNameList = self.configForm:FindChild("AuraNameList")
	for _, abilityOption in pairs(spellNameList:GetChildren()) do
		if abilityOption:GetText():lower():find(filterText:lower()) ~= nil then
			abilityOption:Show(true)
		else
			abilityOption:Show(false)
		end
	end
	spellNameList:ArrangeChildrenVert()
end

function AuraMasteryConfig:OnGenerateAuraSpellTooltip(wndHandler, wndControl)
	if wndControl == wndHandler then
		splTarget = wndControl:GetData()
		local currentTier = splTarget.nCurrentTier
		splObject = splTarget.tTiers[currentTier].Spell.CodeEnumCastResult.ItemObjectiveComplete

		Tooltip.GetSpellTooltipForm(self, wndHandler, GameLib.GetSpell(splObject:GetId()), false)
	end
end

function AuraMasteryConfig:OnAuraSoundSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		Sound.Play(wndHandler:GetData())
		wndHandler:GetParent():SetData(wndHandler)
	end
end

function AuraMasteryConfig:OnAuraScaleChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	
	fNewValue = tonumber(string.format("%.1f", fNewValue))
	icon:SetScale(fNewValue)
	wndHandler:GetParent():FindChild("AuraSpriteScaleText"):SetText(fNewValue)
end

function AuraMasteryConfig:OnAuraScaleTextChanged( wndHandler, wndControl, strText )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	local value = tonumber(strText)
	local scaleSlider = wndHandler:GetParent():FindChild("AuraSpriteScaleSlider")
	if value == nil then
		value = tonumber(string.format("%.1f", scaleSlider:GetValue()))
	end

	wndHandler:SetText(tostring(value))
	icon:SetScale(value)
	scaleSlider:SetValue(value)
end

function AuraMasteryConfig:OnAuraSpellNameSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():SetData(wndHandler)
		self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(wndHandler:GetText()))
	end
end

function AuraMasteryConfig:OnAuraNameSelect( wndHandler, wndControl, eMouseButton )
	wndHandler:GetParent():GetParent():FindChild("BuffName"):SetText(wndHandler:GetText())
	self:OnSpellNameChanged(nil, nil, wndHandler:GetText())
end

function AuraMasteryConfig:OnAuraSpriteSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():SetData(wndHandler)
	end
end

function AuraMasteryConfig:OnAdvancedMode( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]

	icon.SimpleMode = false
	self:SelectIcon(self.selectedIcon)
end


local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(AuraMasteryConfig, "AuraMastery:Config", 1)
