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
}

return MobData
