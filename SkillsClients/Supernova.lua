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
	local Position = Torso.Position
	
	-- Charge up SFX
	SFX:Play3D(9125644676, Position, {MaxDistance = 200, MinDistance = 40, Volume = 1.5, Pitch = 0.5})

	-- Sun/Supernova Sphere
	local Sun = Instance.new("Part")
	Sun.Name = "Supernova_Sun"
	Sun.Material = Enum.Material.Neon
	Sun.Color = Color3.fromRGB(255, 200, 50)
	Sun.Shape = Enum.PartType.Ball
	Sun.Size = Vector3.one
	Sun.Anchored = true
	Sun.CanCollide = false
	Sun.Position = Position + Vector3.new(0, 15, 0)
	Sun.Parent = Temporary
	Debris:AddItem(Sun, 4)

	-- Growing
	Tween:Play(Sun, {2, "Linear"}, {
		Size = Vector3.one * 25
	})
	
	-- Explode
	task.delay(2, function()
		SFX:Play3D(9116385079, Sun.Position, {MaxDistance = 300, MinDistance = 50, Volume = 2, Pitch = 0.8})
		
		local Blast = Instance.new("Part")
		Blast.Name = "Supernova_Blast"
		Blast.Material = Enum.Material.Neon
		Blast.Color = Color3.fromRGB(255, 255, 255)
		Blast.Shape = Enum.PartType.Ball
		Blast.Size = Vector3.one * 25
		Blast.Anchored = true
		Blast.CanCollide = false
		Blast.Position = Sun.Position
		Blast.Parent = Temporary
		Debris:AddItem(Blast, 1)

		Tween:Play(Blast, {0.5, "Quad", "Out"}, {
			Size = Vector3.one * 80,
			Transparency = 1
		})
		
		Tween:Play(Sun, {0.2, "Linear"}, {
			Size = Vector3.zero,
			Transparency = 1
		})
	end)
end
return Keybind
