-- [CLIENT] --> Shared to all clients
--> References
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

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

	SFX:Play3D(9125644676, Character.Torso, {MaxDistance = 150, MinDistance = 30, Pitch = 0.5})

	-- Create visual aura wrapper
	local Tracker = Instance.new("Part")
	Tracker.Name = "BladeTornado_Tracker"
	Tracker.Transparency = 1
	Tracker.Anchored = true
	Tracker.CanCollide = false
	Tracker.Position = Character.Torso.Position
	Tracker.Parent = Temporary
	
	-- Sound parented to tracker so it moves
	local WindSFX = SFX:CreateBaseSound(9066732918, {MaxDistance = 150, MinDistance = 30, Pitch = 1.0, Looped = true})
	WindSFX.Parent = Tracker
	WindSFX:Play()

	local windRing = Instance.new("Part")
	windRing.Name = "WindRing"
	windRing.Material = Enum.Material.ForceField
	windRing.Color = Color3.fromRGB(200, 200, 200)
	windRing.Size = Vector3.new(2, 40, 40)
	windRing.Shape = Enum.PartType.Cylinder
	windRing.CanCollide = false
	windRing.Anchored = false
	windRing.CastShadow = false
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = Tracker
	weld.Part1 = windRing
	weld.Parent = Tracker
	windRing.Parent = Tracker

	-- Spinning blades
	local blades = {}
	for i = 1, 5 do
		local blade = Instance.new("Part")
		blade.Name = "SpinningBlade"
		blade.Material = Enum.Material.Neon
		blade.Color = Color3.fromRGB(255, 255, 255)
		blade.Size = Vector3.new(1, 15, 2)
		blade.CanCollide = false
		blade.Anchored = false
		blade.CastShadow = false
		blade.Parent = Tracker
		table.insert(blades, blade)
	end

	local connection
	local startTime = os.clock()
	local angle = 0
	
	connection = RunService.Heartbeat:Connect(function(dt)
		if not Character or not Character:FindFirstChild("Torso") then
			connection:Disconnect()
			Tracker:Destroy()
			return
		end
		
		if os.clock() - startTime > 5 then
			connection:Disconnect()
			Tween:Play(windRing, {0.5, "Quad", "In"}, {Transparency = 1, Size = Vector3.new(0, 0, 0)})
			for _, b in blades do
				Tween:Play(b, {0.5, "Quad", "In"}, {Transparency = 1})
			end
			Debris:AddItem(Tracker, 0.5)
			return
		end
		
		Tracker.Position = Character.Torso.Position
		angle = angle + (math.pi * 4 * dt) -- 2 rotations per second
		
		windRing.CFrame = Tracker.CFrame * CFrame.Angles(0, angle, math.pi/2)
		
		for i, blade in blades do
			local offsetAngle = angle + (i * ((math.pi * 2) / #blades))
			local radius = 15
			local x = math.cos(offsetAngle) * radius
			local z = math.sin(offsetAngle) * radius
			blade.CFrame = CFrame.lookAt(Tracker.Position + Vector3.new(x, 0, z), Tracker.Position) * CFrame.Angles(0, math.pi/2, 0)
		end
	end)
end

return Keybind
