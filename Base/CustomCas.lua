--[[
	ej0w @ November 2024
	CustomCAS
	
	Serves as a custom ContextActionService module for keybind buttons (displayed above the hotbar)
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

--> Player
local Player = Players.LocalPlayer
local ButtonFrame = Player.PlayerGui:WaitForChild("Inventory"):WaitForChild("Main"):WaitForChild("HideCanvas"):WaitForChild("ContextActionButtons")
local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local createNotification = require(ReplicatedStorage.Modules.Client.createNotification)

--> Variables
local CustomCAS = {}

local ActiveCooldowns = {}
local ActiveKeybindInputs = {}

local RelevancyKeybindSpaces = {"Q", "R", "F", "Z", "X", "C", "V", "G", "B", "Y", "H", "N", "U", "J", "M", "I", "K", "O", "L", "P"}
local KeybindChanged = Instance.new("BindableEvent")

local isNotKeybind = (UserInputService.GamepadEnabled and not RunService:IsStudio()) or UserInputService.TouchEnabled

-- Tracks which keybind names are currently held down, used for weapon-swap enforcement
local HeldKeybinds = {} -- [Name] = OnActivated function

-- Number keys 1-9 used to switch hotbar slots (weapon switching)
local WeaponSwitchKeys = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
	Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
}

local function IsWeaponSwitchInput(Input: InputObject): boolean
	return table.find(WeaponSwitchKeys, Input.KeyCode) ~= nil
end

--------------------------------------------------------------------------------
-- Centralized Input Handlers for massive performance boost
local function HandleGlobalInput(Input: InputObject, GPE: boolean, isBeginning: boolean)
	if isBeginning and IsWeaponSwitchInput(Input) and not GPE then
		if GameConfig.LockKeybindWeapon then
			if next(HeldKeybinds) then
				return -- sink is handled below by Priority Action
			end
		else
			for _, OnActivatedFn in pairs(HeldKeybinds) do
				task.spawn(OnActivatedFn, false, false)
			end
		end
	end

	local KeyStr = Input.KeyCode.Name
	local SearchKey = KeyStr ~= "Unknown" and KeyStr or Input.UserInputType
	local Data = ActiveKeybindInputs[SearchKey]
	
	if Data then
		local OnActivated = Data[5]
		if OnActivated then
			task.spawn(OnActivated, isBeginning, GPE)
		end
	end
end

UserInputService.InputBegan:Connect(function(Input, GPE)
	HandleGlobalInput(Input, GPE, true)
end)

UserInputService.InputEnded:Connect(function(Input, GPE)
	HandleGlobalInput(Input, GPE, false)
end)
--------------------------------------------------------------------------------

local function UpdateButtonFrameVisibility()
	local Visible = 0
	for _, Frame in ipairs(ButtonFrame:GetChildren()) do
		if Frame:IsA("GuiObject") and Frame.Visible then
			Visible += 1
		end
	end

	ButtonFrame.Visible = Visible > 0
end

function CustomCAS:StartContextInput(Name: string, DisplayName: string, LevelReq: number, Icon: number, CreateButton: boolean, Key: string, Cooldown: number, CooldownAfterHold: boolean, HoldTime: number, Priority: number, Callback, Validation, KeyName, DontMakeSound, CanNotPress)
	-- CLEANUP old input with the same Name to prevent duplicates on re-equip
	for _Key, Data in pairs(ActiveKeybindInputs) do
		if Data[1] == Name then
			self:StopContextInput(Name)
			break
		end
	end

	local Button = script.ButtonTemplate:Clone()
	Button.Name = Name
	Button.LayoutOrder = Priority or 999

	local InputFrame = Button:WaitForChild("InputButton")
	InputFrame.Button:SetAttribute("DisableSound", true)

	local Connections = {}

	local function UpdateKeybindTaking()
		if not ActiveKeybindInputs[Key] then
			return Key
		end
		for _, NewKey in ipairs(RelevancyKeybindSpaces) do
			if not ActiveKeybindInputs[NewKey] then
				return NewKey
			end
		end
		return nil
	end

	local activatedTime = os.clock()
	local isHeldDown = false

	-- Forward declaration for OnActivated
	local OnActivated

	local function MakeData()
		return {Name, Cooldown, Button, Connections, OnActivated}
	end

	local ChosenKey = Key
	if typeof(Key) == "string" and ActiveKeybindInputs[Key] then
		ChosenKey = UpdateKeybindTaking()
	end
	
	if ChosenKey ~= Key and not isNotKeybind then
		Connections[#Connections + 1] = KeybindChanged.Event:Connect(function(KeyChanged)
			local PreviousKey = ChosenKey

			local function UpdateKey(NewChosenKey)
				if PreviousKey and ActiveKeybindInputs[PreviousKey] then
					ActiveKeybindInputs[PreviousKey] = nil
					KeybindChanged:Fire(PreviousKey)
				end
				
				ChosenKey = NewChosenKey
				if NewChosenKey then
					ActiveKeybindInputs[NewChosenKey] = MakeData()
					Button.Keybind.Text = NewChosenKey
				end
			end

			local isOriginalKey = (KeyChanged == Key and not ActiveKeybindInputs[Key])
			if isOriginalKey then
				UpdateKey(Key)
			else
				local NewChosenKey = UpdateKeybindTaking()
				if NewChosenKey and NewChosenKey ~= PreviousKey then
					UpdateKey(NewChosenKey)
				end
			end
		end)
	end

	if Icon ~= nil then
		if tonumber(Icon) then
			Icon = "rbxassetid://" .. Icon
		end

		Button.Icon.Image = Icon

		Button.Icon.Visible = true
		Button.Display.Visible = false
	end

	Tween:Play(Button.UIScale, {0.35, "Circular"}, {
		Scale = 1,
	})

	Button.UIScale.Scale = 0.7
	Button.Input.Visible = isNotKeybind

	if KeyName then
		Button.Keybind.TextSize -= 4
	end

	Button.Display.Text = DisplayName

	Button.Keybind.Visible = not isNotKeybind
	Button.Keybind.Text = (not isNotKeybind and (KeyName or (typeof(Key) == "string" and ChosenKey) or Key.Name)) or ""

	local function OnTimerStarted(_Button)
		local NewButton = _Button or Button
		if NewButton.Parent == nil then
			return
		end

		task.spawn(function()
			while ActiveCooldowns[Name] and NewButton.Parent do
				local TimeLeft = Cooldown - (os.clock() - ActiveCooldowns[Name])

				if TimeLeft <= 0.05 then
					break
				end

				NewButton.Timer.Text = tostring(math.floor(TimeLeft * 10 + 0.5) / 10)
				task.wait(0.1)
			end

			if NewButton.Parent then
				NewButton.Timer.Visible = false
			end
		end)

		NewButton.Timer.Visible = true
	end

	function OnActivated(Verdict, GPE, fromButton)
		if (Verdict and isHeldDown) or (not Verdict and not isHeldDown) then
			return
		end
		
		-- Only check level req on button down to prevent hanging input states
		if Verdict and LevelReq ~= nil then
			local Level = pData.Stats.Level.Value
			if Level < LevelReq then
				-- Optimization: Local short-circuit overreaches, but fallback to network when valid
				local Success, Response = EventModule:InvokeServer("KeybindLevelReq", LevelReq)
				if Response then
					createNotification(
						"Error",
						`You need to be Level {LevelReq} to use {Name}. (Current Level: {Level})`,
						12900311562
					)
					return 
				end
			end
		end

		isHeldDown = Verdict

		-- Register/unregister from HeldKeybinds for weapon-swap enforcement
		if Verdict then
			HeldKeybinds[Name] = OnActivated
			if GameConfig.LockKeybindWeapon then
				ContextActionService:BindActionAtPriority("LockWeapon_" .. Name, function()
					return Enum.ContextActionResult.Sink
				end, false, 2000, unpack(WeaponSwitchKeys))
			end
		else
			HeldKeybinds[Name] = nil
			if GameConfig.LockKeybindWeapon then
				ContextActionService:UnbindAction("LockWeapon_" .. Name)
			end
		end

		local isGoingCooldown = (CooldownAfterHold and not Verdict) or (not CooldownAfterHold and Verdict)
		local Success = (Validation == nil) or Validation(Verdict, GPE)

		if Success and (not Cooldown or not ActiveCooldowns[Name]) then
			local Clock = os.clock()
			activatedTime = Clock

			if not isGoingCooldown and CooldownAfterHold and HoldTime then
				task.delay(HoldTime, function()
					if activatedTime == Clock then
						OnActivated(false, false)
					end
				end)
			elseif isGoingCooldown and Cooldown and Cooldown > 0 then
				ActiveCooldowns[Name] = os.clock()

				local function RequestActivate(_Button)
					local _InputFrame = _Button:WaitForChild("InputButton")

					task.delay(Cooldown, function()
						if _InputFrame.Parent ~= nil then
							_InputFrame.Button.AutoButtonColor = true
						end

						ActiveCooldowns[Name] = nil
					end)

					OnTimerStarted(_Button)

					Tween:Play(_Button.Canvas.Cooldown, {Cooldown + 0.1, "Linear", "InOut"}, {
						Size = UDim2.fromScale(1, 0)
					})

					_InputFrame.Button.AutoButtonColor = false
					_Button.Canvas.Cooldown.Size = UDim2.fromScale(1, 1)
				end

				if Button.Parent then
					RequestActivate(Button)
				else
					for _Key, Data in pairs(ActiveKeybindInputs) do
						if Data[1] == Name then
							RequestActivate(Data[3])
							break
						end
					end
				end
			end

			if isGoingCooldown and not (not fromButton and DontMakeSound) then
				SFX:Play2D(GameConfig.ClickSFX[1], {Volume = GameConfig.ClickSFX[2]})
			end

			if Callback then
				Callback(Verdict, GPE)
			end
		end
	end

	if not CanNotPress then
		Connections[#Connections + 1] = InputFrame.Button.MouseButton1Down:Connect(function()
			OnActivated(true, false, true)
		end)

		Connections[#Connections + 1] = InputFrame.Button.MouseButton1Up:Connect(function()
			OnActivated(false, false, true)
		end)
	else
		InputFrame.Button.AutoButtonColor = false
	end

	if CreateButton and not (isNotKeybind and CanNotPress) then
		Button.Visible = true
		Button.Parent = ButtonFrame
	end

	if ActiveCooldowns[Name] and Button.Parent then
		local Duration = os.clock() - ActiveCooldowns[Name]
		local TimeLeft = math.max(0, Cooldown - Duration)

		InputFrame.Button.AutoButtonColor = false

		task.delay(TimeLeft, function()
			if InputFrame.Parent ~= nil then
				InputFrame.Button.AutoButtonColor = true
			end
		end)

		local Percentage = math.clamp(TimeLeft / Cooldown, 0, 1)
		Button.Canvas.Cooldown.Size = UDim2.fromScale(1, Percentage)

		OnTimerStarted()

		Tween:Play(Button.Canvas.Cooldown, {TimeLeft, "Linear", "InOut"}, {
			Size = UDim2.fromScale(1, 0)
		})
	else
		Button.Canvas.Cooldown.Size = UDim2.fromScale(1, 0)
	end

	if ChosenKey ~= nil then
		ActiveKeybindInputs[ChosenKey] = MakeData()
	end
	UpdateButtonFrameVisibility()
end

function CustomCAS:StopContextInput(Name: string)
	for _Key, Data in pairs(ActiveKeybindInputs) do
		if Data[1] == Name then
			if Data[3] then
				Data[3]:Destroy()
			end

			for _, Connection in pairs(Data[4]) do
				if typeof(Connection) == "RBXScriptConnection" then
					Connection:Disconnect()
				end
			end

			ActiveKeybindInputs[_Key] = nil
			if typeof(_Key) == "string" then
				KeybindChanged:Fire(_Key)
			end

			-- Clean up weapon-lock state if this keybind was held when stopped
			if HeldKeybinds[Name] then
				HeldKeybinds[Name] = nil
				if GameConfig.LockKeybindWeapon then
					ContextActionService:UnbindAction("LockWeapon_" .. Name)
				end
			end
			break -- Name is unique across all ActiveKeybindInputs
		end
	end
end

return CustomCAS
