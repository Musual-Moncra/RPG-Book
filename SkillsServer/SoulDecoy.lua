-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Knockback = require(ServerStorage.Modules.Server.Knockback)
local Damage = require(ServerStorage.Modules.Libraries.Damage)
local MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}

function Keybind:OnActivated(Player, Snapshot) end

function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	local Tool = Snapshot and Snapshot.Tool

	if not Torso then return end

	-- Decoy Origin
	local Origin = Torso.Position
	WeaponLock:Lock(Player, 0.5)
	
	-- Back jump player
	local Velocity = Instance.new("BodyVelocity")
	Velocity.MaxForce = Vector3.new(100000, 100000, 100000)
	Velocity.Velocity = Torso.CFrame.LookVector * -50 + Vector3.new(0, 30, 0)
	Velocity.Parent = Torso
	local Debris = game:GetService("Debris")
	Debris:AddItem(Velocity, 0.2)

	task.delay(5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - Origin).Magnitude < 15 then
				task.spawn(function()
					RequestStunMob(MobInstance, 1)
					Knockback:Activate(MobTorso, 10, Origin, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 40,
						Tool = Tool,
						SkillScaling = {
							["Intelligence"] = { Type = "Attributes", Additive = 1.0, Cap = 150 },
						},
					})
				end)
			end
		end
		
		-- Heal Player slightly
		local Humanoid = Character:FindFirstChild("Humanoid")
		if Humanoid then
			Humanoid.Health = math.clamp(Humanoid.Health + (Humanoid.MaxHealth * 0.1), 0, Humanoid.MaxHealth)
		end
	end)
end
return Keybind
