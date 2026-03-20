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

	WeaponLock:Lock(Player, 1)

	local StartPos = Torso.Position
	local Forward = Torso.CFrame.LookVector
	
	-- Dash mathematically
	Character:PivotTo(Torso.CFrame + (Forward * 30))
	
	-- Explode 3 echoes after 1.2s
	task.delay(1.2, function()
		for i = 1, 3 do
			local EchoPos = StartPos + (Forward * (i * 10))
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - EchoPos).Magnitude < 10 then
					task.spawn(function()
						RequestStunMob(MobInstance, 1)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 35,
							Tool = Tool,
							SkillScaling = {
								["Dexterity"] = { Type = "Attributes", Additive = 0.8, Cap = 200 },
							},
						})
					end)
				end
			end
		end
	end)
end
return Keybind
