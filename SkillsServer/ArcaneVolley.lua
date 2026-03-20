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
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local originPos = Character.HumanoidRootPart.Position
	local Tool = Snapshot and Snapshot.Tool

	WeaponLock:Lock(Player, 2.5)

	-- Find closest target
	local closestMob
	local minMag = 50
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local Torso = MobInstance:FindFirstChild("Torso")
		if Torso then
			local mag = (Torso.Position - originPos).Magnitude
			if mag < minMag then
				minMag = mag
				closestMob = MobInstance
			end
		end
	end

	if not closestMob then return end -- No target found

	-- Rapid fire 10 shots
	task.spawn(function()
		for i = 1, 10 do
			if not closestMob or not closestMob:FindFirstChild("Torso") then break end
			local Torso = closestMob.Torso
			
			-- Stun slightly each hit
			RequestStunMob(closestMob, 0.4)
			
			-- Push them back a tiny bit
			local currentOrigin = Character.HumanoidRootPart.Position
			Knockback:Activate(Torso, 10, currentOrigin, Torso.Position)
			
			Damage:DamageMobSkill(Player, MobList[closestMob], {
				Damage = 8, -- Fast hitting so lower damage per shot
				Tool = Tool,
				SkillScaling = {
					["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
					["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
				},
			})
			pcall(function() Torso:SetNetworkOwner(Player) end)
			
			task.wait(0.2)
		end
	end)
end

return Keybind
