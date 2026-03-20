--[[
	Combo_AuraBurst.lua (Bùng Nổ Hào Quang 3 Lớp)
	Boss gầm thét, nổ tung 3 phát lan toả từ trong ra ngoài!
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
				local Boss = Mob.Instance:FindFirstChild("Torso") or Mob.Instance:FindFirstChild("HumanoidRootPart")
				if not Boss then return end
				local BPos = Floor(Boss.Position)
				
				local radii = {25, 50, 80}
				for i, rad in pairs(radii) do
					local Ring = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(255,255,150), Position = BPos, Size = Vector3.new(0.5, rad, rad), Orientation = Vector3.new(0,90,90), Shape="Cylinder" })
					Debris:AddItem(Ring, 5)
					task.spawn(function()
						AttackUtils:Telegraph(Ring, 1)
						AttackUtils:RegisterHitDetection(Ring, 0.2, 0.2)
						Ring.Material = Enum.Material.Neon
						Tween(Ring, {0.3}, {Transparency=0, Size=Vector3.new(20, rad, rad)})
						task.wait(0.3); Tween(Ring, {0.4}, {Transparency=1}); task.wait(0.4); Ring:Destroy()
					end)
					task.wait(0.6) -- Vòng nổ đuổi nhau
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 2, Activation = {Type = "Time", Value = 15},
		}
	}
}
