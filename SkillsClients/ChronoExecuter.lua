-- [CLIENT] ChronoExecuter
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
	local Center = Torso.Position

	-- Phase 1: Domain Expansion
	SFX:Play3D(12222030, Center, {MaxDistance = 300, MinDistance = 50, Pitch = 0.2, Volume = 2})
	local Domain = Instance.new("Part")
	Domain.Material = Enum.Material.ForceField
	Domain.Color = Color3.fromRGB(255, 215, 0)
	Domain.Shape = Enum.PartType.Ball
	Domain.Size = Vector3.zero
	Domain.Anchored = true
	Domain.CanCollide = false
	Domain.Position = Center
	Domain.Parent = Temporary
	Debris:AddItem(Domain, 6)

	Tween:Play(Domain, {1, "Quad", "Out"}, {Size = Vector3.one * 80})

	-- Phase 2: Spawn floating swords that stab inward
	task.delay(1, function()
		for i = 1, 10 do
			task.delay(i*0.2, function()
				SFX:Play3D(9125644676, Center, {MaxDistance = 150, MinDistance = 30, Pitch = 3})
				local Sword = Instance.new("Part")
				Sword.Material = Enum.Material.Neon
				Sword.Color = Color3.fromRGB(255, 255, 150)
				Sword.Size = Vector3.new(1, 10, 3)
				Sword.Anchored = true
				Sword.CanCollide = false
				
				local Angle = math.rad(i * (360/10))
				local sPos = Center + Vector3.new(math.cos(Angle)*20, math.random(5,15), math.sin(Angle)*20)
				Sword.CFrame = CFrame.new(sPos, Center) * CFrame.Angles(math.rad(90),0,0)
				Sword.Parent = Temporary
				Debris:AddItem(Sword, 3)
				
				Tween:Play(Sword, {0.2, "Quad", "In"}, {
					CFrame = CFrame.new(Center + Vector3.new(math.random(-10,10), math.random(0,10), math.random(-10,10))) * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)),0)
				})
			end)
		end
	end)

	-- Phase 3: Shatter
	task.delay(3.5, function()
		SFX:Play3D(9066732918, Center, {MaxDistance = 300, MinDistance = 50, Volume = 3, Pitch = 2})
		Tween:Play(Domain, {0.2}, {Transparency = 1})
		
		for i = 1, 20 do
			local Shard = Instance.new("Part")
			Shard.Material = Enum.Material.Glass
			Shard.Color = Color3.fromRGB(255, 215, 0)
			Shard.Size = Vector3.new(math.random(1,4), math.random(1,4), math.random(1,4))
			Shard.Anchored = false
			Shard.CanCollide = false
			Shard.Position = Center + Vector3.new(math.random(-30,30), math.random(0, 30), math.random(-30,30))
			
			local BV = Instance.new("BodyVelocity")
			BV.MaxForce = Vector3.one * math.huge
			BV.Velocity = Vector3.new(math.random(-50,50), math.random(-10,50), math.random(-50,50))
			BV.Parent = Shard
			
			Shard.Parent = Temporary
			Debris:AddItem(Shard, 1)
			Tween:Play(Shard, {0.8}, {Transparency = 1})
		end
	end)
end
return Keybind
