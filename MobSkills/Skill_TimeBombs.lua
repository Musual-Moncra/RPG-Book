--[[
	Skill_TimeBombs.lua (Hạt Nhân Kép)
	3 Vòng nổ đồng tâm: Vòng nhỏ nổ trước, lan ra vòng trung, rồi vòng lớn. (Dodge mechanics)
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
				local TPos = Floor(Target.Position)
				local sizes = {15, 35, 55}
				local delays = {1.5, 2.0, 2.5}
				
				for i, rad in pairs(sizes) do
					local Part = AttackUtils:CreateBasePart({
						Color = Color3.fromRGB(255, 100, 100), Position = TPos, Size = Vector3.new(0.5, rad, rad), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
					})
					Debris:AddItem(Part, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Part, delays[i])
						AttackUtils:RegisterHitDetection(Part, 0.2, 0.2)
						Part.Color = Color3.fromRGB(255, 0, 0)
						Tween(Part, {0.3}, {Transparency = 1, Size = Vector3.new(10, rad, rad)})
						task.wait(0.3); Part:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 15},
		}
	}
}
