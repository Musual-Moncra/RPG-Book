-- [SERVER]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}
function Keybind:OnActivated(Player, Snapshot) end
function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")

	if not Torso then return end
	WeaponLock:Lock(Player, 0.5)

	local Humanoid = Character:FindFirstChild("Humanoid")
	
	task.spawn(function()
		for tick = 1, 15 do
			task.wait(1)
			if Humanoid and Humanoid.Health > 0 and Humanoid.Health < Humanoid.MaxHealth then
				local Heal = Humanoid.MaxHealth * 0.05
				Humanoid.Health = math.clamp(Humanoid.Health + Heal, 0, Humanoid.MaxHealth)
			end
		end
	end)
end
return Keybind
