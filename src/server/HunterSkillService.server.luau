local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local masteryAward = script.Parent:FindFirstChild("HunterMasteryAward") or Instance.new("BindableEvent")
masteryAward.Name = "HunterMasteryAward"
masteryAward.Parent = script.Parent

local dataByPlayer = {}
local store
local persistent = false

if not (RunService:IsStudio() and game.GameId == 0) then
	local ok, result = pcall(function() return DataStoreService:GetDataStore("Wildforge_HunterMastery_v1") end)
	if ok then store = result persistent = true else warn("[HunterSkills] DataStore unavailable; using session mastery.", result) end
end

local function defaultData()
	return { MasteryXP = 0, Missions = 0, Minutes = 0 }
end

local function normalize(raw)
	local data = defaultData()
	if type(raw) == "table" then
		for _, key in { "MasteryXP", "Missions", "Minutes" } do
			if type(raw[key]) == "number" then data[key] = math.max(0, raw[key]) end
		end
	end
	return data
end

local function skillLevels(data)
	local xp = data.MasteryXP or 0
	return {
		Power = math.clamp(1 + math.floor(xp / 105), 1, 20),
		Vitality = math.clamp(1 + math.floor(xp / 145), 1, 20),
		Agility = math.clamp(1 + math.floor(xp / 165), 1, 20),
		Fortune = math.clamp(1 + math.floor((data.Missions or 0) / 3), 1, 20),
	}
end

local function rankFor(data)
	local missions = data.Missions or 0
	if missions >= 40 then return "S" end
	if missions >= 25 then return "A" end
	if missions >= 15 then return "B" end
	if missions >= 8 then return "C" end
	if missions >= 3 then return "D" end
	return "E"
end

local function publish(player)
	local data = dataByPlayer[player]
	if not data or not player.Parent then return end
	local levels = skillLevels(data)
	local powerMultiplier = 1 + (levels.Power - 1) * 0.025
	local defenseBonus = (levels.Vitality - 1) * 0.008
	local speedBonus = (levels.Agility - 1) * 0.22
	local goldMultiplier = 1 + (levels.Fortune - 1) * 0.035

	player:SetAttribute("HunterMasteryXP", math.floor(data.MasteryXP))
	player:SetAttribute("HunterMinutes", math.floor(data.Minutes))
	player:SetAttribute("HunterMissions", math.floor(data.Missions))
	player:SetAttribute("HunterRank", rankFor(data))
	player:SetAttribute("HunterPowerLevel", levels.Power)
	player:SetAttribute("HunterVitalityLevel", levels.Vitality)
	player:SetAttribute("HunterAgilityLevel", levels.Agility)
	player:SetAttribute("HunterFortuneLevel", levels.Fortune)
	player:SetAttribute("HunterPowerMultiplier", powerMultiplier)
	player:SetAttribute("HunterDefenseBonus", defenseBonus)
	player:SetAttribute("HunterSpeedBonus", speedBonus)
	player:SetAttribute("HunterGoldMultiplier", goldMultiplier)
end

local function save(player)
	if not persistent or not store then return end
	local data = dataByPlayer[player]
	if not data then return end
	local payload = { MasteryXP = data.MasteryXP, Missions = data.Missions, Minutes = data.Minutes }
	local ok, err = pcall(function() store:SetAsync(`hunter_{player.UserId}`, payload) end)
	if not ok then warn(`[HunterSkills] Save failed for {player.Name}: {err}`) end
end

local function load(player)
	local data = defaultData()
	if persistent and store then
		local ok, result = pcall(function() return store:GetAsync(`hunter_{player.UserId}`) end)
		if ok then data = normalize(result) else warn(`[HunterSkills] Load failed for {player.Name}: {result}`) end
	end
	dataByPlayer[player] = data
	publish(player)
end

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do task.spawn(load, player) end
Players.PlayerRemoving:Connect(function(player) save(player) dataByPlayer[player] = nil end)
game:BindToClose(function() for _, player in Players:GetPlayers() do save(player) end end)

masteryAward.Event:Connect(function(player, masteryXP, missionCount)
	local data = dataByPlayer[player]
	if not data then return end
	data.MasteryXP += math.max(0, tonumber(masteryXP) or 0)
	data.Missions += math.max(0, tonumber(missionCount) or 0)
	publish(player)
	if missionCount and missionCount > 0 then task.spawn(save, player) end
end)

-- Playtime itself matters: every full minute online adds Mastery.
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			local data = dataByPlayer[player]
			if data then
				data.Minutes += 1
				data.MasteryXP += 12
				publish(player)
				if data.Minutes % 5 == 0 then task.spawn(save, player) end
			end
		end
	end
end)

local function baseEquipmentStats(player)
	local armorReduction = 0
	local cloakDamage = 1
	local cloakWalk = 0
	local armorName = player:GetAttribute("EquippedArmorItem")
	local cloakName = player:GetAttribute("EquippedCloakItem")
	local armor = armorName and SurvivalItemData.Items[armorName]
	local cloak = cloakName and SurvivalItemData.Items[cloakName]
	if armor then armorReduction = armor.ArmorReduction or 0 end
	if cloak then
		cloakDamage = cloak.DamageMultiplier or 1
		cloakWalk = cloak.WalkSpeedBonus or 0
	end
	return armorReduction, cloakDamage, cloakWalk
end

-- Existing combat/survival systems already consume these attributes. Recompose
-- equipment + skill bonuses here so skill growth affects the whole game.
task.spawn(function()
	while true do
		task.wait(0.35)
		for _, player in Players:GetPlayers() do
			if dataByPlayer[player] then
				local armorBase, cloakDamageBase, cloakWalkBase = baseEquipmentStats(player)
				local defense = player:GetAttribute("HunterDefenseBonus") or 0
				local power = player:GetAttribute("HunterPowerMultiplier") or 1
				local speed = player:GetAttribute("HunterSpeedBonus") or 0
				player:SetAttribute("ArmorReduction", math.clamp(armorBase + defense, 0, 0.65))
				player:SetAttribute("CloakDamageMultiplier", math.max(0.1, cloakDamageBase * power))
				player:SetAttribute("CloakWalkBonus", cloakWalkBase + speed)
			end
		end
	end
end)

print("[HunterSkills] Persistent Mastery online: Power, Vitality, Agility and Fortune grow with playtime and contracts.")
