local MobData = {}

MobData.Mobs = {
	Wolf = {
		Label = "Wolf", Biome = "Grass", Hostile = true, Health = 85, Damage = 14,
		WalkSpeed = 17, AggroRange = 60, AttackRange = 4.5, AttackCooldown = 1.15, Count = 8,
		Color = Color3.fromRGB(112, 112, 118),
		Drops = { { Item = "RawMeat", Min = 1, Max = 2, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.8 } },
	},
	Spider = {
		Label = "Spider", Biome = "Grass", Hostile = true, Health = 42, Damage = 8,
		WalkSpeed = 18, AggroRange = 42, AttackRange = 3.5, AttackCooldown = 0.9, Count = 10,
		Color = Color3.fromRGB(55, 50, 61), PoisonChance = 0.3,
		Drops = { { Item = "Web", Min = 1, Max = 3, Chance = 1 }, { Item = "Venom", Min = 1, Max = 1, Chance = 0.35 } },
	},
	Boar = {
		Label = "Boar", Biome = "Grass", Hostile = true, Health = 120, Damage = 18,
		WalkSpeed = 15, AggroRange = 48, AttackRange = 4.5, AttackCooldown = 1.35, Count = 6,
		Color = Color3.fromRGB(106, 73, 56),
		Drops = { { Item = "RawMeat", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.55 } },
	},
	Deer = {
		Label = "Deer", Biome = "Grass", Hostile = false, Health = 70, Damage = 0,
		WalkSpeed = 18, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 7,
		Color = Color3.fromRGB(142, 102, 68),
		Drops = { { Item = "RawMeat", Min = 2, Max = 3, Chance = 1 }, { Item = "Hide", Min = 1, Max = 2, Chance = 1 } },
	},
	WildCattle = {
		Label = "Wild Cattle", Biome = "Grass", Hostile = false, Health = 145, Damage = 0,
		WalkSpeed = 12, AggroRange = 0, AttackRange = 0, AttackCooldown = 1, Count = 5,
		Color = Color3.fromRGB(128, 91, 62),
		Drops = { { Item = "RawBeef", Min = 2, Max = 4, Chance = 1 }, { Item = "Hide", Min = 1, Max = 3, Chance = 1 }, { Item = "Bone", Min = 1, Max = 2, Chance = 0.5 } },
	},
	SnowWolf = {
		Label = "Snow Wolf", Biome = "Snow", Hostile = true, Health = 105, Damage = 17,
		WalkSpeed = 18, AggroRange = 68, AttackRange = 4.5, AttackCooldown = 1.1, Count = 7,
		Color = Color3.fromRGB(207, 218, 225),
		Drops = { { Item = "RawMeat", Min = 1, Max = 3, Chance = 1 }, { Item = "Fur", Min = 1, Max = 2, Chance = 0.9 }, { Item = "Bone", Min = 1, Max = 1, Chance = 0.45 } },
	},
	SnowBear = {
		Label = "Snow Bear", Biome = "Snow", Hostile = true, Health = 260, Damage = 30,
		WalkSpeed = 13, AggroRange = 72, AttackRange = 5.5, AttackCooldown = 1.6, Count = 3,
		Color = Color3.fromRGB(225, 229, 231),
		Drops = { { Item = "RawMeat", Min = 4, Max = 6, Chance = 1 }, { Item = "Fur", Min = 2, Max = 4, Chance = 1 }, { Item = "Bone", Min = 2, Max = 4, Chance = 0.9 } },
	},
	Scorpion = {
		Label = "Dune Scorpion", Biome = "Desert", Hostile = true, Health = 58, Damage = 11,
		WalkSpeed = 17, AggroRange = 46, AttackRange = 3.6, AttackCooldown = 0.95, Count = 10,
		Color = Color3.fromRGB(129, 88, 49), PoisonChance = 0.5,
		Drops = { { Item = "Venom", Min = 1, Max = 2, Chance = 0.65 }, { Item = "Bone", Min = 1, Max = 1, Chance = 0.25 } },
	},
}

return MobData
