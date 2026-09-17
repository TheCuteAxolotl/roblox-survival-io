local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)

local problems = {}
local function check(condition, message)
	if not condition then table.insert(problems, message) end
end

local cycle = Config.WorldCycle
check(type(cycle) == "table", "WorldCycle is missing.")
if type(cycle) == "table" then
	check((cycle.DawnSeconds or 0) > 0, "Dawn duration must be positive.")
	check((cycle.DaySeconds or 0) > 0, "Day duration must be positive.")
	check((cycle.DuskSeconds or 0) > 0, "Dusk duration must be positive.")
	check((cycle.NightSeconds or 0) > 0, "Night duration must be positive.")
	check((cycle.MaxThreat or 0) >= 1, "MaxThreat must be at least 1.")
end

check(#Config.AgeThresholds == 8, "V2 should expose eight Forge Levels.")
check(ItemData.Items.Campfire ~= nil, "Starter Campfire build is missing.")
check(table.find(ItemData.StarterUnlocks, "Campfire") ~= nil, "Campfire must be a starter unlock.")
check(table.find(ItemData.StarterUnlocks, "Windmill") == nil, "Windmill should not be a starter unlock in V2.")
check(ItemData.Items.Wall and (ItemData.Items.Wall.Cost.Wood or 999) <= 12, "First wall is too expensive for onboarding.")

for forgeLevel = 2, #Config.AgeThresholds do
	local options = ItemData.AgeChoices[forgeLevel]
	check(type(options) == "table" and #options >= 2, `Forge Level {forgeLevel} needs at least two choices.`)
end

local workbench = CraftingData.Recipes.WorkbenchKit
check(workbench ~= nil, "Workbench recipe is missing.")
if workbench then
	check((workbench.Ingredients.Resources.Wood or 999) <= 35, "Workbench wood cost is too high for the intended early-midgame.")
	check((workbench.Ingredients.Resources.Stone or 999) <= 20, "Workbench stone cost is too high for the intended early-midgame.")
end

local developerProducts = MonetizationConfig.DeveloperProducts or {}
check(next(developerProducts) == nil, "V2 should not sell direct progression currency through Developer Products.")
for passName, pass in MonetizationConfig.GamePasses or {} do
	check(pass.PremiumKit == nil, `Game pass {passName} still grants a premium combat kit.`)
end

if #problems > 0 then
	for _, message in problems do warn(`[WildforgeV2Validation] {message}`) end
	error(`[WildforgeV2Validation] Found {#problems} V2 integration problem(s).`)
else
	local totalCycle = (cycle.DawnSeconds or 0) + (cycle.DaySeconds or 0) + (cycle.DuskSeconds or 0) + (cycle.NightSeconds or 0)
	print(`[WildforgeV2Validation] Passed: {#Config.AgeThresholds} Forge Levels • {totalCycle}s world cycle • starter camp • progression crafting • fair monetization.`)
end
