local MonetizationConfig = {}

-- Replace every Id = 0 with the real Roblox product/pass ID after publishing.
-- RobuxLabel is only a design/display value; Roblox controls the real storefront price.
MonetizationConfig.DeveloperProducts = {
	GoldPouch = { Id = 0, RobuxLabel = 99, Grant = { Gold = 650 } },
	GoldChest = { Id = 0, RobuxLabel = 249, Grant = { Gold = 1900 } },
	GoldVault = { Id = 0, RobuxLabel = 499, Grant = { Gold = 4500 } },
	GoldTreasury = { Id = 0, RobuxLabel = 999, Grant = { Gold = 10500 } },
	GoldFortune = { Id = 0, RobuxLabel = 1499, Grant = { Gold = 18000 } },
}

MonetizationConfig.GamePasses = {
	InventoryInsurance = {
		Id = 0,
		RobuxLabel = 99,
		Description = "Keep your 10-slot survival inventory on death. Wood, stone and carried resource counters still drop.",
	},
	ExplorerStarter = { Id = 0, RobuxLabel = 249, PremiumKit = "ExplorerKit" },
	HunterStarter = { Id = 0, RobuxLabel = 499, PremiumKit = "HunterKit" },
	BuilderStarter = { Id = 0, RobuxLabel = 699, PremiumKit = "BuilderKit" },
	AlchemistStarter = { Id = 0, RobuxLabel = 999, PremiumKit = "AlchemistKit" },
	DragonbornStarter = { Id = 0, RobuxLabel = 1499, PremiumKit = "DragonbornKit" },
	VIP = { Id = 0, RobuxLabel = 599 },
}

return MonetizationConfig
