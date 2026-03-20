--[[
	ApocalypseCombo.lua
	
	Một tuyệt chiêu đẩy cao độ căng thẳng (Tension) tột độ. Boss ĐỨNG YÊN TẠI CHỖ
	và thi triển cùng lúc CẢ CHIÊU CHẬM (diện rộng, 3 giây) VÀ CHIÊU NHANH (dồn dập rượt đuổi).
	Hệ quả: Ngươi chơi phải vừa liên tục né các đòn nhấp nháy liên tục, vừa phải căng mắt 
	chạy ra khỏi vùng chết chóc khổng lồ đang đếm ngược!
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local AttackUtils, FindNearestTorso, Tween, Floor
if RunService:IsServer() then
	local ServerStorage = game:GetService("ServerStorage")
	AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
	FindNearestTorso = AttackUtils.FindNearestTorso
	Tween = AttackUtils.Tween
	Floor = AttackUtils.Floor
end

local ColorDoom = Color3.fromRGB(150, 0, 255)   -- Tím chói (Vùng chết 3 giây chậm)
local ColorFast = Color3.fromRGB(255, 0, 50)    -- Đỏ rực (Tia nhanh dồn dập 0.5s)
local ColorCore = Color3.fromRGB(0, 0, 0)       -- Đen (Nổ)

return {
	{
		-- THỨC 1: HỖN MANG BAO TRÙM (Overlapping Hell)
		-- Cứ mỗi 16 giây, Boss khoá vị trí, tạo ra một vùng chết 60 studs siêu to (3 giây nổ).
		-- NHƯNG trong 3 giây đó, nó bắn liên tục 5 phát tia laser dẹt khoá mục tiêu.
		{
			Callback = function(NearestTorso, Mob)
				local TargetPos = Floor(NearestTorso.Position)
				local BossPos = Floor(Mob.Instance:GetPivot().Position)
				
				-- 1. TẠO VÙNG CHẾT CHẬM (3s Telegraph)
				local DoomPart = AttackUtils:CreateBasePart({
					Color = ColorDoom,
					Position = BossPos, 
					Size = Vector3.new(0.5, 70, 70), -- Rất to
					Orientation = Vector3.new(0, 90, 90),
					Shape = "Cylinder",
				})
				Debris:AddItem(DoomPart, 8)

				-- Chạy đếm ngược 3 giây độc lập
				task.spawn(function()
					AttackUtils:Telegraph(DoomPart, 3) 
					-- Hết 3 giây mới nổ, 50% máu!
					AttackUtils:RegisterHitDetection(DoomPart, 0.5, 0.3) 
					DoomPart.Color = ColorCore
					Tween(DoomPart, {0.3, "Bounce", "Out"}, {Transparency = 0.2, Size = DoomPart.Size + Vector3.new(10, 20, 20)})
					task.wait(0.3)
					Tween(DoomPart, {0.5}, {Transparency = 1, Size = Vector3.new(0.5,0,0)})
					task.wait(0.5)
					DoomPart:Destroy()
				end)

				-- 2. ĐÒN DỒN DẬP TẠO ÁP LỰC (Liên tiếp 5 phát trong thời gian chờ DoomPart)
				-- Phải né đòn này trong khi tháo chạy khỏi cái DoomPart 70 studs kia!
				for i = 1, 5 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local CurrentTargetPos = Floor(NearestTorso.Position)
					
					local FastLine = AttackUtils:CreateBasePart({
						Color = ColorFast,
						Position = CurrentTargetPos,
						Size = Vector3.new(4, 4, 40), 
						CFrame = CFrame.lookAt(CurrentTargetPos, CurrentTargetPos + Vector3.new(math.random(-10,10), 0, math.random(-10,10))), 
						Shape = "Block",
					})
					Debris:AddItem(FastLine, 3)

					task.spawn(function()
						AttackUtils:Telegraph(FastLine, 0.4) -- Nhanh vùn vụt
						AttackUtils:RegisterHitDetection(FastLine, 0.08, 0.2) -- Trúng cắn dăm 8% máu
						Tween(FastLine, {0.2}, {Transparency = 0, Size = FastLine.Size + Vector3.new(2,2,0)})
						task.wait(0.2)
						FastLine:Destroy()
					end)
					
					-- Đẻ tia chớp liên tục cách nhau 0.5 giây
					task.wait(0.5)
				end
			end,

			RequiresTarget = true,
			StopWhileAttacking = 3.5, -- Boss CỨNG NGẮC 3.5 giây để niệm chú
			Activation = {Type = "Time", Value = 16},
		},

		-- THỨC 2: CƠN MƯA LƯU TINH (Standstill Rapid-Fire)
		-- Đứng yên và spam rải thảm một vùng chữ thập cực nhanh quanh người chơi.
		{
			Callback = function(NearestTorso, Mob)
				for i = 1, 8 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local TargetPos = Floor(NearestTorso.Position)
					
					-- Spam liên tục theo bước di chuyển của người chơi
					local Part = AttackUtils:CreateBasePart({
						Color = ColorFast,
						Position = TargetPos + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)),
						Size = Vector3.new(0.5, 12, 12),
						Orientation = Vector3.new(0, 90, 90),
						Shape = "Cylinder",
					})
					Debris:AddItem(Part, 3)

					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.3) -- Không cho kịp phản ứng, phải vừa chạy vừa lách
						AttackUtils:RegisterHitDetection(Part, 0.1, 0.2)
						Part.Color = ColorCore
						Tween(Part, {0.2}, {Transparency = 0.5, Size = Part.Size + Vector3.new(0, 2, 2)})
						task.wait(0.2)
						Part:Destroy()
					end)

					task.wait(0.2) -- Xả đạn mỗi 0.2s
				end
			end,

			RequiresTarget = true,
			StopWhileAttacking = 2,
			Activation = {Type = "Time", Value = 2.5},
		}
	}
}
