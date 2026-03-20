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
	WeaponLock:Lock(Player, 2.5)

	local HitboxPos = Torso.Position + Torso.CFrame.LookVector * 10
	local GrabbedMob = nil
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso and (MobTorso.Position - HitboxPos).Magnitude < 10 then
			GrabbedMob = MobInstance
			break
		end
	end
	
	if GrabbedMob then
		RequestStunMob(GrabbedMob, 2.5)
		local MobTorso = GrabbedMob:FindFirstChild("Torso")
		
		for i = 1, 2 do
			task.delay(i*0.5, function()
				if MobTorso then
					MobTorso.CFrame = Torso.CFrame * CFrame.new(0, -5, -5)
					Damage:DamageMobSkill(Player, MobList[GrabbedMob], {Damage = 25, Tool = Tool})
				end
			end)
		end
		
		task.delay(1.5, function()
			if MobTorso then
				Knockback:Activate(MobTorso, 50, Torso.Position, MobTorso.Position)
				Damage:DamageMobSkill(Player, MobList[GrabbedMob], {
					Damage = 80,
					Tool = Tool,
					SkillScaling = { ["Strength"] = { Type = "Attributes", Additive = 2.0, Cap = 500 } },
				})
			end
		end)
	end
end
return Keybind
