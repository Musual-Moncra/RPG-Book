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

	-- 3 Punches
	for i = 1, 3 do
		task.delay((i-1)*0.2, function()
			if not Character or not Character:FindFirstChild("Torso") then return end
			SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20, Pitch = 1.5})
			local Hit = Instance.new("Part")
			Hit.Material = Enum.Material.Neon
			Hit.Color = Color3.fromRGB(255, 100, 50)
			Hit.Shape = Enum.PartType.Ball
			Hit.Size = Vector3.one * 3
			Hit.Anchored = true
			Hit.CanCollide = false
			Hit.Position = TargetPos + Vector3.new(math.random(-2,2), math.random(-2,2), math.random(-2,2))
			Hit.Parent = Temporary
			Debris:AddItem(Hit, 0.3)
			Tween:Play(Hit, {0.2}, {Size = Vector3.zero, Transparency = 1})
		end)
	end
	
	-- Meteor Drop
	task.delay(1, function()
		SFX:Play3D(9125644676, TargetPos, {MaxDistance = 200, MinDistance = 40, Pitch = 0.3})
		local Meteor = Instance.new("Part")
		Meteor.Material = Enum.Material.CrushedRock
		Meteor.Color = Color3.fromRGB(50, 20, 10)
		Meteor.Shape = Enum.PartType.Ball
		Meteor.Size = Vector3.one * 15
		Meteor.Anchored = true
		Meteor.CanCollide = false
		Meteor.Position = TargetPos + Vector3.new(0, 100, 0)
		Meteor.Parent = Temporary
		Debris:AddItem(Meteor, 1.5)
		
		Tween:Play(Meteor, {0.5, "Quad", "In"}, {
			Position = TargetPos
		})
		
		task.delay(0.5, function()
			SFX:Play3D(9116385079, TargetPos, {MaxDistance = 200, MinDistance = 40, Volume = 2})
			local Bloom = Instance.new("Part")
			Bloom.Material = Enum.Material.Neon
			Bloom.Color = Color3.fromRGB(255, 100, 0)
			Bloom.Shape = Enum.PartType.Ball
			Bloom.Size = Vector3.one * 15
			Bloom.Anchored = true
			Bloom.CanCollide = false
			Bloom.Position = TargetPos
			Bloom.Parent = Temporary
			Debris:AddItem(Bloom, 1)
			
			Tween:Play(Bloom, {0.5, "Quad", "Out"}, {
				Size = Vector3.one * 60, Transparency = 1
			})
			Meteor:Destroy()
		end)
	end)
end
return Keybind
