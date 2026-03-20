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

	SFX:Play3D(9125644676, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 2.0})

	-- Teleport outward burst at original position
	do
		local Object = Instance.new("Part")
		Object.Name = "VoidBlink_Burst"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(80, 0, 150)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 0
		Object.Size = Vector3.one * 5
		Object.Position = Position
		Object.Shape = Enum.PartType.Ball

		Tween:Play(Object, {0.3, "Quad", "Out"}, {
			Transparency = 1,
			Size = Vector3.one * 25
		})

		Object.Parent = Temporary
		Debris:AddItem(Object, 1)
	end
	
	task.delay(0.4, function()
		-- We need the new position from the character
		local newPos = Character and Character:FindFirstChild("Torso") and Character.Torso.Position
		if not newPos then return end
		
		SFX:Play3D(9066732918, newPos, {MaxDistance = 100, MinDistance = 20, Pitch = 1.5})
		
		-- Reappear burst
		local Reappear = Instance.new("Part")
		Reappear.Name = "VoidBlink_Reappear"
		Reappear.Material = Enum.Material.Neon
		Reappear.Color = Color3.fromRGB(150, 0, 255)
		Reappear.Anchored = true
		Reappear.CastShadow = false
		Reappear.CanCollide = false
		Reappear.Transparency = 0
		Reappear.Size = Vector3.one * 5
		Reappear.Position = newPos
		Reappear.Shape = Enum.PartType.Ball

		Tween:Play(Reappear, {0.4, "Quad", "Out"}, {
			Transparency = 1,
			Size = Vector3.one * 20
		})

		Reappear.Parent = Temporary
		Debris:AddItem(Reappear, 1)
	end)
end

return Keybind
