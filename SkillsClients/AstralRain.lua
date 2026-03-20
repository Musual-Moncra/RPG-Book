-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"), workspace:WaitForChild("Mobs"), workspace:WaitForChild("Zones")}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), RaycastParams)
	return Raycast and Raycast.Position or Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end
	
	local TargetPos = Floor(Torso.Position + (Torso.CFrame.LookVector * 25))
	
	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 150, MinDistance = 30, Volume = 1.0, Pitch = 1.5})
	
	local TargetCircle = Instance.new("Part")
	TargetCircle.Material = Enum.Material.Neon
	TargetCircle.Color = Color3.fromRGB(150, 150, 255)
	TargetCircle.Shape = Enum.PartType.Cylinder
	TargetCircle.Size = Vector3.new(0.5, 30, 30)
	TargetCircle.Anchored = true
	TargetCircle.CanCollide = false
	TargetCircle.Position = TargetPos
	TargetCircle.Orientation = Vector3.new(0, 0, 90)
	TargetCircle.Transparency = 0.5
	TargetCircle.Parent = Temporary
	Debris:AddItem(TargetCircle, 3)

	Tween:Play(TargetCircle, {3, "Linear"}, {
		Transparency = 1
	})
	
	for i = 1, 15 do
		task.delay(math.random() * 2, function()
			local Arrow = Instance.new("Part")
			Arrow.Material = Enum.Material.Neon
			Arrow.Color = Color3.fromRGB(150, 150, 255)
			Arrow.Size = Vector3.new(0.5, 8, 0.5)
			Arrow.Anchored = true
			Arrow.CanCollide = false
			local rX = TargetPos.X + math.random(-15, 15)
			local rZ = TargetPos.Z + math.random(-15, 15)
			
			Arrow.Position = Vector3.new(rX, TargetPos.Y + 60, rZ)
			Arrow.Orientation = Vector3.new(90, 0, 0)
			Arrow.Parent = Temporary
			Debris:AddItem(Arrow, 1)
			
			Tween:Play(Arrow, {0.3, "Linear"}, {
				Position = Vector3.new(rX, TargetPos.Y, rZ)
			})
			
			task.delay(0.3, function()
				SFX:Play3D(9116385079, Arrow.Position, {MaxDistance = 80, MinDistance = 10, Volume = 0.4, Pitch = 2})
				Arrow.Size = Vector3.new(3, 0.5, 3)
				Arrow.Shape = Enum.PartType.Ball
				Tween:Play(Arrow, {0.2, "Linear"}, {
					Size = Vector3.zero, Transparency = 1
				})
			end)
		end)
	end
end
return Keybind
