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

	local Center = Torso.Position
	SFX:Play3D(12222030, Center, {MaxDistance = 300, MinDistance = 50, Volume = 2, Pitch = 1.2})
	
	local Domain = Instance.new("Part")
	Domain.Material = Enum.Material.Neon
	Domain.Color = Color3.fromRGB(150, 200, 255)
	Domain.Shape = Enum.PartType.Cylinder
	Domain.Size = Vector3.new(0.5, 60, 60)
	Domain.Anchored = true
	Domain.CanCollide = false
	Domain.Position = Center - Vector3.new(0, 5, 0)
	Domain.Orientation = Vector3.new(0, 0, 90)
	Domain.Transparency = 0.8
	Domain.Parent = Temporary
	Debris:AddItem(Domain, 5)

	-- Lightning bolts
	for i = 1, 10 do
		task.delay(math.random() * 4.5, function()
			local rX = Center.X + math.random(-25, 25)
			local rZ = Center.Z + math.random(-25, 25)
			
			local Bolt = Instance.new("Part")
			Bolt.Material = Enum.Material.Neon
			Bolt.Color = Color3.fromRGB(200, 255, 255)
			Bolt.Size = Vector3.new(2, 100, 2)
			Bolt.Anchored = true
			Bolt.CanCollide = false
			Bolt.Position = Vector3.new(rX, Center.Y + 50, rZ)
			Bolt.Parent = Temporary
			Debris:AddItem(Bolt, 0.2)
			
			SFX:Play3D(9116385079, Bolt.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.5})
			Tween:Play(Bolt, {0.1}, {Size = Vector3.new(0.2, 100, 0.2), Transparency = 1})
		end)
	end
end
return Keybind
