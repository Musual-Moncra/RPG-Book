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

	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 15)
	SFX:Play3D(12222030, TargetPos, {MaxDistance = 150, MinDistance = 20, Pitch = 1.2})

	local Turret = Instance.new("Part")
	Turret.Material = Enum.Material.Neon
	Turret.Color = Color3.fromRGB(255, 255, 200)
	Turret.Size = Vector3.new(2, 6, 2)
	Turret.Anchored = true
	Turret.CanCollide = false
	Turret.Position = TargetPos - Vector3.new(0, 10, 0)
	Turret.Parent = Temporary
	Debris:AddItem(Turret, 10)

	Tween:Play(Turret, {0.5, "Quad", "Out"}, {
		Position = TargetPos
	})
	
	-- Make it spin
	task.spawn(function()
		local t = 0
		while Turret.Parent and t < 100 do
			t = t + 1
			Tween:Play(Turret, {0.1}, {Orientation = Turret.Orientation + Vector3.new(0, 45, 0)})
			task.wait(0.1)
		end
	end)
end
return Keybind
