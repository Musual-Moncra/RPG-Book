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
	WeaponLock:Lock(Player, 2.0)
	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 30)
	
	task.delay(1.0, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 30 then
				task.spawn(function()
					RequestStunMob(MobInstance, 3)
					-- Heavy Knockback UPward
					Knockback:Activate(MobTorso, 50, TargetPos - Vector3.new(0, 15, 0), MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 180,
						Tool = Tool,
						SkillScaling = {
							["Intelligence"] = { Type = "Attributes", Additive = 3.0, Cap = 500 },
							["Strength"] = { Type = "Attributes", Additive = 1.0, Cap = 200 }
						},
					})
				end)
			end
		end
	end)
end
return Keybind
