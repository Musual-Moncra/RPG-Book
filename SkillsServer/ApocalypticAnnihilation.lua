-- [SERVER] ApocalypticAnnihilation
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

	-- Insane 10 second lock
	WeaponLock:Lock(Player, 10.0)
	
	local FloorPos = Torso.Position
	local CaughtMobs = {}

	-- Helper func to find mobs
	local function GrabMobs(radius)
		local count = 0
		for _, m in CollectionService:GetTagged("Mob") do
			local mT = m:FindFirstChild("Torso")
			if mT and (mT.Position - FloorPos).Magnitude <= radius and not table.find(CaughtMobs, m) then
				table.insert(CaughtMobs, m)
				count = count + 1
			end
		end
		return count
	end

	-- Phase 1 (0.0s): Launch
	GrabMobs(40)
	for _, m in ipairs(CaughtMobs) do
		RequestStunMob(m, 10) -- stun them for the whole ordeal
		local mT = m:FindFirstChild("Torso")
		if mT then
			Knockback:Activate(mT, 50, FloorPos - Vector3.new(0,10,0), mT.Position)
			Damage:DamageMobSkill(Player, MobList[m], {Damage = 20, Tool = Tool})
		end
	end

	-- Phase 2 (0.5s): Sky Strike
	task.delay(0.5, function()
		if not Character or not Character.PrimaryPart then return end
		-- Pivot player up
		Character:PivotTo(CFrame.new(FloorPos + Vector3.new(0, 40, 0)))
		
		for i = 1, 5 do
			task.delay(i*0.1, function()
				for _, m in ipairs(CaughtMobs) do
					if m and m.Parent then
						local mT = m:FindFirstChild("Torso")
						if mT then
							-- Freeze in mid air juggling
							mT.CFrame = CFrame.new(FloorPos + Vector3.new(0, 35 + math.random(-5,5), 0))
						end
						Damage:DamageMobSkill(Player, MobList[m], {Damage = 15, Tool = Tool})
					end
				end
			end)
		end
	end)

	-- Phase 3 (1.5s): Meteor Kick
	task.delay(1.5, function()
		if not Character or not Character.PrimaryPart then return end
		Character:PivotTo(CFrame.new(FloorPos))
		for _, m in ipairs(CaughtMobs) do
			if m and m.Parent then
				local mT = m:FindFirstChild("Torso")
				if mT then
					mT.CFrame = CFrame.new(FloorPos + Vector3.new(math.random(-10,10), 5, math.random(-10,10)))
				end
				Damage:DamageMobSkill(Player, MobList[m], {Damage = 50, Tool = Tool})
			end
		end
	end)

	-- Phase 4 (2.0s): Lasers
	task.delay(2.5, function()
		GrabMobs(45) -- Grab any new ones wandering in
		for _, m in ipairs(CaughtMobs) do
			if m and m.Parent then
				RequestStunMob(m, 8)
				Damage:DamageMobSkill(Player, MobList[m], {Damage = 60, Tool = Tool})
			end
		end
	end)

	-- Phase 5 (3.5s): Time Stop
	task.delay(3.5, function()
		GrabMobs(50)
		for _, m in ipairs(CaughtMobs) do
			if m and m.Parent then
				local mT = m:FindFirstChild("Torso")
				if mT then mT.Anchored = true end -- Literal time stop
			end
		end
	end)

	-- Phase 6 (4.0s - 6.0s): 100 Slashes (20 ticks of dmg)
	task.delay(4.0, function()
		for i = 1, 20 do
			task.delay(i*0.1, function()
				-- Teleport around rapidly
				if Character and Character.PrimaryPart then
					Character:PivotTo(CFrame.new(FloorPos + Vector3.new(math.random(-30,30), math.random(5,20), math.random(-30,30))))
				end
				
				for _, m in ipairs(CaughtMobs) do
					if m and m.Parent then
						Damage:DamageMobSkill(Player, MobList[m], {Damage = 10, Tool = Tool})
					end
				end
			end)
		end
	end)

	-- Phase 7 (6.0s): Leap
	task.delay(6.0, function()
		if Character and Character.PrimaryPart then
			Character:PivotTo(CFrame.new(FloorPos + Vector3.new(0, 150, 0)))
			if Character:FindFirstChild("Torso") then
				Character.Torso.Anchored = true
			end
		end
	end)

	-- Phase 8 (7.0s): Stars
	task.delay(7.0, function()
		for i = 1, 10 do
			task.delay(i*0.1, function()
				for _, m in ipairs(CaughtMobs) do
					if m and m.Parent then
						Damage:DamageMobSkill(Player, MobList[m], {Damage = 25, Tool = Tool})
					end
				end
			end)
		end
	end)

	-- Phase 9 (8.0s): Comet Fall
	task.delay(8.0, function()
		if Character and Character:FindFirstChild("Torso") then
			Character.Torso.Anchored = false
			Character:PivotTo(CFrame.new(FloorPos))
		end
	end)

	-- Phase 10 (8.5s): Big Bang
	task.delay(8.5, function()
		GrabMobs(80) -- Massive final check
		for _, m in ipairs(CaughtMobs) do
			if m and m.Parent then
				local mT = m:FindFirstChild("Torso")
				if mT then
					mT.Anchored = false -- Unfreeze time
					Knockback:Activate(mT, 150, FloorPos, mT.Position) -- Crazy launch
				end
				Damage:DamageMobSkill(Player, MobList[m], {
					Damage = 600,
					Tool = Tool,
					SkillScaling = { 
						["Intelligence"] = { Type = "Attributes", Additive = 5.0, Cap = 1000 },
						["Strength"] = { Type = "Attributes", Additive = 5.0, Cap = 1000 },
						["Dexterity"] = { Type = "Attributes", Additive = 5.0, Cap = 1000 }
					}
				})
			end
		end
	end)

	-- Cleanup
	task.delay(10.0, function()
		for _, m in ipairs(CaughtMobs) do
			if m and m.Parent then
				local mT = m:FindFirstChild("Torso")
				if mT then mT.Anchored = false end
			end
		end
		CaughtMobs = nil
	end)
end
return Keybind
