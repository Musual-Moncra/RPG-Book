-- [SERVER]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}
function Keybind:OnActivated(Player, Snapshot) end
function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Tool = Snapshot and Snapshot.Tool

	if Tool then
		WeaponLock:Lock(Player, 0.5)

		local Torso = Character and Character:FindFirstChild("Torso")
		if Torso then
			local CollectionService = game:GetService("CollectionService")
			local Damage = require(game:GetService("ServerStorage").Modules.Libraries.Damage)
			local MobList = require(game:GetService("ServerStorage").Modules.Libraries.Mob.MobList)
			
			for i = 1, 10 do
				task.delay(i, function()
					if not Torso then return end
					for _, MobInstance in CollectionService:GetTagged("Mob") do
						local MobTorso = MobInstance:FindFirstChild("Torso")
						if MobTorso and (MobTorso.Position - Torso.Position).Magnitude < 15 then
							task.spawn(function()
								Damage:DamageMobSkill(Player, MobList[MobInstance], {
									Damage = 15,
									Tool = Tool,
									SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 100 } }
								})
							end)
						end
					end
				end)
			end
		end
	end
end
return Keybind
