--[[
	Combo_AbyssalChains.lua (Tỏa Cốt Xích hẹp góc & Co vòng)
	Mô phỏng một vòng xích hoặc hố sâu Co Dần (Shrinking Ring) ép người chơi
	phải chạy thẳng vào vòng ôm của Boss, và kết liễu bằng một quả nổ tĩnh điện.
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
local C_Abyss = Color3.fromRGB(30, 0, 70)
local C_Spark = Color3.fromRGB(200, 100, 255)

return {
	{
		-- Thức 1: VÒNG TỬ THẦN THU HẸP (Torus Shrinking)
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				-- Bốn tấm vách trượt từ ngoài (50 studs) chạy dồn vào người Boss (10 studs)
				local Offsets = {
					{CFrame.Angles(0, 0, 0), Vector3.new(0, 0, 50)},
					{CFrame.Angles(0, math.pi/2, 0), Vector3.new(50, 0, 0)},
					{CFrame.Angles(0, math.pi, 0), Vector3.new(0, 0, -50)},
					{CFrame.Angles(0, -math.pi/2, 0), Vector3.new(-50, 0, 0)}
				}
				for _, d in pairs(Offsets) do
					local angleCF, trans = d[1], d[2]
					local StartPos = BPos + trans
					local Wall = AttackUtils:CreateBasePart({
						Color = C_Abyss, Position = StartPos, Size = Vector3.new(50, 20, 4), CFrame = CFrame.new(StartPos) * angleCF, Shape = "Block"
					})
					Debris:AddItem(Wall, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Wall, 0.5)
						AttackUtils:RegisterHitDetection(Wall, 0.05, 3) -- Rỉa máu nếu chạm cạnh
						-- Co giật dịch chuyển vách tường vào sát thân Boss mạn sườn
						local EndPos = BPos + (trans / 5) -- Thu vào cách thân 10 studs
						Tween(Wall, {3, "Linear", "In"}, {Position = EndPos, Transparency = 0.4})
						task.wait(3); Tween(Wall, {0.3}, {Transparency = 1}); task.wait(0.3); Wall:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 3.5, Activation = {Type = "Time", Value = 4},
		},
		-- Thức 2: NỔ QUÉT (AoE Nổ Cực Cận)
		-- Ngay khi vòng thu lại buộc người chơi đứng ôm Boss, Boss làm quả Nổ banh 20 studs!
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				local Electro = AttackUtils:CreateBasePart({ Color = C_Spark, Position = BPos, Size = Vector3.new(0.5, 25, 25), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Electro, 4)
				task.spawn(function()
					AttackUtils:Telegraph(Electro, 0.8) -- Rất gấp: Đang chạy vào lại phải lướt ngược ra!
					AttackUtils:RegisterHitDetection(Electro, 0.35, 0.3)
					Tween(Electro, {0.2}, {Transparency = 0, Size = Vector3.new(15, 25, 25)})
					task.wait(0.2); Tween(Electro, {0.4}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)}); task.wait(0.4); Electro:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 15},
		}
	}
}
