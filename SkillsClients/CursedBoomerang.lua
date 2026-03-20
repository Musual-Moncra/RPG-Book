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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 2})

	local Blade = Instance.new("Part")
	Blade.Material = Enum.Material.Neon
	Blade.Color = Color3.fromRGB(0, 0, 0)
	Blade.Shape = Enum.PartType.Cylinder
	Blade.Size = Vector3.new(0.5, 12, 12)
	Blade.Anchored = true
	Blade.CanCollide = false
	Blade.Position = Torso.Position
	Blade.Parent = Temporary
	Debris:AddItem(Blade, 2)
	
	local Forward = Torso.CFrame.LookVector * 60
	local MidPoint = Torso.Position + Forward

	-- Spin outward
	Tween:Play(Blade, {1.0, "Quad", "Out"}, {
		Position = MidPoint, Orientation = Vector3.new(0, 720, 90)
	})
	
	task.delay(1.0, function()
		SFX:Play3D(9116385079, MidPoint, {MaxDistance = 100, MinDistance = 20, Pitch = 1.5})
		-- Spin return
		if Character and Character:FindFirstChild("Torso") then
			Tween:Play(Blade, {1.0, "Quad", "In"}, {
				Position = Character.Torso.Position, Orientation = Vector3.new(0, 1440, 90)
			})
		else
			Tween:Play(Blade, {1.0, "Quad", "In"}, {
				Position = Torso.Position, Orientation = Vector3.new(0, 1440, 90)
			})
		end
	end)
end
return Keybind
