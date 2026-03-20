--[[
	Combo_TimeBomb.lua (Đồng Hồ Trái Bom)
	Gắn bom vào người chơi. Bom rớt xuống đất sau 3s và nổ banh xác.
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
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not TargetRoot then return end
				-- Quả pháo gắn trên đầu
				local Bomb = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(200,50,0), Position = TargetRoot.Position + Vector3.new(0,5,0), Size=Vector3.new(3,3,3), Shape="Ball" })
				local W = Instance.new("WeldConstraint"); W.Part0=Bomb; W.Part1=TargetRoot; W.Parent=Bomb
				Debris:AddItem(Bomb, 8)
				
				task.spawn(function()
					-- Tích tắc 3 giây
					for i=1, 3 do
						Tween(Bomb, {0.1}, {Size=Vector3.new(5,5,5)}); task.wait(0.1); Tween(Bomb, {0.9}, {Size=Vector3.new(3,3,3)}); task.wait(0.9)
					end
					-- Rớt xuống đất
					W:Destroy()
					local BPos = Floor(Bomb.Position)
					Bomb:Destroy()
					
					-- Sóng nổ tĩnh dưới sàn
					local Blast = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,0,0), Position = BPos, Size = Vector3.new(0.5, 45, 45), Orientation = Vector3.new(0,90,90), Shape="Cylinder" })
					Debris:AddItem(Blast, 4)
					AttackUtils:Telegraph(Blast, 0.4) -- Cho 0.4s để Lướt chạy xa khỏi cái bãi vừa rớt bom
					AttackUtils:RegisterHitDetection(Blast, 0.5, 0.3)
					Tween(Blast, {0.2}, {Transparency=0, Size = Vector3.new(10,45,45)})
					task.wait(0.2); Tween(Blast, {0.3}, {Transparency=1}); task.wait(0.3); Blast:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 18},
		}
	}
}
