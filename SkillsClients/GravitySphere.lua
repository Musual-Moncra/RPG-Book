-- [CLIENT] --> Shared to all clients

--> References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> References
local Temporary = workspace:WaitForChild("Temporary")

--> Variables
local Keybind = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"),
	workspace:WaitForChild("Mobs"), workspace.Zones, workspace.Teleports, workspace.Map.Doors
}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.RespectCanCollide = true

local Duration = 1.0

--------------------------------------------------------------------------------

-- Callbacks
local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position, Raycast
end

-- Ran when activated
function Keybind:OnActivated(Player)
	
end

function Keybind:OnLetGo(Player)
	local Character = Player.Character

	local OriginPosition = Character 
		and Character:FindFirstChild("Torso")
		and Character.Torso.Position

	if not OriginPosition then 
		return
	end

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.25) then
		return
	end
	
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local Position = HRP and (HRP.Position + HRP.CFrame.LookVector * 15) or OriginPosition
	Position = Floor(Position) or Position

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.3})

	-- Core black hole
	local Core = Instance.new("Part")
	Core.Name = "GravitySphere_Core"
	Core.Material = Enum.Material.Neon
	Core.Color = Color3.fromRGB(15, 0, 30)
	Core.Anchored = true
	Core.CastShadow = false
	Core.CanCollide = false
	Core.Position = Position + Vector3.new(0, 2, 0)
	Core.Size = Vector3.one * 1
	Core.Shape = Enum.PartType.Ball

	Tween:Play(Core, {0.5, "Quad", "Out"}, {
		Size = Vector3.one * 10
	})
	
	task.delay(5.0, function()
		SFX:Play3D(9066732918, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.8})
		Tween:Play(Core, {0.4, "Quad", "In"}, {
			Size = Vector3.one * 0,
			Transparency = 1
		})
	end)

	Core.Parent = Temporary
	Debris:AddItem(Core, 6)
	
	-- Swirling Rings
	for i = 1, 3 do
		local Ring = Instance.new("Part")
		Ring.Name = "GravitySphere_Ring"
		Ring.Material = Enum.Material.ForceField
		Ring.Color = Color3.fromRGB(100, 0, 255)
		Ring.Anchored = true
		Ring.CastShadow = false
		Ring.CanCollide = false
		Ring.Position = Position + Vector3.new(0, 2, 0)
		Ring.Size = Vector3.one * 0.1
		Ring.Shape = Enum.PartType.Ball
		
		Ring.Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		
		Tween:Play(Ring, {0.5, "Quad", "Out"}, {
			Size = Vector3.one * (30 + i * 10)
		})
		
		task.delay(1.0, function()
			Tween:Play(Ring, {4.0, "Linear"}, {
				Orientation = Ring.Orientation + Vector3.new(360, 360, 0)
			})
		end)
		
		task.delay(5.0, function()
			Tween:Play(Ring, {0.4, "Quad", "In"}, {
				Size = Vector3.one * 0,
				Transparency = 1
			})
		end)

		Ring.Parent = Temporary
		Debris:AddItem(Ring, 6)
	end
end

return Keybind
