local RiftRunData = {}

-- Player-facing name is ASCENSION. Internal "Rift" names stay for save/API compatibility.
RiftRunData.ArenaCenter = Vector3.new(0, 0, 1800)
RiftRunData.MaxStages = 10
RiftRunData.RallySeconds = 7
RiftRunData.ExtractStages = { [3] = true, [6] = true, [9] = true }
RiftRunData.IntermissionSeconds = 6

RiftRunData.Modifiers = {
	Standard = { Label = "STABLE ASCENSION", Count = 1, Health = 1, Damage = 1, Speed = 1, Reward = 1 },
	Swarm = { Label = "SWARM", Count = 1.55, Health = 0.86, Damage = 0.94, Speed = 1.08, Reward = 1.24 },
	Juggernaut = { Label = "JUGGERNAUT", Count = 0.78, Health = 1.70, Damage = 1.14, Speed = 0.90, Reward = 1.34 },
	Frenzy = { Label = "FRENZY", Count = 1.12, Health = 1.04, Damage = 1.25, Speed = 1.24, Reward = 1.30 },
	Golden = { Label = "GOLDEN", Count = 1.10, Health = 1.12, Damage = 1.08, Speed = 1, Reward = 1.60 },
	Unstable = { Label = "UNSTABLE", Count = 1.28, Health = 1.32, Damage = 1.20, Speed = 1.13, Reward = 1.52 },
	Nightmare = { Label = "NIGHTMARE", Count = 1.25, Health = 1.46, Damage = 1.35, Speed = 1.12, Reward = 1.82 },
}
RiftRunData.ModifierOrder = { "Standard", "Swarm", "Juggernaut", "Frenzy", "Golden", "Unstable", "Nightmare" }

RiftRunData.Upgrades = {
	Fury = { Label = "FURY", Description = "+18% damage this run.", MaxStacks = 4 },
	IronSkin = { Label = "IRON SKIN", Description = "Take 9% less damage this run.", MaxStacks = 4 },
	Quickstep = { Label = "QUICKSTEP", Description = "+2 move speed and faster dodges.", MaxStacks = 4 },
	GiantHeart = { Label = "GIANT HEART", Description = "+25 maximum health and heal the gained health.", MaxStacks = 4 },
	BloodRush = { Label = "BLOOD RUSH", Description = "Heal 7% whenever an Ascension enemy dies.", MaxStacks = 3 },
	Executioner = { Label = "EXECUTIONER", Description = "+22% damage against bosses.", MaxStacks = 3 },
	GreedyFlame = { Label = "GILDED SOUL", Description = "+18% Gold when you cash out.", MaxStacks = 4 },
	SecondWind = { Label = "SECOND WIND", Description = "+1 automatic solo recovery or emergency revive.", MaxStacks = 2 },
	Overcharge = { Label = "OVERCHARGE", Description = "Dodging releases a damaging shockwave.", MaxStacks = 1 },
	Recovery = { Label = "RECOVERY", Description = "Heal 18% after every cleared stage.", MaxStacks = 3 },
	BossWard = { Label = "WARD", Description = "Take 8% less damage from everything this run.", MaxStacks = 2 },
	GlassCannon = { Label = "GLASS CANNON", Description = "+32% damage, but take 14% more damage.", MaxStacks = 2 },
}
RiftRunData.UpgradeOrder = {
	"Fury", "IronSkin", "Quickstep", "GiantHeart", "BloodRush", "Executioner",
	"GreedyFlame", "SecondWind", "Overcharge", "Recovery", "BossWard", "GlassCannon",
}

RiftRunData.Stages = {
	[1] = { Label = "BREACH", Kind = "Wave", EnemyPool = { "Riftling", "RiftHunter" }, BaseCount = 9, RewardGold = 65, RewardXP = 45, Essence = 60 },
	[2] = { Label = "ELITE PACK", Kind = "Mixed", EnemyPool = { "RiftHunter", "ShadeHound" }, BaseCount = 7, Brutes = 2, RewardGold = 95, RewardXP = 65, Essence = 75 },
	[3] = { Label = "FIRST GUARDIAN", Kind = "Boss", BossPool = { "Gloomfang", "AshWarden", "CrystalBeast" }, Adds = 4, RewardGold = 190, RewardXP = 120, Essence = 130 },
	[4] = { Label = "VOID STORM", Kind = "Survival", EnemyPool = { "RiftHunter", "ShadeHound", "Riftling" }, Duration = 36, SpawnEvery = 3.2, RewardGold = 155, RewardXP = 95, Essence = 105 },
	[5] = { Label = "HUNTER GAUNTLET", Kind = "Mixed", EnemyPool = { "RiftHunter", "ShadeHound" }, BaseCount = 10, Brutes = 4, RewardGold = 190, RewardXP = 120, Essence = 115 },
	[6] = { Label = "SECOND GUARDIAN", Kind = "Boss", BossPool = { "StormMaw", "VoidStalker", "IronBehemoth" }, Adds = 6, RewardGold = 340, RewardXP = 210, Essence = 165 },
	[7] = { Label = "CORRUPTED LEGION", Kind = "Mixed", EnemyPool = { "ShadeHound", "RiftHunter", "RiftBrute" }, BaseCount = 12, Brutes = 4, RewardGold = 235, RewardXP = 145, Essence = 130 },
	[8] = { Label = "COLLAPSE", Kind = "Survival", EnemyPool = { "RiftHunter", "RiftBrute", "ShadeHound" }, Duration = 42, SpawnEvery = 2.8, RewardGold = 280, RewardXP = 175, Essence = 145 },
	[9] = { Label = "EXECUTION FLOOR", Kind = "Boss", BossPool = { "RiftTyrant", "StormMaw", "VoidStalker", "IronBehemoth" }, Adds = 8, RewardGold = 450, RewardXP = 270, Essence = 185 },
	[10] = { Label = "ASCENSION SOVEREIGN", Kind = "Boss", BossPool = { "AbyssalSovereign", "SolarDevourer", "GraveTitan" }, Adds = 10, RewardGold = 900, RewardXP = 560, Essence = 260 },
}

RiftRunData.Enemies = {
	Riftling = { Label = "Riftling", Health = 115, Damage = 13, Speed = 15, Range = 4.5, Cooldown = 1.0, Scale = 0.8, Color = Color3.fromRGB(70,82,112), Glow = Color3.fromRGB(97,160,255) },
	RiftHunter = { Label = "Rift Hunter", Health = 210, Damage = 20, Speed = 18, Range = 5, Cooldown = 0.82, Scale = 0.95, Color = Color3.fromRGB(73,47,93), Glow = Color3.fromRGB(194,92,255) },
	RiftBrute = { Label = "Rift Brute", Health = 390, Damage = 31, Speed = 11, Range = 6, Cooldown = 1.25, Scale = 1.25, Color = Color3.fromRGB(73,65,77), Glow = Color3.fromRGB(255,105,160) },
	ShadeHound = { Label = "Shade Hound", Health = 275, Damage = 24, Speed = 20, Range = 5.5, Cooldown = 0.72, Scale = 1.0, Color = Color3.fromRGB(43,50,62), Glow = Color3.fromRGB(87,233,214) },

	Gloomfang = { Label = "GLOOMFANG", Health = 1450, Damage = 36, Speed = 17, Range = 7, Cooldown = 0.9, Scale = 1.5, Boss = true, Special = "Pulse", Color = Color3.fromRGB(49,43,68), Glow = Color3.fromRGB(122,111,255) },
	AshWarden = { Label = "ASH WARDEN", Health = 1750, Damage = 40, Speed = 12, Range = 8, Cooldown = 1.05, Scale = 1.65, Boss = true, Special = "Slam", Color = Color3.fromRGB(78,54,47), Glow = Color3.fromRGB(255,128,63) },
	CrystalBeast = { Label = "CRYSTAL BEAST", Health = 1600, Damage = 35, Speed = 14, Range = 7, Cooldown = 0.95, Scale = 1.6, Boss = true, Special = "Bolts", Color = Color3.fromRGB(54,72,88), Glow = Color3.fromRGB(100,221,255) },

	RiftTyrant = { Label = "RIFT TYRANT", Health = 3400, Damage = 54, Speed = 12, Range = 9, Cooldown = 1.15, Scale = 1.8, Boss = true, Special = "Pulse", Color = Color3.fromRGB(58,35,69), Glow = Color3.fromRGB(255,74,213) },
	StormMaw = { Label = "STORM MAW", Health = 4100, Damage = 64, Speed = 8.5, Range = 11, Cooldown = 1.55, Scale = 2.05, Boss = true, Special = "Slam", Color = Color3.fromRGB(48,62,78), Glow = Color3.fromRGB(91,199,255) },
	VoidStalker = { Label = "VOID STALKER", Health = 3100, Damage = 48, Speed = 16, Range = 7, Cooldown = 0.82, Scale = 1.55, Boss = true, Special = "Bolts", Color = Color3.fromRGB(49,36,72), Glow = Color3.fromRGB(166,92,255) },
	IronBehemoth = { Label = "IRON BEHEMOTH", Health = 4700, Damage = 68, Speed = 7.5, Range = 12, Cooldown = 1.65, Scale = 2.2, Boss = true, Special = "Slam", Color = Color3.fromRGB(65,68,72), Glow = Color3.fromRGB(255,190,84) },

	AbyssalSovereign = { Label = "ABYSSAL SOVEREIGN", Health = 7200, Damage = 78, Speed = 13, Range = 10, Cooldown = 0.92, Scale = 2.15, Boss = true, Special = "Bolts", Color = Color3.fromRGB(45,28,63), Glow = Color3.fromRGB(221,74,255) },
	SolarDevourer = { Label = "SOLAR DEVOURER", Health = 8200, Damage = 86, Speed = 9.5, Range = 13, Cooldown = 1.35, Scale = 2.4, Boss = true, Special = "Pulse", Color = Color3.fromRGB(88,48,33), Glow = Color3.fromRGB(255,172,54) },
	GraveTitan = { Label = "GRAVE TITAN", Health = 9000, Damage = 92, Speed = 7, Range = 14, Cooldown = 1.6, Scale = 2.55, Boss = true, Special = "Slam", Color = Color3.fromRGB(76,78,72), Glow = Color3.fromRGB(176,255,152) },
}

return RiftRunData
