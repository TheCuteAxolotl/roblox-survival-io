local MissionData = {}

MissionData.RankOrder = { "E", "D", "C", "B", "A", "S" }

MissionData.Missions = {
	LumberCommission = {
		Rank = "E",
		Title = "Frontier Lumber",
		Description = "Gather fresh wood for the town's repairs.",
		MinForge = 1,
		Objective = { Type = "Gather", Resource = "Wood", Amount = 40 },
		Reward = { Gold = 75, XP = 45, Mastery = 24 },
	},
	QuarryRequest = {
		Rank = "E",
		Title = "Stone for the Walls",
		Description = "Bring in stone for fortifications and roads.",
		MinForge = 1,
		Objective = { Type = "Gather", Resource = "Stone", Amount = 32 },
		Reward = { Gold = 90, XP = 50, Mastery = 26 },
	},
	HunterNotice = {
		Rank = "D",
		Title = "Cull the Wild",
		Description = "Defeat hostile wildlife threatening travelers.",
		MinForge = 2,
		Objective = { Type = "KillAny", Amount = 6 },
		Reward = { Gold = 145, XP = 80, Mastery = 38 },
	},
	BuilderWrit = {
		Rank = "C",
		Title = "Fortify the Frontier",
		Description = "Place structures and expand a defensible camp.",
		MinForge = 2,
		Objective = { Type = "Build", Amount = 4 },
		Reward = { Gold = 190, XP = 110, Mastery = 46 },
	},
	NightWatch = {
		Rank = "C",
		Title = "Night Watch",
		Description = "Accept before night and survive until dawn.",
		MinForge = 3,
		Objective = { Type = "SurviveNight", Amount = 1 },
		Reward = { Gold = 230, XP = 135, Mastery = 55 },
	},
	BlackwoodPurge = {
		Rank = "B",
		Title = "Blackwood Extermination",
		Description = "Defeat dangerous creatures inside Blackwood Forest.",
		MinForge = 4,
		Objective = { Type = "KillBiome", Biome = "Forest", Amount = 7 },
		Reward = { Gold = 360, XP = 210, Mastery = 80 },
	},
	DungeonBreaker = {
		Rank = "A",
		Title = "Dungeon Breaker",
		Description = "Enter a dungeon and bring down any true boss monster.",
		MinForge = 5,
		Objective = { Type = "KillBoss", Amount = 1 },
		Reward = { Gold = 700, XP = 380, Mastery = 135 },
	},
	DragonSlayer = {
		Rank = "S",
		Title = "Ancient Dragon Hunt",
		Description = "Defeat the Ancient Dragon. This contract is not meant for beginners.",
		MinForge = 6,
		Objective = { Type = "KillBossKey", BossKey = "AncientDragon", Amount = 1 },
		Reward = { Gold = 1300, XP = 700, Mastery = 240 },
	},
}

MissionData.Order = {
	"LumberCommission",
	"QuarryRequest",
	"HunterNotice",
	"BuilderWrit",
	"NightWatch",
	"BlackwoodPurge",
	"DungeonBreaker",
	"DragonSlayer",
}

function MissionData.Get(id)
	return MissionData.Missions[id]
end

return MissionData
