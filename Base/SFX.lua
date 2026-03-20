--[[
	Evercyan @ March 2023
	SFX
	
	Lighter implementation of my SFX library from Infinity's Occultation Update, a simple
	wrapper to create one-time sounds, either 2D or 3D.
]]

--> Services
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

--> References
local Client = script:WaitForChild("Client")

--> Variables
local SFX = {}

local SoundGroup = Instance.new("SoundGroup")
SoundGroup.Name = "KitSounds"
SoundGroup.Volume = 0.5
SoundGroup.Parent = SoundService

--------------------------------------------------------------------------------

function SFX:CreateBaseSound(SoundId, Parameters)
	if tonumber(SoundId) then
		SoundId = "rbxassetid://" .. SoundId
	end
	
	local Sound = Instance.new("Sound")
	Sound.Name = "SFX_".. SoundId
	Sound.SoundId = SoundId or ""
	Sound.SoundGroup = SoundGroup
	
	for Name, Value in typeof(Parameters) == "table" and Parameters or {} do
		Sound[Name] = Value
	end
	
	return Sound
end

function SFX:Play2D(SoundId: number, Player: Player?, Parameters)
	local IsServer = RunService:IsServer()
	if Player and IsServer then
		Client:FireClient(Player, SoundId)
	elseif not IsServer then
		local Sound = self:CreateBaseSound(SoundId, typeof(Player) == "table" and Player or Parameters)
		Sound.Parent = SoundGroup
		
		Sound.Ended:Once(function()
			Sound:Destroy()
		end)

		Sound:Play()
	end
end

function SFX:Play3D(SoundId: number, Location: Vector3 | Instance, Parameters)
	if not Location or typeof(Location) ~= "Vector3" and typeof(Location) ~= "Instance" then
		warn(`SFX.Play3D: Invalid Location passed: {tostring(Location)}`)
		return
	end
	
	local isInstance = typeof(Location) == "Instance"
	if isInstance then
		local Sound = self:CreateBaseSound(SoundId, Parameters)
		Sound.Parent = Location

		Sound.Ended:Once(function()
			if Sound.Parent == nil then
				return
			end
			Sound:Destroy()
		end)

		Sound:Play()
	elseif not isInstance then
		local Attachment = Instance.new("Part")
		Attachment.Parent = workspace.Temporary
		Attachment.Name = "SoundLocation"
		Attachment.Transparency = 1
		Attachment.Anchored = true
		Attachment.CanCollide = false
		Attachment.Position = Location

		local Sound = self:CreateBaseSound(SoundId, Parameters)
		Sound.Parent = Attachment
		Sound.PlayOnRemove = true
		
		Sound:Destroy()

		task.defer(function()
			Attachment:Destroy()
		end)
	end
end

if RunService:IsClient() then
	Client.OnClientEvent:Connect(function(SoundId)
		SFX:Play2D(SoundId)
	end)
end

return SFX