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
	if not Torso then return end

	local ClosestMob = nil
	local MinDist = 60
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso then
			local dist = (MobTorso.Position - Torso.Position).Magnitude
			if dist < MinDist then
				MinDist = dist
				ClosestMob = MobInstance
			end
		end
	end
	
	if ClosestMob then
		local MobTorso = ClosestMob:FindFirstChild("Torso")
		if MobTorso then
			local MyCFrame = Character:GetPivot()
			local MobCFrame = ClosestMob:GetPivot()
			
			Character:PivotTo(MobCFrame)
			ClosestMob:PivotTo(MyCFrame)
			
			task.spawn(function()
				RequestStunMob(ClosestMob, 2)
				Damage:DamageMobSkill(Player, MobList[ClosestMob], {
					Damage = 10,
					Tool = Snapshot.Tool,
					SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 1.0, Cap = 150 } },
				})
			end)
		end
	end
end
return Keybind
