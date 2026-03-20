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
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local OriginPosition = Character.HumanoidRootPart.Position
	local LookVector = Character.HumanoidRootPart.CFrame.LookVector
	local RightVector = LookVector:Cross(Vector3.new(0, 1, 0)).Unit

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	local targetCenter = OriginPosition + LookVector * 20
	local floorPosCenter = Floor(targetCenter) or targetCenter
	
	SFX:Play3D(9125644676, floorPosCenter, {MaxDistance = 150, MinDistance = 30, Pitch = 0.8})
	
	-- Draw Ice indicator
	local indicator = Instance.new("Part")
	indicator.Name = "GlacialWall_Indicator"
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(150, 200, 255)
	indicator.Anchored = true
	indicator.CastShadow = false
	indicator.CanCollide = false
	indicator.Size = Vector3.new(40, 0.5, 5)
	indicator.CFrame = CFrame.lookAt(targetCenter, targetCenter + LookVector)
	indicator.Position = floorPosCenter
	indicator.Parent = Temporary
	Debris:AddItem(indicator, 0.5)
	
	Tween:Play(indicator, {0.4, "Quad", "In"}, {Transparency = 1})
	
	-- Erupt the wall segments
	task.delay(0.4, function()
		SFX:Play3D(9066732918, floorPosCenter, {MaxDistance = 150, MinDistance = 30, Pitch = 1.2})
		
		for i = -15, 15, 3 do
			local segmentCenter = targetCenter + RightVector * i
			local floorPos = Floor(segmentCenter) or segmentCenter
			
			local Spike = Instance.new("Part")
			Spike.Name = "GlacialWall_Spike"
			Spike.Material = Enum.Material.Ice
			Spike.Color = Color3.fromRGB(150, 230, 255)
			Spike.Anchored = true
			Spike.CastShadow = false
			Spike.CanCollide = false
			
			local height = math.random(15, 35)
			local width = math.random(4, 7)
			
			Spike.Size = Vector3.new(width, height, 4)
			Spike.CFrame = CFrame.lookAt(floorPos, floorPos + LookVector) * CFrame.Angles(math.random(-15, 15)/100, 0, math.random(-15, 15)/100)
			Spike.Position = floorPos - Vector3.new(0, height, 0)

			Tween:Play(Spike, {0.3, "Bounce", "Out"}, {
				Position = floorPos + Vector3.new(0, height/2 - 2, 0)
			})
			
			Spike.Parent = Temporary
			Debris:AddItem(Spike, 4)
			
			-- Melt away
			task.delay(3.0 + math.random()*0.5, function()
				Tween:Play(Spike, {0.8, "Quad", "In"}, {
					Position = floorPos - Vector3.new(0, height, 0),
					Transparency = 1
				})
			end)
			
			task.wait(0.01)
		end
	end)
end

return Keybind
