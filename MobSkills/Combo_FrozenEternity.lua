--[[
	Combo_FrozenEternity.lua
	Chuỗi Combo Kỷ Nguyên Băng Giá (4 Thức liên hoàn)
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
local C_Ice = Color3.fromRGB(150, 220, 255)
local C_Chill = Color3.fromRGB(200, 240, 255)

return {
	{
		-- THỨC 1: SÓNG LẠNH (Băng quyển đẩy lùi)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				local sizes = {20, 40, 60}
				for i, rad in pairs(sizes) do
					local Part = AttackUtils:CreateBasePart({ Color = C_Ice, Position = BPos, Size = Vector3.new(0.5, rad, rad), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					Debris:AddItem(Part, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.8)
						AttackUtils:RegisterHitDetection(Part, 0.1, 0.3)
						Tween(Part, {0.3}, {Transparency = 1, Size = Vector3.new(5, rad, rad)})
						task.wait(0.3); Part:Destroy()
					end)
					task.wait(0.5) -- Sóng tỏa ra từ từ
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 1.8},
		},
		-- THỨC 2: MƯA BĂNG TIỄN (Nhắm thẳng đầu)
		{
			Callback = function(Target, Mob)
				for i = 1, 4 do
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					local IceProj = AttackUtils:CreateBasePart({ Color = C_Ice, Position = TPos, Size = Vector3.new(4, 4, 30), CFrame = CFrame.lookAt(TPos + Vector3.new(math.random(-15,15), 30, math.random(-15,15)), TPos), Shape = "Block", Material = Enum.Material.Ice })
					Debris:AddItem(IceProj, 3)
					task.spawn(function()
						AttackUtils:Telegraph(IceProj, 0.5)
						AttackUtils:RegisterHitDetection(IceProj, 0.15, 0.2)
						Tween(IceProj, {0.2}, {Position = TPos})
						task.wait(0.2); Tween(IceProj, {0.2}, {Transparency = 1}); task.wait(0.2); IceProj:Destroy()
					end)
					task.wait(0.4)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 3: NHÀ GIAM BĂNG GIÁ (Nhốt bằng 4 cột)
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local offsets = { Vector3.new(15,0,0), Vector3.new(-15,0,0), Vector3.new(0,0,15), Vector3.new(0,0,-15) }
				for _, off in pairs(offsets) do
					local Wall = AttackUtils:CreateBasePart({ Color = C_Chill, Position = TPos + off, Size = Vector3.new(2, 40, 30), CFrame = CFrame.lookAt(TPos + off, TPos), Shape = "Block", Material = Enum.Material.ForceField })
					Debris:AddItem(Wall, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Wall, 1)
						AttackUtils:RegisterHitDetection(Wall, 0.2, 0.3)
						Tween(Wall, {0.2}, {Transparency = 0.4})
						task.wait(4); Tween(Wall, {0.5}, {Transparency = 1}); task.wait(0.5); Wall:Destroy()
					end)
				end
				-- Ở giữa rải Bão tuyết rỉa máu
				task.spawn(function()
					task.wait(1)
					local Core = AttackUtils:CreateBasePart({ Color = C_Ice, Position = TPos, Size = Vector3.new(0.5, 30, 30), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					AttackUtils:RegisterHitDetection(Core, 0.05, 4)
					Tween(Core, {4}, {Transparency = 1}); task.wait(4); Core:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 4},
		},
		-- THỨC 4 TỐI THƯỢNG: TUYỆT ĐỘ KHÔNG (Absolute Zero)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				local GiantZero = AttackUtils:CreateBasePart({ Color = C_Ice, Position = BPos, Size = Vector3.new(0.5, 120, 120), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.Neon })
				Debris:AddItem(GiantZero, 8)
				task.spawn(function()
					AttackUtils:Telegraph(GiantZero, 3.5)
					AttackUtils:RegisterHitDetection(GiantZero, 0.6, 0.4) -- Xóa sổ 60% máu!
					Tween(GiantZero, {0.3}, {Size = Vector3.new(50, 120, 120), Transparency = 0.2})
					task.wait(0.3); Tween(GiantZero, {0.5}, {Size = Vector3.new(0.5, 0, 0), Transparency = 1}); task.wait(0.5); GiantZero:Destroy()
				end)
				
				-- Nhiễu loạn đạn băng trong 3.5s tụ lực
				for i = 1, 6 do
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					local Spike = AttackUtils:CreateBasePart({ Color = C_Chill, Position = TPos, Size = Vector3.new(0.5, 8, 8), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
					task.spawn(function()
						AttackUtils:Telegraph(Spike, 0.4); AttackUtils:RegisterHitDetection(Spike, 0.05, 0.3)
						Tween(Spike, {0.2}, {Transparency = 1}); task.wait(0.2); Spike:Destroy()
					end)
					task.wait(0.5)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 4, Activation = {Type = "Time", Value = 20},
		}
	}
}
