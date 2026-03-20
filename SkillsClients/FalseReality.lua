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
	return Raycast and Raycast.Position or Position
end

function Keybind:OnActivated(Player) end
function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end

	local TargetPos = Floor(Torso.Position + Torso.CFrame.LookVector * 20)
	SFX:Play3D(12222030, TargetPos, {MaxDistance = 100, MinDistance = 20, Pitch = 0.5})

	local Trap = Instance.new("Part")
	Trap.Material = Enum.Material.Neon
	Trap.Color = Color3.fromRGB(50, 0, 50)
	Trap.Shape = Enum.PartType.Cylinder
	Trap.Size = Vector3.new(0.5, 30, 30)
	Trap.Anchored = true
	Trap.CanCollide = false
	Trap.Position = TargetPos
	Trap.Orientation = Vector3.new(0, 0, 90)
	Trap.Transparency = 0.9 -- hard to see
	Trap.Parent = Temporary
	Debris:AddItem(Trap, 10)
end
return Keybind
