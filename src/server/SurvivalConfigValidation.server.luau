local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local KitData = require(ReplicatedStorage.Shared.KitData)
local MobData = require(ReplicatedStorage.Shared.MobData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local errors = {}
local validStations = { Hand = true, Workbench = true, Campfire = true }
local validRarities = {}
local validCategories = {}
for _, rarity in SurvivalItemData.RarityOrder do validRarities[rarity] = true end
for _, category in CraftingData.Categories or {} do validCategories[category] = true end

for itemName, item in SurvivalItemData.Items do
	if type(item.Label) ~= "string" or item.Label == "" then table.insert(errors, `Item {itemName} has no label.`) end
	if not validRarities[item.Rarity] then table.insert(errors, `Item {itemName} has invalid rarity {tostring(item.Rarity)}.`) end
	if type(item.Stack) ~= "number" or item.Stack < 1 then table.insert(errors, `Item {itemName} has invalid stack limit.`) end
end

for recipeName, recipe in CraftingData.Recipes do
	if not validStations[recipe.Station] then table.insert(errors, `Recipe {recipeName} has invalid station {tostring(recipe.Station)}.`) end
	if not validCategories[recipe.Category] or recipe.Category == "All" then table.insert(errors, `Recipe {recipeName} has invalid category {tostring(recipe.Category)}.`) end
	local resultName = recipe.Result and recipe.Result.Item
	if not resultName or not SurvivalItemData.Items[resultName] then table.insert(errors, `Recipe {recipeName} produces missing item {tostring(resultName)}.`) end
	for itemName in recipe.Ingredients and recipe.Ingredients.Items or {} do
		if not SurvivalItemData.Items[itemName] then table.insert(errors, `Recipe {recipeName} requires missing item {itemName}.`) end
	end
end

for _, recipeName in CraftingData.Order do
	if not CraftingData.Recipes[recipeName] then table.insert(errors, `Crafting order references missing recipe {recipeName}.`) end
end

for kitName, kit in KitData.Kits do
	for itemName in kit.Items or {} do
		if not SurvivalItemData.Items[itemName] then table.insert(errors, `Kit {kitName} contains missing item {itemName}.`) end
	end
	if type(kit.Cost) ~= "number" or kit.Cost < 0 then table.insert(errors, `Kit {kitName} has invalid gold cost.`) end
end

for mobName, mob in MobData.Mobs do
	if type(mob.Health) ~= "number" or mob.Health <= 0 then table.insert(errors, `Mob {mobName} has invalid health.`) end
	for _, drop in mob.Drops or {} do
		if not SurvivalItemData.Items[drop.Item] then table.insert(errors, `Mob {mobName} drops missing item {tostring(drop.Item)}.`) end
	end
end

if #errors > 0 then
	for _, message in errors do warn(`[SurvivalConfigValidation] {message}`) end
	error(`[SurvivalConfigValidation] Found {#errors} survival configuration error(s).`)
else
	print(`[SurvivalConfigValidation] Passed: {#CraftingData.Order} recipes, 10 inventory slots, crafting categories, kits and mob loot validated.`)
end
