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

	for i = 1, 5 do
		task.delay((i-1)*0.2, function()
			if not Character or not Character:FindFirstChild("Torso") then return end
			SFX:Play3D(9125644676, Character.Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8, Pitch = 3})
			local Bolt = Instance.new("Part")
			Bolt.Material = Enum.Material.Neon
			Bolt.Color = Color3.fromRGB(150, 255, 255)
			Bolt.Size = Vector3.new(0.5, 20, 0.5)
			Bolt.Anchored = true
			Bolt.CanCollide = false
			Bolt.CFrame = Character.Torso.CFrame * CFrame.Angles(math.random(-1,1), math.random(-1,1), math.random(-1,1))
			Bolt.Parent = Temporary
			Debris:AddItem(Bolt, 0.3)
			Tween:Play(Bolt, {0.2, "Quad", "Out"}, {Size = Vector3.new(0,0,0), Transparency = 1})
			
			local Slash = Instance.new("Part")
			Slash.Material = Enum.Material.Neon
			Slash.Color = Color3.fromRGB(150, 255, 255)
			Slash.Size = Vector3.new(0.5, 20, 3)
			Slash.Anchored = true
			Slash.CanCollide = false
			Slash.CFrame = Character.Torso.CFrame * CFrame.new(0,0,-5) * CFrame.Angles(0,0,math.rad(math.random(0,360)))
			Slash.Parent = Temporary
			Debris:AddItem(Slash, 0.3)
			Tween:Play(Slash, {0.2}, {Size = Vector3.new(0, 40, 0), Transparency = 1})
		end)
	end
end
return Keybind
