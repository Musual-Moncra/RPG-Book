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
	WeaponLock:Lock(Player, 2)
	
	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 15)

	-- 3 Punches
	for i = 1, 3 do
		task.delay((i-1)*0.2, function()
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 10 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15,
							Tool = Tool,
						})
					end)
				end
			end
		end)
	end

	-- Meteor Strike
	task.delay(1.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 30 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(MobTorso, 15, TargetPos, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 90,
						Tool = Tool,
						SkillScaling = {
							["Strength"] = { Type = "Attributes", Additive = 1.5, Cap = 300 },
						},
					})
				end)
			end
		end
	end)
end
return Keybind
