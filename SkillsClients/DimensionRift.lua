-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
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
	
	local StartPos = Torso.Position
	local EndPos = StartPos + (Torso.CFrame.LookVector * 40) -- Predicted Teleport Pos
	
	-- Play teleport SFX
	SFX:Play3D(9125644676, StartPos, {MaxDistance = 100, MinDistance = 20, Volume = 0.8})

	-- Create Rift at Start Pos
	local Rift = Instance.new("Part")
	Rift.Name = "DimensionRift"
	Rift.Material = Enum.Material.Neon
	Rift.Color = Color3.fromRGB(138, 43, 226) -- Purple
	Rift.Shape = Enum.PartType.Ball
	Rift.Size = Vector3.zero
	Rift.Anchored = true
	Rift.CanCollide = false
	Rift.Position = StartPos
	Rift.Parent = Temporary
	Debris:AddItem(Rift, 2)

	Tween:Play(Rift, {0.3, "Circular", "Out"}, {
		Size = Vector3.one * 8,
		Transparency = 0.5
	})
	
	-- Portal explosion at 1.5s
	task.delay(1.5, function()
		SFX:Play3D(9116385079, StartPos, {MaxDistance = 150, MinDistance = 20, Volume = 1})
		
		Tween:Play(Rift, {0.2, "Quad", "Out"}, {
			Size = Vector3.one * 25,
			Transparency = 1
		})
	end)
	
	-- Flash at destination
	local EndFlash = Instance.new("Part")
	EndFlash.Material = Enum.Material.Neon
	EndFlash.Color = Color3.fromRGB(138, 43, 226)
	EndFlash.Shape = Enum.PartType.Ball
	EndFlash.Size = Vector3.one * 10
	EndFlash.Anchored = true
	EndFlash.CanCollide = false
	EndFlash.Position = EndPos
	EndFlash.Parent = Temporary
	Debris:AddItem(EndFlash, 1)
	
	Tween:Play(EndFlash, {0.5, "Quad", "Out"}, {
		Size = Vector3.zero,
		Transparency = 1
	})
end
return Keybind
