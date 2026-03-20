--[[
	Evercyan @ March 2023
	Tween
	
	Tween is a utility wrapper used to conveniently create & play tweens in a short & quick fashion.
	A wrapper basically takes an existing feature (TweenService) and adds code on top of it for extra functionality.
	
	---- Roblox TweenService:
	local Tween = TweenService:Create(Lighting, {1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In}, {Brightness = 0})
	Tween:Play()
	
	---- Tween Wrapper:
	local Tween = Tween:Play(Lighting, {1, "Expontential", "In"}, {Brightness = 0})
]]

--> Services
local TweenService = game:GetService("TweenService")

--------------------------------------------------------------------------------

local Tween = {}

local function GetTweenInfo(tweenInfo)
	if typeof(tweenInfo) == "table" then
		if tweenInfo[2] and typeof(tweenInfo[2]) == "string" then
			tweenInfo[2] = Enum.EasingStyle[tweenInfo[2]]
		end
		if tweenInfo[3] and typeof(tweenInfo[3]) == "string" then
			tweenInfo[3] = Enum.EasingDirection[tweenInfo[3]]
		end
		tweenInfo = TweenInfo.new(unpack(tweenInfo))
	end
	
	return tweenInfo
end

function Tween:Create(Instance: Instance, tweenInfo, Properties)
	if Instance == nil then 
		return 
	end
	
	return TweenService:Create(Instance, GetTweenInfo(tweenInfo), Properties)
end

function Tween:Play(Instance: Instance, tweenInfo, Properties)
	if Instance == nil then 
		return 
	end
	
	local Tween = Tween:Create(Instance, tweenInfo, Properties)
	Tween:Play()
	
	return Tween
end

return Tween