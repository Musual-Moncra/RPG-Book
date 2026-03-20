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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 200, MinDistance = 40, Volume = 1.5, Pitch = 0.5})

	local Forward = Torso.CFrame.LookVector * 50
	local Fissure = Instance.new("Part")
	Fissure.Material = Enum.Material.Neon
	Fissure.Color = Color3.fromRGB(255, 100, 0)
	Fissure.Size = Vector3.new(5, 1, 50)
	Fissure.Anchored = true
	Fissure.CanCollide = false
	Fissure.CFrame = CFrame.new(Torso.Position + (Torso.CFrame.LookVector * 25) - Vector3.new(0,5,0), Torso.Position + Forward)
	Fissure.Parent = Temporary
	Debris:AddItem(Fissure, 3)

	local Lava = Instance.new("Part")
	Lava.Material = Enum.Material.Neon
	Lava.Color = Color3.fromRGB(255, 50, 0)
	Lava.Size = Vector3.new(3, 0, 50)
	Lava.Anchored = true
	Lava.CanCollide = false
	Lava.CFrame = Fissure.CFrame
	Lava.Parent = Temporary
	Debris:AddItem(Lava, 1)

	Tween:Play(Lava, {0.2, "Quad", "Out"}, {
		Size = Vector3.new(3, 15, 50)
	})
	
	task.delay(0.2, function()
		Tween:Play(Lava, {0.3, "Linear"}, {
			Size = Vector3.new(3, 0, 50), Transparency = 1
		})
		Tween:Play(Fissure, {2, "Linear"}, {
			Transparency = 1
		})
	end)
end
return Keybind
