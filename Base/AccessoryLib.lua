--[[
	ej0w @ October 2024
	Accessory
	
	Acts similar to ArmorLib script for a few given differences, being equipping multiple at once 
	& lacking in some configuration (in exchange for keybinds)
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local Morph = require(ServerStorage.Modules.Server.Morph)
local CreateValue = require(ServerStorage.Modules.Server.createValue)
local RemoveValue = require(ServerStorage.Modules.Server.removeValue)

local GameConfig = require(ReplicatedStorage.GameConfig)
local ArmorLib   = require(ServerStorage.Modules.Libraries["items [Subcategories]"].Armor)

--> Variables
local Library = script.Name

local Debounce = {}
local AccessoryLib = {}

--------------------------------------------------------------------------------

local function RequestCallback(Model, Name, CallbackType, Parameters)
	EventModule:Fire("ServerToServerEquipmentCallback", Model, Name, CallbackType, Parameters)
	EventModule:FireAllClients("ServerToClientEquipmentCallback", Model, Name, CallbackType, Parameters)
end

local SEP_ACC = "|"

-- Returns true if the player owns at least 1 of this accessory (prefix-aware).
-- Matches bare "Ring" OR prefixed "Ring|Godly" etc.
local function PlayerOwnsAccessory(pData, AccessoryName: string): boolean
	local ItemFolder = pData.Items[Library]
	if not ItemFolder then return false end
	-- Exact match first (bare name)
	local exact = ItemFolder:FindFirstChild(AccessoryName)
	if exact then
		if exact:IsA("NumberValue") then return exact.Value > 0 end
		return true -- BoolValue / presence-based
	end
	-- Prefixed match: "Ring|Godly", etc.
	for _, v in ItemFolder:GetChildren() do
		local base = v.Name:match("^(.+)" .. SEP_ACC .. ".+$")
		if base == AccessoryName then
			if not v:IsA("NumberValue") or v.Value >= 1 then return true end
		end
	end
	return false
end

function AccessoryLib:Give(Player: Player, Accessory, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Accessory) == "table"
	if not isItem then
		warn(`Item {Library} --> {tostring(Accessory) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		local Found = pData.Items[Library]:FindFirstChild(Accessory.Name)
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = ((not Found) or IsStackable)
		
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Accessory.Config.Cost[4]) and IsStackable)
		if CanGive or CanBuyMultiple then
				return CreateValue(pData, Accessory, DontSave, Amount, Library)
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function AccessoryLib:Trash(Player: Player, Accessory, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)

	if pData then
		RemoveValue(pData, Accessory, Amount, Library)
		
		for _, Slot in pData.EquippedSlots:GetChildren() do
			if Slot.Value == Accessory.Name then
				AccessoryLib:UnequipAccessory(Player, tonumber(Slot.Name), Slot.Value)
				
				Slot.Value = ""
			end
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function AccessoryLib:EquipAccessory(Player: Player, Accessory, Index)
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Attributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
	if not Attributes or Humanoid.Health <= 0 then return end
	
	local Key = "Accessory" .. tostring(Index)
	
	-- Humanoid changes
	Attributes.Health:SetAttribute(Key, Accessory.Config.Health)
	Attributes.WalkSpeed:SetAttribute(Key, Accessory.Config.WalkSpeed)
	Attributes.JumpPower:SetAttribute(Key, Accessory.Config.JumpPower)
	
	if Accessory.Config.Mana then
		local ManaAttributes = Humanoid:WaitForChild("Mana")
		ManaAttributes.MaxMana:SetAttribute(Key, Accessory.Config.Mana)
	end
	
	-- Morph changes
	Morph:AddAccessory(Player, Accessory, Index)
	RequestCallback(Accessory.Instance, Accessory.Name, "OnEquipped", {Player, Accessory.Config})

	-- Apply prefix stats (reads pData to find prefixed key e.g. "Cerulean Crown|Godly")
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if pData then
		local ItemFolder = pData.Items[Library]
		local ownedKey = nil
		for _, v in ItemFolder:GetChildren() do
			local base = v.Name:match("^(.+)|.+$") or v.Name
			if base == Accessory.Name then ownedKey = v; break end
		end
		local prefixName = ownedKey and ownedKey.Name:match("^.+|(.+)$")
		ArmorLib.ApplyPrefixStats(Humanoid, prefixName, "Accessory", tostring(Index))
	end
end

function AccessoryLib:UnequipAccessory(Player: Player, Index, AccessoryName)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	
	local Accessory = ContentLibrary[Library][AccessoryName]
	if not Accessory then return end -- guard against bad AccessoryName
	local Key = "Accessory" .. tostring(Index)
	
	RequestCallback(Accessory.Instance, Accessory.Name, "OnUnequipped", {Player, Accessory.Config})
	
	-- Humanoid changes
	local Attributes = Humanoid and Humanoid:FindFirstChild("Attributes")
	if Attributes then
		Attributes.Health:SetAttribute(Key, nil)
		Attributes.WalkSpeed:SetAttribute(Key, nil)
		Attributes.JumpPower:SetAttribute(Key, nil)
	end
	
	local ManaAttributes = Humanoid and Humanoid:FindFirstChild("Mana")
	if ManaAttributes then
		ManaAttributes.MaxMana:SetAttribute(Key, nil)
	end

		-- Morph changes
	Morph:RemoveAccessory(Player, Index)

	-- Clear prefix stats for this slot
	ArmorLib.ClearPrefixStats(Humanoid, tostring(Index))
end

---- Remotes -------------------------------------------------------------------

EventModule:GetOnServerInvoke("EquipAccessory", function(Player: Player, AccessoryName: string, Index: number)
	-- Type checks
	if typeof(AccessoryName) ~= "string" then return end
	if typeof(Index) ~= "number" or math.floor(Index) ~= Index or Index < 1 then return end

	local pData = PlayerData:WaitForChild(Player.UserId)
	local EquippedSlots = pData:WaitForChild("EquippedSlots")

	-- Index must be a valid slot
	local Slot = EquippedSlots:FindFirstChild(tostring(Index))
	if not Slot or Slot.Value ~= "" then return end

	-- Accessory must exist in ContentLibrary
	local Accessory = ContentLibrary[Library][AccessoryName]
	if not Accessory then return end

	-- SECURITY: player must actually own this accessory
	if not PlayerOwnsAccessory(pData, AccessoryName) then return end

	-- Debounce to prevent rapid-fire equips
	if Debounce[Player.UserId] then return end
	Debounce[Player.UserId] = true
	task.delay(0.25, function()
		Debounce[Player.UserId] = nil
	end)

	Slot.Value = AccessoryName
	AccessoryLib:EquipAccessory(Player, Accessory, Index)
end)

EventModule:GetOnServerInvoke("UnequipAccessory", function(Player: Player, Index: number)
	-- Type checks
	if typeof(Index) ~= "number" or math.floor(Index) ~= Index or Index < 1 then return end

	local pData = PlayerData:WaitForChild(Player.UserId)
	local EquippedSlots = pData:WaitForChild("EquippedSlots")

	local Slot = EquippedSlots:FindFirstChild(tostring(Index))
	if Slot and Slot.Value ~= "" then
		AccessoryLib:UnequipAccessory(Player, Index, Slot.Value)
		Slot.Value = ""
	end
end)

--------------------------------------------------------------------------------

local function OnPlayerAdded(Player: Player)
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local function OnCharacterAdded(Character)
		local EquippedSlots = pData:WaitForChild("EquippedSlots")
		
		local function EquipAccessory(Accessory, Index)
			if Player:HasAppearanceLoaded() then
				AccessoryLib:EquipAccessory(Player, Accessory, Index)
			else
				Player.CharacterAppearanceLoaded:Once(function()
					AccessoryLib:EquipAccessory(Player, Accessory, Index)
				end)
			end
		end
		
		for _, Slot in EquippedSlots:GetChildren() do
			local Accessory = Slot.Value ~= "" and ContentLibrary[Library][Slot.Value]
			if Accessory then
				-- Re-verify ownership on respawn too
				if PlayerOwnsAccessory(pData, Slot.Value) then
					task.spawn(EquipAccessory, Accessory, tonumber(Slot.Name))
				else
					Slot.Value = ""
				end
			end
		end
	end
	
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end
	
	Player.CharacterAdded:Connect(OnCharacterAdded)
end

for _, Player in Players:GetChildren() do
	task.defer(OnPlayerAdded, Player)
end
Players.PlayerAdded:Connect(OnPlayerAdded)
return AccessoryLib
