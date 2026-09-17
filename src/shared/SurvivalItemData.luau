local SurvivalItemData = {}

SurvivalItemData.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
SurvivalItemData.RarityColors = {
	Common = Color3.fromRGB(205, 205, 205),
	Uncommon = Color3.fromRGB(104, 205, 120),
	Rare = Color3.fromRGB(94, 151, 245),
	Epic = Color3.fromRGB(180, 103, 238),
	Legendary = Color3.fromRGB(245, 185, 67),
}

SurvivalItemData.Items = {
	Web = { Label = "Spider Web", Rarity = "Common", Stack = 20, Description = "Sticky web used for rope, traps, and potions." },
	Venom = { Label = "Spider Venom", Rarity = "Uncommon", Stack = 12, Description = "Dangerous alchemy ingredient dropped by spiders and scorpions." },
	RawMeat = { Label = "Raw Meat", Rarity = "Common", Stack = 12, Description = "Cook it before eating for the best result." },
	RawBeef = { Label = "Raw Beef", Rarity = "Common", Stack = 12, Description = "Fresh beef from wild cattle. Cook it at a campfire." },
	Hide = { Label = "Animal Hide", Rarity = "Common", Stack = 16, Description = "Useful for flasks, pouches, and survival gear." },
	Bone = { Label = "Bone", Rarity = "Common", Stack = 20, Description = "Hard crafting material dropped by larger animals." },
	Fur = { Label = "Thick Fur", Rarity = "Uncommon", Stack = 12, Description = "Warm fur found mostly on snow-biome animals." },
	Herb = { Label = "Wild Herb", Rarity = "Common", Stack = 20, Description = "A basic medicine and potion ingredient." },
	Wheat = { Label = "Wheat", Rarity = "Common", Stack = 20, Description = "Harvested crop used for cloth, food, and more seeds." },
	WheatSeeds = { Label = "Wheat Seeds", Rarity = "Common", Stack = 20, Description = "Use near an empty farm plot to grow wheat.", Use = "Seed", Crop = "Wheat" },
	CactusFiber = { Label = "Cactus Fiber", Rarity = "Common", Stack = 20, Description = "Dry desert fiber useful for cloth and rope." },
	Charcoal = { Label = "Charcoal", Rarity = "Common", Stack = 20, Description = "Fuel and alchemy material made at a campfire." },
	Rope = { Label = "Rope", Rarity = "Common", Stack = 16, Description = "Basic construction and crafting component." },
	Cloth = { Label = "Cloth", Rarity = "Common", Stack = 16, Description = "Soft material used for medicine and equipment." },
	ReinforcedRope = { Label = "Reinforced Rope", Rarity = "Uncommon", Stack = 12, Description = "Strong rope woven with web." },
	LeatherPouch = { Label = "Leather Pouch", Rarity = "Uncommon", Stack = 6, Description = "Valuable crafted trade item." },
	BoneKnife = { Label = "Bone Knife", Rarity = "Uncommon", Stack = 4, Description = "A compact crafted survival knife." },
	Bandage = { Label = "Bandage", Rarity = "Common", Stack = 10, Description = "Restores 28 health.", Use = "Heal", Heal = 28 },
	FieldDressing = { Label = "Field Dressing", Rarity = "Uncommon", Stack = 8, Description = "Heavy bandage that restores 55 health.", Use = "Heal", Heal = 55 },
	CookedMeat = { Label = "Cooked Meat", Rarity = "Common", Stack = 10, Description = "Restores 32 hunger and 8 health.", Use = "Food", Hunger = 32, Heal = 8 },
	CookedBeef = { Label = "Cooked Beef", Rarity = "Uncommon", Stack = 10, Description = "A filling steak. Restores 65 hunger and 22 health.", Use = "Food", Hunger = 65, Heal = 22 },
	TrailRation = { Label = "Trail Ration", Rarity = "Uncommon", Stack = 8, Description = "Compact food that restores a lot of hunger.", Use = "Food", Hunger = 52, Heal = 5 },
	BoneBroth = { Label = "Bone Broth", Rarity = "Uncommon", Stack = 6, Description = "Warm meal restoring hunger, thirst, and health.", Use = "Meal", Hunger = 38, Thirst = 20, Heal = 18 },
	HerbalTea = { Label = "Herbal Tea", Rarity = "Uncommon", Stack = 8, Description = "Restores thirst and a small amount of health.", Use = "Drink", Thirst = 38, Heal = 10 },
	EmptyFlask = { Label = "Empty Flask", Rarity = "Common", Stack = 6, Description = "Fill this at a river drinking point." },
	WaterFlask = { Label = "Water Flask", Rarity = "Common", Stack = 6, Description = "Filled river water. Drinking it leaves an empty flask.", Use = "Drink", Thirst = 48, ReturnsItem = "EmptyFlask" },
	HealthPotion = { Label = "Health Potion", Rarity = "Uncommon", Stack = 6, Description = "Instantly restores 45 health.", Use = "Heal", Heal = 45 },
	SpeedPotion = { Label = "Fleet Potion", Rarity = "Rare", Stack = 4, Description = "+5 movement speed for 25 seconds.", Use = "Buff", Buff = "Speed", Amount = 5, Duration = 25 },
	FortifyPotion = { Label = "Fortify Potion", Rarity = "Rare", Stack = 4, Description = "+35 maximum health for 30 seconds.", Use = "Buff", Buff = "Fortify", Amount = 35, Duration = 30 },
	SurvivalElixir = { Label = "Survival Elixir", Rarity = "Epic", Stack = 3, Description = "Hunger and thirst stop draining for 90 seconds.", Use = "Buff", Buff = "NoNeeds", Duration = 90 },
	Antidote = { Label = "Antidote", Rarity = "Uncommon", Stack = 5, Description = "Immediately removes poison effects.", Use = "Antidote" },
	FurWrap = { Label = "Fur Wrap", Rarity = "Rare", Stack = 3, Description = "Greatly reduces snow slowdown for 120 seconds.", Use = "Buff", Buff = "ColdResist", Duration = 120 },
	Fertilizer = { Label = "Fertilizer", Rarity = "Uncommon", Stack = 10, Description = "Use near a growing crop to instantly advance its growth.", Use = "Fertilizer" },
	Torch = { Label = "Torch", Rarity = "Common", Stack = 6, Description = "Place a temporary light source.", Use = "Place", Structure = "Torch" },
	WorkbenchKit = { Label = "Workbench Kit", Rarity = "Uncommon", Stack = 3, Description = "Places a crafting workbench for advanced recipes.", Use = "Place", Structure = "Workbench" },
	ChestKit = { Label = "Chest Kit", Rarity = "Uncommon", Stack = 3, Description = "Places a session-only storage chest with 8 slots.", Use = "Place", Structure = "Chest" },
	FarmPlotKit = { Label = "Farm Plot Kit", Rarity = "Common", Stack = 5, Description = "Places soil where crops can be planted.", Use = "Place", Structure = "FarmPlot" },
	CampfireKit = { Label = "Campfire Kit", Rarity = "Common", Stack = 4, Description = "Places a campfire for cooking recipes.", Use = "Place", Structure = "SurvivalCampfire" },
	SpikeTrapKit = { Label = "Spike Trap Kit", Rarity = "Uncommon", Stack = 5, Description = "Places a damaging survival trap.", Use = "Place", Structure = "SurvivalSpikeTrap" },
	WebTrapKit = { Label = "Web Trap Kit", Rarity = "Rare", Stack = 4, Description = "Places a sticky trap that slows enemies.", Use = "Place", Structure = "WebTrap" },
}

function SurvivalItemData.Get(itemName)
	return SurvivalItemData.Items[itemName]
end

function SurvivalItemData.StackLimit(itemName)
	local item = SurvivalItemData.Items[itemName]
	return item and item.Stack or 1
end

return SurvivalItemData
