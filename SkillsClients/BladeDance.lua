-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end
	
	local function createSlash(Offset, Angle, DelayTime)
		task.delay(DelayTime, function()
			if not Character or not Character:FindFirstChild("Torso") then return end
			local Slash = Instance.new("Part")
			Slash.Material = Enum.Material.Neon
			Slash.Color = Color3.fromRGB(200, 200, 255)
			Slash.Size = Vector3.new(0.5, 15, 3)
			Slash.Anchored = true
			Slash.CanCollide = false
			Slash.Position = Torso.Position + Offset
			Slash.Orientation = Angle
			Slash.Parent = Temporary
			Debris:AddItem(Slash, 0.5)

			SFX:Play3D(9116385079, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8, Pitch = math.random(1.2, 1.5)})

			Tween:Play(Slash, {0.3, "Quad", "Out"}, {
				Size = Vector3.new(0, 25, 1),
				Transparency = 1
			})
		end)
	end
	
	createSlash(Vector3.new(5, 0, 0), Vector3.new(0, 45, 45), 0)
	createSlash(Vector3.new(-5, 0, 5), Vector3.new(0, -45, -45), 0.3)
	createSlash(Vector3.new(0, 5, -5), Vector3.new(45, 0, 90), 0.6)
	createSlash(Vector3.new(0, -5, 5), Vector3.new(-45, 0, -90), 0.9)
end
return Keybind
