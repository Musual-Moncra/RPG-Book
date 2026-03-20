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
	WeaponLock:Lock(Player, 0.5)
	
	local TargetPos = Torso.Position + Torso.CFrame.LookVector * 20
	
	-- Loop check for mobs entering the trap over 10 seconds
	local EndTime = os.clock() + 10
	local HitMobs = {}
	
	task.spawn(function()
		while os.clock() < EndTime do
			task.wait(0.5)
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				if not HitMobs[MobInstance] then
					local MobTorso = MobInstance:FindFirstChild("Torso")
					if MobTorso and (MobTorso.Position - TargetPos).Magnitude < 15 then
						HitMobs[MobInstance] = true
						task.spawn(function()
							RequestStunMob(MobInstance, 3)
							Damage:DamageMobSkill(Player, MobList[MobInstance], {
								Damage = 20,
								Tool = Tool,
								SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 0.8, Cap = 150 } },
							})
						end)
					end
				end
			end
		end
	end)
end
return Keybind
