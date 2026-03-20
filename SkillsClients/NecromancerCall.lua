-- [CLIENT]
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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 0.5, Volume = 1.0})

	for i = 1, 2 do
		local SpawnPoint = Torso.Position + Vector3.new(math.random(-10, 10), -5, math.random(-10, 10))
		
		local Glow = Instance.new("Part")
		Glow.Material = Enum.Material.Neon
		Glow.Color = Color3.fromRGB(150, 0, 50)
		Glow.Shape = Enum.PartType.Cylinder
		Glow.Size = Vector3.new(0.5, 10, 10)
		Glow.Anchored = true
		Glow.CanCollide = false
		Glow.Position = SpawnPoint + Vector3.new(0, 5, 0)
		Glow.Orientation = Vector3.new(0, 0, 90)
		Glow.Parent = Temporary
		Debris:AddItem(Glow, 1.5)
		
		Tween:Play(Glow, {1, "Quad", "Out"}, {Transparency = 1, Size = Vector3.new(0.5, 20, 20)})
		
		local SkeletonProxy = Instance.new("Part")
		SkeletonProxy.Material = Enum.Material.CorrodedMetal
		SkeletonProxy.Color = Color3.fromRGB(200, 200, 200)
		SkeletonProxy.Size = Vector3.new(3, 5, 3)
		SkeletonProxy.Anchored = true
		SkeletonProxy.CanCollide = false
		SkeletonProxy.Position = SpawnPoint
		SkeletonProxy.Parent = Temporary
		Debris:AddItem(SkeletonProxy, 10)
		
		Tween:Play(SkeletonProxy, {0.5, "Quad", "Out"}, {
			Position = SpawnPoint + Vector3.new(0, 2.5, 0)
		})
	end
end
return Keybind
