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
	WeaponLock:Lock(Player, 1.5)
	
	for i = 1, 4 do
		task.delay((i - 1) * 0.3, function()
			if not Character or not Character:FindFirstChild("Torso") then return end
			local Origin = Character.Torso.Position
			
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - Origin).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						Knockback:Activate(MobTorso, 5, Origin, MobTorso.Position)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 25,
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.8, Cap = 200 },
							},
						})
					end)
				end
			end
		end)
	end
end
return Keybind
