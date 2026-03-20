-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"), workspace:WaitForChild("Mobs"), workspace:WaitForChild("Zones")}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), RaycastParams)
	return Raycast and Raycast.Position or Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end
	
	local GroundPos = Floor(Torso.Position)
	
	SFX:Play3D(12222030, GroundPos, {MaxDistance = 150, MinDistance = 30, Volume = 1.2, Pitch = 0.7})

	local IceField = Instance.new("Part")
	IceField.Name = "AbsoluteZero_Field"
	IceField.Material = Enum.Material.Neon
	IceField.Color = Color3.fromRGB(150, 255, 255)
	IceField.Shape = Enum.PartType.Cylinder
	IceField.Size = Vector3.new(1, 0, 0)
	IceField.Anchored = true
	IceField.CanCollide = false
	IceField.Position = GroundPos + Vector3.new(0, 0.5, 0)
	IceField.Orientation = Vector3.new(0, 90, 90)
	IceField.Parent = Temporary
	Debris:AddItem(IceField, 3)

	Tween:Play(IceField, {0.6, "Quad", "Out"}, {
		Size = Vector3.new(1, 50, 50),
		Transparency = 0.4
	})
	
	task.delay(2.5, function()
		Tween:Play(IceField, {0.5, "Linear"}, {
			Transparency = 1
		})
	end)
	
	-- Ice spikes / mist
	for i = 1, 8 do
		local Mist = Instance.new("Part")
		Mist.Material = Enum.Material.Neon
		Mist.Color = Color3.fromRGB(220, 255, 255)
		Mist.Shape = Enum.PartType.Ball
		Mist.Size = Vector3.one * 2
		Mist.Anchored = true
		Mist.CanCollide = false
		
		local Angle = math.rad((360 / 8) * i)
		local Direction = Vector3.new(math.cos(Angle), 0, math.sin(Angle))
		Mist.Position = GroundPos + (Direction * 5)
		Mist.Parent = Temporary
		Debris:AddItem(Mist, 2)
		
		Tween:Play(Mist, {1, "Quad", "Out"}, {
			Position = GroundPos + (Direction * 20) + Vector3.new(0, math.random(5, 10), 0),
			Size = Vector3.one * 10,
			Transparency = 1
		})
	end
end
return Keybind
