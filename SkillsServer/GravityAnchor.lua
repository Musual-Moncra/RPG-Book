-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Damage = require(ServerStorage.Modules.Libraries.Damage)
local MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}
function Keybind:OnActivated(Player, Snapshot) end
function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	local Tool = Snapshot and Snapshot.Tool

	if not Torso then return end
	WeaponLock:Lock(Player, 1.0)
	local Origin = Torso.Position
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso and (MobTorso.Position - Origin).Magnitude < 75 then
			task.spawn(function()
				-- Heavy Stun (Grounded)
				RequestStunMob(MobInstance, 3)
				
				-- Pull down
				local RaycastParams = RaycastParams.new()
				RaycastParams.FilterDescendantsInstances = {workspace:FindFirstChild("Characters"), workspace:FindFirstChild("Mobs")}
				RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

				local RayResult = workspace:Raycast(MobTorso.Position, Vector3.new(0, -100, 0), RaycastParams)
				if RayResult then
					MobTorso.CFrame = CFrame.new(RayResult.Position + Vector3.new(0, 5, 0))
				end
				
				Damage:DamageMobSkill(Player, MobList[MobInstance], {
					Damage = 30,
					Tool = Tool,
				})
			end)
		end
	end
end
return Keybind
