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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 1.0, Pitch = 2})

	local Wisps = Instance.new("Part")
	Wisps.Material = Enum.Material.Neon
	Wisps.Color = Color3.fromRGB(150, 255, 150)
	Wisps.Shape = Enum.PartType.Ball
	Wisps.Size = Vector3.one * 2
	Wisps.Anchored = false
	Wisps.CanCollide = false
	Wisps.Massless = true
	
	local BP = Instance.new("BodyPosition", Wisps)
	BP.MaxForce = Vector3.one * math.huge
	BP.P = 10000
	
	Wisps.Position = Torso.Position + Vector3.new(5, 5, 0)
	Wisps.Parent = Temporary
	Debris:AddItem(Wisps, 15)
	
	task.spawn(function()
		local angle = 0
		while Wisps.Parent and Character.Parent and Torso.Parent do
			angle = angle + 0.1
			local offset = Vector3.new(math.cos(angle)*5, 4 + math.sin(angle*2)*2, math.sin(angle)*5)
			BP.Position = Torso.Position + offset
			task.wait(0.05)
		end
	end)
end
return Keybind
