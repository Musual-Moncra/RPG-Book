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
	local Position = Torso.Position
	
	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Volume = 1.0, Pitch = 0.2})

	-- Time Sphere
	local Sphere = Instance.new("Part")
	Sphere.Name = "TimeDilatorField"
	Sphere.Material = Enum.Material.ForceField
	Sphere.Color = Color3.fromRGB(255, 255, 100) -- Yellowish time magic
	Sphere.Shape = Enum.PartType.Ball
	Sphere.Size = Vector3.one * 5
	Sphere.Anchored = true
	Sphere.CanCollide = false
	Sphere.Position = Position
	Sphere.Parent = Temporary
	Debris:AddItem(Sphere, 6)

	Tween:Play(Sphere, {1, "Quad", "Out"}, {
		Size = Vector3.one * 50
	})
	
	task.delay(5, function()
		Tween:Play(Sphere, {1, "Linear"}, {
			Transparency = 1,
			Size = Vector3.zero
		})
	end)
end
return Keybind
