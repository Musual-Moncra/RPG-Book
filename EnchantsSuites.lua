--[[
	Enchant > Suites
	----------------
	On-hit side effects for enchants. Same pattern as Magic.Suites / Spell.Suites.

	SIGNATURE:
	  function Suites:MySuite(Player, Tool, MobInstance, Level, Properties)
	    Player      → player who hit
	    Tool        → the physical Tool instance (has Enchant_X attributes on it)
	    MobInstance → the mob Model that was hit
	    Level       → current enchant level (1, 2, 3…) — scale effects with this
	    Properties  → Suite[2] table from GameConfig.EnchantConfig.Enchants exactly as written

	ADDING A NEW SUITE:
	  1. Add function Suites:MySuite(...) below
	  2. In GameConfig EnchantConfig.Enchants, set:
	       Suite = {"MySuite", { ...your properties... }}
	  3. Done — Enchant library dispatches it on every real weapon hit automatically.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")

--> Lazy dependencies (avoid circular require with DamageLib)
local _DamageLib, _Mobs
local function DamageLib() if not _DamageLib then _DamageLib = require(ServerStorage.Modules.Libraries.Damage) end return _DamageLib end
local function Mobs()      if not _Mobs      then _Mobs      = require(ServerStorage.Modules.Libraries.Mob.MobList) end return _Mobs end

--> References
local Effects = ReplicatedStorage.Assets.Effects

--> Variables
local Suites = {}

--------------------------------------------------------------------------------
-- Shared utilities
--------------------------------------------------------------------------------

-- Prevents the same DoT re-stacking on rapid hits (per player, per mob, per suite name)
local ActiveDoTs = {}
local function CanStartDoT(Player, MobInstance, suiteName, duration)
	local key = tostring(Player.UserId) .. tostring(MobInstance) .. suiteName
	local now  = os.clock()
	if ActiveDoTs[key] and ActiveDoTs[key] > now then return false end
	ActiveDoTs[key] = now + duration
	return true
end

-- Clone particles from an Effects folder onto every mob limb for `duration` seconds
local function AddParticles(MobInstance, duration, effectPart)
	for _, limbName in {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"} do
		local part = MobInstance:FindFirstChild(limbName)
		if not part then continue end
		for _, emitter in effectPart:GetChildren() do
			local clone = emitter:Clone()
			clone.Parent  = part
			clone.Enabled = true
			task.delay(duration, function()
				if clone.Parent then clone.Enabled = false end
			end)
			Debris:AddItem(clone, duration + 2)
		end
	end
end

-- Deal a server-authoritative damage tick.
-- We deliberately do NOT pass Tool so prefix multipliers and DamageModifier
-- callbacks don't compound on top of the flat tick damage you set in GameConfig.
-- Mob defense still applies (intentional — enchants aren't defense-ignoring by default).
local function DamageTick(Player, MobInstance, damage)
	local mob = Mobs()[MobInstance]
	if not mob then return end
	DamageLib():DamageMob(Player, mob, {
		Damage     = damage,
		NoHitSound = true,
		Ignore     = true,
	})
end

--------------------------------------------------------------------------------
-- SUITES — add new ones here, name must match Suite[1] in GameConfig
--------------------------------------------------------------------------------

--[[
	"Fire" suite — burns the mob on hit, dealing damage ticks.
	Properties (all optional, have defaults):
	  Ticks   number   damage tick count        (default 4)
	  Delay   number   seconds between ticks    (default 0.5)
	  Damage  number   damage per tick × Level  (default 2)
]]
function Suites:Fire(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local ticks    = P.Ticks  or 4
	local delay    = P.Delay  or 0.5
	local damage   = (P.Damage or 2) * Level
	local duration = ticks * delay

	if not CanStartDoT(Player, MobInstance, "Fire", duration) then return end

	if Effects:FindFirstChild("Burn") then
		AddParticles(MobInstance, duration, Effects.Burn)
	end

	task.spawn(function()
		for _ = 1, ticks do
			if Enemy.Health <= 0 then break end
			DamageTick(Player, MobInstance, damage)
			task.wait(delay)
		end
	end)
end

--[[
	"Freeze" suite — slows the mob and deals cold damage ticks.
	Properties:
	  Ticks       number   (default 3)
	  Delay       number   (default 0.75)
	  Damage      number   per tick × Level (default 1)
	  SlowAmount  number   walkspeed penalty (default -10)
]]
function Suites:Freeze(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local ticks    = P.Ticks      or 3
	local delay    = P.Delay      or 0.75
	local damage   = (P.Damage    or 1) * Level
	local slow     = P.SlowAmount or -10
	local duration = ticks * delay

	if not CanStartDoT(Player, MobInstance, "Freeze", duration) then return end

	if Effects:FindFirstChild("Freeze") then
		AddParticles(MobInstance, duration, Effects.Freeze)
	end

	local WalkSpeed = Enemy:FindFirstChild("WalkSpeed")
	if WalkSpeed then WalkSpeed:SetAttribute("EnchantFreeze", slow) end

	task.spawn(function()
		for _ = 1, ticks do
			if Enemy.Health <= 0 then break end
			DamageTick(Player, MobInstance, damage)
			RunService.Heartbeat:Wait()
			task.wait(delay)
		end
		if WalkSpeed then WalkSpeed:SetAttribute("EnchantFreeze", nil) end
	end)
end

--[[
	"Lifesteal" suite — heals the player a fraction of base weapon damage on each hit.
	Properties:
	  Percentage  number   fraction of base weapon damage healed × Level (default 0.05)
]]
function Suites:Lifesteal(Player, Tool, MobInstance, Level, P)
	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	local pct = (P.Percentage or 0.05) * Level

	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	local baseDmg = 0
	if ItemConfig and ItemConfig.Damage then
		local d = ItemConfig.Damage
		baseDmg = typeof(d) == "table" and (d[1] + d[2]) / 2 or d
	end

	local heal = math.max(1, math.round(baseDmg * pct))
	Humanoid.Health = math.clamp(Humanoid.Health + heal, 0, Humanoid.MaxHealth)
end

--[[
	"Bleed" suite — applies a stacking bleed that deals increasing damage the
	more times the mob is hit in the window. Each hit refreshes and adds a stack.
	Properties:
	  MaxStacks    number   maximum bleed stacks             (default 5)
	  TickDamage   number   damage per stack per tick × Level (default 2)
	  Ticks        number   total ticks in the bleed window   (default 4)
	  Delay        number   seconds between ticks             (default 0.6)
]]
local BleedStacks = {} -- [userId_mobId] = {stacks, expiry}
function Suites:Bleed(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local maxStacks  = P.MaxStacks  or 5
	local tickDmg    = (P.TickDamage or 2) * Level
	local ticks      = P.Ticks      or 4
	local delay      = P.Delay      or 0.6
	local duration   = ticks * delay

	local key = tostring(Player.UserId) .. tostring(MobInstance)
	local entry = BleedStacks[key]
	local now = os.clock()

	if entry and entry.expiry > now then
		-- Refresh and add a stack
		entry.stacks = math.min(entry.stacks + 1, maxStacks)
		entry.expiry = now + duration
		return -- existing DoT loop already running
	end

	-- Start fresh bleed
	BleedStacks[key] = { stacks = 1, expiry = now + duration }

	-- Red tint scales with stacks
	task.spawn(function()
		for _ = 1, ticks do
			if Enemy.Health <= 0 then break end
			local currentEntry = BleedStacks[key]
			if not currentEntry then break end
			local stacks = currentEntry.stacks
			DamageTick(Player, MobInstance, tickDmg * stacks)
			-- Tint proportional to stacks
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = Color3.fromRGB(200, 30 + stacks * 10, 30 + stacks * 10)
				end
			end
			task.wait(delay)
		end
		-- Restore color
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Color = BrickColor.new("Medium stone grey").Color
			end
		end
		BleedStacks[key] = nil
	end)
end

--[[
	"Chill" suite — coats the mob in frost, slowing it more and more with each
	hit until it shatters (instakill below a health threshold) or the chill wears off.
	Properties:
	  SlowPerHit     number   extra WalkSpeed penalty per hit (default -4)
	  MaxSlow        number   maximum total slow penalty      (default -20)
	  Duration       number   seconds before chill resets     (default 4.0)
	  ShatterPercent number   health % threshold for shatter  (default 0.15)
	  ShatterDamage  number   bonus damage on shatter × Level (default 30)
]]
local ChillState = {} -- [userId_mobId] = {slowTotal, expiry, connection}
function Suites:Chill(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local slowPerHit     = P.SlowPerHit     or -4
	local maxSlow        = P.MaxSlow        or -20
	local duration       = P.Duration       or 4.0
	local shatterPct     = P.ShatterPercent or 0.15
	local shatterDamage  = (P.ShatterDamage or 30) * Level

	local key = tostring(Player.UserId) .. tostring(MobInstance)
	local now = os.clock()
	local WalkSpeed = Enemy:FindFirstChild("WalkSpeed")

	local state = ChillState[key]
	if not state or state.expiry <= now then
		-- Fresh chill
		state = { slowTotal = 0, expiry = now + duration }
		ChillState[key] = state
		-- Ice-blue tint
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Color = Color3.fromRGB(160, 220, 255)
			end
		end
		-- Auto-reset after duration
		task.delay(duration, function()
			if ChillState[key] then
				ChillState[key] = nil
				if WalkSpeed and WalkSpeed.Parent then
					WalkSpeed:SetAttribute("EnchantChill", nil)
				end
				for _, part in MobInstance:GetDescendants() do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Color = BrickColor.new("Medium stone grey").Color
					end
				end
			end
		end)
	else
		state.expiry = now + duration -- refresh
	end

	-- Stack the slow
	state.slowTotal = math.max(state.slowTotal + slowPerHit, maxSlow)
	if WalkSpeed then WalkSpeed:SetAttribute("EnchantChill", state.slowTotal) end

	-- Shatter check: if mob is below shatter threshold, deal burst damage
	if Enemy.Health / Enemy.MaxHealth <= shatterPct then
		ChillState[key] = nil
		if WalkSpeed and WalkSpeed.Parent then WalkSpeed:SetAttribute("EnchantChill", nil) end
		DamageTick(Player, MobInstance, shatterDamage)
		-- Flash white on shatter
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") then part.Color = Color3.new(1,1,1) end
		end
	end
end

--[[
	"Void" suite — burns the player's own mana to deal bonus void damage on hit.
	The more mana spent, the bigger the burst. If the player has no mana, no bonus fires.
	Properties:
	  ManaCost     number   mana consumed per hit              (default 8)
	  DamagePerMana number  bonus damage per mana point spent × Level (default 0.8)
	  Cooldown     number   seconds between void bursts        (default 1)
]]
local VoidCooldowns = {}
function Suites:Void(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local now = os.clock()
	local uid = Player.UserId
	local cooldown = P.Cooldown or 1
	if VoidCooldowns[uid] and VoidCooldowns[uid] > now then return end

	local manaCost     = P.ManaCost      or 8
	local dmgPerMana   = (P.DamagePerMana or 0.8) * Level

	-- Read player's current mana from Humanoid.Mana.Mana "Default" attribute
	local Character    = Player.Character
	local Humanoid     = Character and Character:FindFirstChild("Humanoid")
	local ManaFolder   = Humanoid and Humanoid:FindFirstChild("Mana")
	local ManaSub      = ManaFolder and ManaFolder:FindFirstChild("Mana")
	if not ManaSub then return end

	local currentMana = ManaSub:GetAttribute("Default") or 0
	if currentMana <= 0 then return end -- no mana, no effect

	-- Spend mana (clamp so we can't go below 0)
	local spent = math.min(manaCost, currentMana)
	ManaSub:SetAttribute("Default", math.max(0, currentMana - spent))

	VoidCooldowns[uid] = now + cooldown

	-- Deal bonus damage proportional to mana spent
	local bonus = math.round(spent * dmgPerMana)
	if bonus > 0 then
		DamageTick(Player, MobInstance, bonus)
	end

	-- Brief purple flash on the hit mob
	local origColors = {}
	for _, part in MobInstance:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			origColors[part] = part.Color
			part.Color = Color3.fromRGB(80, 0, 140)
		end
	end
	task.delay(0.2, function()
		for part, orig in origColors do
			if part and part.Parent then part.Color = orig end
		end
	end)
end

--[[
	"Poison" suite — applies a long-duration toxic effect to the mob.
	Properties:
	  Ticks   number   damage tick count        (default 10)
	  Delay   number   seconds between ticks    (default 1.0)
	  Damage  number   damage per tick × Level  (default 1)
]]
function Suites:Poison(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local ticks    = P.Ticks  or 10
	local delay    = P.Delay  or 1.0
	local damage   = (P.Damage or 1) * Level
	local duration = ticks * delay

	if not CanStartDoT(Player, MobInstance, "Poison", duration) then return end

	if Effects:FindFirstChild("Poison") then
		AddParticles(MobInstance, duration, Effects.Poison)
	end
	
	task.spawn(function()
		for _ = 1, ticks do
			if Enemy.Health <= 0 then break end
			DamageTick(Player, MobInstance, damage)
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = Color3.fromRGB(100, 200, 100)
				end
			end
			task.wait(0.2)
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = BrickColor.new("Medium stone grey").Color
				end
			end
			task.wait(delay - 0.2)
		end
	end)
end

--[[
	"Lightning" suite — builds static charge, unleashing heavy burst damage after enough hits.
	Properties:
	  RequiredHits  number   hits needed to proc burst (default 4)
	  BurstDamage   number   burst damage base × Level (default 25)
]]
local StaticCharges = {} -- [userId_mobId] = {hits, expiry}
function Suites:Lightning(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local requiredHits = P.RequiredHits or 4
	local burstDamage  = (P.BurstDamage or 25) * Level

	local key = tostring(Player.UserId) .. tostring(MobInstance)
	local now = os.clock()

	local charge = StaticCharges[key]
	if not charge or charge.expiry <= now then
		charge = { hits = 0, expiry = now + 5 }
		StaticCharges[key] = charge
	end

	charge.hits = charge.hits + 1
	charge.expiry = now + 5

	if charge.hits >= requiredHits then
		-- Proc Lightning
		StaticCharges[key] = nil
		DamageTick(Player, MobInstance, burstDamage)

		local origColors = {}
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				origColors[part] = part.Color
				part.Color = Color3.fromRGB(255, 255, 100)
			end
		end
		
		if Effects:FindFirstChild("Lightning") then
			AddParticles(MobInstance, 0.5, Effects.Lightning)
		end

		task.delay(0.15, function()
			for part, orig in origColors do
				if part and part.Parent then part.Color = orig end
			end
		end)
	else
		-- Spark visual
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Color = Color3.fromRGB(200, 200, 180)
			end
		end
		task.delay(0.1, function()
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = BrickColor.new("Medium stone grey").Color
				end
			end
		end)
	end
end

--[[
	"Execute" suite — deals bonus damage based on the mob's missing health.
	Properties:
	  MissingHealthPercent number (default 0.05)
	  MaxExecuteDamage     number max cap (default 100)
]]
function Suites:Execute(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local pct = (P.MissingHealthPercent or 0.05) * Level
	local maxBonus = (P.MaxExecuteDamage or 100) * Level

	local missingHealth = Enemy.MaxHealth - Enemy.Health
	if missingHealth <= 0 then return end

	local bonusDamage = missingHealth * pct
	bonusDamage = math.clamp(bonusDamage, 0, maxBonus)
	
	if bonusDamage >= 1 then
		DamageTick(Player, MobInstance, math.round(bonusDamage))
		
		local origColors = {}
		for _, part in MobInstance:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				origColors[part] = part.Color
				part.Color = Color3.fromRGB(150, 0, 0)
			end
		end
		task.delay(0.15, function()
			for part, orig in origColors do
				if part and part.Parent then part.Color = orig end
			end
		end)
	end
end

--[[
	"Manasteal" suite — restores the player's mana on hit.
	Properties:
	  FlatMana number  base mana restored per hit × Level (default 2)
]]
function Suites:Manasteal(Player, Tool, MobInstance, Level, P)
	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid")
	local ManaFolder = Humanoid and Humanoid:FindFirstChild("Mana")
	local ManaSub    = ManaFolder and ManaFolder:FindFirstChild("Mana")
	local MaxManaSub = ManaFolder and ManaFolder:FindFirstChild("Max")
	if not ManaSub or not MaxManaSub then return end

	local flatMana = (P.FlatMana or 2) * Level
	local currentMana = ManaSub:GetAttribute("Default") or 0
	local maxMana = MaxManaSub:GetAttribute("Default") or 100

	if currentMana < maxMana then
		local newMana = math.min(maxMana, currentMana + flatMana)
		ManaSub:SetAttribute("Default", newMana)
	end
end

return Suites
