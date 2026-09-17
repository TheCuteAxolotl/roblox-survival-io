local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)

local MonetizationService = {}
local PlayerService = nil
local receiptStore = nil

local productById = {}
for name, product in MonetizationConfig.DeveloperProducts do
	if product.Id and product.Id > 0 then productById[product.Id] = { Name = name, Data = product } end
end

local function receiptKey(receiptInfo)
	return `receipt_{tostring(receiptInfo.PurchaseId)}`
end

local function alreadyGranted(receiptInfo)
	if not receiptStore then return false end
	local ok, value = pcall(function() return receiptStore:GetAsync(receiptKey(receiptInfo)) end)
	return ok and value == true
end

local function markGranted(receiptInfo)
	if not receiptStore then return true end
	local ok = pcall(function() receiptStore:SetAsync(receiptKey(receiptInfo), true) end)
	return ok
end

function MonetizationService.Init(playerService)
	PlayerService = playerService
	if not (RunService:IsStudio() and game.GameId == 0) then
		local ok, result = pcall(function() return DataStoreService:GetDataStore("Wildforge_ProductReceipts_v1") end)
		if ok then receiptStore = result else warn("[Monetization] Receipt DataStore unavailable:", result) end
	end

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local product = productById[receiptInfo.ProductId]
		if not product then
			warn("[Monetization] Unknown developer product ID:", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if alreadyGranted(receiptInfo) then return Enum.ProductPurchaseDecision.PurchaseGranted end

		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if not PlayerService.Add(player, product.Data.Grant or {}) then return Enum.ProductPurchaseDecision.NotProcessedYet end

		-- Save permanent gold immediately before acknowledging the purchase.
		PlayerService.Save(player)
		if not markGranted(receiptInfo) then
			warn("[Monetization] Could not persist receipt marker; purchase will retry:", receiptInfo.PurchaseId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

function MonetizationService.GetCatalog()
	return MonetizationConfig
end

return MonetizationService
