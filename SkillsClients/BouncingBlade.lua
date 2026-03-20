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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 2})

	local Blade = Instance.new("Part")
	Blade.Material = Enum.Material.Neon
	Blade.Color = Color3.fromRGB(200, 200, 200)
	Blade.Shape = Enum.PartType.Cylinder
	Blade.Size = Vector3.new(0.5, 8, 8)
	Blade.Anchored = false
	Blade.CanCollide = false
	Blade.Position = Torso.Position
	
	local BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(1,1,1)*math.huge
	BV.Velocity = Torso.CFrame.LookVector * 100
	BV.Parent = Blade
	
	Blade.Parent = Temporary
	Debris:AddItem(Blade, 2)
end
return Keybind
