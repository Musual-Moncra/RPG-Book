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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8})

	-- Clone appearance
	Character.Archivable = true
	local Clone = Character:Clone()
	Character.Archivable = false
	
	Clone.Name = "SoulDecoy"
	for _, child in Clone:GetDescendants() do
		if child:IsA("BasePart") then
			child.Material = Enum.Material.ForceField
			child.Color = Color3.fromRGB(150, 255, 150)
			child.Anchored = true
			child.CanCollide = false
		elseif child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		end
	end
	
	Clone.Parent = Temporary
	Debris:AddItem(Clone, 5)

	-- Detonate effect after 5s or early on hit
	task.delay(5, function()
		if Clone and Clone.Parent then
			SFX:Play3D(9116385079, Clone:GetPivot().Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.0, Pitch = 1.2})
			local Explosion = Instance.new("Part")
			Explosion.Material = Enum.Material.Neon
			Explosion.Color = Color3.fromRGB(150, 255, 150)
			Explosion.Shape = Enum.PartType.Ball
			Explosion.Size = Vector3.one * 5
			Explosion.Anchored = true
			Explosion.CanCollide = false
			Explosion.Position = Clone:GetPivot().Position
			Explosion.Parent = Temporary
			Debris:AddItem(Explosion, 1)

			Tween:Play(Explosion, {0.3, "Quad", "Out"}, {
				Size = Vector3.one * 30, Transparency = 1
			})
			Clone:Destroy()
		end
	end)
end
return Keybind
