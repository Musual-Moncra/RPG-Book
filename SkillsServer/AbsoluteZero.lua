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
	WeaponLock:Lock(Player, 1.5)
	
	local Origin = Torso.Position
	
	-- Delayed to match the ice field expansion
	task.delay(0.3, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - Origin).Magnitude < 25 then
				task.spawn(function()
					-- Heavy Stun (Freeze)
					RequestStunMob(MobInstance, 4)
					-- Minor knockback up to simulate getting encased
					Knockback:Activate(MobTorso, 2, Origin - Vector3.new(0, 10, 0), MobTorso.Position)
					
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 45,
						Tool = Tool,
						SkillScaling = {
							["Intelligence"] = { Type = "Attributes", Additive = 1.0, Cap = 250 },
						},
					})
					pcall(function() MobTorso:SetNetworkOwner(Player) end)
				end)
			end
		end
	end)
end
return Keybind
