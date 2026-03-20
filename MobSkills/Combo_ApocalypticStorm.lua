--[[
	Combo_ApocalypticStorm.lua (Bão Táp Tận Thế)
	Sự hỗn mang rợp trời bằng Hố đen hút và các Lốc xoáy chạy rông trên map.
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

local C_Storm = Color3.fromRGB(100, 255, 200)
local C_Thunder = Color3.fromRGB(255, 255, 50)

return {
	{
		-- THỨC 1: TRIỆU GỌI LỐC XOÁY LANG THANG (Wandering Tornadoes)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				-- 4 lốc xoáy lang thang trên bản đồ trong 12 giây
				for i = 1, 4 do
					local angle = (math.pi/2) * i
					local off = Vector3.new(math.cos(angle)*30, 0, math.sin(angle)*30)
					local Nado = AttackUtils:CreateBasePart({ Color = C_Storm, Position = BPos + off, Size = Vector3.new(0.5, 30, 30), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.ForceField })
					Debris:AddItem(Nado, 15)
					
					task.spawn(function()
						AttackUtils:Telegraph(Nado, 1.5)
						AttackUtils:RegisterHitDetection(Nado, 0.08, 12) -- Bước vào là bị xé xác duy trì
						Tween(Nado, {0.5}, {Transparency = 0.5, Size = Vector3.new(80, 30, 30)}) -- Cao 80, rộng 30
						
						local alive = true
						task.delay(12, function() alive = false end)
						-- AI lang thang cho Lốc Xoáy
						while alive and Nado and Nado.Parent do
							local tpos = Target and Target.Parent and Target.Position or BPos
							-- Cứ 1 giây Lốc xoáy lại rượt theo tpos một tí
							local drift = tpos + Vector3.new(math.random(-25,25), 0, math.random(-25,25))
							Tween(Nado, {1.0, "Sine", "Out"}, {Position = Floor(drift)})
							task.wait(1.0)
						end
						
						Tween(Nado, {0.5}, {Transparency = 1}); task.wait(0.5); Nado:Destroy()
					end)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 25},
		},

		-- THỨC 2: MƯA SÉT KINH HOÀNG (Thunder Spam)
		-- Ngay khi lốc xoáy đang chạy, Boss xả thêm sấm sét đùng đùng
		{
			Callback = function(Target, Mob)
				local Central = Floor(Target.Position)
				for i = 1, 15 do
					if not Target or not Target.Parent then break end
					local RndPos = Central + Vector3.new(math.random(-35,35), 0, math.random(-35,35))
					local Strike = AttackUtils:CreateBasePart({ Color = C_Thunder, Position = RndPos, Size = Vector3.new(0.5, 12, 12), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					Debris:AddItem(Strike, 3)
					
					task.spawn(function()
						AttackUtils:Telegraph(Strike, 0.6)
						AttackUtils:RegisterHitDetection(Strike, 0.1, 0.2)
						Tween(Strike, {0.2}, {Transparency = 0, Size = Vector3.new(60, 12, 12)})
						task.wait(0.2); Tween(Strike, {0.3}, {Transparency = 1}); task.wait(0.3); Strike:Destroy()
					end)
					task.wait(0.25)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 4, Activation = {Type = "Time", Value = 15},
		},

		-- THỨC 3 TỐI THƯỢNG: LỖ ĐEN NUỐT CHỬNG (Vacuum Pull)
		-- Boss hóa tâm bão, Hút mọi thứ dưới sàn giật ngược vào người nó! (Đẩy người chơi bay thẳng vào mấy Lốc Xoáy)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				local Vacuum = AttackUtils:CreateBasePart({ Color = C_Storm, Position = BPos, Size = Vector3.new(0.5, 150, 150), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Vacuum, 5)
				
				task.spawn(function()
					AttackUtils:Telegraph(Vacuum, 2)
					
					-- Dùng Touch để giật ngược mọi người chơi bên trong về tâm Boss
					local Conn = Vacuum.Touched:Connect(function(Hit)
						local Player = Players:GetPlayerFromCharacter(Hit.Parent)
						if Player then
							local Root = Hit.Parent:FindFirstChild("HumanoidRootPart")
							if Root then
								-- Lực giật ngược bạo lực - hất tung thẳng về Boss
								local cf = CFrame.lookAt(Root.Position, Boss.Position)
								Root.CFrame = Root.CFrame + cf.LookVector * 15
							end
						end
					end)
					
					Vacuum.Color = Color3.fromRGB(0, 0, 0)
					Tween(Vacuum, {0.5}, {Transparency = 0.6, Size = Vector3.new(15, 150, 150)})
					task.wait(1.5) -- Quá trình hút duy trì 1.5s
					Conn:Disconnect()
					
					-- Nổ nhẹ đánh bay
					AttackUtils:RegisterHitDetection(Vacuum, 0.2, 0.3)
					Tween(Vacuum, {0.3}, {Transparency = 1, Size = Vector3.new(0.5, 180, 180)}); task.wait(0.3); Vacuum:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 22},
		}
	}
}
