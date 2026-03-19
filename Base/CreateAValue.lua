--[[
	ej0w @ October 2024
	CreateValue

	Adds items to pData. If a prefixed version of the item already exists
	(e.g. "Iron Sword|Godly"), stacks onto that key instead of creating a new base entry.
]]

local SEP = "|"

return function(pData, Item, DontSave, Amount, Library)
	Amount = Amount or 1
	local folder = pData.Items[Library]

	-- Check if a prefixed version already exists with copies (value > 0)
	local prefixedKey = nil
	for _, child in folder:GetChildren() do
		local base = child.Name:match("^(.+)" .. SEP .. ".+$")
		if base == Item.Name and child:IsA("NumberValue") and child.Value > 0 then
			prefixedKey = child.Name
			break
		end
	end

	local targetName = prefixedKey or Item.Name
	local ValueObject = folder:FindFirstChild(targetName)
	if not ValueObject then
		ValueObject = Instance.new("NumberValue")
		ValueObject.Parent = folder
		ValueObject.Name = targetName
	end

	ValueObject.Value += Amount

	if DontSave then
		local DontSaveAttribute = ValueObject:GetAttribute("DontSave") or 0
		ValueObject:SetAttribute("DontSave", DontSaveAttribute + (typeof(DontSave) == "boolean" and 1 or DontSave))
	end

	return ValueObject
end