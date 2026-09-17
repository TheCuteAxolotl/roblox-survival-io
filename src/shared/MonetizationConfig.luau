local MonetizationConfig = {}

-- Replace 0 with real Roblox product/pass IDs after publishing the experience.
MonetizationConfig.DeveloperProducts = {
	SmallResourceCrate = { Id = 0, RobuxLabel = 49, Grant = { Wood = 250, Stone = 150, Food = 5 } },
	LargeResourceCrate = { Id = 0, RobuxLabel = 149, Grant = { Wood = 900, Stone = 600, Food = 15 } },
	GoldPack = { Id = 0, RobuxLabel = 99, Grant = { Gold = 500 } },
}

MonetizationConfig.GamePasses = {
	VIP = { Id = 0, RobuxLabel = 399 },
	Builder = { Id = 0, RobuxLabel = 249 },
}

return MonetizationConfig
