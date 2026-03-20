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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 1.2, Pitch = 0.8})

	local Aura = Instance.new("Part")
	Aura.Material = Enum.Material.Neon
	Aura.Color = Color3.fromRGB(255, 0, 0)
	Aura.Shape = Enum.PartType.Cylinder
	Aura.Size = Vector3.new(20, 0, 20)
	Aura.Anchored = false
	Aura.CanCollide = false
	Aura.Massless = true
	Aura.Transparency = 0.5
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Aura
	Weld.Part1 = Torso
	Weld.Parent = Aura
	Aura.CFrame = Torso.CFrame * CFrame.Angles(0, 0, math.rad(90))
	Aura.Parent = Character
	Debris:AddItem(Aura, 8)

	Tween:Play(Aura, {0.3, "Quad", "Out"}, {
		Size = Vector3.new(20, 10, 10)
	})
	
	task.delay(7.7, function()
		if Aura then
			Tween:Play(Aura, {0.3, "Quad", "In"}, {
				Size = Vector3.new(20, 0, 0), Transparency = 1
			})
		end
	end)
end
return Keybind
