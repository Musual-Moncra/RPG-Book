--[[
	Skill_MeteorDrop.lua (Vẫn Thạch Hủy Diệt)
	Triệu hồi khối đá khổng lồ rớt từ trên cao đập thẳng xuống sàn.
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
				-- Bóng trên mặt đất
				local Shadow = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(0, 0, 0), Position = TPos, Size = Vector3.new(0.5, 35, 35), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
				})
				-- Thiên thạch thật trên trời
				local Meteor = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(255, 100, 50), Position = TPos + Vector3.new(0, 150, 0), Size = Vector3.new(30, 30, 30), Shape = "Block", Material = Enum.Material.Slate
				})
				Debris:AddItem(Shadow, 6); Debris:AddItem(Meteor, 6)

				task.spawn(function()
					AttackUtils:Telegraph(Shadow, 2)
					-- Rớt nhanh
					Tween(Meteor, {0.3, "Sine", "In"}, {Position = TPos + Vector3.new(0, 15, 0)})
					task.wait(0.3)
					-- Kích nổ ở sàn
					AttackUtils:RegisterHitDetection(Shadow, 0.35, 0.2)
					Meteor.Material = Enum.Material.Neon
					Tween(Meteor, {0.2}, {Size = Vector3.new(45, 45, 45), Transparency = 1})
					Tween(Shadow, {0.2}, {Transparency = 1, Size = Vector3.new(0.5, 50, 50)})
					task.wait(0.5); Meteor:Destroy(); Shadow:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 15},
		}
	}
}
