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
	if Humanoid then
		-- Sacrifice 10% health
		local Sacrifice = Humanoid.MaxHealth * 0.1
		Humanoid.Health = math.max(1, Humanoid.Health - Sacrifice)
		
		-- Buff walkspeed
		local OldSpeed = Humanoid.WalkSpeed
		Humanoid.WalkSpeed = OldSpeed + 15
		
		task.delay(8, function()
			if Humanoid then
				Humanoid.WalkSpeed = OldSpeed
			end
		end)
	end
end
return Keybind
