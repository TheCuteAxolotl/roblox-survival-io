local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local errors = {}

if type(ExpansionData.SpawnUnlockAge) ~= "number" or ExpansionData.SpawnUnlockAge < 2 then table.insert(errors, "SpawnUnlockAge must be age 2 or higher.") end
if type(ExpansionData.DoorAccessModes) ~= "table" or #ExpansionData.DoorAccessModes < 2 then table.insert(errors, "Door access modes are missing.") end

for role, trades in ExpansionData.VillageTrades do
	if type(trades) ~= "table" or #trades == 0 then table.insert(errors, `Trader role {role} has no trades.`) end
	for index, trade in ipairs(trades) do
		for itemName in (trade.Take and trade.Take.Items or {}) do
			if not SurvivalItemData.Items[itemName] then table.insert(errors, `{role} trade {index} takes missing item {itemName}.`) end
		end
		for itemName in (trade.Give and trade.Give.Items or {}) do
			if not SurvivalItemData.Items[itemName] then table.insert(errors, `{role} trade {index} gives missing item {itemName}.`) end
		end
	end
end

local boss = ExpansionData.Boss
if type(boss) ~= "table" or type(boss.Health) ~= "number" or boss.Health <= 0 then table.insert(errors, "Boss health is invalid.") end
if type(boss) == "table" and (type(boss.RespawnSeconds) ~= "number" or boss.RespawnSeconds < 10) then table.insert(errors, "Boss respawn time is invalid.") end

if #errors > 0 then
	for _, message in errors do warn(`[ExpansionConfigValidation] {message}`) end
	error(`[ExpansionConfigValidation] Found {#errors} expansion configuration error(s).`)
else
	local tradeCount = 0
	for _, trades in ExpansionData.VillageTrades do tradeCount += #trades end
	print(`[ExpansionConfigValidation] Passed: {tradeCount} villager trades, door permissions, spawn pad and boss validated.`)
end
