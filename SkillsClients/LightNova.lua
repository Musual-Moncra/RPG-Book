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

	SFX:Play3D(9125644676, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 1.2})

	-- Charge up spheres
	do
		local Object = Instance.new("Part")
		Object.Name = "LightNova_Charge"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(255, 255, 127)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 1
		Object.Size = Vector3.one * 25
		Object.Position = Position
		Object.Shape = Enum.PartType.Ball

		Tween:Play(Object, {0.1}, {Transparency = 0.9})

		task.delay(0.1, function()
			Tween:Play(Object, {0.8, "Circular", "In"}, {
				Transparency = 0, 
				Size = Vector3.one * 2, 
			})
		end)

		Object.Parent = Temporary
		Debris:AddItem(Object, 1.5)
	end
	
	-- Ground Rune / Mark
	do
		local Object = Instance.new("Part")
		Object.Name = "LightNova_Mark"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(255, 255, 255)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Position = Floor(Position)

		Object.Size = Vector3.new(1, 40, 40)
		Object.Shape = Enum.PartType.Cylinder
		Object.Orientation = Vector3.new(0, 90, 90)

		Object.Transparency = 1
		Tween:Play(Object, {1.0, "Quad", "Out"}, {
			Transparency = 0.5,
		})

		Object.Parent = Temporary
		Debris:AddItem(Object, 2.5)
		
		task.delay(1.2, function()
			Tween:Play(Object, {0.5, "Quad"}, {
				Transparency = 1,
				Size = Vector3.new(1, 60, 60)
			})
		end)
	end

	-- The Detonation at 1.2s
	task.delay(1.2, function()
		SFX:Play3D(9066732918, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 0.8})
		SFX:Play3D(9116385087, Position, {Volume = 0.8, MaxDistance = 100, MinDistance = 20})

		-- Main Flash
		do
			local Object = Instance.new("Part")
			Object.Name = "LightNova_Flash"
			Object.Material = Enum.Material.Neon
			Object.Color = Color3.fromRGB(255, 255, 200)
			Object.Anchored = true
			Object.CastShadow = false
			Object.CanCollide = false
			Object.Transparency = 0
			Object.Size = Vector3.one * 5
			Object.Position = Position
			Object.Shape = Enum.PartType.Ball

			Tween:Play(Object, {0.6, "Circular", "Out"}, {
				Transparency = 1, 
				Size = Vector3.one * 50, 
			})

			Object.Parent = Temporary
			Debris:AddItem(Object, 1)
		end
		
		-- Upward Pillars
		for i = 1, 4 do
			local Object = Instance.new("Part")
			Object.Name = "LightNova_Pillar"
			Object.Material = Enum.Material.Neon
			Object.Color = Color3.fromRGB(255, 255, 100)
			Object.Anchored = true
			Object.CastShadow = false
			Object.CanCollide = false
			Object.Transparency = 0.3
			Object.Position = Floor(Position) + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
			
			Object.Size = Vector3.new(math.random(3, 6), 0.1, math.random(3, 6))
			local targetY = math.random(40, 70)

			Tween:Play(Object, {0.4, "Quad", "Out"}, {
				Transparency = 1, 
				Size = Vector3.new(1, targetY, 1), 
				Position = Object.Position + Vector3.new(0, targetY/2, 0)
			})

			Object.Parent = Temporary
			Debris:AddItem(Object, 1)
		end
	end)
end

return Keybind
