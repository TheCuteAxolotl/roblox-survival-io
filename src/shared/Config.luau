local Config = {}

Config.WorldSize = 1200
Config.BiomeSplit = 200
Config.RiverHalfWidth = 32
Config.RiverNoBuildPadding = 8
Config.BridgeXPositions = { -360, 0, 360 }
Config.ResourceRespawnSeconds = 14
-- Slightly shrink build-overlap checks so wall faces can touch edge-to-edge.
-- Actual intersections are still rejected by BuildService.
Config.BuildClearance = -0.08
Config.OwnBuildRefundRatio = 1
Config.EnemyBuildSalvageRatio = 0.5

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

-- Age 10 leaves room for late weapon/secondary upgrades without making the
-- early game too slow to test in Studio.
Config.AgeThresholds = { 0, 100, 250, 500, 900, 1400, 2100, 3000, 4200, 5600 }

return Config
