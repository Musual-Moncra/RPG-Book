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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 200, MinDistance = 40, Volume = 2.0, Pitch = 1.5})
	
	local Forward = Torso.CFrame.LookVector
	local Beam = Instance.new("Part")
	Beam.Material = Enum.Material.Neon
	Beam.Color = Color3.fromRGB(255, 255, 150)
	Beam.Shape = Enum.PartType.Cylinder
	Beam.Size = Vector3.new(200, 10, 10)
	Beam.Anchored = true
	Beam.CanCollide = false
	Beam.CFrame = Torso.CFrame * CFrame.new(0, 0, -100) * CFrame.Angles(0, math.rad(90), 0)
	Beam.Parent = Temporary
	Debris:AddItem(Beam, 1.5)

	Tween:Play(Beam, {1.0, "Quad", "Out"}, {
		Size = Vector3.new(200, 0, 0), Transparency = 1
	})
end
return Keybind
