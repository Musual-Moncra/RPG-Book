--[[
	Combo_LaserGrid.lua (Lưới Laze Tử Thần)
	Tạo ra một mạng lưới tia laze ngang dọc chằng chịt khóa mọi hướng chạy.
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

return {
	{
		-- Lưới chéo
		{
			Callback = function(Target, Mob)
				local BPos = Floor((Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")).Position)
				local off = 20
				local Lines = {
					{BPos + Vector3.new(0,0,off), Vector3.new(120,4,4), 0},
					{BPos + Vector3.new(0,0,-off), Vector3.new(120,4,4), 0},
					{BPos + Vector3.new(off,0,0), Vector3.new(4,4,120), 0},
					{BPos + Vector3.new(-off,0,0), Vector3.new(4,4,120), 0}
				}
				for _, d in pairs(Lines) do
					local Beam = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(200, 0, 0), Position = d[1], Size = d[2], Shape = "Block" })
					Debris:AddItem(Beam, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Beam, 1.2)
						AttackUtils:RegisterHitDetection(Beam, 0.2, 0.2)
						Beam.Color = Color3.fromRGB(255, 50, 50); Beam.Material = Enum.Material.Neon
						Tween(Beam, {0.3}, {Transparency = 0, Size = d[2] + Vector3.new(0,10,0)})
						task.wait(0.3); Tween(Beam, {0.4}, {Transparency = 1}); task.wait(0.4); Beam:Destroy()
					end)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 1.5, Activation = {Type = "Time", Value = 12},
		}
	}
}
