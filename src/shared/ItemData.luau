local ItemData = {}

ItemData.Items = {
	-- CORE STARTER LOOP
	Axe = { Category = "Weapon", WeaponSlot = "Primary", Label = "Stone Tool", Description = "Your starter survival tool. Good at gathering and reliable in an emergency fight.", Damage = 18, BuildDamage = 24, Range = 14, Cooldown = 0.5, GatherHits = 1, Visual = "Hammer", UpgradeGroup = "PrimaryWeapon", Tier = 1 },
	Food = { Category = "Consumable", Label = "Food", Description = "Eat one carried food to recover health." },
	Wall = { Category = "Build", Label = "Wood Wall", Description = "Cheap early cover for shaping your first camp.", Cost = { Wood = 12 }, Health = 150, BuildLimit = 30, PreviewSize = Vector3.new(10, 12, 1.2), PreviewY = 6, Rotatable = true },
	Spike = { Category = "Build", Label = "Wood Spikes", Description = "Simple perimeter defense that punishes anything pushing into your camp.", Cost = { Wood = 10, Stone = 3 }, Health = 75, TouchDamage = 12, BuildLimit = 16, PreviewSize = Vector3.new(5.5, 2.2, 5.5), PreviewY = 1.1 },
	Campfire = { Category = "Build", Label = "Campfire", Description = "The heart of an early camp and a landmark for your first shelter.", Cost = { Wood = 14, Stone = 8 }, Health = 130, PreviewSize = Vector3.new(6, 2, 6), PreviewY = 1, BuildLimit = 2 },

	-- FORGE LEVEL 2: choose how you want to play.
	Sword = { Category = "Weapon", WeaponSlot = "Primary", Label = "Short Sword", Description = "Fast and dependable. Best all-around early combat choice and later becomes the Katana.", Damage = 30, BuildDamage = 12, Range = 14, Cooldown = 0.36, GatherHits = 1, Visual = "Sword", UpgradeGroup = "PrimaryWeapon", Tier = 2, Branch = "Sword" },
	Pickaxe = { Category = "Weapon", WeaponSlot = "Primary", Label = "Pickaxe", Description = "Slower combat, much better gathering and bonus stone. Later becomes the Great Axe.", Damage = 17, BuildDamage = 25, Range = 14, Cooldown = 0.5, GatherHits = 2, StoneBonus = 2, Visual = "Pickaxe", UpgradeGroup = "PrimaryWeapon", Tier = 2, Branch = "Pickaxe" },
	Spear = { Category = "Weapon", WeaponSlot = "Primary", Label = "Hunter Spear", Description = "Long reach and heavy hits with a deliberate attack rhythm.", Damage = 48, BuildDamage = 18, Range = 21, Cooldown = 1.05, GatherHits = 1, Visual = "Spear", UpgradeGroup = "PrimaryWeapon", Tier = 2, Terminal = true },

	-- BASE SPECIALIZATION
	StoneWall = { Category = "Build", Label = "Stone Wall", Description = "A serious fortified wall for camps you plan to defend.", Cost = { Wood = 6, Stone = 20 }, Health = 360, BuildLimit = 20, PreviewSize = Vector3.new(10, 12, 1.6), PreviewY = 6, Rotatable = true },
	GreaterSpikes = { Category = "Build", Label = "Reinforced Spikes", Description = "Tougher perimeter spikes with much higher contact damage.", Cost = { Wood = 18, Stone = 10 }, Health = 125, TouchDamage = 24, BuildLimit = 12, PreviewSize = Vector3.new(6.5, 2.8, 6.5), PreviewY = 1.4 },
	BearTrap = { Category = "Build", Label = "Snare Trap", Description = "Damages and briefly slows enemies that step on it.", Cost = { Wood = 14, Stone = 8 }, Health = 90, PreviewSize = Vector3.new(6, 1, 6), PreviewY = 0.5, BuildLimit = 6 },

	-- SECONDARY COMBAT
	WoodenShield = { Category = "Weapon", WeaponSlot = "Secondary", Kind = "Shield", Label = "Wooden Shield", Description = "A forgiving defensive secondary for surviving close fights.", Damage = 0, BuildDamage = 0, Range = 0, Cooldown = 0.5, CanAttack = false, CanGather = false, BlockPercent = 0.45, RangedBlockPercent = 0.6, Visual = "WoodShield", UpgradeGroup = "SecondaryWeapon", Tier = 1, Terminal = true },
	HuntingBow = { Category = "Weapon", WeaponSlot = "Secondary", Ranged = true, Label = "Hunting Bow", Description = "Safe ranged pressure for hunting and dangerous encounters. Opens the ranged upgrade path.", Damage = 23, BuildDamage = 8, Range = 95, Cooldown = 0.78, ProjectileSpeed = 155, ProjectileCount = 1, CanGather = false, Visual = "Bow", UpgradeGroup = "SecondaryWeapon", Tier = 1, Branch = "Bow" },
	GreatHammer = { Category = "Weapon", WeaponSlot = "Secondary", Label = "Great Hammer", Description = "Slow close-range secondary made for cracking structures and heavy targets.", Damage = 24, BuildDamage = 58, Range = 13, Cooldown = 0.9, GatherHits = 1, Visual = "GreatHammer", UpgradeGroup = "SecondaryWeapon", Tier = 1, Terminal = true },

	-- CAMP SPECIALIZATION
	Windmill = { Category = "Build", Label = "Windmill", Description = "A long-term camp investment that slowly earns Gold and XP.", Cost = { Wood = 80, Stone = 35 }, Health = 150, BuildLimit = 6, LimitGroup = "Mill", GoldPerTick = 1, TickSeconds = 8, PreviewSize = Vector3.new(7, 10, 7), PreviewY = 5, UpgradeGroup = "Mill", Tier = 1 },
	Sapling = { Category = "Build", Label = "Resource Grove", Description = "A renewable wood source for established camps.", Cost = { Wood = 45, Stone = 12 }, Health = 120, WoodPerTick = 6, TickSeconds = 8, BuildLimit = 3, PreviewSize = Vector3.new(5, 7, 5), PreviewY = 3.5 },
	Turret = { Category = "Build", Label = "Watch Turret", Description = "Expensive automatic defense for a developed base.", Cost = { Wood = 120, Stone = 90 }, Health = 220, TurretDamage = 14, TurretRange = 52, TurretCooldown = 1.3, BuildLimit = 2, PreviewSize = Vector3.new(6, 7, 6), PreviewY = 3.5 },

	-- LATE PRIMARY / DEFENSE UPGRADES
	Katana = { Category = "Weapon", WeaponSlot = "Primary", Label = "Katana", Description = "Sword-path upgrade: fast, precise and high damage.", Damage = 40, BuildDamage = 18, Range = 15, Cooldown = 0.29, GatherHits = 1, Visual = "Katana", UpgradeGroup = "PrimaryWeapon", Tier = 3, RequiresUnlock = "Sword" },
	BattleAxe = { Category = "Weapon", WeaponSlot = "Primary", Label = "Great Axe", Description = "Pickaxe-path upgrade: excellent gathering with serious combat and structure damage.", Damage = 35, BuildDamage = 36, Range = 15, Cooldown = 0.58, GatherHits = 3, StoneBonus = 2, WoodBonus = 2, Visual = "BattleAxe", UpgradeGroup = "PrimaryWeapon", Tier = 3, RequiresUnlock = "Pickaxe" },
	StoneShield = { Category = "Weapon", WeaponSlot = "Secondary", Kind = "Shield", Label = "Stone Shield", Description = "Heavy protection for players who want to hold their ground in endgame fights.", Damage = 0, BuildDamage = 0, Range = 0, Cooldown = 0.55, CanAttack = false, CanGather = false, BlockPercent = 0.62, RangedBlockPercent = 0.78, Visual = "StoneShield", UpgradeGroup = "SecondaryWeapon", Tier = 2, Terminal = true },

	-- RANGED / ECONOMY ENDGAME
	RapidMill = { Category = "Build", Label = "Rapid Windmill", Description = "High-frequency Gold and XP production. All mill tiers share one six-mill cap.", Cost = { Wood = 130, Stone = 65 }, Health = 180, BuildLimit = 6, LimitGroup = "Mill", GoldPerTick = 3, TickSeconds = 5, PreviewSize = Vector3.new(8, 12, 8), PreviewY = 6, UpgradeGroup = "Mill", Tier = 2 },
	PowerMill = { Category = "Build", Label = "Power Windmill", Description = "Slow but durable high-output Gold production for a fortified base.", Cost = { Wood = 200, Stone = 115 }, Health = 300, BuildLimit = 6, LimitGroup = "Mill", GoldPerTick = 6, TickSeconds = 10, PreviewSize = Vector3.new(9, 13, 9), PreviewY = 6.5, UpgradeGroup = "Mill", Tier = 3 },
	Shotgun = { Category = "Weapon", WeaponSlot = "Secondary", Ranged = true, Label = "Scattergun", Description = "Bow-path upgrade that dominates close range with a wide pellet spread.", Damage = 8, BuildDamage = 5, Range = 68, Cooldown = 1.3, ProjectileSpeed = 175, ProjectileCount = 6, Spread = 0.12, CanGather = false, Visual = "Shotgun", UpgradeGroup = "SecondaryWeapon", Tier = 2, RequiresUnlock = "HuntingBow", Branch = "Shotgun" },
	RepeaterCrossbow = { Category = "Weapon", WeaponSlot = "Secondary", Ranged = true, Label = "Repeater Crossbow", Description = "Bow-path alternative built around rapid ranged pressure.", Damage = 11, BuildDamage = 4, Range = 90, Cooldown = 0.22, ProjectileSpeed = 190, ProjectileCount = 1, CanGather = false, Visual = "Crossbow", UpgradeGroup = "SecondaryWeapon", Tier = 2, RequiresUnlock = "HuntingBow", Terminal = true },
	Mine = { Category = "Build", Label = "Blast Mine", Description = "Hidden one-use defense that deals heavy damage when an enemy crosses it.", Cost = { Wood = 22, Stone = 34 }, Health = 65, MineDamage = 55, BuildLimit = 6, PreviewSize = Vector3.new(5, 0.7, 5), PreviewY = 0.35 },
	Musket = { Category = "Weapon", WeaponSlot = "Secondary", Ranged = true, Label = "Dragon Musket", Description = "Scattergun-path endgame weapon: very slow, extremely punishing single shots.", Damage = 0, PercentHealthDamage = 0.35, BuildDamage = 18, Range = 135, Cooldown = 2.6, ProjectileSpeed = 240, ProjectileCount = 1, CanGather = false, Visual = "Musket", UpgradeGroup = "SecondaryWeapon", Tier = 3, RequiresUnlock = "Shotgun", Terminal = true },

	-- LEGACY / HIDDEN ITEMS retained so old profiles do not corrupt.
	Daggers = { Category = "Weapon", WeaponSlot = "Primary", Label = "Legacy Daggers", Description = "Legacy weapon retained for older profiles.", Damage = 13, BuildDamage = 7, Range = 11, Cooldown = 0.18, GatherHits = 1, Visual = "Daggers", UpgradeGroup = "PrimaryWeapon", Tier = 2, Terminal = true },
	Bat = { Category = "Weapon", WeaponSlot = "Primary", Label = "Legacy Bat", Description = "Legacy weapon retained for older profiles.", Damage = 12, BuildDamage = 9, Range = 15, Cooldown = 0.48, GatherHits = 1, Knockback = 58, Visual = "Bat", UpgradeGroup = "PrimaryWeapon", Tier = 2, Terminal = true },
	Stick = { Category = "Weapon", WeaponSlot = "Primary", Label = "Legacy Gather Stick", Description = "Legacy item retained for older profiles.", Damage = 0, BuildDamage = 5, Range = 14, Cooldown = 0.28, GatherHits = 3, ResourceBonus = 3, Visual = "Stick", UpgradeGroup = "PrimaryWeapon", Tier = 2, Terminal = true },
	McGrabby = { Category = "Weapon", WeaponSlot = "Secondary", Label = "Legacy Grabber", Description = "Legacy item retained for older profiles.", Damage = 10, BuildDamage = 5, Range = 23, Cooldown = 0.85, GoldStealPercent = 0.1, Knockback = 28, Visual = "Grabby", UpgradeGroup = "SecondaryWeapon", Tier = 1, Terminal = true },
	HealingPad = { Category = "Build", Label = "Legacy Rest Pad", Description = "Legacy structure retained for older profiles.", Cost = { Wood = 70, Stone = 45 }, Health = 180, HealPerSecond = 0, EffectRange = 17, BuildLimit = 2, PreviewSize = Vector3.new(7, 1, 7), PreviewY = 0.5 },
	WarHammer = { Category = "Weapon", WeaponSlot = "Primary", Label = "Legacy War Hammer", Description = "Legacy item retained for older profiles.", Damage = 30, BuildDamage = 46, Range = 14, Cooldown = 0.62, GatherHits = 1, Visual = "Hammer" },
}

ItemData.StarterUnlocks = { "Axe", "Food", "Campfire", "Wall", "Spike" }

-- Player-facing name: Forge Level. Internal table name remains AgeChoices so
-- existing save/profile code does not need a destructive data migration.
ItemData.AgeChoices = {
	[2] = { "Sword", "Pickaxe", "Spear" },
	[3] = { "StoneWall", "GreaterSpikes", "BearTrap" },
	[4] = { "WoodenShield", "HuntingBow", "GreatHammer" },
	[5] = { "Windmill", "Sapling", "Turret" },
	[6] = { "Katana", "BattleAxe", "StoneShield" },
	[7] = { "RapidMill", "Shotgun", "RepeaterCrossbow", "Mine" },
	[8] = { "PowerMill", "Musket" },
}

ItemData.HotbarOrder = {
	"Axe", "Sword", "Pickaxe", "Spear", "Katana", "BattleAxe",
	"HuntingBow", "Shotgun", "RepeaterCrossbow", "Musket", "WoodenShield", "StoneShield", "GreatHammer",
	"Food", "Campfire", "Wall", "StoneWall", "Spike", "GreaterSpikes", "BearTrap",
	"Windmill", "RapidMill", "PowerMill", "Sapling", "Turret", "Mine",
	"Daggers", "Bat", "Stick", "McGrabby", "HealingPad", "WarHammer",
}

return ItemData
