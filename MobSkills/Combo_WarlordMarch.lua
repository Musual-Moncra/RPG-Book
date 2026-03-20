--[[
	Combo_WarlordMarch.lua (Cuộc Hành Quân Của Bạo Chúa)
	Thả vô số đại kiếm từ trên trời khóa kín xung quanh mục tiêu 
	rồi dậm đất tạo thành hình dấu X nứt mặt kính.
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
local C_Sword = Color3.fromRGB(180, 180, 180)
local C_Earth = Color3.fromRGB(255, 100, 50)

return {
	{
		-- Thức 1: TRIỆU GỌI Binh Khí
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local rad = 25
				local points = 8
				local angleStep = (math.pi * 2) / points
				
				-- Cắm kiếm vây quanh người chơi
				for i = 1, points do
					local angle = angleStep * i
					local pos = TPos + Vector3.new(math.cos(angle)*rad, 0, math.sin(angle)*rad)
					local Sword = AttackUtils:CreateBasePart({ Color = C_Sword, Position = pos + Vector3.new(0, 50, 0), Size = Vector3.new(3, 40, 3), CFrame = CFrame.lookAt(pos + Vector3.new(0, 50, 0), pos), Shape = "Block", Material = Enum.Material.Slate })
					Debris:AddItem(Sword, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Sword, 0.5)
						Tween(Sword, {0.2, "Quad", "Out"}, {Position = pos})
						AttackUtils:RegisterHitDetection(Sword, 0.1, 0.2)
						task.wait(4); Tween(Sword, {0.5}, {Transparency = 1}); task.wait(0.5); Sword:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 2: RÃNH ĐỨT GÃY DẬM ĐẤT
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				local Fissure1 = AttackUtils:CreateBasePart({ Color = C_Earth, Position = BPos, Size = Vector3.new(8, 0.5, 80), CFrame = CFrame.new(BPos) * CFrame.Angles(0, math.rad(45), 0), Shape = "Block" })
				local Fissure2 = AttackUtils:CreateBasePart({ Color = C_Earth, Position = BPos, Size = Vector3.new(8, 0.5, 80), CFrame = CFrame.new(BPos) * CFrame.Angles(0, math.rad(-45), 0), Shape = "Block" })
				Debris:AddItem(Fissure1, 5); Debris:AddItem(Fissure2, 5)

				task.spawn(function()
					AttackUtils:Telegraph(Fissure1, 1.2); AttackUtils:Telegraph(Fissure2, 0)
					AttackUtils:RegisterHitDetection(Fissure1, 0.25, 0.4); AttackUtils:RegisterHitDetection(Fissure2, 0.25, 0.4)
					Tween(Fissure1, {0.2}, {Size = Vector3.new(8, 15, 80), Transparency = 0}); Tween(Fissure2, {0.2}, {Size = Vector3.new(8, 15, 80), Transparency = 0})
					task.wait(0.2); Tween(Fissure1, {0.5}, {Transparency = 1}); Tween(Fissure2, {0.5}, {Transparency = 1}); task.wait(0.5); Fissure1:Destroy(); Fissure2:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 10},
		}
	}
}
