--[[
	Combo_PoisonNova.lua (Độc Giáp Nổ)
	Xả 8 hướng suối độc tủa ra ngoài.
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
				for i=1, 8 do
					local ang = (math.pi*2/8)*i
					local Stream = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(50,200,0), Position = BPos, Size = Vector3.new(8, 4, 60), CFrame = CFrame.new(BPos)*CFrame.Angles(0,ang,0)*CFrame.new(0,0,-30), Shape="Block" })
					Debris:AddItem(Stream, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Stream, 0.8)
						AttackUtils:RegisterHitDetection(Stream, 0.2, 0.2)
						Tween(Stream, {0.2}, {Transparency=0}); task.wait(0.2)
						Tween(Stream, {0.4}, {Transparency=1}); task.wait(0.4); Stream:Destroy()
					end)
				end
			end,
			RequiresTarget = false, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 10},
		}
	}
}
