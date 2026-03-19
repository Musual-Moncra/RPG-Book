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

--> DataManager integration: resolve pData.Stats for a player
local _PlayerData -- lazy reference to ReplicatedStorage.PlayerData
local function GetPDataStats(Player: Player)
	if not _PlayerData then
		_PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	end
	local pData = _PlayerData and _PlayerData:FindFirstChild(tostring(Player.UserId))
	return pData and pData:FindFirstChild("Stats")
end

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
	"Thunder" suite — releases a lightning bolt on hit that chains to nearby enemies,
	dealing reduced damage to each subsequent target.
	Properties:
	  Damage       number   base damage to primary target × Level  (default 5)
	  ChainCount   number   max number of chain targets            (default 2)
	  ChainRadius  number   studs radius to search for chain target (default 12)
	  ChainDecay   number   damage multiplier per chain hop        (default 0.6)
	  Cooldown     number   seconds between thunder bursts         (default 1.5)
]]
local ThunderCooldowns = {}
-- Overlap params shared across Thunder calls to avoid re-alloc each hit
local _ThunderOverlapParams = OverlapParams.new()
_ThunderOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
function Suites:Thunder(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local now      = os.clock()
	local uid      = Player.UserId
	local cooldown = P.Cooldown or 1.5
	if ThunderCooldowns[uid] and ThunderCooldowns[uid] > now then return end
	ThunderCooldowns[uid] = now + cooldown

	local damage     = (P.Damage    or 5) * Level
	local chainCount = P.ChainCount or 2
	local radius     = P.ChainRadius or 12
	local decay      = P.ChainDecay  or 0.6

	-- Brief yellow flash on hit mob
	local function FlashYellow(mob)
		local saved = {}
		for _, part in mob:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				saved[part] = part.Color
				part.Color = Color3.fromRGB(255, 240, 60)
			end
		end
		task.delay(0.12, function()
			for part, c in saved do
				if part and part.Parent then part.Color = c end
			end
		end)
	end

	-- Finds the nearest unhit mob within radius using a spatial parts query.
	-- Much cheaper than workspace:GetDescendants() on large maps.
	local function FindNearestMob(origin: Vector3, excludeSet: {[Model]: true})
		local parts = workspace:GetPartBoundsInRadius(origin, radius, _ThunderOverlapParams)
		local best, bestDist = nil, radius + 1
		for _, part in parts do
			local model = part:FindFirstAncestorWhichIsA("Model")
			if model and not excludeSet[model] then
				local h = model:FindFirstChild("Enemy") :: Humanoid
				if h and h.Health > 0 then
					local d = (model:GetPivot().Position - origin).Magnitude
					if d < bestDist then bestDist = d; best = model end
				end
			end
		end
		return best
	end

	-- Initial hit
	DamageTick(Player, MobInstance, damage)
	FlashYellow(MobInstance)

	-- Chain to nearby mobs
	task.spawn(function()
		local hit = { [MobInstance] = true }
		local currentMob = MobInstance
		local currentDmg = damage

		for _ = 1, chainCount do
			task.wait(0.12)
			currentDmg = currentDmg * decay
			local nearest = FindNearestMob(currentMob:GetPivot().Position, hit)
			if not nearest then break end
			hit[nearest] = true
			DamageTick(Player, nearest, math.max(1, math.round(currentDmg)))
			FlashYellow(nearest)
			currentMob = nearest
		end
	end)
end

--[[
	"Poison" suite — coats the target in venom, dealing stacking poison ticks.
	Each hit adds one stack (up to MaxStacks); damage per tick scales with stacks.
	Properties:
	  MaxStacks   number   max poison stacks                   (default 6)
	  TickDamage  number   damage per stack per tick × Level   (default 1.5)
	  Ticks       number   total ticks in the poison window    (default 5)
	  Delay       number   seconds between ticks               (default 0.8)
]]
local PoisonState = {} -- [uid_mob] = {stacks, expiry, loop}
function Suites:Poison(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local maxStacks = P.MaxStacks  or 6
	local tickDmg   = (P.TickDamage or 1.5) * Level
	local ticks     = P.Ticks      or 5
	local delay     = P.Delay      or 0.8
	local duration  = ticks * delay

	local key = tostring(Player.UserId) .. tostring(MobInstance)
	local now = os.clock()
	local state = PoisonState[key]

	if state and state.expiry > now then
		-- Add a stack and refresh
		state.stacks = math.min(state.stacks + 1, maxStacks)
		state.expiry = now + duration
		return
	end

	-- Fresh poison
	PoisonState[key] = { stacks = 1, expiry = now + duration }

	if Effects:FindFirstChild("Poison") then
		AddParticles(MobInstance, duration, Effects.Poison)
	end

	task.spawn(function()
		for _ = 1, ticks do
			if Enemy.Health <= 0 then break end
			local cur = PoisonState[key]
			if not cur then break end
			DamageTick(Player, MobInstance, tickDmg * cur.stacks)
			-- Green tint
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = Color3.fromRGB(60, 160 + cur.stacks * 8, 60)
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
		PoisonState[key] = nil
	end)
end

--[[
	"Thorns" suite — wraps the player in a protective aura after hitting.
	For a short window, any damage the player takes is reflected back at enemies
	in a small AoE around them.
	Properties:
	  ReflectPercent  number   fraction of incoming damage reflected (default 0.4)
	  Duration        number   seconds the thorns aura lasts        (default 3)
	  Radius          number   studs radius to reflect to           (default 10)
	  Cooldown        number   seconds before thorns can re-trigger (default 4)
]]
local ThornsCooldowns = {}
local ThornsActive    = {} -- [uid] = {conn, overlapParams}
local _ThornsOverlapParams = OverlapParams.new()
_ThornsOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
function Suites:Thorns(Player, Tool, MobInstance, Level, P)
	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	local now = os.clock()
	local uid = Player.UserId
	local cooldown = P.Cooldown or 4
	if ThornsCooldowns[uid] and ThornsCooldowns[uid] > now then return end
	ThornsCooldowns[uid] = now + cooldown

	local reflectPct = (P.ReflectPercent or 0.4) * Level
	local duration   = P.Duration or 3
	local radius     = P.Radius   or 10

	-- Disconnect previous aura if any
	local existing = ThornsActive[uid]
	if existing then
		existing:Disconnect()
		ThornsActive[uid] = nil
	end

	-- Golden thorns tint on player
	local savedColors = {}
	for _, part in Character:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			savedColors[part] = part.Color
			part.Color = Color3.fromRGB(200, 180, 50)
		end
	end

	-- IMPORTANT: HealthChanged fires AFTER Humanoid.Health has already been updated to
	-- `newHealth`. Reading `Humanoid.Health` inside the callback gives the same value as
	-- `newHealth`, so subtracting them always yields 0. We track prevHealth manually.
	local prevHealth = Humanoid.Health
	local conn = Humanoid.HealthChanged:Connect(function(newHealth)
		local delta = prevHealth - newHealth  -- positive = damage received
		prevHealth  = newHealth               -- always update for next callback
		if delta <= 0 then return end         -- healing or no change — skip

		local reflectDmg = math.max(1, math.round(delta * reflectPct))
		local playerPos  = Character:GetPivot().Position

		-- Use spatial query instead of GetDescendants for performance
		local parts = workspace:GetPartBoundsInRadius(playerPos, radius, _ThornsOverlapParams)
		local checked = {}
		for _, part in parts do
			local model = part:FindFirstAncestorWhichIsA("Model")
			if model and not checked[model] then
				checked[model] = true
				local h = model:FindFirstChild("Enemy") :: Humanoid
				if h and h.Health > 0 then
					DamageTick(Player, model, reflectDmg)
				end
			end
		end
	end)

	ThornsActive[uid] = conn

	task.delay(duration, function()
		conn:Disconnect()
		if ThornsActive[uid] == conn then ThornsActive[uid] = nil end
		-- Restore player color
		for part, c in savedColors do
			if part and part.Parent then part.Color = c end
		end
	end)
end

--[[
	"Shadow" suite — after hitting an enemy, the player plunges deeper into shadow,
	building momentum with each strike. Each stack deals a bonus void-like shadow
	damage tick that scales with the number of hits landed in quick succession.
	Stacks decay if the player stops attacking.

	WHY NOT A CRIT BONUS:
	  Damage.lua resolves crits through external CriticalModifier modules loaded from
	  `script.Critical`. Those modules receive (Player, Tool, UnitCritChance, CritDmg)
	  and are not hookable from EnchantsSuites without modifying DamageLib itself.
	  A DamageTick bonus is equivalent in power and works through the proven Ignore=true
	  path that all DoT-style enchants already use.

	Properties:
	  DamagePerStack number   bonus shadow damage per stack × Level  (default 2)
	  MaxStacks      number   max shadow stacks                       (default 5)
	  DecayDelay     number   seconds of inactivity before a stack decays (default 2.5)
]]
local ShadowStacks = {} -- [uid] = {stacks, lastHit}
function Suites:Shadow(Player, Tool, MobInstance, Level, P)
	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then return end

	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local dmgPerStack = (P.DamagePerStack or 2) * Level
	local maxStacks   = P.MaxStacks   or 5
	local decayDelay  = P.DecayDelay  or 2.5
	local uid         = Player.UserId
	local now         = os.clock()

	local state = ShadowStacks[uid]
	if not state then
		state = { stacks = 0, lastHit = now }
		ShadowStacks[uid] = state

		-- Decay loop: one stack is removed per decayDelay window of inactivity
		task.spawn(function()
			while ShadowStacks[uid] do
				task.wait(0.5)
				local s = ShadowStacks[uid]
				if not s then break end
				if os.clock() - s.lastHit >= decayDelay then
					s.stacks = s.stacks - 1
					if s.stacks <= 0 then
						ShadowStacks[uid] = nil
						-- Restore character color on full decay
						local char = Player.Character
						if char then
							for _, part in char:GetDescendants() do
								if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
									part.Color = BrickColor.new("Medium stone grey").Color
								end
							end
						end
						break
					end
				end
			end
		end)
	end

	state.stacks  = math.min(state.stacks + 1, maxStacks)
	state.lastHit = now

	-- Deal a shadow damage tick to the mob proportional to current stacks.
	-- Goes through DamageTick (Ignore=true, NoHitSound=true) — the same authoritative
	-- path used by Fire, Bleed, Poison, etc. Damage.lua's defense still applies.
	if state.stacks > 0 then
		DamageTick(Player, MobInstance, math.round(dmgPerStack * state.stacks))
	end

	-- Dark tint proportional to stacks (cosmetic feedback for the player)
	local alpha = state.stacks / maxStacks
	for _, part in Character:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = Color3.fromRGB(
				math.round(40 * alpha),
				math.round(10 * alpha),
				math.round(60 * alpha)
			)
		end
	end
end

--[[
	"Shockwave" suite — emits a ground shockwave on hit, damaging and knocking
	back all enemies within the blast radius.
	Properties:
	  Radius      number   AoE radius in studs                       (default 10)
	  Damage      number   AoE damage × Level                        (default 6)
	  KBForce     number   knockback impulse magnitude               (default 60)
	  KBDuration  number   seconds enemies are staggered             (default 0.4)
	  Cooldown    number   seconds between shockwaves                (default 2)
]]
local ShockwaveCooldowns = {}
function Suites:Shockwave(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local now      = os.clock()
	local uid      = Player.UserId
	local cooldown = P.Cooldown or 2
	if ShockwaveCooldowns[uid] and ShockwaveCooldowns[uid] > now then return end
	ShockwaveCooldowns[uid] = now + cooldown

	local radius     = P.Radius     or 10
	local damage     = (P.Damage    or 6) * Level
	local kbForce    = P.KBForce    or 60
	local kbDuration = P.KBDuration or 0.4

	local origin = MobInstance:GetPivot().Position

	-- Spatial AoE search: GetPartBoundsInRadius is far cheaper than GetDescendants
	-- on maps with many objects. We de-duplicate by model to avoid double-hitting.
	local _shockwaveParams = OverlapParams.new()
	_shockwaveParams.FilterType = Enum.RaycastFilterType.Exclude
	local parts = workspace:GetPartBoundsInRadius(origin, radius, _shockwaveParams)
	local checked = {}
	for _, part in parts do
		local obj = part:FindFirstAncestorWhichIsA("Model")
		if obj and not checked[obj] then
			checked[obj] = true
			local h = obj:FindFirstChild("Enemy") :: Humanoid
			if h and h.Health > 0 then
				local mobPos = obj:GetPivot().Position
				DamageTick(Player, obj, damage)
				-- Knockback via RootPart impulse, directed away from origin
				local root = obj:FindFirstChild("HumanoidRootPart") :: BasePart
				if root and root:IsA("BasePart") then
					local dir = (mobPos - origin)
					if dir.Magnitude > 0 then dir = dir.Unit end
					root:ApplyImpulse((dir + Vector3.new(0, 0.3, 0)) * kbForce)
				end
				-- Stun (zero walk speed briefly)
				local WalkSpeed = h:FindFirstChild("WalkSpeed")
				if WalkSpeed then
					WalkSpeed:SetAttribute("EnchantShockwave", -9999)
					task.delay(kbDuration, function()
						if WalkSpeed and WalkSpeed.Parent then
							WalkSpeed:SetAttribute("EnchantShockwave", nil)
						end
					end)
				end
			end
		end
	end

	-- White ring flash at origin
	local part = Instance.new("Part")
	part.Anchored       = true
	part.CanCollide     = false
	part.CastShadow     = false
	part.Shape          = Enum.PartType.Cylinder
	part.Size           = Vector3.new(0.4, radius * 2, radius * 2)
	part.CFrame         = CFrame.new(origin) * CFrame.Angles(0, 0, math.pi / 2)
	part.Color          = Color3.new(1, 1, 1)
	part.Material       = Enum.Material.Neon
	part.Transparency   = 0.3
	part.Parent         = workspace
	Debris:AddItem(part, 0.25)
end

--[[
	"Soulrip" suite — tears the soul from defeated enemies, granting bonus Gold
	and XP on mob kills while the soulrip mark is active.
	The mark is applied on hit; if the marked mob dies within the window it drops bonus rewards.
	Properties:
	  GoldBonus    number   flat bonus Gold on the kill × Level     (default 10)
	  XPBonus      number   flat bonus XP on the kill × Level       (default 15)
	  MarkDuration number   seconds the mark lasts                  (default 5)
]]
local SoulripMarks = {} -- [mob] = {player, expiry, goldBonus, xpBonus}
function Suites:Soulrip(Player, Tool, MobInstance, Level, P)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if not Enemy or Enemy.Health <= 0 then return end

	local goldBonus    = (P.GoldBonus    or 10) * Level
	local xpBonus      = (P.XPBonus      or 15) * Level
	local markDuration = P.MarkDuration  or 5

	local now = os.clock()
	local existing = SoulripMarks[MobInstance]
	if existing and existing.expiry > now then
		-- Refresh and stack bonuses
		existing.expiry    = now + markDuration
		existing.goldBonus = existing.goldBonus + goldBonus
		existing.xpBonus   = existing.xpBonus  + xpBonus
		return
	end

	SoulripMarks[MobInstance] = {
		player    = Player,
		expiry    = now + markDuration,
		goldBonus = goldBonus,
		xpBonus   = xpBonus,
	}

	-- Purple soul aura on the mob
	for _, part in MobInstance:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = Color3.fromRGB(100, 0, 160)
		end
	end

	-- Listen for death within window
	local conn
	conn = Enemy.Died:Connect(function()
		conn:Disconnect()
		local mark = SoulripMarks[MobInstance]
		if not mark or os.clock() > mark.expiry then return end
		SoulripMarks[MobInstance] = nil

		local p = mark.player
		if not p or not p.Parent then return end

		-- Per DataManager, the real data lives in ReplicatedStorage.PlayerData.[UserId].Stats
		-- leaderstats is a display-only folder and writing to it does NOT persist.
		local pStats = GetPDataStats(p)
		if not pStats then return end

		local Gold = pStats:FindFirstChild("Gold")
		local XP   = pStats:FindFirstChild("XP")
		if Gold then Gold.Value = Gold.Value + math.round(mark.goldBonus) end
		if XP   then XP.Value   = XP.Value   + math.round(mark.xpBonus)  end
	end)

	-- Auto-clear mark and color after duration
	task.delay(markDuration, function()
		if SoulripMarks[MobInstance] then
			SoulripMarks[MobInstance] = nil
			for _, part in MobInstance:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = BrickColor.new("Medium stone grey").Color
				end
			end
		end
		if conn.Connected then conn:Disconnect() end
	end)
end

return Suites
