local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local resultEvent = script.Parent:FindFirstChild("AscensionRunResult") or Instance.new("BindableEvent")
resultEvent.Name = "AscensionRunResult"
resultEvent.Parent = script.Parent

local store
local persistent = false
local profiles = {}

local TIER_THRESHOLDS = { 0, 180, 500, 1100, 2100, 3600 }

local function tierFor(renown)
	for i = #TIER_THRESHOLDS, 1, -1 do
		if renown >= TIER_THRESHOLDS[i] then return i end
	end
	return 1
end

local function defaultData()
	return { Renown = 0, Clears = 0, Runs = 0, BestStage = 0 }
end

local function normalize(raw)
	local data = defaultData()
	if type(raw) == "table" then
		for _, key in { "Renown", "Clears", "Runs", "BestStage" } do
			if type(raw[key]) == "number" then data[key] = math.max(0, math.floor(raw[key])) end
		end
	end
	return data
end

if not (RunService:IsStudio() and game.GameId == 0) then
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("Wildforge_Ascension_v1")
	end)
	if ok then
		store = ds
		persistent = true
	else
		warn("[AscensionProgression] DataStore unavailable; progression is session-only.", ds)
	end
end

local function publish(player)
	local data = profiles[player]
	if not data then return end
	player:SetAttribute("AscensionRenown", data.Renown)
	player:SetAttribute("AscensionTier", tierFor(data.Renown))
	player:SetAttribute("AscensionClears", data.Clears)
	player:SetAttribute("AscensionRuns", data.Runs)
	player:SetAttribute("AscensionBestStage", data.BestStage)
end

local function save(player)
	if not persistent or not store then return end
	local data = profiles[player]
	if not data then return end
	local payload = {
		Renown = data.Renown,
		Clears = data.Clears,
		Runs = data.Runs,
		BestStage = data.BestStage,
	}
	local ok, err = pcall(function()
		store:SetAsync("ascension_" .. player.UserId, payload)
	end)
	if not ok then warn("[AscensionProgression] Save failed for " .. player.Name .. ": " .. tostring(err)) end
end

local function load(player)
	local data = defaultData()
	if persistent and store then
		local ok, raw = pcall(function()
			return store:GetAsync("ascension_" .. player.UserId)
		end)
		if ok then data = normalize(raw) else warn("[AscensionProgression] Load failed for " .. player.Name .. ": " .. tostring(raw)) end
	end
	profiles[player] = data
	publish(player)
end

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do task.spawn(load, player) end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	profiles[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do save(player) end
end)

resultEvent.Event:Connect(function(player, result)
	local data = profiles[player]
	if not data or type(result) ~= "table" then return end

	local stage = math.max(0, math.floor(result.Stage or 0))
	local cleared = result.Cleared == true
	local extracted = result.Extracted == true
	local modifier = tostring(result.Modifier or "Standard")

	local modifierBonus = ({
		Standard = 1.0,
		Swarm = 1.08,
		Juggernaut = 1.12,
		Frenzy = 1.12,
		Golden = 1.08,
		Unstable = 1.20,
		Nightmare = 1.38,
	})[modifier] or 1

	local base = 14 + stage * 9
	if extracted then base += 12 end
	if cleared then base += 95 end
	local renown = math.max(5, math.floor(base * modifierBonus + 0.5))

	data.Renown += renown
	data.Runs += 1
	data.BestStage = math.max(data.BestStage, stage)
	if cleared then data.Clears += 1 end
	publish(player)
	task.spawn(save, player)

	player:SetAttribute("AscensionLastRenownGain", renown)
end)

print("[AscensionProgression] Persistent Renown and six difficulty tiers online.")
