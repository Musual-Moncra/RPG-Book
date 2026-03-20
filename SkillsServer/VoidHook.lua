-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Knockback = require(ServerStorage.Modules.Server.Knockback)
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
	WeaponLock:Lock(Player, 1)

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterDescendantsInstances = {Character, workspace:FindFirstChild("Temporary")}
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local RayResult = workspace:Raycast(Torso.Position, Torso.CFrame.LookVector * 60, RaycastParams)
	local HitPos = RayResult and RayResult.Position or (Torso.Position + Torso.CFrame.LookVector * 60)
	
	-- Grapple to HitPos, leaving 5 studs gap
	local Dest = HitPos - (Torso.CFrame.LookVector * 5)
	Character:PivotTo(CFrame.new(Dest, HitPos))
	
	-- Kick impact around arriving location
	task.delay(0.1, function()
		if not Character or not Character:FindFirstChild("Torso") then return end
		local ArrivePos = Character.Torso.Position
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - ArrivePos).Magnitude < 15 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(MobTorso, 20, ArrivePos, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 45,
						Tool = Tool,
						SkillScaling = {
							["Dexterity"] = { Type = "Attributes", Additive = 1.0, Cap = 200 },
						},
					})
				end)
			end
		end
	end)
end
return Keybind
