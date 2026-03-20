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
	WeaponLock:Lock(Player, 1.5)
	
	local Origin = Torso.Position
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso and (MobTorso.Position - Origin).Magnitude < 25 then
			task.spawn(function()
				-- Heavy Long Stun (Time Freeze effect on mob physics)
				RequestStunMob(MobInstance, 5)
				
				-- Deal tick damage over 5 seconds
				for i = 1, 5 do
					if MobInstance and MobInstance.Parent then
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15,
							Tool = Tool,
							SkillScaling = {
								["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 150 },
							},
						})
					end
					task.wait(1)
				end
			end)
		end
	end
end
return Keybind
