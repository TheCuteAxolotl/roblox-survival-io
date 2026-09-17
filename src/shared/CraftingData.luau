local CraftingData = {}

CraftingData.Categories = {
	"All",
	"Materials",
	"Building",
	"Medical",
	"Potions",
	"Food",
	"Farming",
	"Traps",
	"Gear",
}

CraftingData.Recipes = {
	Rope = { Label = "Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Web = 2 } }, Result = { Item = "Rope", Amount = 1 } },
	DesertRope = { Label = "Desert Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 3 } }, Result = { Item = "Rope", Amount = 1 } },
	Cloth = { Label = "Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Wheat = 3 } }, Result = { Item = "Cloth", Amount = 1 } },
	DesertCloth = { Label = "Desert Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 4 } }, Result = { Item = "Cloth", Amount = 1 } },
	ReinforcedRope = { Label = "Reinforced Rope", Category = "Materials", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Rope = 2, Web = 2 } }, Result = { Item = "ReinforcedRope", Amount = 1 } },

	WorkbenchKit = { Label = "Workbench Kit", Category = "Building", Rarity = "Uncommon", Station = "Hand", Ingredients = { Resources = { Wood = 30, Stone = 15 }, Items = { Rope = 2 } }, Result = { Item = "WorkbenchKit", Amount = 1 } },
	FarmPlotKit = { Label = "Farm Plot Kit", Category = "Farming", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 12, Stone = 4 } }, Result = { Item = "FarmPlotKit", Amount = 1 } },
	CampfireKit = { Label = "Campfire Kit", Category = "Building", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 18, Stone = 12 } }, Result = { Item = "CampfireKit", Amount = 1 } },
	Torch = { Label = "Torch", Category = "Building", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 6 }, Items = { Cloth = 1 } }, Result = { Item = "Torch", Amount = 1 } },
	ChestKit = { Label = "Chest Kit", Category = "Building", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 28, Stone = 8 }, Items = { Rope = 1 } }, Result = { Item = "ChestKit", Amount = 1 } },

	Bandage = { Label = "Bandage", Category = "Medical", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Cloth = 1, Herb = 2 } }, Result = { Item = "Bandage", Amount = 2 } },
	FieldDressing = { Label = "Field Dressing", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bandage = 2, Hide = 1 } }, Result = { Item = "FieldDressing", Amount = 1 } },
	EmptyFlask = { Label = "Empty Flask", Category = "Gear", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Hide = 2, Rope = 1 } }, Result = { Item = "EmptyFlask", Amount = 1 } },

	HealthPotion = { Label = "Health Potion", Category = "Potions", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 3, WaterFlask = 1 } }, Result = { Item = "HealthPotion", Amount = 1 } },
	SpeedPotion = { Label = "Fleet Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 2, Web = 2, WaterFlask = 1 } }, Result = { Item = "SpeedPotion", Amount = 1 } },
	FortifyPotion = { Label = "Fortify Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 3, Bone = 2, WaterFlask = 1 } }, Result = { Item = "FortifyPotion", Amount = 1 } },
	SurvivalElixir = { Label = "Survival Elixir", Category = "Potions", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Herb = 4, Venom = 1, Fur = 1, WaterFlask = 1 } }, Result = { Item = "SurvivalElixir", Amount = 1 } },
	Antidote = { Label = "Antidote", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 2, Venom = 1 } }, Result = { Item = "Antidote", Amount = 1 } },

	SpikeTrapKit = { Label = "Spike Trap Kit", Category = "Traps", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 18, Stone = 8 }, Items = { Rope = 1 } }, Result = { Item = "SpikeTrapKit", Amount = 1 } },
	WebTrapKit = { Label = "Web Trap Kit", Category = "Traps", Rarity = "Rare", Station = "Workbench", Ingredients = { Resources = { Wood = 10 }, Items = { Web = 5, ReinforcedRope = 1 } }, Result = { Item = "WebTrapKit", Amount = 1 } },

	Fertilizer = { Label = "Fertilizer", Category = "Farming", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { RawMeat = 1, Wheat = 2, Herb = 1 } }, Result = { Item = "Fertilizer", Amount = 2 } },
	LeatherPouch = { Label = "Leather Pouch", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 3, Rope = 1 } }, Result = { Item = "LeatherPouch", Amount = 1 } },
	BoneKnife = { Label = "Bone Knife", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bone = 2, Rope = 1 } }, Result = { Item = "BoneKnife", Amount = 1 } },
	FurWrap = { Label = "Fur Wrap", Category = "Gear", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 4, Cloth = 2, ReinforcedRope = 1 } }, Result = { Item = "FurWrap", Amount = 1 } },

	CookedMeat = { Label = "Cooked Meat", Category = "Food", Rarity = "Common", Station = "Campfire", Ingredients = { Items = { RawMeat = 1 } }, Result = { Item = "CookedMeat", Amount = 1 } },
	CookedBeef = { Label = "Cooked Beef", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { RawBeef = 1 } }, Result = { Item = "CookedBeef", Amount = 1 } },
	Charcoal = { Label = "Charcoal", Category = "Materials", Rarity = "Common", Station = "Campfire", Ingredients = { Resources = { Wood = 4 } }, Result = { Item = "Charcoal", Amount = 2 } },
	BoneBroth = { Label = "Bone Broth", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Bone = 1, RawMeat = 1, Herb = 1 } }, Result = { Item = "BoneBroth", Amount = 1 } },
	TrailRation = { Label = "Trail Ration", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { CookedMeat = 1, Wheat = 2 } }, Result = { Item = "TrailRation", Amount = 1 } },
	HerbalTea = { Label = "Herbal Tea", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Herb = 2, WaterFlask = 1 } }, Result = { Item = "HerbalTea", Amount = 1 } },
	WheatSeeds = { Label = "Wheat Seeds", Category = "Farming", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Wheat = 2 } }, Result = { Item = "WheatSeeds", Amount = 3 } },
}

CraftingData.Order = {
	"Rope", "DesertRope", "Cloth", "DesertCloth", "WorkbenchKit", "FarmPlotKit", "CampfireKit", "Torch",
	"Bandage", "EmptyFlask", "ChestKit", "ReinforcedRope", "FieldDressing", "HealthPotion",
	"SpeedPotion", "FortifyPotion", "Antidote", "SpikeTrapKit", "WebTrapKit", "Fertilizer",
	"LeatherPouch", "BoneKnife", "FurWrap", "CookedMeat", "CookedBeef", "Charcoal", "BoneBroth",
	"TrailRation", "HerbalTea", "WheatSeeds", "SurvivalElixir",
}

return CraftingData
