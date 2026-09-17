local RiftRunData = {}

RiftRunData.ArenaCenter = Vector3.new(0, 0, 1800)
RiftRunData.MaxStages = 6
RiftRunData.RallySeconds = 8
RiftRunData.ExtractAfterStage = 3
RiftRunData.IntermissionSeconds = 8

RiftRunData.Modifiers = {
	Standard = { Label = "STABLE RIFT", Count = 1, Health = 1, Damage = 1, Speed = 1, Reward = 1 },
	Swarm = { Label = "SWARM RIFT", Count = 1.45, Health = 0.88, Damage = 0.95, Speed = 1.08, Reward = 1.22 },
	Juggernaut = { Label = "JUGGERNAUT RIFT", Count = 0.82, Health = 1.62, Damage = 1.12, Speed = 0.9, Reward = 1.30 },
	Frenzy = { Label = "FRENZY RIFT", Count = 1.1, Health = 1.05, Damage = 1.22, Speed = 1.22, Reward = 1.28 },
	Golden = { Label = "GOLDEN RIFT", Count = 1.08, Health = 1.12, Damage = 1.06, Speed = 1, Reward = 1.55 },
	Unstable = { Label = "UNSTABLE RIFT", Count = 1.25, Health = 1.28, Damage = 1.18, Speed = 1.12, Reward = 1.48 },
}
RiftRunData.ModifierOrder = { "Standard", "Swarm", "Juggernaut", "Frenzy", "Golden", "Unstable" }

RiftRunData.Upgrades = {
	Fury = {
		Label = "FURY",
		Description = "+18% damage this expedition.",
		MaxStacks = 4,
	},
	IronSkin = {
		Label = "IRON SKIN",
		Description = "Take 9% less damage this expedition.",
		MaxStacks = 4,
	},
	Quickstep = {
		Label = "QUICKSTEP",
		Description = "+2 movement speed and faster dodges.",
		MaxStacks = 4,
	},
	GiantHeart = {
		Label = "GIANT HEART",
		Description = "+25 maximum health and heal the gained health.",
		MaxStacks = 4,
	},
	BloodRush = {
		Label = "BLOOD RUSH",
		Description = "Heal 7% of max health whenever an expedition enemy dies.",
		MaxStacks = 3,
	},
	Executioner = {
		Label = "EXECUTIONER",
		Description = "+22% damage against expedition bosses.",
		MaxStacks = 3,
	},
	GreedyFlame = {
		Label = "GREEDY FLAME",
		Description = "+18% Gold when you extract.",
		MaxStacks = 4,
	},
	SecondWind = {
		Label = "SECOND WIND",
		Description = "+1 automatic self-revive for this expedition.",
		MaxStacks = 2,
	},
	Overcharge = {
		Label = "OVERCHARGE",
		Description = "Dodging releases a damaging shockwave around you.",
		MaxStacks = 1,
	},
	Recovery = {
		Label = "RECOVERY",
		Description = "Heal 18% of max health after every cleared stage.",
		MaxStacks = 3,
	},
}

RiftRunData.UpgradeOrder = {
	"Fury", "IronSkin", "Quickstep", "GiantHeart", "BloodRush",
	"Executioner", "GreedyFlame", "SecondWind", "Overcharge", "Recovery",
}

RiftRunData.Stages = {
	[1] = { Label = "RIFT SWARM", Kind = "Wave", Enemy = "Riftling", BaseCount = 8, RewardGold = 70, RewardXP = 45, Essence = 55 },
	[2] = { Label = "HUNTER PACK", Kind = "Wave", Enemy = "RiftHunter", BaseCount = 7, RewardGold = 95, RewardXP = 60, Essence = 70 },
	[3] = { Label = "GLOOMFANG", Kind = "Boss", Enemy = "Gloomfang", BaseCount = 1, Adds = 4, RewardGold = 180, RewardXP = 110, Essence = 120 },
	[4] = { Label = "CORRUPTION STORM", Kind = "Survival", Enemy = "RiftHunter", Duration = 32, SpawnEvery = 3.5, RewardGold = 150, RewardXP = 90, Essence = 95 },
	[5] = { Label = "ELITE HUNT", Kind = "Mixed", Enemy = "RiftHunter", BaseCount = 8, Brutes = 3, RewardGold = 175, RewardXP = 105, Essence = 100 },
	[6] = { Label = "RIFT OVERLORD", Kind = "Boss", BossPool = { "RiftTyrant", "StormMaw", "VoidStalker" }, BaseCount = 1, Adds = 6, RewardGold = 500, RewardXP = 320, Essence = 180 },
}

RiftRunData.Enemies = {
	Riftling = {
		Label = "Riftling",
		Health = 115,
		Damage = 13,
		Speed = 15,
		Range = 4.5,
		Cooldown = 1.0,
		Scale = 0.8,
		Color = Color3.fromRGB(70, 82, 112),
		Glow = Color3.fromRGB(97, 160, 255),
	},
	RiftHunter = {
		Label = "Rift Hunter",
		Health = 210,
		Damage = 20,
		Speed = 18,
		Range = 5,
		Cooldown = 0.82,
		Scale = 0.95,
		Color = Color3.fromRGB(73, 47, 93),
		Glow = Color3.fromRGB(194, 92, 255),
	},
	RiftBrute = {
		Label = "Rift Brute",
		Health = 390,
		Damage = 31,
		Speed = 11,
		Range = 6,
		Cooldown = 1.25,
		Scale = 1.25,
		Color = Color3.fromRGB(73, 65, 77),
		Glow = Color3.fromRGB(255, 105, 160),
	},
	Gloomfang = {
		Label = "GLOOMFANG",
		Health = 1250,
		Damage = 34,
		Speed = 17,
		Range = 7,
		Cooldown = 0.9,
		Scale = 1.5,
		Boss = true,
		Color = Color3.fromRGB(49, 43, 68),
		Glow = Color3.fromRGB(122, 111, 255),
	},
	RiftTyrant = {
		Label = "RIFT TYRANT",
		Health = 3200,
		Damage = 52,
		Speed = 12,
		Range = 9,
		Cooldown = 1.15,
		Scale = 1.8,
		Boss = true,
		Special = "Pulse",
		Color = Color3.fromRGB(58, 35, 69),
		Glow = Color3.fromRGB(255, 74, 213),
	},
	StormMaw = {
		Label = "STORM MAW",
		Health = 3900,
		Damage = 63,
		Speed = 8.5,
		Range = 11,
		Cooldown = 1.55,
		Scale = 2.05,
		Boss = true,
		Special = "Slam",
		Color = Color3.fromRGB(48, 62, 78),
		Glow = Color3.fromRGB(91, 199, 255),
	},
	VoidStalker = {
		Label = "VOID STALKER",
		Health = 2900,
		Damage = 46,
		Speed = 16,
		Range = 7,
		Cooldown = 0.82,
		Scale = 1.55,
		Boss = true,
		Special = "Bolts",
		Color = Color3.fromRGB(49, 36, 72),
		Glow = Color3.fromRGB(166, 92, 255),
	},
}

return RiftRunData
