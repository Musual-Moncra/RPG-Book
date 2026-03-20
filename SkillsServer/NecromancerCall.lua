-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
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
	
	-- Simplified summon: Turrets disguised as skeletons, shooting arrows at nearby enemies for 10s
	local function FireAtMobs(StartPos)
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - StartPos).Magnitude < 40 then
				task.spawn(function()
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 15,
						Tool = Tool,
						SkillScaling = { ["Intelligence"] = { Type = "Attributes", Additive = 0.5, Cap = 100 } }
					})
				end)
				break -- Only shoot 1 per tick per skelly
			end
		end
	end

	local Start1 = Torso.Position + Torso.CFrame.RightVector * -10
	local Start2 = Torso.Position + Torso.CFrame.RightVector * 10

	task.spawn(function()
		for tick = 1, 10 do
			task.wait(1)
			FireAtMobs(Start1)
			FireAtMobs(Start2)
		end
	end)
end
return Keybind
