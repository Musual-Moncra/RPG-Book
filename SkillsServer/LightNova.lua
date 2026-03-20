-- [SERVER]
--> References
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
--> Dependencies
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Knockback = require(ServerStorage.Modules.Server.Knockback)
local Damage = require(ServerStorage.Modules.Libraries.Damage)
local MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)
--> Variables
local Keybind = {}
--------------------------------------------------------------------------------
function Keybind:OnActivated(Player, Snapshot)

end

function Keybind:OnLetGo(Player, Snapshot)
	if not Snapshot or not Snapshot.Position then
		return
	end

	local Position = Snapshot.Position
	local Tool = Snapshot.Tool

	-- Prevent weapon switching for 4 seconds while the skill resolves
	WeaponLock:Lock(Player, 4)

	task.delay(1.2, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso and (Torso.Position - Position).Magnitude < 18 then
				task.spawn(function()
					RequestStunMob(MobInstance, 3)
					Knockback:Activate(Torso, 15, Position, Torso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 45,
						Tool = Tool,

						SkillScaling = {
							["Constitution"] = { Type = "Attributes", Additive = 0.8, Cap = 150 },
							["Strength"] = { Type = "Attributes", Additive = 0.4, Cap = 200 },
						},
					})
					pcall(function()
						Torso:SetNetworkOwner(Player)
					end)
				end)
			end
		end
	end)
end

return Keybind
