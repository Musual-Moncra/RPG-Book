--[[
	Combo_Trickster.lua (Ngụy Tạo & Hoán Đổi Sinh Tử)
	Chuỗi chiêu hack não: Hoán đổi vị trí tàn độc khiến người chơi tự chạy vào vùng chết,
	cộng với việc tạo ra ảo ảnh dọa nạt, tăng độ tập trung tới đỉnh điểm.
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

local C_Trick = Color3.fromRGB(255, 100, 200) -- Hồng lừa gạt
local C_Death = Color3.fromRGB(0, 0, 0)       -- Đen tuyền

return {
	{
		-- THỨC 1: HOÁN ĐỔI SINH TỬ ĐỘT NGỘT (Sudden Swap)
		-- Cực kỳ mất dạy: Chớp mắt một cái, Boss và người chơi TRÁO ĐỔI VỊ TRÍ.
		-- Chỗ Boss (nay là người chơi đứng) bùng nổ tức tốc trong 0.5s!
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("HumanoidRootPart") or Mob.Instance:FindFirstChild("Torso")
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not Boss or not TargetRoot then return end
				
				-- Lưu lại vị trí để tráo
				local BossOldCF = Boss.CFrame
				local TargetOldCF = TargetRoot.CFrame
				
				-- Boom! Tráo đổi CFrame ngang tàng
				TargetRoot.CFrame = BossOldCF
				Boss.CFrame = TargetOldCF
				
				-- NGAY LẬP TỨC đặt một quả bom nổ siêu nhanh MẤT DẠY ngay tại vị trí cũ của Boss (tức là chỗ người chơi vừa bị chuyển tới)
				local TrapPos = Floor(BossOldCF.Position)
				local Trap = AttackUtils:CreateBasePart({
					Color = C_Death, Position = TrapPos, Size = Vector3.new(0.5, 25, 25), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
				})
				Debris:AddItem(Trap, 4)

				task.spawn(function()
					AttackUtils:Telegraph(Trap, 0.5) -- Người chơi chỉ có nửa giây để chớp mắt và gạt nút né khỏi chỗ đó!
					AttackUtils:RegisterHitDetection(Trap, 0.25, 0.3) -- Nát 25% máu
					Trap.Color = C_Trick
					Tween(Trap, {0.2}, {Transparency = 0, Size = Vector3.new(15, 35, 35)})
					task.wait(0.2); Tween(Trap, {0.3}, {Transparency = 1, Size = Vector3.new(0.5, 50, 50)}); task.wait(0.3); Trap:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 0.5, Activation = {Type = "Time", Value = 1},
		},

		-- THỨC 2: MÙ LOÀ (Bom Giả Chân)
		-- Đẻ ra 10 bãi nổ ngẫu nhiên. Chỉ có 3 bãi nổ Tỏa Mầu Hồng Đen (C_Tick/C_Death) là Gây Sát thương chết chóc.
		-- Còn lại là màu nhạt hoàn toàn không có hitbox! Game thủ phải nhanh mắt nhìn màu để né vùng thật.
		{
			Callback = function(Target, Mob)
				local TargetPos = Floor(Target.Position)
				
				for i = 1, 12 do
					local FakePos = TargetPos + Vector3.new(math.random(-40, 40), 0, math.random(-40, 40))
					-- Radom tỉ lệ Mìn Thật (25%) / Mìn Giả (75%)
					local isReal = math.random(1, 4) == 1 
					
					local BombColor = isReal and C_Death or Color3.fromRGB(230, 230, 230) -- Mìn giả màu Trắng nhạt xám
					
					local Bomb = AttackUtils:CreateBasePart({
						Color = BombColor, Position = FakePos, Size = Vector3.new(0.5, 18, 18), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
					})
					Debris:AddItem(Bomb, 4)
					
					task.spawn(function()
						AttackUtils:Telegraph(Bomb, 1.5) -- Cho 1.5s để game thủ căng mắt chọn chỗ dẫm
						
						if isReal then
							AttackUtils:RegisterHitDetection(Bomb, 0.2, 0.2) -- Thật cắn 20%
							Bomb.Color = C_Trick
							Tween(Bomb, {0.2}, {Transparency = 0, Size = Vector3.new(10, 18, 18)})
						else
							-- Bom giả tịt ngòi, không kích hoạt hitbox, mờ đi luôn
							Tween(Bomb, {0.2}, {Transparency = 1})
						end
						
						task.wait(0.3)
						Tween(Bomb, {0.4}, {Transparency = 1}); task.wait(0.4); Bomb:Destroy()
					end)
					
					task.wait(0.05) -- Spawn liên tục ngập sàn
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 3},
		},

		-- THỨC 3: GIẬT LÙI LỐC XOÁY (Pushback)
		-- Bắn 1 vòng laze bự hất tung văng người chơi văng lùi lại xa 30 studs!
		-- Ép người chơi phải bơi lại gần Boss.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				
				local Repel = AttackUtils:CreateBasePart({
					Color = C_Trick, Position = Floor(Boss.Position), Size = Vector3.new(0.5, 40, 40), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
				})
				Debris:AddItem(Repel, 4)
				
				task.spawn(function()
					AttackUtils:Telegraph(Repel, 0.8)
					
					-- Custom Event hất văng (Pushback)
					local Conn = Repel.Touched:Connect(function(Hit)
						local Player = Players:GetPlayerFromCharacter(Hit.Parent)
						if Player then
							local Root = Hit.Parent:FindFirstChild("HumanoidRootPart")
							if Root then
								-- Bơm 1 BodyVelocity nhỏ hoặc chỉnh CFrame hất lùi bạo lực
								-- (Ở đây dùng dịch chuyển bạo lực lùi về 30 studs bằng cái nhìn đối với Boss)
								local cf = CFrame.lookAt(Boss.Position, Root.Position)
								Root.CFrame = Root.CFrame + cf.LookVector * 25
							end
						end
					end)
					
					AttackUtils:RegisterHitDetection(Repel, 0.1, 0.2) -- Kèm xíu dmg
					Tween(Repel, {0.2}, {Transparency = 0, Size = Vector3.new(5, 60, 60)})
					task.wait(0.2)
					Conn:Disconnect()
					Tween(Repel, {0.3}, {Transparency = 1, Size = Vector3.new(0.5, 80, 80)})
					task.wait(0.3); Repel:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1.0, Activation = {Type = "Time", Value = 15},
		}
	}
}
