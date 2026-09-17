local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AdvancedStructureData = require(ReplicatedStorage.Shared.AdvancedStructureData)
local MissionData = require(ReplicatedStorage.Shared.MissionData)

local errors = {}

if #MissionData.Order < 8 then table.insert(errors, "Expected at least 8 ranked contracts.") end
for _, id in MissionData.Order do
	local mission = MissionData.Missions[id]
	if not mission then table.insert(errors, `Mission order references missing contract {id}.`) end
	if mission and (not mission.Reward or (mission.Reward.Gold or 0) <= 0) then table.insert(errors, `Contract {id} has no Gold reward.`) end
end

if #AdvancedStructureData.Order < 5 then table.insert(errors, "Expected at least 5 advanced structures.") end
for _, name in AdvancedStructureData.Order do
	if not AdvancedStructureData.Structures[name] then table.insert(errors, `Advanced structure {name} is missing.`) end
end

if #errors > 0 then
	for _, message in errors do warn(`[HunterExpansionValidation] {message}`) end
else
	print(`[HunterExpansionValidation] Config passed: {#MissionData.Order} repeatable contracts and {#AdvancedStructureData.Order} advanced structures.`)
end

task.spawn(function()
	task.wait(8)
	local world = Workspace:FindFirstChild("SurvivalArena")
	if not world then warn("[HunterExpansionValidation] SurvivalArena missing at runtime.") return end
	local hall = world:FindFirstChild("FrontierTownHall")
	if not hall then warn("[HunterExpansionValidation] Hunter Town Hall did not generate.") end
	local expected = { DragonDungeon = 2, DemonDungeon = 3 }
	local totalBosses = 0
	for dungeonName, minimum in expected do
		local dungeon = world:FindFirstChild(dungeonName)
		local count = 0
		if dungeon then
			for _, descendant in dungeon:GetDescendants() do
				if descendant:IsA("Model") and descendant:GetAttribute("DungeonBoss") == true then count += 1 end
			end
		end
		totalBosses += count
		if count < minimum then warn(`[HunterExpansionValidation] {dungeonName} has {count}/{minimum} required bosses.`) end
	end
	if hall and totalBosses >= 5 then
		print("[HunterExpansionValidation] Runtime passed: Town Hall online and all 5 authoritative dungeon bosses are present.")
	end
end)
