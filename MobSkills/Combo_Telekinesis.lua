--[[
	Combo_Telekinesis.lua (Siêu Siêu Năng Lực / Thao Túng Không Gian)
	Combo dị dạng thao túng vật lý: Bay theo người chơi, dịch chuyển bắt cóc, và treo lơ lửng kẻ địch.
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

local C_Psycho = Color3.fromRGB(200, 0, 255)
local C_Danger = Color3.fromRGB(255, 0, 50)

return {
	{
		-- THỨC 1: ORB RƯỢT ĐUỔI (Missile Tracking)
		-- Cầu ma thuật liên tục bay rượt theo vị trí người chơi trong 6 giây.
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Orb = AttackUtils:CreateBasePart({
					Color = C_Psycho, Position = Mob.Instance:GetPivot().Position + Vector3.new(0, 15, 0), Size = Vector3.new(6, 6, 6), Shape = "Ball", Material = Enum.Material.ForceField
				})
				Debris:AddItem(Orb, 8)

				AttackUtils:Telegraph(Orb, 1) -- Gồng 1 giây
				
				-- Bắt đầu rượt đuổi bằng Loop + Tween
				local tracking = true
				task.spawn(function()
					while tracking and Orb and Orb.Parent do
						if Target and Target.Parent then
							local Dest = Target.Position + Vector3.new(0, 3, 0)
							-- Di chuyển bám đuổi với tốc độ Tween 0.3s liên tục
							Tween(Orb, {0.3}, {CFrame = CFrame.lookAt(Orb.Position, Dest) * CFrame.new(0,0,-8)})
						end
						task.wait(0.3)
					end
				end)

				-- Nhịp Damage DoT trong lúc bay
				AttackUtils:RegisterHitDetection(Orb, 0.05, 6)

				task.spawn(function()
					task.wait(6)
					tracking = false
					Orb.Material = Enum.Material.Neon
					Orb.Color = C_Danger
					-- Nổ tung khi hết nhịp
					Tween(Orb, {0.2}, {Size = Vector3.new(35, 35, 35), Transparency = 0})
					AttackUtils:RegisterHitDetection(Orb, 0.25, 0.3)
					task.wait(0.2); Tween(Orb, {0.4}, {Size = Vector3.new(1,1,1), Transparency = 1}); task.wait(0.4); Orb:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 1},
		},

		-- THỨC 2: BẮT CÓC / LỖ ĐEN DỊCH CHUYỂN
		-- Ép Dịch chuyển người chơi thẳng mặt Boss và dậm tàn bạo.
		{
			Callback = function(Target, Mob)
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not Boss or not TargetRoot then return end
				
				local TrapColor = Color3.fromRGB(0, 0, 0)
				
				-- Dịch chuyển người chơi tới sát gốc Boss (Khoảng cách 8 studs trước mặt)
				local FrontBossCF = Boss.CFrame * CFrame.new(0, 0, -8)
				TargetRoot.CFrame = FrontBossCF

				-- Đồng thời Boss tung ngay một cú đập đất dồn dập
				local FloorPos = Floor(FrontBossCF.Position)
				local Smash = AttackUtils:CreateBasePart({ Color = C_Danger, Position = FloorPos, Size = Vector3.new(0.5, 25, 25), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder" })
				Debris:AddItem(Smash, 4)

				task.spawn(function()
					-- Telegraph CHỈ 0.6 GIÂY! Người chơi vừa bị dịch chuyển phải lập tức bấm Dash để né!
					AttackUtils:Telegraph(Smash, 0.6)
					AttackUtils:RegisterHitDetection(Smash, 0.3, 0.2) -- Trúng là bay 30% máu
					
					Smash.Color = C_Psycho
					Tween(Smash, {0.2}, {Transparency = 0, Size = Vector3.new(35, 35, 35)})
					task.wait(0.2); Tween(Smash, {0.3}, {Transparency = 1, Size = Vector3.new(0.5, 0, 0)}); task.wait(0.3); Smash:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1.0, Activation = {Type = "Time", Value = 8},
		},

		-- THỨC 3: TRỌNG LỰC ĐẢO NGƯỢC (Treo lơ lửng)
		-- Bốc mục tiêu bay bổng lên trời cao 50 studs, làm mồi cho tia laze
		{
			Callback = function(Target, Mob)
				local TargetRoot = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
				if not TargetRoot then return end
				
				local TPos = TargetRoot.Position
				
				-- Nhấc bổng lên trời 50 studs
				TargetRoot.CFrame = TargetRoot.CFrame + Vector3.new(0, 50, 0)
				TargetRoot.Anchored = true -- Khóa cứng người chơi trên không

				local MidAirPos = TargetRoot.Position
				local Warning = AttackUtils:CreateBasePart({ Color = C_Psycho, Position = MidAirPos, Size = Vector3.new(8, 8, 8), Shape = "Ball" })
				Debris:AddItem(Warning, 6)

				task.spawn(function()
					AttackUtils:Telegraph(Warning, 1.5)
					
					-- Mở khoá để rớt xuống
					if TargetRoot and TargetRoot.Parent then
						TargetRoot.Anchored = false 
					end

					-- Nổ trên không
					AttackUtils:RegisterHitDetection(Warning, 0.2, 0.2) 
					Warning.Color = C_Danger
					Tween(Warning, {0.2}, {Transparency = 0, Size = Vector3.new(65, 65, 65)})
					task.wait(0.2); Tween(Warning, {0.4}, {Transparency = 1}); task.wait(0.4); Warning:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 2.5},
		}
	}
}
