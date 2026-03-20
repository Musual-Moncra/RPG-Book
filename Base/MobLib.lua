--[[
	ej0w @ October 2024
	Mob
	
	All serverside code for mobs get ran through here; in most cases, this won't need to be modified
	Due to how customizable AttackConfig & MobConfig are, but you're able to dive through here if needed
	*Originally written by Evercyan, since has been entirely recoded & expanded upon
]]

--> Services
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

local Alternatives = ServerStorage.Assets.Entities.Alternatives

local function ClearMobInstance(MobInstance)
	for _, Script in MobInstance:GetChildren() do
		if Script:IsA("Script") or Script:IsA("ModuleScript") then
			Script:Destroy()
		end
	end
	CollectionService:RemoveTag(MobInstance, "Mob")
end

for _, MobInstance in Alternatives:GetChildren() do
	task.spawn(ClearMobInstance, MobInstance)
end
Alternatives.ChildAdded:Connect(ClearMobInstance)

local Doors = workspace.Map.Doors

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local GetPlayerLuck = require(ReplicatedStorage.Modules.Shared.getPlayerLuck)
local GetStatMultiplier = require(ReplicatedStorage.Modules.Shared.getStatMultiplier)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local ActivateRagdoll = require(ServerStorage.Modules.Server.activateRagdoll)
local AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
local GiftDrops = require(ServerStorage.Modules.Server.giftDrops)

local HitCycleFunctions = require(ReplicatedStorage.Modules.Entity.hitCycleFunctions)
local AttackFunctions = require(ReplicatedStorage.Modules.Entity.attackFunctions)

local Morph = require(ServerStorage.Modules.Server.Morph)
local DamageLib = require(ServerStorage.Modules.Libraries.Damage)

local AIMob = require(script.AIMob)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local Mobs = require(script.MobList) -- Dictionary which stores a reference to every Mob

local DamageCooldown = {}
local Random = Random.new()

local FindNearestTorso = AttackUtils.FindNearestTorso

--------------------------------------------------------------------------------

local MobLib = {} -- Mirror table with the Mob constructor function

local Mob = {} -- Syntax sugar for mob-related functions
Mob.__index = Mob

local MobsFolder = workspace:FindFirstChild("Mobs")
if not MobsFolder then
	MobsFolder = Instance.new("Folder")
	MobsFolder.Name = "Mobs"
	MobsFolder.Parent = workspace
end

function MobLib.new(MobInstance: Model): Mobs.Mob
	local HumanoidRootPart = MobInstance:FindFirstChild("HumanoidRootPart") :: BasePart
	
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	local MobConfig = MobInstance:FindFirstChild("MobConfig") and require(MobInstance:FindFirstChild("MobConfig"))
	
	if not HumanoidRootPart or not Enemy or not MobConfig then
		error(("MobLib.new: Passed mob '%s' is missing vital components."):format(MobInstance.Name))
	end
	
	local AttributeFolder = MobInstance:FindFirstChild("HeldAttributes") 
		or AttributeModule:CreateAttributeFolder(MobInstance)

	if AttributeModule:GetAttribute(MobInstance, "Loaded") then
		return 
	end
	
	local Mob = setmetatable({}, Mob)
	Mob.Instance = MobInstance
	Mob.Config = MobConfig
	Mob.Name = MobConfig.Name
	Mob.Ranged = (MobConfig.Projectile and true) or false
	Mob.Cooldown = os.clock()
	Mob.Root = HumanoidRootPart
	Mob.Enemy = Enemy
	Mob.Hitbox = MobInstance:FindFirstChild("Hitbox")
	Mob.Origin = HumanoidRootPart:GetPivot()
	
	Mob.isActive = false
	Mob.isWandering = false
	Mob.isGoingBack = false
	Mob.PathfindId = nil
	
	Mob.Attributes = AttributeFolder
	
	-- AI config
	local AIData = Mob.Config.AIData

	Mob.FollowDistance = AIData and AIData.FollowDistance or 32
	Mob.WanderRadius = AIData and AIData.WanderRadius or 10
	
	Mob.aiType = AIData and AIData.Type
	Mob.canWander = AIData and AIData.CanWander
	Mob.lookTarget = AIData and AIData.LookAtTarget
	
	Mob.isDumb = AIData and AIData.Intelligence == "Dumb"
	Mob.tendencyType = AIData and AIData.Tendency or "Brave"
	Mob.rangeRadius = AIData and AIData.Range or math.huge
	Mob.runPercentage = AIData and AIData.Percentage or 0.25
	Mob.keepDistance = AIData and AIData.KeepDistance or {13, 16}
	
	local Agent = AIMob:ConstructPathfindingAgent(Mob)
	Mob.Path = Agent and PathfindingService:CreatePath(Agent)
	Mob.Agent = Agent
	
	Mob.Threads = {}
	Mob.Signals = {}
	
	Mob:SetupHitboxesAndScripts()
	
	Mob.CanRegenerate = MobConfig.RegenerateData and MobConfig.RegenerateData.Duration and MobConfig.RegenerateData.Step and MobConfig.RegenerateData.Percentage
	
	---- Load in pre-clone stuff
	
	local function SetRandomPivot(Pivot)
		Pivot = Pivot or MobInstance:GetPivot()

		local Position = Pivot.Position + Vector3.new(Random:NextNumber(-MobConfig.RespawnRadius, MobConfig.RespawnRadius), 0, Random:NextNumber(-MobConfig.RespawnRadius, MobConfig.RespawnRadius))
		local NewPivot = nil

		local NewPosition, Raycast = AttackUtils.Floor(Position)
		if NewPosition and math.abs(Position.Y - NewPosition.Y) < 5 then
			local LowerPosition = Mob.Hitbox.Position - (Vector3.yAxis * (Mob.Hitbox.Size.Y / 2))
			local Offset = Vector3.yAxis * (Pivot.Position.Y - LowerPosition.Y)

			NewPivot = CFrame.new(NewPosition + Offset) * Pivot.Rotation
			MobInstance:PivotTo(NewPivot)
		end

		return NewPivot
	end
	
	-- Randomize models (they share the same scripts as the parent model)
	if MobConfig.RandomizeAppearance then
		Mob:RandomizeAppearance()
	end
	
	local InitiallyLoaded = AttributeModule:GetAttribute(MobInstance, "InitiallyLoaded")
	if not InitiallyLoaded then
		if MobConfig.RespawnRadius and MobConfig.RespawnRadius > 0 then
			local NewPivot = SetRandomPivot()
			if NewPivot then
				if Mob._Copy then
					AttributeModule:SetAttribute(Mob._Copy, "OriginPivot", NewPivot)
				end
				
				AttributeModule:SetAttribute(MobInstance, "OriginPivot", NewPivot)
			end
		end
		
		if Mob._Copy then
			AttributeModule:SetAttribute(Mob._Copy, "InitiallyLoaded", true)
		end
		
		AttributeModule:SetAttribute(MobInstance, "InitiallyLoaded", true)
	end
	
	Mob._Copy = Mob._Copy or MobInstance:Clone()
	
	---- Initialize
	
	AttributeModule:SetAttribute(MobInstance, "Loaded", true)
	
	-- Set pivot of ore if respawned
	if InitiallyLoaded then
		local OriginPivot = AttributeModule:GetAttribute(MobInstance, "OriginPivot")
		if not MobConfig.KeepPosition and MobConfig.RespawnRadius and MobConfig.RespawnRadius > 0 then
			SetRandomPivot(OriginPivot)
		elseif OriginPivot then
			MobInstance:PivotTo(OriginPivot)
		end
		
		Mob.OriginPivot = OriginPivot or MobInstance:GetPivot()
	end
	
	-- Set collision group to mob (done here because _copy can be cloned before setting stuff up)
	for _, Part in MobInstance:GetDescendants() do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = "Mobs"
		end
	end
	
	Enemy.MaxHealth = MobConfig.Health
	Enemy.Health = MobConfig.Health
	Enemy.JumpPower = MobConfig.JumpPower
	HumanoidRootPart.Anchored = true
	MobInstance.Parent = MobsFolder
	
	-- We're doing these here because it's after cloning, these won't clone every time the mob respawns
	if MobConfig.Armor then
		Morph:ApplyOutfit(MobInstance, ContentLibrary.Armor[MobConfig.Armor])
	end
	
	-- Set humanoid states (helps prevent falling down & useless calculations - you're unlikely to have an enemy climbing without pathfinding)
	for _, EnumName in {"FallingDown", "Seated", "Flying", "Swimming", "Climbing"} do
		local HumanoidStateType = Enum.HumanoidStateType[EnumName]
		Enemy:SetStateEnabled(HumanoidStateType, false)
		
		if Enemy:GetState() == HumanoidStateType then
			Enemy:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	
	-- Walkspeed config (for freezing & stun)
	local WalkSpeed = Instance.new("Configuration")
	WalkSpeed.Parent = Enemy
	WalkSpeed.Name = "WalkSpeed"
	
	local function AttributeChanged()
		local TotalWalkSpeed = 0
		for Name, Value in WalkSpeed:GetAttributes() do
			TotalWalkSpeed += Value
		end
		
		Enemy.WalkSpeed = math.clamp(TotalWalkSpeed, 0, 100)
	end
	
	WalkSpeed.AttributeChanged:Connect(AttributeChanged)
	AttributeChanged()
	
	WalkSpeed:SetAttribute("Default", MobConfig.WalkSpeed)
	
	function Mob:SetWalkSpeed(Name, Value)
		return WalkSpeed:SetAttribute(Name, Value)
	end
	
	function Mob:RequestJump()
		local TotalWalkSpeed = 0
		for Name, Value in WalkSpeed:GetAttributes() do
			TotalWalkSpeed += Value
		end
		
		if TotalWalkSpeed <= 0 then
			return
		end
		
		Enemy.Jump = true
	end
	
	-- Respawn delay (freeze mob)
	local RespawnDelay = (Mob.Config.RespawnDelay and Mob.Config.RespawnDelay[1]) or 0
	if RespawnDelay > 0 then
		task.delay(RespawnDelay, function()
			Mob:SetWalkSpeed("Respawning", nil)
		end)

		Mob:SetWalkSpeed("Respawning", -9999)
	end
	
	---- Connections
	
	local PreviousHealth = Enemy.Health
	
	local function OnTouchedHitbox(BasePart)
		if BasePart:IsDescendantOf(Doors) then
			HumanoidRootPart:PivotTo(Mob.Origin)
		end
	end
	
	local function OnDied()
		if Mob.isDead then
			return
		end
		
		Mob.isDead = true
		
		if MobInstance.Parent ~= nil and MobConfig.DeathSound then
			SFX:Play3D(MobConfig.DeathSound, MobInstance:GetPivot().Position)
		end
		
		Mob:AwardDrops()
		AttributeModule:SetAttribute(MobInstance, "Dead", true)
		
		ActivateRagdoll(MobInstance)
		
		task.delay(MobConfig.RespawnTime or 5, function()
			if Mob.Respawn then
				Mob:Respawn()
			end
		end)
		
		Mob:RequestCallback("OnDied")
	end
	
	local function OnMoveToFinished()
		local DontAnchor = AttributeModule:GetAttribute(MobInstance, "DontAnchor")

		local CanAnchor = (typeof(DontAnchor) == "boolean" and false) 
			or (typeof(DontAnchor) == "number" and os.clock() - DontAnchor < 2) 
			or true

		if not Mob.AIMob:GetClosestPlayer() and not Mob.isDead and not AttributeModule:GetAttribute(MobInstance, "DontAnchor") then
			HumanoidRootPart.Anchored = true
		end
	end
	
	local LastHealthChanged = os.clock()
	
	local function OnHealthChanged()
		if PreviousHealth > Enemy.Health then
			local Clock = os.clock()
			LastHealthChanged = Clock
			
			-- Regeneration system
			if Mob.CanRegenerate then
				task.delay(MobConfig.RegenerateData.Duration, function()
					if Enemy.Health <= 0 or Clock ~= LastHealthChanged then
						return
					end
					
					while Clock == LastHealthChanged and Enemy.Health ~= Enemy.MaxHealth and Enemy.Health > 0 do
						local AddedHealth = MobConfig.RegenerateData.Amount 
							or math.max(math.round(MobConfig.RegenerateData.Percentage * Enemy.MaxHealth), 1)
						
						Enemy.Health += AddedHealth
						task.wait(MobConfig.RegenerateData.Step)
					end
				end)
			end
			
			Mob.AIMob:StartTracking(GameConfig.DefaultDistanceRadius)
		end

		PreviousHealth = Enemy.Health
	end
	
	if Mob.Hitbox then
		Mob.Hitbox.Touched:Connect(OnTouchedHitbox)
	end
	
	AttributeModule:GetAttributeChanged(MobInstance, "NoRespawn"):Connect(function()
		Mob.NoRespawn = AttributeModule:GetAttribute(MobInstance, "NoRespawn")
	end)
	
	AttributeModule:SetAttribute(MobInstance, "NoKnockback", Mob.Config.NoKnockback)
	AttributeModule:SetAttribute(MobInstance, "NoStun", Mob.Config.NoStun)
	
	Enemy.Died:Once(OnDied)
	
	Enemy.MoveToFinished:Connect(OnMoveToFinished)
	Enemy.HealthChanged:Connect(OnHealthChanged)
	
	if MobConfig.InstantRefreshData and MobConfig.InstantRefreshData.CanRefresh then
		Mob:CheckRegenerateTag()
	end
	
	if MobConfig.AttackCycle then
		Mob:CommitAttackSystem()
	end
	
	if MobConfig.HitCycle then
		Mob:CommitHitCycle()
	end
	
	Mobs[MobInstance] = Mob
	
	Mob.AIMob = AIMob.new(Mob)
	Mob:RequestCallback("OnSpawned")
	return Mob
end

function Mob:RequestCallback(CallbackType, Parameters)
	local MobInstance = self.Instance
	local Name = self.Config.Name
	
	EventModule:Fire("ServerToServerMobCallback", MobInstance, Name, CallbackType, Parameters)
	EventModule:FireAllClients("ServerToClientMobCallback", MobInstance, Name, CallbackType, Parameters)
end

function Mob:Respawn()
	if not self.Destroyed then
		local NewMob = self._Copy

		self:Destroy()
		
		if not self.NoRespawn then
			NewMob.Parent = MobsFolder
		else
			NewMob:Destroy()
		end
	end
end

function Mob:TakeDamage(Damage: number)
	local Enemy = self.Enemy
	if not self.isDead then
		Enemy.Health = math.clamp(Enemy.Health - Damage, 0, Enemy.MaxHealth)
	end
end

function Mob:Destroy()
	if not self.Destroyed then
		self.Destroyed = true
		self.AIMob:Destroy()
		
		for _, Thread in self.Threads do
			task.cancel(Thread)
			Thread = nil
		end
		
		for _, Signal in self.Signals do
			Signal:Destroy()
			Signal = nil
		end
		
		if self.HitboxConnections then
			for _, Connection in self.HitboxConnections do
				Connection:Disconnect()
				Connection = nil
			end
		end
		
		if self.AttackConnection then
			self.AttackConnection:Disconnect()
			self.AttackConnection = nil
		end

		Mobs[self.Instance] = nil

		self.Instance:Destroy()
		
		-- Remove instance references
		self.Instance = nil
		self.Root = nil
		self.Enemy = nil
		self._Copy = nil
	end
end

-- genuinely hate how thislooks!
function Mob:SetupHitboxesAndScripts()
	local RequestedDefaultLimbs = {"Right Arm", "Left Arm"}
	
	local MobInstance = self.Instance :: Model
	local MobConfig = self.Config
	
	local Tool = MobInstance:FindFirstChildWhichIsA("Tool")
	
	self.Scripts = {}
	self.HitboxObjects = {}
	
	---- Check intially for config hitboxes
	
	local function RequestCheckObject(Object)
		local IsBasePart = Object:IsA("BasePart")
		
		if Object:IsA("BaseScript") or Object:IsA("ModuleScript") then
			table.insert(self.Scripts, Object)
			
		elseif 
			not self.Ranged 
			and MobConfig.HitboxObjects 
			and ((IsBasePart or Object:IsA("Model")) and string.find(MobConfig.HitboxObjects, Object.Name)) 
		then
			if IsBasePart then
				table.insert(self.HitboxObjects, Object)
			elseif not IsBasePart then
				for _, NewObject in Object:GetDescendants() do
					if not NewObject:IsA("BasePart") then
						continue
					end

					table.insert(self.HitboxObjects, NewObject)
				end
			end
		end
	end
	
	for _, Object in MobInstance:GetChildren() do
		RequestCheckObject(Object)
	end
	
	---- Check for default config
	
	local function PrioritizeArms()
		for _, Limb in RequestedDefaultLimbs do
			local NewLimb = self.Instance:FindFirstChild(Limb)
			if NewLimb then
				table.insert(self.HitboxObjects, NewLimb)
			end
		end
	end
	
	local function PrioritizeTool()
		for _, Object in Tool:GetDescendants() do
			if Object:IsA("BasePart") then
				table.insert(self.HitboxObjects, Object)
			end
		end
	end
	
	if not self.Ranged and #self.HitboxObjects == 0 then
		if Tool then
			PrioritizeTool()
		elseif not Tool then
			PrioritizeArms()
		end
	end
end

function Mob:RandomizeAppearance()
	local MobModels = self.Config.RandomizeAppearance
	
	if self.Config.AddCurrentModelToRandom then
		if not table.find(MobModels, self.Config.Name) then
			table.insert(MobModels, self.Config.Name)
		end
		if not Alternatives:FindFirstChild(self.Config.Name) then
			local NewMobCopy = self.Instance:Clone()
			ClearMobInstance(NewMobCopy)
			NewMobCopy.Parent = Alternatives
			NewMobCopy.Name = self.Config.Name
		end
	end

	local ChosenName = MobModels[math.random(1, #MobModels)]
	if Alternatives:FindFirstChild(ChosenName) then
		local NewMobCopy = Alternatives[ChosenName]:Clone()
		ClearMobInstance(NewMobCopy)
		
		if not NewMobCopy:FindFirstChildWhichIsA("ModuleScript") then
			for _, Script in self.Scripts do
				Script:Clone().Parent = NewMobCopy
			end
		end

		NewMobCopy:WaitForChild("HumanoidRootPart"):PivotTo(self.Origin)
		CollectionService:AddTag(NewMobCopy, "Mob")

		self._Copy = NewMobCopy
	else
		warn(`[Kit/MobLib/.new]: Alternative model doesn't exist: {ChosenName}`)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- yes, this is just to swing the sword.
function Mob:CommitHitCycle()
	local MobInstance = self.Instance
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	
	local HitCycle = HitCycleFunctions:GetHitCycle(self)
	self.HitCycle = HitCycle
	
	local Cooldown = {}
	self.HitboxConnections = {}
	
	---- Callback functions
	
	local function PlayToolSound(Position)
		local Tool = MobInstance:FindFirstChildWhichIsA("Tool")
		if Tool then
			local ContentTool = ReplicatedStorage.Items:FindFirstChild(Tool.Name, true)

			local Config = ContentTool 
				and ContentTool:FindFirstChild("ItemConfig") 
				and require(ContentTool.ItemConfig)

			if Config and Config.ActivateSound then
				SFX:Play3D(Config.ActivateSound[1], Position, {Volume = Config.ActivateSound[2]})
			end
		end
	end
	
	local function Damage(Player)
		table.insert(Cooldown, Player)
		task.spawn(DamageLib.Hurt, Player, self.Config.Damage, self)
	end
	
	local function AttackPlayersInRadius(Position, Radius)
		for _, Player in Players:GetPlayers() do
			if table.find(Cooldown, Player) then continue end
			
			local Character = Player.Character
			local Torso = Character and Character:FindFirstChild("Torso")
			if not Torso then continue end
			
			local Magnitude = (Torso.Position - Position).Magnitude
			if Magnitude <= Radius then
				Damage(Player)
			end
		end
	end
	
	local function OnTouched(Hit)
		local Player = Players:GetPlayerFromCharacter(Hit.Parent)
		if Player and not table.find(Cooldown, Player) then
			Damage(Player)
		end
	end
	
	local function ClearConnections()
		for _, Connection in self.HitboxConnections do
			Connection:Disconnect()
			Connection = nil
		end

		self.HitboxConnections = {}
	end
	
	---- Hitcycle functions
	
	local function RequestAttack(Cycle, NearestTorso)
		local MobTorso = MobInstance:FindFirstChild("Torso")
		if not MobTorso then return end
		
		ClearConnections()
		
		if self.YieldAttackSignal then
			self.YieldAttackSignal:Wait()
		end
		
		local OriginalWalkSpeed = self.Config.WalkSpeed
		
		local StopWhileAttacking = Cycle.StopWhileAttacking
		if StopWhileAttacking and typeof(StopWhileAttacking) == "number" then
			task.delay(StopWhileAttacking, function()
				self:SetWalkSpeed("HitCycle", nil)
			end)

			self:SetWalkSpeed("HitCycle", -9999)
		end
		
		local TelegraphAnimation = Cycle.TelegraphAnimation
		EventModule:FireAllClients("RequestAnimateMob", 
			MobInstance, "Telegraph" .. TelegraphAnimation[1], 
			TelegraphAnimation[1], TelegraphAnimation[2], TelegraphAnimation[3], Cycle.ShowTrail
		)
		
		task.spawn(function()
			self.YieldCycleSignal = Signal.new()
			
			task.delay((Cycle.Cooldown or 1) * 0.75, function()
				ClearConnections()
				
				self.YieldCycleSignal:Fire()

				self.YieldCycleSignal:Destroy()
				self.YieldCycleSignal = nil
			end)
			
			local TotalDuration = (TelegraphAnimation[2] or 0) + (TelegraphAnimation[3] or 0)
			if TotalDuration > 0 then
				task.wait(TotalDuration)
			end
			
			local Callback = Cycle.Callback 
			if Callback then
				task.spawn(Callback, MobInstance, NearestTorso)
			end
			
			PlayToolSound(MobTorso)
			
			local Attack = Cycle.Attack
			if Attack then
				if Attack[2] == "InFront" then
					local DistanceInFront = MobTorso.Size.Y
					local NewCFrame = MobTorso.CFrame + MobTorso.CFrame.LookVector * Vector3.new(DistanceInFront, 0, DistanceInFront)

					AttackPlayersInRadius(NewCFrame.Position, Attack[1])
				elseif Attack[2] == "Circular" then
					AttackPlayersInRadius(MobTorso.Position, Attack[1])
				end
			end
			
			for _, Object in self.HitboxObjects do
				if Object.Size.Magnitude > 3.5 then
					self.HitboxConnections[#self.HitboxConnections + 1] = Object.Touched:Connect(OnTouched)
				end
			end
		end)
	end
	
	local function GoThroughHitCycle()
		for _, Cycle in HitCycle do
			local NearestTorso = FindNearestTorso(MobInstance, nil, true)
			local MobTorso = MobInstance:FindFirstChild("Torso")
			
			local isStunned = AttributeModule:GetAttribute(MobInstance, "Stunned")
			if NearestTorso and MobTorso and not isStunned then 
				local AttackDistance = Cycle.Range or 4 * MobTorso.Size.Y

				if (NearestTorso.Position - MobTorso.Position).Magnitude <= AttackDistance then
					RequestAttack(Cycle, NearestTorso)
					
					task.wait(Cycle.Cooldown or 1)
				end
			else
				task.wait(0.5)
			end
			
			table.clear(Cooldown)
		end
	end
	
	if HitCycle then
		self.Threads[#self.Threads + 1] = task.spawn(function()
			task.wait(1)
			
			while self and not self.isDead do
				GoThroughHitCycle()
				task.wait()
			end
		end)
	end
end

function Mob:CommitAttackSystem()
	local MobInstance = self.Instance
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	
	local AttackConfig = AttackFunctions:GetAttackCycle(self)
	self.AttackConfig = AttackConfig

	local function MobCycleSequence(Sequence)
		for _, Cycle in Sequence do
			if self.YieldCycleSignal then
				self.YieldCycleSignal:Wait()
			end
			
			local NearestTorso = FindNearestTorso(MobInstance, nil, Cycle.RequiresTarget)
			
			local isStunned = AttributeModule:GetAttribute(MobInstance, "Stunned")
			if NearestTorso and not isStunned then
				local YieldSignal = Signal.new()
				
				task.spawn(function() -- for some reason i can't cancel this so rip
					while YieldSignal do
						if not FindNearestTorso(MobInstance, nil, Cycle.RequiresTarget) then
							YieldSignal:Fire()
							break
						end

						task.wait(1)
					end
				end)
				
				task.spawn(Cycle.Callback, NearestTorso, self)
				
				local StopWhileAttacking = Cycle.StopWhileAttacking
				if StopWhileAttacking and typeof(StopWhileAttacking) == "number" then
					task.delay(StopWhileAttacking, function()
						self:SetWalkSpeed("AttackCycle", nil)
					end)
					
					self:SetWalkSpeed("AttackCycle", -9999)
				end

				local TelegraphAnimation = Cycle.TelegraphAnimation
				if TelegraphAnimation then
					local TotalDuration = (TelegraphAnimation[2] or 0) + (TelegraphAnimation[3] or 0)
					if TotalDuration > 0 then
						self.YieldAttackSignal = Signal.new()
						
						task.delay(TotalDuration + 0.5, function()
							self.YieldAttackSignal:Fire()
							
							self.YieldAttackSignal:Destroy()
							self.YieldAttackSignal = nil
						end) 
					end
					
					EventModule:FireAllClients("RequestAnimateMob", 
						MobInstance, "Telegraph" .. TelegraphAnimation[1], 
						TelegraphAnimation[1], TelegraphAnimation[2], TelegraphAnimation[3]
					)
				end

				local CycleActivation = Cycle.Activation or {}
				if CycleActivation.Type == "Time" then
					task.delay(CycleActivation.Value, function()
						if YieldSignal then
							YieldSignal:Fire()
						end
					end)
				elseif CycleActivation.Type == "Health" then
					local CurrentPercent = Enemy.Health / Enemy.MaxHealth
					local Difference = CurrentPercent - CycleActivation.Value

					self.AttackConnection = Enemy.HealthChanged:Connect(function()
						local Percent = Enemy.Health / Enemy.MaxHealth
						if Percent <= Difference then
							YieldSignal:Fire()
						end
					end)
				elseif CycleActivation.Type == "MaxHealth" then
					self.AttackConnection = Enemy.HealthChanged:Connect(function()
						local Percent = Enemy.Health / Enemy.MaxHealth
						if Percent <= CycleActivation.Value then
							YieldSignal:Fire()
						end
					end)
				end
				
				self.Signals[#self.Signals + 1] = YieldSignal
				
				YieldSignal:Wait()

				if self.AttackConnection then
					self.AttackConnection:Disconnect()
					self.AttackConnection = nil
				end
				
				if self.Threads.AttackThread then
					self.Threads.AttackThread = nil
				end
				
				self.Threads.AttackThread = nil
				
				YieldSignal:Destroy()
				YieldSignal = nil
			else
				return false
			end
		end

		return true
	end	

	for _, Sequence in AttackConfig do
		self.Threads[#self.Threads + 1] = task.spawn(function()
			while self and not self.isDead do
				local Success = MobCycleSequence(Sequence)
				if not Success then
					task.wait(1)
				end
			end
		end)
	end
end

function Mob:AwardDrops()
	if self.Awarded then return end
	self.Awarded = true
	
	local PlayerTags = self.Instance:FindFirstChild("PlayerTags") :: Configuration
	if not PlayerTags then return end
	
	local AlreadyGiven = {}
	
	for UserId, Damage: number in PlayerTags:GetAttributes() do
		UserId = tonumber(UserId)
		
		if AlreadyGiven[UserId] then continue end
		AlreadyGiven[UserId] = true

		local Player = Players:GetPlayerByUserId(UserId)
		local Percent = Damage / self.Enemy.MaxHealth
		if not Player or Percent < 0.25 then continue end

		local pData = PlayerData:FindFirstChild(Player.UserId)

		local Products = ProductLib:GetProducts(Player)
		local AllocatedLuck = GetPlayerLuck(Products)

		local Statistics = pData:FindFirstChild("Stats")
		if not Statistics then continue end

		-- Update quest kills & kills
		local Quests = pData:FindFirstChild("Quests")
		if Quests then
			for _, Folder in Quests.Active:GetChildren() do
				local Mobs = Folder:FindFirstChild("Mobs")
				if not Mobs then	
					continue
				end
				
				for _, Value in Mobs:GetChildren() do
					if Value.Name == self.Name then
						Value.Value += 1
					end
				end
			end
		end
		
		Statistics.Kills.Value += 1

		-- Track mob kills for Mob Index
		local MobKills = pData:FindFirstChild("MobKills")
		if MobKills then
			local MobName = self.Config.Name or self.Name
			local KillValue = MobKills:FindFirstChild(MobName)
			if not KillValue then
				KillValue = Instance.new("NumberValue")
				KillValue.Name = MobName
				KillValue.Parent = MobKills
			end
			KillValue.Value += 1
		end
		---- Handle items & stats
		
		GiftDrops(Player, self.Config.Drops, true, true, true)

		---- Handle badges & misc

		local function AwardBadge(BadgeID)
			local Success = nil :: boolean
			local Results = nil :: any

			repeat
				Success, Results = pcall(function()
					return BadgeService:AwardBadge(Player.UserId, BadgeID)
				end)
				if not Success then
					print(`MobLib: couldn't award badge ID {BadgeID}, {Results}.`)
					task.wait(1)
				end
			until Success

			print(`MobLib: awarded badge ID {BadgeID} to {Player.DisplayName}`)
			AttributeModule:SetAttribute(Player, tostring(BadgeID), true)
		end

		local BadgeID = self.Config.AwardBadge
		if BadgeID and not AttributeModule:GetAttribute(Player, tostring(BadgeID)) then
			task.defer(AwardBadge, BadgeID)
		end
		
		if self.Config.TeleportLocation then
			EventModule:FireClient("RequestTeleport", Player, self.Config.TeleportLocation, true)
		end
	end
end

function Mob:CheckRegenerateTag()
	local MobInstance = self.Instance
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	local MobConfig = MobInstance:FindFirstChild("MobConfig") and require(MobInstance.MobConfig)

	local RegenerateConnections = {}
	local DespawnTask = nil
	
	local function ClearRegenerateConnections()
		for _, Connection in RegenerateConnections do
			if typeof(Connection) == "RBXScriptConnection" then
				Connection:Disconnect()
			else
				task.cancel(Connection)
			end
			
			Connection = nil
		end
		
		RegenerateConnections = {}
	end

	local function FullHealMobInstance()
		local PlayerTags = MobInstance:FindFirstChild("PlayerTags") :: Configuration
		if PlayerTags then
			for Name, Value in PlayerTags:GetAttributes() do
				PlayerTags:SetAttribute(Name, nil)
			end
		end
		Enemy.Health = MobConfig.Health
	end

	local CurrentTimer = os.clock()
	local function CommitMobInstanceRegenerated(Object, SetNil)
		CurrentTimer = os.clock()

		if SetNil and Object then
			Object:Destroy()
			AttributeModule:SetAttribute(MobInstance, "Target", nil)
		end

		ClearRegenerateConnections()
		FullHealMobInstance()
	end

	local function OnChildAddded(Object)
		if Object.Name == "RegenerateTag" and Object:IsA("Configuration") then
			Object:GetAttributeChangedSignal("Clock"):Connect(function()
				local Clock = Object:GetAttribute("Clock") :: number
				
				if DespawnTask then
					task.cancel(DespawnTask)
					DespawnTask = nil
				end
				
				if Clock == nil then 
					return 
				end

				DespawnTask = task.delay(MobConfig.InstantRefreshData and MobConfig.InstantRefreshData.Cooldown or 60, function()
					if Object:GetAttribute("Clock") == Clock then
						CommitMobInstanceRegenerated(Object, true)
						Object:Destroy()
					end
				end)
			end)

			local PreviousPlayer = nil
			Object:GetAttributeChangedSignal("PlayerID"):Connect(function()
				local PlayerID = Object:GetAttribute("PlayerID")
				local Player = PlayerID and (Players:GetPlayerByUserId(PlayerID) or Players:GetPlayerByUserId("-" .. PlayerID)) :: Player
				if PreviousPlayer == Player then
					return
				end

				PreviousPlayer = Player
				if Player == nil then 
					return 
				end

				CommitMobInstanceRegenerated(Object)

				local Character = Player and Player.Character
				local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
				if Humanoid and Humanoid.Health > 0 then 
					RegenerateConnections[#RegenerateConnections + 1] = Player.AncestryChanged:Connect(function(Child, Parent)
						if Parent == nil then
							CommitMobInstanceRegenerated(Object, true)
						end
					end)

					RegenerateConnections[#RegenerateConnections + 1] = Humanoid.Died:Connect(function()
						CommitMobInstanceRegenerated(Object, true)
					end)

					local OldTimer = CurrentTimer
					task.spawn(function()
						while Object.Parent ~= nil and OldTimer == CurrentTimer and not Mob.isDead and Player.Parent ~= nil do
							local Magnitude = (Character:GetPivot().Position - MobInstance:GetPivot().Position).Magnitude
							if Magnitude > (MobConfig.InstantRefreshData and MobConfig.InstantRefreshData.Distance or GameConfig.DefaultDistanceRadius) then
								CommitMobInstanceRegenerated(Object, true)
							end

							task.wait(2)
						end
					end)
				end
			end)
		end
	end

	MobInstance.ChildAdded:Connect(OnChildAddded)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

task.defer(function()
	CollectionService:GetInstanceAddedSignal("Mob"):Connect(function(MobInstance)
		if MobInstance:IsDescendantOf(workspace) then 
			MobLib.new(MobInstance)
		end
	end)
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		if MobInstance:IsDescendantOf(workspace) then 
			task.spawn(MobLib.new, MobInstance)
		end
	end
end)

return MobLib