--[[
	Combo_BloodMoon.lua
	Chuỗi Huyết Nguyệt Quỷ Dữ (Chuyên Hút máu và bào mòn Sinh Lực - 4 Thức)
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
local C_Blood = Color3.fromRGB(150, 0, 0)
local C_Moon = Color3.fromRGB(255, 50, 50)

return {
	{
		-- THỨC 1: AO MÁU (Siphon)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				local Pool = AttackUtils:CreateBasePart({ Color = C_Blood, Position = BPos, Size = Vector3.new(0.5, 35, 35), Orientation = Vector3.new(0,90,90), Shape = "Cylinder", Material = Enum.Material.Mud })
				Debris:AddItem(Pool, 6)
				task.spawn(function()
					AttackUtils:Telegraph(Pool, 0.8)
					AttackUtils:RegisterHitDetection(Pool, 0.05, 4) -- Hút 4s liên tục
					if Mob.Enemy then
						Mob.Enemy.Health = math.clamp(Mob.Enemy.Health + Mob.Enemy.MaxHealth * 0.1, 0, Mob.Enemy.MaxHealth)
					end
					Tween(Pool, {0.2}, {Transparency = 0.4}); task.wait(4); Tween(Pool, {0.5}, {Transparency = 1}); task.wait(0.5); Pool:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 2: CƠN MƯA HUYẾT TỤ (Nhiều bãi nổ ngẫu nhiên)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Center = Floor(Boss.Position)
				for i = 1, 12 do
					local RPos = Center + Vector3.new(math.random(-30,30), 0, math.random(-30,30))
					local Drop = AttackUtils:CreateBasePart({ Color = C_Moon, Position = RPos, Size = Vector3.new(0.5, 10, 10), Orientation = Vector3.new(0,90,90), Shape = "Cylinder" })
					Debris:AddItem(Drop, 3)
					task.spawn(function()
						AttackUtils:Telegraph(Drop, 0.5)
						AttackUtils:RegisterHitDetection(Drop, 0.08, 0.2)
						Tween(Drop, {0.2}, {Transparency = 0}); task.wait(0.2); Tween(Drop, {0.2}, {Transparency = 1}); task.wait(0.2); Drop:Destroy()
					end)
					task.wait(0.15)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 2.5},
		},
		-- THỨC 3: LƯỜI HÁI ĐỎ (Nhát chém khổng lồ ngang người)
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Scythe = AttackUtils:CreateBasePart({ Color = C_Blood, Position = TPos, Size = Vector3.new(5, 5, 60), CFrame = CFrame.lookAt(TPos, TPos + Vector3.new(math.random(-1,1),0,math.random(-1,1))), Shape = "Block" })
				Debris:AddItem(Scythe, 4)
				task.spawn(function()
					AttackUtils:Telegraph(Scythe, 0.8)
					AttackUtils:RegisterHitDetection(Scythe, 0.2, 0.2)
					Scythe.Color = C_Moon
					Tween(Scythe, {0.2}, {Transparency = 0, Size = Scythe.Size + Vector3.new(5,0,0)}); task.wait(0.2); Tween(Scythe, {0.2}, {Transparency = 1}); task.wait(0.2); Scythe:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1},
		},
		-- THỨC 4 TỐI THƯỢNG: NHẬT THỰC ĐỎ (Bành trướng tử khí, cực rộng)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Eclipse = AttackUtils:CreateBasePart({ Color = C_Blood, Position = Floor(Boss.Position), Size = Vector3.new(0.5, 100, 100), Orientation = Vector3.new(0,90,90), Shape = "Cylinder" })
				Debris:AddItem(Eclipse, 8)
				task.spawn(function()
					AttackUtils:Telegraph(Eclipse, 3)
					AttackUtils:RegisterHitDetection(Eclipse, 0.5, 0.4) -- Nổ 50% HP
					if Mob.Enemy then
						Mob.Enemy.Health = math.clamp(Mob.Enemy.Health + Mob.Enemy.MaxHealth * 0.2, 0, Mob.Enemy.MaxHealth) -- Hồi 20% máu
					end
					Eclipse.Color = C_Moon
					Tween(Eclipse, {0.3}, {Transparency = 0, Size = Vector3.new(20, 100, 100)})
					task.wait(0.3); Tween(Eclipse, {0.5}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)}); task.wait(0.5); Eclipse:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 3.5, Activation = {Type = "Time", Value = 18},
		}
	}
}
