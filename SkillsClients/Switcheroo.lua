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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8})
	local Poof = Instance.new("Part")
	Poof.Material = Enum.Material.Neon
	Poof.Color = Color3.fromRGB(200, 200, 200)
	Poof.Shape = Enum.PartType.Ball
	Poof.Size = Vector3.one * 10
	Poof.Anchored = true
	Poof.CanCollide = false
	Poof.Position = Torso.Position
	Poof.Parent = Temporary
	Debris:AddItem(Poof, 0.5)

	Tween:Play(Poof, {0.3, "Quad", "Out"}, {
		Size = Vector3.one * 20, Transparency = 1
	})
end
return Keybind
