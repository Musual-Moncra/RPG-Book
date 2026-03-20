--[[
	Combo_WorldEnder.lua (Trùm Cuối: Kẻ Hủy Diệt Thế Giới)
	Quy mô cực kỳ khổng lồ. Yêu cầu người chơi phải liên tục chạy thục mạng bao quát toàn bộ map.
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

local C_Core = Color3.fromRGB(255, 50, 0)
local C_Beam = Color3.fromRGB(255, 100, 50)

return {
	{
		-- THỨC 1: SÀN ĐẤT RUNG CHUYỂN (Safe Zone)
		-- Cả bản đồ phát nổ 500 studs. CHỈ CÓ DUY NHẤT một khoảng chóp 30 studs dưới chân Boss là an toàn!
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				-- 4 bức tường siêu to quây thành một "Vùng an toàn" hình vuông rỗng 40x40 ở giữa
				local Offs = {
					{CFrame.new(0, 0, -220), Vector3.new(400, 20, 400)},
					{CFrame.new(0, 0, 220), Vector3.new(400, 20, 400)},
					{CFrame.new(-220, 0, 0), Vector3.new(400, 20, 400)},
					{CFrame.new(220, 0, 0), Vector3.new(400, 20, 400)}
				}
				
				for _, d in pairs(Offs) do
					local WPos = (CFrame.new(BPos) * d[1]).Position
					local WSize = d[2]
					local Zone = AttackUtils:CreateBasePart({ Color = C_Core, Position = WPos, Size = Vector3.new(WSize.X, 0.5, WSize.Z), CFrame = CFrame.lookAt(WPos, BPos), Shape = "Block" })
					Debris:AddItem(Zone, 8)
					
					task.spawn(function()
						AttackUtils:Telegraph(Zone, 3.5) -- Người chơi có 3.5s để nhìn màu đỏ và chui vào trong 40x40
						AttackUtils:RegisterHitDetection(Zone, 0.6, 0.4) -- Xoá sổ 60% Máu những ai đứng ngoài sảnh!
						Zone.Color = C_Beam
						Tween(Zone, {0.3}, {Transparency = 0, Size = Vector3.new(WSize.X, 30, WSize.Z)})
						task.wait(0.3); Tween(Zone, {0.6}, {Transparency = 1}); task.wait(0.6); Zone:Destroy()
					end)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 4, Activation = {Type = "Time", Value = 25},
		},

		-- THỨC 2: CỐI XAY TỬ THẦN (Windmill Lasers)
		-- 4 tia Laze 150 studs giăng ngang bản đồ và Xoay Tròn liên tục trong 8 giây.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Pivot = AttackUtils:CreateBasePart({ Color = C_Core, Position = Boss.Position, Size = Vector3.new(1,1,1), Transparency = 1 })
				Debris:AddItem(Pivot, 12)
				local W = Instance.new("WeldConstraint"); W.Part0 = Pivot; W.Part1 = Boss; W.Parent = Pivot
				
				local Beams = {}
				for i = 1, 4 do
					local ang = (math.pi/2) * i
					local Beam = AttackUtils:CreateBasePart({ Color = C_Beam, Position = Boss.Position, Size = Vector3.new(6, 6, 150), CFrame = CFrame.new(Boss.Position) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -75), Shape = "Block" })
					local BW = Instance.new("WeldConstraint"); BW.Part0 = Beam; BW.Part1 = Pivot; BW.Parent = Beam
					Debris:AddItem(Beam, 12)
					table.insert(Beams, Beam)
				end
				
				task.spawn(function()
					-- Bật Telegraph 1.5s nhấp nháy
					for _, b in pairs(Beams) do AttackUtils:Telegraph(b, 1.5) end
					task.wait(1.5)
					
					-- Sát thương duy trì chém liên tục
					for _, b in pairs(Beams) do AttackUtils:RegisterHitDetection(b, 0.1, 8.5) end
					
					-- Xoay Cối Xay Gió
					local active = true
					task.delay(8, function() active = false end)
					local Y = 0
					while active and Pivot and Pivot.Parent do
						Y = Y + 2.5 -- Xoay 2.5 độ một tick, cối xay chạy lùa người chơi
						Tween(Pivot, {0.1}, {CFrame = Boss.CFrame * CFrame.Angles(0, math.rad(Y), 0)})
						task.wait(0.1)
					end
					
					for _, b in pairs(Beams) do Tween(b, {0.5}, {Transparency = 1}) end
					task.wait(0.5)
					for _, b in pairs(Beams) do b:Destroy() end; Pivot:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 18},
		},

		-- THỨC 3: ĐÁP XUỐNG TỪ TẦNG OZONE (Planet Smasher)
		-- Boss bay thẳng lên trời cao 300 studs rồi giáng một đòn đạp đất tạo 3 sóng xung kích.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("HumanoidRootPart") or Mob.Instance:FindFirstChild("Torso")
				if not Boss or not Target then return end
				local BPos = Floor(Boss.Position)
				local TPos = Floor(Target.Position)
				
				-- Bay bổng lên trời tàng hình
				Boss.Anchored = true
				Tween(Boss, {1, "Quad", "In"}, {CFrame = Boss.CFrame + Vector3.new(0, 300, 0)})
				
				-- Cảnh báo dưới mặt đất chỗ Target
				local Mark = AttackUtils:CreateBasePart({ Color = C_Core, Position = TPos, Size = Vector3.new(0.5, 30, 30), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Mark, 4)
				AttackUtils:Telegraph(Mark, 2)
				
				task.spawn(function()
					task.wait(2)
					-- Đạp mạnh xuống mặt đất!
					Boss.CFrame = CFrame.new(TPos + Vector3.new(0, 10, 0))
					Boss.Anchored = false
					
					-- Sóng xung kích liên tiếp 3 nhịp to dần
					local scales = {40, 80, 120}
					for i, s in pairs(scales) do
						local Wave = AttackUtils:CreateBasePart({ Color = C_Beam, Position = TPos, Size = Vector3.new(10, s, s), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.Neon })
						Debris:AddItem(Wave, 2)
						AttackUtils:RegisterHitDetection(Wave, 0.25, 0.2)
						Tween(Wave, {0.4, "Quad", "Out"}, {Transparency = 1, Size = Vector3.new(0.5, s+40, s+40)})
						task.wait(0.2)
					end
					Mark:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 3.5, Activation = {Type = "Time", Value = 22},
		}
	}
}
