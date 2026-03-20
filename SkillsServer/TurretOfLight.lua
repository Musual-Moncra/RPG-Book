-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
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
	
	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 15)

	task.spawn(function()
		for tick = 1, 20 do
			task.wait(0.5) -- Shoots every 0.5s for 10s
			
			local ClosestMob = nil
			local MinDist = 60
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso then
					local dist = (MobTorso.Position - TargetPos).Magnitude
					if dist < MinDist then
						MinDist = dist
						ClosestMob = MobInstance
					end
				end
			end
			
			if ClosestMob then
				task.spawn(function()
					Damage:DamageMobSkill(Player, MobList[ClosestMob], {
						Damage = 20,
						Tool = Tool,
						SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 150 } }
					})
				end)
			end
		end
	end)
end
return Keybind
