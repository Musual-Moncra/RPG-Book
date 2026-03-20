-- [SERVER]
--> References
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
--> Dependencies
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
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

	WeaponLock:Lock(Player, 4)

	-- Find all targets initially in the 35 stud radius
	local targets = {}
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local Torso = MobInstance:FindFirstChild("Torso")
		if Torso and (Torso.Position - Position).Magnitude <= 35 then
			table.insert(targets, MobInstance)
		end
	end

	-- Lock them down and deal DoT for 4 seconds (8 ticks)
	task.spawn(function()
		for i = 1, 8 do
			for _, MobInstance in targets do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso then
					task.spawn(function()
						-- Continuous stun to keep them locked
						RequestStunMob(MobInstance, 0.6)
						
						-- Notice: NO KNOCKBACK. This is a pure root/entangle.
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 12, 
							Tool = Tool,
							SkillScaling = {
								["Constitution"] = { Type = "Attributes", Additive = 0.5, Cap = 150 },
								["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 150 },
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
