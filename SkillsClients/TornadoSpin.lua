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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.0, Pitch = 0.8})

	local Tornado = Instance.new("Part")
	Tornado.Material = Enum.Material.Neon
	Tornado.Color = Color3.fromRGB(200, 200, 200)
	Tornado.Shape = Enum.PartType.Cylinder
	Tornado.Size = Vector3.new(30, 0, 30)
	Tornado.Anchored = false
	Tornado.CanCollide = false
	Tornado.Massless = true
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Tornado
	Weld.Part1 = Torso
	Weld.Parent = Tornado
	Tornado.CFrame = Torso.CFrame * CFrame.Angles(0, 0, math.rad(90))
	Tornado.Parent = Character
	Debris:AddItem(Tornado, 3)

	Tween:Play(Tornado, {0.3, "Quad", "Out"}, {
		Size = Vector3.new(30, 20, 20), Transparency = 0.5
	})
	
	task.delay(2.7, function()
		if Tornado then
			Tween:Play(Tornado, {0.3, "Quad", "In"}, {
				Size = Vector3.new(30, 0, 0), Transparency = 1
			})
		end
	end)
end
return Keybind
