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

	SFX:Play3D(12222030, Torso.Position, {MaxDistance = 100, MinDistance = 20})

	for i = 1, 3 do
		Character.Archivable = true
		local Clone = Character:Clone()
		Character.Archivable = false
		Clone.Name = "MirrorImage"
		
		for _, child in Clone:GetDescendants() do
			if child:IsA("BasePart") then
				child.Material = Enum.Material.ForceField
				child.Color = Color3.fromRGB(150, 150, 150)
				child.Anchored = true
				child.CanCollide = false
			elseif child:IsA("Script") or child:IsA("LocalScript") then
				child:Destroy()
			end
		end
		
		Clone.Parent = Temporary
		Debris:AddItem(Clone, 4)
		
		local Angle = math.rad(i * 120)
		local EndPos = Torso.Position + Vector3.new(math.cos(Angle)*20, 0, math.sin(Angle)*20)
		
		Tween:Play(Clone.PrimaryPart, {1, "Quad", "Out"}, {
			CFrame = CFrame.new(EndPos)
		})
		
		task.delay(4, function()
			if Clone and Clone.Parent then
				SFX:Play3D(9116385079, Clone:GetPivot().Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8})
				local Expl = Instance.new("Part")
				Expl.Material = Enum.Material.Neon
				Expl.Color = Color3.fromRGB(150, 150, 150)
				Expl.Shape = Enum.PartType.Ball
				Expl.Size = Vector3.one * 5
				Expl.Anchored = true
				Expl.CanCollide = false
				Expl.Position = Clone:GetPivot().Position
				Expl.Parent = Temporary
				Debris:AddItem(Expl, 0.5)

				Tween:Play(Expl, {0.3, "Quad", "Out"}, {
					Size = Vector3.one * 20, Transparency = 1
				})
			end
		end)
	end
end
return Keybind
