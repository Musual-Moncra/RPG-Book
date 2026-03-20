--[[
	Skill_BlackHole.lua (Hố Đen Vũ Trụ)
	Ngưng tụ một quả cầu đen khổng lồ hút cạn sinh lực kẻ đứng bên trong trước khi nổ.
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
				local TPos = Floor(Target.Position) + Vector3.new(0, 10, 0)
				local Part = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(20, 0, 50), Position = TPos, Size = Vector3.new(5, 5, 5), Shape = "Ball"
				})
				Debris:AddItem(Part, 10)
				task.spawn(function()
					AttackUtils:Telegraph(Part, 4) -- Tụ rât lâu
					AttackUtils:RegisterHitDetection(Part, 0.05, 4) -- Sát thương rỉa nếu chót lọt vào
					Tween(Part, {4, "Quad", "In"}, {Size = Vector3.new(35, 35, 35), Transparency = 0.5})
					task.wait(4)
					-- Nổ siêu to
					Part.Color = Color3.fromRGB(0, 0, 0)
					AttackUtils:RegisterHitDetection(Part, 0.4, 0.2) 
					Tween(Part, {0.2}, {Size = Vector3.new(50, 50, 50), Transparency = 0})
					task.wait(0.2)
					Tween(Part, {0.6}, {Size = Vector3.new(1, 1, 1), Transparency = 1})
					task.wait(0.6); Part:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 16},
		}
	}
}
