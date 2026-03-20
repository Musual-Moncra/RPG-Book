--[[
	Combo_SkyfallNuke.lua (Quả Bom Khải Huyền)
	Một quả Genki-Dama/Siêu Bom từ từ rớt xuống trong 6 giây.
	Trong lúc quả bom đang rơi, Boss xả vô số các chiêu nhỏ liên tục để ép người chơi không kịp thoát.
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

local C_Nuke = Color3.fromRGB(255, 150, 0)
local C_Warning = Color3.fromRGB(255, 0, 0)
local C_Mini = Color3.fromRGB(255, 255, 100)

return {
	{
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				
				-- 1. SAO BĂNG TỬ THẦN TỪ TRÊN CAO MẤT 5 GIÂY RỚT
				local Nuke = AttackUtils:CreateBasePart({
					Color = C_Nuke, Position = TPos + Vector3.new(0, 150, 0), Size = Vector3.new(50, 50, 50), Shape = "Ball", Material = Enum.Material.Neon
				})
				local Shadow = AttackUtils:CreateBasePart({
					Color = C_Warning, Position = TPos, Size = Vector3.new(0.5, 60, 60), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
				})
				Debris:AddItem(Nuke, 10); Debris:AddItem(Shadow, 10)

				task.spawn(function()
					task.spawn(function() AttackUtils:Telegraph(Shadow, 5) end) -- Vùng bóng hiển thị 5s! Cảnh báo tận thế!
					-- Bom lơ lửng rớt chậm (gia tốc như trọng lực)
					Tween(Nuke, {5, "Quad", "In"}, {Position = TPos + Vector3.new(0, 25, 0)})
					task.wait(5)
					
					-- Va chạm mặt sàn! Gây nổ 75% máu! Khủng khiếp!
					AttackUtils:RegisterHitDetection(Shadow, 0.75, 0.3)
					
					-- TẠO HIỆU ỨNG VỤ NỔ ROBLOX (Chỉ lấy hình ảnh sinh động, tắt lực đẩy)
					local Exp = Instance.new("Explosion")
					Exp.Position = TPos
					Exp.BlastRadius = 50
					Exp.BlastPressure = 0
					Exp.Parent = workspace
					
					-- Chuyển bóng thành dạng sóng xung kích (Shockwave) lan siêu rộng
					Shadow.Color = Color3.fromRGB(255, 100, 50)
					Shadow.Material = Enum.Material.Neon
					Tween(Shadow, {0.4, "Quad", "Out"}, {Transparency = 1, Size = Vector3.new(0.5, 120, 120)})
					
					-- Flash trắng quả Nuke rồi tiêu biến
					Nuke.Color = Color3.fromRGB(255, 255, 255)
					Tween(Nuke, {0.3, "Quad", "Out"}, {Size = Vector3.new(80, 80, 80), Transparency = 1})
					
					task.wait(0.4); Nuke:Destroy(); Shadow:Destroy()
				end)

				-- 2. ĐÒN NHIỄU SÓNG TRONG 5 GIÂY (Mưa Vẫn Thạch Phụ)
				-- Ép game thủ đang hoảng loạn phải mất tập trung
				for i = 1, 10 do
					if not Target or not Target.Parent then break end
					local MiniPos = Floor(Target.Position) + Vector3.new(math.random(-25,25), 0, math.random(-25,25))
					local Mini = AttackUtils:CreateBasePart({
						Color = C_Mini, Position = MiniPos, Size = Vector3.new(0.5, 12, 12), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
					})
					Debris:AddItem(Mini, 3)
					task.spawn(function()
						AttackUtils:Telegraph(Mini, 0.6) -- Chớp nổ rất nhanh làm rối loạn
						AttackUtils:RegisterHitDetection(Mini, 0.05, 0.2)
						Tween(Mini, {0.2}, {Transparency = 1}); task.wait(0.2); Mini:Destroy()
					end)
					task.wait(0.4) 
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 5.5, Activation = {Type = "Time", Value = 18},
		}
	}
}
