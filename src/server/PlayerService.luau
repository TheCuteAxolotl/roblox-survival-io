local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)

local PlayerService = {}
local profiles = {}
local store = nil
local persistentEnabled = false

local function deepCopy(source)
	if type(source) ~= "table" then return source end
	local result = {}
	for key, value in source do
		result[deepCopy(key)] = deepCopy(value)
	end
	return result
end

local function starterUnlocks()
	local unlocks = {}
	for _, itemName in ItemData.StarterUnlocks do
		unlocks[itemName] = true
	end
	return unlocks
end

local function defaultProfile()
	local profile = deepCopy(Config.StartingResources)
	profile.Unlocks = starterUnlocks()
	profile.Choices = {}
	return profile
end

local function normalizeProfile(raw)
	local profile = defaultProfile()
	if type(raw) ~= "table" then return profile end

	for _, key in { "Wood", "Stone", "Food", "Gold", "XP", "Age" } do
		if type(raw[key]) == "number" then
			profile[key] = math.max(0, raw[key])
		end
	end

	if type(raw.Unlocks) == "table" then
		for itemName, unlocked in raw.Unlocks do
			if unlocked == true and ItemData.Items[itemName] then
				profile.Unlocks[itemName] = true
			end
		end
	end

	if type(raw.Choices) == "table" then
		for ageKey, itemName in raw.Choices do
			local age = tonumber(ageKey)
			if age and type(itemName) == "string" and ItemData.Items[itemName] then
				profile.Choices[tostring(age)] = itemName
				profile.Unlocks[itemName] = true
			end
		end
	end

	return profile
end

local function tryEnableStore()
	if RunService:IsStudio() and game.GameId == 0 then
		warn("[PlayerService] Unpublished Studio place: using temporary session data.")
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SurvivalIO_Player_v2")
	end)
	if ok then
		store = result
		persistentEnabled = true
	else
		warn("[PlayerService] DataStore unavailable; using temporary data:", result)
	end
end

local function updateAge(profile)
	for age = #Config.AgeThresholds, 1, -1 do
		if profile.XP >= Config.AgeThresholds[age] then
			profile.Age = age
			return
		end
	end
	profile.Age = 1
end

local function syncLeaderstats(player)
	local profile = profiles[player]
	if not profile then return end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	for _, name in { "Wood", "Stone", "Food", "Gold", "XP", "Age" } do
		local value = stats:FindFirstChild(name)
		if value then value.Value = math.floor(profile[name] or 0) end
	end
end

function PlayerService.Get(player)
	return profiles[player]
end

function PlayerService.GetPendingChoice(player)
	local profile = profiles[player]
	if not profile then return nil end
	for age = 2, profile.Age do
		local options = ItemData.AgeChoices[age]
		if options and not profile.Choices[tostring(age)] then
			return {
				Age = age,
				Options = deepCopy(options),
			}
		end
	end
	return nil
end

function PlayerService.GetPublic(player)
	local profile = profiles[player]
	if not profile then profile = defaultProfile() end
	local public = deepCopy(profile)
	public.PendingChoice = PlayerService.GetPendingChoice(player)
	return public
end

function PlayerService.HasUnlock(player, itemName)
	local profile = profiles[player]
	return profile ~= nil and profile.Unlocks[itemName] == true
end

function PlayerService.ChooseUpgrade(player, itemName)
	if type(itemName) ~= "string" then return false, "Invalid upgrade." end
	local profile = profiles[player]
	if not profile then return false, "Profile not ready." end
	local pending = PlayerService.GetPendingChoice(player)
	if not pending then return false, "No upgrade choice is waiting." end

	local allowed = false
	for _, option in pending.Options do
		if option == itemName then
			allowed = true
			break
		end
	end
	if not allowed then return false, "That item is not one of your current choices." end

	profile.Unlocks[itemName] = true
	profile.Choices[tostring(pending.Age)] = itemName
	return true, `Unlocked {ItemData.Items[itemName].Label}!`
end

function PlayerService.Add(player, changes)
	local profile = profiles[player]
	if not profile then return false end
	for key, amount in changes do
		if type(amount) == "number" and type(profile[key]) == "number" then
			profile[key] = math.max(0, (profile[key] or 0) + amount)
		end
	end
	updateAge(profile)
	syncLeaderstats(player)
	return true
end

function PlayerService.CanAfford(player, cost)
	local profile = profiles[player]
	if not profile then return false end
	for resource, amount in cost do
		if (profile[resource] or 0) < amount then return false end
	end
	return true
end

function PlayerService.Spend(player, cost)
	if not PlayerService.CanAfford(player, cost) then return false end
	local changes = {}
	for resource, amount in cost do changes[resource] = -amount end
	return PlayerService.Add(player, changes)
end

function PlayerService.TakeDeathDrop(player, ratio)
	local profile = profiles[player]
	if not profile then return {} end
	ratio = math.clamp(tonumber(ratio) or 0.35, 0, 1)

	local drops = {}
	for _, resource in { "Wood", "Stone", "Food", "Gold" } do
		local current = math.floor(profile[resource] or 0)
		local amount = math.floor(current * ratio)
		if amount > 0 then
			profile[resource] = current - amount
			drops[resource] = amount
		else
			drops[resource] = 0
		end
	end
	syncLeaderstats(player)
	return drops
end

local function makeLeaderstats(player, profile)
	local old = player:FindFirstChild("leaderstats")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	for _, name in { "Wood", "Stone", "Food", "Gold", "XP", "Age" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = math.floor(profile[name] or 0)
		value.Parent = folder
	end
end

function PlayerService.Load(player)
	local profile = defaultProfile()
	if persistentEnabled and store then
		local ok, data = pcall(function() return store:GetAsync(`p_{player.UserId}`) end)
		if ok then
			profile = normalizeProfile(data)
		end
	end
	updateAge(profile)
	profiles[player] = profile
	makeLeaderstats(player, profile)
end

function PlayerService.Save(player)
	if not persistentEnabled or not store then return end
	local profile = profiles[player]
	if not profile then return end
	local payload = deepCopy(profile)
	pcall(function() store:SetAsync(`p_{player.UserId}`, payload) end)
end

function PlayerService.Init()
	tryEnableStore()
	Players.PlayerAdded:Connect(PlayerService.Load)
	Players.PlayerRemoving:Connect(function(player)
		PlayerService.Save(player)
		profiles[player] = nil
	end)
	for _, player in Players:GetPlayers() do task.spawn(PlayerService.Load, player) end
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do PlayerService.Save(player) end
	end)
end

return PlayerService
