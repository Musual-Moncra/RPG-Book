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
	local lookVec = Character.HumanoidRootPart.CFrame.LookVector
	local rightVec = lookVec:Cross(Vector3.new(0, 1, 0)).Unit
	
	-- Wall is placed 20 studs forward
	local wallCenter = originPos + lookVec * 20
	local Tool = Snapshot and Snapshot.Tool

	WeaponLock:Lock(Player, 3)

	task.delay(0.4, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso then
				local offset = Torso.Position - wallCenter
				-- Check if inside the wall's box (Length 40, Depth 10)
				local dotForward = math.abs(offset:Dot(lookVec))
				local dotRight = math.abs(offset:Dot(rightVec))
				
				if dotForward < 5 and dotRight < 20 then
					task.spawn(function()
						-- Heavy Freeze
						RequestStunMob(MobInstance, 4.0)
						
						-- Knockback straight up
						local upwardTarget = Torso.Position + Vector3.new(0, 15, 0)
						Knockback:Activate(Torso, 15, Torso.Position, upwardTarget)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 35, 
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.8, Cap = 250 },
								["Intelligence"] = { Type = "Attributes", Additive = 0.4, Cap = 150 },
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
