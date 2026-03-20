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

	local OriginPosition = Character 
		and Character:FindFirstChild("Torso")
		and Character.Torso.Position

	if not OriginPosition then 
		return
	end

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end
	
	local Position = Floor(OriginPosition) or OriginPosition

	SFX:Play3D(9125644676, Position, {MaxDistance = 150, MinDistance = 30, Pitch = 0.4})

	-- Ground sludge
	local Sludge = Instance.new("Part")
	Sludge.Name = "VenomNova_Sludge"
	Sludge.Material = Enum.Material.Mud
	Sludge.Color = Color3.fromRGB(50, 150, 20)
	Sludge.Anchored = true
	Sludge.CastShadow = false
	Sludge.CanCollide = false
	Sludge.Position = Position
	Sludge.Size = Vector3.new(1, 10, 10)
	Sludge.Shape = Enum.PartType.Cylinder
	Sludge.Orientation = Vector3.new(0, 90, 90)

	Tween:Play(Sludge, {0.6, "Quad", "Out"}, {
		Size = Vector3.new(2, 60, 60),
		Transparency = 0.3
	})
	
	Sludge.Parent = Temporary
	Debris:AddItem(Sludge, 6)
	
	task.delay(5.0, function()
		Tween:Play(Sludge, {1.0, "Quad", "In"}, {
			Size = Vector3.new(0, 80, 80),
			Transparency = 1
		})
	end)

	-- Spawning toxic gas clouds over 5 seconds
	task.spawn(function()
		for i = 1, 20 do
			local angle = math.rad(math.random(0, 360))
			local radius = math.random(5, 25)
			
			local cloudPos = Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			
			local Gas = Instance.new("Part")
			Gas.Name = "VenomNova_Gas"
			Gas.Material = Enum.Material.Smoke
			Gas.Color = Color3.fromRGB(100, 255, 50)
			if math.random() > 0.5 then
				Gas.Color = Color3.fromRGB(150, 50, 200)
			end
			Gas.Anchored = true
			Gas.CastShadow = false
			Gas.CanCollide = false
			Gas.Shape = Enum.PartType.Ball
			Gas.Size = Vector3.one * 2
			Gas.Transparency = 0.3
			Gas.Position = cloudPos + Vector3.new(0, 2, 0)
			
			Gas.Parent = Temporary
			Debris:AddItem(Gas, 3)
			
			Tween:Play(Gas, {2.0, "Quad", "Out"}, {
				Size = Vector3.one * math.random(15, 25),
				Position = Gas.Position + Vector3.new(0, math.random(5, 10), 0),
				Transparency = 1
			})
			
			task.wait(0.25)
			if i % 3 == 0 then
				SFX:Play3D(9066732918, Position, {MaxDistance = 100, MinDistance = 20, Pitch = 0.5})
			end
		end
	end)
end

return Keybind
