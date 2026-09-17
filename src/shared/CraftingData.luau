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
	"Armor",
}

CraftingData.Recipes = {
	Rope = { Label = "Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Web = 3 } }, Result = { Item = "Rope", Amount = 1 } },
	DesertRope = { Label = "Desert Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 4 } }, Result = { Item = "Rope", Amount = 1 } },
	Cloth = { Label = "Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Wheat = 4 } }, Result = { Item = "Cloth", Amount = 1 } },
	DesertCloth = { Label = "Desert Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 5 } }, Result = { Item = "Cloth", Amount = 1 } },
	ReinforcedRope = { Label = "Reinforced Rope", Category = "Materials", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Rope = 3, Web = 3 } }, Result = { Item = "ReinforcedRope", Amount = 1 } },
	Glass = { Label = "Glass", Category = "Materials", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Sand = 4, Charcoal = 1 } }, Result = { Item = "Glass", Amount = 2 } },

	WorkbenchKit = { Label = "Workbench Kit", Category = "Building", Rarity = "Uncommon", Station = "Hand", Ingredients = { Resources = { Wood = 45, Stone = 25 }, Items = { Rope = 3 } }, Result = { Item = "WorkbenchKit", Amount = 1 } },
	FarmPlotKit = { Label = "Farm Plot Kit", Category = "Farming", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 18, Stone = 6 } }, Result = { Item = "FarmPlotKit", Amount = 1 } },
	CampfireKit = { Label = "Campfire Kit", Category = "Building", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 24, Stone = 16 } }, Result = { Item = "CampfireKit", Amount = 1 } },
	Torch = { Label = "Torch", Category = "Building", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 8 }, Items = { Cloth = 1 } }, Result = { Item = "Torch", Amount = 1 } },
	ChestKit = { Label = "Chest Kit", Category = "Building", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 40, Stone = 15 }, Items = { Rope = 2 } }, Result = { Item = "ChestKit", Amount = 1 } },
	BedKit = { Label = "Bed Kit", Category = "Building", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 25 }, Items = { Cloth = 4, Rope = 2, Fur = 1 } }, Result = { Item = "BedKit", Amount = 1 } },

	Bandage = { Label = "Bandage", Category = "Medical", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Cloth = 1, Herb = 3 } }, Result = { Item = "Bandage", Amount = 2 } },
	FieldDressing = { Label = "Field Dressing", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bandage = 3, Hide = 2 } }, Result = { Item = "FieldDressing", Amount = 1 } },
	Antidote = { Label = "Antidote", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 3, Venom = 1 } }, Result = { Item = "Antidote", Amount = 1 } },

	EmptyFlask = { Label = "Empty Water Bottle", Category = "Gear", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Glass = 2, Hide = 1, Rope = 1 } }, Result = { Item = "EmptyFlask", Amount = 1 } },
	HealthPotion = { Label = "Health Potion", Category = "Potions", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 4, WaterFlask = 1, Glass = 1 } }, Result = { Item = "HealthPotion", Amount = 1 } },
	SpeedPotion = { Label = "Fleet Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 3, Web = 3, WaterFlask = 1, Glass = 1 } }, Result = { Item = "SpeedPotion", Amount = 1 } },
	FortifyPotion = { Label = "Fortify Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 4, Bone = 3, WaterFlask = 1, Glass = 1 } }, Result = { Item = "FortifyPotion", Amount = 1 } },
	SurvivalElixir = { Label = "Survival Elixir", Category = "Potions", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Herb = 6, Venom = 2, Fur = 2, WaterFlask = 1, Glass = 2 } }, Result = { Item = "SurvivalElixir", Amount = 1 } },

	SpikeTrapKit = { Label = "Spike Trap Kit", Category = "Traps", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 24, Stone = 12 }, Items = { Rope = 2 } }, Result = { Item = "SpikeTrapKit", Amount = 1 } },
	WebTrapKit = { Label = "Web Trap Kit", Category = "Traps", Rarity = "Rare", Station = "Workbench", Ingredients = { Resources = { Wood = 16 }, Items = { Web = 7, ReinforcedRope = 2 } }, Result = { Item = "WebTrapKit", Amount = 1 } },

	Fertilizer = { Label = "Fertilizer", Category = "Farming", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { RawMeat = 2, Wheat = 3, Herb = 2 } }, Result = { Item = "Fertilizer", Amount = 2 } },
	LeatherPouch = { Label = "Leather Pouch", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 4, Rope = 2 } }, Result = { Item = "LeatherPouch", Amount = 1 } },
	BoneKnife = { Label = "Bone Knife", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bone = 3, Rope = 1 } }, Result = { Item = "BoneKnife", Amount = 1 } },
	FurWrap = { Label = "Fur Wrap", Category = "Gear", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 5, Cloth = 3, ReinforcedRope = 1 } }, Result = { Item = "FurWrap", Amount = 1 } },

	LeatherArmor = { Label = "Leather Armor", Category = "Armor", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 8, Rope = 3, Cloth = 2 } }, Result = { Item = "LeatherArmor", Amount = 1 } },
	FurArmor = { Label = "Fur Armor", Category = "Armor", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 8, Cloth = 4, ReinforcedRope = 2 } }, Result = { Item = "FurArmor", Amount = 1 } },
	RangerArmor = { Label = "Blackwood Ranger Armor", Category = "Armor", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Hide = 6, Fur = 4, MoonSilk = 4, DireFang = 2, Rope = 2 } }, Result = { Item = "RangerArmor", Amount = 1 } },
	StoneplateArmor = { Label = "Stoneplate Armor", Category = "Armor", Rarity = "Epic", Station = "Workbench", Ingredients = { Resources = { Stone = 120 }, Items = { Hide = 4, ReinforcedRope = 2 } }, Result = { Item = "StoneplateArmor", Amount = 1 } },
	DragonforgedArmor = { Label = "Dragonforged Armor", Category = "Armor", Rarity = "Mythic", Station = "Workbench", Ingredients = { Resources = { Stone = 150 }, Items = { DragonScale = 6, DemonCore = 2, ObsidianShard = 4, ReinforcedRope = 2 } }, Result = { Item = "DragonforgedArmor", Amount = 1 } },

	CookedMeat = { Label = "Cooked Meat", Category = "Food", Rarity = "Common", Station = "Campfire", Ingredients = { Items = { RawMeat = 1 } }, Result = { Item = "CookedMeat", Amount = 1 } },
	CookedBeef = { Label = "Cooked Beef", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { RawBeef = 1 } }, Result = { Item = "CookedBeef", Amount = 1 } },
	Charcoal = { Label = "Charcoal", Category = "Materials", Rarity = "Common", Station = "Campfire", Ingredients = { Resources = { Wood = 5 } }, Result = { Item = "Charcoal", Amount = 2 } },
	BoneBroth = { Label = "Bone Broth", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Bone = 1, RawMeat = 1, Herb = 2 } }, Result = { Item = "BoneBroth", Amount = 1 } },
	TrailRation = { Label = "Trail Ration", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { CookedMeat = 1, Wheat = 3 } }, Result = { Item = "TrailRation", Amount = 1 } },
	HerbalTea = { Label = "Herbal Tea", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Herb = 3, WaterFlask = 1 } }, Result = { Item = "HerbalTea", Amount = 1 } },
	WheatSeeds = { Label = "Wheat Seeds", Category = "Farming", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Wheat = 3 } }, Result = { Item = "WheatSeeds", Amount = 3 } },
}

CraftingData.Order = {
	"Rope", "DesertRope", "Cloth", "DesertCloth", "ReinforcedRope", "Glass",
	"WorkbenchKit", "FarmPlotKit", "CampfireKit", "Torch", "ChestKit", "BedKit",
	"Bandage", "FieldDressing", "Antidote", "EmptyFlask", "HealthPotion", "SpeedPotion", "FortifyPotion", "SurvivalElixir",
	"SpikeTrapKit", "WebTrapKit", "Fertilizer", "LeatherPouch", "BoneKnife", "FurWrap",
	"LeatherArmor", "FurArmor", "RangerArmor", "StoneplateArmor", "DragonforgedArmor",
	"CookedMeat", "CookedBeef", "Charcoal", "BoneBroth", "TrailRation", "HerbalTea", "WheatSeeds",
}

return CraftingData
