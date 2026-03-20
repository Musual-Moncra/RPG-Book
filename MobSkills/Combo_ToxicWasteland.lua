--[[
	Combo_ToxicWasteland.lua
	Chuỗi Vùng Đất Chết Thảm (Độc Tố - 4 Thức)
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
local C_Poison = Color3.fromRGB(80, 200, 50)
local C_Acid = Color3.fromRGB(150, 255, 50)

return {
	{
		-- THỨC 1: XỊT AXIT (Phun bãi độc nhỏ)
		{
			Callback = function(Target, Mob)
				for i = 1, 3 do
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					local Puddle = AttackUtils:CreateBasePart({ Color = C_Poison, Position = TPos, Size = Vector3.new(0.5, 12, 12), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.Mud })
					Debris:AddItem(Puddle, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Puddle, 0.5)
						AttackUtils:RegisterHitDetection(Puddle, 0.05, 4) -- Sát thương rỉa tồn tại lâu
						Tween(Puddle, {0.2}, {Transparency = 0.5})
						task.wait(4); Tween(Puddle, {0.5}, {Transparency = 1}); task.wait(0.5); Puddle:Destroy()
					end)
					task.wait(0.3)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 1.2},
		},
		-- THỨC 2: QUÉT NỌC ĐỘC (Laser chéo chữ V quét qua mặt)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss or not Target then return end
				local BPos = Floor(Boss.Position)
				local TPos = Floor(Target.Position)
				
				local CF = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z))
				local B1 = AttackUtils:CreateBasePart({ Color = C_Acid, Position = BPos, Size = Vector3.new(8, 4, 60), CFrame = CF * CFrame.Angles(0, math.rad(25), 0) * CFrame.new(0,0,-30), Shape = "Block" })
				local B2 = AttackUtils:CreateBasePart({ Color = C_Acid, Position = BPos, Size = Vector3.new(8, 4, 60), CFrame = CF * CFrame.Angles(0, math.rad(-25), 0) * CFrame.new(0,0,-30), Shape = "Block" })
				Debris:AddItem(B1, 5); Debris:AddItem(B2, 5)
				
				task.spawn(function()
					AttackUtils:Telegraph(B1, 1); AttackUtils:RegisterHitDetection(B1, 0.15, 0.3)
					Tween(B1, {0.3}, {Transparency = 1}); task.wait(0.3); B1:Destroy()
				end)
				task.spawn(function()
					AttackUtils:Telegraph(B2, 1); AttackUtils:RegisterHitDetection(B2, 0.15, 0.3)
					Tween(B2, {0.3}, {Transparency = 1}); task.wait(0.3); B2:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1.5},
		},
		-- THỨC 3: QUÁI THAI SÌNH LẦY (Ball to rơi xuống)
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Ball = AttackUtils:CreateBasePart({ Color = C_Poison, Position = TPos + Vector3.new(0, 40, 0), Size = Vector3.new(30,30,30), Shape = "Ball", Material = Enum.Material.Mud })
				local Shadow = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(0,0,0), Position = TPos, Size = Vector3.new(0.5, 30, 30), Orientation = Vector3.new(0,90,90), Shape = "Cylinder" })
				Debris:AddItem(Ball, 5); Debris:AddItem(Shadow, 5)
				
				task.spawn(function()
					AttackUtils:Telegraph(Shadow, 1.5)
					Tween(Ball, {0.3, "Bounce", "Out"}, {Position = TPos + Vector3.new(0, 15, 0)})
					task.wait(0.3)
					AttackUtils:RegisterHitDetection(Ball, 0.3, 0.4)
					Tween(Ball, {0.2}, {Size = Vector3.new(45, 45, 45), Transparency = 1})
					Tween(Shadow, {0.2}, {Transparency = 1})
					task.wait(0.2); Ball:Destroy(); Shadow:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2, Activation = {Type = "Time", Value = 2.5},
		},
		-- THỨC 4: HÀO QUANG DỊCH BỆNH (Boss hóa mây độc rượt người chơi)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local Aura = AttackUtils:CreateBasePart({ Color = C_Acid, Position = Boss.Position, Size = Vector3.new(40, 40, 40), Shape = "Ball", Material = Enum.Material.ForceField })
				local Weld = Instance.new("WeldConstraint"); Weld.Part0, Weld.Part1, Weld.Parent = Aura, Boss, Aura
				Debris:AddItem(Aura, 8)
				
				task.spawn(function()
					AttackUtils:Telegraph(Aura, 1) -- Gồng 1 giây
					AttackUtils:RegisterHitDetection(Aura, 0.1, 5) -- Nếu người chơi để Boss ôm sát sẽ ăn dmg DoT liên tục!
					Tween(Aura, {0.2}, {Transparency = 0.6})
					task.wait(5)
					Tween(Aura, {0.5}, {Transparency = 1, Size = Vector3.new(60,60,60)}); task.wait(0.5); Aura:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = nil, Activation = {Type = "Time", Value = 14}, -- Càng di chuyển càng ép góc người chơi!
		}
	}
}
