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
	local originPosition = Character.HumanoidRootPart.Position
	local lookVector = Character.HumanoidRootPart.CFrame.LookVector

	WeaponLock:Lock(Player, 3)

	task.delay(0.3, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso then
				local toMob = (Torso.Position - originPosition)
				local dist = toMob.Magnitude
				local dot = toMob.Unit:Dot(lookVector)
				
				-- If within 60 studs and in a ~45 degree cone in front
				if dist < 60 and dot > 0.85 then
					task.spawn(function()
						RequestStunMob(MobInstance, 3)
						
						-- Throw highly into the air
						local airTarget = Torso.Position + Vector3.new(lookVector.X * 10, 50, lookVector.Z * 10)
						local originPush = originPosition
						Knockback:Activate(Torso, 40, originPush, airTarget)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 40, 
							Tool = Tool,
							SkillScaling = {
								["Strength"] = { Type = "Attributes", Additive = 0.8, Cap = 250 },
								["Constitution"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
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
