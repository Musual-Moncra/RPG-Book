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

	local ClosestMob = nil
	local MinDist = 100
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
		WeaponLock:Lock(Player, 1.0)
		local OriginalCFrame = Character:GetPivot()
		local TargetCFrame = ClosestMob:GetPivot() * CFrame.new(0, 0, 5)
		
		Character:PivotTo(TargetCFrame)
		
		task.delay(0.5, function()
			task.spawn(function()
				RequestStunMob(ClosestMob, 1)
				Damage:DamageMobSkill(Player, MobList[ClosestMob], {
					Damage = 60,
					Tool = Tool,
					SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 1.5, Cap = 200 } },
				})
			end)
			Character:PivotTo(OriginalCFrame)
		end)
	end
end
return Keybind
