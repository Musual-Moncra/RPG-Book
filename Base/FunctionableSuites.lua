--[[
	Enchant Library  (FunctionableSuites.lua)
	------------------------------------------
	Central dispatcher for ALL enchant logic.

	ARCHITECTURE:
	  • Weapon enchants (Tool / Spell):
	      DamageLib calls  EnchantLib.OnHit(Player, Tool, MobInstance)
	        after every real (non-Ignore) hit.
	      Damage / Stun modifiers are applied inside DamageLib via the
	        DamageModifiers callback folder — see Enchant.lua under Damage/.

	  • Armor enchants (Armor):
	      ArmorLib calls  EnchantLib.OnArmorEquipped(Player, Humanoid, itemName, level)
	        when the player equips armor, and
	        EnchantLib.OnArmorUnequipped(Player, Humanoid, itemName)
	        when they unequip it.

	  • Accessory enchants (Accessory):
	      AccessoryLib calls  EnchantLib.OnAccessoryEquipped(Player, Humanoid, itemName, level, index)
	        when an accessory slot is filled, and
	        EnchantLib.OnAccessoryUnequipped(Player, Humanoid, itemName, index)
	        when it is emptied.

	Suite modules:
	  • script.Suites           → EnchantsSuites.lua       (weapon on-hit suites)
	  • script.WeaponSuites      → ArmorEnchantSuites.lua   (armor/accessory suites)

	Suite names must match Suite[1] in GameConfig.EnchantConfig.Enchants.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

--> Dependencies
local GameConfig    = require(ReplicatedStorage.GameConfig)
local WeaponSuites  = require(script.Suites)  -- EnchantsSuites.lua (weapon + armor + accessory suites)
-- NOTE: ArmorEnchantSuites.lua is no longer needed; all suites are in script.Suites.

--> Variables
local EnchantLib = {}

local EC = GameConfig.EnchantConfig -- shorthand, read-only

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

-- Read all Enchant_<Name> = <Level> attributes from a physical Tool.
local function GetWeaponEnchants(Tool): {[string]: number}
	local result = {}
	for attr, val in Tool:GetAttributes() do
		local name = attr:match("^Enchant_(.+)$")
		if name then result[name] = val end
	end
	return result
end

-- Resolve per-level stats for a named enchant at a given level.
-- Returns a flat { StatName = {op, value} } table, or nil if no stats defined.
local function ResolveStats(data, level: number)
	if not data then return nil end

	if data.PerLevelStats then
		-- AUTO mode: accumulate each stat up to `level`
		local stats = {}
		for statName, op in data.PerLevelStats do
			local opType, val = op[1], op[2]
			if opType == "Multiply" then
				-- e.g. ×1.08 per level → final = 1 + (0.08 × level)
				stats[statName] = { opType, 1 + (val - 1) * level }
			elseif opType == "Add" then
				stats[statName] = { opType, val * level }
			end
		end
		return stats

	elseif data.Levels then
		-- MANUAL mode: exact entry for this level
		local entry = data.Levels[level]
		-- Support both { Damage={...} } and legacy { Stats={ Damage={...} } }
		return entry and (entry.Stats or entry)
	end

	return nil
end

-- Dispatch a suite function by name, trying WeaponSuites first, then WeaponSuites.
local function DispatchSuite(suiteName: string, ...)
	local fn = WeaponSuites[suiteName] or WeaponSuites[suiteName]
	if fn then
		task.spawn(fn, fn, ...)  -- pass the module table as self
	else
		warn(("[EnchantLib] Suite function '%s' not found in either Suites module."):format(suiteName))
	end
end

--------------------------------------------------------------------------------
-- Weapon enchant damage / stun modifiers
-- (These are called from the DamageModifiers folder module, not directly)
--------------------------------------------------------------------------------

--- Apply enchant Damage stat modifiers to a base damage value.
--- Called by the Enchants DamageModifier module in script.Damage/.
function EnchantLib.ApplyDamage(Tool, Damage: number): number
	if not EC or not EC.Enchants then return Damage end

	for enchantName, level in GetWeaponEnchants(Tool) do
		local data  = EC.Enchants[enchantName]
		local stats = ResolveStats(data, level)
		if stats and stats.Damage then
			local opType, val = stats.Damage[1], stats.Damage[2]
			if opType == "Multiply" then
				Damage = Damage * val
			elseif opType == "Add" then
				Damage = Damage + val
			end
		end
	end

	return Damage
end

--- Apply enchant Stun stat modifiers.
--- Called by the Enchants DamageModifier module if a stun modifier is needed.
function EnchantLib.ApplyStun(Tool, Stun): number?
	if not EC or not EC.Enchants then return Stun end

	for enchantName, level in GetWeaponEnchants(Tool) do
		local data  = EC.Enchants[enchantName]
		local stats = ResolveStats(data, level)
		if stats and stats.Stun then
			local opType, val = stats.Stun[1], stats.Stun[2]
			local current = Stun or 0
			if opType == "Add" then
				Stun = current + val
			elseif opType == "Multiply" then
				Stun = current > 0 and current * val or current
			end
		end
	end

	return Stun
end

--- Apply enchant CritChance stat modifiers.
--- CritChance is a {roll, outOf} pair. "Add" reduces outOf (easier to crit).
function EnchantLib.ApplyCritChance(Tool, CritChance)
	if not EC or not EC.Enchants then return CritChance end

	for enchantName, level in GetWeaponEnchants(Tool) do
		local data  = EC.Enchants[enchantName]
		local stats = ResolveStats(data, level)
		if stats and stats.CritChance then
			local opType, val = stats.CritChance[1], stats.CritChance[2]
			if opType == "Add" then
				CritChance = { CritChance[1], math.max(CritChance[1], CritChance[2] - val) }
			end
		end
	end

	return CritChance
end

--- Apply enchant KnockbackForce modifiers.
function EnchantLib.ApplyKnockback(Tool, Knockback)
	if not Knockback or not EC or not EC.Enchants then return Knockback end

	for enchantName, level in GetWeaponEnchants(Tool) do
		local data  = EC.Enchants[enchantName]
		local stats = ResolveStats(data, level)
		if stats and stats.KnockbackForce then
			local opType, val = stats.KnockbackForce[1], stats.KnockbackForce[2]
			if opType == "Multiply" then
				Knockback = Knockback * val
			elseif opType == "Add" then
				Knockback = Knockback + val
			end
		end
	end

	return Knockback
end

--------------------------------------------------------------------------------
-- Weapon on-hit dispatch
-- Called by DamageLib:DamageMob after every real (non-Ignore) hit.
--------------------------------------------------------------------------------

function EnchantLib.OnHit(Player: Player, Tool, MobInstance: Model)
	if not EC or not EC.Enchants then return end

	for enchantName, level in GetWeaponEnchants(Tool) do
		local data = EC.Enchants[enchantName]
		if not data or not data.Suite then continue end

		-- Only dispatch if this enchant is valid for Tool/Spell (weapon on-hit)
		local vt = data.ValidTypes
		if not (vt and (vt.Tool or vt.Spell)) then continue end

		local suiteName  = data.Suite[1]
		local properties = data.Suite[2]

		-- Per-item custom property overrides (stored as JSON attribute on tool)
		local propsAttr = Tool:GetAttribute("EnchantProps_" .. enchantName)
		if propsAttr then
			local HttpService = game:GetService("HttpService")
			local ok, customProps = pcall(HttpService.JSONDecode, HttpService, propsAttr)
			if ok and type(customProps) == "table" then
				local merged = {}
				for k, v in properties do merged[k] = v end
				for k, v in customProps  do merged[k] = v end
				properties = merged
			end
		end

		local fn = WeaponSuites[suiteName]
		if fn then
			task.spawn(fn, WeaponSuites, Player, Tool, MobInstance, level, properties)
		else
			-- Fallback: check WeaponSuites for cross-type suites (e.g. Manaflow on accessory)
			local fn2 = WeaponSuites[suiteName]
			if fn2 then
				task.spawn(fn2, WeaponSuites, Player, Tool, MobInstance, level, properties)
			else
				warn(("[EnchantLib] OnHit: suite '%s' not found."):format(suiteName))
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Armor enchant dispatch
-- Called by ArmorLib when armor is equipped / unequipped.
--------------------------------------------------------------------------------

--- Called when a player equips an armor piece.
--- Reads enchants stored as attributes on the pData armor NumberValue.
--- Attribute format:  Enchant_<Name> = <Level>  (same as weapon tools).
---
--- @param Player    Player
--- @param Humanoid  Humanoid  — the player's Humanoid
--- @param itemName  string    — e.g. "Bronze Armor"
--- @param armorValue Instance — the pData NumberValue for this armor item
function EnchantLib.OnArmorEquipped(Player: Player, Humanoid, itemName: string, armorValue)
	if not EC or not EC.Enchants then return end
	if not armorValue then return end

	for attr, level in armorValue:GetAttributes() do
		local enchantName = attr:match("^Enchant_(.+)$")
		if not enchantName then continue end

		local data = EC.Enchants[enchantName]
		if not data or not data.Suite then continue end

		local vt = data.ValidTypes
		if not (vt and vt.Armor) then continue end

		local suiteName  = data.Suite[1]
		local properties = data.Suite[2]

		local fn = WeaponSuites[suiteName]
		if fn then
			task.spawn(fn, WeaponSuites, Player, nil, level, properties)
		else
			warn(("[EnchantLib] OnArmorEquipped: suite '%s' not found."):format(suiteName))
		end
	end
end

--- Called when a player unequips their armor.
--- Calls the corresponding _Clear function for each equipped enchant suite.
---
--- @param Player    Player
--- @param Humanoid  Humanoid
--- @param itemName  string
--- @param armorValue Instance — the pData NumberValue (may be nil if already removed)
function EnchantLib.OnArmorUnequipped(Player: Player, Humanoid, itemName: string, armorValue)
	if not EC or not EC.Enchants then return end
	if not armorValue then return end

	for attr in armorValue:GetAttributes() do
		local enchantName = attr:match("^Enchant_(.+)$")
		if not enchantName then continue end

		local data = EC.Enchants[enchantName]
		if not data or not data.Suite then continue end

		local vt = data.ValidTypes
		if not (vt and vt.Armor) then continue end

		local suiteName = data.Suite[1]
		local clearFn   = WeaponSuites[suiteName .. "_Clear"]
		if clearFn then
			task.spawn(clearFn, WeaponSuites, Player)
		end
	end
end

--------------------------------------------------------------------------------
-- Accessory enchant dispatch
-- Called by AccessoryLib when an accessory slot is filled / cleared.
--------------------------------------------------------------------------------

--- Called when a player equips an accessory into a given slot (index).
--- Reads enchants stored as attributes on the pData accessory NumberValue.
---
--- @param Player    Player
--- @param Humanoid  Humanoid
--- @param itemName  string    — e.g. "Cerulean Crown"
--- @param accValue  Instance  — the pData NumberValue for this accessory
--- @param index     number    — slot index (1, 2, …)
function EnchantLib.OnAccessoryEquipped(Player: Player, Humanoid, itemName: string, accValue, index: number)
	if not EC or not EC.Enchants then return end
	if not accValue then return end

	for attr, level in accValue:GetAttributes() do
		local enchantName = attr:match("^Enchant_(.+)$")
		if not enchantName then continue end

		local data = EC.Enchants[enchantName]
		if not data or not data.Suite then continue end

		local vt = data.ValidTypes
		if not (vt and vt.Accessory) then continue end

		local suiteName  = data.Suite[1]
		local properties = data.Suite[2]

		local fn = WeaponSuites[suiteName]
		if fn then
			task.spawn(fn, WeaponSuites, Player, nil, level, properties, index)
		else
			warn(("[EnchantLib] OnAccessoryEquipped: suite '%s' not found."):format(suiteName))
		end
	end
end

--- Called when a player unequips an accessory from a given slot.
---
--- @param Player    Player
--- @param Humanoid  Humanoid
--- @param itemName  string
--- @param accValue  Instance  — pData NumberValue (may be nil)
--- @param index     number    — slot index
function EnchantLib.OnAccessoryUnequipped(Player: Player, Humanoid, itemName: string, accValue, index: number)
	if not EC or not EC.Enchants then return end
	if not accValue then return end

	for attr in accValue:GetAttributes() do
		local enchantName = attr:match("^Enchant_(.+)$")
		if not enchantName then continue end

		local data = EC.Enchants[enchantName]
		if not data or not data.Suite then continue end

		local vt = data.ValidTypes
		if not (vt and vt.Accessory) then continue end

		local suiteName = data.Suite[1]
		local clearFn   = WeaponSuites[suiteName .. "_Clear"]
		if clearFn then
			task.spawn(clearFn, WeaponSuites, Player, index)
		end
	end
end

--------------------------------------------------------------------------------
-- Utility: set / remove an enchant on a pData item value
-- Convenience for external code (NPC enchanters, admin commands, etc.)
--------------------------------------------------------------------------------

--- Apply an enchant of `level` to a pData item NumberValue.
--- Stores Enchant_<Name> = level as an attribute on the value.
function EnchantLib.ApplyEnchantToItem(itemValue, enchantName: string, level: number)
	if not itemValue then return end
	itemValue:SetAttribute("Enchant_" .. enchantName, level)
end

--- Remove an enchant from a pData item NumberValue.
function EnchantLib.RemoveEnchantFromItem(itemValue, enchantName: string)
	if not itemValue then return end
	itemValue:SetAttribute("Enchant_" .. enchantName, nil)
end

--- Get the current level of an enchant on a pData item value (0 = not applied).
function EnchantLib.GetEnchantLevel(itemValue, enchantName: string): number
	if not itemValue then return 0 end
	return itemValue:GetAttribute("Enchant_" .. enchantName) or 0
end

--------------------------------------------------------------------------------

return EnchantLib
