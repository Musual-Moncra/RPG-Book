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
	
	local Center = Torso.Position
	
	for i = 1, 5 do
		task.delay(i, function()
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - Center).Magnitude < 30 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 35,
							Tool = Tool,
							SkillScaling = {
								["Intelligence"] = { Type = "Attributes", Additive = 0.8, Cap = 200 },
							},
						})
					end)
				end
			end
		end)
	end
end
return Keybind
