local MobData = {}

MobData.Mobs = {
	Wolf = {
		Label = "Wolf", Biome = "Grass", Hostile = true, Health = 85, Damage = 18,
		WalkSpeed = 17, AggroRange = 60, AttackRange = 4.5, AttackCooldown = 1.15, Count = 8,
		Color = Color3.fromRGB(112, 112, 118),
		Drops = { { Item = "Food", Min = 1, Max = 2, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.8 } },
	},
	Spider = {
		Label = "Spider", Biome = "Grass", Hostile = true, NightOnly = true, Archetype = "Spider", Health = 42, Damage = 10,
		WalkSpeed = 18, AggroRange = 42, AttackRange = 3.5, AttackCooldown = 0.9, Count = 8,
		Color = Color3.fromRGB(55, 50, 61), PoisonChance = 0.3, Scale = 0.7,
		Drops = { { Item = "Web", Min = 1, Max = 3, Chance = 1 }, { Item = "Venom", Min = 1, Max = 1, Chance = 0.35 } },
	},
	Boar = {
		Label = "Boar", Biome = "Grass", Hostile = true, Health = 120, Damage = 24,
		WalkSpeed = 15, AggroRange = 48, AttackRange = 4.5, AttackCooldown = 1.35, Count = 6,
		Color = Color3.fromRGB(106, 73, 56),
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.55 } },
	},
	Deer = {
		Label = "Deer", Biome = "Grass", Hostile = false, Health = 70, Damage = 0,
		WalkSpeed = 18, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 7,
		Color = Color3.fromRGB(142, 102, 68),
		Drops = { { Item = "Food", Min = 2, Max = 3, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 1 } },
	},
	WildCattle = {
		Label = "Wild Cattle", Biome = "Grass", Hostile = false, Health = 145, Damage = 0,
		WalkSpeed = 12, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 5,
		Color = Color3.fromRGB(128, 91, 62), Scale = 1.15,
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 3, Chance = 1 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.5 } },
	},
	SnowWolf = {
		Label = "Snow Wolf", Biome = "Snow", Hostile = true, Health = 105, Damage = 22,
		WalkSpeed = 18, AggroRange = 68, AttackRange = 4.5, AttackCooldown = 1.1, Count = 7,
		Color = Color3.fromRGB(207, 218, 225), Scale = 1.05,
		Drops = { { Item = "Food", Min = 1, Max = 3, Chance = 1 }, { Item = "Fur", Min = 1, Max = 2, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 1, Chance = 0.45 } },
	},
	SnowBear = {
		Label = "Snow Bear", Biome = "Snow", Hostile = true, Health = 260, Damage = 38,
		WalkSpeed = 13, AggroRange = 72, AttackRange = 5.5, AttackCooldown = 1.6, Count = 3,
		Color = Color3.fromRGB(225, 229, 231), Scale = 1.65,
		Drops = { { Item = "Food", Min = 4, Max = 6, Chance = 1 }, { Item = "Fur", Min = 2, Max = 4, Chance = 1 }, { Item = "Bone", Min = 2, Max = 4, Chance = 0.9 } },
	},
	Scorpion = {
		Label = "Dune Scorpion", Biome = "Desert", Hostile = true, Archetype = "Scorpion", Health = 58, Damage = 15,
		WalkSpeed = 17, AggroRange = 46, AttackRange = 3.6, AttackCooldown = 0.95, Count = 10,
		Color = Color3.fromRGB(129, 88, 49), PoisonChance = 0.5, Scale = 0.7,
		Drops = { { Item = "Venom", Min = 1, Max = 2, Chance = 0.65 }, { Item = "Bone", Min = 1, Max = 1, Chance = 0.25 } },
	},

	-- Blackwood Forest: intentionally stronger than normal grassland wildlife.
	DireWolf = {
		Label = "Dire Wolf", Biome = "Forest", Hostile = true, Health = 185, Damage = 31,
		WalkSpeed = 19, AggroRange = 78, AttackRange = 5, AttackCooldown = 1.05, Count = 5,
		Color = Color3.fromRGB(61, 68, 62), Scale = 1.18, GoldReward = 12, XPReward = 24,
		Drops = {
			{ Item = "Food", Min = 2, Max = 4, Chance = 1 },
			{ Item = "Hide", Min = 1, Max = 2, Chance = 0.9 },
			{ Item = "DireFang", Min = 1, Max = 2, Chance = 0.6 },
		},
	},
	BroodSpider = {
		Label = "Blackwood Brood Spider", Biome = "Forest", Hostile = true, NightOnly = true, Archetype = "Spider", Health = 98, Damage = 19,
		WalkSpeed = 20, AggroRange = 58, AttackRange = 4, AttackCooldown = 0.8, Count = 5,
		Color = Color3.fromRGB(40, 48, 43), PoisonChance = 0.55, Scale = 0.9, GoldReward = 10, XPReward = 18,
		Drops = {
			{ Item = "Web", Min = 2, Max = 4, Chance = 1 },
			{ Item = "Venom", Min = 1, Max = 2, Chance = 0.7 },
			{ Item = "MoonSilk", Min = 1, Max = 2, Chance = 0.45 },
		},
	},
	ForestBear = {
		Label = "Blackwood Bear", Biome = "Forest", Hostile = true, Health = 350, Damage = 45,
		WalkSpeed = 14, AggroRange = 82, AttackRange = 6, AttackCooldown = 1.5, Count = 2,
		Color = Color3.fromRGB(56, 63, 50), Scale = 1.8, GoldReward = 22, XPReward = 45,
		Drops = {
			{ Item = "Food", Min = 4, Max = 7, Chance = 1 },
			{ Item = "Hide", Min = 2, Max = 4, Chance = 1 },
			{ Item = "Fur", Min = 2, Max = 4, Chance = 0.9 },
			{ Item = "ForestHeart", Min = 1, Max = 1, Chance = 0.12 },
		},
	},
	FrostRam = {
		Label = "Frost Ram", Biome = "Highlands", Hostile = false, Archetype = "Deer", Health = 150, Damage = 0,
		WalkSpeed = 19, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 4,
		Color = Color3.fromRGB(191, 202, 211), Scale = 1.12,
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Fur", Min = 1, Max = 2, Chance = 0.85 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.5 } },
	},
	IceGolem = {
		Label = "Icebound Golem", Biome = "Highlands", Hostile = true, Archetype = "Golem", Health = 460, Damage = 52,
		WalkSpeed = 10, AggroRange = 72, AttackRange = 6.5, AttackCooldown = 1.55, Count = 3,
		Color = Color3.fromRGB(129, 151, 166), Scale = 1.45, GoldReward = 28, XPReward = 58,
		Drops = { { Item = "ObsidianShard", Min = 1, Max = 1, Chance = 0.18 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.45 } },
	},
	SandHyena = {
		Label = "Sand Hyena", Biome = "Dunes", Hostile = true, Archetype = "Canine", Health = 135, Damage = 25,
		WalkSpeed = 21, AggroRange = 70, AttackRange = 4.8, AttackCooldown = 0.95, Count = 5,
		Color = Color3.fromRGB(173, 137, 82), Scale = 0.95, GoldReward = 7, XPReward = 16,
		Drops = { { Item = "Food", Min = 1, Max = 3, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.8 }, { Item = "Bone", Min = 1, Max = 1, Chance = 0.4 } },
	},
	DuneTitan = {
		Label = "Dune Titan Scorpion", Biome = "Dunes", Hostile = true, Archetype = "Scorpion", Health = 310, Damage = 38,
		WalkSpeed = 16, AggroRange = 68, AttackRange = 5, AttackCooldown = 1.0, Count = 3,
		Color = Color3.fromRGB(153, 87, 45), PoisonChance = 0.7, Scale = 1.35, GoldReward = 18, XPReward = 38,
		Drops = { { Item = "Venom", Min = 2, Max = 4, Chance = 1 }, { Item = "Bone", Min = 1, Max = 3, Chance = 0.55 } },
	},
	MireBoar = {
		Label = "Mire Boar", Biome = "Marsh", Hostile = true, Archetype = "Boar", Health = 210, Damage = 33,
		WalkSpeed = 17, AggroRange = 58, AttackRange = 5, AttackCooldown = 1.15, Count = 4,
		Color = Color3.fromRGB(74, 91, 65), Scale = 1.18, GoldReward = 10, XPReward = 24,
		Drops = { { Item = "Food", Min = 3, Max = 5, Chance = 1 }, { Item = "Hide", Min = 1, Max = 3, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.6 } },
	},
	BogCrawler = {
		Label = "Bog Crawler", Biome = "Marsh", Hostile = true, NightOnly = true, Archetype = "Spider", Health = 125, Damage = 21,
		WalkSpeed = 20, AggroRange = 58, AttackRange = 4, AttackCooldown = 0.78, Count = 5,
		Color = Color3.fromRGB(52, 78, 58), PoisonChance = 0.62, Scale = 1.02, GoldReward = 9, XPReward = 20,
		Drops = { { Item = "Web", Min = 2, Max = 4, Chance = 1 }, { Item = "Venom", Min = 1, Max = 2, Chance = 0.75 } },
	},
	EmberStag = {
		Label = "Ember Stag", Biome = "Grove", Hostile = false, Archetype = "Deer", Health = 170, Damage = 0,
		WalkSpeed = 21, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 4,
		Color = Color3.fromRGB(162, 76, 51), Scale = 1.22, GoldReward = 5, XPReward = 14,
		Drops = { { Item = "Food", Min = 3, Max = 5, Chance = 1 }, { Item = "Hide", Min = 2, Max = 3, Chance = 1 }, { Item = "ForestHeart", Min = 1, Max = 1, Chance = 0.025 } },
	},
	EmberWolf = {
		Label = "Ember Wolf", Biome = "Grove", Hostile = true, Archetype = "Canine", Health = 190, Damage = 31,
		WalkSpeed = 22, AggroRange = 76, AttackRange = 5, AttackCooldown = 0.9, Count = 5,
		Color = Color3.fromRGB(104, 53, 46), Scale = 1.08, GoldReward = 11, XPReward = 25,
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.85 }, { Item = "DireFang", Min = 1, Max = 1, Chance = 0.22 } },
	},
	CrystalGolem = {
		Label = "Crystal Golem", Biome = "Crystal", Hostile = true, Archetype = "Golem", Health = 560, Damage = 57,
		WalkSpeed = 11, AggroRange = 78, AttackRange = 7, AttackCooldown = 1.45, Count = 3,
		Color = Color3.fromRGB(87, 104, 132), Scale = 1.55, GoldReward = 34, XPReward = 72,
		Drops = { { Item = "ObsidianShard", Min = 1, Max = 2, Chance = 0.5 }, { Item = "AncientRelic", Min = 1, Max = 1, Chance = 0.004 } },
	},
	Mammoth = {
		Label = "Woolly Mammoth", Biome = "Highlands", Hostile = false, Archetype = "Mammoth", Health = 520, Damage = 0,
		WalkSpeed = 12, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 2,
		Color = Color3.fromRGB(116, 92, 76), Scale = 1.65,
		Drops = { { Item = "Food", Min = 6, Max = 10, Chance = 1 }, { Item = "Fur", Min = 3, Max = 6, Chance = 1 }, { Item = "Bone", Min = 3, Max = 6, Chance = 1 } },
	},

	GlacierLeopard = {
		Label = "Glacier Leopard", Biome = "Highlands", Hostile = true, Archetype = "Canine", Health = 230, Damage = 34,
		WalkSpeed = 23, AggroRange = 82, AttackRange = 5, AttackCooldown = 0.82, Count = 4,
		Color = Color3.fromRGB(178, 194, 207), Scale = 0.98, GoldReward = 13, XPReward = 30,
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Fur", Min = 1, Max = 3, Chance = 0.9 }, { Item = "DireFang", Min = 1, Max = 1, Chance = 0.18 } },
	},
	SandBoar = {
		Label = "Razorback Dune Boar", Biome = "Dunes", Hostile = true, Archetype = "Boar", Health = 245, Damage = 39,
		WalkSpeed = 18, AggroRange = 60, AttackRange = 5.4, AttackCooldown = 1.05, Count = 4,
		Color = Color3.fromRGB(153, 111, 69), Scale = 1.22, GoldReward = 12, XPReward = 28,
		Drops = { { Item = "Food", Min = 3, Max = 5, Chance = 1 }, { Item = "Hide", Min = 1, Max = 3, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.6 } },
	},
	MarshBear = {
		Label = "Mire Bear", Biome = "Marsh", Hostile = true, Archetype = "Bear", Health = 420, Damage = 50,
		WalkSpeed = 15, AggroRange = 76, AttackRange = 6.2, AttackCooldown = 1.35, Count = 3,
		Color = Color3.fromRGB(66, 76, 58), Scale = 1.7, GoldReward = 24, XPReward = 50,
		Drops = { { Item = "Food", Min = 4, Max = 7, Chance = 1 }, { Item = "Hide", Min = 2, Max = 4, Chance = 1 }, { Item = "Fur", Min = 1, Max = 3, Chance = 0.75 } },
	},
	AshHound = {
		Label = "Ash Hound", Biome = "Grove", Hostile = true, Archetype = "Canine", Health = 260, Damage = 38,
		WalkSpeed = 24, AggroRange = 86, AttackRange = 5.2, AttackCooldown = 0.76, Count = 4,
		Color = Color3.fromRGB(77, 53, 49), Scale = 1.02, GoldReward = 15, XPReward = 32,
		Drops = { { Item = "Food", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.85 }, { Item = "DireFang", Min = 1, Max = 1, Chance = 0.24 } },
	},
	CrystalStag = {
		Label = "Prism Stag", Biome = "Crystal", Hostile = false, Archetype = "Deer", Health = 190, Damage = 0,
		WalkSpeed = 23, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 4,
		Color = Color3.fromRGB(111, 130, 171), Scale = 1.2, GoldReward = 8, XPReward = 18,
		Drops = { { Item = "Food", Min = 3, Max = 5, Chance = 1 }, { Item = "Hide", Min = 2, Max = 3, Chance = 1 }, { Item = "ObsidianShard", Min = 1, Max = 1, Chance = 0.08 } },
	},

}

return MobData
