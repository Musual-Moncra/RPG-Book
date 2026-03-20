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

	local TargetPos = Torso.Position + (Torso.CFrame.LookVector * 30)
	
	-- Big ground crack alert
	SFX:Play3D(12222030, TargetPos, {MaxDistance = 200, MinDistance = 40, Volume = 2.0, Pitch = 0.5})
	
	local Warning = Instance.new("Part")
	Warning.Material = Enum.Material.Neon
	Warning.Color = Color3.fromRGB(150, 0, 255)
	Warning.Shape = Enum.PartType.Cylinder
	Warning.Size = Vector3.new(0.5, 40, 40)
	Warning.Anchored = true
	Warning.CanCollide = false
	Warning.Position = TargetPos
	Warning.Orientation = Vector3.new(0, 0, 90)
	Warning.Transparency = 0.5
	Warning.Parent = Temporary
	Debris:AddItem(Warning, 1.5)
	
	Tween:Play(Warning, {1.0, "Quad", "Out"}, {Transparency = 1})

	-- Dragon bite up from ground after 1s
	task.delay(1.0, function()
		SFX:Play3D(9116385079, TargetPos, {MaxDistance = 300, MinDistance = 60, Volume = 3.0, Pitch = 0.6})
		
		local DragonHead = Instance.new("Part")
		DragonHead.Material = Enum.Material.Neon
		DragonHead.Color = Color3.fromRGB(100, 0, 200)
		DragonHead.Size = Vector3.new(30, 50, 30)
		DragonHead.Anchored = true
		DragonHead.CanCollide = false
		DragonHead.Position = TargetPos - Vector3.new(0, 30, 0)
		DragonHead.Parent = Temporary
		Debris:AddItem(DragonHead, 2)
		
		Tween:Play(DragonHead, {0.3, "Quad", "Out"}, {
			Position = TargetPos + Vector3.new(0, 10, 0)
		})
		
		task.delay(0.5, function()
			Tween:Play(DragonHead, {0.3, "Quad", "In"}, {
				Position = TargetPos - Vector3.new(0, 30, 0), Transparency = 1
			})
		end)
	end)
end
return Keybind
