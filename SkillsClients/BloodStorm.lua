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

	-- Initial aura
	do
		local aura = Instance.new("Part")
		aura.Name = "BloodStorm_Aura"
		aura.Material = Enum.Material.Neon
		aura.Color = Color3.fromRGB(170, 0, 0)
		aura.Anchored = true
		aura.CastShadow = false
		aura.CanCollide = false
		aura.Transparency = 1
		aura.Size = Vector3.one * 5
		aura.Position = Position
		aura.Shape = Enum.PartType.Ball

		Tween:Play(aura, {0.3}, {
			Transparency = 0.6,
			Size = Vector3.one * 30
		})

		aura.Parent = Temporary
		Debris:AddItem(aura, 2)
		
		task.delay(1.2, function()
			Tween:Play(aura, {0.4, "Quad", "In"}, {
				Transparency = 1,
				Size = Vector3.zero
			})
		end)
	end

	-- 3 Waves of slashes
	for wave = 1, 3 do
		task.delay(0.2 + (wave * 0.3), function()
			SFX:Play3D(9125644676, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 1.0 + (wave * 0.1)})
			
			-- Generate 4-6 random slashes per wave
			local slashCount = math.random(4, 6)
			for i = 1, slashCount do
				local Object = Instance.new("Part")
				Object.Name = "BloodStorm_Slash"
				Object.Material = Enum.Material.Neon
				Object.Color = Color3.fromRGB(200, 0, 0)
				Object.Anchored = true
				Object.CastShadow = false
				Object.CanCollide = false
				
				local offset = Vector3.new(math.random(-12, 12), math.random(-5, 10), math.random(-12, 12))
				Object.Position = Position + offset
				
				Object.Size = Vector3.new(0.5, math.random(15, 25), math.random(2, 4))
				Object.Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))

				Object.Transparency = 1
				Tween:Play(Object, {0.1}, {
					Transparency = 0.2
				})

				task.delay(0.15, function()
					Tween:Play(Object, {0.3, "Quad", "Out"}, {
						Transparency = 1,
						Size = Vector3.new(0, Object.Size.Y * 1.5, 0)
					})
				end)

				Object.Parent = Temporary
				Debris:AddItem(Object, 1)
			end
			
			-- Shockwave on physical hit
			local GroundCyl = Instance.new("Part")
			GroundCyl.Name = "BloodStorm_Shockwave"
			GroundCyl.Material = Enum.Material.Neon
			GroundCyl.Color = Color3.fromRGB(255, 50, 50)
			GroundCyl.Anchored = true
			GroundCyl.CastShadow = false
			GroundCyl.CanCollide = false
			GroundCyl.Position = Floor(Position)

			GroundCyl.Size = Vector3.new(1, 5, 5)
			GroundCyl.Shape = Enum.PartType.Cylinder
			GroundCyl.Orientation = Vector3.new(0, 90, 90)

			GroundCyl.Transparency = 0.7
			Tween:Play(GroundCyl, {0.4, "Quad", "Out"}, {
				Size = Vector3.new(1, 35, 35),
				Transparency = 1
			})

			GroundCyl.Parent = Temporary
			Debris:AddItem(GroundCyl, 1)
		end)
	end
end

return Keybind
