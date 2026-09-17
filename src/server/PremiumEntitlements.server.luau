local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local passById = {}
for passName, data in MonetizationConfig.GamePasses or {} do
	if data.Id and data.Id > 0 then passById[data.Id] = { Name = passName, Data = data } end
end

local function waitForProfile(player)
	for _ = 1, 80 do
		local profile = PlayerService.Get(player)
		if profile then return profile end
		task.wait(0.1)
	end
	return nil
end

local function grantPremiumKit(player, kitName)
	local profile = waitForProfile(player)
	if not profile or type(kitName) ~= "string" then return end
	profile.OwnedKits = profile.OwnedKits or {}
	profile.OwnedKits[kitName] = true
	if not profile.EquippedKit then profile.EquippedKit = kitName end
	PlayerService.Save(player)
end

local function scanPlayer(player)
	local profile = waitForProfile(player)
	if not profile then return end
	for _, pass in MonetizationConfig.GamePasses or {} do
		if pass.Id and pass.Id > 0 then
			local ok, owned = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id) end)
			if ok and owned then
				if pass.PremiumKit then grantPremiumKit(player, pass.PremiumKit) end
			end
		end
	end
	InventoryService.RefreshEntitlements(player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(scanPlayer, player)
end)
for _, player in Players:GetPlayers() do task.spawn(scanPlayer, player) end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end
	local pass = passById[gamePassId]
	if not pass then return end
	if pass.Data.PremiumKit then grantPremiumKit(player, pass.Data.PremiumKit) end
	if pass.Name == "InventoryInsurance" then InventoryService.RefreshEntitlements(player) end
end)
