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
	
	task.delay(1, function()
		for i = 1, 5 do
			task.delay((i-1)*0.2, function()
				if not Character or not Character:FindFirstChild("Torso") then return end
				local Origin = Character.Torso.Position
				
				local ClosestMob = nil
				local MinDist = 100
				for _, MobInstance in CollectionService:GetTagged("Mob") do
					local MobTorso = MobInstance:FindFirstChild("Torso")
					if MobTorso then
						local dist = (MobTorso.Position - Origin).Magnitude
						if dist < MinDist then
							MinDist = dist
							ClosestMob = MobInstance
						end
					end
				end
				
				if ClosestMob then
					task.spawn(function()
						RequestStunMob(ClosestMob, 0.5)
						Damage:DamageMobSkill(Player, MobList[ClosestMob], {
							Damage = 25,
							Tool = Tool,
							SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 150 } },
						})
					end)
				end
			end)
		end
	end)
end
return Keybind
