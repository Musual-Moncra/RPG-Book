-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Damage = require(ServerStorage.Modules.Libraries.Damage)
local MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)
local WeaponLock = require(ReplicatedStorage.Modules.Shared.WeaponLock)

local Keybind = {}
function Keybind:OnActivated(Player, Snapshot) end
function Keybind:OnLetGo(Player, Snapshot)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	local Tool = Snapshot and Snapshot.Tool

	if not Torso then return end

	-- Get nearest mob to teleport behind after 5s
	task.delay(5, function()
		if not Character or not Character:FindFirstChild("Torso") then return end
		local ClosestMob = nil
		local MaxDist = 150
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local MobTorso = MobInstance:FindFirstChild("Torso")
			if MobTorso then
				local dist = (MobTorso.Position - Character.Torso.Position).Magnitude
				if dist < MaxDist then
					MaxDist = dist
					ClosestMob = MobInstance
				end
			end
		end
		
		if ClosestMob then
			local MobTorso = ClosestMob:FindFirstChild("Torso")
			if MobTorso then
				Character:PivotTo(MobTorso.CFrame * CFrame.new(0, 0, 5))
				
				task.spawn(function()
					RequestStunMob(ClosestMob, 2)
					Damage:DamageMobSkill(Player, MobList[ClosestMob], {
						Damage = 100,
						Tool = Tool,
						SkillScaling = {
							["Dexterity"] = { Type = "Attributes", Additive = 2.0, Cap = 250 },
						},
					})
				end)
			end
		end
	end)
end
return Keybind
