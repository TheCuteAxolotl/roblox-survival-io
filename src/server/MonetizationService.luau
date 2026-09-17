local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)

local MonetizationService = {}
local PlayerService = nil

local productById = {}
for name, product in MonetizationConfig.DeveloperProducts do
	if product.Id and product.Id > 0 then
		productById[product.Id] = { Name = name, Data = product }
	end
end

function MonetizationService.Init(playerService)
	PlayerService = playerService

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local product = productById[receiptInfo.ProductId]
		if not product then
			warn("[Monetization] Unknown developer product ID:", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if not PlayerService.Add(player, product.Data.Grant or {}) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

function MonetizationService.GetCatalog()
	return MonetizationConfig
end

return MonetizationService
