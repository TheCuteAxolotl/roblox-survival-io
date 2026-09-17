local MonetizationConfig = {}

-- V2 monetization rule: purchases should not sell combat dominance.
-- Keep IDs at 0 until the experience is published and the matching Roblox
-- passes/products actually exist.
MonetizationConfig.DeveloperProducts = {}

MonetizationConfig.GamePasses = {
	InventoryInsurance = {
		Id = 0,
		RobuxLabel = 99,
		Description = "Convenience only: keep the items in your 10-slot bag on death. Carried wood, stone and food resources can still drop.",
	},
	VIP = {
		Id = 0,
		RobuxLabel = 399,
		Description = "Supporter status reserved for cosmetic identity perks, titles and future non-combat extras.",
	},
}

return MonetizationConfig
