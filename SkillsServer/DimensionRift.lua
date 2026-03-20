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
	WeaponLock:Lock(Player, 2)

	local StartPos = Torso.Position
	-- Teleport Forward
	local RiftOffset = Torso.CFrame.LookVector * 40
	local TargetCFrame = Torso.CFrame + RiftOffset
	Character:PivotTo(TargetCFrame)

	-- Detonate StartPos after 1.5s
	task.delay(1.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - StartPos).Magnitude < 20 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(MobTorso, 15, StartPos, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 60,
						Tool = Tool,
						SkillScaling = {
							["Dexterity"] = { Type = "Attributes", Additive = 1.2, Cap = 300 },
						},
					})
					pcall(function() MobTorso:SetNetworkOwner(Player) end)
				end)
			end
		end
	end)
end
return Keybind
