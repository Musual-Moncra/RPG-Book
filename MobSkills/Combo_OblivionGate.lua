--[[
	Combo_OblivionGate.lua (Địa Ngục Touhou / Bullet Hell)
	Kiểu xả đạn (địa ngục đạn) dồn dập và tường ép 2 bên. Đòi hỏi di chuyển rất khéo léo.
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

local C_Gate = Color3.fromRGB(0, 30, 80)
local C_Bullet = Color3.fromRGB(100, 200, 255)

return {
	{
		-- THỨC 1: CÔN TRÙNG CẮN XÉ (Bullet Hell)
		-- Ép Boss đứng yên và khạc ra 3 đợt đạn, mỗi đợt 16 viên bay rợp trời theo vòng tròn.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				
				for wave = 1, 3 do
					local BPos = Floor(Boss.Position)
					for i = 1, 16 do
						local angle = (math.pi * 2 / 16) * i + (wave * 0.2) -- Lệch xoáy nhẹ mỗi Wave
						local EndPos = BPos + Vector3.new(math.cos(angle)*80, 0, math.sin(angle)*80)
						
						local Orb = AttackUtils:CreateBasePart({ Color = C_Bullet, Position = BPos, Size = Vector3.new(4, 4, 4), Shape = "Ball", Material = Enum.Material.Neon })
						Debris:AddItem(Orb, 5)
						
						task.spawn(function()
							AttackUtils:RegisterHitDetection(Orb, 0.08, 0.2)
							-- Đạn bay với tốc độ vừa phải cho game thủ luồn lách (2 giây)
							Tween(Orb, {2, "Linear", "Out"}, {Position = EndPos, Size = Vector3.new(6, 6, 6)})
							task.wait(2)
							Tween(Orb, {0.3}, {Transparency = 1}); task.wait(0.3); Orb:Destroy()
						end)
					end
					task.wait(0.8) -- Cứ 0.8s lại xả 1 Wave đạn
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 10},
		},

		-- THỨC 2: TƯỜNG ÉP MÁY ÉP RÁC (Compactor Walls)
		-- 2 Tường siêu to khổng lồ 300 studs ép từ 2 bên sườn vào để giới hạn không gian di chuyển.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				local W1 = AttackUtils:CreateBasePart({ Color = C_Gate, Position = BPos + Vector3.new(150, 0, 0), Size = Vector3.new(10, 60, 300), Shape = "Block", Material = Enum.Material.ForceField })
				local W2 = AttackUtils:CreateBasePart({ Color = C_Gate, Position = BPos + Vector3.new(-150, 0, 0), Size = Vector3.new(10, 60, 300), Shape = "Block", Material = Enum.Material.ForceField })
				Debris:AddItem(W1, 15); Debris:AddItem(W2, 15)
				
				task.spawn(function()
					AttackUtils:Telegraph(W1, 1); AttackUtils:Telegraph(W2, 1)
					
					AttackUtils:RegisterHitDetection(W1, 0.15, 8) -- Nếu chạm tường kẹt lại sẽ bị cà nhão
					AttackUtils:RegisterHitDetection(W2, 0.15, 8)
					
					-- Trượt tường nhốt lại (Còn 60 studs ở giữa)
					Tween(W1, {8, "Sine", "In"}, {Position = BPos + Vector3.new(30, 0, 0), Transparency = 0.4})
					Tween(W2, {8, "Sine", "In"}, {Position = BPos + Vector3.new(-30, 0, 0), Transparency = 0.4})
					
					task.wait(8)
					Tween(W1, {1}, {Transparency = 1}); Tween(W2, {1}, {Transparency = 1}); task.wait(1); W1:Destroy(); W2:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 25},
		},

		-- THỨC 3: DEATH BEAM (Căn chuẩn lúc tường đang ép)
		-- Bắn một luồng sáng dài 400 studs! Ép người chơi phải luồn mép.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss or not Target then return end
				local TPos = Floor(Target.Position)
				local BPos = Floor(Boss.Position)
				
				local BeamCF = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z))
				local BeamCenter = (BeamCF * CFrame.new(0, 0, -200)).Position
				
				local Beam = AttackUtils:CreateBasePart({
					Color = C_Gate, Position = BeamCenter, Size = Vector3.new(12, 12, 400), CFrame = CFrame.lookAt(BeamCenter, Vector3.new(TPos.X, BeamCenter.Y, TPos.Z)), Shape = "Block"
				})
				Debris:AddItem(Beam, 6)
				
				task.spawn(function()
					AttackUtils:Telegraph(Beam, 2) -- Tụ rát 2s
					AttackUtils:RegisterHitDetection(Beam, 0.4, 0.2)
					Beam.Color = C_Bullet
					Beam.Material = Enum.Material.Neon
					Tween(Beam, {0.3}, {Transparency = 0, Size = Vector3.new(20, 20, 400)})
					task.wait(0.3)
					Tween(Beam, {0.5}, {Transparency = 1, Size = Vector3.new(0, 0, 400)}); task.wait(0.5); Beam:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 8},
		}
	}
}
