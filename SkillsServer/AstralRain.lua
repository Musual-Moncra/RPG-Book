-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
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
	WeaponLock:Lock(Player, 1.0)
	
	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 25)
	
	for i = 1, 6 do
		task.delay((i - 1) * 0.35, function()
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 18,
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 150 },
							},
						})
					end)
				end
			end
		end)
	end
end
return Keybind
