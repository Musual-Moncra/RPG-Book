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
	WeaponLock:Lock(Player, 3)

	-- Multiple hits in a short span
	for i = 1, 3 do
		task.delay(0.2 + (i * 0.3), function()
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso and (Torso.Position - Position).Magnitude < 15 then
					task.spawn(function()
						-- Minor stun per hit to keep them locked
						RequestStunMob(MobInstance, 1)
						-- Knockback slightly towards the final blow
						local knockbackDir = (i == 3) and 20 or 2
						Knockback:Activate(Torso, knockbackDir, Position, Torso.Position)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15, -- 3 hits totaling 45 base
							Tool = Tool,
							SkillScaling = {
								["Strength"] = { Type = "Attributes", Additive = 0.5, Cap = 250 },
								["Dexterity"] = { Type = "Attributes", Additive = 0.3, Cap = 150 },
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
end

return Keybind
