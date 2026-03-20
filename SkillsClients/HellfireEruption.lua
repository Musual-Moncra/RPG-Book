-- [CLIENT] HellfireEruption
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

	local Center = Torso.Position + Torso.CFrame.LookVector * 20
	
	-- Phase 1: Slam
	SFX:Play3D(12222030, Center, {MaxDistance = 200, MinDistance = 40, Pitch = 0.5, Volume = 2})
	local GroundFlame = Instance.new("Part")
	GroundFlame.Material = Enum.Material.Neon
	GroundFlame.Color = Color3.fromRGB(255, 50, 0)
	GroundFlame.Shape = Enum.PartType.Cylinder
	GroundFlame.Size = Vector3.new(1, 40, 40)
	GroundFlame.Anchored = true
	GroundFlame.CanCollide = false
	GroundFlame.Position = Center - Vector3.new(0, 2, 0)
	GroundFlame.Orientation = Vector3.new(0,0,90)
	GroundFlame.Parent = Temporary
	Debris:AddItem(GroundFlame, 4)
	
	Tween:Play(GroundFlame, {0.5, "Quad", "Out"}, {Transparency = 0.5})

	-- Phase 2: Pillars
	task.delay(0.5, function()
		SFX:Play3D(9116385079, Center, {MaxDistance = 200, MinDistance = 40, Pitch = 0.5, Volume = 1.5})
		for i = 1, 5 do
			local angle = math.rad(i * (360/5))
			local pPos = Center + Vector3.new(math.cos(angle)*10, 0, math.sin(angle)*10)
			
			local Pillar = Instance.new("Part")
			Pillar.Material = Enum.Material.Neon
			Pillar.Color = Color3.fromRGB(255, 100, 0)
			Pillar.Shape = Enum.PartType.Cylinder
			Pillar.Size = Vector3.new(0, 10, 10)
			Pillar.Anchored = true
			Pillar.CanCollide = false
			Pillar.Position = pPos
			Pillar.Orientation = Vector3.new(0,0,90)
			Pillar.Parent = Temporary
			Debris:AddItem(Pillar, 3.5)
			
			Tween:Play(Pillar, {0.3, "Quad", "Out"}, {Size = Vector3.new(50, 10, 10), Position = pPos + Vector3.new(0, 25, 0)})
			
			-- Phase 3: Boom!
			task.delay(3, function()
				Tween:Play(Pillar, {0.2}, {Transparency = 1, Size = Vector3.new(60,20,20)})
			end)
		end
	end)

	-- Phase 3: Supernova
	task.delay(3.5, function()
		SFX:Play3D(9066732918, Center, {MaxDistance = 300, MinDistance = 50, Volume = 3, Pitch = 0.8})
		local FinalBoom = Instance.new("Part")
		FinalBoom.Material = Enum.Material.Neon
		FinalBoom.Color = Color3.fromRGB(255, 200, 50)
		FinalBoom.Shape = Enum.PartType.Ball
		FinalBoom.Size = Vector3.one * 20
		FinalBoom.Anchored = true
		FinalBoom.CanCollide = false
		FinalBoom.Position = Center + Vector3.new(0, 20, 0)
		FinalBoom.Parent = Temporary
		Debris:AddItem(FinalBoom, 1)

		Tween:Play(FinalBoom, {0.5, "Quad", "Out"}, {Size = Vector3.one * 80, Transparency = 1})
		Tween:Play(GroundFlame, {0.5}, {Transparency = 1, Size = Vector3.new(1, 80, 80)})
	end)
end
return Keybind
