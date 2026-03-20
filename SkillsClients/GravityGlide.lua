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

	SFX:Play3D(9066732918, Torso.Position, {MaxDistance = 150, MinDistance = 20, Pitch = 1.2})
	local Aura = Instance.new("Part")
	Aura.Material = Enum.Material.ForceField
	Aura.Color = Color3.fromRGB(150, 0, 255)
	Aura.Shape = Enum.PartType.Ball
	Aura.Size = Vector3.one * 10
	Aura.Anchored = false
	Aura.CanCollide = false
	Aura.Massless = true
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Aura
	Weld.Part1 = Torso
	Weld.Parent = Aura
	Aura.CFrame = Torso.CFrame
	Aura.Parent = Character
	Debris:AddItem(Aura, 5)
end
return Keybind
