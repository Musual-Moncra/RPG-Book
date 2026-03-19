--[[
	Evercyan @ March 2023 / updated for prefix stacking
	ToolLib
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local ItemUtils = require(ReplicatedStorage.Modules.Shared.ItemUtils)
local CreateValue = require(ServerStorage.Modules.Server.createValue)
local RemoveValue = require(ServerStorage.Modules.Server.removeValue)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Library = script.Name
local ToolLib = {}

--------------------------------------------------------------------------------

-- True if the physical tool already lives anywhere on the player
local function hasPhysicalTool(player, toolName)
	local sg = player:FindFirstChild("StarterGear")
	if sg and sg:FindFirstChild(toolName) then return true end
	local bp = player:FindFirstChild("Backpack")
	if bp and bp:FindFirstChild(toolName) then return true end
	if player.Character and player.Character:FindFirstChild(toolName) then return true end
	return false
end

function ToolLib:Give(Player, Tool, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)

	if Tool == nil then
		-- Most likely cause: ContentLibrary.Weapon["Name"] returned nil.
		-- Check that the item name is correct AND that it belongs to the
		-- "Weapon" category (script.Name). Items under "Tool" category
		-- live in ContentLibrary.Tool, not ContentLibrary.Weapon.
		warn(("[WeaponLib] Give called with nil Tool for player '%s'. " ..
			"Did you look up the item in the wrong ContentLibrary category? " ..
			"This library uses category '%s' — make sure your item exists under ContentLibrary.%s.")
			:format(Player.Name, Library, Library))
		return
	end

	if typeof(Tool) ~= "table" then
		warn(("[WeaponLib] Give: Tool is not a table (got %s). Use ContentLibrary.%s[\"ItemName\"].")
			:format(typeof(Tool), Library))
		return
	end

		if pData then
		local Found = ItemUtils.FindItem(pData.Items[Library], Tool.Name)
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = (not Found) or IsStackable
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Tool.Config.Cost[4]) and IsStackable)


		if CanGive or CanBuyMultiple then
			local vo = CreateValue(pData, Tool, DontSave, Amount, Library)

			if not hasPhysicalTool(Player, Tool.Name) then
				local StarterGear = Player:FindFirstChild("StarterGear")
				if StarterGear then Tool.Instance:Clone().Parent = StarterGear end
				local Backpack = Player:WaitForChild("Backpack")
				if Backpack then Tool.Instance:Clone().Parent = Backpack end
			end

			return vo
		else
		end
	else
		warn("pData for Player '" .. Player.Name .. "' doesn't exist! Did they leave?")
	end
end

function ToolLib:Trash(Player, Tool, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)

	if pData then
		RemoveValue(pData, Tool, Amount, Library)

		local CompletelyRemoved = not ItemUtils.FindItem(pData.Items[Library], Tool.Name)
		if CompletelyRemoved then
			if Player.StarterGear:FindFirstChild(Tool.Name) then
				Player.StarterGear[Tool.Name]:Destroy()
			end
			if Player.Backpack:FindFirstChild(Tool.Name) then
				Player.Backpack[Tool.Name]:Destroy()
			end
			if Player.Character and Player.Character:FindFirstChild(Tool.Name) then
				Player.Character[Tool.Name]:Destroy()
			end
		end
	else
		warn("pData for Player '" .. Player.Name .. "' doesn't exist! Did they leave?")
	end
end

return ToolLib