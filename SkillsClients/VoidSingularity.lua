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

	local TargetPos = Floor(Torso.Position + Torso.CFrame.LookVector * 25)
	SFX:Play3D(9066732918, TargetPos, {MaxDistance = 200, MinDistance = 40, Volume = 1.5, Pitch = 0.3})

	local BlackHole = Instance.new("Part")
	BlackHole.Material = Enum.Material.Neon
	BlackHole.Color = Color3.fromRGB(0, 0, 0)
	BlackHole.Shape = Enum.PartType.Ball
	BlackHole.Size = Vector3.zero
	BlackHole.Anchored = true
	BlackHole.CanCollide = false
	BlackHole.Position = TargetPos + Vector3.new(0, 5, 0)
	BlackHole.Parent = Temporary
	Debris:AddItem(BlackHole, 5)

	Tween:Play(BlackHole, {1, "Quad", "Out"}, {
		Size = Vector3.one * 15
	})
	
	local Ring = Instance.new("Part")
	Ring.Material = Enum.Material.Neon
	Ring.Color = Color3.fromRGB(100, 0, 150)
	Ring.Shape = Enum.PartType.Cylinder
	Ring.Size = Vector3.new(0.5, 30, 30)
	Ring.Anchored = true
	Ring.CanCollide = false
	Ring.Position = TargetPos
	Ring.Orientation = Vector3.new(0, 0, 90)
	Ring.Transparency = 0.5
	Ring.Parent = Temporary
	Debris:AddItem(Ring, 5)

	task.delay(4.5, function()
		SFX:Play3D(9116385079, TargetPos, {MaxDistance = 200, MinDistance = 40, Volume = 2})
		Tween:Play(BlackHole, {0.5, "Quad", "In"}, {
			Size = Vector3.zero, Transparency = 1
		})
		Tween:Play(Ring, {0.5, "Quad", "Out"}, {
			Size = Vector3.new(0.5, 60, 60), Transparency = 1
		})
	end)
end
return Keybind
