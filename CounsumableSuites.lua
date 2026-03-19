--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> Variables
local Consumes = {}

--------------------------------------------------------------------------------
-- Utilities

local function PotionBase(Tool)
	Tool.Handle.Weld:Destroy()
	Tool.Liquid:Destroy()
	Tool.Cork:Destroy()
	
	local Bottle = Tool.Handle:clone()
	Bottle.CanCollide = true
	Bottle.Parent = workspace.Temporary
	Bottle.CFrame = CFrame.new(Tool.Handle.Position)
	
	task.delay(3, function()
		Bottle:Destroy()
	end)
	task.delay(0.2, function()
		SFX:Play3D(11415738, Bottle.Position)
	end)
	
	return Bottle
end

--------------------------------------------------------------------------------
-- Callbacks

-- One time healing
function Consumes:Healing(Player, Tool, Properties)
	local Health = Properties.Health

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if not Humanoid then return end

	Humanoid.Health = math.clamp(Humanoid.Health + Health, 0, Humanoid.MaxHealth)
end

-- Regenative/realhp healing
function Consumes:Health(Player, Tool, Properties)
	if string.find(Tool.Name, "Potion") then
		PotionBase(Tool)
	end
	
	local Boost = Properties.Boost
	local Percentage = Properties.Percentage
	local Duration = Properties.Duration
	
	-- Heal percentage of health
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if not Humanoid then 
		return 
	end
	if Percentage then
		local Health = Humanoid.MaxHealth * Percentage
		Humanoid.Health = math.clamp(Humanoid.Health + Health, 0, Humanoid.MaxHealth)
	end
	
	-- Get effects registry
	local Statuses = Player:WaitForChild("Statuses", 1)
	local Effect = Statuses and Statuses:WaitForChild("Regeneration")
	if Effect then 
		Effect:SetAttribute("Duration", Effect:GetAttribute("Duration") + Duration)
		Effect:SetAttribute("Boost", Boost)
	end
end

function Consumes:Mana(Player, Tool, Properties)
	PotionBase(Tool)

	-- Properties
	local Addition = Properties.Addition
	local Duration = Properties.Duration

	-- Get effects registry
	local Statuses = Player:WaitForChild("Statuses", 1)
	if not Statuses then 
		return 
	end

	-- Set effect
	local Effect = Statuses:WaitForChild("Mana")
	Effect:SetAttribute("Duration", Effect:GetAttribute("Duration") + Duration)
	Effect:SetAttribute("Addition", Addition)
end

function Consumes:Strength(Player, Tool, Properties)
	PotionBase(Tool)
	
	-- Properties
	local Multiplier = Properties.Multiplier
	local Duration = Properties.Duration
	
	-- Get effects registry
	local Statuses = Player:WaitForChild("Statuses", 1)
	if not Statuses then 
		return 
	end
	
	-- Set effect
	local Effect = Statuses:WaitForChild("Strength")
	Effect:SetAttribute("Duration", Effect:GetAttribute("Duration") + Duration)
	Effect:SetAttribute("Boost", Multiplier)
end

return Consumes