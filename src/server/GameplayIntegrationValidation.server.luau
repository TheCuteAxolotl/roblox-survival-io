local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local MobData = require(ReplicatedStorage.Shared.MobData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local issues = {}
local function problem(message) table.insert(issues, message) end

local spider = MobData.Mobs.Spider
if not spider or spider.NightOnly ~= true then problem("Spider must be configured as NightOnly.") end

for _, mobName in { "DireWolf", "BroodSpider", "ForestBear" } do
	local mob = MobData.Mobs[mobName]
	if not mob then
		problem(`Missing Blackwood mob: {mobName}`)
	else
		if mob.Biome ~= "Forest" then problem(`${mobName} must use Forest biome spawning.`) end
		for _, drop in mob.Drops or {} do
			if not SurvivalItemData.Items[drop.Item] then problem(`${mobName} drops missing item {tostring(drop.Item)}.`) end
		end
	end
end

for _, itemName in { "DireFang", "MoonSilk", "ForestHeart", "RangerArmor" } do
	if not SurvivalItemData.Items[itemName] then problem(`Missing forest item: {itemName}`) end
end

local ranger = CraftingData.Recipes.RangerArmor
if not ranger or not ranger.Result or ranger.Result.Item ~= "RangerArmor" then
	problem("Blackwood Ranger Armor recipe is missing or invalid.")
end

if #issues > 0 then
	for _, message in issues do warn(`[GameplayIntegrationValidation] {message}`) end
	error(`[GameplayIntegrationValidation] Found {#issues} integration error(s).`)
else
	print("[GameplayIntegrationValidation] Passed: night spiders, Blackwood mobs, forest loot and Ranger Armor validated.")
end
