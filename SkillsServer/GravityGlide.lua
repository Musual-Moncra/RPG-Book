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
	if not Torso then return end
    WeaponLock:Lock(Player, 5)

	local AntiGravity = Instance.new("BodyForce")
	AntiGravity.Force = Vector3.new(0, workspace.Gravity * Character.PrimaryPart.AssemblyMass * 0.9, 0)
	AntiGravity.Parent = Torso
	local Debris = game:GetService("Debris")
	Debris:AddItem(AntiGravity, 5)
	
	local BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(0, 100000, 0)
	BV.Velocity = Vector3.new(0, 20, 0)
	BV.Parent = Torso
	Debris:AddItem(BV, 1)

	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid then
		local OldSpeed = Humanoid.WalkSpeed
		Humanoid.WalkSpeed = OldSpeed + 25
		task.delay(5, function()
			if Humanoid then Humanoid.WalkSpeed = OldSpeed end
		end)
	end
end
return Keybind
