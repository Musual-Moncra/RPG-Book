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

	-- Prevent weapon switching
	WeaponLock:Lock(Player, 4)

	local mobsHit = 0
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local Torso = MobInstance:FindFirstChild("Torso")
		if Torso and (Torso.Position - Position).Magnitude < 50 then
			mobsHit += 1
			-- Stagger the meteor impacts slightly for effect
			task.delay(0.5 + (math.random() * 0.5), function()
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(Torso, 10, Torso.Position + Vector3.new(0, 10, 0), Torso.Position)
					
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 20, 
						Tool = Tool,
						SkillScaling = {
							["Dexterity"] = { Type = "Attributes", Additive = 0.4, Cap = 200 },
							["Constitution"] = { Type = "Attributes", Additive = 0.2, Cap = 150 },
						},
					})
					pcall(function()
						Torso:SetNetworkOwner(Player)
					end)
				end)
			end)
		end
	end
end

return Keybind
