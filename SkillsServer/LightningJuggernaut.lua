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
	
	local ClosestMob = nil
	local MinDist = 30
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
		for i = 1, 5 do
			task.delay((i-1)*0.2, function()
				local MobTorso = ClosestMob:FindFirstChild("Torso")
				if MobTorso and Character and Character.PrimaryPart then
					-- Teleport around the mob
					local Angle = math.rad(math.random(0, 360))
					local Offset = Vector3.new(math.cos(Angle)*5, 0, math.sin(Angle)*5)
					Character:PivotTo(CFrame.new(MobTorso.Position + Offset, MobTorso.Position))
					
					task.spawn(function()
						RequestStunMob(ClosestMob, 0.5)
						Damage:DamageMobSkill(Player, MobList[ClosestMob], {
							Damage = 15,
							Tool = Tool,
							SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 150 } },
						})
					end)
				end
			end)
		end
	end
end
return Keybind
