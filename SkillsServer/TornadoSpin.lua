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
	WeaponLock:Lock(Player, 3.0)
	
	for i = 1, 6 do
		task.delay((i-1)*0.5, function()
			if not Torso then return end
			local Origin = Torso.Position
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - Origin).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						-- Pull in slightly
						MobTorso.CFrame = CFrame.new(MobTorso.Position, Origin) * CFrame.new(0,0,-2)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15,
							Tool = Tool,
						})
					end)
				end
			end
			
			if i == 6 then
				-- Final explosion
				task.delay(0.5, function()
					if not Torso then return end
					local FinalOrigin = Torso.Position
					for _, MobInstance in CollectionService:GetTagged("Mob") do
						local MobTorso = MobInstance:FindFirstChild("Torso")
						if MobTorso and (MobTorso.Position - FinalOrigin).Magnitude < 20 then
							task.spawn(function()
								RequestStunMob(MobInstance, 1)
								Knockback:Activate(MobTorso, 30, FinalOrigin, MobTorso.Position)
								Damage:DamageMobSkill(Player, MobList[MobInstance], {
									Damage = 40,
									Tool = Tool,
									SkillScaling = { ["Strength"] = { Type = "Attributes", Additive = 0.8, Cap = 200 } },
								})
							end)
						end
					end
				end)
			end
		end)
	end
end
return Keybind
