--[[
	ej0w @ September 2024
	AttackUtils
	
	Handles attack utilities
	Fed through AttackConfig modules and passed back to MobLib
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local DamageLib = require(ServerStorage.Modules.Libraries.Damage)
local AIMob = require(ServerStorage.Modules.Libraries.Mob.AIMob)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--> Variables
local AttackUtils = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"), workspace:WaitForChild("Mobs"), workspace:WaitForChild("Props"),
	workspace.Zones, workspace.Teleports, workspace.Map.Doors, workspace.NPCs, workspace.Armors
}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.RespectCanCollide = true

--------------------------------------------------------------------------------

function AttackUtils.Tween(Object: Instance, Info: {any}, Properties: {[string]: any}, Distance: number?)
	if Object == nil or Object.Parent == nil then
		return
	end
	
	for _, Player in Players:GetPlayers() do
		local Character = Player.Character
		if Character and (Character:GetPivot().Position - Object.Position).Magnitude < (Distance or GameConfig.DefaultDistanceRadius) then
			EventModule:FireClient("RequestClientTween", Player, Object, Info, Properties)
		end
	end
	
	task.delay(Info[1], function()
		for Name, Value in Properties do
			Object[Name] = Value
		end
	end)
end

function AttackUtils.Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position, Raycast
end

function AttackUtils.FindNearestTorso(MobInstance, Distance, RequiresTarget)
	local Position = MobInstance:GetPivot().Position
	
	local Torso = nil :: BasePart
	local NewDistance = Distance or 500
	
	if not RequiresTarget or AttributeModule:GetAttribute(MobInstance, "Target") then
		for _, Player in Players:GetPlayers() do
			local Character = Player.Character

			local _Torso = Character and Character:FindFirstChild("Torso")
			local Humanoid = Character and Character:FindFirstChild("Humanoid")
			
			local Magnitude = _Torso and (_Torso.Position - Position).Magnitude or math.huge

			if (Humanoid and Humanoid.Health > 0) and Magnitude < NewDistance then
				NewDistance = Magnitude
				Torso = _Torso
			end
		end
	end

	return Torso
end

function AttackUtils:Damage(Player: Player, Damage: number)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if Humanoid then
		local RequestedDamage = Damage
		if Damage <= 1 then
			RequestedDamage = Humanoid.MaxHealth * Damage
		end
		
		local CanHighlight = DamageLib.Hurt(Player, RequestedDamage)
		if CanHighlight then
			EventModule:FireClient("MobDamagedPlayer", Player, nil, Damage, nil, true, true)
		end
	end
end

function AttackUtils:Telegraph(Part: BasePart, Duration: number)
	Part.Material = Enum.Material.ForceField
	Part.Transparency = 0.7

	local Clone = Part:Clone()
	Clone.Parent = workspace:WaitForChild("Temporary")
	Clone.Material = Enum.Material.Neon
	Clone.Transparency = 0.9
	
	local LongestAxis = math.max(Part.Size.X, Part.Size.Y, Part.Size.Z)
	local AverageAxis = (Part.Size.X + Part.Size.Y + Part.Size.Z) / 3
	local ValidAxis = math.abs(AverageAxis - LongestAxis) > (AverageAxis / 2)
	Clone.Size = Vector3.new(
		((not ValidAxis or Part.Size.X ~= LongestAxis) and 0) or Part.Size.X - 0.1,
		((not ValidAxis or Part.Size.Y ~= LongestAxis) and 0) or Part.Size.Y - 0.1,
		((not ValidAxis or Part.Size.Z ~= LongestAxis) and 0) or Part.Size.Z - 0.1
	)
	
	AttackUtils.Tween(Clone, {Duration, "Linear", "InOut"}, {Size = Vector3.new(Part.Size.X, Part.Size.Y, Part.Size.Z)})

	task.wait(Duration)
	Part.Transparency = 0.7
	Part.Material = Enum.Material.Neon
	Clone:Destroy()
end

function AttackUtils:RegisterHitDetection(Part: BasePart, Damage: number, Duration: number?)
	local Debounce = {}
	
	local Connection; Connection = Part.Touched:Connect(function(Hit)
		local Player = Players:GetPlayerFromCharacter(Hit.Parent)
		if Player and not Debounce[Player] then
			Debounce[Player] = true
			task.delay(0.5, function()
				Debounce[Player] = nil
			end)
			
			AttackUtils:Damage(Player, Damage)
		end
	end)
	
	if Duration then
		task.delay(Duration, function()
			Connection:Disconnect()
		end)
	end
	return Connection
end

function AttackUtils:CreateBasePart(Properties: {[string]: any}, BasePart: Instance)
	local Part = if BasePart == nil
		then Instance.new("Part") 
		else BasePart:Clone()
	
	Part.Parent = workspace:WaitForChild("Temporary")
	Part.Material = "Neon"
	Part.Transparency = 0.7
	Part.Anchored = true
	Part.CastShadow = false
	Part.CanCollide = false
	
	for Name, Value in Properties do
		Part[Name] = Value
	end
	return Part
end

return AttackUtils