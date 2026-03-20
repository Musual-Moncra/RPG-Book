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
	WeaponLock:Lock(Player, 2.0)
	
	local Origin = Torso.Position
	local Forward = Torso.CFrame.LookVector
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso then
			local toMob = MobTorso.Position - Origin
			local projection = toMob:Dot(Forward)
			
			if projection > 0 and projection < 200 then
				local closestPoint = Origin + (Forward * projection)
				local distToLine = (MobTorso.Position - closestPoint).Magnitude
				
				if distToLine < 10 then
					task.spawn(function()
						RequestStunMob(MobInstance, 1)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 130,
							Tool = Tool,
							SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 2.0, Cap = 500 } },
						})
					end)
				end
			end
		end
	end
end
return Keybind
