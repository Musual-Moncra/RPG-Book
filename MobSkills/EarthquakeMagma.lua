--[[
	EarthquakeMagma.lua
	
	Đã sửa đổi: Xen kẽ skill dồn dập và cảnh báo chậm.
	Tại Thức 2: Quả cầu lửa sẽ mất tận 2.5s để tụ năng lượng (telegraph cực chậm).
	Nhưng Boss sẽ dùng địa chấn dăm gây nhiễu dưới chân người chơi liên tục. 
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local AttackUtils, Floor, Tween
if RunService:IsServer() then
	local ServerStorage = game:GetService("ServerStorage")
	AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
	Floor = AttackUtils.Floor
	Tween = AttackUtils.Tween
end

local ColorMagma = Color3.fromRGB(255, 85, 0)
local ColorCore = Color3.fromRGB(255, 200, 100)
local ColorEarth = Color3.fromRGB(130, 80, 50)

return {
	{
		-- Thức 1: Cột Dung Nham
		{
			Callback = function(NearestTorso, Mob)
				for i = 1, 3 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local TargetPosition = Floor(NearestTorso.Position)
					local Part = AttackUtils:CreateBasePart({ Color = ColorMagma, Position = TargetPosition, Size = Vector3.new(0.5, 18, 18), Orientation = Vector3.new(0, 0, 90), Shape = "Cylinder" })
					Debris:AddItem(Part, 6)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.7)
						Tween(Part, {0.15, "Back", "Out"}, { Size = Vector3.new(80, 18, 18), Position = Part.Position + Vector3.new(0, 40, 0) })
						AttackUtils:RegisterHitDetection(Part, 0.15, 0.3); task.wait(0.3)
						Tween(Part, {0.4}, { Transparency = 1, Size = Vector3.new(0.5, 5, 5), Position = TargetPosition }); task.wait(0.4); Part:Destroy()
					end)
					task.wait(0.3) -- Rút ngắn nhịp độ, rượt đuổi dồn dập hơn
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 15},
		},

		-- Thức 2: BÃO TÁP ÁP LỰC (Quả Bom Dung Nham mix cùng Gai Đất dồn dập)
		{
			Callback = function(NearestTorso, Mob)
				local TargetPosition = Floor(NearestTorso.Position)
				local HoverPosition = TargetPosition + Vector3.new(0, 8, 0) 

				-- 1. Waning siêu to khổng lồ mất TẬN 2.5 GIÂY (Chậm)
				local BigBomb = AttackUtils:CreateBasePart({
					Color = ColorCore, Position = HoverPosition, Size = Vector3.new(4, 4, 4), Shape = "Ball"
				})
				Debris:AddItem(BigBomb, 8)

				task.spawn(function()
					AttackUtils:Telegraph(BigBomb, 2.5) -- Đếm ngược 2.5s
					Tween(BigBomb, {0.2}, {Transparency = 0.2, Size = Vector3.new(45, 45, 45)})
					AttackUtils:RegisterHitDetection(BigBomb, 0.25, 0.3)
					task.wait(0.3)
					Tween(BigBomb, {0.5}, {Transparency = 1, Size = Vector3.new(55, 55, 55)})
					task.wait(0.5); BigBomb:Destroy()
				end)

				-- 2. Tấn công nhiễu dồn dập: Mọc liên tiếp 6 gai đá nhỏ làm rào cản di chuyển
				for i = 1, 6 do
					if not NearestTorso or not NearestTorso.Parent then break end
					local TargetPos = Floor(NearestTorso.Position)
					local Spikes = AttackUtils:CreateBasePart({
						Color = ColorEarth, Position = TargetPos, Size = Vector3.new(0.5, 8, 8), Orientation = Vector3.new(0, 0, 90), Shape = "Cylinder"
					})
					Debris:AddItem(Spikes, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Spikes, 0.35) -- Giật rất nhanh 0.35s
						Tween(Spikes, {0.1}, {Size = Vector3.new(15, 8, 8), Position = Spikes.Position + Vector3.new(0, 7.5, 0)})
						AttackUtils:RegisterHitDetection(Spikes, 0.05, 0.2)
						task.wait(0.2)
						Tween(Spikes, {0.3}, {Transparency = 1, Position = TargetPos})
						task.wait(0.3); Spikes:Destroy()
					end)
					task.wait(0.4) 
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 2.5},
		},

		-- Thức 3: Earth-Splitter
		{
			Callback = function(NearestTorso, Mob)
				local MobInstance = Mob.Instance
				local MobTorso = MobInstance:FindFirstChild("Torso") or MobInstance:FindFirstChild("HumanoidRootPart")
				if not MobTorso or not NearestTorso then return end
				
				local TargetPos = Floor(NearestTorso.Position)
				local BossPos = Floor(MobTorso.Position)
				local CFrameDirection = CFrame.lookAt(BossPos, Vector3.new(TargetPos.X, BossPos.Y, TargetPos.Z))
				local CenterPos = (CFrameDirection * CFrame.new(0, -5, -50)).Position
				
				local Part = AttackUtils:CreateBasePart({
					Color = ColorEarth, Position = CenterPos, Size = Vector3.new(12, 1, 100), CFrame = CFrame.lookAt(CenterPos, Vector3.new(TargetPos.X, CenterPos.Y, TargetPos.Z)), Shape = "Block",
				})
				Debris:AddItem(Part, 8)
				AttackUtils:Telegraph(Part, 1.5)
				Tween(Part, {0.15, "Bounce", "Out"}, { Size = Vector3.new(12, 30, 100), Position = Part.Position + Vector3.new(0, 15, 0) })
				AttackUtils:RegisterHitDetection(Part, 0.3, 0.4); task.wait(0.4)
				Tween(Part, {1.5}, { Transparency = 1, Size = Vector3.new(12, 1, 100), Position = CenterPos }); task.wait(1.5); Part:Destroy()
			end,
			RequiresTarget = true, StopWhileAttacking = 3, Activation = {Type = "Time", Value = 2.5},
		}
	}
}
