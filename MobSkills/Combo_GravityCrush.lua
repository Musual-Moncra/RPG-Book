--[[
	Combo_GravityCrush.lua (Nghiền Nát Trọng Lực)
	Tạo quả cầu đen hút cực mạnh, sau đó nhả ra nổ văng.
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

return {
	{
		{
			Callback = function(Target, Mob)
				local TPos = Floor(Target.Position)
				local Hole = AttackUtils:CreateBasePart({ Color = Color3.fromRGB(15,0,30), Position = TPos, Size = Vector3.new(1,1,1), Shape="Ball" })
				Debris:AddItem(Hole, 5)
				task.spawn(function()
					AttackUtils:Telegraph(Hole, 1)
					-- HÚT
					local Conn = Hole.Touched:Connect(function(Hit)
						local Player = Players:GetPlayerFromCharacter(Hit.Parent)
						local Root = Hit.Parent:FindFirstChild("HumanoidRootPart")
						if Player and Root then
							Root.CFrame = Root.CFrame:Lerp(CFrame.new(Hole.Position), 0.5) -- Kéo giật vào giữa
						end
					end)
					Tween(Hole, {1.5, "Quint", "In"}, {Size = Vector3.new(45,45,45), Transparency=0.4})
					task.wait(1.5)
					Conn:Disconnect()
					-- NỔ
					AttackUtils:RegisterHitDetection(Hole, 0.4, 0.3)
					Hole.Color = Color3.fromRGB(100,0,255)
					Tween(Hole, {0.2}, {Size = Vector3.new(55,55,55), Transparency=0})
					task.wait(0.2); Tween(Hole, {0.3}, {Size = Vector3.new(0,0,0), Transparency=1}); task.wait(0.3); Hole:Destroy()
				end)
			end,
			RequiresTarget = true, StopWhileAttacking = 1, Activation = {Type = "Time", Value = 14},
		}
	}
}
