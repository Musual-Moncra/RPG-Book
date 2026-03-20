--[[
	Skill_HealAura.lua (Lãnh Địa Hồi Phục)
	Boss bật hào quang phòng ngự hút máu kẻ nào dám áp sát vào nó trong 4 giây.
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
				local Part = AttackUtils:CreateBasePart({
					Color = Color3.fromRGB(100, 255, 150), Position = Boss.Position, Size = Vector3.new(22, 22, 22), Shape = "Ball", Material = Enum.Material.ForceField
				})
				Debris:AddItem(Part, 6)
				local Weld = Instance.new("WeldConstraint"); Weld.Part0, Weld.Part1, Weld.Parent = Part, Boss, Part

				task.spawn(function()
					AttackUtils:Telegraph(Part, 1) -- Boss lườm tụ lực mầu xanh
					-- Hút máu!
					AttackUtils:RegisterHitDetection(Part, 0.05, 4)
					-- Hồi phục cực mạnh cho boss
					if Mob.Enemy then
						local Heal = Mob.Enemy.MaxHealth * 0.2
						Mob.Enemy.Health = math.clamp(Mob.Enemy.Health + Heal, 0, Mob.Enemy.MaxHealth)
					end
					Tween(Part, {4}, {Transparency = 0.6})
					task.wait(4)
					Tween(Part, {0.5}, {Size = Vector3.new(35, 35, 35), Transparency = 1})
					task.wait(0.5); Part:Destroy()
				end)
			end,
			RequiresTarget = false, StopWhileAttacking = 1, Activation = {Type = "MaxHealth", Value = 0.5}, -- Xài 1 lần khi lượng máu tụt 50%
		}
	}
}
