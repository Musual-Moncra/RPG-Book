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

	WeaponLock:Lock(Player, 3)

	task.spawn(function()
		local hitMobs = {}
		local maxBounces = 4
		local currentPos = Position
		
		for bounce = 1, maxBounces do
			local closestMob = nil
			local closestDist = 25
			
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				if hitMobs[MobInstance] then continue end
				
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso then
					local dist = (Torso.Position - currentPos).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestMob = MobInstance
					end
				end
			end
			
			if not closestMob then break end
			
			local Torso = closestMob:FindFirstChild("Torso")
			hitMobs[closestMob] = true
			currentPos = Torso.Position
			
			RequestStunMob(closestMob, 1.5)
			Knockback:Activate(Torso, 5, Torso.Position + Vector3.new(0, 5, 0), Torso.Position)
			Damage:DamageMobSkill(Player, MobList[closestMob], {
				Damage = 25, 
				Tool = Tool,
				SkillScaling = {
					["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
					["Dexterity"] = { Type = "Attributes", Additive = 0.3, Cap = 150 },
				},
			})
			pcall(function() Torso:SetNetworkOwner(Player) end)
			
			task.wait(0.2)
		end
	end)
end

return Keybind
