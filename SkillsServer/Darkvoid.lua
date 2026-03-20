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

	-- Prevent weapon switching for 5 seconds while the skill resolves
	WeaponLock:Lock(Player, 5)

	task.delay(1.35, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso and (Torso.Position - Position).Magnitude < 15 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(Torso, 5, Position, Torso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 25,
						Tool = Tool,

						-- SkillScaling: scales the base Damage using any NumberValue in pData.
						-- Type = the folder name inside pData. Key = the value name inside that folder.
						--
						-- Available folders & their values:
						--   "Stats"       --> Level, XP, Gold, Kills
						--   "Attributes"  --> Strength, Dexterity, Constitution, etc (see GameConfig.Attributes)
						--
						-- Formula: FinalDamage = (BaseDamage * (1 + sum of Multipliers)) + sum of Additives
						-- Each entry is capped at Cap points before it stops scaling.
						--
						-- Examples:
						--   Scale off Kills:    ["Kills"]    = { Type = "Stats",      Multiplier = 0.001, Cap = 5000 }
						--   Scale off Strength: ["Strength"] = { Type = "Attributes", Additive = 0.5,    Cap = 200  }
						SkillScaling = {
							-- ["Kills"]    = { Type = "Stats",      Multiplier = 0.001, Cap = 5000 },
							["Strength"] = { Type = "Attributes", Additive = 0.5,     Cap = 200  },
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
