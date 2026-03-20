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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.0, Pitch = 0.3})
	
	local Shock = Instance.new("Part")
	Shock.Material = Enum.Material.ForceField
	Shock.Color = Color3.fromRGB(50, 0, 100)
	Shock.Shape = Enum.PartType.Cylinder
	Shock.Size = Vector3.new(1, 100, 100)
	Shock.Anchored = true
	Shock.CanCollide = false
	Shock.Position = Torso.Position - Vector3.new(0,2,0)
	Shock.Orientation = Vector3.new(0, 0, 90)
	Shock.Parent = Temporary
	Debris:AddItem(Shock, 1)

	Tween:Play(Shock, {0.5, "Quad", "Out"}, {
		Size = Vector3.new(20, 150, 150), Transparency = 1
	})
end
return Keybind
