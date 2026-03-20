-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"), workspace:WaitForChild("Mobs"), workspace:WaitForChild("Zones")}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 50, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position or Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end
	local Position = Torso.Position

	-- Jump SFX
	SFX:Play3D(12222030, Position, {MaxDistance = 100, MinDistance = 20, Volume = 1})

	-- Jump wind effect
	local Wind = Instance.new("Part")
	Wind.Name = "LeapWind"
	Wind.Material = Enum.Material.Neon
	Wind.Color = Color3.fromRGB(200, 200, 200)
	Wind.Anchored = true
	Wind.CanCollide = false
	Wind.Shape = Enum.PartType.Cylinder
	Wind.Size = Vector3.new(1, 10, 10)
	Wind.Position = Torso.Position
	Wind.Orientation = Vector3.new(0, 0, 90)
	Wind.Parent = Temporary
	Debris:AddItem(Wind, 1)

	Tween:Play(Wind, {0.3, "Quad", "Out"}, {
		Size = Vector3.new(20, 2, 2),
		Transparency = 1,
		Position = Torso.Position + Vector3.new(0, 20, 0)
	})

	-- Landing impact after 0.8s (assuming hang time)
	task.delay(0.8, function()
		if not Character or not Character:FindFirstChild("Torso") then return end
		local LandPos = Floor(Character.Torso.Position)
		
		SFX:Play3D(9066732918, LandPos, {MaxDistance = 150, MinDistance = 30, Volume = 1.5})

		local Shockwave = Instance.new("Part")
		Shockwave.Name = "LeapShockwave"
		Shockwave.Material = Enum.Material.Neon
		Shockwave.Color = Color3.fromRGB(255, 100, 50)
		Shockwave.Anchored = true
		Shockwave.CanCollide = false
		Shockwave.Shape = Enum.PartType.Cylinder
		Shockwave.Size = Vector3.new(2, 5, 5)
		Shockwave.Position = LandPos
		Shockwave.Orientation = Vector3.new(0, 90, 90)
		Shockwave.Parent = Temporary
		Debris:AddItem(Shockwave, 2)

		Tween:Play(Shockwave, {0.5, "Circular", "Out"}, {
			Size = Vector3.new(0, 40, 40),
			Transparency = 1
		})
	end)
end
return Keybind
