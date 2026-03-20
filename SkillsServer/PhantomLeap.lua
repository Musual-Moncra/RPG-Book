-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

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

	WeaponLock:Lock(Player, 1.5)

	-- Launch player upwards
	local Velocity = Instance.new("BodyVelocity")
	Velocity.MaxForce = Vector3.new(0, 100000, 0)
	Velocity.Velocity = Vector3.new(0, 80, 0)
	Velocity.Parent = Torso
	Debris:AddItem(Velocity, 0.2)

	task.delay(0.8, function()
		if not Torso then return end
		local LandPos = Torso.Position
		
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - LandPos).Magnitude < 25 then
				task.spawn(function()
					RequestStunMob(MobInstance, 1.5)
					Knockback:Activate(MobTorso, 10, LandPos, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 40,
						Tool = Tool,
						SkillScaling = {
							["Strength"] = { Type = "Attributes", Additive = 1.0, Cap = 300 },
						},
					})
					pcall(function() MobTorso:SetNetworkOwner(Player) end)
				end)
			end
		end
	end)
end
return Keybind
