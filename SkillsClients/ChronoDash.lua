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

	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8, Pitch = 2})

	local StartPos = Torso.Position
	local Forward = Torso.CFrame.LookVector
	
	-- Create 3 Echoes
	for i = 1, 3 do
		local EchoPos = StartPos + (Forward * (i * 10))
		
		Character.Archivable = true
		local Clone = Character:Clone()
		Character.Archivable = false
		Clone.Name = "ChronoEcho"
		
		for _, child in Clone:GetDescendants() do
			if child:IsA("BasePart") then
				child.Material = Enum.Material.ForceField
				child.Color = Color3.fromRGB(150, 200, 255)
				child.Anchored = true
				child.CanCollide = false
			elseif child:IsA("Script") or child:IsA("LocalScript") then
				child:Destroy()
			end
		end
		
		Clone:PivotTo(CFrame.new(EchoPos, EchoPos + Forward))
		Clone.Parent = Temporary
		Debris:AddItem(Clone, 1.5)
		
		task.delay(1.2, function()
			if Clone and Clone.Parent then
				SFX:Play3D(9116385079, Clone:GetPivot().Position, {MaxDistance = 100, MinDistance = 20, Volume = 0.8})
				local Expl = Instance.new("Part")
				Expl.Material = Enum.Material.Neon
				Expl.Color = Color3.fromRGB(150, 200, 255)
				Expl.Shape = Enum.PartType.Ball
				Expl.Size = Vector3.one * 2
				Expl.Anchored = true
				Expl.CanCollide = false
				Expl.Position = Clone:GetPivot().Position
				Expl.Parent = Temporary
				Debris:AddItem(Expl, 0.5)

				Tween:Play(Expl, {0.2, "Quad", "Out"}, {
					Size = Vector3.one * 15, Transparency = 1
				})
			end
		end)
	end
end
return Keybind
