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

	SFX:Play3D(9116385079, Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.0, Pitch = 0.5})
	
	local Hand = Instance.new("Part")
	Hand.Material = Enum.Material.Neon
	Hand.Color = Color3.fromRGB(50, 0, 100)
	Hand.Shape = Enum.PartType.Ball
	Hand.Size = Vector3.one * 15
	Hand.Anchored = true
	Hand.CanCollide = false
	Hand.Position = Torso.Position + Torso.CFrame.LookVector * 10
	Hand.Parent = Temporary
	Debris:AddItem(Hand, 2)

	Tween:Play(Hand, {0.5, "Quad", "In"}, {
		Size = Vector3.one * 5, Transparency = 1
	})
end
return Keybind
