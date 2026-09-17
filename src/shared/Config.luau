local Config = {}

Config.WorldSize = 420
Config.StartingResources = { Wood = 0, Stone = 0, Food = 3, Gold = 0, XP = 0, Age = 1 }

Config.GatherDistance = 18
Config.AttackDistance = 14
Config.BuildDistance = 24
Config.AttackCooldown = 0.45
Config.GatherCooldown = 0.28
Config.RespawnSeconds = 8

Config.PlayerDamage = 22
Config.BuildDamage = 28
Config.FoodHeal = 28

Config.BuildCosts = {
	Wall = { Wood = 20 },
	Spike = { Wood = 15, Stone = 5 },
}

Config.AgeThresholds = { 0, 100, 250, 500, 900, 1400 }

return Config
