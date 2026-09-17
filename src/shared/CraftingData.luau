local CraftingData = {}

CraftingData.Recipes = {
	Rope = { Label = "Rope", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Web = 2 } }, Result = { Item = "Rope", Amount = 1 } },
	Cloth = { Label = "Cloth", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Wheat = 3 } }, Result = { Item = "Cloth", Amount = 1 } },
	ReinforcedRope = { Label = "Reinforced Rope", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Rope = 2, Web = 2 } }, Result = { Item = "ReinforcedRope", Amount = 1 } },
	WorkbenchKit = { Label = "Workbench Kit", Rarity = "Uncommon", Station = "Hand", Ingredients = { Resources = { Wood = 30, Stone = 15 }, Items = { Rope = 2 } }, Result = { Item = "WorkbenchKit", Amount = 1 } },
	FarmPlotKit = { Label = "Farm Plot Kit", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 12, Stone = 4 } }, Result = { Item = "FarmPlotKit", Amount = 1 } },
	CampfireKit = { Label = "Campfire Kit", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 18, Stone = 12 } }, Result = { Item = "CampfireKit", Amount = 1 } },
	Torch = { Label = "Torch", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 6 }, Items = { Cloth = 1 } }, Result = { Item = "Torch", Amount = 1 } },
	ChestKit = { Label = "Chest Kit", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 28, Stone = 8 }, Items = { Rope = 1 } }, Result = { Item = "ChestKit", Amount = 1 } },
	Bandage = { Label = "Bandage", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Cloth = 1, Herb = 2 } }, Result = { Item = "Bandage", Amount = 2 } },
	FieldDressing = { Label = "Field Dressing", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bandage = 2, Hide = 1 } }, Result = { Item = "FieldDressing", Amount = 1 } },
	WaterFlask = { Label = "Water Flask", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Hide = 2, Rope = 1 } }, Result = { Item = "WaterFlask", Amount = 1 } },
	HealthPotion = { Label = "Health Potion", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 3, WaterFlask = 1 } }, Result = { Item = "HealthPotion", Amount = 1 } },
	SpeedPotion = { Label = "Fleet Potion", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 2, Web = 2, WaterFlask = 1 } }, Result = { Item = "SpeedPotion", Amount = 1 } },
	FortifyPotion = { Label = "Fortify Potion", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 3, Bone = 2, WaterFlask = 1 } }, Result = { Item = "FortifyPotion", Amount = 1 } },
	SurvivalElixir = { Label = "Survival Elixir", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Herb = 4, Venom = 1, Fur = 1, WaterFlask = 1 } }, Result = { Item = "SurvivalElixir", Amount = 1 } },
	Antidote = { Label = "Antidote", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 2, Venom = 1 } }, Result = { Item = "Antidote", Amount = 1 } },
	SpikeTrapKit = { Label = "Spike Trap Kit", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 18, Stone = 8 }, Items = { Rope = 1 } }, Result = { Item = "SpikeTrapKit", Amount = 1 } },
	WebTrapKit = { Label = "Web Trap Kit", Rarity = "Rare", Station = "Workbench", Ingredients = { Resources = { Wood = 10 }, Items = { Web = 5, ReinforcedRope = 1 } }, Result = { Item = "WebTrapKit", Amount = 1 } },
	Fertilizer = { Label = "Fertilizer", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { RawMeat = 1, Wheat = 2, Herb = 1 } }, Result = { Item = "Fertilizer", Amount = 2 } },
	LeatherPouch = { Label = "Leather Pouch", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 3, Rope = 1 } }, Result = { Item = "LeatherPouch", Amount = 1 } },
	BoneKnife = { Label = "Bone Knife", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bone = 2, Rope = 1 } }, Result = { Item = "BoneKnife", Amount = 1 } },
	FurWrap = { Label = "Fur Wrap", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 4, Cloth = 2, ReinforcedRope = 1 } }, Result = { Item = "FurWrap", Amount = 1 } },
	CookedMeat = { Label = "Cooked Meat", Rarity = "Common", Station = "Campfire", Ingredients = { Items = { RawMeat = 1 } }, Result = { Item = "CookedMeat", Amount = 1 } },
	Charcoal = { Label = "Charcoal", Rarity = "Common", Station = "Campfire", Ingredients = { Resources = { Wood = 4 } }, Result = { Item = "Charcoal", Amount = 2 } },
	BoneBroth = { Label = "Bone Broth", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Bone = 1, RawMeat = 1, Herb = 1 } }, Result = { Item = "BoneBroth", Amount = 1 } },
	TrailRation = { Label = "Trail Ration", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { CookedMeat = 1, Wheat = 2 } }, Result = { Item = "TrailRation", Amount = 1 } },
	HerbalTea = { Label = "Herbal Tea", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Herb = 2, WaterFlask = 1 } }, Result = { Item = "HerbalTea", Amount = 1 } },
	WheatSeeds = { Label = "Wheat Seeds", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Wheat = 2 } }, Result = { Item = "WheatSeeds", Amount = 3 } },
}

CraftingData.Order = {
	"Rope", "Cloth", "WorkbenchKit", "FarmPlotKit", "CampfireKit", "Torch",
	"Bandage", "WaterFlask", "ChestKit", "ReinforcedRope", "FieldDressing", "HealthPotion",
	"SpeedPotion", "FortifyPotion", "Antidote", "SpikeTrapKit", "WebTrapKit", "Fertilizer",
	"LeatherPouch", "BoneKnife", "FurWrap", "CookedMeat", "Charcoal", "BoneBroth",
	"TrailRation", "HerbalTea", "WheatSeeds", "SurvivalElixir",
}

return CraftingData
