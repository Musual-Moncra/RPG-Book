-- [SERVER] HellfireEruption
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
	WeaponLock:Lock(Player, 4.0)
	
	local Center = Torso.Position + Torso.CFrame.LookVector * 20

	-- Phase 1 & 2
	local CaughtMobs = {}
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso and (MobTorso.Position - Center).Magnitude < 25 then
			table.insert(CaughtMobs, MobInstance)
			RequestStunMob(MobInstance, 4)
			-- Knockup
			Knockback:Activate(MobTorso, 30, Center - Vector3.new(0, 20, 0), MobTorso.Position)
		end
	end
	
	-- Juggling damage
	task.delay(0.5, function()
		for i = 1, 5 do
			task.delay(i*0.5, function()
				for _, MobInstance in ipairs(CaughtMobs) do
					if MobInstance and MobInstance.Parent then
						local MobTorso = MobInstance:FindFirstChild("Torso")
						if MobTorso then
							-- Keep them juggled up
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(0, 100000, 0)
							bv.Velocity = Vector3.new(0, 10, 0)
							bv.Parent = MobTorso
							game:GetService("Debris"):AddItem(bv, 0.2)
						end
						
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 20,
							Tool = Tool,
						})
					end
				end
			end)
		end
	end)
	
	-- Phase 3: Final Explosion
	task.delay(3.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - Center).Magnitude < 40 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(MobTorso, 60, Center, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 200,
						Tool = Tool,
						SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 2.5, Cap = 500 } }
					})
				end)
			end
		end
	end)
end
return Keybind
