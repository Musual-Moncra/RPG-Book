-- [CLIENT] --> Shared to all clients
--> References
local CollectionService = game:GetService("CollectionService")
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

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("Torso") then return end

	-- Try to use Snapshot Position if we can, but let's just use Origin/LookVector
	local OriginPosition = Character.Torso.Position
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local targetCenter = HRP and (HRP.Position + HRP.CFrame.LookVector * 20) or OriginPosition
	local Position = Floor(targetCenter) or targetCenter

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 3.0})

	-- Ground Rune Trap
	local Rune = Instance.new("Part")
	Rune.Name = "ChronoTrap_Rune"
	Rune.Material = Enum.Material.Neon
	Rune.Color = Color3.fromRGB(0, 255, 255)
	Rune.Anchored = true
	Rune.CastShadow = false
	Rune.CanCollide = false
	Rune.Position = Position + Vector3.new(0, 0.5, 0)
	Rune.Size = Vector3.new(0.5, 40, 40)
	Rune.Shape = Enum.PartType.Cylinder
	Rune.Orientation = Vector3.new(0, 90, 90)

	Rune.Transparency = 1
	Tween:Play(Rune, {0.5, "Quad", "Out"}, {
		Transparency = 0.5
	})
	
	-- Ticking Rotation over 3 seconds
	Tween:Play(Rune, {3.0, "Linear"}, {
		Orientation = Rune.Orientation + Vector3.new(0, 360, 0)
	})

	Rune.Parent = Temporary
	Debris:AddItem(Rune, 4)
	
	for tick = 1, 3 do
		task.delay(tick - 0.5, function()
			SFX:Play3D(9066732918, Position, {MaxDistance = 150, MinDistance = 40, Pitch = 2.0})
			
			local pulse = Rune:Clone()
			pulse.Parent = Temporary
			pulse.Transparency = 0.5
			Tween:Play(pulse, {0.6, "Quad", "Out"}, {
				Size = Vector3.new(0.5, 60, 60),
				Transparency = 1
			})
			Debris:AddItem(pulse, 0.6)
		end)
	end
	
	-- Detonation at 3s
	task.delay(3.0, function()
		SFX:Play3D(9116385087, Position, {MaxDistance = 200, MinDistance = 50, Pitch = 0.8})
		
		Rune.Transparency = 1
		
		local Explosion = Instance.new("Part")
		Explosion.Name = "ChronoTrap_Explosion"
		Explosion.Material = Enum.Material.Glass
		Explosion.Color = Color3.fromRGB(200, 255, 255)
		Explosion.Anchored = true
		Explosion.CastShadow = false
		Explosion.CanCollide = false
		Explosion.Position = Position + Vector3.new(0, 5, 0)
		Explosion.Size = Vector3.one * 5
		Explosion.Shape = Enum.PartType.Ball
		
		Tween:Play(Explosion, {0.4, "Bounce", "Out"}, {
			Size = Vector3.one * 70,
			Transparency = 0.8
		})
		
		Explosion.Parent = Temporary
		Debris:AddItem(Explosion, 2)
		
		task.delay(0.5, function()
			Tween:Play(Explosion, {0.8, "Quad", "In"}, {
				Size = Vector3.new(0, 0, 0),
				Transparency = 1
			})
		end)
	end)
end

return Keybind
