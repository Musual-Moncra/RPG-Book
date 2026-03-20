--[[
	Combo_TimeStop.lua (Thời Gian Lưng Chừng/Đồng Hồ Cát)
	Tạo ra Lồng thời gian. Bất kể ai rơi vào lồng sẽ dính hiệu ứng làm chậm
	phải lết từng bước cực mệt mỏi trong khi bẫy nổ chực chờ!
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

local C_Time = Color3.fromRGB(0, 200, 255)
local C_Shatter = Color3.fromRGB(0, 50, 150)

return {
	{
		{
			Callback = function(Target, Mob)
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not TargetRoot then return end
				local TPos = Floor(TargetRoot.Position)
				
				-- 1. LỒNG THỜI GIAN (Time Sphere) LÀM CHẬM (SLOW) NGƯỜI CHƠI TRONG 4 GIÂY
				local TimeZone = AttackUtils:CreateBasePart({
					Color = C_Time, Position = TPos, Size = Vector3.new(0.5, 45, 45), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.ForceField
				})
				Debris:AddItem(TimeZone, 7)

				-- Event làm chậm (Custom Touch Event)
				local Conn = TimeZone.Touched:Connect(function(Hit)
					local Player = Players:GetPlayerFromCharacter(Hit.Parent)
					if Player then
						local Hum = Hit.Parent:FindFirstChild("Humanoid")
						if Hum and Hum.WalkSpeed > 6 then
							local oldSpd = Hum.WalkSpeed
							Hum.WalkSpeed = 6 -- Rất Rất Chậm
							task.delay(1.5, function()
								if Hum then Hum.WalkSpeed = oldSpd end
							end)
						end
					end
				end)

				task.spawn(function()
					AttackUtils:Telegraph(TimeZone, 4) -- Vùng xoáy quay chậm 4s
					Conn:Disconnect()

					-- 2. VỤ NỔ PHÁ KÉN THỜI GIAN
					TimeZone.Material = Enum.Material.Neon
					TimeZone.Color = C_Shatter
					AttackUtils:RegisterHitDetection(TimeZone, 0.35, 0.4) -- Nát 35% HP! Xoay mòng mòng lết không ra khỏi lồng là chết.
					Tween(TimeZone, {0.3, "Bounce", "Out"}, {Size = Vector3.new(10, 55, 55), Transparency = 0})
					task.wait(0.3); Tween(TimeZone, {0.5}, {Size = Vector3.new(0.5,0,0), Transparency = 1}); task.wait(0.5); TimeZone:Destroy()
				end)

				-- Bổ sung đạn nổ làm khó trong vùng TimeZone
				task.spawn(function()
					task.wait(1.5)
					local Trap = AttackUtils:CreateBasePart({ Color = C_Shatter, Position = TPos, Size = Vector3.new(0.5, 15, 15), Orientation = Vector3.new(0,90,90), Shape = "Cylinder" })
					AttackUtils:Telegraph(Trap, 1.5)
					AttackUtils:RegisterHitDetection(Trap, 0.2, 0.2)
					Tween(Trap, {0.2}, {Transparency = 1}); task.wait(0.2); Trap:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 12},
		}
	}
}
