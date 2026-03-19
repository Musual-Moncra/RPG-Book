--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

--> Dependencies
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local DamageLib = require(ServerStorage.Modules.Libraries.Damage)
local Mobs = require(ServerStorage.Modules.Libraries.Mob.MobList)

--> Variables
local Spells = {}
-- Key: player.UserId .. "_" .. mob (tostring) so per-player per-mob.
-- Prevents: (a) same player re-applying before DoT expires, (b) two players
-- sharing one lock, (c) spamming a different mob while token is live.
local CurrentlyAffected = {}

--------------------------------------------------------------------------------
-- Utilities

local function AddParticlesToCharacter(Character, TotalTime, Folder)
	local Limbs = {"Left Leg", "Left Arm", "Right Arm", "Right Leg", "Torso", "Head"}
	for _, Limb in Limbs do
		local LimbPart = Character:FindFirstChild(Limb)
		if not LimbPart then
			continue
		end

		for _, Particle in Folder:GetChildren() do
			local Clone = Particle:Clone()
			Clone.Parent = LimbPart
			Clone.Enabled = true
			task.delay(TotalTime, function()
				Clone.Enabled = false
			end)

			Debris:AddItem(Clone, TotalTime + 2)
		end
	end
end

local function ChangeCharacter(Character, Callback)
	local Tool = Character:FindFirstChildWhichIsA("Tool")
	for _, Object: Part in Character:GetDescendants() do
		if Tool and Object:IsDescendantOf(Tool) then
			continue
		end
		
		if Object:IsA("SpecialMesh") then
			Object.TextureId = ""
		elseif Object:IsA("BasePart") then
			if Object:IsA("MeshPart") then
				Object.TextureID = ""
			end
			task.spawn(Callback, Object)
		elseif Object:IsA("Decal") then
			Object.Transparency = 1
		end
	end
end

--------------------------------------------------------------------------------
-- Callbacks

--[[
	Fire — burning DoT. Deals damage ticks and chars the mob black on kill.
	Properties:
	  Ticks         number   damage tick count
	  Delay         number   seconds between ticks
	  Damage        number   flat damage per tick — required for isDamaging check
	  Proportionate boolean  if true, damage = Damage × player's best weapon DPS

	Example ItemConfig Suite:
	  Suite = {"Fire", {
	      Projectile    = "Fireball",
	      Velocity      = 200,
	      Acceleration  = Vector3.new(0, -workspace.Gravity/8, 0),
	      Damage        = 2,
	      Proportionate = false,
	      Ticks         = 5,
	      Delay         = 0.5,
	  }},
	  Throwable = true,
]]
function Spells:Fire(Player, Spell, MobInstance, Properties)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	local key = Player.UserId .. "_" .. tostring(MobInstance)
	if CurrentlyAffected[key] then return end
	CurrentlyAffected[key] = os.clock()

	local TotalTime = Properties.Delay * Properties.Ticks
	task.delay(TotalTime, function()
		CurrentlyAffected[key] = nil
	end)

	AddParticlesToCharacter(MobInstance, TotalTime, ReplicatedStorage.Assets.Effects.Burn)

	for Iteration = 1, Properties.Ticks do
		DamageLib.CallDamage(Player, MobInstance, nil, "Spell", Spell)
		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then
					Object.Transparency = 0
				end
				Object.Color = Color3.fromRGB(0, 0, 0)
				Object.Reflectance = 0
				Object.Material = Enum.Material.SmoothPlastic
			end)
			break
		end
		task.wait(Properties.Delay)
	end
end

--[[
	Freeze — slows the mob and deals cold damage ticks. Freezes it on kill.
	Properties:
	  Ticks         number   damage tick count
	  Delay         number   seconds between ticks
	  Damage        number   flat damage per tick — required for isDamaging check
	  Proportionate boolean  if true, damage = Damage × player's best weapon DPS

	Example ItemConfig Suite:
	  Suite = {"Freeze", {
	      Projectile    = "Iceball",
	      Velocity      = 180,
	      Acceleration  = Vector3.new(0, -workspace.Gravity/8, 0),
	      Damage        = 1,
	      Proportionate = false,
	      Ticks         = 5,
	      Delay         = 0.75,
	  }},
	  Throwable = true,
]]
function Spells:Freeze(Player, Spell, MobInstance, Properties)
	if not MobInstance then return end

	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	local key = Player.UserId .. "_" .. tostring(MobInstance)
	if CurrentlyAffected[key] then return end
	CurrentlyAffected[key] = os.clock()

	local TotalTime = Properties.Delay * Properties.Ticks

	local WalkSpeed = Enemy:WaitForChild("WalkSpeed")
	WalkSpeed:SetAttribute("FreezingSpell", -10)

	AddParticlesToCharacter(MobInstance, TotalTime, ReplicatedStorage.Assets.Effects.Freeze)

	task.delay(TotalTime, function()
		WalkSpeed:SetAttribute("FreezingSpell", nil)
		CurrentlyAffected[key] = nil
	end)

	for Iteration = 1, Properties.Ticks do
		DamageLib.CallDamage(Player, MobInstance, nil, "Spell", Spell)
		RunService.Heartbeat:Wait()

		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then
					Object.Transparency = 0.25
				end
				Object.CastShadow = false
				Object.Color = Color3.fromRGB(153, 194, 255)
				Object.Material = Enum.Material.Ice
			end)
			break
		end

		task.wait(Properties.Delay)
	end
end

--[[
	Health — self-buff. Boosts max health via Statuses and optionally heals a
	percentage of current max health immediately. Non-targeting (no Damage field).
	Properties:
	  Additive   number  fraction of current MaxHealth added as a status bonus
	  Duration   number  seconds the health bonus lasts
	  Percentage number  fraction of MaxHealth healed immediately (optional)

	Example ItemConfig Suite:
	  Suite = {"Health", {
	      Additive   = 0.4,
	      Duration   = 30,
	      Percentage = 0.25,
	  }},
	  Throwable = false,
]]
function Spells:Health(Player, Spell, _, Properties)
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Attributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
	if not Attributes then return end
	
	-- Set effect
	local Additive = Properties.Additive
	local Duration = Properties.Duration
	
	local MaxHealth = 0
	for Name, Value in Attributes.Health:GetAttributes() do
		if Name == "Spell" then
			continue
		end
		MaxHealth += Value
	end

	local Statuses = Player:WaitForChild("Statuses", 1)
	local Effect = Statuses and Statuses:WaitForChild("Health")
	if Effect and Additive then
		local AddedHealth = math.round(Additive * MaxHealth)
		Effect:SetAttribute("Duration", Duration)
		
		if Effect:GetAttribute("Addition") < AddedHealth then
			Effect:SetAttribute("Addition", AddedHealth)
		end
	end

	-- Heal percentage of health
	local Percentage = Properties.Percentage
	if Percentage then
		local Health = Humanoid.MaxHealth * Percentage
		Humanoid.Health = math.clamp(Humanoid.Health + Health, 0, Humanoid.MaxHealth)
	end
end

--[[
	Poison — slow DoT with a green tint. Longer duration than Fire, lower per-tick
	damage. Kill effect turns the mob dark green and glossy.
	Properties:
	  Ticks         number   damage tick count
	  Delay         number   seconds between ticks
	  Damage        number   flat damage per tick — required for isDamaging check
	  Proportionate boolean  if true, damage = Damage × player's best weapon DPS

	Example ItemConfig Suite:
	  Suite = {"Poison", {
	      Projectile    = "Arrow",
	      Velocity      = 150,
	      Acceleration  = Vector3.new(0, -workspace.Gravity/8, 0),
	      Damage        = 1,
	      Proportionate = false,
	      Ticks         = 6,
	      Delay         = 1.0,
	  }},
	  Throwable = true,
]]
function Spells:Poison(Player, Spell, MobInstance, Properties)
	if not MobInstance then return end
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	local key = Player.UserId .. "_" .. tostring(MobInstance)
	if CurrentlyAffected[key] then return end
	CurrentlyAffected[key] = os.clock()

	local TotalTime = Properties.Delay * Properties.Ticks
	task.delay(TotalTime, function()
		CurrentlyAffected[key] = nil
	end)

	-- Green tint for duration
	local origColors = {}
	for _, obj in MobInstance:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			origColors[obj] = obj.Color
			obj.Color = Color3.fromRGB(80, 185, 80)
		end
	end
	task.delay(TotalTime, function()
		for obj, orig in origColors do
			if obj and obj.Parent then obj.Color = orig end
		end
	end)

	for Iteration = 1, Properties.Ticks do
		DamageLib.CallDamage(Player, MobInstance, nil, "Spell", Spell)
		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then Object.Transparency = 0 end
				Object.Color       = Color3.fromRGB(30, 90, 30)
				Object.Material    = Enum.Material.SmoothPlastic
				Object.Reflectance = 0.15
			end)
			break
		end
		task.wait(Properties.Delay)
	end
end

--[[
	Shock — rapid bursts of lightning damage with a WalkSpeed slow per hit.
	Kill effect chars the mob black.
	Properties:
	  Ticks         number   damage tick count
	  Delay         number   seconds between ticks
	  SlowAmount    number   WalkSpeed penalty applied for the duration
	  Damage        number   flat damage per tick — required for isDamaging check
	  Proportionate boolean  if true, damage = Damage × player's best weapon DPS

	Example ItemConfig Suite:
	  Suite = {"Shock", {
	      Projectile    = "Cannonball",
	      Velocity      = 250,
	      Acceleration  = Vector3.new(0, -workspace.Gravity/12, 0),
	      Damage        = 1,
	      Proportionate = false,
	      Ticks         = 5,
	      Delay         = 0.25,
	      SlowAmount    = -8,
	  }},
	  Throwable = true,
]]
function Spells:Shock(Player, Spell, MobInstance, Properties)
	if not MobInstance then return end
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	local key = Player.UserId .. "_" .. tostring(MobInstance)
	if CurrentlyAffected[key] then return end
	CurrentlyAffected[key] = os.clock()

	local TotalTime = Properties.Delay * Properties.Ticks
	task.delay(TotalTime, function()
		CurrentlyAffected[key] = nil
	end)

	local WalkSpeed = Enemy:FindFirstChild("WalkSpeed")
	local slow = Properties.SlowAmount or -8
	if WalkSpeed then WalkSpeed:SetAttribute("ShockSpell", slow) end

	task.delay(TotalTime, function()
		if WalkSpeed and WalkSpeed.Parent then
			WalkSpeed:SetAttribute("ShockSpell", nil)
		end
	end)

	for Iteration = 1, Properties.Ticks do
		-- Flash yellow-white on each tick
		for _, obj in MobInstance:GetDescendants() do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Color = Color3.fromRGB(255, 240, 120)
			end
		end
		RunService.Heartbeat:Wait()
		for _, obj in MobInstance:GetDescendants() do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Color = Color3.fromRGB(180, 180, 180)
			end
		end

		DamageLib.CallDamage(Player, MobInstance, nil, "Spell", Spell)
		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then Object.Transparency = 0 end
				Object.Color       = Color3.fromRGB(20, 20, 20)
				Object.Material    = Enum.Material.SmoothPlastic
				Object.Reflectance = 0
			end)
			break
		end
		task.wait(Properties.Delay)
	end
end

--[[
	Shield — self-buff. Temporarily boosts the player's Defense via Statuses.
	Non-targeting (no Damage field).
	Properties:
	  Additive  number  fraction of current Defense added as a bonus
	  Duration  number  seconds the shield lasts

	Example ItemConfig Suite:
	  Suite = {"Shield", {
	      Additive = 0.25,
	      Duration = 6,
	  }},
	  Throwable = false,
]]
function Spells:Shield(Player, Spell, _, Properties)
	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid")
	if not Humanoid then return end

	local Additive = Properties.Additive or 0.25
	local Duration = Properties.Duration or 6

	-- Read current total Defense (additive bucket)
	local Statistics = Humanoid:FindFirstChild("Statistics")
	local DefenseSub = Statistics and Statistics:FindFirstChild("Defense")
	local currentDef = 0
	if DefenseSub then
		for _, v in DefenseSub:GetAttributes() do
			currentDef += v
		end
	end

	local Statuses = Player:FindFirstChild("Statuses")
	local Effect   = Statuses and Statuses:FindFirstChild("Defense")
	if Effect then
		local bonus = math.round(Additive * math.max(currentDef, 1))
		Effect:SetAttribute("Duration", Duration)
		if (Effect:GetAttribute("Addition") or 0) < bonus then
			Effect:SetAttribute("Addition", bonus)
		end
	end

	-- Visual: player briefly shimmers gold
	local origColors = {}
	for _, obj in Character:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			origColors[obj] = obj.Color
			obj.Color = Color3.fromRGB(255, 210, 80)
		end
	end
	task.delay(0.3, function()
		for obj, orig in origColors do
			if obj and obj.Parent then obj.Color = orig end
		end
	end)
end

--[[
	Drain — leeches health from the mob to the player each tick.
	Damages the mob and heals the caster by HealFactor of damage dealt.
	Properties:
	  Ticks         number   damage tick count
	  Delay         number   seconds between ticks
	  Damage        number   flat damage per tick — required for isDamaging check
	  Proportionate boolean  if true, damage = Damage × player's best weapon DPS
	  HealFactor    number   fraction of damage dealt returned as healing

	Example ItemConfig Suite:
	  Suite = {"Drain", {
	      Projectile    = "Arrow",
	      Velocity      = 140,
	      Acceleration  = Vector3.new(0, -workspace.Gravity/6, 0),
	      Damage        = 1,
	      Proportionate = false,
	      Ticks         = 4,
	      Delay         = 0.6,
	      HealFactor    = 0.5,
	  }},
	  Throwable = true,
]]
function Spells:Drain(Player, Spell, MobInstance, Properties)
	if not MobInstance then return end
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	local key = Player.UserId .. "_" .. tostring(MobInstance)
	if CurrentlyAffected[key] then return end
	CurrentlyAffected[key] = os.clock()

	local TotalTime  = Properties.Delay * Properties.Ticks
	local HealFactor = Properties.HealFactor or 0.5

	task.delay(TotalTime, function()
		CurrentlyAffected[key] = nil
	end)

	-- Purple tint on mob for duration
	local origColors = {}
	for _, obj in MobInstance:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			origColors[obj] = obj.Color
			obj.Color = Color3.fromRGB(140, 60, 200)
		end
	end
	task.delay(TotalTime, function()
		for obj, orig in origColors do
			if obj and obj.Parent then obj.Color = orig end
		end
	end)

	local Character = Player.Character
	local Humanoid  = Character and Character:FindFirstChild("Humanoid")

	for Iteration = 1, Properties.Ticks do
		local hpBefore = Enemy.Health
		DamageLib.CallDamage(Player, MobInstance, nil, "Spell", Spell)
		local dealt = math.max(0, hpBefore - Enemy.Health)

		-- Heal player proportional to damage dealt
		if Humanoid and Humanoid.Health > 0 and dealt > 0 then
			local heal = math.round(dealt * HealFactor)
			Humanoid.Health = math.clamp(Humanoid.Health + heal, 0, Humanoid.MaxHealth)
		end

		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then Object.Transparency = 0 end
				Object.Color       = Color3.fromRGB(60, 0, 80)
				Object.Material    = Enum.Material.SmoothPlastic
				Object.Reflectance = 0.05
			end)
			break
		end
		task.wait(Properties.Delay)
	end
end

return Spells