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
	WeaponLock:Lock(Player, 1.0)
	
	local Forward = Torso.CFrame.LookVector
	local Origin = Torso.Position
	
	-- Damage along the line 50 studs
	task.delay(0.2, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso then
				-- Math: Line vs Point distance
				local toMob = MobTorso.Position - Origin
				local projection = toMob:Dot(Forward)
				
				if projection > 0 and projection < 50 then
					local closestPoint = Origin + (Forward * projection)
					local distToLine = (MobTorso.Position - closestPoint).Magnitude
					
					if distToLine < 10 then
						task.spawn(function()
							RequestStunMob(MobInstance, 1.5)
							Knockback:Activate(MobTorso, 30, closestPoint - Vector3.new(0, 10, 0), MobTorso.Position)
							Damage:DamageMobSkill(Player, MobList[MobInstance], {
								Damage = 110,
								Tool = Tool,
								SkillScaling = {
									["Strength"] = { Type = "Attributes", Additive = 1.2, Cap = 300 },
								},
							})
						end)
					end
				end
			end
		end
	end)
end
return Keybind
