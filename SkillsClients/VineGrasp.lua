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

	-- Snapshot gives Cursor position, let's use LookVector to guess cursor position since client doesn't get Snapshot easily inside OnLetGo
	local OriginPosition = Character.Torso.Position
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local targetCenter = HRP and (HRP.Position + HRP.CFrame.LookVector * 15) or OriginPosition
	local Position = Floor(targetCenter) or targetCenter

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.6})

	-- Ground flora ring
	local Ring = Instance.new("Part")
	Ring.Name = "VineGrasp_Ring"
	Ring.Material = Enum.Material.Grass
	Ring.Color = Color3.fromRGB(50, 150, 50)
	Ring.Anchored = true
	Ring.CastShadow = false
	Ring.CanCollide = false
	Ring.Position = Position
	Ring.Size = Vector3.new(1, 10, 10)
	Ring.Shape = Enum.PartType.Cylinder
	Ring.Orientation = Vector3.new(0, 90, 90)

	Tween:Play(Ring, {0.5, "Bounce", "Out"}, {
		Size = Vector3.new(2, 70, 70), -- 35 radius = 70 diameter
		Transparency = 0.2
	})
	
	Ring.Parent = Temporary
	Debris:AddItem(Ring, 4.5)
	
	task.delay(4.0, function()
		Tween:Play(Ring, {0.5, "Quad", "In"}, {
			Size = Vector3.new(0, 75, 75),
			Transparency = 1
		})
	end)

	-- Spawning Thorny Roots
	task.spawn(function()
		SFX:Play3D(9066732918, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.7})
		
		for i = 1, 20 do
			local angle = math.rad(math.random(0, 360))
			local radius = math.random(5, 30)
			local rootPosRaw = Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			local rootPos = Floor(rootPosRaw) or rootPosRaw
			
			local Root = Instance.new("Part")
			Root.Material = Enum.Material.Wood
			Root.Color = Color3.fromRGB(60, 40, 20)
			Root.Anchored = true
			Root.CanCollide = false
			local blockHeight = math.random(10, 25)
			Root.Size = Vector3.new(math.random(2, 4), blockHeight, math.random(2, 4))
			Root.Position = rootPos - Vector3.new(0, blockHeight, 0)
			
			-- Twist them like thorny vines
			Root.Orientation = Vector3.new(math.random(-30, 30), math.random(0, 360), math.random(-30, 30))
			
			Root.Parent = Temporary
			Debris:AddItem(Root, 4.5)
			
			Tween:Play(Root, {0.4, "Back", "Out"}, {
				Position = rootPos + Vector3.new(0, blockHeight/2 - 2, 0)
			})
			
			task.delay(3.5 + math.random()*0.5, function()
				Tween:Play(Root, {0.8, "Quad", "In"}, {
					Position = rootPos - Vector3.new(0, blockHeight, 0),
					Transparency = 1
				})
			end)
		end
	end)
end

return Keybind
