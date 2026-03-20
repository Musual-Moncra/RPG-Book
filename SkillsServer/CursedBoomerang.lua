-- [SERVER]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Knockback = require(ServerStorage.Modules.Server.Knockback)
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
	WeaponLock:Lock(Player, 2.0)
	local Origin = Torso.Position
	local Forward = Torso.CFrame.LookVector
	
	for i = 1, 10 do
		task.delay(i*0.1, function() -- Outward phase
			local currentPos = Origin + (Forward * (i * 6))
			for _, MobInstance in CollectionService:GetTagged("Mob") do
				local MobTorso = MobInstance:FindFirstChild("Torso")
				if MobTorso and (MobTorso.Position - currentPos).Magnitude < 15 then
					task.spawn(function()
						RequestStunMob(MobInstance, 0.5)
						Damage:DamageMobSkill(Player, MobList[MobInstance], {
							Damage = 15,
							Tool = Tool,
						})
					end)
				end
			end
		end)
	end
	
	task.delay(1.0, function() -- Return phase
		if not Character or not Character:FindFirstChild("Torso") then return end
		local ReturnOrigin = Character.Torso.Position
		local MidPoint = Origin + (Forward * 60)
		local ReturnVec = (ReturnOrigin - MidPoint).Unit
		
		for i = 1, 10 do
			task.delay(i*0.1, function()
				local currentPos = MidPoint + (ReturnVec * (i * 6))
				for _, MobInstance in CollectionService:GetTagged("Mob") do
					local MobTorso = MobInstance:FindFirstChild("Torso")
					if MobTorso and (MobTorso.Position - currentPos).Magnitude < 15 then
						task.spawn(function()
							RequestStunMob(MobInstance, 1.0)
							-- Pull towards player on return
							MobTorso.CFrame = CFrame.new(MobTorso.Position, ReturnOrigin) * CFrame.new(0,0,-5)
							Damage:DamageMobSkill(Player, MobList[MobInstance], {
								Damage = 25,
								Tool = Tool,
							})
						end)
					end
				end
			end)
		end
	end)
end
return Keybind
