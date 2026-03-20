--[[
	Combo_DeathSpiral.lua (Xoắn Ốc Tử Thần)
	Laze quạt 2 cánh quay tròn siêu tốc!
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
				local Pivot = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,100,0), Position = Boss.Position, Size = Vector3.new(1,1,1), Transparency=1})
				local W = Instance.new("WeldConstraint"); W.Part0 = Pivot; W.Part1 = Boss; W.Parent = Pivot
				Debris:AddItem(Pivot, 7)
				
				local B1 = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,50,0), Position = Boss.Position, Size = Vector3.new(5,5,100), CFrame = CFrame.new(Boss.Position)*CFrame.Angles(0,0,0)*CFrame.new(0,0,-50), Shape="Block"})
				local B2 = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,50,0), Position = Boss.Position, Size = Vector3.new(5,5,100), CFrame = CFrame.new(Boss.Position)*CFrame.Angles(0,math.pi,0)*CFrame.new(0,0,-50), Shape="Block"})
				local W1 = Instance.new("WeldConstraint"); W1.Part0=B1; W1.Part1=Pivot; W1.Parent=B1
				local W2 = Instance.new("WeldConstraint"); W2.Part0=B2; W2.Part1=Pivot; W2.Parent=B2
				Debris:AddItem(B1,7); Debris:AddItem(B2,7)
				
				task.spawn(function()
					AttackUtils:Telegraph(B1, 1); AttackUtils:Telegraph(B2, 1)
					AttackUtils:RegisterHitDetection(B1, 0.1, 5); AttackUtils:RegisterHitDetection(B2, 0.1, 5)
					local active = true
					task.delay(5, function() active = false end)
					local deg = 0
					while active and Pivot and Pivot.Parent do
						deg = deg + 6 -- Quay rất tít
						Tween(Pivot, {0.1}, {CFrame = Boss.CFrame * CFrame.Angles(0, math.rad(deg), 0)})
						task.wait(0.1)
					end
					Tween(B1,{0.5},{Transparency=1}); Tween(B2,{0.5},{Transparency=1})
					task.wait(0.5); B1:Destroy(); B2:Destroy(); Pivot:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 2.0, Activation = {Type = "Time", Value = 15},
		}
	}
}
