local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerService = {}
local profiles = {}
local store = nil
local persistentEnabled = false

local function copyTable(source)
	local result = {}
	for key, value in source do
		result[key] = value
	end
	return result
end

local function defaultProfile()
	return copyTable(Config.StartingResources)
end

local function tryEnableStore()
	if RunService:IsStudio() and game.GameId == 0 then
		warn("[PlayerService] Unpublished Studio place: using temporary session data.")
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SurvivalIO_Player_v1")
	end)
	if ok then
		store = result
		persistentEnabled = true
	else
		warn("[PlayerService] DataStore unavailable; using temporary data:", result)
	end
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

function PlayerService.GetPublic(player)
	local profile = profiles[player]
	if not profile then return defaultProfile() end
	return copyTable(profile)
end

function PlayerService.Add(player, changes)
	local profile = profiles[player]
	if not profile then return false end
	for key, amount in changes do
		if type(amount) == "number" and profile[key] ~= nil then
			profile[key] = math.max(0, (profile[key] or 0) + amount)
		end
	end
	for age = #Config.AgeThresholds, 1, -1 do
		if profile.XP >= Config.AgeThresholds[age] then
			profile.Age = age
			break
		end
	end
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
		if ok and type(data) == "table" then
			for key, value in data do
				if profile[key] ~= nil and type(value) == "number" then profile[key] = value end
			end
		end
	end
	profiles[player] = profile
	makeLeaderstats(player, profile)
end

function PlayerService.Save(player)
	if not persistentEnabled or not store then return end
	local profile = profiles[player]
	if not profile then return end
	pcall(function() store:SetAsync(`p_{player.UserId}`, profile) end)
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
