--[[
	Combo_Executioner.lua (Đao Phủ Đoạt Mệnh - Siêu Interact)
	Tính năng cực kỳ tương tác và ức chế: Khóa chân, Bắt cóc, Băng bó người chơi (Stun).
	Đây là chuỗi chiêu bắt người chơi phải luôn trong trạng thái đề phòng cao độ!
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

local C_Iron = Color3.fromRGB(100, 100, 100) -- Xám sắt
local C_Blood = Color3.fromRGB(200, 0, 0)    -- Đỏ máu

return {
	{
		-- THỨC 1: XÍCH BẮT HỒN (Kéo Cổ & Khóa Chân - Stun)
		-- Bắn ra một sợi xích siêu nhanh. Bất cứ ai dính phải sợi xích này sẽ bị
		-- giật thẳng vào mặt Boss và KHÓA CỨNG (Anchored) trong 1.5 giây!
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss or not Target then return end
				local TPos = Floor(Target.Position)
				local BPos = Floor(Boss.Position)
				
				local Dist = (TPos - BPos).Magnitude + 20
				local ChainCF = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z))
				local ChainCenter = (ChainCF * CFrame.new(0, 0, -Dist/2)).Position
				
				local Chain = AttackUtils:CreateBasePart({
					Color = C_Iron, Position = ChainCenter, Size = Vector3.new(2, 2, Dist),
					CFrame = CFrame.lookAt(ChainCenter, Vector3.new(TPos.X, ChainCenter.Y, TPos.Z)), Shape = "Block"
				})
				Debris:AddItem(Chain, 4)

				AttackUtils:Telegraph(Chain, 0.4) -- Nhanh vùn vụt

				-- HIỆU ỨNG TƯƠNG TÁC ĐẶC BIỆT: TỰ CODE EVENT CHẠM (ONTOUCH) ĐỂ STUN VÀ KÉO!
				local HitDebounce = {}
				local HitConn = Chain.Touched:Connect(function(Hit)
					local Player = Players:GetPlayerFromCharacter(Hit.Parent)
					if Player and not HitDebounce[Player] then
						HitDebounce[Player] = true
						local Hum = Player.Character:FindFirstChild("Humanoid")
						local Root = Player.Character:FindFirstChild("HumanoidRootPart")
						if Hum and Root then
							-- 1. Giật ngay 10% máu
							AttackUtils:Damage(Player, 0.1)
							
							-- 2. Kéo (Pull) người chơi ngay trước mặt Boss
							Root.CFrame = Boss.CFrame * CFrame.new(0, 0, -6)
							
							-- 3. Khóa chân (Stun)
							Root.Anchored = true
							Hum.WalkSpeed = 0
							
							-- 4. Giải phóng sau 1.5s
							task.delay(1.5, function()
								if Root and Hum then
									Root.Anchored = false
									Hum.WalkSpeed = 16 -- Tốc độ mặc định
								end
							end)
						end
					end
				end)

				Chain.Color = C_Blood
				Tween(Chain, {0.2}, {Transparency = 0, Size = Chain.Size + Vector3.new(2,2,0)})
				task.wait(0.2)
				HitConn:Disconnect() -- Ngắt tương tác
				Tween(Chain, {0.3}, {Transparency = 1, Size = Vector3.new(0,0,Dist)})
				task.wait(0.3); Chain:Destroy()
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1},
		},

		-- THỨC 2: MÁY CHÉM VÔ TÌNH (Guillotine)
		-- Ngay sau khi người chơi bị xích khóa chặt chân ở Thức 1, Đao Phủ thả ngay máy chém!
		-- Người chơi nào ko bấm Dash (nháy lướt giải hiệu ứng) sẽ chết chắc.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				-- Quét hitbox một vùng 15x15 ngay trước mặt Boss
				local GuillotineCF = Boss.CFrame * CFrame.new(0, 0, -8)
				local GPos = Floor(GuillotineCF.Position)

				local Warning = AttackUtils:CreateBasePart({
					Color = C_Blood, Position = GPos, Size = Vector3.new(0.5, 18, 18), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"
				})
				Debris:AddItem(Warning, 4)

				task.spawn(function()
					AttackUtils:Telegraph(Warning, 1.2) -- Cảnh báo 1.2s
					
					-- Sát thủ: Trảm thẳng 60% Máu!
					AttackUtils:RegisterHitDetection(Warning, 0.6, 0.4) 
					
					Warning.Color = Color3.fromRGB(0,0,0)
					Tween(Warning, {0.2}, {Size = Vector3.new(0.5, 25, 25), Transparency = 0})
					task.wait(0.2); Tween(Warning, {0.4}, {Size = Vector3.new(0.5, 0, 0), Transparency = 1}); task.wait(0.4); Warning:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 2},
		},

		-- THỨC 3: LỒNG CHIM (Cage Trap)
		-- Nhấn chìm bất kỳ ai trốn thoát vào một lồng giam 4 vách bằng sắt đỏ.
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Offsets = {
					{CFrame.new(0, 0, -15), Vector3.new(30, 20, 2)},  -- Mặt trước
					{CFrame.new(0, 0, 15),  Vector3.new(30, 20, 2)},  -- Mặt sau
					{CFrame.new(-15, 0, 0), Vector3.new(2, 20, 30)},  -- Mặt trái
					{CFrame.new(15, 0, 0),  Vector3.new(2, 20, 30)}   -- Mặt phải
				}
				
				for _, data in pairs(Offsets) do
					local offCF = data[1]
					local size = data[2]
					local WallCenter = (CFrame.new(TPos) * offCF).Position
					
					local Wall = AttackUtils:CreateBasePart({
						Color = C_Iron, Position = WallCenter, Size = size, CFrame = CFrame.lookAt(WallCenter, TPos), Shape = "Block"
					})
					Debris:AddItem(Wall, 7)
					
					task.spawn(function()
						AttackUtils:Telegraph(Wall, 0.8)
						-- Bất kỳ ai cố tình leo ra hoặc chạm tường sẽ rỉa máu & làm chậm
						local Conn = Wall.Touched:Connect(function(Hit)
							local Player = Players:GetPlayerFromCharacter(Hit.Parent)
							if Player then
								AttackUtils:Damage(Player, 0.02) -- Cắn tí máu liên tục nếu cứ húc vào
							end
						end)

						Tween(Wall, {0.2}, {Transparency = 0.3})
						task.wait(5)
						Conn:Disconnect()
						Tween(Wall, {0.5}, {Transparency = 1, Position = Wall.Position - Vector3.new(0, 20, 0)})
						task.wait(0.5); Wall:Destroy()
					end)
				end
				
				-- Ngay khi bị nhốt, Thả bom vào giữa lồng
				task.spawn(function()
					task.wait(1.5)
					local Bomb = AttackUtils:CreateBasePart({Color = C_Blood, Position = TPos, Size = Vector3.new(0.5, 25, 25), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder"})
					AttackUtils:Telegraph(Bomb, 1.5)
					AttackUtils:RegisterHitDetection(Bomb, 0.3, 0.3)
					Tween(Bomb, {0.3}, {Transparency = 0, Size = Vector3.new(15, 25, 25)})
					task.wait(0.3); Tween(Bomb, {0.5}, {Transparency = 1}); task.wait(0.5); Bomb:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2, Activation = {Type = "Time", Value = 6},
		},

		-- THỨC 4 TỐI THƯỢNG: TRỤC XUẤT (Bắn Lên Đỉnh Trời Khóa Chân Vĩnh Viễn)
		{
			Callback = function(Target, Mob)
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not TargetRoot then return end
				
				-- Dịch chuyển người chơi lơ lửng tận 100 studs trên cao và Tắt trọng lực (Anchored)
				TargetRoot.CFrame = TargetRoot.CFrame + Vector3.new(0, 100, 0)
				TargetRoot.Anchored = true
				
				local MidAir = TargetRoot.Position
				local Aura = AttackUtils:CreateBasePart({ Color = C_Blood, Position = MidAir, Size = Vector3.new(30, 30, 30), Shape = "Ball", Material = Enum.Material.Neon })
				Debris:AddItem(Aura, 8)

				task.spawn(function()
					AttackUtils:Telegraph(Aura, 3) -- Phán xét đếm ngược 3 giây trên trời đoạt nhãn
					AttackUtils:RegisterHitDetection(Aura, 0.8, 0.3) -- Phán xét cắn thẳng 80% máu, gần như One-Shot nếu HP đang lưng chừng!
					
					if TargetRoot and TargetRoot.Parent then TargetRoot.Anchored = false end -- Trả tự do rơi xuống

					Tween(Aura, {0.2}, {Transparency = 0, Size = Vector3.new(60, 60, 60)})
					task.wait(0.2); Tween(Aura, {0.5}, {Transparency = 1, Size = Vector3.new(1, 1, 1)}); task.wait(0.5); Aura:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 3.5, Activation = {Type = "Time", Value = 18},
		}
	}
}
