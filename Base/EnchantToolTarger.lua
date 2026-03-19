-- EnchantToolTagger
-- Tags physical backpack/character tools with enchant attributes from a pData value.
-- For Armor/Accessory items (not physical Tools), re-triggers EnchantLib suites
-- so on-equip effects update immediately when an enchant is added or upgraded.
--
-- Armor equipped location:   pData.ActiveArmor        (StringValue = baseName)
-- Accessory equipped slots:  pData.EquippedSlots[idx] (StringValue = baseName, named "1","2",…)

local ServerStorage = game:GetService("ServerStorage")

-- Lazy-load EnchantLib to avoid circular requires
local _EnchantLib = nil
local function GetEnchantLib()
	if not _EnchantLib then
		_EnchantLib = require(ServerStorage.Modules.Libraries.Enchant)
	end
	return _EnchantLib
end

local function SplitKey(k)
	return k:match("^(.+)|.+$") or k
end

local function GetItemType(pDataValue)
	local folder = pDataValue.Parent
	return folder and folder.Name or nil
end

-- Sync enchant attributes onto physical Tool instances in Backpack / StarterGear / Character
local function TagTools(Player, baseName, enchants)
	local function tagList(list)
		for _, tool in list do
			if not tool:IsA("Tool") or tool.Name ~= baseName then continue end
			-- Clear all existing enchant + enchant-props attrs first
			for attrName in tool:GetAttributes() do
				if attrName:sub(1, 8) == "Enchant_" or attrName:sub(1, 13) == "EnchantProps_" then
					tool:SetAttribute(attrName, nil)
				end
			end
			-- Apply current enchants + custom props
			for attrName, attrVal in enchants do
				tool:SetAttribute(attrName, attrVal)
			end
		end
	end

	local Backpack    = Player:FindFirstChild("Backpack")
	local StarterGear = Player:FindFirstChild("StarterGear")
	local Character   = Player.Character
	if Backpack    then tagList(Backpack:GetChildren()) end
	if StarterGear then tagList(StarterGear:GetChildren()) end
	if Character   then tagList(Character:GetChildren()) end
end

-- Re-trigger armor enchant suites if this armor is currently equipped.
-- ArmorLib stores active armor in pData.ActiveArmor (StringValue).
local function RefreshArmorSuites(Player, pDataValue)
	local pd = pDataValue:FindFirstAncestor(tostring(Player.UserId))
	if not pd then return end
	local ActiveArmor = pd:FindFirstChild("ActiveArmor")
	if not ActiveArmor then return end
	local baseName = SplitKey(pDataValue.Name)
	if ActiveArmor.Value ~= baseName then return end -- not equipped
	local EL = GetEnchantLib()
	EL.OnArmorUnequipped(Player, nil, baseName, pDataValue)
	EL.OnArmorEquipped(Player, nil, baseName, pDataValue)
end

-- Re-trigger accessory enchant suites for every slot holding this accessory.
-- AccessoryLib stores equipped accessories in pData.EquippedSlots[idx] (StringValue).
local function RefreshAccessorySuites(Player, pDataValue)
	local pd = pDataValue:FindFirstAncestor(tostring(Player.UserId))
	if not pd then return end
	local EquippedSlots = pd:FindFirstChild("EquippedSlots")
	if not EquippedSlots then return end
	local baseName = SplitKey(pDataValue.Name)
	local EL = GetEnchantLib()
	for _, slot in EquippedSlots:GetChildren() do
		local idx = tonumber(slot.Name) -- slot name is "1", "2", …
		if idx and slot.Value == baseName then
			EL.OnAccessoryUnequipped(Player, nil, baseName, pDataValue, idx)
			EL.OnAccessoryEquipped(Player, nil, baseName, pDataValue, idx)
		end
	end
end

-- Main export
return function(Player, pDataValue)
	local baseName = SplitKey(pDataValue.Name)
	local itemType = GetItemType(pDataValue)

	-- Collect all enchant + EnchantProps attributes from the pData value
	local enchants = {}
	for attrName, attrVal in pDataValue:GetAttributes() do
		if attrName:sub(1, 8) == "Enchant_" or attrName:sub(1, 13) == "EnchantProps_" then
			enchants[attrName] = attrVal
		end
	end

	if itemType == "Tool" or itemType == "Weapon" then
		-- Physical item: sync attributes directly onto Tool instances in Backpack/Character
		TagTools(Player, baseName, enchants)

	elseif itemType == "Armor" then
		-- Non-physical: re-trigger armor enchant suites if currently equipped
		task.spawn(RefreshArmorSuites, Player, pDataValue)

	elseif itemType == "Accessory" then
		-- Non-physical: re-trigger accessory enchant suites for each matching slot
		task.spawn(RefreshAccessorySuites, Player, pDataValue)

	else
		-- Unknown category — fallback to physical tool tagging
		TagTools(Player, baseName, enchants)
	end
end
