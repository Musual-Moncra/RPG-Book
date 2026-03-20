-- [CLIENT] OmniSlash
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

	-- Phase 1: Dash
	SFX:Play3D(9125644676, Torso.Position, {MaxDistance = 150, MinDistance = 30, Pitch = 1.5})
	local DashTrail = Instance.new("Part")
	DashTrail.Material = Enum.Material.Neon
	DashTrail.Color = Color3.fromRGB(200, 200, 255)
	DashTrail.Size = Vector3.new(1, Torso.CFrame.LookVector.Magnitude * 40, 3)
	DashTrail.Anchored = true
	DashTrail.CanCollide = false
	DashTrail.CFrame = Torso.CFrame * CFrame.new(0,0,-20) * CFrame.Angles(math.rad(90), 0, 0)
	DashTrail.Parent = Temporary
	Debris:AddItem(DashTrail, 0.5)
	Tween:Play(DashTrail, {0.3}, {Size = Vector3.new(0, 40, 0), Transparency = 1})

	-- Phase 2: 15 Slashes around the area (approx 40 studs ahead)
	local CenterPos = Torso.Position + Torso.CFrame.LookVector * 40
	task.delay(0.3, function()
		for i = 1, 15 do
			task.delay(i*0.1, function()
				SFX:Play3D(9116385079, CenterPos, {MaxDistance = 150, MinDistance = 30, Pitch = math.random(1.2, 1.8), Volume = 0.8})
				local Slash = Instance.new("Part")
				Slash.Material = Enum.Material.Neon
				Slash.Color = Color3.fromRGB(150, 200, 255)
				Slash.Size = Vector3.new(0.5, 25, 2)
				Slash.Anchored = true
				Slash.CanCollide = false
				Slash.CFrame = CFrame.new(CenterPos + Vector3.new(math.random(-10,10), math.random(0,10), math.random(-10,10))) * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))
				Slash.Parent = Temporary
				Debris:AddItem(Slash, 0.3)
				Tween:Play(Slash, {0.2}, {Size = Vector3.new(0, 40, 0), Transparency = 1})
			end)
		end
	end)

	-- Phase 3: Giant Sword Slam
	task.delay(2.2, function()
		SFX:Play3D(12222030, CenterPos, {MaxDistance = 300, MinDistance = 50, Pitch = 0.5, Volume = 2})
		local GiantSword = Instance.new("Part")
		GiantSword.Material = Enum.Material.Neon
		GiantSword.Color = Color3.fromRGB(100, 150, 255)
		GiantSword.Size = Vector3.new(5, 50, 10)
		GiantSword.Anchored = true
		GiantSword.CanCollide = false
		GiantSword.CFrame = CFrame.new(CenterPos + Vector3.new(0, 60, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
		GiantSword.Parent = Temporary
		Debris:AddItem(GiantSword, 2)

		Tween:Play(GiantSword, {0.3, "Quad", "In"}, {
			CFrame = CFrame.new(CenterPos) * CFrame.Angles(math.rad(-90), 0, 0)
		})

		task.delay(0.3, function()
			SFX:Play3D(9066732918, CenterPos, {MaxDistance = 300, MinDistance = 50, Volume = 3})
			local Explosion = Instance.new("Part")
			Explosion.Material = Enum.Material.Neon
			Explosion.Color = Color3.fromRGB(150, 200, 255)
			Explosion.Shape = Enum.PartType.Ball
			Explosion.Size = Vector3.one * 10
			Explosion.Anchored = true
			Explosion.CanCollide = false
			Explosion.Position = CenterPos
			Explosion.Parent = Temporary
			Debris:AddItem(Explosion, 1)

			Tween:Play(Explosion, {0.5, "Quad", "Out"}, {
				Size = Vector3.one * 60, Transparency = 1
			})
			Tween:Play(GiantSword, {0.5, "Quad", "Out"}, {Transparency = 1})
		end)
	end)
end
return Keybind
