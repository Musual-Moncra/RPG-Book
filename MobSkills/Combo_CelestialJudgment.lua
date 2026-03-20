--[[
	Combo_CelestialJudgment.lua
	Chuỗi Phán Xét Thiên Thần (Sát thương Ánh sáng - 4 Thức)
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
local C_Holy = Color3.fromRGB(255, 255, 100)
local C_Ray = Color3.fromRGB(255, 255, 200)

return {
	{
		-- THỨC 1: TỘI ĐỒ (4 cột sáng phạt)
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local offsets = { Vector3.new(15,0,15), Vector3.new(-15,0,15), Vector3.new(15,0,-15), Vector3.new(-15,0,-15) }
				for _, off in pairs(offsets) do
					local Pillar = AttackUtils:CreateBasePart({ Color = C_Holy, Position = TPos + off + Vector3.new(0,50,0), Size = Vector3.new(100, 10, 10), Orientation = Vector3.new(0,0,90), Shape = "Cylinder", Material = Enum.Material.Neon })
					Debris:AddItem(Pillar, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Pillar, 0.8)
						AttackUtils:RegisterHitDetection(Pillar, 0.15, 0.2)
						Tween(Pillar, {0.2}, {Transparency = 0, Size = Pillar.Size + Vector3.new(0,5,5)})
						task.wait(0.2); Tween(Pillar, {0.3}, {Transparency = 1}); task.wait(0.3); Pillar:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 2: TIA SÁNG THANH TRỪNG (Cắt bầu trời dọc)
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				local Block = AttackUtils:CreateBasePart({ Color = C_Ray, Position = BPos, Size = Vector3.new(10, 60, 100), CFrame = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z)) * CFrame.new(0, 30, -50), Shape = "Block" })
				Debris:AddItem(Block, 5)
				task.spawn(function()
					AttackUtils:Telegraph(Block, 1.2)
					AttackUtils:RegisterHitDetection(Block, 0.25, 0.3)
					Tween(Block, {0.3}, {Transparency = 0, Size = Block.Size + Vector3.new(5, 0, 0)})
					task.wait(0.3); Tween(Block, {0.4}, {Transparency = 1}); task.wait(0.4); Block:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 2},
		},
		-- THỨC 3: LƯỜI HÁI CHỮ THẬP
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local P1 = AttackUtils:CreateBasePart({ Color = C_Holy, Position = TPos, Size = Vector3.new(6, 6, 80), CFrame = CFrame.new(TPos), Shape = "Block" })
				local P2 = AttackUtils:CreateBasePart({ Color = C_Holy, Position = TPos, Size = Vector3.new(6, 6, 80), CFrame = CFrame.new(TPos) * CFrame.Angles(0, math.rad(90), 0), Shape = "Block" })
				Debris:AddItem(P1, 4); Debris:AddItem(P2, 4)
				task.spawn(function()
					AttackUtils:Telegraph(P1, 0.6); AttackUtils:RegisterHitDetection(P1, 0.15, 0.2)
					Tween(P1, {0.2}, {Transparency = 1}); task.wait(0.2); P1:Destroy()
				end)
				task.spawn(function()
					AttackUtils:Telegraph(P2, 0.6); AttackUtils:RegisterHitDetection(P2, 0.15, 0.2)
					Tween(P2, {0.2}, {Transparency = 1}); task.wait(0.2); P2:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 2},
		},
		-- THỨC 4 TỐI THƯỢNG: ÁNH SÁNG CỦA CHÚA (Ngồi thiền tụ lực nổ bản đồ)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				local Nova = AttackUtils:CreateBasePart({ Color = C_Holy, Position = BPos, Size = Vector3.new(0.5, 100, 100), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Nova, 8)
				task.spawn(function()
					AttackUtils:Telegraph(Nova, 3) 
					AttackUtils:RegisterHitDetection(Nova, 0.5, 0.3) -- Nổ nửa cây HP
					
					-- Đồng thời Hồi Máu 15% Max HP cho bản thân vì hút tụ năng lượng
					if Mob.Enemy then
						Mob.Enemy.Health = math.clamp(Mob.Enemy.Health + Mob.Enemy.MaxHealth * 0.15, 0, Mob.Enemy.MaxHealth)
					end
					
					Tween(Nova, {0.3}, {Transparency = 0, Size = Nova.Size + Vector3.new(10, 20, 20)})
					task.wait(0.3); Tween(Nova, {0.5}, {Transparency = 1}); task.wait(0.5); Nova:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 3.5, Activation = {Type = "Time", Value = 18},
		}
	}
}
