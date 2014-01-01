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
-- e.g. local kiExampleVariableMax = 999

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
	saveData["BarPosition"] = { }
	saveData["BarPosition"][1], saveData["BarPosition"][2], saveData["BarPosition"][3], saveData["BarPosition"][4] = self.iconForm:GetAnchorOffsets()
	saveData["BarSize"] = self.iconForm:GetScale()
	
	saveData["Icons"] = { }
	Print("Saving Icons")
	for idx, icon in pairs(self.Icons) do
		saveData["Icons"][idx] = icon:GetSaveData()
	end
	
	return saveData
end

function AuraMastery:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end
	
	self.IconData = tData["Icons"]
	for idx, icon in pairs(tData["Icons"]) do
		self.Icons[idx]:Load(icon)
	end
	
	if tData["BarPosition"] ~= nil then
		self.iconForm:SetAnchorOffsets(tData["BarPosition"][1], tData["BarPosition"][2], tData["BarPosition"][3], tData["BarPosition"][4])
	end
	
	if tData["BarSize"] then
		self.iconForm:SetScale(tData["BarSize"])
		self.wndMain:FindChild("BarResize"):SetValue(tData["BarSize"])
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
    
    -- load our forms
    self.wndMain = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm", nil, self)
    self.wndMain:Show(false)
	
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

	self.iconForm = Apollo.LoadForm("AuraMastery.xml", "IconForm", nil, self)
	
	Apollo.RegisterTimerHandler("AuraMastery_BuffTimer", "OnUpdate", self)
	Apollo.CreateTimer("AuraMastery_BuffTimer", 0.1, true)
	
	
	self.Icons = {}
	if self.IconData == nil then
		self.IconData = { }
	end
	
	for i = 1, 4 do
		self.Icons[i] = Icon.new(self.buffWatch, self.iconForm, self.IconData[i], i)
	end    
		
	self:CreateControls()
	
	self:SelectFirstIcon()
end

function AuraMastery:CreateControls()
	local iconList = self.wndMain:FindChild("IconList"):FindChild("ListWindow")
	for i, icon in pairs(self.Icons) do
		local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
		iconItem:SetAnchorOffsets(0, (i-1) * 40, 500, (i-1) * 40 + 40)
		iconItem:FindChild("Id"):SetText(i)
		iconItem:FindChild("Label"):SetText(icon:GetName())
		local left, top, right, bottom = iconList:GetAnchorOffsets()
		iconList:SetAnchorOffsets(left, top, right, bottom + 50)
	end
end

function AuraMastery:UpdateControls()
	for _, iconItem in pairs(self.wndMain:FindChild("IconList"):FindChild("ListWindow"):GetChildren()) do
		iconItem:FindChild("Label"):SetText(self.Icons[tonumber(iconItem:FindChild("Id"):GetText())]:GetName())
	end
end

function AuraMastery:SelectFirstIcon()
	local firstIconItem = self.wndMain:FindChild("IconList"):FindChild("ListWindow"):GetChildren()[1]
	if firstIconItem ~= nil then
		self:SelectIcon(firstIconItem)
	end
end

-----------------------------------------------------------------------------------------------
-- AuraMastery Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/am"
function AuraMastery:OnAuraMasteryOn()
	self.wndMain:Show(true) -- show the window
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
	
	local abilities = AbilityBook.GetAbilitiesList() -- scan ability book for spells on cooldown
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

function AuraMastery:OnResize( wndHandler, wndControl, fNewValue, fOldValue )
	self.iconForm:SetScale(fNewValue)
end

function AuraMastery:OnToggleBarLock()
	if not self.BarLocked then
		self.iconForm:SetStyle("Moveable", false)
		self.iconForm:SetBGColor(ApolloColor.new(0, 1, 1, 0))
		self.wndMain:FindChild("UnlockBarButton"):SetText("Unlock Bar")
		self.BarLocked = true
	else
		self.iconForm:SetStyle("Moveable", true)
		self.iconForm:SetBGColor(ApolloColor.new(1, 1, 0, 1))
		self.wndMain:FindChild("UnlockBarButton"):SetText("Lock Bar")
		self.BarLocked = false
	end
end

function AuraMastery:OnSoundPlay( wndHandler, wndControl, eMouseButton )
	local soundNo = tonumber(self.wndMain:FindChild("SoundNo"):GetText())
	Sound.Play(soundNo)
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
		self.wndMain:FindChild("BuffBackgroundShown"):SetCheck(icon.iconBackground)
		
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
	end
end

-----------------------------------------------------------------------------------------------
-- AuraMastery Instance
-----------------------------------------------------------------------------------------------
AuraMasteryInst = AuraMastery:new()
AuraMasteryInst:Init()


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

