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

	WeaponLock:Lock(Player, 4.5)

	-- Seeded randomness to roughly match client visuals perfectly without networking
	local Seed = math.floor(Position.X + Position.Y + Position.Z)
	local RNG = Random.new(Seed)

	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.4)
			
			local offsetX = RNG:NextNumber(-30, 30)
			local offsetZ = RNG:NextNumber(-30, 30)
			local strikePos = Position + Vector3.new(offsetX, 0, offsetZ)
			
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso and (Torso.Position - strikePos).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 1)
						Knockback:Activate(Torso, 10, strikePos, Torso.Position)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 25, 
							Tool = Tool,
							SkillScaling = {
								["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
							},
						})
						pcall(function() Torso:SetNetworkOwner(Player) end)
					end)
				end
			end
		end
	end)
end

return Keybind
