--[[
	Skill_RandomStrikes.lua (Mưa Bão Ánh Sáng)
	Rải 15 vùng nổ nhỏ ngẫu nhiên xung quanh người chơi cực nhanh. Ép phải luồn lách.
]]
local RS = game:GetService("RunService")
local Debris = game:GetService("Debris")
local AttackUtils, Floor, Tween
if RS:IsServer() then
	local Server = game:GetService("ServerStorage")
	AttackUtils = require(Server.Modules.Server.AttackUtils)
	Floor = AttackUtils.Floor
	Tween = AttackUtils.Tween
end
return {
	{
		{
			Callback = function(Target, Mob)
				local Center = Floor(Target.Position)
				for i = 1, 15 do
					local RandomPos = Center + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
					local Part = AttackUtils:CreateBasePart({
						Color = Color3.fromRGB(255, 255, 0), Position = RandomPos, Size = Vector3.new(0.5, 12, 12), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
					})
					Debris:AddItem(Part, 3)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.6)
						AttackUtils:RegisterHitDetection(Part, 0.1, 0.2)
						Part.Color = Color3.fromRGB(255, 255, 255)
						Tween(Part, {0.2}, {Transparency = 0, Size = Part.Size + Vector3.new(10, 5, 5)})
						task.wait(0.2); Tween(Part, {0.3}, {Transparency = 1}); task.wait(0.3); Part:Destroy()
					end)
					task.wait(0.15) -- Nổ rào rào liên tục
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 18},
		}
	}
}
