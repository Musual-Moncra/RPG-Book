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

	local OriginPosition = Character.Torso.Position
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local targetCenter = HRP and (HRP.Position + HRP.CFrame.LookVector * 25) or OriginPosition
	local Position = Floor(targetCenter) or targetCenter

	local Seed = math.floor(Position.X + Position.Y + Position.Z)
	local RNG = Random.new(Seed)

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.5})

	-- Main zone indicator
	local Zone = Instance.new("Part")
	Zone.Name = "MeteorBarrage_Zone"
	Zone.Material = Enum.Material.Neon
	Zone.Color = Color3.fromRGB(200, 50, 0)
	Zone.Anchored = true
	Zone.CastShadow = false
	Zone.CanCollide = false
	Zone.Position = Position
	Zone.Size = Vector3.new(1, 60, 60)
	Zone.Shape = Enum.PartType.Cylinder
	Zone.Orientation = Vector3.new(0, 90, 90)
	Zone.Transparency = 1
	
	Tween:Play(Zone, {0.3, "Quad", "Out"}, {Transparency = 0.7})
	Zone.Parent = Temporary
	Debris:AddItem(Zone, 4.5)
	
	task.delay(4.0, function()
		Tween:Play(Zone, {0.5, "Quad", "In"}, {Transparency = 1})
	end)

	task.spawn(function()
		for i = 1, 10 do
			task.wait(0.4)
			
			local offsetX = RNG:NextNumber(-30, 30)
			local offsetZ = RNG:NextNumber(-30, 30)
			local strikePosRaw = Position + Vector3.new(offsetX, 0, offsetZ)
			local strikePos = Floor(strikePosRaw) or strikePosRaw
			
			-- Warning Mark
			local Mark = Instance.new("Part")
			Mark.Material = Enum.Material.Neon
			Mark.Color = Color3.fromRGB(255, 100, 0)
			Mark.Anchored = true
			Mark.CanCollide = false
			Mark.Size = Vector3.new(1, 1, 1)
			Mark.Position = strikePos
			Mark.Shape = Enum.PartType.Cylinder
			Mark.Orientation = Vector3.new(0, 90, 90)
			Mark.Parent = Temporary
			Debris:AddItem(Mark, 0.4)
			
			Tween:Play(Mark, {0.3, "Quad", "Out"}, {Size = Vector3.new(1, 30, 30), Transparency = 1})
			
			-- The Meteor
			local Meteor = Instance.new("Part")
			Meteor.Material = Enum.Material.Neon
			Meteor.Color = Color3.fromRGB(255, 150, 50)
			Meteor.Anchored = true
			Meteor.CanCollide = false
			Meteor.Size = Vector3.one * 5
			Meteor.Shape = Enum.PartType.Ball
			Meteor.Position = strikePos + Vector3.new(RNG:NextNumber(-10, 10), 100, RNG:NextNumber(-10, 10))
			Meteor.Parent = Temporary
			Debris:AddItem(Meteor, 1)
			
			Tween:Play(Meteor, {0.3, "Quad", "In"}, {Position = strikePos})
			
			task.delay(0.3, function()
				Meteor.Transparency = 1
				SFX:Play3D(9066732918, strikePos, {MaxDistance = 150, MinDistance = 30, Pitch = RNG:NextNumber(0.8, 1.2)})
				
				local explosion = Instance.new("Part")
				explosion.Material = Enum.Material.Neon
				explosion.Color = Color3.fromRGB(255, 50, 0)
				explosion.Anchored = true
				explosion.CanCollide = false
				explosion.Size = Vector3.one * 5
				explosion.Position = strikePos
				explosion.Shape = Enum.PartType.Ball
				explosion.Parent = Temporary
				Debris:AddItem(explosion, 0.5)
				
				Tween:Play(explosion, {0.4, "Quad", "Out"}, {Size = Vector3.one * 30, Transparency = 1})
			end)
		end
	end)
end

return Keybind
