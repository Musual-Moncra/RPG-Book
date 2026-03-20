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
	WeaponLock:Lock(Player, 6)
	
	task.spawn(function()
		-- Loop for 5 seconds (10 ticks)
		for i = 1, 10 do
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso then
					local diff = Torso.Position - Position
					if diff.Magnitude < 40 then
						task.spawn(function()
							-- Keep them stunned
							RequestStunMob(MobInstance, 1)
							
							-- Pull towards center via Knockback mechanism
							-- Origin is "behind" the mob relative to the center, so it pushes them into the center
							local pushOrigin = Torso.Position + diff.Unit * 10
							Knockback:Activate(Torso, 10, pushOrigin, Torso.Position)
							
							-- Minor tick damage
							Damage:DamageMobSkill(Player, MobList[MobInstance], {
								Damage = 1, 
								Tool = Tool,
								SkillScaling = {},
							})
							pcall(function()
								Torso:SetNetworkOwner(Player)
							end)
						end)
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

return Keybind
