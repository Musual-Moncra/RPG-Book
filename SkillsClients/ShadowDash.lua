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

local RaycastParamsFilter = RaycastParams.new()
RaycastParamsFilter.FilterDescendantsInstances = {
	workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"),
	workspace:WaitForChild("Mobs"), workspace.Zones, workspace.Teleports, workspace.Map.Doors
}
RaycastParamsFilter.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsFilter.RespectCanCollide = true

local Duration = 1.0

--------------------------------------------------------------------------------

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParamsFilter)
	return Raycast and Raycast.Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local OriginPosition = Character.HumanoidRootPart.Position
	local LookVector = Character.HumanoidRootPart.CFrame.LookVector

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	-- Replicate Raycast safety to perfectly match server's line
	local rayHit = workspace:Raycast(OriginPosition, LookVector * 40, RaycastParamsFilter)
	local TargetPos = rayHit and rayHit.Position or (OriginPosition + LookVector * 40)
	
	local dist = (TargetPos - OriginPosition).Magnitude
	local midPoint = OriginPosition + (TargetPos - OriginPosition)/2

	SFX:Play3D(9125644676, OriginPosition, {MaxDistance = 150, MinDistance = 30, Pitch = 1.5})
	SFX:Play3D(9066732918, TargetPos, {MaxDistance = 150, MinDistance = 30, Pitch = 0.5})

	-- Create massive shadow slash trail
	local trail = Instance.new("Part")
	trail.Name = "ShadowDash_Trail"
	trail.Material = Enum.Material.Neon
	trail.Color = Color3.fromRGB(50, 0, 100) -- Dark Purple
	trail.Anchored = true
	trail.CastShadow = false
	trail.CanCollide = false
	trail.Size = Vector3.new(2, 2, dist)
	trail.CFrame = CFrame.lookAt(midPoint, TargetPos)
	trail.Parent = Temporary
	Debris:AddItem(trail, 1)

	Tween:Play(trail, {0.3, "Quad", "Out"}, {
		Size = Vector3.new(15, 15, dist),
		Transparency = 1
	})
	
	-- Burst at origin and target
	for _, pos in {OriginPosition, TargetPos} do
		local Burst = Instance.new("Part")
		Burst.Material = Enum.Material.Neon
		Burst.Color = Color3.fromRGB(0, 0, 0)
		Burst.Anchored = true
		Burst.CanCollide = false
		Burst.Size = Vector3.new(5, 5, 5)
		Burst.Shape = Enum.PartType.Ball
		Burst.Position = pos
		Burst.Parent = Temporary
		Debris:AddItem(Burst, 0.5)
		
		Tween:Play(Burst, {0.4, "Quad", "Out"}, {Size = Vector3.new(20, 20, 20), Transparency = 1})
	end
end

return Keybind
