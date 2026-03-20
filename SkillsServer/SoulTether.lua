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

	local Tool = Snapshot and Snapshot.Tool

	WeaponLock:Lock(Player, 5)

	-- Find up to 5 targets
	local targets = {}
	local originPos = Character.HumanoidRootPart.Position
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local Torso = MobInstance:FindFirstChild("Torso")
		if Torso and (Torso.Position - originPos).Magnitude < 30 then
			table.insert(targets, MobInstance)
			if #targets >= 5 then break end
		end
	end

	-- Tick loop for 4 seconds (8 ticks)
	task.spawn(function()
		for i = 1, 8 do
			if not Character or not Character:FindFirstChild("HumanoidRootPart") then break end
			local currentPos = Character.HumanoidRootPart.Position
			
			for _, MobInstance in targets do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso then
					task.spawn(function()
						-- Stun briefly to simulate being tethered
						RequestStunMob(MobInstance, 0.6)
						
						-- Pull towards the player slightly (Origin is "behind" the mob to push it to player)
						local diff = Torso.Position - currentPos
						local pushOrigin = Torso.Position + diff.Unit * 10
						Knockback:Activate(Torso, 10, pushOrigin, Torso.Position)
						
						-- DoT
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 10, 
							Tool = Tool,
							SkillScaling = {
								["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
								["Constitution"] = { Type = "Attributes", Additive = 0.3, Cap = 150 },
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
