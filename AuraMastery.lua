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
AuraMastery.spriteIcons = {
	Tick = "icon_Tick",
	No = "icon_No",
	Crosshair = "icon_Crosshair",
	Flower = "icon_Flower",
	Fluer = "icon_Fluer",
	Heart = "icon_Heart",
	Lightning = "icon_Lightning",
	Paw = "icon_Paw",
	HexBladeLeft = "icon_HexBladeLeft"
}

local criticalTime = 5
local deflectTime = 4

local resourceIds = {}
resourceIds[GameLib.CodeEnumClass.Warrior] = 1
resourceIds[GameLib.CodeEnumClass.Engineer] = 1
resourceIds[GameLib.CodeEnumClass.Stalker] = 3
resourceIds[GameLib.CodeEnumClass.Esper] = 1
resourceIds[GameLib.CodeEnumClass.Spellslinger] = 4
resourceIds[GameLib.CodeEnumClass.Medic] = 1

local abilitiesList = nil
local function GetAbilitiesList()
	if abilitiesList == nil then
		abilitiesList = AbilityBook.GetAbilitiesList()
	end
	return abilitiesList
end

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
		Cooldown = {},
		OnCritical = {},
		OnDeflect = {},
		ActionSet = {},
		Resources = {}
	}
	self.BarLocked = true
	self.nextIconId = 1
	self.selectedColor = CColor.new(1,1,1,1)
	self.selectedFontColor = CColor.new(1,1,1,1)
	self.currentSampleNum = 0
	self.lastCritical = 0
	self.lastDeflect = 0
	self.Icons = {}
	
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
	self:OnSpecChanged(AbilityBook.GetCurrentSpec())
end

function AuraMastery:OnAbilityBookChange()
	abilitiesList = AbilityBook.GetAbilitiesList()
	for _, icon in pairs(self.Icons) do
		icon:UpdateDefaultIcon()
	end
end

function AuraMastery:OnDamageDealt(tData)
	if tData.unitCaster ~= nil and tData.unitCaster.IsThePlayer then
		if tData.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
			self.lastCritical = os.time()
		end
	end
end

function AuraMastery:OnMiss( unitCaster, unitTarget, eMissType )
	if unitTarget.IsThePlayer then
		if eMissType == GameLib.CodeEnumMissType.Dodge then
			self.lastDeflect = os.time()
		end
	end
end

function AuraMastery:OnCharacterCreated()
	self:OnSpecChanged(AbilityBook.GetCurrentSpec())
end

function AuraMastery:AddIcon()
	local newIcon = Icon.new(self.buffWatch, self.configForm)
	newIcon:SetScale(1)
	
	newIcon.iconId = self.nextIconId
	self.Icons[self.nextIconId] = newIcon
	self.nextIconId = self.nextIconId + 1
	
	return newIcon
end

-----------------------------------------------------------------------------------------------
-- AuraMastery OnLoad
-----------------------------------------------------------------------------------------------
function AuraMastery:OnLoad()
	Apollo.LoadSprites("Icons.xml")
	Apollo.RegisterEventHandler("AMLoadIcons", "OnLoadIcons", self)

	self.xmlDoc = XmlDoc.CreateFromFile("AuraMastery.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterEventHandler("AbilityBookChange", "OnAbilityBookChange", self)
	Apollo.RegisterEventHandler("CombatLogDamage", "OnDamageDealt", self)
	Apollo.RegisterEventHandler("AttackMissed", "OnMiss", self)
	Apollo.RegisterEventHandler("SpecChanged", "OnSpecChanged", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)

	Apollo.RegisterTimerHandler("AuraMastery_CacheTimer", "OnAbilityBookChange", self)
	Apollo.CreateTimer("AuraMastery_CacheTimer", 3, false)

	Apollo.RegisterTimerHandler("AuraMastery_BuffTimer", "OnUpdate", self)
	Apollo.CreateTimer("AuraMastery_BuffTimer", 0.1, true)
end

function AuraMastery:OnDocLoaded()
	if self.xmlDoc:IsLoaded() then
		GeminiPackages:Require("AuraMastery:Config", function(config)
			self.auraMasteryConfig = config
			Apollo.RegisterSlashCommand("am", "OnOpenConfig", self)
		end)		
	end
end

-----------------------------------------------------------------------------------------------
-- AuraMastery Functions
-----------------------------------------------------------------------------------------------
function AuraMastery:OnOpenConfig()
	self.config = self.auraMasteryConfig.new(self, self.xmlDoc)
end

function AuraMastery:GetSpellIconByName(spellName)
	local abilities = GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	return ""
end

function AuraMastery:OnUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()	
	local targetPlayer = GameLib.GetTargetUnit()

	for _, icon in pairs(self.Icons) do
		if icon.isEnabled then
			icon:PreUpdate()
		end
	end
	
	if unitPlayer ~= nil then
		self:ProcessBuffs(unitPlayer:GetBuffs(), "Player")
	end
	
	if targetPlayer ~= nil then
		self:ProcessBuffs(targetPlayer:GetBuffs(), "Target")
	end
	
	local abilities = GetAbilitiesList()
	if abilities then
		self:ProcessCooldowns(abilities)
	end

	self:ProcessOnCritical()
	self:ProcessOnDeflect()
	self:ProcessResources()
	
	--self:ProcessInnate()
	
	for _, icon in pairs(self.Icons) do
		if icon.isEnabled then
			icon:PostUpdate()
		end
	end
end

function AuraMastery:ProcessOnCritical()
	if os.difftime(os.time(), self.lastCritical) < criticalTime then
		for _, watcher in pairs(self.buffWatch["OnCritical"]) do
			watcher()
		end
	end
end

function AuraMastery:ProcessOnDeflect()
	if os.difftime(os.time(), self.lastDeflect) < deflectTime then
		for _, watcher in pairs(self.buffWatch["OnDeflect"]) do
			watcher()
		end
	end
end

function AuraMastery:ProcessResources()
	local playerUnit = GameLib.GetPlayerUnit()
	if playerUnit ~= nil then
		local resourceId = resourceIds[playerUnit:GetClassId()]

		local mana, maxMana, resource, maxResource = playerUnit:GetMana(), playerUnit:GetMaxMana(), playerUnit:GetResource(resourceId), playerUnit:GetMaxResource(resourceId)
		for _, watcher in pairs(self.buffWatch["Resources"]) do
			watcher({Mana = mana, MaxMana = maxMana, Resource = resource, MaxResource = maxResource})
		end
	end
end

function AuraMastery:ProcessBuffs(buffs, target)
	for idx, buff in pairs(buffs.arBeneficial) do
		if self.buffWatch["Buff"][target][buff.splEffect:GetName()] ~= nil then
			for _, watcher in pairs(self.buffWatch["Buff"][target][buff.splEffect:GetName()]) do
				watcher(buff)
			end
		end
	end
	
	for idx, buff in pairs(buffs.arHarmful) do
		if self.buffWatch["Debuff"][target][buff.splEffect:GetName()] ~= nil then
			for _, watcher in pairs(self.buffWatch["Debuff"][target][buff.splEffect:GetName()]) do
				watcher(buff)
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
					for _, watcher in pairs(self.buffWatch["Cooldown"][s:GetName()]) do
						watcher(s)
					end
				end
			end
		end
	end
end

function AuraMastery:ProcessInnate()
	--GameLib.GetClassInnateAbility()
	--unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
end

function AuraMastery:OnSpecChanged(newSpec)
	for _, icon in pairs(self.Icons) do
		icon:ChangeActionSet(newSpec)
	end

	for _, watcher in pairs(self.buffWatch["ActionSet"]) do
		watcher(newSpec)
	end
end

function AuraMastery:OnEnteredCombat(unit, inCombat)
	if unit:IsThePlayer() then
		for _, icon in pairs(self.Icons) do
			icon.isInCombat = inCombat
		end
	end
end

if _G["AuraMasteryLibs"] == nil then
	_G["AuraMasteryLibs"] = { }
end
_G["AuraMasteryLibs"]["GetAbilitiesList"] = GetAbilitiesList


-----------------------------------------------------------------------------------------------
-- AuraMastery Instance
-----------------------------------------------------------------------------------------------
AuraMasteryInst = AuraMastery:new()
AuraMasteryInst:Init()

---------------------------------------------------------------------------------------------------
-- TriggerDetails Functions
---------------------------------------------------------------------------------------------------
function AuraMastery:OnResourceStateToggle( wndHandler, wndControl, eMouseButton )
end

