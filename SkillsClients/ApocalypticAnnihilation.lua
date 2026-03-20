-- [CLIENT] ApocalypticAnnihilation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}
function Keybind:OnActivated(Player) end
function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end

	local Origin = Torso.Position
	local FloorPos = Origin

	-- Phase 1 (0.0s): Tremor & Launch
	SFX:Play3D(12222030, FloorPos, {MaxDistance = 300, MinDistance = 50, Volume = 2, Pitch = 0.5})
	local Tremor = Instance.new("Part")
	Tremor.Material = Enum.Material.Neon
	Tremor.Color = Color3.fromRGB(200, 100, 0)
	Tremor.Shape = Enum.PartType.Cylinder
	Tremor.Size = Vector3.new(1, 60, 60)
	Tremor.Anchored = true
	Tremor.CanCollide = false
	Tremor.Position = FloorPos - Vector3.new(0,2,0)
	Tremor.Orientation = Vector3.new(0,0,90)
	Tremor.Parent = Temporary
	Debris:AddItem(Tremor, 1)
	Tween:Play(Tremor, {0.5}, {Transparency = 1, Size = Vector3.new(1, 100, 100)})

	-- Phase 2 (0.5s): Sky Strike
	task.delay(0.5, function()
		SFX:Play3D(9125644676, FloorPos + Vector3.new(0,40,0), {MaxDistance = 200, MinDistance = 50, Volume = 1.5, Pitch = 1.5})
		for i = 1, 5 do
			task.delay(i*0.1, function()
				if Character and Character:FindFirstChild("Torso") then
					local Slash = Instance.new("Part")
					Slash.Material = Enum.Material.Neon
					Slash.Color = Color3.fromRGB(255, 200, 100)
					Slash.Size = Vector3.new(0.5, 30, 2)
					Slash.Anchored = true
					Slash.CanCollide = false
					Slash.CFrame = Character.Torso.CFrame * CFrame.new(0,0,-5) * CFrame.Angles(math.random(-1,1), math.random(-1,1), math.random(-1,1))
					Slash.Parent = Temporary
					Debris:AddItem(Slash, 0.2)
					Tween:Play(Slash, {0.1}, {Size = Vector3.new(0.1, 40, 0.1), Transparency = 1})
				end
			end)
		end
	end)

	-- Phase 3 (1.5s): Meteor Kick
	task.delay(1.5, function()
		SFX:Play3D(9066732918, FloorPos, {MaxDistance = 300, MinDistance = 50, Volume = 3, Pitch = 0.8})
		local Crater = Instance.new("Part")
		Crater.Material = Enum.Material.Neon
		Crater.Color = Color3.fromRGB(255, 50, 0)
		Crater.Shape = Enum.PartType.Ball
		Crater.Size = Vector3.one * 10
		Crater.Anchored = true
		Crater.CanCollide = false
		Crater.Position = FloorPos
		Crater.Parent = Temporary
		Debris:AddItem(Crater, 1)
		Tween:Play(Crater, {0.5, "Quad", "Out"}, {Size = Vector3.one * 50, Transparency = 1})
	end)

	-- Phase 4 (2.0s): Dimension Lasers
	task.delay(2.0, function()
		SFX:Play3D(9116385079, FloorPos, {MaxDistance = 300, MinDistance = 50, Volume = 2, Pitch = 0.5})
		for i = 1, 4 do
			local angle = math.rad(i * 90)
			local gatePos = FloorPos + Vector3.new(math.cos(angle)*40, 20, math.sin(angle)*40)
			
			local Gate = Instance.new("Part")
			Gate.Material = Enum.Material.Neon
			Gate.Color = Color3.fromRGB(150, 0, 255)
			Gate.Shape = Enum.PartType.Cylinder
			Gate.Size = Vector3.new(1, 20, 20)
			Gate.Anchored = true
			Gate.CanCollide = false
			Gate.CFrame = CFrame.new(gatePos, FloorPos)
			Gate.Parent = Temporary
			Debris:AddItem(Gate, 1.5)
			
			task.delay(0.5, function()
				local Beam = Instance.new("Part")
				Beam.Material = Enum.Material.Neon
				Beam.Color = Color3.fromRGB(200, 100, 255)
				Beam.Shape = Enum.PartType.Cylinder
				Beam.Size = Vector3.new((gatePos - FloorPos).Magnitude, 5, 5)
				Beam.Anchored = true
				Beam.CanCollide = false
				Beam.CFrame = CFrame.new((gatePos + FloorPos)/2, FloorPos) * CFrame.Angles(0, math.rad(90), 0)
				Beam.Parent = Temporary
				Debris:AddItem(Beam, 0.5)
				Tween:Play(Beam, {0.3}, {Size = Vector3.new((gatePos - FloorPos).Magnitude, 0, 0), Transparency = 1})
			end)
		end
	end)

	local Domain
	-- Phase 5 (3.5s): Time Stop
	task.delay(3.5, function()
		SFX:Play3D(12222030, FloorPos, {MaxDistance = 400, MinDistance = 60, Volume = 3, Pitch = 0.2})
		Domain = Instance.new("Part")
		Domain.Material = Enum.Material.ForceField
		Domain.Color = Color3.fromRGB(100, 100, 100)
		Domain.Shape = Enum.PartType.Ball
		Domain.Size = Vector3.zero
		Domain.Anchored = true
		Domain.CanCollide = false
		Domain.Position = FloorPos
		Domain.Parent = Temporary
		Debris:AddItem(Domain, 6)
		Tween:Play(Domain, {0.5, "Quad", "Out"}, {Size = Vector3.one * 100})
	end)

	-- Phase 6 (4.0s - 6.0s): 100 Slashes
	task.delay(4.0, function()
		for i = 1, 30 do
			task.delay(i*0.06, function()
				SFX:Play3D(9125644676, FloorPos, {MaxDistance = 200, MinDistance = 40, Volume = 0.3, Pitch = math.random(2, 3)})
				local Slash = Instance.new("Part")
				Slash.Material = Enum.Material.Neon
				Slash.Color = Color3.fromRGB(255, 255, 255)
				Slash.Size = Vector3.new(0.2, math.random(20, 40), 1)
				Slash.Anchored = true
				Slash.CanCollide = false
				Slash.CFrame = CFrame.new(FloorPos + Vector3.new(math.random(-30,30), math.random(0,30), math.random(-30,30))) * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))
				Slash.Parent = Temporary
				Debris:AddItem(Slash, 0.5)
			end)
		end
	end)

	-- Phase 7 (6.0s): Black Arrow / Cosmic Leap
	task.delay(6.0, function()
		SFX:Play3D(9066732918, FloorPos + Vector3.new(0, 150, 0), {MaxDistance = 400, MinDistance = 60, Volume = 2, Pitch = 1.5})
		local Aura = Instance.new("Part")
		Aura.Material = Enum.Material.Neon
		Aura.Color = Color3.fromRGB(255, 255, 200)
		Aura.Shape = Enum.PartType.Ball
		Aura.Size = Vector3.one * 10
		Aura.Anchored = true
		Aura.CanCollide = false
		Aura.Position = FloorPos + Vector3.new(0, 150, 0)
		Aura.Parent = Temporary
		Debris:AddItem(Aura, 2.5)
		Tween:Play(Aura, {2.0}, {Size = Vector3.one * 30, Transparency = 0.8})
	end)

	-- Phase 8 (7.0s): Raining Stars
	task.delay(7.0, function()
		for i = 1, 15 do
			task.delay(i*0.06, function()
				local Star = Instance.new("Part")
				Star.Material = Enum.Material.Neon
				Star.Color = Color3.fromRGB(255, 255, 100)
				Star.Shape = Enum.PartType.Ball
				Star.Size = Vector3.one * 3
				Star.Anchored = true
				Star.CanCollide = false
				Star.Position = FloorPos + Vector3.new(math.random(-30,30), 150, math.random(-30,30))
				Star.Parent = Temporary
				Debris:AddItem(Star, 0.5)
				
				Tween:Play(Star, {0.3, "Linear"}, {Position = FloorPos + Vector3.new(math.random(-20,20), 0, math.random(-20,20))})
			end)
		end
	end)

	-- Phase 9 (8.0s): Comet Fall
	task.delay(8.0, function()
		SFX:Play3D(9116385079, FloorPos, {MaxDistance = 400, MinDistance = 60, Volume = 3, Pitch = 0.5})
		local Comet = Instance.new("Part")
		Comet.Material = Enum.Material.Neon
		Comet.Color = Color3.fromRGB(255, 50, 50)
		Comet.Shape = Enum.PartType.Ball
		Comet.Size = Vector3.one * 20
		Comet.Anchored = true
		Comet.CanCollide = false
		Comet.Position = FloorPos + Vector3.new(0, 150, 0)
		Comet.Parent = Temporary
		Debris:AddItem(Comet, 1)

		Tween:Play(Comet, {0.5, "Quad", "In"}, {Position = FloorPos})
	end)

	-- Phase 10 (8.5s): THE BIG BANG
	task.delay(8.5, function()
		SFX:Play3D(12222030, FloorPos, {MaxDistance = 500, MinDistance = 100, Volume = 4, Pitch = 0.3})
		
		if Domain and Domain.Parent then
			Tween:Play(Domain, {0.2}, {Transparency = 1})
			
			for i = 1, 30 do
				local Shard = Instance.new("Part")
				Shard.Material = Enum.Material.Glass
				Shard.Color = Color3.fromRGB(255, 255, 255)
				Shard.Size = Vector3.new(math.random(2,8), math.random(2,8), math.random(2,8))
				Shard.Anchored = false
				Shard.CanCollide = false
				Shard.Position = FloorPos + Vector3.new(math.random(-40,40), math.random(0,40), math.random(-40,40))
				
				local BV = Instance.new("BodyVelocity")
				BV.MaxForce = Vector3.one * math.huge
				BV.Velocity = Vector3.new(math.random(-100,100), math.random(10,100), math.random(-100,100))
				BV.Parent = Shard
				
				Shard.Parent = Temporary
				Debris:AddItem(Shard, 1.5)
				Tween:Play(Shard, {1.2}, {Transparency = 1})
			end
		end

		local Colors = {Color3.fromRGB(255,255,255), Color3.fromRGB(255,100,100), Color3.fromRGB(150,0,255)}
		for i, col in ipairs(Colors) do
			task.delay(i*0.1, function()
				local Nuke = Instance.new("Part")
				Nuke.Material = Enum.Material.Neon
				Nuke.Color = col
				Nuke.Shape = Enum.PartType.Ball
				Nuke.Size = Vector3.one * 20
				Nuke.Anchored = true
				Nuke.CanCollide = false
				Nuke.Position = FloorPos
				Nuke.Parent = Temporary
				Debris:AddItem(Nuke, 2)
				Tween:Play(Nuke, {1.0, "Quad", "Out"}, {Size = Vector3.one * (100 + i*20), Transparency = 1})
			end)
		end
	end)
end
return Keybind
