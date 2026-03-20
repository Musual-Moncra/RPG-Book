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

local function DistToSegment(p, a, b)
    local ab = b - a
    local ap = p - a
    local t = ap:Dot(ab) / ab:Dot(ab)
    t = math.clamp(t, 0, 1)
    local closest = a + t * ab
    return (p - closest).Magnitude
end

--------------------------------------------------------------------------------
function Keybind:OnActivated(Player, Snapshot)

end

function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local originPos = Character.HumanoidRootPart.Position
	local lookVec = Character.HumanoidRootPart.CFrame.LookVector
	
	-- Dash 40 studs forward safely
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character, workspace:FindFirstChild("Mobs"), workspace:FindFirstChild("Temporary")}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayHit = workspace:Raycast(originPos, lookVec * 40, rayParams)
	local targetPos = rayHit and rayHit.Position or (originPos + lookVec * 40)
	
	local Tool = Snapshot and Snapshot.Tool

	WeaponLock:Lock(Player, 2)

	-- Teleport Player
	Character:PivotTo(CFrame.new(targetPos, targetPos + lookVec))

	task.spawn(function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso then
				local distToDash = DistToSegment(Torso.Position, originPos, targetPos)
				
				if distToDash < 8 then
					task.spawn(function()
						-- Minor stun to interrupt their action
						RequestStunMob(MobInstance, 1.0)
						
						-- Knockback slightly away from the path
						local pathDir = (targetPos - originPos).Unit
						local rightPath = pathDir:Cross(Vector3.new(0, 1, 0)).Unit
						local pushSide = rightPath * ((Torso.Position - originPos):Dot(rightPath) > 0 and 1 or -1)
						local throwTarget = Torso.Position + pushSide * 20
						
						Knockback:Activate(Torso, 20, Torso.Position, throwTarget)
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 50, -- Massive Burst
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 1.0, Cap = 300 },
								["Strength"] = { Type = "Attributes", Additive = 0.5, Cap = 200 },
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
