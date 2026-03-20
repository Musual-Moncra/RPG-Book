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

	-- 5 seconds active Aura
	task.spawn(function()
		for i = 1, 10 do
			if not Character or not Character:FindFirstChild("HumanoidRootPart") then break end
			local currentPos = Character.HumanoidRootPart.Position
			
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local Torso = MobInstance:FindFirstChild("Torso")
				if Torso and (Torso.Position - currentPos).Magnitude < 20 then
					task.spawn(function()
						-- Minor stun
						RequestStunMob(MobInstance, 0.5)
						
						-- Knockback outwards
						Knockback:Activate(Torso, 15, currentPos, Torso.Position)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15, 
							Tool = Tool,
							SkillScaling = {
								["Strength"] = { Type = "Attributes", Additive = 0.6, Cap = 250 },
								["Dexterity"] = { Type = "Attributes", Additive = 0.4, Cap = 150 },
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
