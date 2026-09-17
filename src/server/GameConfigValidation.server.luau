local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)

local issues = {}

local function problem(message)
	table.insert(issues, message)
end

local hotbarSeen = {}
for _, itemName in ItemData.HotbarOrder do
	if not ItemData.Items[itemName] then
		problem(`HotbarOrder references missing item: {itemName}`)
	elseif hotbarSeen[itemName] then
		problem(`HotbarOrder contains duplicate item: {itemName}`)
	end
	hotbarSeen[itemName] = true
end

for _, itemName in ItemData.StarterUnlocks do
	if not ItemData.Items[itemName] then
		problem(`StarterUnlocks references missing item: {itemName}`)
	end
end

for age, options in ItemData.AgeChoices do
	if type(age) ~= "number" or age < 2 or age > #Config.AgeThresholds then
		problem(`AgeChoices contains invalid age: {tostring(age)}`)
	end
	if type(options) ~= "table" or #options == 0 then
		problem(`Age {tostring(age)} has no choices.`)
	else
		local seen = {}
		for _, itemName in options do
			local item = ItemData.Items[itemName]
			if not item then
				problem(`Age {age} references missing item: {itemName}`)
			elseif seen[itemName] then
				problem(`Age {age} repeats item: {itemName}`)
			else
				seen[itemName] = true
				if item.RequiresUnlock and not ItemData.Items[item.RequiresUnlock] then
					problem(`{itemName} requires missing item: {item.RequiresUnlock}`)
				end
				if not hotbarSeen[itemName] then
					problem(`Age {age} unlock {itemName} is missing from HotbarOrder.`)
				end
			end
		end
	end
end

for itemName, item in ItemData.Items do
	if item.RequiresUnlock and not ItemData.Items[item.RequiresUnlock] then
		problem(`{itemName} requires missing item: {item.RequiresUnlock}`)
	end
	if item.Category == "Build" and item.LimitGroup and not item.BuildLimit then
		problem(`Build {itemName} has LimitGroup {item.LimitGroup} but no BuildLimit.`)
	end
	if item.Ranged and item.Category ~= "Weapon" then
		problem(`Ranged item {itemName} is not categorized as a Weapon.`)
	end
end

if #issues > 0 then
	for _, message in issues do
		warn(`[GameConfigValidation] {message}`)
	end
	warn(`[GameConfigValidation] Found {#issues} configuration issue(s).`)
else
	print("[GameConfigValidation] Progression and item configuration passed validation.")
end
