--[[
	ThunderGodCombo.lua
	
	Đã nâng cấp: CĂNG THẲNG HƠN - PHỨC TẠP HƠN.
	Tại Thức 5 (Thiên Lôi Phán Xét), Boss sẽ không chỉ trải 1 vòng đỏ 3 giây rồi đứng yên chờ,
	nó sẽ phóng liên tục 6 tia chớp giật vào đầu mục tiêu NGAY TRONG LÚC cái vòng 3 giây đang tụ lực!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local AttackUtils, Tween, Floor
if RunService:IsServer() then
	local ServerStorage = game:GetService("ServerStorage")
	AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
	Tween = AttackUtils.Tween
	Floor = AttackUtils.Floor
end

local ColorThunder = Color3.fromRGB(0, 255, 255)
local ColorThunderCore = Color3.fromRGB(255, 255, 200)
local ColorWarning = Color3.fromRGB(200, 50, 50)

return {
	{
		-- Thức 1: Sấm Động
		{
			Callback = function(NearestTorso, Mob)
				local TargetPosition = Floor(NearestTorso.Position)
				local Part = AttackUtils:CreateBasePart({
					Color = ColorThunder, Position = TargetPosition,
					Size = Vector3.new(0.5, 12, 12), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder",
				})
				Debris:AddItem(Part, 5)
				AttackUtils:Telegraph(Part, 0.6)
				AttackUtils:RegisterHitDetection(Part, 0.1, 0.2)
				Tween(Part, {0.3}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)})
				task.wait(0.3)
				Part:Destroy()
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1.2},
		},

		-- Thức 2: Tứ Tượng Lôi
		{
			Callback = function(NearestTorso, Mob)
				local TargetPosition = Floor(NearestTorso.Position)
				local Part1 = AttackUtils:CreateBasePart({ Color = ColorThunder, Position = TargetPosition, Size = Vector3.new(6, 4, 80), CFrame = CFrame.new(TargetPosition), Shape = "Block" })
				local Part2 = AttackUtils:CreateBasePart({ Color = ColorThunder, Position = TargetPosition, Size = Vector3.new(6, 4, 80), CFrame = CFrame.new(TargetPosition) * CFrame.Angles(0, math.rad(90), 0), Shape = "Block" })
				Debris:AddItem(Part1, 5); Debris:AddItem(Part2, 5)
				task.spawn(function() AttackUtils:Telegraph(Part1, 1) end)
				AttackUtils:Telegraph(Part2, 1)
				AttackUtils:RegisterHitDetection(Part1, 0.15, 0.3)
				AttackUtils:RegisterHitDetection(Part2, 0.15, 0.3)
				task.spawn(function() Tween(Part1, {0.3}, {Transparency = 1}); task.wait(0.3); Part1:Destroy() end)
				Tween(Part2, {0.3}, {Transparency = 1}); task.wait(0.3); Part2:Destroy()
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1.5},
		},

		-- Thức 3: Lôi Trận
		{
			Callback = function(NearestTorso, Mob)
				for i = 1, 3 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local TargetPosition = Floor(NearestTorso.Position)
					local Part = AttackUtils:CreateBasePart({ Color = ColorThunder, Position = TargetPosition, Size = Vector3.new(0.5, 20, 20), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					Debris:AddItem(Part, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.5)
						AttackUtils:RegisterHitDetection(Part, 0.1, 0.2)
						Tween(Part, {0.3}, {Transparency = 1}); task.wait(0.3); Part:Destroy()
					end)
					task.wait(0.4)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2, Activation = {Type = "Time", Value = 2.5},
		},

		-- Thức 4: Lôi Tốc
		{
			Callback = function(NearestTorso, Mob)
				local TargetPos = Floor(NearestTorso.Position)
				local BossPos = Floor(Mob.Instance:GetPivot().Position)
				local Dist = (TargetPos - BossPos).Magnitude + 20
				local CFrameLaser = CFrame.lookAt(BossPos, Vector3.new(TargetPos.X, BossPos.Y, TargetPos.Z))
				local LaserCenterPos = (CFrameLaser * CFrame.new(0, 0, -(Dist/2))).Position
				local Part = AttackUtils:CreateBasePart({ Color = ColorThunder, Position = LaserCenterPos, Size = Vector3.new(12, 10, Dist), CFrame = CFrame.lookAt(LaserCenterPos, Vector3.new(TargetPos.X, LaserCenterPos.Y, TargetPos.Z)), Shape = "Block" })
				Debris:AddItem(Part, 6)
				AttackUtils:Telegraph(Part, 1.2)
				AttackUtils:RegisterHitDetection(Part, 0.2, 0.3)
				Tween(Part, {0.4}, {Transparency = 1}); task.wait(0.4); Part:Destroy()
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1.5},
		},

		-- THỨC 5 TỐI THƯỢNG ĐƯỢC CHỈNH SỬA LẠI: LỒNG ĐÒN DỒN DẬP 
		{
			Callback = function(NearestTorso, Mob)
				local BossPos = Floor(Mob.Instance:GetPivot().Position)

				-- 1. TẠO VÙNG CHẾT CHẬM (3 giây Telegraph) Bắt buộc người chơi phải chạy ra mép
				local GiantPart = AttackUtils:CreateBasePart({
					Color = ColorWarning, Position = BossPos,
					Size = Vector3.new(0.5, 90, 90), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder",
				})
				Debris:AddItem(GiantPart, 10)

				-- Nhánh 1: Chạy vòng đếm ngược 3 giây
				task.spawn(function()
					AttackUtils:Telegraph(GiantPart, 3) 
					AttackUtils:RegisterHitDetection(GiantPart, 0.4, 0.5) -- Trúng là bay 40% máu
					Tween(GiantPart, {0.5}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)})
					task.wait(0.5)
					GiantPart:Destroy()
				end)

				-- Nhánh 2: TRONG LÚC chờ 3 giây kia, Boss xả thêm sấm sét nhỏ liên tục thẳng vào đầu người chơi
				-- Ép người chơi phải nhảy lách qua vệt sét VÀ tháo chạy khỏi cái vùng đỏ khổng lồ
				for i = 1, 5 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local TargetPos = Floor(NearestTorso.Position)
					local FastStrike = AttackUtils:CreateBasePart({
						Color = ColorThunderCore, Position = TargetPos,
						Size = Vector3.new(0.5, 10, 10), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder",
					})
					Debris:AddItem(FastStrike, 3)

					task.spawn(function()
						AttackUtils:Telegraph(FastStrike, 0.3) -- Siêu nhanh 0.3s
						AttackUtils:RegisterHitDetection(FastStrike, 0.05, 0.2) -- Trúng cắn 5% máu
						Tween(FastStrike, {0.2}, {Transparency = 1})
						task.wait(0.2)
						FastStrike:Destroy()
					end)
					
					task.wait(0.5) -- Dội mỗi nửa giây một quả
				end
			end,

			RequiresTarget = false,
			StopWhileAttacking = 3.5, -- Bắt Boss phải "đứng yên" gồng trong suốt quá trình đếm ngược & spam đạn
			Activation = {Type = "Time", Value = 15}, 
		}
	}
}
