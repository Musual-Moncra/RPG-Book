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
	WeaponLock:Lock(Player, 1.0)
	local Origin = Torso.Position
	
	task.spawn(function()
		local hitCount = 0
		local MaxHits = 6
		local ignored = {}
		
		local function getNextTarget(pos)
			local closest = nil
			local minDist = 50
			for _, m in CollectionService:GetTagged("Mob") do
				if not ignored[m] then
					local mTorso = m:FindFirstChild("Torso")
					if mTorso then
						local dist = (mTorso.Position - pos).Magnitude
						if dist < minDist then
							minDist = dist
							closest = m
						end
					end
				end
			end
			return closest
		end
		
		local CurrentPos = Origin
		
		for i = 1, MaxHits do
			task.wait(0.2)
			local nxt = getNextTarget(CurrentPos)
			if nxt then
				ignored[nxt] = true
				CurrentPos = nxt:GetPivot().Position
				
				RequestStunMob(nxt, 0.5)
				Knockback:Activate(nxt:FindFirstChild("Torso"), 5, CurrentPos - Vector3.new(0,5,0), CurrentPos)
				Damage:DamageMobSkill(Player, MobList[nxt], {
					Damage = math.max(10, 40 - (hitCount * 5)),
					Tool = Tool,
					SkillScaling = { ["Dexterity"] = { Type = "Attributes", Additive = 0.5, Cap = 150 } },
				})
				hitCount = hitCount + 1
			else
				break
			end
		end
	end)
end
return Keybind
