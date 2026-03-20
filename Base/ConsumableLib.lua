--[[
	ej0w @ May 2024
	ConsumableLib
	
	This is where consumables, e.g. apple, potions, etc. are managed.
	Add new functions under the module under this script, called Consumes
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local CreateValue = require(ServerStorage.Modules.Server.createValue)
local RemoveValue = require(ServerStorage.Modules.Server.removeValue)

local GameConfig = require(ReplicatedStorage.GameConfig)
local Consumes = require(script.Suites)

local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Config
local Library = script.Name

local ConsumableLib = {}
local Cooldown = {}

--------------------------------------------------------------------------------

local function RequestClearTool(Player, Tool)
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

function ConsumableLib:Give(Player: Player, Tool, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Tool) == "table" 
	if not isItem then
		warn(`Item {Library} --> {tostring(Tool) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		local Found = pData.Items[Library]:FindFirstChild(Tool.Name)
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = ((not Found) or IsStackable)
		
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Tool.Config.Cost[4]) and IsStackable)
		if CanGive or CanBuyMultiple then
			CreateValue(pData, Tool, DontSave, Amount, Library)

			local StarterGear = Player:FindFirstChild("StarterGear")
			if StarterGear and not StarterGear:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = StarterGear
			end

			local Backpack = Player:WaitForChild("Backpack")
			if Backpack and not Backpack:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = Backpack
			end

			return true
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ConsumableLib:Trash(Player: Player, Tool, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)

	if pData then
		RemoveValue(pData, Tool, Amount, Library)
		
		local NewTool = ContentLibrary[Library][Tool.Name].Instance
		
		local isRemoved = not pData.Items[Library]:FindFirstChild(Tool.Name)
		if not isRemoved then
			task.defer(function()
				NewTool:Clone().Parent = Player.StarterGear
				NewTool:Clone().Parent = Player.Backpack
			end)
		end
		
		RequestClearTool(Player, Tool)
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ConsumableLib:Commit(Player, Consumable: Model)
	local Character = Player.Character
	
	if not Consumable:IsDescendantOf(Character) and not Consumable:IsDescendantOf(Player) then 
		return
	end
	
	-- Get tool
	local ItemConfig = Consumable:FindFirstChild("ItemConfig") and require(Consumable.ItemConfig)
	if not ItemConfig or not ItemConfig.Suite or ItemConfig.Type ~= "Consumable" then 
		return 
	end
	
	-- Cooldown
	local ItemCooldown = ItemConfig.Cooldown or 1
	Cooldown[Player] = (Cooldown[Player] or {})
	
	local CurrentCooldown = Cooldown[Player][Consumable.Name]
	if CurrentCooldown and os.clock() - CurrentCooldown < ItemCooldown then
		return
	end
	
	Cooldown[Player][Consumable.Name] = os.clock()
	
	-- Get suite
	local Suite = ItemConfig.Suite
	local Process = Suite[1]
	local Properties = Suite[2]
	
	-- Commit function
	local Function = Consumes[Process]
	if Function then
		task.spawn(Function, nil, Player, Consumable, Properties)
	end
	
	-- Trash
	if not ItemConfig.Reusable then
		ConsumableLib:Trash(Player, Consumable)
	end
end

EventModule:GetOnServerEvent("PlayerConsumedItem"):Connect(function(Player, Consumable)
	if typeof(Consumable) ~= "Instance" then
		return
	end

	-- SECURITY: verify the player actually owns this consumable in pData before committing.
	-- The physical presence check in Commit() (IsDescendantOf Character/Player) is necessary
	-- but not sufficient — a bug elsewhere could put an untracked tool in the backpack, letting
	-- a player consume items they never legitimately received without deducting from pData.
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end

	local ConsumableFolder = pData.Items:FindFirstChild("Consumable")
	local ItemValue = ConsumableFolder and ConsumableFolder:FindFirstChild(Consumable.Name)
	local isOwned = ItemValue and (not ItemValue:IsA("NumberValue") or ItemValue.Value >= 1)
	if not isOwned then return end

	ConsumableLib:Commit(Player, Consumable)
end)

-- if you're reading this u deserve to be loved and appreciated u r amazing
	
return ConsumableLib