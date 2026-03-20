--[[
	ej0w @ October 2024
	AttackFunctions

	Example of a sequential attack of 2
	*Add more to an array VV { {Attack 1}, {Attack 2} } and they'll run in order.
	
	{
		{
			Callback = function()
				-- Run an attack here
			end,
		
			RequiresTarget = nil,
			Activation = {},
		},
		{
			Callback = function()
				-- Run an attack here
			end,
			
			RequiresTarget = nil,
			Activation = {},
		}
	},
	
	Another example, this is an attack in a sequence of 1.
	*Meaning, this attack runs every xx seconds alone
	
	{
		{
			Callback = function()
				-- Run an attack here
			end,
		
			RequiresTarget = nil,
			Activation = {},
		}
	},
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

--> Serverside 
local AttackUtils, MobList, FindNearestTorso, Tween, Floor

if RunService:IsServer() then
	local ServerStorage = game:GetService("ServerStorage")
	
	AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
	MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)
	
	FindNearestTorso = AttackUtils.FindNearestTorso
	
	Tween = AttackUtils.Tween
	Floor = AttackUtils.Floor
end

--> Configuration
local Configuration = {
	TelegraphColor = Color3.fromRGB(255, 69, 69)
}

--------------------------------------------------------------------------------

return {
	{
		{
			--[[
		
				[Callback]
			
				This function is called when the attack is deemed playable, note that NearestTorso will not return (and the attack wont play) when no players are near
				Don't worry about serversided & laggy attacks, the visuals are handled on the client
			
				Follow the schematic here and you'll be pretty good - check AttackUtils for more functions that you're able to use
				Also allowed to use your own, I don't mind c:
			
				You're probably also able to change the state of the mob through this code too btw (e.g. making it anchored)
				* Can also weld telegraphed attacks
		
			]]
			Callback = function(NearestTorso, Mob)
				local TorsoPosition = Floor(NearestTorso.Position)
				local Offset = Vector3.new(225, 0, 0)

				local Part = AttackUtils:CreateBasePart({
					Color = Configuration.TelegraphColor,
					Position = TorsoPosition,
					Size = Vector3.new(0.25, 50, 15),
					Orientation = Vector3.new(0, 90, 90),
					Shape = "Cylinder",
				})

				Debris:AddItem(Part, 10)

				AttackUtils:Telegraph(Part, 1)
				AttackUtils:RegisterHitDetection(Part, 0.25, 0.4)

				Tween(Part, {0.4}, {Transparency = 0.2, Size = Part.Size + Offset})
				task.wait(0.4)

				Tween(Part, {0.5}, {Transparency = 1, Size = Part.Size - Offset})
				task.wait(0.5)

				Part:Destroy()
			end,

			-- General
			RequiresTarget = true, 	-- If set to true, the mob will revert attacks if the target (the mob it's attacking) doesn't exist.
			StopWhileAttacking = 0.5, -- Stops whilst doing an attack for xx seconds

			TelegraphAnimation = nil, -- Set to nil for none. Else, the mob will play an animation 'rbxassetid://xxxx': number before doing the attack (delay should be handled by callback)
			-- [TelegraphAnimation]: {AnimationID, FreezeTime?, TimeFrozen?} (like attack sequences)

			--[[
			
				[Activation]
			
				Type can either be 'MaxHealth' 'Health' or 'Time', if Healh, {Value = x.x (e.g. 0.5 for 50%)}, else, {Value = xx Seconds}
			
				The difference between MaxHealth and Health is that MaxHealth starts the attack when the mob is exactly at that hp, versus damage difference for Health
				e.g. the mob needs to be at 10% hp, versus mob needs to take 10% dmg, 
		
			]]
			Activation = {Type = "Time", Value = 4},
		},
	},
}