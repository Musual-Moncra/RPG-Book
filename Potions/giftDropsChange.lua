--[[
	ej0w @ October 2024
	GiftDrops
	
	Acts as a suite to give items based on a universal table type,
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GetPlayerLuck = require(ReplicatedStorage.Modules.Shared.getPlayerLuck)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local GetStatMultiplier = require(ReplicatedStorage.Modules.Shared.getStatMultiplier)

local GiveItemWithAmount = require(ServerStorage.Modules.Server.giveItemWithAmount)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Libraries = {}
for _, Module in ServerStorage.Modules.Libraries["items [Subcategories]"]:GetChildren() do
	Libraries[Module.Name] = require(Module)
end

local LeaderstatIcons = GameConfig.LeaderstatIcons
local Random = Random.new()

--------------------------------------------------------------------------------

local function AlertChat(Color, Text)
	EventModule:FireAllClients("ChatAlert", Color or Color3.fromRGB(238, 238, 238), Text)
end

return function(Player: Player, Drops, NoStatNotif, CanMultiply, UseGlobalDrops)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end
	
	local Items = pData:FindFirstChild("Items")
	if not Items then return end
	
	local BoostLuck = Player:WaitForChild("Statuses").Luck:GetAttribute("Addition") or 1
	local BoostXP = Player:WaitForChild("Statuses").Experience:GetAttribute("Addition") or 1
	
	local Products = ProductLib:GetProducts(Player)
	local AllocatedLuck = GetPlayerLuck(Products) * (1 + BoostLuck)
	
	local CanMakeSFX = false
	
	---- Drop statistics
	
	if Drops.Statistics then
		for _, Stat in Drops.Statistics do
			local ItemName: string = Stat[1]
			local DropAmount: number = Stat[2]
			local DropChance: number = Stat[3]
			local OnlyOnce: boolean = Stat[4]
			
			local IconData = LeaderstatIcons[ItemName]
			
			if ItemName == "XP" then
				DropAmount = DropAmount * (1 + BoostXP)
			end
			
			local Statistic = pData.Stats:FindFirstChild(ItemName)
			if Statistic then
				local NewDropAmount = typeof(DropAmount) == "table" and Random:NextInteger(DropAmount[1], DropAmount[2]) or DropAmount or 1
				if NewDropAmount <= 0 then
					continue
				end
				
				if DropChance then
					local ChanceModifier = math.max(math.round(DropChance / AllocatedLuck), 1)

					local ObtainedDrop = Random:NextInteger(1, ChanceModifier) == 1
					if not ObtainedDrop then
						continue
					end
				end
				
				if Statistic.Value >= 1 and OnlyOnce then
					continue
				end
				
				if not NoStatNotif then
					EventModule:FireClient("SendNotification",
						Player, 
						"Stat Dropped", 
						`{ItemName} <font transparency="0.2">(x{FormatNumber(NewDropAmount, "Suffix")})</font> at a {typeof(DropChance) == "table" and DropChance[1] or 1}/{FormatNumber(typeof(DropChance) == "table" and DropChance[2] or DropChance or 1, "Suffix")} chance.`, 
						IconData and IconData.Image, 
						true,
						IconData and (IconData.Color or GameConfig.UIColors.PrimaryColor)
					)
					
					CanMakeSFX = true
				end

				local NewStatCount = CanMultiply and GetStatMultiplier(Products, Statistic, NewDropAmount) or NewDropAmount
				Statistic.Value += NewStatCount
			end
		end
	end
	
	---- Drop items
	
	if Drops.Items or UseGlobalDrops then
		for _, Table in {Drops.Items, UseGlobalDrops and GameConfig.GlobalDrops} do
			for _, ItemInfo in Table do
				local ItemType: string = ItemInfo[1]
				local ItemName: string = ItemInfo[2]
				local DropAmount: number = ItemInfo[3]
				local DropChance: number = ItemInfo[4]
				local OnlyOnce: boolean = ItemInfo[5]

				local ContentItem = ContentLibrary[ItemType][ItemName]
				if ContentItem then 
					local NewDropAmount = typeof(DropAmount) == "table" and Random:NextInteger(DropAmount[1], DropAmount[2]) or DropAmount or 1
					if NewDropAmount <= 0 then
						continue
					end
					
					local ItemValue = Items[ItemType]:FindFirstChild(ItemName)
					if not ItemValue then
						-- Also check for a prefixed version e.g. "Iron Sword|Godly"
						for _, child in Items[ItemType]:GetChildren() do
							if child.Name:match("^(.+)|.+$") == ItemName then
								ItemValue = child
								break
							end
						end
					end
					if ItemValue and (OnlyOnce or ContentItem.Config.AwardableOnce or (not GameConfig.CanItemsStack and not GameConfig.Categories[ItemType].IsStackable)) then
						continue
					end
					
					if DropChance then
						local RealDropChance = typeof(DropChance) == "table" and (DropChance[2] - DropChance[1]) + 1 or DropChance
						local ChanceModifier = math.max(math.round(RealDropChance / AllocatedLuck), 1)

						local ObtainedDrop = Random:NextInteger(1, ChanceModifier) == 1
						if not ObtainedDrop then
							continue
						end
						
						if GameConfig.ServerDropNotifications and RealDropChance >= GameConfig.ChanceRequiredToNotifyServer then
							AlertChat(
								ContentItem.Config.SpecialColor or GameConfig.Categories[ItemType].Color, 
								`{Player.DisplayName} has dropped a(n) {ItemName} x{NewDropAmount} at a 1/{FormatNumber(RealDropChance, "Suffix")} chance!`
							)
						end
					end

					EventModule:FireClient("SendNotification",
						Player, 
						`{ItemType} Dropped`, 
						`{ItemName} <font transparency="0.2">(x{FormatNumber(NewDropAmount, "Suffix")})</font> at a {typeof(DropChance) == "table" and DropChance[1] or 1}/{FormatNumber(typeof(DropChance) == "table" and DropChance[2] or DropChance or 1, "Suffix")} chance.`, 
						ContentItem.Config.IconId, 
						true
					)
					
					CanMakeSFX = true
					GiveItemWithAmount(Player, ItemType, ItemName, NewDropAmount)
				end
			end
		end
	end
	
	if CanMakeSFX then
		SFX:Play2D(GameConfig.DropItemSFX[1], Player, {Volume = GameConfig.DropItemSFX[2]})
	end
	return true
end
