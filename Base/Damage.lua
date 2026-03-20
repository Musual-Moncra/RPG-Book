--[[
	ej0w @ October 2024
	DamageLib
	
	Consists all Ore, Mob, and Player related damaging
	Highly advised to use Critical and Damage modules under this script to modify damage values
	
	path: ServerStorage/Modules/Damage
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Security
local AntiCheat = require(ServerStorage.Modules.Server.AntiCheat)
--> Dependencies
local Mobs  = require(ServerStorage.Modules.Libraries.Mob.MobList)
local Props = require(ServerStorage.Modules.Libraries.Prop.PropList)
-- Lazy-load Enchant to avoid require-order issues (Enchant/Suites lazy-loads us back)
local _Enchant = nil
local function EnchantLib() if not _Enchant then _Enchant = require(ServerStorage.Modules.Libraries.Enchant) end return _Enchant end
local Knockback = require(ServerStorage.Modules.Server.Knockback)
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local DamageLib = {}

local DamageModifiers = {}
for _, Module in script.Damage:GetChildren() do
	DamageModifiers[Module.Name] = require(Module)
end

local CriticalModifiers = {}
for _, Module in script.Critical:GetChildren() do
	CriticalModifiers[Module.Name] = require(Module)
end

local Interactions = {}

task.spawn(function()
	while true do
		task.wait(GameConfig.MaxDamageInteractions[2])
	end
end)

local Random = Random.new()

---- Prefix stat application -------------------------------------------------------
-- Reads PrefixName + PrefixCat attributes from the tool and applies stat modifiers
-- from GameConfig.PrefixConfig directly to the given values.
local PC = GameConfig.PrefixConfig

local function GetPrefixStats(Tool)
	if not Tool then return nil end
	local prefixName = Tool:GetAttribute("PrefixName")
	local prefixCat  = Tool:GetAttribute("PrefixCat")
	if not prefixName or not prefixCat then return nil end
	return PC.Prefixes and PC.Prefixes[prefixCat] and PC.Prefixes[prefixCat][prefixName]
end

local function ApplyPrefixDamage(Tool, Damage)
	local data = GetPrefixStats(Tool)
	if not data or not data.Stats or not data.Stats.Damage then return Damage end
	local op, val = data.Stats.Damage[1], data.Stats.Damage[2]
	if op == "Multiply"  then return Damage * val
	elseif op == "Add"   then return Damage + val
	elseif op == "Subtract" then return Damage - val
	end
	return Damage
end

local function ApplyPrefixCritChance(Tool, CritChance)
	local data = GetPrefixStats(Tool)
	if not data or not data.Stats or not data.Stats.CritChance then return CritChance end
	local op, val = data.Stats.CritChance[1], data.Stats.CritChance[2]
	-- CritChance is {roll, outOf} — Add reduces outOf (easier to crit), Subtract increases it
	if op == "Add" then
		return {CritChance[1], math.max(CritChance[1], CritChance[2] - val)}
	elseif op == "Subtract" then
		return {CritChance[1], CritChance[2] + val}
	end
	return CritChance
end

local function ApplyPrefixKnockback(Tool, Knockback)
	if not Knockback then return Knockback end
	local data = GetPrefixStats(Tool)
	if not data or not data.Stats or not data.Stats.KnockbackForce then return Knockback end
	local op, val = data.Stats.KnockbackForce[1], data.Stats.KnockbackForce[2]
	if op == "Multiply" then return Knockback * val
	elseif op == "Add"  then return Knockback + val
	end
	return Knockback
end

-- Stun: adds prefix bonus on top of base or combo step stun value.
-- If baseStun is nil and prefix adds stun, it starts from 0.
local function ApplyPrefixStun(Tool, baseStun)
	local data = GetPrefixStats(Tool)
	if not data or not data.Stats or not data.Stats.Stun then return baseStun end
	local op, val = data.Stats.Stun[1], data.Stats.Stun[2]
	local current = baseStun or 0
	if op == "Multiply" then return current > 0 and current * val or current
	elseif op == "Add"  then return current + val
	end
	return baseStun
end

-- DefensePenetration: adds to the existing penetration value, preserving the canAdd flag.
-- Returns a modified {value, canAdd} pair. If tool has no base penetration, creates one.
local function ApplyPrefixDefensePenetration(Tool, basePenetration)
	local data = GetPrefixStats(Tool)
	if not data or not data.Stats or not data.Stats.DefensePenetration then return basePenetration end
	local op, val = data.Stats.DefensePenetration[1], data.Stats.DefensePenetration[2]
	local baseVal  = basePenetration and basePenetration[1] or 0
	local canAdd   = basePenetration and basePenetration[2] or false
	if op == "Add"      then return {baseVal + val, canAdd}
	elseif op == "Multiply" then return {baseVal * val, canAdd}
	end
	return basePenetration
end

--> Configuration
local MOB_MISS_MAX_CHANCE = 100

-- Tracks how many times each player has absorbed a hit while holding block this block session.
-- { [Player] = { Melee = n, Projectiles = n, LastHitTime = os.clock() } }
-- Counter persists across block/unblock cycles and only resets 5 seconds after the last hit.
local BlockHits = {}
local BLOCK_HIT_DECAY = 5

-- Server-side combo tracking: mirrors the client's AdvanceCombo() so the server can
-- set ComboStep authoritatively. Client-set attributes don't replicate server→client,
-- so we track state here instead of trusting the Tool attribute written by the LocalScript.
-- { [Player] = { index = number, resetTimer = thread? } }
local serverComboState = {}
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for player, data in BlockHits do
			if now - data.LastHitTime >= BLOCK_HIT_DECAY then
				BlockHits[player] = nil
			end
		end
	end
end)
--------------------------------------------------------------------------------
-- Utilities

local function GetUserID(Player)
	local UserId = Player.UserId; if string.find(UserId, "-") then UserId = string.gsub(UserId, "-", "") end
	return UserId
end

local function GetPlayerBestDPS(Player)
	local Character = Player.Character
	local Weapons = {Character:FindFirstChildWhichIsA("Tool")}
	for _, Weapon in Player.Backpack:GetChildren() do
		table.insert(Weapons, Weapon)
	end
	
	local Selected = {}
	local BestDPS = 0
	for _, Weapon in Weapons do
		if Selected[Weapon.Name] then continue end
		Selected[Weapon.Name] = true
		
		local ItemConfig = Weapon:FindFirstChild("ItemConfig") and require(Weapon.ItemConfig)
		if ItemConfig and ItemConfig.Damage then
			local DPS = if typeof(ItemConfig.Damage) == "table" 
				then ((ItemConfig.Damage[1] + ItemConfig.Damage[2]) / 2) / ItemConfig.Cooldown 
				else ItemConfig.Damage / ItemConfig.Cooldown
			
			if DPS > BestDPS then
				BestDPS = DPS
			end
		end
	end
	
	return BestDPS
end

local function ShareDamageCallback(_Player, Name, Type, Params)
	EventModule:FireAllClients("ServerToClientCallback", _Player, Name, Type, Params)
	EventModule:Fire("ServerToServerCallback", _Player, Name, Type, Params)
end

--------------------------------------------------------------------------------
-- Player damaging

local function InteractParry(Player, Mob, Damage)
	local Character = Player.Character
	local DidNotInteract = true

	-- Blocking & parrying (honestly this entire system is really messy and idk how to fix that)
	local Tool = Character:FindFirstChildWhichIsA("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)

	if ItemConfig and ItemConfig.BlockAndParry then
		local IsReleased = AttributeModule:GetAttribute(Tool, "Released")

		local MobPivot = Mob and Mob.Instance:GetPivot().Position
		local CharacterPivot = Character:GetPivot().Position

		local IsBlocking = AttributeModule:GetAttribute(Tool, "Blocking")

		if not Mob or IsBlocking then
			-- Only absorb damage if CanDeflectProjectiles is true (or this is a melee hit, not a projectile).
			-- If CanDeflectProjectiles = false, the player takes full damage even while holding block.
			local isProjectile = Mob and Mob.Ranged
			local canAbsorb = not isProjectile or ItemConfig.BlockAndParry.CanDeflectProjectiles
			if canAbsorb then
				Damage = math.clamp(Damage - (Damage * ItemConfig.BlockAndParry.Absorption), 0, Damage)
			end

			-- Track block hits and break the block if the limit is reached.
			-- Only count this hit if it was actually absorbed (canAbsorb).
			-- If CanDeflectProjectiles = false, projectiles pass through at full damage
			-- and should NOT count toward MaxBlock or trigger a block break.
			local MaxBlock = ItemConfig.BlockAndParry.MaxBlock
			if IsBlocking and MaxBlock and canAbsorb then
				local isProjectile = Mob and Mob.Ranged
				local category = isProjectile and "Projectiles" or "Melee"
				local limit = MaxBlock[category]

				if limit then
					if not BlockHits[Player] then
						BlockHits[Player] = { Melee = 0, Projectiles = 0, LastHitTime = 0 }
					end
					BlockHits[Player][category] += 1
					BlockHits[Player].LastHitTime = os.clock()

					if BlockHits[Player][category] >= limit then
						-- Final hit — break the block and clear the counter
						BlockHits[Player] = nil
						AttributeModule:SetAttribute(Tool, "Blocking", nil)
						AttributeModule:SetAttribute(Tool, "Released", nil)
						AttributeModule:SetAttribute(Tool, "BlockResult", "Blocked")
						DidNotInteract = false
						return Damage, DidNotInteract
					else
						-- Non-final hit — pulse BlockHitFX so the client plays the block SFX
						AttributeModule:SetAttribute(Tool, "BlockHitFX", os.clock())
					end
				end
			end

			-- Only break the block on this hit if MaxBlock is NOT configured,
			-- or if this mob type has no limit set. MaxBlock handles the break itself.
			local shouldBreakNow = true
			if IsBlocking and MaxBlock then
				local isProjectile = Mob and Mob.Ranged
				local category = isProjectile and "Projectiles" or "Melee"
				if MaxBlock[category] then
					shouldBreakNow = false
				end
			end

			if shouldBreakNow and (not Mob or not Mob.Ranged) then
				AttributeModule:SetAttribute(Tool, "BlockResult", "Blocked")
				AttributeModule:SetAttribute(Tool, "Blocking", nil)
				AttributeModule:SetAttribute(Tool, "Released", nil)
			end

			DidNotInteract = false
		elseif Mob and IsReleased then
			-- For ranged mobs, only parry if CanParryProjectiles = true.
			-- If false, the player takes full damage (no parry counter-attack).
			local isProjectile = Mob.Ranged
			local canParryThis = not isProjectile or (ItemConfig.BlockAndParry.CanParry and ItemConfig.BlockAndParry.CanParryProjectiles)

			if canParryThis then
				Damage = 0

				local KnockbackValue = ItemConfig.Knockback or ItemConfig.BlockAndParry.Knockback
				if KnockbackValue then
					Knockback:Activate(Mob.Instance:FindFirstChild("Torso"), KnockbackValue, CharacterPivot, MobPivot)
				end

				local ParryToMob = ItemConfig.BlockAndParry.ParryToMob
				if ParryToMob then
					EventModule:FireAllClients("ForceAnimateMob", Mob.Instance, ParryToMob[math.random(#ParryToMob)])
				end

				local StunTime = ItemConfig.BlockAndParry.StunTime
				if StunTime then
					RequestStunMob(Mob, StunTime)
				end

				DamageLib:DamageMob(Player, Mob, {ClassType = "Melee", Ignore = true, Tool = Tool, Multiplier = ItemConfig.BlockAndParry.Multiplier or true})
				ShareDamageCallback(Player, Tool.Name, "OnParried", {Tool, Mob.Instance})

				if not Mob or not Mob.Ranged then
					AttributeModule:SetAttribute(Tool, "BlockResult", "Parried")
					AttributeModule:SetAttribute(Tool, "Blocking", nil)
					AttributeModule:SetAttribute(Tool, "Released", nil)
				end

				DidNotInteract = false
			end
			-- canParryThis = false: DidNotInteract stays true, Damage is unchanged → full hit
		end

		if DidNotInteract then
			DidNotInteract = not IsReleased and not IsBlocking
		end
	end

	return Damage, DidNotInteract
end

function DamageLib.Hurt(Player: Player, Damage: number, Mob)
	if typeof(Mob) == "Instance" then
		Mob = Mobs[Mob]
	end
	
	if Mob and AttributeModule:GetAttribute(Mob.Instance, "Stunned") then
		return
	end
	
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	if not Character then return end
	
	local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
	
	-- Hardcoded constitution because I genuinely don't know another use case for mobs missing attacks
	local Attributes = pData.Attributes
	local Constitution = Attributes.Constitution
	if Constitution.Value > 0 then
		local HitOpportunity = math.clamp(Constitution.Value * GameConfig.Attributes.Constitution.Amplifier, 0, math.max(MOB_MISS_MAX_CHANCE - (Mob and Mob.Config.WeightToMissChance or 0), 0))
		if math.random(100) < HitOpportunity then 
			EventModule:FireClient("PlayerDamagedEntity", Player, nil, "Missed!", GameConfig.MissColor, GameConfig.MissSFX)
			return false
		end
	end
	
	-- Defense hardcoding / ported over from Mob
	local RawDefense = 0
	local Statistics = Humanoid:FindFirstChild("Statistics")
	for Name, Value in (Statistics and Statistics.Defense:GetAttributes() or {}) do
		local IsAdditive = string.find(Name, "Additive")
		if IsAdditive then
			RawDefense += Value
		elseif not IsAdditive then
			RawDefense += Value * Damage
		end
	end

	Damage = math.clamp(math.round(Damage - RawDefense), 1, math.huge)

	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Humanoid 
		or Character:FindFirstChildWhichIsA("ForceField") 
		or not Character:FindFirstChild("Torso") 
		or Character.Torso:FindFirstChildWhichIsA("ForceField") 
	then
		return false
	end
	
	local NewDamage, DidNotInteract = InteractParry(Player, Mob, Damage)
	Damage = NewDamage
	
	-- Damage handling
	Damage = math.round(Damage)
	
	local CanDamage = Damage > 0
	if CanDamage then
		Humanoid.Health = math.clamp(Humanoid.Health - Damage, 0, Humanoid.MaxHealth)
	end
	
	if Mob then
		Mob:RequestCallback("OnHitPlayer", {Player})
	end
	
	EventModule:FireClient("MobDamagedPlayer", Player, CanDamage, DidNotInteract)
end

-- Fix vuln 4: PlayerDamaged no longer trusts the client-supplied Damage number.
-- The client sends only the MobInstance; the server looks up damage from Mob.Config.
-- This prevents exploiters sending Damage=0 (god mode) or Damage=9e18 (insta-kill self).
EventModule:GetOnServerEvent("PlayerDamaged"):Connect(function(Player, MobInstance)
	-- MobInstance must be a real Instance living in workspace.Mobs
	if typeof(MobInstance) ~= "Instance" then return end
	if not MobInstance:IsDescendantOf(workspace:FindFirstChild("Mobs")) then return end

	local Mob = Mobs[MobInstance]
	if not Mob or not Mob.Config or not Mob.Config.Damage then return end

	-- Use the authoritative server damage value, never the client's
	local ServerDamage = Mob.Config.Damage

	local CanHighlight = DamageLib.Hurt(Player, ServerDamage, MobInstance)
	if CanHighlight then
		EventModule:FireClient("MobDamagedPlayer", Player, nil, ServerDamage, nil, true, true)
	end
end)



-- ProjectileDeflected: no longer used
EventModule:GetOnServerEvent("ProjectileDeflected"):Connect(function() end)
EventModule:GetOnServerEvent("ProjectileParried"):Connect(function() end)

-- ProjectileParriedLaunched: fired the moment the player perfect-parries.
-- ONLY consumes the parry window and triggers the player-side feedback (BlockResult).
-- All mob effects (stun, knockback, damage) are deferred to ProjectileParriedHit.
-- We store the parry context keyed by player so ProjectileParriedHit can look it up.
local PendingParries = {} -- [Player] = { Mob, BlockAndParry, Tool, Character, timestamp }

EventModule:GetOnServerEvent("ProjectileParriedLaunched"):Connect(function(Player, MobInstance)
	if typeof(MobInstance) ~= "Instance" then return end
	if not MobInstance:IsDescendantOf(workspace:FindFirstChild("Mobs")) then return end

	local Mob = Mobs[MobInstance]
	if not Mob or not Mob.Config then return end

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	local Tool = Character:FindFirstChildWhichIsA("Tool")
	if not Tool then return end

	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	local BlockAndParry = ItemConfig and ItemConfig.BlockAndParry
	if not BlockAndParry or not BlockAndParry.CanParry or not BlockAndParry.CanParryProjectiles then return end

	local IsReleased = AttributeModule:GetAttribute(Tool, "Released")
	if not IsReleased then return end

	-- Consume the parry window immediately (player feedback)
	AttributeModule:SetAttribute(Tool, "Released", nil)
	AttributeModule:SetAttribute(Tool, "Blocking", nil)
	AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())

	-- Store context so ProjectileParriedHit knows what to apply and to which mob
	PendingParries[Player] = {
		Mob = Mob,
		BlockAndParry = BlockAndParry,
		Tool = Tool,
		Character = Character,
		Timestamp = os.clock(),
	}

	-- Expire after 10 seconds in case the arrow misses everything
	task.delay(10, function()
		if PendingParries[Player] and PendingParries[Player].Timestamp == PendingParries[Player].Timestamp then
			PendingParries[Player] = nil
		end
	end)
end)

-- ProjectileParriedHit: fired when the parry arrow physically hits a mob.
-- Applies damage, stun, knockback, and anim all at once — on the hit mob.
EventModule:GetOnServerEvent("ProjectileParriedHit"):Connect(function(Player, originalMobInstance, hitMobInstance)
	if typeof(originalMobInstance) ~= "Instance" then return end
	if typeof(hitMobInstance) ~= "Instance" then return end
	if not originalMobInstance:IsDescendantOf(workspace:FindFirstChild("Mobs")) then return end
	if not hitMobInstance:IsDescendantOf(workspace:FindFirstChild("Mobs")) then return end

	local pending = PendingParries[Player]
	if not pending then return end
	PendingParries[Player] = nil

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	local hitMob = Mobs[hitMobInstance]
	if not hitMob then return end

	local BlockAndParry = pending.BlockAndParry
	local Tool = pending.Tool
	local OriginalMob = pending.Mob

	-- Damage
	DamageLib:DamageMob(Player, hitMob, {
		ClassType = "Melee",
		Ignore = true,
		Tool = Tool,
		Multiplier = BlockAndParry.Multiplier or true,
	})

	-- Stun the hit mob
	if BlockAndParry.StunTime then
		RequestStunMob(hitMob, BlockAndParry.StunTime)
	end

	-- Stagger animation on the hit mob
	if BlockAndParry.ParryToMob then
		EventModule:FireAllClients("ForceAnimateMob", hitMob.Instance,
			BlockAndParry.ParryToMob[math.random(#BlockAndParry.ParryToMob)])
	end

	-- Knockback away from the player
	if BlockAndParry.Knockback then
		local CharacterPivot = Character:GetPivot().Position
		local MobPivot = hitMob.Instance:GetPivot().Position
		Knockback:Activate(hitMob.Instance:FindFirstChild("Torso"), BlockAndParry.Knockback, CharacterPivot, MobPivot)
	end

	ShareDamageCallback(Player, Tool.Name, "OnParried", {Tool, hitMob.Instance})
end)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local RemoteUsages = {}
local ParryCooldown = {}
local ActivateCooldown = {}

task.spawn(function()
	while true do
		RemoteUsages = {}
		
		task.wait(GameConfig.MaxInputInteractions[2])
	end
end)

---- Parrying / blocking

Players.PlayerRemoving:Connect(function(Player)
	BlockHits[Player] = nil
	serverComboState[Player] = nil
end)

EventModule:GetOnServerEvent("RequestBlock"):Connect(function(Player: Player, OldTool, Verdict: boolean, CanComplete: boolean)
	if not RemoteUsages[Player] then
		RemoteUsages[Player] = 0
	end

	RemoteUsages[Player] += 1

	-- Check if the player can block
	local Character = Player.Character

	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	-- Always use the server-known equipped tool, never the client-supplied OldTool.
	-- The client-supplied OldTool is only used for attribute cleanup, but writing
	-- attributes to an arbitrary client-supplied Instance lets exploiters stamp
	-- attributes on any game object (e.g. mobs). We resolve it server-side instead.
	local Tool = Character and Character:FindFirstChildWhichIsA("Tool")

	if not Tool or RemoteUsages[Player] > GameConfig.MaxInputInteractions[1] then
		-- SECURITY: clear block state on the server-known tool, not on the client-supplied one.
		-- If there is no tool equipped, there is nothing to clean up — just bail.
		if Tool then
			AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())
			AttributeModule:SetAttribute(Tool, "Blocking", nil)
			AttributeModule:SetAttribute(Tool, "Released", nil)
		end
		return
	end

	if (not Humanoid or Humanoid.Health <= 0) or not Tool:IsDescendantOf(Character) then
		return
	end

	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if not ItemConfig or not ItemConfig.BlockAndParry then
		return
	end

	-- On activated block:
	AttributeModule:SetAttribute(Tool, "BlockResult", nil)

	if Verdict then
		AttributeModule:SetAttribute(Tool, "Blocking", true)
	elseif not Verdict then
		if ItemConfig.BlockAndParry.CanParry and CanComplete and not ActivateCooldown[Player] then
			ActivateCooldown[Player] = true

			AttributeModule:SetAttribute(Tool, "Released", true)

			task.delay(ItemConfig.BlockAndParry.ParryWindow, function()
				if not AttributeModule:GetAttribute(Tool, "BlockResult") then
					AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())
				end
				AttributeModule:SetAttribute(Tool, "Released", nil)

				ActivateCooldown[Player] = false
			end)
		elseif not ActivateCooldown[Player] then
			AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())
		end

		AttributeModule:SetAttribute(Tool, "Blocking", nil)
		-- Do NOT reset BlockHits here — the 5-second decay loop handles that.
		-- Clearing it on unblock would let players spam block/unblock to reset MaxBlock.
	end
end)

--------------------------------------------------------------------------------
-- Ore / mob damaging

function DamageLib:TagMobForDamage(Player: Player, Mob, Damage: number)
	if Mob.isDead then
		return 
	end
	
	local UserId = GetUserID(Player)
	
	if Mob.Config.InstantRefreshData and Mob.Config.InstantRefreshData.CanRefresh then
		local RegenerateTag = Mob.Instance:FindFirstChild("RegenerateTag")
			or Instance.new("Configuration")
		
		RegenerateTag.Name = "RegenerateTag"
		RegenerateTag.Parent = Mob.Instance
		
		if RegenerateTag:GetAttribute("Player") == nil or RegenerateTag:GetAttribute("Player") == Player then
			RegenerateTag:SetAttribute("Clock", os.clock())
			RegenerateTag:SetAttribute("PlayerID", UserId)
		end
	end
	
	local PlayerTags = Mob.Instance:FindFirstChild("PlayerTags")
	if not PlayerTags then
		PlayerTags = Instance.new("Configuration")
		PlayerTags.Name = "PlayerTags"
		PlayerTags.Parent = Mob.Instance
	end
	
	local ExistingTag = PlayerTags:GetAttribute(tonumber(UserId))
	PlayerTags:SetAttribute(tonumber(UserId), (ExistingTag or 0) + Damage)
end

-- Sorry for how messy this is: Ignore should be called for serverside, Tool & Modifier same story, modifier is true/num to no knockback, number to * damage
function DamageLib:DamageMob(Player: Player, Mob, Parameters)
	Parameters = Parameters or {}
	
	local NoHitSound = Parameters.NoHitSound 
	local Multiplier = Parameters.Multiplier
	local ClassType = Parameters.ClassType
	local Damage = Parameters.Damage
	local Ignore = Parameters.Ignore 
	local Dampen = Parameters.Dampen
	local Tool = Parameters.Tool
	
	local UserId = GetUserID(Player)
	local RegenerateTag = Mob.Instance:FindFirstChild("RegenerateTag")
	
	if Mob.isDead or (Mob.Config.InstantRefreshData and Mob.Config.InstantRefreshData.CanRefresh and RegenerateTag and (RegenerateTag:GetAttribute("PlayerID") ~= UserId and RegenerateTag:GetAttribute("PlayerID") ~= nil)) then
		return
	end
	
	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if not Level or (Level.Value < Mob.Config.Level[2]) then
		return
	end
	
	-- Make sure the equipped tool can be found, so we can safely grab the damage from it.
	-- Never pass damage as a number through a remote, as the client can manipulate this data.
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then
		return
	end
	
	local Tool = Tool or Character:FindFirstChildOfClass("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if (not ItemConfig or not ItemConfig.Damage or (ItemConfig.WeaponType ~= ClassType and ItemConfig.ToolType ~= ClassType)) and not Ignore then 
		return 
	end
	
	-- Damage Cooldown
	local Count = Interactions[Player.UserId]
	local Default = GameConfig.MaxDamageInteractions[1]
	if not Ignore and (Count and (Count > Default / ItemConfig.Cooldown)) then
		return 
	end
	
	Interactions[Player.UserId] = (Count and Count + 1) or 1
	
	-- Calculate damage & criticals
	-- *These wouldn't be hardcoded if they were practical
	local ItemSuite = ItemConfig and ItemConfig.Suite and ItemConfig.Suite[2]
	local CriticalChance = ItemConfig and ItemConfig.CriticalChance or GameConfig.CriticalChance
	local CriticalDamage = GameConfig.CriticalMultiplier
	
	if CriticalChance[2] then
		local UnitCriticalChance = {1, CriticalChance[2] / CriticalChance[1]}
		for _, Callback in CriticalModifiers do
			UnitCriticalChance, CriticalDamage = Callback(Player, Tool, UnitCriticalChance, CriticalDamage)
		end
	end
	
	local Proportionate = ItemSuite and ItemSuite.Proportionate
	local SuiteDamage = ItemSuite and ItemSuite.Damage

	local Damage = Damage 
		or Proportionate and GetPlayerBestDPS(Player) * ItemSuite.Damage
		or SuiteDamage
		or typeof(ItemConfig.Damage) == "table" and Random:NextInteger(unpack(ItemConfig.Damage))
		or ItemConfig.Damage
	
	-- Combo step overrides: if the tool has a Combo config and ComboStep attribute,
	-- apply per-step Damage, Knockback, Stun, and CriticalChance from that step's config.
	local comboStep = nil
	if ItemConfig and ItemConfig.Combo and Tool then
		local stepIndex = AttributeModule:GetAttribute(Tool, "ComboStep")
		if stepIndex and stepIndex > 0 then
			comboStep = ItemConfig.Combo[stepIndex]
		end
	end

	-- Override CriticalChance with the combo step's value if specified
	if comboStep and comboStep.CriticalChance then
		CriticalChance = comboStep.CriticalChance
	end

	-- Override base damage with combo step damage if specified
	if comboStep and comboStep.Damage then
		Damage = typeof(comboStep.Damage) == "table"
			and Random:NextInteger(unpack(comboStep.Damage))
			or comboStep.Damage
	end

	-- Apply prefix stat bonuses (Damage, CritChance) from the tool's PrefixName attribute
	if Tool then
		Damage = ApplyPrefixDamage(Tool, Damage)
		CriticalChance = ApplyPrefixCritChance(Tool, CriticalChance)
	end

	if Tool then
		for _, Callback in DamageModifiers do
			Damage = Callback(Player, Tool, Damage, Mob)
		end
	end
	
	-- Defense negation
	local ConfigDefensePenetration = ApplyPrefixDefensePenetration(Tool, ItemConfig and ItemConfig.DefensePenetration)
	local ConfigDefense = Mob.Config.Defense
	
	local WeaponCanAdd = ConfigDefensePenetration and ConfigDefensePenetration[2]
	local WeaponDefense = ConfigDefensePenetration and ConfigDefensePenetration[1]
	if not WeaponCanAdd then
		WeaponDefense = WeaponDefense and math.clamp(WeaponDefense, 0, 1)
	end
	
	local MobCanAdd = ConfigDefense and ConfigDefense[2]
	local MobDefense = ConfigDefense and ConfigDefense[1]
	if not MobCanAdd then
		MobDefense = MobDefense and math.clamp(MobDefense, 0, 1)
	end
	
	local RawMobDefense = (MobCanAdd and MobDefense) or 0
	local RawWeaponDefense = (WeaponCanAdd and WeaponDefense) or 0
	if MobDefense and not MobCanAdd then
		local DividedMobDefense = (1 / MobDefense)
		if WeaponDefense and not WeaponCanAdd then
			DividedMobDefense *= (1 / WeaponDefense)
		end
		local NegatedWeaponDamage = Damage / DividedMobDefense
		RawMobDefense = NegatedWeaponDamage
	end
	
	RawMobDefense = math.clamp(RawMobDefense - RawWeaponDefense, 0, math.huge)
	Damage = math.clamp(Damage - RawMobDefense, 1, math.huge)
	
	-- Dampen damage (based on ranged piercing)
	if Dampen and Dampen == Dampen then
		local ClampedDampen = math.clamp(Dampen, 0.1, 1)
		Damage = Damage * ClampedDampen
	end
	
	-- Critical multiplier
	local Critical = CriticalChance[2] and Random:NextInteger(unpack(CriticalChance)) == CriticalChance[2]
	if Critical then
		Damage *= CriticalDamage
	end
	
	-- Damage modifier
	if typeof(Multiplier) == "number" then
		Damage *= Multiplier
	end
	
	-- Damage cap
	local MaxDamageCap = Mob.Config.MaxDamageCap 
	if MaxDamageCap then
		local MaxDamage = math.round(Mob.Config.Health * MaxDamageCap)
		Damage = math.clamp(Damage, 0, MaxDamage)
	end
	
	Damage = math.round(Damage)
	
	local CharacterPivot = Character:GetPivot().Position
	local MobPivot = Mob.Instance:GetPivot().Position


	-- Knockback: combo step value takes priority; falls back to base ItemConfig if step doesn't define it.
	-- Multiplier=true means server-spawned DoT tick (parry/enchant) — skip knockback entirely.
	-- Ignore=true also skips (enchant DoT ticks, spell ticks).
	local knockbackValue = (comboStep and comboStep.Knockback)
		or (not Multiplier and ItemConfig and ItemConfig.Knockback)
	knockbackValue = ApplyPrefixKnockback(Tool, knockbackValue)
	if knockbackValue and not Ignore and Multiplier ~= true then
		Knockback:Activate(Mob.Instance:FindFirstChild("Torso"), knockbackValue, CharacterPivot, MobPivot)
	end

	-- Stun: combo step fully overrides base config; base config only used when no combo is active
	-- Stun: pick base (combo step overrides base config), then apply prefix bonus on top.
	-- This means prefix stun stacks with both per-step and base ItemConfig stun values.
	local rawStun = comboStep and comboStep.Stun or (not comboStep and ItemConfig and ItemConfig.Stun)
	local stunValue = ApplyPrefixStun(Tool, rawStun)
	if stunValue then
		RequestStunMob(Mob, stunValue)
	end
	
	AttributeModule:SetAttribute(Mob.Instance, "HasBeenHit", true)
	
	-- Damage handling
	DamageLib:TagMobForDamage(Player, Mob, Damage)
	
	Mob:TakeDamage(Damage)
	Mob:RequestCallback("OnHit", {Player})
	
	EventModule:FireClient("PlayerDamagedEntity", Player, Mob.Instance, Damage, Critical, ItemConfig, NoHitSound)
	
	if Tool then
		if Critical then
			ShareDamageCallback(Player, Tool.Name, "OnCritical", {Tool, Mob.Instance})
		end
		
		ShareDamageCallback(Player, Tool.Name, "OnHit", {Tool, Mob.Instance})
		-- Dispatch enchant on-hit suites (skip Ignore=true server-spawned ticks to prevent recursion)
		if not Ignore then EnchantLib().OnHit(Player, Tool, Mob.Instance) end
	end
end

function DamageLib:DamageMobSkill(Player: Player, Mob, Parameters)
	Parameters = Parameters or {}

	local Damage      = Parameters.Damage or 0
	local SkillScaling = Parameters.SkillScaling
	local Multiplier  = Parameters.Multiplier
	local NoHitSound  = Parameters.NoHitSound
	local Tool        = Parameters.Tool

	if Mob.isDead then return end

	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if not Level or Level.Value < Mob.Config.Level[2] then return end

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	-- Apply SkillScaling (stat-based scaling defined per-skill, not per-tool)
	if SkillScaling then
		-- Build a fake config table that getValueScaling can iterate over.
		-- It looks for keys containing "Scaling" and the Required string ("Damage").
		local FakeConfig = { DamageScaling = SkillScaling }
		local GetValueScaling = require(ReplicatedStorage.Modules.Shared.getValueScaling)
		Damage = GetValueScaling(Damage, "Damage", FakeConfig, Player)
	end

	-- Defense negation (same as DamageMob)
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	local ConfigDefensePenetration = ApplyPrefixDefensePenetration(Tool, ItemConfig and ItemConfig.DefensePenetration)
	local ConfigDefense = Mob.Config.Defense

	local WeaponCanAdd = ConfigDefensePenetration and ConfigDefensePenetration[2]
	local WeaponDefense = ConfigDefensePenetration and ConfigDefensePenetration[1]
	if not WeaponCanAdd then
		WeaponDefense = WeaponDefense and math.clamp(WeaponDefense, 0, 1)
	end
	local MobCanAdd = ConfigDefense and ConfigDefense[2]
	local MobDefense = ConfigDefense and ConfigDefense[1]
	if not MobCanAdd then
		MobDefense = MobDefense and math.clamp(MobDefense, 0, 1)
	end
	local RawMobDefense = (MobCanAdd and MobDefense) or 0
	local RawWeaponDefense = (WeaponCanAdd and WeaponDefense) or 0
	if MobDefense and not MobCanAdd then
		local DividedMobDefense = (1 / MobDefense)
		if WeaponDefense and not WeaponCanAdd then
			DividedMobDefense *= (1 / WeaponDefense)
		end
		RawMobDefense = Damage / DividedMobDefense
	end
	RawMobDefense = math.clamp(RawMobDefense - RawWeaponDefense, 0, math.huge)
	Damage = math.clamp(Damage - RawMobDefense, 1, math.huge)

	-- Criticals
	local CriticalChance = (ItemConfig and ItemConfig.CriticalChance) or GameConfig.CriticalChance
	local CriticalDamage = GameConfig.CriticalMultiplier
	local Critical = CriticalChance[2] and Random:NextInteger(unpack(CriticalChance)) == CriticalChance[2]
	if Critical then
		Damage *= CriticalDamage
	end

	-- Multiplier
	if typeof(Multiplier) == "number" then
		Damage *= Multiplier
	end

	-- Damage cap
	local MaxDamageCap = Mob.Config.MaxDamageCap
	if MaxDamageCap then
		Damage = math.clamp(Damage, 0, math.round(Mob.Config.Health * MaxDamageCap))
	end

	Damage = math.round(Damage)

	-- Knockback (skipped for server-spawned enchant/spell DoT ticks where Ignore=true)
	if Tool and ItemConfig and ItemConfig.Knockback and not Multiplier and not Ignore then
		local CharacterPivot = Character:GetPivot().Position
		local MobPivot = Mob.Instance:GetPivot().Position
		Knockback:Activate(Mob.Instance:FindFirstChild("Torso"), ItemConfig.Knockback, CharacterPivot, MobPivot)
	end

	AttributeModule:SetAttribute(Mob.Instance, "HasBeenHit", true)
	DamageLib:TagMobForDamage(Player, Mob, Damage)
	Mob:TakeDamage(Damage)
	Mob:RequestCallback("OnHit", {Player})

	EventModule:FireClient("PlayerDamagedEntity", Player, Mob.Instance, Damage, Critical, ItemConfig, NoHitSound)

	if Tool then
		if Critical then
			ShareDamageCallback(Player, Tool.Name, "OnCritical", {Tool, Mob.Instance})
		end
		ShareDamageCallback(Player, Tool.Name, "OnHit", {Tool, Mob.Instance})
	end
end

function DamageLib:DamageProp(Player: Player, Prop, Parameters)
	Parameters = Parameters or {}
	
	local Damage = Parameters.Damage
	local Ignore = Parameters.Ignore 
	local Tool = Parameters.Tool
	
	local Character = Player.Character
	Tool = Tool or Character and Character:FindFirstChildOfClass("Tool")
	
	if Prop.isDead then return end
	
	-- Check if ItemConfig exists & uses eight weapon type
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if (not ItemConfig or not ItemConfig.Damage or not ItemConfig.ValidPropTypes or not table.find(ItemConfig.ValidPropTypes, Prop.Config.PropType)) and not Ignore then 
		return 
	end
	
	-- Check if player's level is enough to mine ore
	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if Level and Level.Value < Prop.Config.Level[2] then
		EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, "Level too low!", GameConfig.WarningColor, ItemConfig.InvalidSFX or GameConfig.InvalidSFX)
		return
	end
	
	if ItemConfig.Tier < Prop.Config.Tier then
		EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, "Tier too low!", GameConfig.WarningColor, ItemConfig.InvalidSFX or GameConfig.InvalidSFX)
		return
	end
	
	-- Calculate damage
	local Damage = Damage 
		or typeof(ItemConfig.Damage) == "table" and Random:NextInteger(unpack(ItemConfig.Damage))
		or ItemConfig.Damage

	for _, Callback in DamageModifiers do
		Damage = Callback(Player, Tool, Damage)
	end
	
	Damage = math.round(Damage)

	-- Ore tagging
	local CurrentDamage = Prop.PlayerTags[Player.UserId] or 0
	Prop.PlayerTags[Player.UserId] = CurrentDamage + Damage
	
	-- Render damage & return
	Prop:TakeDamage(Damage)
	
	EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, Damage, false, ItemConfig, false, Prop.Scale)
	ShareDamageCallback(Player, Tool.Name, "OnHit", {Tool, Prop.Instance})
end

-- Advances the server-side combo counter for a player and sets ComboStep on the tool.
-- Called on every swing (via RequestComboAdvance) so it stays in sync even on misses.
-- stepIndex: the exact index the client resolved (handles Random type); falls back to sequential if invalid.
local function AdvanceServerCombo(Player, Tool, ItemConfig, stepIndex)
	if not ItemConfig or not ItemConfig.Combo then return end
	local combo = ItemConfig.Combo

	-- Count numeric keys (the hit steps)
	local comboCount = 0
	for k in combo do
		if type(k) == "number" then comboCount += 1 end
	end
	if comboCount == 0 then return end

	if not serverComboState[Player] then
		serverComboState[Player] = { index = 0, resetTimer = nil }
	end

	local state = serverComboState[Player]

	-- Cancel any pending reset
	if state.resetTimer then
		task.cancel(state.resetTimer)
		state.resetTimer = nil
	end

	-- Use client-reported index if valid (needed for Random type), else advance sequentially
	if type(stepIndex) == "number" and stepIndex >= 1 and stepIndex <= comboCount then
		state.index = stepIndex
	else
		state.index = (state.index % comboCount) + 1
	end

	-- Schedule reset using ResetTime (inactivity window), or LastHitCooldown on final hit
	local isLastHit = state.index == comboCount
	local resetDelay = isLastHit and combo.LastHitCooldown or combo.ResetTime
	state.resetTimer = task.delay(resetDelay, function()
		state.index = 0
		state.resetTimer = nil
		-- Clear attribute so DamageMob falls back to base damage after reset
		if Tool and Tool.Parent then
			AttributeModule:SetAttribute(Tool, "ComboStep", 0)
		end
	end)

	-- Set the attribute server-side so DamageMob reads the correct step
	AttributeModule:SetAttribute(Tool, "ComboStep", state.index)
end

-- RequestComboAdvance: fired by the client on every swing (hit or miss).
-- This keeps serverComboState in sync regardless of whether a mob was actually hit,
-- fixing the desync that occurred when swings missed and DamageEntity never fired.
EventModule:GetOnServerEvent("RequestComboAdvance"):Connect(function(Player, stepIndex)
	if not RemoteUsages[Player] then RemoteUsages[Player] = 0 end
	RemoteUsages[Player] += 1
	if RemoteUsages[Player] > GameConfig.MaxInputInteractions[1] then return end

	local Character = Player.Character
	local Tool = Character and Character:FindFirstChildOfClass("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if not ItemConfig or not ItemConfig.Combo then return end

	AdvanceServerCombo(Player, Tool, ItemConfig, stepIndex)
end)


function DamageLib.CallDamage(Player, EntityInstance: Model, Dampen: number?, Class, SpellTool)
	-- Spell DoT ticks are server-initiated: the cast was already validated at PlayerUsedSpell time.
	-- Skip AntiCheat for these — the tool check and class check are meaningless mid-tick.
	if SpellTool then
		if CollectionService:HasTag(EntityInstance, "Mob") then
			local Mob = Mobs[EntityInstance]
			if Mob then
				DamageLib:DamageMob(Player, Mob, {
					ClassType = Class,
					Tool      = SpellTool,
					Ignore    = true,
				})
			end
		end
		return
	end

	-- Client-originated hit: full AntiCheat validation required.
	if not AntiCheat.Validate(Player, EntityInstance, Dampen, Class) then
		return
	end

	if CollectionService:HasTag(EntityInstance, "Mob") then
		local Mob = Mobs[EntityInstance]
		if Mob then
			-- ComboStep is already stamped by RequestComboAdvance (fired on every swing).
			-- No need to advance here — doing so would double-advance on hits.
			DamageLib:DamageMob(Player, Mob, {Dampen = Dampen, ClassType = Class})
		end
	elseif CollectionService:HasTag(EntityInstance, "Prop") then
		local Prop = Props[EntityInstance]
		if Prop then
			DamageLib:DamageProp(Player, Prop)
		end
	end
end

EventModule:GetOnServerEvent("DamageEntity"):Connect(DamageLib.CallDamage)
return DamageLib