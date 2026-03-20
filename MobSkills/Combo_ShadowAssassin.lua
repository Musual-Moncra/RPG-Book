--[[
	Combo_ShadowAssassin.lua
	Chuỗi Trảm Ảnh Ma Tôn (Sát Thủ Bóng Đêm - 4 Thức tập trung vào tốc độ và khóa mục tiêu hẹp)
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
local C_Dark = Color3.fromRGB(50, 0, 80)
local C_Strike = Color3.fromRGB(120, 0, 150)

return {
	{
		-- THỨC 1: LƯỚT ẢNH (Gạch chéo đường đi)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss or not Target then return end
				local Dist = 80
				local CF = CFrame.lookAt(Floor(Boss.Position), Vector3.new(Target.Position.X, Boss.Position.Y, Target.Position.Z))
				local Pos = (CF * CFrame.new(0,0,-Dist/2)).Position
				
				local Strike = AttackUtils:CreateBasePart({ Color = C_Dark, Position = Pos, Size = Vector3.new(4, 4, Dist), CFrame = CFrame.lookAt(Pos, Vector3.new(Target.Position.X, Pos.Y, Target.Position.Z)), Shape = "Block" })
				Debris:AddItem(Strike, 4)
				task.spawn(function()
					AttackUtils:Telegraph(Strike, 0.4) -- Quét lướt cực nhanh
					AttackUtils:RegisterHitDetection(Strike, 0.15, 0.2)
					Strike.Color = C_Strike
					Tween(Strike, {0.2}, {Transparency = 0.2}); task.wait(0.2); Tween(Strike, {0.2}, {Transparency = 1}); task.wait(0.2); Strike:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 0.8, Activation = {Type = "Time", Value = 1},
		},
		-- THỨC 2: PHÂN BÓNG BỦA VÂY (3 nhát chém chéo liên tiếp chèn ép người chơi)
		{
			Callback = function(Target, Mob)
				for i = 1, 3 do
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					local Slash = AttackUtils:CreateBasePart({ Color = C_Strike, Position = TPos, Size = Vector3.new(2, 6, 40), CFrame = CFrame.new(TPos) * CFrame.Angles(0, math.rad(math.random(0,180)), 0), Shape = "Block" })
					Debris:AddItem(Slash, 3)
					task.spawn(function()
						AttackUtils:Telegraph(Slash, 0.3) -- Không có time thở
						AttackUtils:RegisterHitDetection(Slash, 0.08, 0.2)
						Tween(Slash, {0.1}, {Transparency = 0, Size = Slash.Size + Vector3.new(2,0,0)}); task.wait(0.1); Tween(Slash, {0.1}, {Transparency = 1}); task.wait(0.1); Slash:Destroy()
					end)
					task.wait(0.25)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 3: MÓC LỐP (Hitbox lén sau lưng)
		{
			Callback = function(Target, Mob)
				local TPos = Target.Position
				-- Phán đoán phía sau lưng người chơi 12 studs
				local BackPos = TPos - (Target.CFrame.LookVector * 12)
				local BackGround = Floor(BackPos)
				local Trap = AttackUtils:CreateBasePart({ Color = C_Dark, Position = BackGround, Size = Vector3.new(0.5, 18, 18), Orientation = Vector3.new(0,90,90), Shape = "Cylinder" })
				Debris:AddItem(Trap, 4)
				task.spawn(function()
					AttackUtils:Telegraph(Trap, 0.5)
					AttackUtils:RegisterHitDetection(Trap, 0.2, 0.2)
					Trap.Color = C_Strike
					Tween(Trap, {0.2}, {Transparency = 0}); task.wait(0.2); Tween(Trap, {0.2}, {Transparency = 1}); task.wait(0.2); Trap:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1},
		},
		-- THỨC 4 TỐI THƯỢNG: MA TÔN XUẤT THẾ (Bùng nổ cầu bóng đêm khóa mục tiêu)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Bomb = AttackUtils:CreateBasePart({ Color = C_Dark, Position = Boss.Position, Size = Vector3.new(0.5, 60, 60), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Bomb, 6)
				
				task.spawn(function()
					AttackUtils:Telegraph(Bomb, 2)
					AttackUtils:RegisterHitDetection(Bomb, 0.4, 0.3)
					Bomb.Color = C_Strike
					Tween(Bomb, {0.2}, {Transparency = 0, Size = Vector3.new(15, 60, 60)})
					task.wait(0.2)
					Tween(Bomb, {0.4}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)})
					task.wait(0.4); Bomb:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 16},
		}
	}
}
