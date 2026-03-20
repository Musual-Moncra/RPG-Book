-- [CLIENT] --> Shared to all clients
--> References
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> References
local Temporary = workspace:WaitForChild("Temporary")

--> Variables
local Keybind = {}

--------------------------------------------------------------------------------

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("Torso") then return end

	local OriginPosition = Character.Torso.Position
	local LocalPlayer = Players.LocalPlayer
	-- If it's too far, don't render
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end

	-- Mirror server logic to find visual target
	local closestMobTorso
	local minMag = 50
	
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local Torso = MobInstance:FindFirstChild("Torso")
		if Torso then
			local mag = (Torso.Position - OriginPosition).Magnitude
			if mag < minMag then
				minMag = mag
				closestMobTorso = Torso
			end
		end
	end
	
	if not closestMobTorso then return end

	-- Player aura effect
	local charge = Instance.new("Part")
	charge.Material = Enum.Material.ForceField
	charge.Color = Color3.fromRGB(0, 50, 255)
	charge.Anchored = true
	charge.CanCollide = false
	charge.Size = Vector3.new(0, 0, 0)
	charge.Shape = Enum.PartType.Ball
	charge.Position = Character.Torso.Position
	charge.Parent = Temporary
	Debris:AddItem(charge, 2.5)
	
	Tween:Play(charge, {0.3, "Quad", "Out"}, {Size = Vector3.one * 15, Transparency = 0.5})
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = Character.Torso
	weld.Part1 = charge
	weld.Parent = charge
	charge.Anchored = false

	task.delay(2.0, function()
		Tween:Play(charge, {0.4, "Quad", "In"}, {Size = Vector3.one * 0, Transparency = 1})
	end)

	-- Rapid fire visuals
	task.spawn(function()
		for i = 1, 10 do
			if not closestMobTorso or not closestMobTorso.Parent then break end
			
			local startPos = Character.Torso.Position + Vector3.new(math.random(-3, 3), math.random(0, 5), math.random(-3, 3))
			local targetPos = closestMobTorso.Position
			
			SFX:Play3D(9125644676, startPos, {MaxDistance = 150, MinDistance = 30, Pitch = 2.0})
			SFX:Play3D(9066732918, targetPos, {MaxDistance = 150, MinDistance = 30, Pitch = 3.0})
			
			local missile = Instance.new("Part")
			missile.Name = "ArcaneMissile"
			missile.Material = Enum.Material.Neon
			missile.Color = Color3.fromRGB(0, 200, 255)
			missile.Anchored = true
			missile.CastShadow = false
			missile.CanCollide = false
			missile.Size = Vector3.new(1, 1, 6)
			missile.CFrame = CFrame.lookAt(startPos, targetPos)
			missile.Parent = Temporary
			Debris:AddItem(missile, 0.5)
			
			-- Fly trajectory
			Tween:Play(missile, {0.15, "Linear"}, {
				Position = targetPos
			})
			
			task.delay(0.15, function()
				missile.Size = Vector3.new(5, 5, 5)
				missile.Shape = Enum.PartType.Ball
				Tween:Play(missile, {0.2, "Quad", "Out"}, {
					Size = Vector3.one * 15,
					Transparency = 1
				})
			end)
			
			task.wait(0.2)
		end
	end)
end

return Keybind
