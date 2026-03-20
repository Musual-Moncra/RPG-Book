--[[
	Combo_BladeDance.lua (Vũ Điệu Của Kiếm)
	Liên hoàn chém xé gió nổ bung xung quanh Boss
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
				local BPos = Floor(Boss.Position)
				for i=1, 6 do
					local ang = math.rad(math.random(0,360))
					local Slash = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(200, 255, 255), Position = BPos, Size = Vector3.new(2, 6, 35), CFrame = CFrame.new(BPos)*CFrame.Angles(0, ang, 0)*CFrame.new(0,0,math.random(0,10)), Shape="Block" })
					Debris:AddItem(Slash, 3)
					task.spawn(function()
						AttackUtils:Telegraph(Slash, 0.4)
						AttackUtils:RegisterHitDetection(Slash, 0.1, 0.2)
						Tween(Slash, {0.1}, {Transparency=0}); task.wait(0.1); Tween(Slash, {0.2}, {Transparency=1}); task.wait(0.2); Slash:Destroy()
					end)
					task.wait(0.2)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 8},
		}
	}
}
