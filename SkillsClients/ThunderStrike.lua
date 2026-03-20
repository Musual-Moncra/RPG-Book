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
	local OriginPosition = Character and Character:FindFirstChild("Torso") and Character.Torso.Position
	if not OriginPosition then return end

	local LocalPlayer = Players.LocalPlayer
	local Position = OriginPosition

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 2.5})
	
	-- Initial bolt from sky
	local MainBolt = Instance.new("Part")
	MainBolt.Name = "ThunderStrike_Main"
	MainBolt.Material = Enum.Material.Neon
	MainBolt.Color = Color3.fromRGB(100, 200, 255)
	MainBolt.Anchored = true
	MainBolt.CastShadow = false
	MainBolt.CanCollide = false
	MainBolt.Position = Position + Vector3.new(0, 100, 0)
	MainBolt.Size = Vector3.new(3, 200, 3)
	MainBolt.Shape = Enum.PartType.Cylinder
	MainBolt.Orientation = Vector3.new(0, 90, 90)

	Tween:Play(MainBolt, {0.3, "Bounce", "Out"}, {
		Size = Vector3.new(0, 200, 0),
		Transparency = 1
	})
	
	MainBolt.Parent = Temporary
	Debris:AddItem(MainBolt, 1)

	-- Find up to 4 nearby mobs to simulate chain visually
	local possibleTargets = {}
	for _, mob in CollectionService:GetTagged("Mob") do
		local torso = mob:FindFirstChild("Torso")
		if torso and (torso.Position - Position).Magnitude < 40 then
			table.insert(possibleTargets, torso)
		end
	end
	
	-- Draw chains visually
	task.spawn(function()
		local currentPos = Position
		for i = 1, math.min(4, #possibleTargets) do
			task.wait(0.2)
			local target = possibleTargets[i]
			if not target then break end
			
			local targetPos = target.Position
			local dist = (targetPos - currentPos).Magnitude
			local midPoint = currentPos + (targetPos - currentPos) / 2
			
			SFX:Play3D(9066732918, targetPos, {MaxDistance = 100, MinDistance = 20, Pitch = 1.8})
			
			local Chain = Instance.new("Part")
			Chain.Name = "ThunderStrike_Chain"
			Chain.Material = Enum.Material.Neon
			Chain.Color = Color3.fromRGB(50, 150, 255)
			Chain.Anchored = true
			Chain.CastShadow = false
			Chain.CanCollide = false
			Chain.Size = Vector3.new(1, dist, 1)
			Chain.CFrame = CFrame.lookAt(currentPos, targetPos) * CFrame.Angles(math.pi/2, 0, 0)
			Chain.Position = midPoint
			
			Tween:Play(Chain, {0.3, "Quad", "In"}, {
				Size = Vector3.new(0, dist, 0),
				Transparency = 1
			})
			
			Chain.Parent = Temporary
			Debris:AddItem(Chain, 1)
			
			currentPos = targetPos
		end
	end)
end

return Keybind
