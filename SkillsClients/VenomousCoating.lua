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

	SFX:Play3D(9116385079, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 2})

	-- Dagger / Weapon aura
	local Aura = Instance.new("Part")
	Aura.Material = Enum.Material.Neon
	Aura.Color = Color3.fromRGB(50, 255, 50)
	Aura.Shape = Enum.PartType.Ball
	Aura.Size = Vector3.one * 5
	Aura.Anchored = false
	Aura.CanCollide = false
	Aura.Massless = true
	Aura.Transparency = 0.5
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Aura
	Weld.Part1 = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand") or Torso
	Weld.Parent = Aura
	Aura.CFrame = Weld.Part1.CFrame
	Aura.Parent = Character
	Debris:AddItem(Aura, 10)
end
return Keybind
