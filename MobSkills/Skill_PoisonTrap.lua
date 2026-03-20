--[[
	Skill_PoisonTrap.lua (Nhà Giam Độc Tố)
	Trồi lên 4 bãi lầy độc tạo thành hình vuông bao vây người chơi. Khóa góc chạy trốn.
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
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local offsets = { Vector3.new(12,0,12), Vector3.new(-12,0,12), Vector3.new(12,0,-12), Vector3.new(-12,0,-12) }
				for _, off in pairs(offsets) do
					local Part = AttackUtils:CreateBasePart({
						Color = Color3.fromRGB(100, 200, 50), Position = TPos + off,
						Size = Vector3.new(0.5, 15, 15), Orientation = Vector3.new(0, 90, 90), Shape = "Cylinder", Material = Enum.Material.Mud
					})
					Debris:AddItem(Part, 8)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.8)
						AttackUtils:RegisterHitDetection(Part, 0.04, 5)
						Tween(Part, {0.2}, {Transparency = 0.3})
						task.wait(5)
						Tween(Part, {0.5}, {Transparency = 1}); task.wait(0.5); Part:Destroy()
					end)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 1.2, Activation = {Type = "Time", Value = 14},
		}
	}
}
