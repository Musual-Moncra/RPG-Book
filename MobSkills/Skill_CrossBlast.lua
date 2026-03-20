--[[
	Skill_CrossBlast.lua (X-Blast / Rạch Cắt Tứ Phương)
	Nhả 2 đòn laze chéo khóa chuyển động, sau 1 giây sẽ nổ lại lần 2 tại đúng vết nứt cũ!
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
				local P1 = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(200, 50, 255), Position = TPos, Size = Vector3.new(4, 3, 70), CFrame = CFrame.new(TPos) * CFrame.Angles(0, math.rad(45), 0), Shape = "Block" })
				local P2 = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(200, 50, 255), Position = TPos, Size = Vector3.new(4, 3, 70), CFrame = CFrame.new(TPos) * CFrame.Angles(0, math.rad(-45), 0), Shape = "Block" })
				Debris:AddItem(P1, 6); Debris:AddItem(P2, 6)
				
				task.spawn(function()
					AttackUtils:Telegraph(P1, 0.8); AttackUtils:Telegraph(P2, 0)
					AttackUtils:RegisterHitDetection(P1, 0.15, 0.3)
					AttackUtils:RegisterHitDetection(P2, 0.15, 0.3)
					P1.Color = Color3.fromRGB(255, 100, 255); P2.Color = Color3.fromRGB(255, 100, 255)
					Tween(P1, {0.3}, {Transparency = 0}); Tween(P2, {0.3}, {Transparency = 0})
					task.wait(1)
					-- Nổ dư chấn lần 2!
					AttackUtils:RegisterHitDetection(P1, 0.15, 0.3)
					AttackUtils:RegisterHitDetection(P2, 0.15, 0.3)
					Tween(P1, {0.4}, {Size = Vector3.new(8, 8, 70), Transparency = 1})
					Tween(P2, {0.4}, {Size = Vector3.new(8, 8, 70), Transparency = 1})
					task.wait(0.4); P1:Destroy(); P2:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.0, Activation = {Type = "Time", Value = 12},
		}
	}
}
