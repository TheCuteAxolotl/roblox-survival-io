local KitData = {}

KitData.Order = { "ExplorerKit", "FarmerKit", "HunterKit", "BuilderKit", "AlchemistKit", "DragonbornKit" }
KitData.Kits = {
	ExplorerKit = {
		Label = "Explorer Kit", Cost = 900,
		Description = "Permanent starter-kit unlock: food, water, medicine and a bed kit for new runs.",
		Items = { CookedMeat = 2, WaterFlask = 2, Bandage = 2, BedKit = 1 },
	},
	FarmerKit = {
		Label = "Farmer Kit", Cost = 1500,
		Description = "Permanent starter-kit unlock for farming-focused runs.",
		Items = { WheatSeeds = 8, FarmPlotKit = 2, Fertilizer = 3, WaterFlask = 1 },
	},
	HunterKit = {
		Label = "Hunter Kit", Cost = 2400,
		Description = "Permanent starter-kit unlock with traps, food and basic armor.",
		Items = { TrailRation = 2, Bandage = 2, SpikeTrapKit = 1, Rope = 2, LeatherArmor = 1 },
	},
	BuilderKit = {
		Label = "Builder Kit", Cost = 3600,
		Description = "Permanent starter-kit unlock for quickly establishing a base.",
		Items = { WorkbenchKit = 1, ChestKit = 1, CampfireKit = 1, BedKit = 1, Torch = 3 },
	},
	AlchemistKit = {
		Label = "Alchemist Kit", Cost = 5200,
		Description = "Permanent starter-kit unlock with stronger survival buffs.",
		Items = { HealthPotion = 2, SpeedPotion = 1, FortifyPotion = 1, SurvivalElixir = 1, WaterFlask = 2 },
	},
	DragonbornKit = {
		Label = "Dragonborn Kit", Cost = 9000,
		Description = "Endgame starter kit with strong armor and high-grade supplies. Dungeon collectibles are still dungeon-only.",
		Items = { FurArmor = 1, FieldDressing = 2, CookedBeef = 3, WaterFlask = 3, SpeedPotion = 1, FortifyPotion = 1 },
	},
}

return KitData
