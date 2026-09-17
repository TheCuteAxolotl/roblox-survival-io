local CraftingData = {}

CraftingData.Categories = {
	"All",
	"Essentials",
	"Materials",
	"Building",
	"Food",
	"Medical",
	"Gear",
	"Armor",
	"Farming",
	"Traps",
	"Potions",
}

CraftingData.Recipes = {
	-- BASIC MATERIALS
	Rope = { Label = "Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Web = 2 } }, Result = { Item = "Rope", Amount = 1 } },
	DesertRope = { Label = "Fiber Rope", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 3 } }, Result = { Item = "Rope", Amount = 1 } },
	Cloth = { Label = "Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { Wheat = 3 } }, Result = { Item = "Cloth", Amount = 1 } },
	DesertCloth = { Label = "Fiber Cloth", Category = "Materials", Rarity = "Common", Station = "Hand", Ingredients = { Items = { CactusFiber = 4 } }, Result = { Item = "Cloth", Amount = 1 } },
	Charcoal = { Label = "Charcoal", Category = "Materials", Rarity = "Common", Station = "Campfire", Ingredients = { Resources = { Wood = 4 } }, Result = { Item = "Charcoal", Amount = 2 } },
	Glass = { Label = "Glass", Category = "Materials", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Sand = 3, Charcoal = 1 } }, Result = { Item = "Glass", Amount = 2 } },
	ReinforcedRope = { Label = "Reinforced Rope", Category = "Materials", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Rope = 2, Web = 2 } }, Result = { Item = "ReinforcedRope", Amount = 1 } },

	-- ESSENTIAL CAMP PROGRESSION
	WorkbenchKit = { Label = "Workbench Kit", Category = "Essentials", Rarity = "Uncommon", Station = "Hand", Ingredients = { Resources = { Wood = 30, Stone = 18 }, Items = { Rope = 1 } }, Result = { Item = "WorkbenchKit", Amount = 1 } },
	FarmPlotKit = { Label = "Farm Plot Kit", Category = "Farming", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 18, Stone = 6 } }, Result = { Item = "FarmPlotKit", Amount = 1 } },
	Torch = { Label = "Torch", Category = "Essentials", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 6 }, Items = { Cloth = 1 } }, Result = { Item = "Torch", Amount = 1 } },
	ChestKit = { Label = "Chest Kit", Category = "Building", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 28, Stone = 12 }, Items = { Rope = 1 } }, Result = { Item = "ChestKit", Amount = 1 } },
	BedKit = { Label = "Bed Kit", Category = "Building", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 20 }, Items = { Cloth = 3, Rope = 1, Fur = 1 } }, Result = { Item = "BedKit", Amount = 1 } },
	-- Kept for existing inventory/save compatibility. The main build hotbar now places Campfires directly.
	CampfireKit = { Label = "Packed Campfire", Category = "Building", Rarity = "Common", Station = "Hand", Ingredients = { Resources = { Wood = 14, Stone = 8 } }, Result = { Item = "CampfireKit", Amount = 1 } },

	-- FOOD: active recovery, never passive regeneration.
	BoneBroth = { Label = "Bone Broth", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Bone = 1, Food = 2, Herb = 1 } }, Result = { Item = "BoneBroth", Amount = 1 } },
	TrailRation = { Label = "Trail Ration", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Food = 2, Wheat = 2 } }, Result = { Item = "TrailRation", Amount = 1 } },
	HerbalTea = { Label = "Herbal Tea", Category = "Food", Rarity = "Uncommon", Station = "Campfire", Ingredients = { Items = { Herb = 2, WaterFlask = 1 } }, Result = { Item = "HerbalTea", Amount = 1 } },

	-- MEDICAL
	Bandage = { Label = "Bandage", Category = "Medical", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Cloth = 1, Herb = 2 } }, Result = { Item = "Bandage", Amount = 2 } },
	FieldDressing = { Label = "Field Dressing", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bandage = 2, Hide = 1 } }, Result = { Item = "FieldDressing", Amount = 1 } },
	Antidote = { Label = "Antidote", Category = "Medical", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 3, Venom = 1 } }, Result = { Item = "Antidote", Amount = 1 } },

	-- TRAVEL / GEAR
	EmptyFlask = { Label = "Empty Water Bottle", Category = "Gear", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Glass = 2, Hide = 1 } }, Result = { Item = "EmptyFlask", Amount = 1 } },
	LeatherPouch = { Label = "Leather Pouch", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 3, Rope = 1 } }, Result = { Item = "LeatherPouch", Amount = 1 } },
	BoneKnife = { Label = "Bone Knife", Category = "Gear", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Bone = 3, Rope = 1 } }, Result = { Item = "BoneKnife", Amount = 1 } },
	FurWrap = { Label = "Fur Wrap", Category = "Gear", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 4, Cloth = 2, ReinforcedRope = 1 } }, Result = { Item = "FurWrap", Amount = 1 } },

	-- ARMOR PATH: grasslands -> snow -> Blackwood -> stone/caves -> dungeon Mythic.
	LeatherArmor = { Label = "Leather Armor", Category = "Armor", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Hide = 6, Rope = 2, Cloth = 1 } }, Result = { Item = "LeatherArmor", Amount = 1 } },
	FurArmor = { Label = "Fur Armor", Category = "Armor", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Fur = 6, Cloth = 3, ReinforcedRope = 1 } }, Result = { Item = "FurArmor", Amount = 1 } },
	RangerArmor = { Label = "Blackwood Ranger Armor", Category = "Armor", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Hide = 5, Fur = 3, MoonSilk = 3, DireFang = 2, Rope = 2 } }, Result = { Item = "RangerArmor", Amount = 1 } },
	StoneplateArmor = { Label = "Stoneplate Armor", Category = "Armor", Rarity = "Epic", Station = "Workbench", Ingredients = { Resources = { Stone = 90 }, Items = { Hide = 4, ReinforcedRope = 2 } }, Result = { Item = "StoneplateArmor", Amount = 1 } },
	DragonforgedArmor = { Label = "Dragonforged Armor", Category = "Armor", Rarity = "Mythic", Station = "Workbench", Ingredients = { Resources = { Stone = 120 }, Items = { DragonScale = 6, DemonCore = 2, ObsidianShard = 4, ReinforcedRope = 2 } }, Result = { Item = "DragonforgedArmor", Amount = 1 } },

	-- TRAPS / FARMING
	SpikeTrapKit = { Label = "Spike Trap Kit", Category = "Traps", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Resources = { Wood = 18, Stone = 10 }, Items = { Rope = 1 } }, Result = { Item = "SpikeTrapKit", Amount = 1 } },
	WebTrapKit = { Label = "Web Trap Kit", Category = "Traps", Rarity = "Rare", Station = "Workbench", Ingredients = { Resources = { Wood = 12 }, Items = { Web = 5, ReinforcedRope = 1 } }, Result = { Item = "WebTrapKit", Amount = 1 } },
	Fertilizer = { Label = "Fertilizer", Category = "Farming", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Food = 1, Wheat = 3, Herb = 1 } }, Result = { Item = "Fertilizer", Amount = 2 } },
	WheatSeeds = { Label = "Wheat Seeds", Category = "Farming", Rarity = "Common", Station = "Workbench", Ingredients = { Items = { Wheat = 2 } }, Result = { Item = "WheatSeeds", Amount = 3 } },

	-- OPTIONAL POWER CONSUMABLES
	HealthPotion = { Label = "Health Potion", Category = "Potions", Rarity = "Uncommon", Station = "Workbench", Ingredients = { Items = { Herb = 3, WaterFlask = 1, Glass = 1 } }, Result = { Item = "HealthPotion", Amount = 1 } },
	SpeedPotion = { Label = "Fleet Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 3, Web = 2, WaterFlask = 1, Glass = 1 } }, Result = { Item = "SpeedPotion", Amount = 1 } },
	FortifyPotion = { Label = "Fortify Potion", Category = "Potions", Rarity = "Rare", Station = "Workbench", Ingredients = { Items = { Herb = 3, Bone = 2, WaterFlask = 1, Glass = 1 } }, Result = { Item = "FortifyPotion", Amount = 1 } },
	SurvivalElixir = { Label = "Survival Elixir", Category = "Potions", Rarity = "Epic", Station = "Workbench", Ingredients = { Items = { Herb = 5, Venom = 2, Fur = 2, WaterFlask = 1, Glass = 2 } }, Result = { Item = "SurvivalElixir", Amount = 1 } },
}

CraftingData.Order = {
	"WorkbenchKit", "Torch",
	"Rope", "DesertRope", "Cloth", "DesertCloth", "Charcoal", "Glass", "ReinforcedRope",
	"BoneBroth", "TrailRation", "HerbalTea",
	"Bandage", "FieldDressing", "Antidote",
	"ChestKit", "BedKit", "FarmPlotKit",
	"EmptyFlask", "LeatherPouch", "BoneKnife", "FurWrap",
	"LeatherArmor", "FurArmor", "RangerArmor", "StoneplateArmor", "DragonforgedArmor",
	"SpikeTrapKit", "WebTrapKit", "Fertilizer", "WheatSeeds",
	"HealthPotion", "SpeedPotion", "FortifyPotion", "SurvivalElixir",
}

return CraftingData
