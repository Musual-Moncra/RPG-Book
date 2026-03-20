-- [CLIENT]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Temporary = workspace:WaitForChild("Temporary")

local Keybind = {}
function Keybind:OnActivated(Player) end
function Keybind:OnLetGo(Player)
	local Character = Player.Character
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then return end

	SFX:Play3D(9066732918, Torso.Position, {MaxDistance = 150, MinDistance = 20, Pitch = 0.5})

	-- Make invisible
	for _, child in Character:GetDescendants() do
		if child:IsA("BasePart") or child:IsA("Decal") then
			if child.Name ~= "HumanoidRootPart" then
				Tween:Play(child, {0.2}, {Transparency = 1})
			end
		end
	end
	
	task.delay(5, function()
		if Character and Character:FindFirstChild("Torso") then
			SFX:Play3D(12222030, Character.Torso.Position, {MaxDistance = 150, MinDistance = 20, Volume = 2})
			-- Fade back
			for _, child in Character:GetDescendants() do
				if child:IsA("BasePart") or child:IsA("Decal") then
					if child.Name ~= "HumanoidRootPart" then
						Tween:Play(child, {0.2}, {Transparency = 0})
					end
				end
			end
            -- Slash effect
			local Slash = Instance.new("Part")
			Slash.Material = Enum.Material.Neon
			Slash.Color = Color3.fromRGB(150, 0, 255)
			Slash.Size = Vector3.new(1, 25, 1)
			Slash.Anchored = true
			Slash.CanCollide = false
			Slash.Position = Character.Torso.Position
			Slash.Orientation = Vector3.new(0, 45, 90)
			Slash.Parent = Temporary
			Debris:AddItem(Slash, 0.5)
			Tween:Play(Slash, {0.3, "Quad", "Out"}, {Size = Vector3.new(0, 40, 1), Transparency = 1})
		end
	end)
end
return Keybind
