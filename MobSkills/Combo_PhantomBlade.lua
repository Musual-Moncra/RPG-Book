--[[
	Combo_PhantomBlade.lua (Kiếm Khách Bóng Ma / Xuyên Không)
	Hollow bám quanh Boss, Dịch chuyển tức thời Boss ra sau lưng người chơi.
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

local C_Blade = Color3.fromRGB(180, 255, 255)
local C_Phantom = Color3.fromRGB(0, 50, 100)

return {
	{
		-- THỨC 1: KIẾM KHÍ THIÊN TÔN (Hollow Orbit bay theo quái)
		-- Đẻ ra 4 thanh kiếm xoay vòng tròn làm lớp khiên cắt tiết quanh Boss
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end

				-- Tạo 1 vật rỗng quay làm trục
				local Pivot = AttackUtils:CreateBasePart({ Color = C_Phantom, Position = Boss.Position, Size = Vector3.new(1,1,1), Transparency = 1 })
				local WeldC = Instance.new("WeldConstraint")
				WeldC.Part0 = Pivot; WeldC.Part1 = Boss; WeldC.Parent = Pivot
				Debris:AddItem(Pivot, 10)

				-- Tạo 4 thanh kiếm bám vây quanh trục (Bán kính 20 studs)
				local Swords = {}
				local angleStep = math.pi / 2
				for i = 1, 4 do
					local angle = angleStep * i
					local offset = Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
					local Sword = AttackUtils:CreateBasePart({ Color = C_Blade, Position = Boss.Position + offset, Size = Vector3.new(4, 4, 15), CFrame = CFrame.lookAt(Boss.Position + offset, Boss.Position) * CFrame.Angles(0, math.pi/2, 0), Shape = "Block" })
					
					local W = Instance.new("WeldConstraint"); W.Part0 = Sword; W.Part1 = Pivot; W.Parent = Sword
					Debris:AddItem(Sword, 10)
					table.insert(Swords, Sword)
					
					-- Dmg DoT liên tục cho 4 thanh kiếm
					AttackUtils:RegisterHitDetection(Sword, 0.05, 10)
				end

				-- Tween quay vòng tròn vật quay Pivot liên tục
				task.spawn(function()
					local active = true
					task.delay(10, function() active = false end)
					local currentY = 0
					while active and Pivot and Pivot.Parent do
						currentY = currentY + 30 -- Xoay 30 độ mỗi khung hình
						Tween(Pivot, {0.1}, {CFrame = Boss.CFrame * CFrame.Angles(0, math.rad(currentY), 0)})
						task.wait(0.1)
					end
					for _, S in pairs(Swords) do
						Tween(S, {0.5}, {Transparency = 1})
					end
					task.wait(0.5)
					for _, S in pairs(Swords) do S:Destroy() end
					Pivot:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1},
		},

		-- THỨC 2: ẢNH LƯU TRẢM (Boss Dịch Chuyển Ám Sát)
		-- Boss ngay lập tức biến mất và dịch chuyển sát sau lưng người chơi để chẻ kiếm.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("HumanoidRootPart") or Mob.Instance:FindFirstChild("Torso")
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not Boss or not TargetRoot then return end
				
				-- Dịch chuyển Boss ra phía sau người chơi (15 studs, xoay mặt nhìn vào lưng người chơi)
				local BackCFrame = TargetRoot.CFrame * CFrame.new(0, 0, 15) * CFrame.Angles(0, math.pi, 0)
				Boss.CFrame = BackCFrame
				
				-- Ngay lập tức kẻ một vệt kiếm ngang siêu to khổng lồ
				local FloorPos = Floor(Boss.Position)
				local Slash = AttackUtils:CreateBasePart({ Color = C_Phantom, Position = FloorPos, Size = Vector3.new(4, 4, 100), CFrame = CFrame.lookAt(FloorPos, TargetRoot.Position) * CFrame.Angles(0, math.pi/2, 0), Shape = "Block" })
				Debris:AddItem(Slash, 4)

				task.spawn(function()
					AttackUtils:Telegraph(Slash, 0.4) -- Cắt rất nhanh xé gió
					AttackUtils:RegisterHitDetection(Slash, 0.2, 0.2)
					Slash.Color = C_Blade
					Tween(Slash, {0.2}, {Size = Vector3.new(12, 12, 120), Transparency = 0})
					task.wait(0.2); Tween(Slash, {0.4}, {Transparency = 1, Size = Vector3.new(0,0,140)}); task.wait(0.4); Slash:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.0, Activation = {Type = "Time", Value = 10},
		},

		-- THỨC 3 TỐI THƯỢNG: TUYỆT SÁT NGỤT NGÀN (Bom Ảnh Phân Thân)
		-- Gọi 10 thanh kiếm rơi từ trời xuống cắm thành vòng bao người chơi rồi nổ tung.
		{
			Callback = function(Target, Mob)
				local Center = Floor(Target.Position)
				local radius = 35
				local angleStep = (math.pi * 2) / 8
				local pieces = {}

				for i = 1, 8 do
					local angle = angleStep * i
					local DropPos = Center + Vector3.new(math.cos(angle) * radius, 100, math.sin(angle) * radius)
					local GroundPos = Center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
					
					local Sword = AttackUtils:CreateBasePart({ Color = C_Blade, Position = DropPos, Size = Vector3.new(4, 30, 4), CFrame = CFrame.new(DropPos), Shape = "Block" })
					Debris:AddItem(Sword, 8)
					table.insert(pieces, {Sword, GroundPos})
					
					-- Dấu chấm đỏ dười đất
					local Mark = AttackUtils:CreateBasePart({ Color = C_Phantom, Position = GroundPos, Size = Vector3.new(0.5, 10, 10), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					AttackUtils:Telegraph(Mark, 1.5)
					task.spawn(function() task.wait(1.5); Mark:Destroy() end)
				end

				task.spawn(function()
					task.wait(1.5) -- Đợi báo động xong, đâm ầm xuống
					for _, item in pairs(pieces) do
						local S = item[1]
						local G = item[2]
						Tween(S, {0.15, "Linear", "Out"}, {Position = G + Vector3.new(0, 15, 0)})
						AttackUtils:RegisterHitDetection(S, 0.1, 0.2)
					end
					task.wait(0.2)
					-- Tụ vòng tròn và nổ dây chuyền toàn bộ
					local Boom = AttackUtils:CreateBasePart({ Color = C_Phantom, Position = Center, Size = Vector3.new(0.5, 90, 90), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					AttackUtils:Telegraph(Boom, 1)
					AttackUtils:RegisterHitDetection(Boom, 0.35, 0.3)
					Tween(Boom, {0.3}, {Transparency = 0, Size = Vector3.new(15, 90, 90)})
					for _, item in pairs(pieces) do
						Tween(item[1], {0.3}, {Transparency = 1, Size = Vector3.new(15, 30, 15)})
					end
					task.wait(0.3)
					Tween(Boom, {0.5}, {Transparency = 1}); task.wait(0.5)
					Boom:Destroy()
					for _, item in pairs(pieces) do item[1]:Destroy() end
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 18},
		}
	}
}
