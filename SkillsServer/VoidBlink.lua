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

	local Tool = Snapshot.Tool
	local Character = Player.Character

	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	-- Prevent weapon switching
	WeaponLock:Lock(Player, 3)

	task.delay(0.4, function()
		if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
		local originalPos = Character.HumanoidRootPart.Position
		
		-- Random teleport within 30 studs
		local offsetX = math.random(-30, 30)
		local offsetZ = math.random(-30, 30)
		local newPos = originalPos + Vector3.new(offsetX, 5, offsetZ)

		-- Teleport player safely
		Character:PivotTo(CFrame.new(newPos))

		-- Stun and damage at both original and new positions
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso then
				local distToOriginal = (Torso.Position - originalPos).Magnitude
				local distToNew = (Torso.Position - newPos).Magnitude
				
				if distToOriginal < 18 or distToNew < 18 then
					task.spawn(function()
						-- High stun, very low damage
						RequestStunMob(MobInstance, 3)
						Knockback:Activate(Torso, 15, newPos, Torso.Position)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 5,
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 150 },
							},
						})
						pcall(function()
							Torso:SetNetworkOwner(Player)
						end)
					end)
				end
			end
		end
	end)
end

return Keybind
