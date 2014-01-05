-----------------------------------------------------------------------------------------------
-- Client Lua Script for AuraMastery
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"

-----------------------------------------------------------------------------------------------
-- AuraMastery Module Definition
-----------------------------------------------------------------------------------------------
local AuraMastery = {} 
local Icon = _G["AuraMasteryLibs"]["Icon"]

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local spriteIcons = {
	Tick = "icon_Tick",
	No = "icon_No",
	Crosshair = "icon_Crosshair",
	Flower = "icon_Flower",
	Fluer = "icon_Fluer",
	Heart = "icon_Heart",
	Lightning = "icon_Lightning",
	Paw = "icon_Paw"
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AuraMastery:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
	self.buffWatch = {
		Buff = {
			Player = {},
			Target = {}
		},
		Debuff = {
			Player = {},
			Target = {}
		},
		Cooldown = {}
	}
	self.BarLocked = true
	self.nextIconId = 1
	self.selectedColor = CColor.new(1,1,1,1)
	self.selectedFontColor = CColor.new(1,1,1,1)
	
    return o
end


function AuraMastery:Init()
    Apollo.RegisterAddon(self)
end

function AuraMastery:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
	local saveData = { }
	
	saveData["Icons"] = { }
	Print("Saving Icons")
	for idx, icon in pairs(self.Icons) do
		saveData["Icons"][# saveData["Icons"] + 1] = icon:GetSaveData()
	end
	
	return saveData
end

function AuraMastery:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end
	
	Event_FireGenericEvent("AMLoadIcons", tData)
end

function AuraMastery:OnLoadIcons(tData)	
	for idx, icon in pairs(tData["Icons"]) do
		local newIcon = self:AddIcon()
		newIcon:Load(icon)
	end
	self:UpdateControls()
	self:SelectFirstIcon()
end
 

-----------------------------------------------------------------------------------------------
-- AuraMastery OnLoad
-----------------------------------------------------------------------------------------------
function AuraMastery:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("am", "OnAuraMasteryOn", self)
	Apollo.RegisterEventHandler("AMLoadIcons", "OnLoadIcons", self)
	Apollo.LoadSprites("Icons.xml")
    
    -- load our forms
    self.wndMain = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm", nil, self)
    self.wndMain:Show(false)
	for _, tab in pairs(self.wndMain:FindChild("BuffEditor"):GetChildren()) do
		tab:Show(false)
	end
	self.wndMain:FindChild("GeneralTabButton"):SetCheck(true)
	self.wndMain:FindChild("BuffEditor"):FindChild("GeneralTab"):Show(true)
	
	self.wndMain:FindChild("BuffType"):AddItem("Buff", "", 1)
	self.wndMain:FindChild("BuffType"):AddItem("Debuff", "", 2)
	self.wndMain:FindChild("BuffType"):AddItem("Cooldown", "", 3)
	
	self.wndMain:FindChild("BuffTarget"):AddItem("Player", "", 1)
	self.wndMain:FindChild("BuffTarget"):AddItem("Target", "", 2)
	self.wndMain:FindChild("BuffTarget"):AddItem("Both", "", 3)
	
		
	self.wndMain:FindChild("BuffShown"):AddItem("Active", "", 1)
	self.wndMain:FindChild("BuffShown"):AddItem("Inactive", "", 2)
	self.wndMain:FindChild("BuffShown"):AddItem("Both", "", 3)
	
	local soundList = self.wndMain:FindChild("SoundSelect"):FindChild("SoundSelectList")
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
	
	local soundSelectHeight = self.wndMain:FindChild("SoundSelect"):GetHeight()
	self.wndMain:FindChild("SoundSelect"):SetVScrollInfo(nextItem - soundSelectHeight, soundSelectHeight, soundSelectHeight)
	
	self:LoadSpriteIcons()
	
	self.textEditor = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor", self.wndMain:FindChild("TextTab"), self)
	self:LoadFontSelector()
	
	Apollo.RegisterTimerHandler("AuraMastery_BuffTimer", "OnUpdate", self)
	Apollo.CreateTimer("AuraMastery_BuffTimer", 0.1, true)
	
	
	self.Icons = {}
	
	self:SelectFirstIcon()
end

function AuraMastery:GetSpellIconByName(spellName)
	local abilities = AbilityBook.GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	return ""
end

function AuraMastery:LoadSpriteIcons()
	local spriteList = self.wndMain:FindChild("BuffEditor"):FindChild("AppearanceTab"):FindChild("SpriteItemList")
	
	local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
	spriteItem:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(self.wndMain:FindChild("BuffName"):GetText()))
	spriteItem:FindChild("SpriteItemText"):SetText("Spell Icon")
	spriteItem:SetAnchorOffsets(0, 0, spriteItem:GetWidth(), spriteItem:GetHeight())
	
	local iconsPerRow = math.floor(spriteList:GetWidth() / 110)
	local currentPos = 1
	
	for spriteName, spriteIcon in pairs(spriteIcons) do
		local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
		spriteItem:FindChild("SpriteItemIcon"):SetSprite(spriteIcon)
		spriteItem:FindChild("SpriteItemText"):SetText(spriteName)
		local x = math.floor(currentPos % iconsPerRow) * 110
		local y = math.floor(currentPos / iconsPerRow) * 140
		spriteItem:SetAnchorOffsets(x, y, x + spriteItem:GetWidth(), y + spriteItem:GetHeight())
		currentPos = currentPos + 1
	end
end

function AuraMastery:CreateControls()
	local iconList = self.wndMain:FindChild("IconListHolder"):FindChild("IconList")
	for i, icon in pairs(self.Icons) do
		local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
		iconItem:SetAnchorOffsets(0, (i-1) * 40, 500, (i-1) * 40 + 40)
		iconItem:FindChild("Id"):SetText(i)
		iconItem:FindChild("Label"):SetText(icon:GetName())
		iconItem:FindChild("LockButton"):SetCheck(true)
		local left, top, right, bottom = iconList:GetAnchorOffsets()
		iconList:SetAnchorOffsets(left, top, right, bottom + 50)
		icon:SetConfigElement(iconItem)
	end
end

function AuraMastery:UpdateControls()
	for _, iconItem in pairs(self.wndMain:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		local icon = self.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
		iconItem:FindChild("Label"):SetText(icon:GetName())
	end
end

function AuraMastery:SelectFirstIcon()
	for _, icon in pairs(self.wndMain:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		if icon ~= nil then
			self:SelectIcon(icon)
			break
		end
	end
end

-----------------------------------------------------------------------------------------------
-- AuraMastery Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/am"
function AuraMastery:OnAuraMasteryOn()
	self.wndMain:Show(true)
	self.wndMain:ToFront()
end


-----------------------------------------------------------------------------------------------
-- AuraMasteryForm Functions
-----------------------------------------------------------------------------------------------
function AuraMastery:OnOK()	
	local iconId = tonumber(self.wndMain:FindChild("BuffId"):GetText())
	local icon = self.Icons[iconId]
	
	icon:SetIcon(self.wndMain)
	
	self:UpdateControls()
end

function AuraMastery:OnCancel()
	self.wndMain:Show(false) -- hide the window
end

function AuraMastery:OnUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()	
	local targetPlayer = GameLib.GetTargetUnit()

	for _, icon in pairs(self.Icons) do
		icon:PreUpdate()
	end
	
	if unitPlayer ~= nil then
		self:ProcessBuffs(unitPlayer:GetBuffs(), "Player")
	end
	
	if targetPlayer ~= nil then
		self:ProcessBuffs(targetPlayer:GetBuffs(), "Target")
	end	
	
	local abilities = AbilityBook.GetAbilitiesList()
	if abilities then
		self:ProcessCooldowns(abilities)
	end
	
	for _, icon in pairs(self.Icons) do
		icon:PostUpdate()
	end
end

function AuraMastery:ProcessBuffs(buffs, target)
	for idx, buff in pairs(buffs.arBeneficial) do
		if self.buffWatch["Buff"][target][buff.spell:GetName()] ~= nil then
			for _, icon in pairs(self.buffWatch["Buff"][target][buff.spell:GetName()]) do
				icon:SetBuff(buff)
			end
		end
	end
	
	for idx, buff in pairs(buffs.arHarmful) do
		if self.buffWatch["Debuff"][target][buff.spell:GetName()] ~= nil then
			for _, icon in pairs(self.buffWatch["Debuff"][target][buff.spell:GetName()]) do
				icon:SetBuff(buff)
			end
		end
	end
end

function AuraMastery:ProcessCooldowns(abilities)
	for k, v in pairs(abilities) do
		if v.bIsActive and v.nCurrentTier and v.tTiers then
			local tier = v.tTiers[v.nCurrentTier]
			if tier then
				local s = tier.splObject
				if self.buffWatch["Cooldown"][s:GetName()] ~= nil then
					for _, icon in pairs(self.buffWatch["Cooldown"][s:GetName()]) do
						icon:ProcessSpell(s)
					end
				end
			end
		end
	end
end

function AuraMastery:OnLockIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
	if self.Icons[iconId] ~= nil then
		self.Icons[iconId]:Lock()
	end
end

function AuraMastery:OnUnlockIcon( wndHandler, wndControl, eMouseButton )
	self.BarLocked = false
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
	if self.Icons[iconId] ~= nil then
		self.Icons[iconId]:Unlock()
	end
end

function AuraMastery:OnSoundPlay( wndHandler, wndControl, eMouseButton )
	local soundNo = tonumber(self.wndMain:FindChild("SoundNo"):GetText())
	Sound.Play(soundNo)
end

function AuraMastery:OnAddIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		self:AddIcon()
	end
end

function AuraMastery:OnRemoveIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		self:RemoveIcon(self.selectedIcon)
	end
end

function AuraMastery:AddIcon()
	local newIcon = Icon.new(self.buffWatch, self.wndMain)
	newIcon:SetScale(1)
	
	local iconList = self.wndMain:FindChild("IconListHolder"):FindChild("IconList")
	local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
	iconItem:SetAnchorOffsets(0, (self.nextIconId-1) * 40, 0, (self.nextIconId-1) * 40 + 40)
	iconItem:FindChild("Id"):SetText(tostring(self.nextIconId))
	iconItem:FindChild("Label"):SetText(newIcon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	newIcon:SetConfigElement(iconItem)
	self.Icons[self.nextIconId] = newIcon
	self.nextIconId = self.nextIconId + 1
	
	local windowHeight = iconList:GetHeight()
	iconList:SetVScrollInfo(self:NumIcons() * 40 - windowHeight, windowHeight, windowHeight)
	
	return newIcon
end

function AuraMastery:RemoveIcon(icon)
	local iconId = tonumber(icon:FindChild("Id"):GetText())
	icon:Destroy()
	
	self.Icons[iconId]:Delete()
	self.Icons[iconId] = nil
	self:SelectFirstIcon()
	
	local currentPos = 0
	for _, iconItem in pairs(self.wndMain:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		iconItem:SetAnchorOffsets(0, currentPos, 0, currentPos + iconItem:GetHeight())
		currentPos = currentPos + iconItem:GetHeight()
	end
	

	local windowHeight = self.wndMain:FindChild("IconListHolder"):FindChild("IconList"):GetHeight()
	self.wndMain:FindChild("IconListHolder"):FindChild("IconList"):SetVScrollInfo(self:NumIcons() * 40 - windowHeight, windowHeight, windowHeight)
end

function AuraMastery:NumIcons()
	local numIcons = 0
	for _, icon in pairs(self.Icons) do
		if icon ~= nil then
			numIcons = numIcons + 1
		end
	end
	return numIcons
end

function AuraMastery:OnIconScale( wndHandler, wndControl, fNewValue, fOldValue )
	local iconId = tonumber(self.wndMain:FindChild("BuffId"):GetText())
	local icon = self.Icons[iconId]
	
	icon:SetScale(fNewValue)
end

function AuraMastery:OnTabSelected( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("BuffEditor"):FindChild(wndHandler:GetText() .. "Tab"):Show(true)
end

function AuraMastery:OnTabUnselected( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("BuffEditor"):FindChild(wndHandler:GetText() .. "Tab"):Show(false)
end

local function OnColorUpdate()
	AuraMasteryInst:OnColorUpdate()
end

function AuraMastery:OnColorUpdate()
	self.wndMain:FindChild("BuffColorSample"):SetBGColor(self.selectedColor)
	for _, icon in pairs(self.wndMain:FindChild("SpriteItemList"):GetChildren()) do
		icon:FindChild("SpriteItemIcon"):SetBGColor(self.selectedColor)
	end
end

function AuraMastery:OnColorSelect( wndHandler, wndControl, eMouseButton )
	ColorPicker.AdjustCColor(self.selectedColor, true, OnColorUpdate)
end

function AuraMastery:OnSpellNameChanged( wndHandler, wndControl, strText )
	self.wndMain:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(strText))
end

--------------------------------------------------------------------------------------------
-- IconListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMastery:OnListItemSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self:SelectIcon(wndHandler)
	end
end

function AuraMastery:SelectIcon(iconItem)
	local icon = self.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
	if icon ~= nil then
		self.wndMain:FindChild("BuffId"):SetText(tonumber(iconItem:FindChild("Id"):GetText()))
		self.wndMain:FindChild("BuffName"):SetText(icon.iconName)
		self.wndMain:FindChild("BuffType"):SetText(icon.iconType)
		self.wndMain:FindChild("BuffTarget"):SetText(icon.iconTarget)
		self.wndMain:FindChild("BuffShown"):SetText(icon.iconShown)
		self.wndMain:FindChild("SelectedSound"):SetText(icon.iconSound)
		self.wndMain:FindChild("BuffScale"):SetValue(icon.iconScale)
		self.wndMain:FindChild("BuffBackgroundShown"):SetCheck(icon.iconBackground)
		self.wndMain:FindChild("BuffBorderShown"):SetCheck(icon.iconBorder)
		self.wndMain:FindChild("SpriteItemList"):GetChildren()[1]:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(icon.iconName))
		self.selectedColor = icon.iconColor
		self.selectedFontColor = icon.iconText.textFontColor
		self:OnColorUpdate()
		
		for _, spriteIcon in pairs(self.wndMain:FindChild("SpriteItemList"):GetChildren()) do
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
		
		for _, sound in pairs(self.wndMain:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetChildren()) do
			if tonumber(sound:FindChild("Id"):GetText()) == icon.iconSound then
				self.selectedSound = sound
				self.selectedSound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
				
				local left, top, right, bottom = sound:GetAnchorOffsets()
				self.wndMain:FindChild("SoundSelect"):SetVScrollPos(top)
				break
			end
		end
		
		local selectedTextAnchor = self.wndMain:FindChild("AnchorPosition_" .. icon.iconText.textAnchor)
		if selectedTextAnchor ~= nil then
			selectedTextAnchor:SetCheck(true)
		end
		
		for _, font in pairs(self.wndMain:FindChild("FontSelector"):GetChildren()) do
			if font:GetText() == icon.iconText.textFont then
				self:SelectFont(font)
				local left, top, right, bottom = font:GetAnchorOffsets()
				self.wndMain:FindChild("FontSelector"):SetVScrollPos(top)
				break
			end
		end
		self.wndMain:FindChild("FontColorSample"):SetBGColor(icon.iconText.textFontColor)
		self.wndMain:FindChild("FontSample"):SetTextColor(icon.iconText.textFontColor)
	end
end

---------------------------------------------------------------------------------------------------
-- SoundListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMastery:OnSoundItemSelected( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.selectedSound ~= nil then
			self.selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
		end
		self.selectedSound = wndHandler
		self.selectedSound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
		local soundId = tonumber(wndHandler:FindChild("Id"):GetText())
		self.wndMain:FindChild("SoundSelect"):FindChild("SelectedSound"):SetText(soundId)
		Sound.Play(soundId)
	end
end

-----------------------------------------------------------------------------------------------
-- AuraMastery Instance
-----------------------------------------------------------------------------------------------
AuraMasteryInst = AuraMastery:new()
AuraMasteryInst:Init()

---------------------------------------------------------------------------------------------------
-- SpriteItem Functions
---------------------------------------------------------------------------------------------------
function AuraMastery:OnSpriteIconSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectSpriteIcon(wndHandler)
	end
end

function AuraMastery:SelectSpriteIcon(spriteIcon)
	if self.selectedSprite ~= nil then
		self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
	end
	self.selectedSprite = spriteIcon
	if self.selectedSprite:FindChild("SpriteItemText"):GetText() == "Spell Icon" then
		self.wndMain:FindChild("SelectedSprite"):SetText("")
	else
		self.wndMain:FindChild("SelectedSprite"):SetText(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
	end
	self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
	self.selectedSprite:SetText("")
end

function AuraMastery:LoadFontSelector()
	local fontSelector = self.wndMain:FindChild("FontSelector")
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
function AuraMastery:OnFontSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectFont(wndHandler)
	end
end

function AuraMastery:SelectFont(fontElement)
	if self.selectedFont ~= nil then
		self.selectedFont:SetBGColor(CColor.new(1,1,1,1))
	end
	self.wndMain:FindChild("FontSample"):SetFont(fontElement:GetText())
	self.wndMain:FindChild("SelectedFont"):SetText(fontElement:GetText())
	self.selectedFont = fontElement
	self.selectedFont:SetBGColor(CColor.new(1,0,1,1))
end

local function OnFontColorUpdate()
	AuraMasteryInst:OnFontColorUpdate()
end

function AuraMastery:OnFontColorSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		ColorPicker.AdjustCColor(self.selectedFontColor, true, OnFontColorUpdate)
	end
end

function AuraMastery:OnFontColorUpdate()
	self.wndMain:FindChild("FontColorSample"):SetBGColor(self.selectedFontColor)
	self.wndMain:FindChild("FontSample"):SetTextColor(self.selectedFontColor)
end

