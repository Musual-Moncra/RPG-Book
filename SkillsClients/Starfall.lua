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
	
	local Position = OriginPosition

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.5})

	-- Giant sky ring
	do
		local Ring = Instance.new("Part")
		Ring.Name = "Starfall_Ring"
		Ring.Material = Enum.Material.Neon
		Ring.Color = Color3.fromRGB(255, 200, 50)
		Ring.Anchored = true
		Ring.CastShadow = false
		Ring.CanCollide = false
		Ring.Position = Position + Vector3.new(0, 60, 0)
		Ring.Size = Vector3.new(2, 5, 5)
		Ring.Shape = Enum.PartType.Cylinder
		Ring.Orientation = Vector3.new(0, 90, 90)

		Ring.Transparency = 1
		Tween:Play(Ring, {0.5, "Quad", "Out"}, {
			Transparency = 0.4,
			Size = Vector3.new(5, 120, 120)
		})
		
		task.delay(1.5, function()
			Tween:Play(Ring, {1.0, "Quad", "In"}, {
				Transparency = 1,
				Size = Vector3.new(0, 0, 0)
			})
		end)

		Ring.Parent = Temporary
		Debris:AddItem(Ring, 3)
	end
	
	task.delay(0.4, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso and (Torso.Position - Position).Magnitude < 50 then
				
				local targetPos = Floor(Torso.Position)
				local delayTime = math.random() * 0.5
				
				task.delay(delayTime, function()
					SFX:Play3D(9066732918, targetPos, {MaxDistance = 100, MinDistance = 20, Pitch = 1.2})
					
					-- Meteor falling
					local Meteor = Instance.new("Part")
					Meteor.Name = "Starfall_Meteor"
					Meteor.Material = Enum.Material.Neon
					Meteor.Color = Color3.fromRGB(255, 255, 100)
					Meteor.Anchored = true
					Meteor.CastShadow = false
					Meteor.CanCollide = false
					Meteor.Size = Vector3.one * 3
					Meteor.Position = targetPos + Vector3.new(math.random(-10, 10), 80, math.random(-10, 10))
					Meteor.Shape = Enum.PartType.Ball
					
					Tween:Play(Meteor, {0.3, "Quad", "In"}, {
						Position = targetPos
					})
					
					Meteor.Parent = Temporary
					Debris:AddItem(Meteor, 1)
					
					task.delay(0.3, function()
						Meteor.Transparency = 1
						
						-- Impact explosion
						local Impact = Instance.new("Part")
						Impact.Name = "Starfall_Impact"
						Impact.Material = Enum.Material.Neon
						Impact.Color = Color3.fromRGB(255, 100, 50)
						Impact.Anchored = true
						Impact.CastShadow = false
						Impact.CanCollide = false
						Impact.Size = Vector3.one * 2
						Impact.Position = targetPos
						Impact.Shape = Enum.PartType.Ball
						
						Tween:Play(Impact, {0.4, "Quad", "Out"}, {
							Transparency = 1,
							Size = Vector3.new(20, 20, 20)
						})
						
						Impact.Parent = Temporary
						Debris:AddItem(Impact, 1)
					end)
				end)
			end
		end
	end)
end

return Keybind
