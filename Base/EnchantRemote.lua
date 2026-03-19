--[[ej0w@2025 EnchantItem]]
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local GC = require(RS.GameConfig)
local EC = GC.EnchantConfig
if not GC.EnabledFeatures or not GC.EnabledFeatures.Enchants then return {} end

local EventModule    = require(RS.Modules.Shared.Event)
local ContentLibrary = require(RS.Modules.Shared.ContentLibrary)
local TagToolEnchants = require(SS.Modules.Server.EnchantToolTagger)
local ItemUtils      = require(RS.Modules.Shared.ItemUtils)

-- Strip prefix from pData key: "Iron Sword|Godly" -> "Iron Sword"
local function SplitKey(k)
	return k:match("^(.+)|.+$") or k
end

local function GetMaxEnchants(baseName, itemType)
	local item = ContentLibrary[itemType] and ContentLibrary[itemType][baseName]
	return item and item.Config and item.Config.MaxEnchants
end

local function GetItemConfig(baseName, itemType)
	local item = ContentLibrary[itemType] and ContentLibrary[itemType][baseName]
	return item and item.Config
end

local function GetMaxLevel(enchantData)
	if enchantData.Levels then
		local max = 0
		for lvl in enchantData.Levels do if lvl > max then max = lvl end end
		return max
	end
	return enchantData.MaxLevel or 1
end

-- Resolve which cost table to use for apply (level 0→1) vs upgrade (level N→N+1).
--
-- Flat format — same table, apply = x1, upgrade at level N = xN:
--   Cost = { Statistics = {{"Gold",50}}, Material = {{"Iron",10}} }
--
-- Tiered format — [1]=apply, [2]=upgrade (amounts x currentLevel):
--   Cost = {
--     [1] = { Statistics = {{"Gold",50}}, Tool = {{"Bronze Sword",1}} },
--     [2] = { Statistics = {{"Gold",100}}, Material = {{"Iron",5}} },
--   }
local function ResolveCostTable(enchantData, currentLevel)
	local cost = enchantData.Cost
	if not cost then return nil end
	if cost[1] or cost[2] then
		if currentLevel == 0 then
			return cost[1] or cost[2], 1
		else
			return cost[2] or cost[1], currentLevel
		end
	end
	return cost, currentLevel == 0 and 1 or currentLevel
end

-- Validate that the player can afford the cost table (multiplied by `mult`).
-- Uses ItemUtils.FindItem for non-Statistics categories so prefix-reforged items
-- (e.g. "Bronze Sword|Godly") are matched transparently.
local function CanAfford(pd, costTable, mult)
	local Stats = pd:FindFirstChild("Stats")
	for Category, Items in costTable do
		if Category == "Statistics" then
			for _, entry in Items do
				local name, amount = entry[1], entry[2] * mult
				local sv = Stats and Stats:FindFirstChild(name)
				if not sv or sv.Value < amount then
					return false, "Not enough " .. name
				end
			end
		else
			if not GC.Categories[Category] then return false, "Invalid cost category: " .. Category end
			local folder = pd.Items:FindFirstChild(Category)
			for _, entry in Items do
				local name, amount = entry[1], entry[2] * mult
				-- Use ItemUtils so "Bronze Sword|Godly" matches "Bronze Sword"
				local iv = folder and ItemUtils.FindItem(folder, name)
				local owned = 0
				if iv then
					owned = iv:IsA("NumberValue") and math.max(0, iv.Value) or 1
				end
				if owned < amount then
					return false, "Not enough " .. name
				end
			end
		end
	end
	return true
end

-- Deduct the cost table (multiplied by `mult`) — only call after CanAfford passes.
-- For item categories, removes via the prefix-transparent ItemUtils.FindItem result.
local function DeductCost(pd, costTable, mult)
	local Stats = pd:FindFirstChild("Stats")
	for Category, Items in costTable do
		if Category == "Statistics" then
			for _, entry in Items do
				local name, amount = entry[1], entry[2] * mult
				local sv = Stats and Stats:FindFirstChild(name)
				if sv then sv.Value -= amount end
			end
		else
			local folder = pd.Items:FindFirstChild(Category)
			for _, entry in Items do
				local name, amount = entry[1], entry[2] * mult
				local iv = folder and ItemUtils.FindItem(folder, name)
				if iv then
					iv.Value = math.max(0, iv.Value - amount)
				end
			end
		end
	end
end

-- Check whitelist/blacklist/backdoor from ItemConfig against enchant name + item type.
local function CheckEnchantPermission(itemCfg, enchantName, enchantData, itemType)
	if not itemCfg then
		if enchantData.ValidTypes and not enchantData.ValidTypes[itemType] then
			return false, "This enchant cannot be applied to this item type"
		end
		return true
	end

	-- 1. Blacklist
	if itemCfg.EnchantBlacklist then
		for _, name in itemCfg.EnchantBlacklist do
			if name == enchantName then
				return false, "This item cannot receive the " .. enchantName .. " enchant"
			end
		end
	end

	-- 2. Backdoor
	if itemCfg.EnchantBackdoor then
		for _, name in itemCfg.EnchantBackdoor do
			if name == enchantName then return true end
		end
	end

	-- 3. Whitelist
	if itemCfg.EnchantWhitelist then
		local allowed = false
		for _, name in itemCfg.EnchantWhitelist do
			if name == enchantName then allowed = true break end
		end
		if not allowed then return false, "This item only accepts specific enchants" end
		return true
	end

	-- 4. ValidTypes
	if enchantData.ValidTypes and not enchantData.ValidTypes[itemType] then
		return false, "This enchant cannot be applied to this item type"
	end

	return true
end

local ValidEnchanters = {}
task.defer(function()
	for _, i in CS:GetTagged("Enchanter") do ValidEnchanters[i] = true end
	CS:GetInstanceAddedSignal("Enchanter"):Connect(function(i) ValidEnchanters[i] = true end)
	CS:GetInstanceRemovedSignal("Enchanter"):Connect(function(i) ValidEnchanters[i] = nil end)
end)

local PD
task.defer(function() PD = RS:WaitForChild("PlayerData", 10) end)

local Remotes = {}

function Remotes:OnEvent(Player, ItemType, ItemKey, EnchantName, EnchanterInstance)
	if typeof(ItemType) ~= "string" or typeof(ItemKey) ~= "string" or typeof(EnchantName) ~= "string" then return end
	if typeof(EnchanterInstance) ~= "Instance" then return end
	if not ValidEnchanters[EnchanterInstance] then return false, "Invalid enchanter" end

	if not EC or not EC.EligibleCategories or not EC.EligibleCategories[ItemType] then
		return false, "This item type cannot be enchanted"
	end

	local enchantData = EC.Enchants and EC.Enchants[EnchantName]
	if not enchantData then return false, "Unknown enchant" end

	-- Verify enchanter sells this enchant
	local nc = EnchanterInstance:FindFirstChild("Config") and require(EnchanterInstance.Config)
	if not nc then return false, "Enchanter not configured" end
	local sells = false
	if nc.Enchants then
		for _, name in nc.Enchants do
			if name == EnchantName then sells = true break end
		end
	end
	if not sells then return false, "This enchanter doesn't sell that enchant" end

	local pd = PD and PD:FindFirstChild(Player.UserId)
	if not pd then return end

	local folder = pd.Items:FindFirstChild(ItemType)
	local val = folder and folder:FindFirstChild(ItemKey)
	if not val then return false, "You don't own that item" end
	if val:IsA("NumberValue") and val.Value < 1 then return false, "You don't own that item" end

	local baseName    = SplitKey(ItemKey)
	local maxEnchants = GetMaxEnchants(baseName, ItemType)
	if not maxEnchants or maxEnchants <= 0 then return false, "This item cannot be enchanted" end

	local itemCfg = GetItemConfig(baseName, ItemType)
	local ok, err = CheckEnchantPermission(itemCfg, EnchantName, enchantData, ItemType)
	if not ok then return false, err end

	local attrKey      = "Enchant_" .. EnchantName
	local currentLevel = val:GetAttribute(attrKey) or 0
	local currentCount = 0
	for attrName in val:GetAttributes() do
		if attrName:sub(1, 8) == "Enchant_" then currentCount += 1 end
	end

	local maxLevel  = GetMaxLevel(enchantData)
	local isUpgrade = currentLevel > 0

	-- Block touching default enchants
	if val:GetAttribute("DefaultEnchant_" .. EnchantName) then
		return false, "This enchant is permanently bound to the item"
	end

	if isUpgrade and currentLevel >= maxLevel then
		return false, "Enchant is already at max level"
	end
	if not isUpgrade and currentCount >= maxEnchants then
		return false, "Item has reached its enchant limit"
	end

	-- Resolve and check cost
	local costTable, mult = ResolveCostTable(enchantData, currentLevel)
	if not costTable then
		return false, "No cost defined for this enchant"
	end

	local canAfford, affordErr = CanAfford(pd, costTable, mult)
	if not canAfford then return false, affordErr end

	DeductCost(pd, costTable, mult)
	val:SetAttribute(attrKey, currentLevel + 1)
	TagToolEnchants(Player, val)
	return true, currentLevel + 1
end

return Remotes
