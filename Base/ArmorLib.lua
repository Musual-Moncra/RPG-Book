--[[
	Evercyan @ March 2023
	ArmorLib
	
	ArmorLib is an item library that houses code that can be ran on the server relating
	to Armor, such as ArmorLib:Give(Player, Armor (ContentLib.Armor[...])), as well
	as equipping & unequipping armor, which is primarily ran through remotes fired from the 
	client's Inventory Gui.
]]

--> Services
local CollectionService = game:GetService("CollectionService")
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

--> Variables
local Library = script.Name
local SEP = "|"

local ArmorLib = {}
local ChangeCd = {}

-- Returns the pData NumberValue for baseName, checking bare key first then any prefixed key.
-- This makes all ownership checks prefix-aware: "Iron Armor" matches "Iron Armor|Godly".
local function FindOwnedKey(folder, baseName)
	if not folder then return nil end
	-- Exact match first (bare name)
	local exact = folder:FindFirstChild(baseName)
	if exact then return exact end
	-- Prefixed match: "Iron Armor|Godly", "Iron Armor|Ancient", etc.
	for _, v in folder:GetChildren() do
		local base = v.Name:match("^(.+)" .. SEP .. ".+$")
		if base == baseName then
			if not v:IsA("NumberValue") or v.Value >= 1 then
				return v
			end
		end
	end
	return nil
end
--------------------------------------------------------------------------------

local function RequestCallback(Model, Name, CallbackType, Parameters)
	EventModule:Fire("ServerToServerEquipmentCallback", Model, Name, CallbackType, Parameters)
	EventModule:FireAllClients("ServerToClientEquipmentCallback", Model, Name, CallbackType, Parameters)
end

function ArmorLib:Give(Player: Player, Armor, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Armor) == "table" 
	if not isItem then
		warn(`Item {Library} --> {tostring(Armor) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		local Found = pData.Items[Library]:FindFirstChild(Armor.Name)
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = ((not Found) or IsStackable)
		
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Armor.Config.Cost[4]) and IsStackable)
		if CanGive or CanBuyMultiple then
			return CreateValue(pData, Armor, DontSave, Amount, Library)
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ArmorLib:Trash(Player: Player, Armor, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	if pData then
		RemoveValue(pData, Armor, Amount, Library)
		
		if pData.ActiveArmor.Value == Armor.Name then
			pData.ActiveArmor.Value = ""
			
			ArmorLib:UnequipArmor(Player)
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ArmorLib:ClearStatistics(Statistics)
	for _, Statistic in Statistics:GetChildren() do
		for Name, Value in Statistic:GetAttributes() do
			if string.find(Name, "Armor") then
				Statistic:SetAttribute(Name, nil)
			end
		end
	end
end

function ArmorLib:ClearBoosts(Boosts)
	for _, Boost in GameConfig.ClassBoosts do
		local Value = Boosts[Boost]
		Value:SetAttribute("Armor", nil)
		Value:SetAttribute("ArmorAdditive", nil)
	end
end


-- Apply prefix stat bonuses onto Humanoid attributes.
-- Uses "ArmorPrefix" key so ClearStatistics (scans for "Armor") clears them on next equip,
-- and UnequipArmor/UnequipAccessory explicitly clears them too.
local function ApplyPrefixStats(Humanoid, prefixName, itemType, attrKeySuffix)
	if not prefixName or not itemType then return end
	local PC = GameConfig.PrefixConfig
	local data = PC and PC.Prefixes and PC.Prefixes[itemType] and PC.Prefixes[itemType][prefixName]
	if not data or not data.Stats then return end

	local Attributes = Humanoid:FindFirstChild("Attributes")
	local Statistics  = Humanoid:FindFirstChild("Statistics")
	local Mana        = Humanoid:FindFirstChild("Mana")
	local attrKey     = "ArmorPrefix" .. (attrKeySuffix or "")

	for statName, statData in data.Stats do
		local op, val = statData[1], statData[2]
		if statName == "Health" and Attributes and Attributes:FindFirstChild("Health") then
			local bonus = op == "Multiply" and math.round((val - 1) * 100) or val
			Attributes.Health:SetAttribute(attrKey, bonus)
		elseif statName == "WalkSpeed" and Attributes and Attributes:FindFirstChild("WalkSpeed") then
			Attributes.WalkSpeed:SetAttribute(attrKey, val)
		elseif statName == "JumpPower" and Attributes and Attributes:FindFirstChild("JumpPower") then
			Attributes.JumpPower:SetAttribute(attrKey, val)
		elseif statName == "Mana" and Mana and Mana:FindFirstChild("MaxMana") then
			Mana.MaxMana:SetAttribute(attrKey, val)
		elseif statName == "Defense" and Statistics and Statistics:FindFirstChild("Defense") then
			if op == "Add" then
					-- Flat additive defense reduction (points)
					Statistics.Defense:SetAttribute(attrKey .. "Additive", val)
				elseif op == "Multiply" then
					-- Scale whichever base value exists: additive (point-based) or multiplicative (%).
					-- Store the delta in the matching bucket so the damage system sums it correctly.
					local baseAdd  = Statistics.Defense:GetAttribute("ArmorAdditive") or 0
					local baseMul  = Statistics.Defense:GetAttribute("Armor") or 0
					if baseAdd ~= 0 then
						-- Point-based: delta is extra flat points (e.g. 5 * 0.25 = 1.25 pts)
					Statistics.Defense:SetAttribute(attrKey .. "Additive", math.round(baseAdd * (val - 1) * 100) / 100)
					else
						-- Percentage-based: delta is extra fraction (e.g. 0.5 * 0.25 = 0.125)
						Statistics.Defense:SetAttribute(attrKey, baseMul * (val - 1))
					end
				end
		end
	end
end

-- Clear all ArmorPrefix<suffix> attributes set by ApplyPrefixStats
local function ClearPrefixStats(Humanoid, attrKeySuffix)
	local Attributes = Humanoid and Humanoid:FindFirstChild("Attributes")
	local Statistics  = Humanoid and Humanoid:FindFirstChild("Statistics")
	local Mana        = Humanoid and Humanoid:FindFirstChild("Mana")
	local attrKey     = "ArmorPrefix" .. (attrKeySuffix or "")

	if Attributes then
		for _, cfg in Attributes:GetChildren() do
			cfg:SetAttribute(attrKey, nil)
		end
	end
	if Mana and Mana:FindFirstChild("MaxMana") then
		Mana.MaxMana:SetAttribute(attrKey, nil)
	end
	if Statistics then
		for _, stat in Statistics:GetChildren() do
			stat:SetAttribute(attrKey, nil)
			stat:SetAttribute(attrKey .. "Additive", nil)
		end
	end
end

ArmorLib.ApplyPrefixStats = ApplyPrefixStats
ArmorLib.ClearPrefixStats  = ClearPrefixStats

function ArmorLib:EquipArmor(Player: Player, Armor)
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Attributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
	if not Attributes or Humanoid.Health <= 0 then return end
	
	-- Humanoid changes
	Attributes.Health:SetAttribute("Armor", Armor.Config.Health)
	Attributes.WalkSpeed:SetAttribute("Armor", Armor.Config.WalkSpeed)
	Attributes.JumpPower:SetAttribute("Armor", Armor.Config.JumpPower)
	
	-- Mana/Data changes
	local Boosts = Humanoid:WaitForChild("Boosts")
	ArmorLib:ClearBoosts(Boosts)
	
	if Armor.Config.Mana then
		local ManaAttributes = Humanoid:WaitForChild("Mana")
		ManaAttributes.MaxMana:SetAttribute("Armor", Armor.Config.Mana)
	end
	
	if Armor.Config.DamageClass then
		local DamageClass = Armor.Config.DamageClass
		
		local DamagePoints = Armor.Config.DamagePoints[1]
		local Additive = Armor.Config.DamagePoints[2]
		
		Boosts[DamageClass]:SetAttribute((Additive and "ArmorAdditive") or Additive, DamagePoints)
	end
	
	-- Statistics changes
	local Statistics = Humanoid.Statistics
	ArmorLib:ClearStatistics(Statistics)
	
	for _, Attribute in Statistics:GetChildren() do
		local Value = Armor.Config[Attribute.Name]
		if not Value then
			continue
		end
		
		local IsAdditive = Value[2]
		Attribute:SetAttribute((IsAdditive and "ArmorAdditive") or "Armor", Value[1])
	end
	
	-- Morph changes
	Morph:ApplyOutfit(Player, Armor)
	RequestCallback(Armor.Instance, Armor.Name, "OnEquipped", {Player, Armor.Config})

	-- Apply prefix stats (reads pData to find the prefixed key, e.g. "Bronze Armor|Warding")
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if pData then
		local ownedKey = FindOwnedKey(pData.Items.Armor, Armor.Name)
		local prefixName = ownedKey and ownedKey.Name:match("^.+|(.+)$")
		ApplyPrefixStats(Humanoid, prefixName, "Armor")
	end
end
function ArmorLib:UnequipArmor(Player: Player)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Armor = ContentLibrary[Library][pData.ActiveArmor.Value]
	RequestCallback(Armor.Instance, Armor.Name, "OnUnequipped", {Player, Armor.Config})
	
	-- Humanoid changes
	local Attributes = Humanoid and Humanoid:FindFirstChild("Attributes")
	if Attributes then
		Attributes.Health:SetAttribute("Armor", nil)
		Attributes.WalkSpeed:SetAttribute("Armor", nil)
		Attributes.JumpPower:SetAttribute("Armor", nil)
	end
	
	-- Boost/mana changes
	local Boosts = Humanoid and Humanoid:FindFirstChild("Boosts")
	if Boosts then
		ArmorLib:ClearBoosts(Boosts)
	end
	
	local ManaAttributes = Humanoid and Humanoid:FindFirstChild("Mana")
	if ManaAttributes then
		ManaAttributes.MaxMana:SetAttribute("Armor", nil)
	end
	
		-- Statistics changes
		local Statistics = Humanoid and Humanoid:FindFirstChild("Statistics")
		if Statistics then
			ArmorLib:ClearStatistics(Statistics)
		end

		-- Clear prefix stats
		ClearPrefixStats(Humanoid)
	
	-- Morph changes
	Morph:ClearOutfit(Player)
end

--------------------------------------------------------------------------------

local ArmorContent = {}

-- Armor objects
local function AddArmorToContent(ArmorInstance)
	local Config = require(ArmorInstance:FindFirstChildWhichIsA("ModuleScript"))
	
	if ArmorContent[Config.Name] then
		warn(`Armor {Config.Name} already exists in ArmorContent, please change its name.`)
		return
	end
	
	ArmorContent[Config.Name] = Config
end

for _, ArmorInstance in CollectionService:GetTagged("Armor") do
	task.spawn(AddArmorToContent, ArmorInstance)
end

CollectionService:GetInstanceAddedSignal("Armor"):Connect(AddArmorToContent)

-- Remotes
local function RequestUnequipArmor(Player)
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	ArmorLib:UnequipArmor(Player)
	pData.ActiveArmor.Value = ""
end

local function RequestEquipArmor(Player, ArmorName: string)
	if typeof(ArmorName) ~= "string" then return end

	local pData = PlayerData:WaitForChild(Player.UserId)

	-- Prefix-aware ownership check: matches "Iron Armor" OR "Iron Armor|Godly" etc.
	local ArmorValue = FindOwnedKey(pData.Items.Armor, ArmorName)
	local ArmorItem = ContentLibrary.Armor[ArmorName]

	if ArmorValue and ArmorItem and not ChangeCd[Player.UserId] then
		ChangeCd[Player.UserId] = true
		task.delay(0.25, function()
			ChangeCd[Player.UserId] = nil
		end)

		ArmorLib:EquipArmor(Player, ArmorItem)
			pData.ActiveArmor.Value = ArmorName
		end
end

EventModule:GetOnServerEvent("EquipObjectArmor"):Connect(function(Player, ArmorName: string)
	if typeof(ArmorName) ~= "string" then return end

	local ArmorConfig = ArmorContent[ArmorName]
	local Requirements = ArmorConfig and ArmorConfig.Requirements
	if not Requirements then return end

	local pData = PlayerData:WaitForChild(Player.UserId)
	local Level = pData:WaitForChild("Stats"):WaitForChild("Level")
	if Requirements.Level and Level.Value < Requirements.Level then
		return
	end

	local ArmorFolder = pData:WaitForChild("Items"):WaitForChild("Armor")

		-- SECURITY: prefix-aware ownership check.
		-- FindOwnedKey matches bare "Iron Armor" OR prefixed "Iron Armor|Godly".
		local isOwned = FindOwnedKey(ArmorFolder, ArmorName) ~= nil
		if not isOwned and not Requirements.FreeToEquip then
			return
		end

		local ArmorItem = ContentLibrary.Armor[ArmorName]
		if ArmorItem then
			-- Only give the bare item if neither bare nor prefixed version is owned
			if not FindOwnedKey(ArmorFolder, ArmorName) then
				ArmorLib:Give(Player, ArmorItem)
			end

			RequestEquipArmor(Player, ArmorName)
		end
	end)

EventModule:GetOnServerEvent("UnequipObjectArmor"):Connect(RequestUnequipArmor)
EventModule:GetOnServerInvoke("EquipArmor", RequestEquipArmor)
EventModule:GetOnServerInvoke("UnequipArmor", RequestUnequipArmor)

--------------------------------------------------------------------------------

local function OnPlayerAdded(Player: Player)
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local function OnCharacterAdded(Character)
		local ActiveArmor = pData:WaitForChild("ActiveArmor")
		local Armor = ActiveArmor.Value ~= "" and ContentLibrary.Armor[ActiveArmor.Value]
		
		-- Update any incoming accessories (CharacterAppearanceLoaded is really broken lol)
		local Connection = Character.ChildAdded:Connect(function(Child)
			if Child:IsA("Accessory") then
				Morph:UpdateAccessoriesTransparency(Character, ActiveArmor.Value ~= "" and ContentLibrary.Armor[ActiveArmor.Value])
			end
		end)
		Player.CharacterRemoving:Once(function()
			Connection:Disconnect()
		end)
		
		if Armor then
			if Player:HasAppearanceLoaded() then
				ArmorLib:EquipArmor(Player, Armor)
			else
				Player.CharacterAppearanceLoaded:Once(function()
					ArmorLib:EquipArmor(Player, Armor)
				end)
			end
		end
	end
	
	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end
end

for _, Player in Players:GetChildren() do
	task.defer(OnPlayerAdded, Player)
end
Players.PlayerAdded:Connect(OnPlayerAdded)
return ArmorLib