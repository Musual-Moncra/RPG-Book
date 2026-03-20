-- [SERVER] ChronoExecuter
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
	WeaponLock:Lock(Player, 4.0)
	
	local Center = Torso.Position
	local CaughtMobs = {}

	-- Phase 1 & 2: Time domain expansion
	task.delay(0.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - Center).Magnitude < 40 then
				table.insert(CaughtMobs, MobInstance)
				RequestStunMob(MobInstance, 4)
			end
		end
	end)

	for i = 1, 10 do
		task.delay(1 + (i*0.2), function()
			for _, MobInstance in ipairs(CaughtMobs) do
				if MobInstance and MobInstance.Parent then
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 15,
						Tool = Tool,
						SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 100 } }
					})
				end
			end
		end)
	end
	
	-- Phase 3: Shatter
	task.delay(3.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - Center).Magnitude < 40 then
				task.spawn(function()
					RequestStunMob(MobInstance, 1)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 250, -- Massive execute 
						Tool = Tool,
						SkillScaling = { 
							["Strength"] = { Type = "Attributes", Additive = 2.0, Cap = 300 },
							["Intelligence"] = { Type = "Attributes", Additive = 2.0, Cap = 300 }
						}
					})
				end)
			end
		end
	end)
end
return Keybind
