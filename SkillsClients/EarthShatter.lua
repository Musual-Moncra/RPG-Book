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

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"),
	workspace:WaitForChild("Mobs"), workspace.Zones, workspace.Teleports, workspace.Map.Doors
}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.RespectCanCollide = true

local Duration = 1.0

--------------------------------------------------------------------------------

local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position, Raycast
end

function Keybind:OnActivated(Player) end

function Keybind:OnLetGo(Player)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local OriginPosition = Character.HumanoidRootPart.Position
	local LookVector = Character.HumanoidRootPart.CFrame.LookVector

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - OriginPosition).Magnitude > GameConfig.DefaultDistanceRadius * 1.5) then
		return
	end

	SFX:Play3D(9125644676, OriginPosition, {MaxDistance = 150, MinDistance = 30, Pitch = 0.5})
	
	-- Erupting spikes along the LookVector path
	task.spawn(function()
		for i = 1, 8 do
			local distanceOut = i * 7
			local targetCenter = OriginPosition + (LookVector * distanceOut)
			local floorPos = Floor(targetCenter) or targetCenter
			
			SFX:Play3D(9066732918, floorPos, {MaxDistance = 100, MinDistance = 20, Pitch = math.random(6, 10)/10})
			
			-- 3 spikes per segment
			for j = 1, 3 do
				local offset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
				local spikeFloor = Floor(floorPos + offset) or (floorPos + offset)
				
				local Spike = Instance.new("Part")
				Spike.Name = "EarthShatter_Spike"
				Spike.Material = Enum.Material.Slate
				Spike.Color = Color3.fromRGB(80, 70, 60)
				Spike.Anchored = true
				Spike.CastShadow = false
				Spike.CanCollide = false
				
				local height = math.random(15, 30)
				local width = math.random(3, 8)
				
				Spike.Size = Vector3.new(width, height, width)
				Spike.Position = spikeFloor - Vector3.new(0, height, 0)
				Spike.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 360), math.random(-20, 20))

				Tween:Play(Spike, {0.2, "Back", "Out"}, {
					Position = spikeFloor + Vector3.new(0, height/3, 0)
				})
				
				Spike.Parent = Temporary
				Debris:AddItem(Spike, 3)
				
				task.delay(1.5 + math.random()*0.5, function()
					Tween:Play(Spike, {0.6, "Quad", "In"}, {
						Position = spikeFloor - Vector3.new(0, height, 0),
						Transparency = 1
					})
				end)
			end
			
			-- Dust shockwave per segment
			local Dust = Instance.new("Part")
			Dust.Name = "EarthShatter_Dust"
			Dust.Material = Enum.Material.Smoke
			Dust.Color = Color3.fromRGB(150, 130, 100)
			Dust.Anchored = true
			Dust.CastShadow = false
			Dust.CanCollide = false
			Dust.Shape = Enum.PartType.Ball
			Dust.Position = floorPos
			Dust.Size = Vector3.one * 5
			Dust.Transparency = 0.5
			
			Tween:Play(Dust, {0.5, "Quad", "Out"}, {
				Size = Vector3.one * 25,
				Transparency = 1
			})
			Dust.Parent = Temporary
			Debris:AddItem(Dust, 1)
			
			task.wait(0.05) -- Erupt sequentially like a wave
		end
	end)
end

return Keybind
