--[[
	Combo_VampireBite.lua (Huyết Ma Chú)
	Cắn và ôm mục tiêu để hút máu trắng trợn.
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
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not Boss or not TargetRoot then return end
				
				local Trap = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(150,0,0), Position = Floor(Boss.Position), Size=Vector3.new(0.5,25,25), Orientation=Vector3.new(0,90,90), Shape="Cylinder" })
				Debris:AddItem(Trap, 4)
				task.spawn(function()
					AttackUtils:Telegraph(Trap, 0.6)
					-- Nếu ai đứng ở đây sẽ bị giật lên mặt Boss và Hút máu 2 giây
					local dist = (TargetRoot.Position - Boss.Position).Magnitude
					if dist <= 12.5 then
						TargetRoot.Anchored = true
						TargetRoot.CFrame = Boss.CFrame * CFrame.new(0,0,-4)
						for i=1, 4 do -- Rút 4 nhịp (Hồi máu boss)
							AttackUtils:Damage(game:GetService("Players"):GetPlayerFromCharacter(Target.Parent), 0.1)
							if Mob.Enemy then Mob.Enemy.Health = math.clamp(Mob.Enemy.Health + Mob.Enemy.MaxHealth * 0.05, 0, Mob.Enemy.MaxHealth) end
							task.wait(0.5)
						end
						TargetRoot.Anchored = false
					end
					Tween(Trap,{0.2},{Transparency=1}); task.wait(0.2); Trap:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 14},
		}
	}
}
