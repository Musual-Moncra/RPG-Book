--[[
	Combo_MeteorStorm.lua (Mưa Trái Thạch/Bão Sao Băng Nhỏ)
	Rơi 30 viên đá ngẫu nhiên liên tục dồn dập trong 5 giây.
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
				for i=1, 30 do
					local TPos = Target and Floor(Target.Position) or Floor(Boss.Position)
					local Pos = TPos + Vector3.new(math.random(-30,30), 0, math.random(-30,30))
					local Rock = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,100,50), Position = Pos + Vector3.new(0,50,0), Size=Vector3.new(6,6,6), Shape="Block", Material=Enum.Material.Slate })
					local Shadow = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,0,0), Position = Pos, Size=Vector3.new(0.5, 12, 12), Orientation=Vector3.new(0,90,90), Shape="Cylinder" })
					Debris:AddItem(Rock,4); Debris:AddItem(Shadow,4)
					
					task.spawn(function()
						AttackUtils:Telegraph(Shadow, 0.7)
						Tween(Rock, {0.3, "Quad", "In"}, {Position = Pos})
						task.wait(0.3)
						AttackUtils:RegisterHitDetection(Shadow, 0.1, 0.2)
						Tween(Rock, {0.2}, {Transparency=1, Size=Vector3.new(12,12,12)}); Tween(Shadow, {0.2}, {Transparency=1})
						task.wait(0.2); Rock:Destroy(); Shadow:Destroy()
					end)
					task.wait(0.15)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 5, Activation = {Type = "Time", Value = 20},
		}
	}
}
