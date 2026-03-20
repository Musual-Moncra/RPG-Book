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

	local Position = Character 
		and Character:FindFirstChild("Torso")
		and Character.Torso.Position

	if not Position then 
		return
	end

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - Position).Magnitude > GameConfig.DefaultDistanceRadius * 1.25) then
		return
	end

	-- Chilling sound
	SFX:Play3D(9125644676, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 0.6})

	-- Ground frost ring
	do
		local Object = Instance.new("Part")
		Object.Name = "FrostSurge_Ring"
		Object.Material = Enum.Material.Ice
		Object.Color = Color3.fromRGB(150, 200, 255)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Position = Floor(Position)

		Object.Size = Vector3.new(1, 10, 10)
		Object.Shape = Enum.PartType.Cylinder
		Object.Orientation = Vector3.new(0, 90, 90)

		Object.Transparency = 0.5
		Tween:Play(Object, {0.6, "Quad", "Out"}, {
			Size = Vector3.new(1, 40, 40),
			Transparency = 1
		})

		Object.Parent = Temporary
		Debris:AddItem(Object, 1)
	end
	
	-- Ice spikes erupting
	task.delay(0.2, function()
		SFX:Play3D(9066732918, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 1.5})
		
		for i = 1, 12 do
			-- Distribute spikes around inner and outer radius
			local angle = math.rad((i / 12) * 360 + math.random(-10, 10))
			local radius = math.random(5, 18)
			
			local spikePos = Floor(Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
			
			local Object = Instance.new("Part")
			Object.Name = "FrostSurge_Spike"
			Object.Material = Enum.Material.Ice
			Object.Color = Color3.fromRGB(150, 230, 255)
			Object.Anchored = true
			Object.CastShadow = false
			Object.CanCollide = false
			Object.Transparency = 0.2
			Object.Position = spikePos - Vector3.new(0, 10, 0)
			
			Object.Size = Vector3.new(math.random(2, 5), math.random(10, 25), math.random(2, 5))
			Object.Orientation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15))

			Tween:Play(Object, {0.3, "Back", "Out"}, {
				Position = spikePos + Vector3.new(0, Object.Size.Y/2 - 2, 0)
			})

			Object.Parent = Temporary
			Debris:AddItem(Object, 3)
			
			-- Melt away
			task.delay(1.5 + math.random() * 0.5, function()
				Tween:Play(Object, {0.5, "Quad", "In"}, {
					Transparency = 1,
					Position = spikePos - Vector3.new(0, 10, 0)
				})
			end)
		end
	end)
end

return Keybind
