local KitData = {}

KitData.Order = { "ExplorerKit", "FarmerKit", "HunterKit", "BuilderKit", "AlchemistKit" }
KitData.Kits = {
	ExplorerKit = {
		Label = "Explorer Kit", Cost = 150,
		Description = "A simple food, water, and medicine starter pack.",
		Items = { CookedMeat = 2, WaterFlask = 1, Bandage = 2 },
	},
	FarmerKit = {
		Label = "Farmer Kit", Cost = 250,
		Description = "Start a small farm immediately.",
		Items = { WheatSeeds = 6, FarmPlotKit = 2, Fertilizer = 2 },
	},
	HunterKit = {
		Label = "Hunter Kit", Cost = 325,
		Description = "Supplies for surviving animal-heavy areas.",
		Items = { TrailRation = 2, Bandage = 2, SpikeTrapKit = 1, Rope = 2 },
	},
	BuilderKit = {
		Label = "Builder Kit", Cost = 425,
		Description = "Quick access to crafting and session storage.",
		Items = { WorkbenchKit = 1, ChestKit = 1, CampfireKit = 1, Torch = 2 },
	},
	AlchemistKit = {
		Label = "Alchemist Kit", Cost = 600,
		Description = "Rare temporary buffs for dangerous runs.",
		Items = { HealthPotion = 2, SpeedPotion = 1, FortifyPotion = 1, SurvivalElixir = 1 },
	},
}

return KitData
