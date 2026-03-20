--[[
	Skill_Cyclone.lua (Lốc Xoáy Cuồng Phong)
	Tạo lốc xoáy bao bọc quanh Boss để chống cận chiến, kéo dài 5 giây.
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
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Part = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(200, 255, 200), Position = Boss.Position,
					Size = Vector3.new(0.5, 30, 30), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.ForceField
				})
				Debris:AddItem(Part, 10)
				local Weld = Instance.new("WeldConstraint")
				Weld.Part0, Weld.Part1, Weld.Parent = Part, Boss, Part

				task.spawn(function()
					AttackUtils:Telegraph(Part, 1)
					-- Vòng lốc cao lên càn quét
					Tween(Part, {0.3}, {Size = Vector3.new(40, 30, 30), Transparency = 0.6})
					AttackUtils:RegisterHitDetection(Part, 0.05, 5) -- Dmg duy trì 5s
					task.wait(5)
					Tween(Part, {0.5}, {Transparency = 1, Size = Vector3.new(0.5, 35, 35)})
					task.wait(0.5); Part:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 12},
		}
	}
}
