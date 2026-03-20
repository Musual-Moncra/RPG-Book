--[[
	Combo_PhantomStrike.lua (Trảm Kích Ảo Ảnh)
	Boss lướt ngang lướt dọc để lại vết cắt chết người.
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
				local Boss = Mob.Instance:FindFirstChild("HumanoidRootPart") or Mob.Instance:FindFirstChild("Torso")
				if not Boss or not Target then return end
				local Trails = {}
				for i=1, 3 do
					local Start = Floor(Boss.Position)
					local TPos = Target.Position + Target.CFrame.LookVector*(20) + Vector3.new(math.random(-15,15),0,math.random(-15,15))
					Boss.CFrame = CFrame.lookAt(TPos, Target.Position) -- Dịch chuyển lướt
					
					local Dist = (TPos - Start).Magnitude
					local Path = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(30,30,30), Position = Start, Size = Vector3.new(4,4,Dist), CFrame = CFrame.lookAt(Start, TPos)*CFrame.new(0,0,-Dist/2), Shape="Block" })
					Debris:AddItem(Path, 5)
					table.insert(Trails, Path)
					AttackUtils:Telegraph(Path, 1)
					task.wait(0.3)
				end
				
				task.wait(0.5) -- Phát nổ toàn bộ ảo ảnh
				for _, Path in pairs(Trails) do
					AttackUtils:RegisterHitDetection(Path, 0.25, 0.2)
					Path.Color = Color3.fromRGB(150,0,255)
					Tween(Path, {0.2}, {Transparency=0, Size = Path.Size + Vector3.new(2,2,0)})
					task.spawn(function() task.wait(0.2); Tween(Path, {0.3}, {Transparency=1}); task.wait(0.3); Path:Destroy() end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 15},
		}
	}
}
