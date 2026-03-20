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
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end

	SFX:Play3D(9125644676, OriginPosition, {MaxDistance = 150, MinDistance = 30, Pitch = 0.4})

	-- Find up to 5 targets visually
	local targets = {}
	for _, mob in CollectionService:GetTagged("Mob") do
		local torso = mob:FindFirstChild("Torso")
		if torso and (torso.Position - OriginPosition).Magnitude < 30 then
			table.insert(targets, torso)
			if #targets >= 5 then break end
		end
	end

	-- Create Tethers
	local beams = {}
	for _, target in targets do
		local BeamPart = Instance.new("Part")
		BeamPart.Name = "SoulTether_Beam"
		BeamPart.Material = Enum.Material.Neon
		BeamPart.Color = Color3.fromRGB(150, 0, 200)
		BeamPart.Anchored = true
		BeamPart.CastShadow = false
		BeamPart.CanCollide = false
		BeamPart.Parent = Temporary
		
		table.insert(beams, {Part = BeamPart, Target = target})
	end
	
	-- Update loop for 4 seconds
	local connection
	local startTime = os.clock()
	
	connection = RunService.Heartbeat:Connect(function()
		if not Character or not Character:FindFirstChild("Torso") then
			connection:Disconnect()
			for _, b in beams do b.Part:Destroy() end
			return
		end
		
		if os.clock() - startTime > 4 then
			connection:Disconnect()
			for _, b in beams do
				Tween:Play(b.Part, {0.3, "Quad", "Out"}, {
					Transparency = 1,
					Size = Vector3.new(0, 0, 0)
				})
				Debris:AddItem(b.Part, 0.4)
			end
			return
		end
		
		local playerPos = Character.Torso.Position
		for _, b in beams do
			local targetPos = b.Target.Position
			local dist = (targetPos - playerPos).Magnitude
			local midPoint = playerPos + (targetPos - playerPos)/2
			
			b.Part.Size = Vector3.new(0.5, 0.5, dist)
			b.Part.CFrame = CFrame.lookAt(midPoint, targetPos)
			
			-- Random flicker
			b.Part.Transparency = math.random(2, 5)/10
		end
	end)
end

return Keybind
