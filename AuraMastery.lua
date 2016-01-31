-----------------------------------------------------------------------------------------------
-- Client Lua Script for AuraMastery
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ICCommLib"
require "ICComm"

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
	HexBladeLeft = "icon_HexBladeLeft",
	HexBlades = "icon_HexBlades",
	Round = "icon_Round",
	Circle = "icon_Circle",
	Boom = "icon_Boom",
	Boop = "icon_Boop",
	Bounce = "icon_Bounce",
	Go = "icon_Go",
	PraiseTheRngGods = "icon_PraiseTheRngGods",
	Surprise = "icon_Surprise",
	Swirl = "icon_Swirl",
	Block1 = "icon_Block1",
	Bla1 = "icon_Bla1",
	BoomHud = "icon_BoomHud",
	Butterflies = "icon_Butterflies",
	Charging1 = "icon_Charging1",
	Charging5 = "icon_Charging5",
	Esper2 = "icon_Esper2",
	EsperWhoosh = "icon_EsperWhoosh",
	Leafy1 = "icon_Leafy1",
	RadicalHeart = "icon_RadicalHeart",
	Stalker1 = "icon_Stalker1",
	Cogsbottom2 = "icon_cogshudbottom1",
	Fireball = "icon_fireball",
	Cogs1 = "icon_cogs1",
	Cogs2 = "icon_cogs2",
	Cogs3 = "icon_cogs3",
	Cogs4 = "icon_cogs4",
	Cogs5 = "icon_cogs5",
	Cogs6 = "icon_cogs6",
	Cogs7 = "icon_cogs7",
	Cogs8 = "icon_cogs8",
	Cogs9 = "icon_cogs9",
	Cogs10 = "icon_cogs10",
	Exclaim1 = "icon_exclaim1",
	Exclaim2 = "icon_exclaim2",
	Medic = "icon_medic1",
	Engineer = "icon_engineer1",
	Esper = "icon_esper1",
	Spellslinger = "icon_slinger1",
	Stalker1 = "icon_stalker1",
	Warrior = "icon_warrior1",
	Robot1 = "icon_glowthing1",
	Robot2 = "icon_glowthing2",
	Wave1 = "icon_wave1",
	Wave2 = "icon_wave2",
	Dominion = "icon_dominion1",
	Exile = "icon_exile1",
	Orb = "icon_orb1",
	Butterfly1 = "icon_butterfly1",
	Halo2 = "icon_halo2",
	Arcanehud1 = "icon_arcanehud1",
	Stroberight1 = "icon_stroberight1",
	Strobeleft1 = "icon_strobeleft1",
	Strobe1 = "icon_strobe1",
	Stormy = "icon_stormy1",
	Metalhudtop = "icon_metalhudtop1",
	Metalhudright = "icon_metalhudright1",
	Metalhudleft = "icon_metalhudleft1",
	Metalhudbottom = "icon_metalhudbottom1",
	Metalhud1 = "icon_metalhud1",
	Metalhud2 = "icon_metalhud2",
	Leaveshudtop1 = "icon_leaveshudtop1",
	Leaveshudright1 = "icon_leaveshudright1",
	Leaveshudright2 = "icon_leaveshudright2",
	Leaveshudleft1 = "icon_leaveshudleft1",
	Leaveshudleft2 = "icon_leaveshudleft2",
	Leaveshudbottom1 = "icon_leaveshudbottom1",
	Leaveshudbottom2 = "icon_leaveshudbottom2",
	Leaveshud1 = "icon_leaveshud1",
	Leaveshud4 = "icon_leaveshud4",
	Hudtop = "icon_hudtop1",
	Hudright = "icon_hudright1",
	Hudleft = "icon_hudleft1",
	Hudbottom = "icon_hudbottom1",
	Hud = "icon_hud1",
	Glowtriangletopright = "icon_glowtriangletopright",
	Glowtriangletopleft = "icon_glowtriangletopleft1",
	Glowtriangletop2 = "icon_glowtriangletop2",
	Glowtriangletright2 = "icon_glowtriangleright2",
	Glowtriangleright1 = "icon_glowtriangleright1",
	Glowtriangleleft2 = "icon_glowtriangleleft2",
	Glowtriangleleft1 = "icon_glowtriangleleft1",
	Glowtrianglebottomright = "icon_glowtrianglebottomright",
	Glowtrianglebottomleft = "icon_glowtrianglebottomleft",
	Glowtrianglebottom2 = "icon_glowtrianglebottom2",
	Glowtriangle1 = "icon_glowtriangle1",
	Glowtriangle2 = "icon_glowtriangle2",
	Flamehud1 = "icon_flamehud1",
	Flamehudtop = "icon_flamehudtop1",
	Flamehudbottom = "icon_flamehudbottom1",
	Flamehudright = "icon_flamehudright1",
	Flamehudleft = "icon_flamehudleft1",
	Featherhudtop = "icon_featherhudtop1",
	Featherhudright = "icon_featherhudright1",
	Featherhudleft = "icon_featherhudleft1",
	Featherhudbottom = "icon_featherhudbottom1",
	Featherhud2 = "icon_featherhud2",
	Curvetopright = "icon_curvetopright1",
	Curvetopleft = "icon_curvetopleft1",
	Curvetop = "icon_curvetop1",
	Curveright = "icon_curveright1",
	Curveleft = "icon_curveleft1",
	Curvehudtop4 = "icon_curvehudtop4",
	Curvehudtop3 = "icon_curvehudtop3",
	Curvehudtop2 = "icon_curvehudtop2",
	Curvehudtop1 = "icon_curvehudtop1",
	Curvehudright2 = "icon_curvehudright2",
	Curvehudright1 = "icon_curvehudright1",
	Curvehudleft2 = "icon_curvehudleft2",
	Curvehudleft1 = "icon_curvehudleft1",
	Curvehudbottom6 = "icon_curvehudbottom6",
	Curvehudbottom5 = "icon_curvehudbottom5",
	Curvehudbottom4 = "icon_curvehudbottom4",
	Curvehudbottom3 = "icon_curvehudbottom3",
	Curvehudbottom2 = "icon_curvehudbottom2",
	Curvehudbottom1 = "icon_curvehudbottom1",
	Curvehud1 = "icon_curvehud1",
	Curvehud2 = "icon_curvehud2",
	Curvehud3 = "icon_curvehud3",
	Curvehud5 = "icon_curvehud5",
	Curvehud6 = "icon_curvehud6",
	Curvehud8 = "icon_curvehud8",
	Curvehud9 = "icon_curvehud9",
	Curvehud10 = "icon_curvehud10",
	Curvebottomright1 = "icon_curvebottomright1",
	Curvebottomleft1 = "icon_curvebottomleft1",
	Curvebottom1 = "icon_curvebottom1",
	Cogshudtop2 = "icon_cogshudtop2",
	Cogshudtop1 = "icon_cogshudtop1",
	Cogshudright2 = "icon_cogshudright2",
	Cogshudright1 = "icon_cogshudright1",
	Cogshudleft2 = "icon_cogshudleft2",
	Cogshudleft1 = "icon_cogshudleft1",
	Cogshudbottom1 = "icon_cogshudbottom2",
	Cogshud3 = "icon_cogshud3",
	Cogshud1 = "icon_cogshud1",
	Charginghudtop1 = "icon_charginghudtop1",
	Charginghudright1 = "icon_charginghudright1",
	Charginghudleft1 = "icon_charginghudleft1",
	Charginghudbottom1 = "icon_charginghudbottom1",
	Charginghud2 = "icon_charginghud2",
	Arcanehudtop = "icon_arcanehudtop1",
	Arcanehudright = "icon_arcanehudright1",
	Arcanehudleft = "icon_arcanehudleft1",
	Arcanehudbottom = "icon_arcanehudbottom1",
	Arcanehud1 = "icon_arcanehud1",
	Leaveshudtop2 = "icon_leaveshudtop2",
	Esperright1 = "icon_esperright1",
	Esperleft1 = "icon_esperleft1",
	Hexbladeright1 = "icon_hexbladeright",
	Whooshright1 = "icon_whooshright1",
	Whooshleft1 = "icon_whooshleft1",
	Stalkerright1 = "icon_stalkerright1",
	Stalkerleft1 = "icon_stalkerleft1",
	Radicalheart2 = "icon_radicalheart2",
	Radicalheart3 = "icon_radicalheart3",
	Chargingsinglebar = "icon_charingsinglebar",
	Butterflyright1 = "icon_butterflyright1",
	Butterflyleft1 = "icon_butterflyleft1",
	Boom2 = "icon_boom2",
	Boom3 = "icon_boom3",
	Boom4 = "icon_boom4",
	Alien2 = "icon_Alien2",
	Block2 = "icon_block2",
	Question = "ClientSprites:QuestJewel_Incomplete_Yellow",
	Tick1 = "ClientSprites:QuestJewel_Accept",
	Exclaim3 = "ClientSprites:QuestJewel_Offer_Grey",
	Plus = "ClientSprites:sprItem_New",
	Exclaim4 = "ClientSprites:sprItem_NewQuest",
	Greentick = "Crafting_CoordSprites:sprCoord_Checkmark",
	Fire = "Crafting_RunecraftingSprites:sprRunecrafting_Fire",
	Leaf = "Crafting_RunecraftingSprites:sprRunecrafting_Earth",
	Rune = "Crafting_RunecraftingSprites:sprRunecrafting_Air",
	Sun = "Crafting_RunecraftingSprites:sprRunecrafting_Life",
	Bulb = "Crafting_RunecraftingSprites:sprRunecrafting_Logic",
	Drop = "Crafting_RunecraftingSprites:sprRunecrafting_Water",
	Orb2 = "CRB_ActionBarFrameSprites:sprResourceBar_DodgeFlashFullSolid",
	Man = "CRB_ActionBarFrameSprites:sprResourceBar_Sprint_RunIconBlue",
	Screen = "CRB_ActionBarIconSprites:sprAS_GCD_FillBase",
	Hamster = "CRB_Anim_Spinner:sprAnim_SpinnerLarge",
	Whee = "CRB_Anim_Spinner:sprAnim_SpinnerSmall",
	Wavey = "CRB_Anim_WaveRunner:CRB_Anim_WaveRunnerStretch",
	Halo3 = "CRB_DatachronSprites:sprDCPP_SolTmdMeter",
	Flies2 = "CRB_HUDAlerts:sprAlert_RotateAnim3",
	Nom = "CRB_Tradeskills:sprSchemArtImage",
	Shield = "PlayerPathContent_TEMP:spr_PathExpScavengerBG",
	Star1 = "PlayerPathContent_TEMP:spr_PathExpHint",
	Soldier = "PlayerPathContent_TEMP:spr_PathSol_MapIconBase",
	Deadman = "ClientSprites:Icon_TutorialMedium_UI_Tradeskill_TA_Materials_Collection",
	Warning = "CRB_CraftingSprites:sprCraft_BlockerSpecialPU",
	Halo4 = "CRB_DatachronSprites:sprDCPP_SolTmdMeterBack",
	World = "CRB_MegamapSprites:sprMap_IconCompletion_World",
	Mountain = "CRB_MegamapSprites:sprMap_IconCompletion_Zone",
	Potion = "IconSprites:Icon_CraftingUI_Item_Crafting_BottleWine",
	Heart = "IconSprites:Icon_CraftingUI_Item_Crafting_Stamina_Blue",
	Wizard = "IconSprites:Icon_CraftingUI_Item_Crafting_Magic_Blue",
	Lopp = "IconSprites:Icon_Guild_UI_Guild_Lopp",
	Injection = "IconSprites:Icon_ItemMisc_Medishot_InstantHeal",
	Injection2 = "IconSprites:Icon_ItemMisc_Medishot_AoEHeal",
	Squirg = "IconSprites:Icon_ItemMisc_UI_Item_SquirgHat",
	Brain ="IconSprites:Icon_Windows_UI_CRB_Attribute_Insight",
	Thumbup = "IconSprites:Icon_Windows_UI_CRB_Attribute_Moxie",
	DNA = "IconSprites:Icon_Windows_UI_CRB_Attribute_Technology",
	Skull3 = "IconSprites:Icon_Windows_UI_CRB_FieldStudy_Aggressive",
	Happymonster = "IconSprites:Icon_Windows_UI_CRB_FieldStudy_Playful"
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
			Target = {},
			TargetOfTarget = {},
			FocusTarget = {},
			FocusTargetTarget = {},
			Friendly = {},
			Hostile = {}
		},
		Debuff = {
			Player = {},
			Target = {},
			TargetOfTarget = {},
			FocusTarget = {},
			FocusTargetTarget = {},
			Friendly = {},
			Hostile = {}
		},
		Cooldown = {},
		OnCritical = {},
		OnDeflect = {},
		ActionSet = {},
		Resources = {},
		Health = {
			Player = {},
			Target = {}
		},
		MomentOfOpportunity = {
			Player = {},
			Target = {}
		},
		Keybind = {},
		LimitedActionSetChecker = {},
		Gadget = {}
	}
	self.BarLocked = true
	self.nextIconId = 1
	self.selectedColor = CColor.new(1,1,1,1)
	self.selectedFontColor = CColor.new(1,1,1,1)
	self.currentSampleNum = 0
	self.lastCritical = 0
	self.lastDeflect = 0
	self.Icons = {}
	self.IconGroups = {}
	GeminiPackages:Require("AuraMastery:IconGroup", function(IconGroup)
		local group = IconGroup.new()
		group.name = "Misc"
		table.insert(self.IconGroups, group)
	end)
	self.BotSpellIds = {}
	self.lastUpdateTime = os.clock()

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

	saveData.Icons = { }
	for idx, icon in pairs(self.Icons) do
		table.insert(saveData.Icons, icon:GetSaveData())
	end

	saveData.Groups = { }
	for idx, group in pairs(self.IconGroups) do
		table.insert(saveData.Groups, group:Save())
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
	GeminiPackages:Require("AuraMastery:IconGroup", function(IconGroup)
		if tData.Groups ~= nil then
			self.IconGroups = {}
			for _, group in pairs(tData.Groups) do
				local iconGroup = IconGroup.new()
				iconGroup:Load(group)
				table.insert(self.IconGroups, iconGroup)
			end
		end

		for idx, icon in pairs(tData["Icons"]) do
			local newIcon = self:AddIcon()
			newIcon:Load(icon)
		end
		self:OnSpecChanged(AbilityBook.GetCurrentSpec())
	end)
end

function AuraMastery:OnAbilityBookChange()
	Apollo.CreateTimer("AuraMastery_CacheTimer", 0.1, false)
end

function AuraMastery:UpdateAbilityBook()
	abilitiesList = AbilityBook.GetAbilitiesList()
	for _, icon in pairs(self.Icons) do
		icon:UpdateDefaultIcon()
	end
	self:OnLASChanged()
end

function AuraMastery:OnDamageDealt(tData)
	if tData.unitCaster ~= nil and tData.unitCaster == GameLib.GetPlayerUnit() then
		if not tData.bPeriodic and tData.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
			self.lastCritical = os.time()
		end
	end

	self:ProcessHealthEvent(tData.unitTarget)
end

function AuraMastery:OnFallDamageDealt(tData)
	self:ProcessHealthEvent(tData.unitCaster, tData.nDamageAmount)
end

function AuraMastery:OnHealingDealt(tData)
	self:ProcessHealthEvent(tData.unitTarget)
end

function AuraMastery:ProcessHealthEvent(unit, decrementedHealth)
	if unit ~= nil then
		decrementedHealth = decrementedHealth or 0
		local playerUnit = GameLib.GetPlayerUnit()

		if unit == playerUnit then
			self:ProcessHealth(unit, "Player", "Player", decrementedHealth)
		elseif unit == GameLib.GetTargetUnit() then
			self:ProcessHealth(unit, "Target", "Target", decrementedHealth)
		end

		if unit:GetDispositionTo(playerUnit) == Unit.CodeEnumDisposition.Friendly then
			self:ProcessHealth(unit, "Friendly", unit:GetId(), decrementedHealth)
		else
			self:ProcessHealth(unit, "Hostile", unit:GetId(), decrementedHealth)
		end
		self:ProcessHealth(unit, unit:GetName(), unit:GetId(), decrementedHealth)
	end
end

function AuraMastery:OnUnitDestroyed(unit)
	if unit:GetDispositionTo(playerUnit) == Unit.CodeEnumDisposition.Friendly then
		self:ProcessHealth(nil, "Friendly", unit:GetId())
	else
		self:ProcessHealth(nil, "Hostile", unit:GetId())
	end
end

function AuraMastery:OnMiss( unitCaster, unitTarget, eMissType )
	if unitTarget ~= nil and unitTarget == GameLib.GetPlayerUnit() then
		if eMissType == GameLib.CodeEnumMissType.Dodge then
			self.lastDeflect = os.time()
		end
	end
end

function AuraMastery:OnBuffAdded(unitTarget, data)
	self:ProcessBuffEvent(unitTarget, "Add", data)
end

function AuraMastery:OnBuffRemoved(unitTarget, data)
	self:ProcessBuffEvent(unitTarget, "Remove", data)
end

function AuraMastery:ProcessBuffEvent(unitTarget, action, data)
	if unitTarget == nil then
		return
	end

	local buffType = data.splEffect:IsBeneficial() and "Buff" or "Debuff"
	local spellId = tostring(data.splEffect:GetId())
	local spellName = data.splEffect:GetName()
	local playerUnit = GameLib:GetPlayerUnit()

	if unitTarget == playerUnit then
		self:ProcessBuff("Player", buffType, spellId, spellName, {
			unit = unitTarget,
			action = action,
			data = data
		})
	end

	local targetUnit = GameLib:GetTargetUnit()
	if targetUnit ~= nil then
		if unitTarget == targetUnit then
			self:ProcessBuff("Target", buffType, spellId, spellName, {
				unit = unitTarget,
				action = action,
				data = data
			})
		end

		if unitTarget == targetUnit:GetTarget() then
			self:ProcessBuff("TargetOfTarget", buffType, spellId, spellName, {
				unit = unitTarget,
				action = action,
				data = data
			})
		end
	end

	if unitTarget:GetDispositionTo(playerUnit) == Unit.CodeEnumDisposition.Friendly then
		self:ProcessBuff("Friendly", buffType, spellId, spellName, {
			unit = unitTarget,
			action = action,
			data = data
		})
	else
		self:ProcessBuff("Hostile", buffType, spellId, spellName, {
			unit = unitTarget,
			action = action,
			data = data
		})
	end

	if self.unitFocus ~= nil then
		if self.unitFocus == unitTarget then
			self:ProcessBuff("FocusTarget", buffType, spellId, spellName, {
				unit = unitTarget,
				action = action,
				data = data
			})
		end

		-- local focusTargetTarget = self.unitFocus:GetTarget()
		-- if focusTargetTarget ~= nil then
		-- 	self:ProcessBuff("FocusTargetTarget", buffType, spellName, {
		-- 		unit = focusTargetTarget,
		-- 		action = action,
		-- 		data = data
		-- 	})
		-- end
	end

	self:ProcessBuff(unitTarget:GetName(), buffType, spellId, spellName, {
		unit = unitTarget,
		action = action,
		data = data
	})

	--if not self.isInRaid then return end


end

function AuraMastery:ProcessBuff(target, buffType, spellId, spellName, payload)
	if self.buffWatch[buffType][target] == nil then return end

	if self.buffWatch[buffType][target][spellId] ~= nil then
		for _, watcher in pairs(self.buffWatch[buffType][target][spellId]) do
			watcher(payload)
		end
	end

	if self.buffWatch[buffType][target][spellName] ~= nil then
		for _, watcher in pairs(self.buffWatch[buffType][target][spellName]) do
			watcher(payload)
		end
	end
end

function AuraMastery:OnTargetChanged(unit)
	local lastTarget = self.target
	self.target = unit
	self:ReloadBuffsForUnit("Target", self.target, lastTarget)
	self:ProcessHealth(nil, "Target", "Target")
	self:ProcessHealth(unit, "Target", "Target")
end

function AuraMastery:OnAlternateTargetUnitChanged(unit)
	local lastFocus = self.unitFocus
	self.unitFocus = unit
	self:ReloadBuffsForUnit("FocusTarget", unit, lastFocus)
	--self:ReloadBuffsForUnit(self.unitFocus:GetTarget(), "FocusTargetTarget")
end

function AuraMastery:ReloadBuffsForUnit(target, unit, lastUnit)
	self:RemoveBuffs("Buff", lastUnit, target)
	self:RemoveBuffs("Debuff", lastUnit, target)

	if unit ~= nil then
		local buffs = unit:GetBuffs()
		self:ReloadBuffLists("Buff", target, unit, buffs.arBeneficial)
		self:ReloadBuffLists("Debuff", target, unit, buffs.arHarmful)
	end
end

function AuraMastery:RemoveBuffs(buffType, unit, target)
	if unit ~= nil then
		for name, spellList in pairs(self.buffWatch[buffType][target]) do
			for _, watcher in pairs(spellList) do
				watcher({ action = "Remove", unit = unit })
			end
		end
	end
end

function AuraMastery:ReloadBuffLists(buffType, target, unit, buffs)
	if buffs then
		for idx, buff in pairs(buffs) do
			if self.buffWatch[buffType][target][buff.splEffect:GetName()] ~= nil then
				for _, watcher in pairs(self.buffWatch[buffType][target][buff.splEffect:GetName()]) do
					watcher({ action = "Add", unit = unit, data = buff })
				end
			end
		end
	end
end

function AuraMastery:OnCharacterCreated()
	self:OnSpecChanged(AbilityBook.GetCurrentSpec())
	self:UpdateAbilityBook()

	local player = GameLib.GetPlayerUnit()
	self:ReloadBuffsForUnit("Player", player)
	self:OnTargetChanged(player:GetTarget())
	self:OnAlternateTargetUnitChanged(player:GetAlternateTarget())
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
	Apollo.RegisterEventHandler("CombatLogFallingDamage", "OnFallDamageDealt", self)
	Apollo.RegisterEventHandler("CombatLogHeal", "OnHealingDealt", self)
	Apollo.RegisterEventHandler("AttackMissed", "OnMiss", self)
	Apollo.RegisterEventHandler("SpecChanged", "OnSpecChanged", self)
	Apollo.RegisterEventHandler("SystemKeyDown", 	"OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("MouseButtonDown", 	"OnMouseButtonDown", self)

	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("Group_Join", "OnGroupChange", self)
	Apollo.RegisterEventHandler("Group_Left", "OnGroupChange", self)
	Apollo.RegisterEventHandler("Group_Add", "OnGroupChange", self)
	Apollo.RegisterEventHandler("Group_Remove", "OnGroupChange", self)
	Apollo.RegisterEventHandler("Group_Disbanded", "OnGroupChange", self)
	Apollo.RegisterEventHandler("Group_FlagsChanged", "OnGroupChange", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", "OnUnitPvpFlagsChanged", self)

	Apollo.RegisterEventHandler("BuffAdded", "OnBuffAdded", self)
	Apollo.RegisterEventHandler("BuffUpdated", "OnBuffAdded", self)
	Apollo.RegisterEventHandler("BuffRemoved", "OnBuffRemoved", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)

	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)

	Apollo.RegisterTimerHandler("AuraMastery_ShareChannelConnect", "ShareChannelConnect", self)
	Apollo.RegisterTimerHandler("AuraMastery_CacheTimer", "UpdateAbilityBook", self)
	self:OnAbilityBookChange()
	self:LoadBotSpellIds()

	Apollo.RegisterTimerHandler("AuraMastery_BuffTimer", "OnUpdate", self)
	Apollo.CreateTimer("AuraMastery_BuffTimer", 0.1, true)

	--self:ShareChannelConnect()

	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnCharacterCreated(unitPlayer)
	end
end

function AuraMastery:ShareChannelConnect()
	if not self.shareChannel then
		self.shareChannel = ICCommLib.JoinChannel("AMShare2", ICCommLib.CodeEnumICCommChannelType.Global)
	end

	if self.shareChannel:IsReady() then
        self.shareChannel:SetReceivedMessageFunction("OnSharingMessageReceived", self)
		return true
    else
		Print("[AuraMastery] Connection failed")
    	Apollo.CreateTimer("AuraMastery_ShareChannelConnect", 1, false)
		return false
    end
end

function AuraMastery:LoadBotSpellIds()
	-- Smokeskin: Find all the botspells and match them to icons (there are spells with the same name but different icon and they cause bugs)
	-- this array of spell names and their icon is the only place actual values need to be entered
	local BotSpellIcons = {
		["[Bot Ability] Barrage"] =  "Icon_SkillEngineer_Pet_Ability_Barrage",
		["[Bot Ability] Blitz"] =  "Icon_SkillEngineer_Pet_Ability_Blitz",
		["[Bot Ability] Shield Boost"] =  "ClientSprites:Icon_SkillEngineer_Pet_Ability_Shield_Restore",
		["[Bot Ability] Strobe"] =  "Icon_SkillEngineer_Pet_Ability_Strobe",

			--Assault
		["Wild Barrage"] = "Icon_SkillSpellslinger_wild_barrage",
		["Charged Shot"] = "Icon_SkillSpellslinger_charged_shot",
		["Chill"] = "Icon_SkillSpellslinger_cone_of_frost",
		["Rapid Fire"] = "Icon_SkillSpellslinger_rapid_fire",
		["Arcane Missiles"] = "Icon_SkillSpellslinger_magic_missile",
		["True Shot"] = "Icon_SkillSpellslinger_Trueshot",
		["Flame Burst"] = "Icon_SkillSpellslinger_flame_burst",
			--Support
		["Runes of Protection"] = "Icon_SkillSpellslinger_distortion",
		["Vitality Burst"] = "Icon_SkillSpellslinger_vitality_burst",
		["Astral Infusion"] = "Icon_SkillSpellslinger_arcane_infusion",
		["Dual Fire"] = "Icon_SkillSpellslinger_dual_fire",
		["Voidspring"] = "Icon_SkillSpellslinger_call_the_void",
		["Regenerative Pulse"] = "Icon_SkillSpellslinger_regenerative_pulse",
		["Sustain"] = "Icon_SkillSpellslinger_sustain",
		["Healing Salve"] = "Icon_SkillSpellslinger_healing_salve",
		["Healing Torrent"] = "Icon_SkillSpellslinger_healing_torrent",
	}

	for tName, _ in pairs(BotSpellIcons) do
		self.BotSpellIds[tName] = {}
	end

	for i = 1, 99999, 1 do
		tSpell = GameLib.GetSpell(i)
		tName = tSpell:GetName()
		tIcon =  tSpell:GetIcon()

		for bName, bIcon in pairs(BotSpellIcons) do
			if bName == tName and bIcon == tIcon then
				table.insert(self.BotSpellIds[bName], i)
			end
		end
	end
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
	if self.config == nil then
		self.config = self.auraMasteryConfig.new(self, self.xmlDoc)
	end
	self.config:Show()
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

function AuraMastery:GetSpellByName(spellName)
	local matches = {}
	local abilities = GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				table.insert(matches, ability)
			end
		end
	end
	return matches
end

function AuraMastery:OnUpdate()
	local currentTime = os.clock()
	local deltaTime = currentTime - self.lastUpdateTime
	self.lastUpdateTime = currentTime

	local unitPlayer = GameLib.GetPlayerUnit()
	local targetPlayer = GameLib.GetTargetUnit()

	for _, icon in pairs(self.Icons) do
		if icon.isEnabled then
			icon:PreUpdate(deltaTime)
		end
	end

	if unitPlayer ~= nil then
		self:ProcessMOO(unitPlayer, "Player")
	end

	if targetPlayer ~= nil then
		self:ProcessMOO(targetPlayer, "Target")
	end

	local abilities = GetAbilitiesList()
	if abilities then
		self:ProcessCooldowns(abilities)
	end
	self:ProcessPetSpells()

	self:ProcessOnCritical()
	self:ProcessOnDeflect()
	self:ProcessResources()
	self:ProcessGadget()

	self:ProcessInnate()

	for _, icon in pairs(self.Icons) do
		if icon.isEnabled then
			icon:PostUpdate()
		end
	end
end

local function TableContainsElements(table)
	for _,_ in pairs(table) do
		return true
	end
	return false
end

function AuraMastery:ProcessMOO(unit, target)
	if self.buffWatch["MomentOfOpportunity"][target] ~= nil and TableContainsElements(self.buffWatch["MomentOfOpportunity"][target]) then
		local timeRemaining = unit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
		local result = { TimeRemaining = timeRemaining }
		for _, watcher in pairs(self.buffWatch["MomentOfOpportunity"][target]) do
			watcher(result)
		end
	end
end

function AuraMastery:ProcessOnCritical()
	if TableContainsElements(self.buffWatch["OnCritical"]) then
		if os.difftime(os.time(), self.lastCritical) < criticalTime then
			for _, watcher in pairs(self.buffWatch["OnCritical"]) do
				watcher()
			end
		end
	end
end

function AuraMastery:ProcessOnDeflect()
	if TableContainsElements(self.buffWatch["OnDeflect"]) then
		if os.difftime(os.time(), self.lastDeflect) < deflectTime then
			for _, watcher in pairs(self.buffWatch["OnDeflect"]) do
				watcher()
			end
		end
	end
end

function AuraMastery:ProcessResources()
	if TableContainsElements(self.buffWatch["Resources"]) then
		local playerUnit = GameLib.GetPlayerUnit()
		if playerUnit ~= nil then
			local resourceId = resourceIds[playerUnit:GetClassId()]

			local mana, maxMana, resource, maxResource = playerUnit:GetFocus(), playerUnit:GetMaxFocus(), playerUnit:GetResource(resourceId), playerUnit:GetMaxResource(resourceId)
			for _, watcher in pairs(self.buffWatch["Resources"]) do
				watcher({Mana = mana, MaxMana = maxMana, Resource = resource, MaxResource = maxResource})
			end
		end
	end
end

function AuraMastery:ProcessHealth(unit, target, id, decrementedHealth)
	if self.buffWatch["Health"][target] ~= nil and TableContainsElements(self.buffWatch["Health"][target]) then
		if unit ~= nil and unit:GetHealth() ~= nil then
			local result = { Action = "Update", Id = id, Unit = unit, Health = unit:GetHealth() - (decrementedHealth or 0), MaxHealth = unit:GetMaxHealth(), Shield = unit:GetShieldCapacity(), MaxShield = unit:GetShieldCapacityMax() }
			for _, watcher in pairs(self.buffWatch["Health"][target]) do
				watcher(result)
			end
		else
			local result = { Action = "Remove", Id = id }
			for _, watcher in pairs(self.buffWatch["Health"][target]) do
				watcher(result)
			end
		end
	end
end

function AuraMastery:ProcessCooldowns(abilities)
	if TableContainsElements(self.buffWatch["Cooldown"]) then
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
end

function AuraMastery:ProcessGadget()
	if TableContainsElements(self.buffWatch["Gadget"]) then
		local gadgetSpell = GameLib.GetGadgetAbility()
		if gadgetSpell ~= nil then
			for _, watcher in pairs(self.buffWatch["Gadget"]) do
				watcher(gadgetSpell)
			end
		end
	end
end

function AuraMastery:ProcessPetSpell(spellId)
	local spell = GameLib.GetSpell(spellId)
	for _, watcher in pairs(self.buffWatch["Cooldown"][spell:GetName()]) do
		watcher(spell)
	end
end

function AuraMastery:ProcessPetSpells()
	if TableContainsElements(self.buffWatch["Cooldown"]) then
		-- Smokeskin: Check if a botspell is on the buffwatch, and if so add all its IDs to watcher
		for bName, Ids in pairs(self.BotSpellIds) do
			if self.buffWatch["Cooldown"][bName] ~= nil then
				for ind, BotSpellId in pairs(Ids) do
					local BotSpell = GameLib.GetSpell(BotSpellId)
					for _, watcher in pairs(self.buffWatch["Cooldown"][bName]) do
						watcher(BotSpell)
					end
				end
			end
		end
	end
end

function AuraMastery:ProcessInnate()
	if TableContainsElements(self.buffWatch["Cooldown"]) then
		for i = 1, GameLib.GetClassInnateAbilitySpells().nSpellCount * 2, 2 do
			local s = GameLib.GetClassInnateAbilitySpells().tSpells[i]
			if self.buffWatch["Cooldown"][s:GetName()] ~= nil then
				for _, watcher in pairs(self.buffWatch["Cooldown"][s:GetName()]) do
					watcher(s)
				end
			end
		end
	end
end

function AuraMastery:OnSystemKeyDown(iKey)
	if TableContainsElements(self.buffWatch["Keybind"]) then
		if self.buffWatch["Keybind"][iKey] ~= nil then
			for _, watcher in pairs(self.buffWatch["Keybind"][iKey]) do
				watcher(iKey)
			end
		end
	end
end

function AuraMastery:OnMouseButtonDown(mouseButton)
	if TableContainsElements(self.buffWatch["Keybind"]) then
		if self.buffWatch["Keybind"]["MB:" .. mouseButton] ~= nil then
			for _, watcher in pairs(self.buffWatch["Keybind"]["MB:" .. mouseButton]) do
				watcher(mouseButton)
			end
		end
	end
end

function AuraMastery:OnSpecChanged(newSpec)
	for _, icon in pairs(self.Icons) do
		icon:ChangeActionSet(newSpec)
	end

	for _, watcher in pairs(self.buffWatch["ActionSet"]) do
		watcher(newSpec)
	end
end

function AuraMastery:OnLASChanged()
	local lasSpellIds = ActionSetLib.GetCurrentActionSet()
    if lasSpellIds then
    	local lasSpellNames = {}
    	for _, spellId in pairs(lasSpellIds) do
	    	if spellId ~= 0 then
	    		for _, ability in pairs(GetAbilitiesList()) do
	    			if ability.nId == spellId then
	    				lasSpellNames[ability.strName] = true
	    				break
	    			end
	    		end
	    	end
    	end

		for spellName, watchList in pairs(self.buffWatch["LimitedActionSetChecker"]) do
			for _, watcher in pairs(watchList) do
				watcher(lasSpellNames[spellName] == true)
			end
		end
	end
end

function AuraMastery:OnEnteredCombat(unit, inCombat)
	if unit:IsThePlayer() then
		for _, icon in pairs(self.Icons) do
			icon.isInCombat = inCombat
		end
	end
end

function AuraMastery:OnGroupChange()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil then
		local isInGroup, isInRaid = GroupLib.InGroup(unitPlayer:GetName()), GroupLib.InRaid(unitPlayer:GetName())
		for _, icon in pairs(self.Icons) do
			icon.isInGroup = isInGroup
			icon.isInRaid = isInRaid
		end
	end
end

function AuraMastery:OnUnitPvpFlagsChanged(unit)
	if unit:IsThePlayer() then
		local isPvpFlagged = GameLib.IsPvpFlagged()
		for _, icon in pairs(self.Icons) do
			icon.isPvpFlagged = isPvpFlagged
		end
	end
end

function AuraMastery:OnSharingMessageReceived(chan, msg)
	if self.sharingCallback == nil then return end
	msg = AuraMastery.DeserializeString(msg)
	if msg.DestinationType == "player" then
		local playerUnit = GameLib.GetPlayerUnit()
		if playerUnit ~= nil and msg.Destination == playerUnit:GetName() then
			self.sharingCallback(chan, msg)
		end
	elseif msg.DestinationType == "group" and GroupLib.GetMemberCount() > 0 then
		for i = 1, GroupLib.GetMemberCount() do
			if GroupLib.GetGroupMember(i).strCharacterName == msg.Sender then
				self.sharingCallback(chan, msg)
			end
		end
	elseif msg.DestinationType == "guild" then

	end
end

function AuraMastery.DeserializeString(string)
  local iconScript, loadStringError = loadstring("return " .. string)
  if iconScript then
    local status, result = pcall(iconScript)
    if status then
      if result ~= nil then
        return result
      else
        Print("Failed to import icon. Data deserialized but was invalid.")
      end
    else
      Print("Failed to import icon, invalid load data: " .. tostring(result))
    end
  else
    Print("Failed to import icon, invalid load data: " .. tostring(loadStringError))
  end
end

function AuraMastery:SendCommsMessageToPlayer(player, msg)
	if self:ShareChannelConnect() then
		msg.Destination = player
		msg.Sender = GameLib.GetPlayerUnit():GetName()
		msg.DestinationType = "player"
		self.shareChannel:SendMessage(self.config:Serialize(msg))
	end
end

function AuraMastery:SendCommsMessageToGroup(msg)
	if self:ShareChannelConnect() then
		msg.Destination = ""
		msg.Sender = GameLib.GetPlayerUnit():GetName()
		msg.DestinationType = "group"
		self.shareChannel:SendMessage(self.config:Serialize(msg))
		self:OnSharingMessageReceived("AM", self.config:Serialize(msg))
	end
end

function AuraMastery:SendCommsMessageToGuild(guild, msg)
	msg.Destination = {
		Name = guild:GetName(),
		Type = guild:GetType()
	}
	msg.Sender = GameLib.GetPlayerUnit():GetName()
	msg.DestinationType = "guild"
	self.shareChannel:SendMessage(self.config:Serialize(msg))
end

if _G["AuraMasteryLibs"] == nil then
	_G["AuraMasteryLibs"] = { }
end
_G["AuraMasteryLibs"]["GetAbilitiesList"] = GetAbilitiesList

-----------------------------------------------------------------------------------------------
-- AuraMastery Instance
-----------------------------------------------------------------------------------------------
local AuraMasteryInst = AuraMastery:new()
AuraMasteryInst:Init()

return AuraMastery
