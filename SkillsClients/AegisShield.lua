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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 1.0, Pitch = 1.5})

	local Shield = Instance.new("Part")
	Shield.Material = Enum.Material.ForceField
	Shield.Color = Color3.fromRGB(255, 255, 100)
	Shield.Shape = Enum.PartType.Ball
	Shield.Size = Vector3.one * 10
	Shield.Anchored = false
	Shield.CanCollide = false
	Shield.Massless = true
	Shield.Transparency = 0.5
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Shield
	Weld.Part1 = Torso
	Weld.Parent = Shield
	Shield.CFrame = Torso.CFrame
	Shield.Parent = Character
	Debris:AddItem(Shield, 10)

	Tween:Play(Shield, {0.3, "Quad", "Out"}, {
		Size = Vector3.one * 12
	})
	
	task.delay(9.7, function()
		if Shield then
			Tween:Play(Shield, {0.3, "Linear"}, {Transparency = 1, Size = Vector3.one*15})
		end
	end)
end
return Keybind
