--[[
	Skill_IceCombo.lua (Ngục Băng Liên Hoàn)
	Bắn 3 vệt băng lạnh buốt khóa vị trí người chơi liên tiếp.
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
				for i = 1, 3 do
					if not Target or not Target.Parent then break end
					local TPos = Floor(Target.Position)
					local BPos = Floor(Mob.Instance:GetPivot().Position)
					local CF = CFrame.lookAt(BPos, Vector3.new(TPos.X, BPos.Y, TPos.Z))
					local Center = (CF * CFrame.new(0,0,-20)).Position
					local Part = AttackUtils:CreateBasePart({
						Color = Color3.fromRGB(150, 200, 255), Position = Center,
						Size = Vector3.new(4, 4, 40), CFrame = CFrame.lookAt(Center, Vector3.new(TPos.X, Center.Y, TPos.Z)), Shape = "Block", Material = Enum.Material.Ice
					})
					Debris:AddItem(Part, 4)
					task.spawn(function()
						AttackUtils:Telegraph(Part, 0.6)
						AttackUtils:RegisterHitDetection(Part, 0.1, 0.2)
						Tween(Part, {0.2}, {Transparency = 0, Size = Part.Size + Vector3.new(2,2,0)})
						task.wait(0.2); Tween(Part, {0.3}, {Transparency = 1}); task.wait(0.3); Part:Destroy()
					end)
					task.wait(0.8)
				end
			end,
			RequiresTarget = true, StopWhileAttacking = 2.5, Activation = {Type = "Time", Value = 10},
		}
	}
}
