--[[
	Skill_DeathLaser.lua (Beam Của Sự Chết Chóc)
	Cảnh báo 2 giây rồi quạt 1 đường Beam siêu to không thể chạy kịp nếu ở giữa.
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
				if not Boss or not Target then return end
				local BPos = Floor(Boss.Position)
				local TPos = Floor(Target.Position)
				local Dist = 120
				local CF = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z))
				local CPos = (CF * CFrame.new(0,0,-Dist/2)).Position
				
				local Part = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(255, 50, 50), Position = CPos, Size = Vector3.new(18, 18, Dist), CFrame = CFrame.lookAt(CPos, Vector3.new(TPos.X, CPos.Y, TPos.Z)), Shape = "Block"
				})
				Debris:AddItem(Part, 6)
				task.spawn(function()
					AttackUtils:Telegraph(Part, 2)
					AttackUtils:RegisterHitDetection(Part, 0.5, 0.3) -- Nửa cây máu!
					Part.Color = Color3.fromRGB(255, 255, 255)
					Tween(Part, {0.3}, {Transparency = 0, Size = Part.Size + Vector3.new(5,5,0)})
					task.wait(0.3)
					Tween(Part, {0.5}, {Transparency = 1, Size = Vector3.new(0,0,Dist)})
					task.wait(0.5); Part:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 14},
		}
	}
}
