local Config = {}

-- WORLD
Config.WorldSize = 2000
Config.BiomeSplit = 320
Config.RiverHalfWidth = 32
Config.RiverNoBuildPadding = 8
Config.BridgeXPositions = { -650, -325, 0, 325, 650 }
Config.ResourceRespawnSeconds = 16
Config.BuildClearance = 0.65
Config.OwnBuildRefundRatio = 1
Config.EnemyBuildSalvageRatio = 0.5

-- FIRST MINUTES: enough food to explore, but players still need to learn hunting/cooking.
Config.StartingResources = { Wood = 0, Stone = 0, Food = 4, Gold = 0, XP = 0, Age = 1 }

-- INTERACTION
Config.GatherDistance = 18
Config.AttackDistance = 16
Config.BuildDistance = 32
Config.AttackCooldown = 0.45
Config.GatherCooldown = 0.28
Config.RespawnSeconds = 8
Config.PlayerDamage = 22
Config.BuildDamage = 28
Config.FoodHeal = 28
Config.BaseWalkSpeed = 20

-- WILDFORGE WORLD RHYTHM.
-- A complete world day lasts seven minutes: generous daylight, a readable dusk,
-- and a dangerous two-minute night. The server publishes this state for the HUD
-- and gameplay systems through ReplicatedStorage attributes.
Config.WorldCycle = {
	DawnSeconds = 45,
	DaySeconds = 210,
	DuskSeconds = 45,
	NightSeconds = 120,
	MaxThreat = 6,
}

-- Internal saves still use the historical field name "Age" for compatibility.
-- In player-facing UI it is now called FORGE LEVEL. Eight levels keep choices
-- meaningful instead of turning the hotbar into a catalog.
Config.AgeThresholds = { 0, 80, 200, 400, 700, 1100, 1700, 2600 }

return Config
