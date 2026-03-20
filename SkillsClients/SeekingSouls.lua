-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")
local RunService = game:GetService("RunService")

local Keybind = {}
function Keybind:OnActivated(Player) end
function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 0.5})

	for i = 1, 5 do
		local Ghost = Instance.new("Part")
		Ghost.Material = Enum.Material.Neon
		Ghost.Color = Color3.fromRGB(100, 255, 200)
		Ghost.Shape = Enum.PartType.Ball
		Ghost.Size = Vector3.one * 3
		Ghost.Anchored = false
		Ghost.CanCollide = false
		Ghost.Position = Torso.Position + Vector3.new(math.random(-10,10), math.random(5,15), math.random(-10,10))
		
		local BV = Instance.new("BodyVelocity")
		BV.MaxForce = Vector3.new(1,1,1)*math.huge
		BV.Velocity = Vector3.new(math.random(-20,20), 20, math.random(-20,20))
		BV.Parent = Ghost
		
		Ghost.Parent = Temporary
		Debris:AddItem(Ghost, 3)
		
		task.delay(0.5, function()
			Tween:Play(Ghost, {2.5, "Linear"}, {Transparency = 1, Size = Vector3.zero})
		end)
	end
end
return Keybind
