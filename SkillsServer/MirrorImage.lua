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
	WeaponLock:Lock(Player, 0.5)

	local StartPos = Torso.Position
	
	task.delay(4, function()
		for i = 1, 3 do
			local Angle = math.rad(i * 120)
			local ExplodePos = StartPos + Vector3.new(math.cos(Angle)*20, 0, math.sin(Angle)*20)
			
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - ExplodePos).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 1)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 30,
							Tool = Tool,
							SkillScaling = {
								["Intelligence"] = { Type = "Attributes", Additive = 0.7, Cap = 150 },
							},
						})
					end)
				end
			end
		end
	end)
end
return Keybind
