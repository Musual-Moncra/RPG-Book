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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 1, Pitch = 3})

	local Poof = Instance.new("Part")
	Poof.Material = Enum.Material.Neon
	Poof.Color = Color3.fromRGB(150, 150, 255)
	Poof.Shape = Enum.PartType.Ball
	Poof.Size = Vector3.one * 5
	Poof.Anchored = true
	Poof.CanCollide = false
	Poof.Position = Torso.Position
	Poof.Parent = Temporary
	Debris:AddItem(Poof, 0.5)

	Tween:Play(Poof, {0.3, "Quad", "Out"}, {
		Size = Vector3.one * 15, Transparency = 1
	})
	
	task.delay(0.5, function()
		if Character and Character:FindFirstChild("Torso") then
			SFX:Play3D(9125644676, Character.Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 1, Pitch = 3})
			local Poof2 = Poof:Clone()
			Poof2.Position = Character.Torso.Position
			Poof2.Parent = Temporary
			Debris:AddItem(Poof2, 0.5)
			Tween:Play(Poof2, {0.3, "Quad", "Out"}, {
				Size = Vector3.one * 15, Transparency = 1
			})
			
			SFX:Play3D(9116385079, Character.Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1, Pitch = 1.5})
			local Slash = Instance.new("Part")
			Slash.Material = Enum.Material.Neon
			Slash.Color = Color3.fromRGB(150, 150, 255)
			Slash.Size = Vector3.new(0.5, 30, 2)
			Slash.Anchored = true
			Slash.CanCollide = false
			Slash.CFrame = Character.Torso.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, 0, math.rad(45))
			Slash.Parent = Temporary
			Debris:AddItem(Slash, 0.5)
			Tween:Play(Slash, {0.2, "Quad", "Out"}, {Size = Vector3.new(0.1, 40, 0.5), Transparency = 1})
		end
	end)
end
return Keybind
