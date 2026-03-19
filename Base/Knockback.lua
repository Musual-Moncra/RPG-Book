--[[
	ej0w @ October 2024
	Knockback
	
	Pushes an entity back depending on the power given,
	Inputs w/ two values, creates a vector from those two points and --> that direction
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--> Variables
local Knockback = {}

--------------------------------------------------------------------------------

function Knockback:Activate(Torso, Distance, Position0, Position1)
	if not Torso then
		return
	end
	
	local MobInstance = Torso.Parent
	if MobInstance:IsA("Model") and AttributeModule:GetAttribute(MobInstance, "NoKnockback") then
		return
	end
	
	local Speed = (10 * Distance) / (Torso.Size.Y / 2)
	
	if math.abs(Speed) > 25 then 
		local KnockbackVelocity = Instance.new("BodyVelocity")
		KnockbackVelocity.Parent = Torso

		KnockbackVelocity.MaxForce = Vector3.one * 80000
		KnockbackVelocity.P = 20

		local Unit = (Position0 - Position1).Unit

		local Velocity = Unit * Speed * -1
		Velocity = Vector3.new(Velocity.X, math.max(Velocity.Y, 0), Velocity.Z)

		KnockbackVelocity.Velocity = Velocity

		task.delay(0.2, function()
			KnockbackVelocity:Destroy()

			task.wait(0.8)
			Torso.AssemblyLinearVelocity = Vector3.zero
		end)
	end
end

return Knockback
