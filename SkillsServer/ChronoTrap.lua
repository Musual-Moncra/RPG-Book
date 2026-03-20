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

	WeaponLock:Lock(Player, 3.5)

	-- Detonate after 3 seconds
	task.delay(3.0, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso and (Torso.Position - Position).Magnitude < 35 then
				task.spawn(function()
					-- Frozen in time!
					RequestStunMob(MobInstance, 5.0)
					
					-- Huge upward and outward knockback
					local upwardTarget = Torso.Position + (Torso.Position - Position).Unit * 20 + Vector3.new(0, 30, 0)
					Knockback:Activate(Torso, 30, Position, upwardTarget)
					
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 60, -- Massive burst 
						Tool = Tool,
						SkillScaling = {
							["Intelligence"] = { Type = "Attributes", Additive = 1.0, Cap = 300 },
							["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
						},
					})
					pcall(function() Torso:SetNetworkOwner(Player) end)
				end)
			end
		end
	end)
end

return Keybind
