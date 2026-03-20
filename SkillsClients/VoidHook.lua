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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 150, MinDistance = 20, Pitch = 2.5})
	
	local Hook = Instance.new("Part")
	Hook.Material = Enum.Material.Neon
	Hook.Color = Color3.fromRGB(150, 50, 255)
	Hook.Size = Vector3.new(0.5, 0.5, 60)
	Hook.Anchored = true
	Hook.CanCollide = false
	Hook.CFrame = Torso.CFrame * CFrame.new(0, 0, -30)
	Hook.Parent = Temporary
	Debris:AddItem(Hook, 0.5)

	Tween:Play(Hook, {0.3, "Linear"}, {
		Transparency = 1, Size = Vector3.new(0,0,60)
	})
	
	-- Impact
	task.delay(0.2, function()
		if Character and Character:FindFirstChild("Torso") then
			SFX:Play3D(9116385079, Character.Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.2})
		end
	end)
end
return Keybind
