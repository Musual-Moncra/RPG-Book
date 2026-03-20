-- [CLIENT] --> Shared to all clients

--> References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> References
local Temporary = workspace:WaitForChild("Temporary")

--> Variables
local Keybind = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Characters"), workspace:WaitForChild("Temporary"),
	workspace:WaitForChild("Mobs"), workspace.Zones, workspace.Teleports, workspace.Map.Doors
}
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.RespectCanCollide = true

local Duration = 1.5

--------------------------------------------------------------------------------

-- Callbacks
local function Floor(Position: Vector3)
	local Raycast = workspace:Raycast(Position + Vector3.new(0, 25, 0), Vector3.new(0, -1000, 0), RaycastParams)
	return Raycast and Raycast.Position, Raycast
end

-- Ran when activated
function Keybind:OnActivated(Player)
	
end

function Keybind:OnLetGo(Player)
	local Character = Player.Character

	local Position = Character 
		and Character:FindFirstChild("Torso")
		and Character.Torso.Position

	if not Position then 
		return
	end

	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer.Character or ((LocalPlayer.Character:GetPivot().Position - Position).Magnitude > GameConfig.DefaultDistanceRadius * 1.25) then
		return
	end

	SFX:Play3D(9125644676, Position, {MaxDistance = 100, MinDistance = 20})

	do
		local Object = Instance.new("Part")
		Object.Name = "Darkvoid_Shadow"
		Object.Material = Enum.Material.Granite
		Object.Color = Color3.fromRGB(0, 0, 0)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 1
		Object.Size = Vector3.one * 2
		Object.Position = Position
		Object.Orientation = Vector3.one * math.random(-70, 70)

		Tween:Play(Object, {0.05}, {Transparency = 0.7})

		task.delay(0.05, function()
			Tween:Play(Object, {0.5, "Circular"}, {
				Transparency = 1, 
				Size = Vector3.one * 10, 
				Orientation = Vector3.one * math.random(-20, 20)
			})
		end)

		Object.Parent = Temporary

		Debris:AddItem(Object, 2)
	end

	do
		local Object = Instance.new("Part")
		Object.Name = "Darkvoid_Main"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(0, 0, 0)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 1
		Object.Size = Vector3.one * 2
		Object.Position = Position
		Object.Orientation = Vector3.one * math.random(-70, 70)

		Tween:Play(Object, {0.05}, {Transparency = 0.4})

		task.delay(0.05, function()
			Tween:Play(Object, {0.3, "Circular"}, {
				Transparency = 1, 
				Size = Vector3.one * 4, 
				Orientation = Vector3.one * math.random(-20, 20)
			})
		end)

		Object.Parent = Temporary

		Debris:AddItem(Object, 2)
	end

	do
		local Object = Instance.new("Part")
		Object.Name = "Darkvoid_Shockwave"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(0, 0, 0)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Position = Floor(Position)

		Object.Size = Vector3.new(2, 40, 40)
		Object.Shape = Enum.PartType.Cylinder
		Object.Orientation = Vector3.new(0, 90, 90)

		Tween:Play(Object, {0.7 * Duration, "Circular", "In"}, {
			Transparency = 0.95,
			Size = Vector3.zero, 
		})

		Object.Transparency = 0.9
		Object.Parent = Temporary

		Debris:AddItem(Object, 2)
	end

	do
		local Object = Instance.new("Part")
		Object.Name = "Darkvoid_Secondary"
		Object.Material = Enum.Material.ForceField
		Object.Color = Color3.fromRGB(0, 0, 0)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 1
		Object.Size = Vector3.one * 2
		Object.Position = Position
		Object.Shape = Enum.PartType.Ball
		Object.Orientation = Vector3.one * math.random(-70, 70)

		Tween:Play(Object, {0.05}, {Transparency = 0.9})

		task.delay(0.05, function()
			Tween:Play(Object, {0.4 * Duration, "Circular", "Out"}, {
				Size = Vector3.one * 20, 
				Orientation = Vector3.one * math.random(-20, 20)
			})

			task.wait(0.4 * Duration)

			Tween:Play(Object, {0.4 * Duration, "Circular", "In"}, {
				Transparency = 0.95,
				Size = Vector3.zero, 
				Orientation = Vector3.zero
			})

			task.wait(0.35)

			SFX:Play3D(9066732918, Position, {MaxDistance = 100, MinDistance = 20})
		end)

		Object.Parent = Temporary

		Debris:AddItem(Object, 2)
	end

	do
		local Object = Instance.new("Part")
		Object.Name = "Darkvoid_Tertiary"
		Object.Material = Enum.Material.Neon
		Object.Color = Color3.fromRGB(0, 0, 0)
		Object.Anchored = true
		Object.CastShadow = false
		Object.CanCollide = false
		Object.Transparency = 1
		Object.Size = Vector3.one * 2
		Object.Position = Position
		Object.Shape = Enum.PartType.Ball
		Object.Orientation = Vector3.one * math.random(-70, 70)

		Tween:Play(Object, {0.05}, {Transparency = 0.9})

		task.delay(0.05, function()
			Tween:Play(Object, {0.35 * Duration, "Circular", "Out"}, {
				Size = Vector3.one * 18, 
				Orientation = Vector3.one * math.random(-20, 20)
			})

			task.wait(0.35 * Duration)

			Tween:Play(Object, {0.35 * Duration, "Circular", "In"}, {
				Transparency = 0.7,
				Size = Vector3.zero, 
				Orientation = Vector3.zero
			})
		end)

		Object.Parent = Temporary

		Debris:AddItem(Object, 2)
	end

	do
		task.delay(0.7 * Duration, function()
			local Object = Instance.new("Part")
			Object.Name = "Darkvoid_Tertiary"
			Object.Material = Enum.Material.Neon
			Object.Color = Color3.fromRGB(0, 0, 0)
			Object.Anchored = true
			Object.CastShadow = false
			Object.CanCollide = false
			Object.Transparency = 1
			Object.Size = Vector3.one * 2
			Object.Position = Position
			Object.Shape = Enum.PartType.Ball
			Object.Orientation = Vector3.one * math.random(-70, 70)

			Tween:Play(Object, {0.05}, {Transparency = 0.9})

			task.delay(0.05, function()
				Tween:Play(Object, {0.35, "Circular", "Out"}, {
					Size = Vector3.one * 7, 
					Orientation = Vector3.one * math.random(-20, 20)
				})

				task.wait(0.35)

				Tween:Play(Object, {0.35, "Circular", "In"}, {
					Transparency = 0.7,
					Size = Vector3.zero, 
					Orientation = Vector3.zero
				})
			end)

			Object.Parent = Temporary

			Debris:AddItem(Object, 2)
		end)
	end

	do
		task.delay(0.7 * Duration, function()
			local Object = Instance.new("Part")
			Object.Name = "Darkvoid_Secondary"
			Object.Material = Enum.Material.ForceField
			Object.Color = Color3.fromRGB(0, 0, 0)
			Object.Anchored = true
			Object.CastShadow = false
			Object.CanCollide = false
			Object.Transparency = 1
			Object.Size = Vector3.one * 2
			Object.Position = Position
			Object.Shape = Enum.PartType.Ball
			Object.Orientation = Vector3.one * math.random(-70, 70)

			Tween:Play(Object, {0.05}, {Transparency = 0.9})

			task.delay(0.05, function()
				Tween:Play(Object, {0.4, "Circular", "Out"}, {
					Size = Vector3.one * 12, 
					Orientation = Vector3.one * math.random(-20, 20)
				})

				task.wait(0.4)

				Tween:Play(Object, {0.4, "Circular", "In"}, {
					Transparency = 0.95,
					Size = Vector3.zero, 
					Orientation = Vector3.zero
				})
			end)

			Object.Parent = Temporary

			Debris:AddItem(Object, 2)
		end)
	end

	do
		for Iteration = 1, 3 do
			task.delay(0.7 * Duration, function()
				local Object = Instance.new("Part")
				Object.Name = "Darkvoid_Main_Outward"
				Object.Material = Enum.Material.Neon
				Object.Color = Color3.fromRGB(189, 189, 189)
				Object.Anchored = true
				Object.CastShadow = false
				Object.CanCollide = false

				Object.Shape = Enum.PartType.Ball
				Object.Size = Vector3.zero
				Object.Position = Position + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))

				Object.Transparency = 0.7
				Object.Orientation = Vector3.one * math.random(-90, 90)

				task.delay(0.05, function()
					Tween:Play(Object, {0.7, "Circular", "Out"}, {
						Transparency = 1, 
						Size = Vector3.one * math.random(3, 5), 
						Orientation = Vector3.one * math.random(-20, 20)
					})

					task.delay(0.1, function()
						local Sounds = {9116385079, 9116385087, 9116385056}
						SFX:Play3D(Sounds[math.random(#Sounds)], Object.Position, {Volume = 0.6, MaxDistance = 100, MinDistance = 20})
					end)

					task.delay(0.3, function()
						local _Object = Instance.new("Part")
						_Object.Name = "Darkvoid_Beam"
						_Object.Material = Enum.Material.Neon
						_Object.Color = Color3.fromRGB(189, 189, 189)
						_Object.Anchored = true
						_Object.CastShadow = false
						_Object.CanCollide = false

						_Object.Shape = Enum.PartType.Cylinder
						_Object.Size = Vector3.new(0, Object.Size.Y, Object.Size.Y)
						_Object.Position = Object.Position

						_Object.Transparency = 0.7
						_Object.Orientation = Vector3.new(0, 90, 90)

						Tween:Play(_Object, {0.7, "Circular", "Out"}, {
							Transparency = 1, 
							Size = Vector3.new(100, Object.Size.Y, Object.Size.Y), 
						})

						_Object.Parent = Temporary

						Debris:AddItem(_Object, 2)
					end)

					task.delay(0.2, function()
						do
							local __Object = Instance.new("Part")
							__Object.Name = "Darkvoid_Shockwave_3"
							__Object.Material = Enum.Material.Neon
							__Object.Color = Color3.fromRGB(189, 189, 189)
							__Object.Anchored = true
							__Object.CastShadow = false
							__Object.CanCollide = false
							__Object.Transparency = 1
							__Object.Position = Floor(Object.Position)

							__Object.Size = Vector3.new(1, 5, 5)
							__Object.Shape = Enum.PartType.Cylinder
							__Object.Orientation = Vector3.new(0, 90, 90)

							Tween:Play(__Object, {0.05}, {Transparency = 0.9})

							task.delay(0.05, function()
								Tween:Play(__Object, {0.4, "Circular", "Out"}, {
									Size = Vector3.new(1, 10, 10), 
								})

								task.wait(0.4)

								Tween:Play(__Object, {0.4, "Circular", "In"}, {
									Transparency = 0.95,
									Size = Vector3.zero, 
								})
							end)

							__Object.Parent = Temporary
							Debris:AddItem(__Object, 2)
						end

						do
							local __Object = Instance.new("Part")
							__Object.Name = "Darkvoid_Shockwave_4"
							__Object.Material = Enum.Material.Neon
							__Object.Color = Color3.fromRGB(189, 189, 189)
							__Object.Anchored = true
							__Object.CastShadow = false
							__Object.CanCollide = false
							__Object.Transparency = 1
							__Object.Position = Floor(Object.Position)

							__Object.Size = Vector3.one * 2
							__Object.Orientation = Vector3.one * math.random(-20, 20)

							Tween:Play(__Object, {0.05}, {Transparency = 0.8})

							task.delay(0.05, function()
								Tween:Play(__Object, {0.7, "Quad", "InOut"}, {
									Transparency = 1,
									Size = Vector3.one * 4, 
									Orientation = Vector3.one * math.random(-60, 60)
								})
							end)

							__Object.Parent = Temporary
							Debris:AddItem(__Object, 2)
						end
					end)
				end)

				Object.Parent = Temporary

				Debris:AddItem(Object, 3)
			end)
		end
	end
end

return Keybind  