--[[
	Combo_DomainExpansion.lua (Bành Trướng Lãnh Địa)
	Tạo ra một khối không gian cực khổng lồ bao trùm khu vực. Mọi kẻ thù đứng trong
	Lãnh địa đều sẽ liên tục bị rút máu cho đến khi Lãnh địa tan vỡ. 
	Bên trong lãnh địa có mưa đạn tất sát.
]]
local RS = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local AttackUtils, Floor, Tween
if RS:IsServer() then
	local Server = game:GetService("ServerStorage")
	AttackUtils = require(Server.Modules.Server.AttackUtils)
	Floor = AttackUtils.Floor
	Tween = AttackUtils.Tween
end

local C_Domain = Color3.fromRGB(20, 0, 50) -- Màu bóng tối Lãnh Địa đè lên thị giác
local C_SureHit = Color3.fromRGB(150, 0, 255) 

return {
	{
		-- THỨC TỐI THƯỢNG: BÀNH TRƯỚNG LÃNH ĐỊA ĐÊM ĐEN
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Center = Floor(Boss.Position)
				
				-- 1. MỞ LÃNH ĐỊA: Quả cầu khổng lồ màu tối bao trùm thị giác người chơi
				local Domain = AttackUtils:CreateBasePart({
					Color = C_Domain, Position = Center, Size = Vector3.new(1, 1, 1), Shape = "Ball", Material = Enum.Material.ForceField
				})
				Debris:AddItem(Domain, 12)
				
				task.spawn(function()
					-- Lan toả kích thước siêu nhanh bao trùm 150 studs
					Tween(Domain, {0.8, "Exponential", "Out"}, {Size = Vector3.new(200, 200, 200), Transparency = 0.3})
					
					-- Dmg DoT liên tục không thể né tránh (Sure-Hit Effect) trong suốt 8 giây
					-- Cứ 0.5s rút 3% máu người chơi nằm trong lãnh địa
					AttackUtils:RegisterHitDetection(Domain, 0.03, 8)
					
					task.wait(8)
					-- Đóng Lãnh Địa (Vỡ nát)
					Tween(Domain, {0.5}, {Transparency = 1, Size = Vector3.new(300, 300, 300)})
					task.wait(0.5); Domain:Destroy()
				end)

				-- 2. TẤT SÁT TRONG LÃNH ĐỊA (Sure-hit Lasers)
				-- Phóng đạn nhắm thẳng vào bên trong Lãnh địa trong thời gian kích hoạt
				for i = 1, 6 do
					task.wait(1)
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					
					local Laser = AttackUtils:CreateBasePart({
						Color = C_SureHit, Position = TPos, Size = Vector3.new(6, 6, 80), CFrame = CFrame.lookAt(Center, Vector3.new(TPos.X, Center.Y, TPos.Z)), Shape = "Block"
					})
					Debris:AddItem(Laser, 3)
					
					task.spawn(function()
						AttackUtils:Telegraph(Laser, 0.3) -- Tốc độ cực nhanh không thể né
						AttackUtils:RegisterHitDetection(Laser, 0.1, 0.2)
						Tween(Laser, {0.2}, {Transparency = 0, Size = Laser.Size + Vector3.new(2,2,0)})
						task.wait(0.2); Tween(Laser, {0.3}, {Transparency = 1}); task.wait(0.3); Laser:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 9, Activation = {Type = "Time", Value = 25},
		}
	}
}
