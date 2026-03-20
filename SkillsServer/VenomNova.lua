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

	WeaponLock:Lock(Player, 2)

	task.spawn(function()
		-- 5 seconds duration, ticking every 0.5s = 10 ticks total
		for i = 1, 10 do
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso and (Torso.Position - Position).Magnitude < 30 then
					task.spawn(function()
						-- Micro stun prevents them from escaping easily
						RequestStunMob(MobInstance, 0.6)
						
						-- No knockback, just pure lingering damage
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 8, -- Ticks very fast, so lower Base damage
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
								["Constitution"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
							},
						})
						pcall(function() Torso:SetNetworkOwner(Player) end)
					end)
				end
			end
			task.wait(0.5)
		end
	end)
end

return Keybind
