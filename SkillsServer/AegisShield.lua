-- [SERVER]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}
function Keybind:OnActivated(Player, Snapshot) end
function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")

	if not Torso then return end
	WeaponLock:Lock(Player, 0.5)

	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid and Humanoid:FindFirstChild("Statistics") then
		local Def = Humanoid.Statistics:FindFirstChild("Defense")
		if Def then
			Def:SetAttribute("AegisShield", 0.5) -- Buff logic (handled in DamageLib if needed)
		end
	end
	
	task.delay(10, function()
		if Humanoid and Humanoid:FindFirstChild("Statistics") then
			local Def = Humanoid.Statistics:FindFirstChild("Defense")
			if Def then
				Def:SetAttribute("AegisShield", nil)
			end
		end
	end)
end
return Keybind
