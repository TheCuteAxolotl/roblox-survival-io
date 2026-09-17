local HatData = {}

HatData.Order = {
	"LumberCap",
	"MinerHelmet",
	"WarriorHelm",
	"ScoutHood",
	"GuardianCrown",
}

HatData.Hats = {
	LumberCap = {
		Label = "Lumber Cap",
		Description = "+25% wood gained from gathering.",
		Cost = 150,
		Effects = { WoodMultiplier = 1.25 },
		Color = Color3.fromRGB(84, 137, 65),
		Accent = Color3.fromRGB(235, 226, 188),
		Style = "Cap",
	},
	MinerHelmet = {
		Label = "Miner Helmet",
		Description = "+25% stone gained from gathering.",
		Cost = 225,
		Effects = { StoneMultiplier = 1.25 },
		Color = Color3.fromRGB(232, 184, 55),
		Accent = Color3.fromRGB(240, 240, 230),
		Style = "Miner",
	},
	WarriorHelm = {
		Label = "Warrior Helm",
		Description = "+12% melee damage against players.",
		Cost = 350,
		Effects = { DamageMultiplier = 1.12 },
		Color = Color3.fromRGB(92, 96, 106),
		Accent = Color3.fromRGB(173, 177, 187),
		Style = "Helm",
	},
	ScoutHood = {
		Label = "Scout Hood",
		Description = "+3 walk speed for faster roaming.",
		Cost = 275,
		Effects = { WalkSpeedBonus = 3 },
		Color = Color3.fromRGB(63, 86, 72),
		Accent = Color3.fromRGB(102, 136, 112),
		Style = "Hood",
	},
	GuardianCrown = {
		Label = "Guardian Crown",
		Description = "+25 maximum health.",
		Cost = 500,
		Effects = { MaxHealthBonus = 25 },
		Color = Color3.fromRGB(235, 190, 52),
		Accent = Color3.fromRGB(255, 232, 121),
		Style = "Crown",
	},
}

return HatData
