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
	
	local TargetPos = Torso.Position + Torso.CFrame.LookVector * 25
	
	-- Pull mobs in over 4 seconds
	for i = 1, 8 do
		task.delay((i-1)*0.5, function()
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 40 then
					task.spawn(function()
						RequestStunMob(MobInstance, 1)
						-- Pull to center
						MobTorso.CFrame = CFrame.new(MobTorso.Position, TargetPos) * CFrame.new(0, 0, -3)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 10,
							Tool = Tool,
						})
					end)
				end
			end
		end)
	end

	-- Final explosion
	task.delay(4.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 20 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 120,
						Tool = Tool,
						SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 2.0, Cap = 500 } },
					})
				end)
			end
		end
	end)
end
return Keybind
