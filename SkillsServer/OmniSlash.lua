-- [SERVER] OmniSlash
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

	-- Lock player for the whole ultimate duration
	WeaponLock:Lock(Player, 3.5)
	
	local StartPos = Torso.Position
	local Forward = Torso.CFrame.LookVector
	local EndPos = StartPos + (Forward * 40)
	
	-- Teleport player to the end of the dash
	Character:PivotTo(Torso.CFrame + (Forward * 40))

	-- Phase 1: Group up enemies in path
	local CaughtMobs = {}
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if MobTorso then
			local toMob = MobTorso.Position - StartPos
			local proj = toMob:Dot(Forward)
			local distToLine = (MobTorso.Position - (StartPos + Forward * proj)).Magnitude
			
			if proj > 0 and proj < 45 and distToLine < 15 then
				table.insert(CaughtMobs, MobInstance)
				RequestStunMob(MobInstance, 4)
				-- Pull them into a cluster at EndPos
				MobTorso.CFrame = CFrame.new(EndPos + Vector3.new(math.random(-5,5), 0, math.random(-5,5)))
			end
		end
	end
	
	-- Phase 2: 15 ticks of fast damage
	task.delay(0.3, function()
		for i = 1, 15 do
			task.delay(i*0.1, function()
				for _, MobInstance in ipairs(CaughtMobs) do
					if MobInstance and MobInstance.Parent then
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15,
							Tool = Tool,
						})
					end
				end
			end)
		end
	end)
	
	-- Phase 3: Giant Slam Explosion
	task.delay(2.5, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso and (MobTorso.Position - EndPos).Magnitude < 35 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)
					Knockback:Activate(MobTorso, 40, EndPos, MobTorso.Position)
					Damage:DamageMobSkill(Player, MobList[MobInstance], {
						Damage = 150,
						Tool = Tool,
						SkillScaling = { ["Strength"] = { Type = "Attributes", Additive = 3.0, Cap = 500 } }
					})
				end)
			end
		end
	end)
end
return Keybind
