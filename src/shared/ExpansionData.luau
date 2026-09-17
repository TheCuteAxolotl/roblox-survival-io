local ExpansionData = {}

ExpansionData.DoorCost = { Wood = 25, Stone = 5 }
ExpansionData.SpawnPadCost = { Wood = 45, Stone = 30 }
ExpansionData.SpawnUnlockAge = 7
ExpansionData.DoorAccessModes = { "OWNER", "CLAN", "PUBLIC" }

ExpansionData.VillageTrades = {
	Provisioner = {
		{ Label = "2 Cooked Meat", Take = { Gold = 20 }, Give = { Items = { CookedMeat = 2 } } },
		{ Label = "4 Wheat Seeds", Take = { Gold = 12 }, Give = { Items = { WheatSeeds = 4 } } },
		{ Label = "2 Water Flasks", Take = { Gold = 18 }, Give = { Items = { WaterFlask = 2 } } },
	},
	Herbalist = {
		{ Label = "Health Potion", Take = { Gold = 35 }, Give = { Items = { HealthPotion = 1 } } },
		{ Label = "3 Wild Herbs", Take = { Gold = 10 }, Give = { Items = { Herb = 3 } } },
		{ Label = "Antidote", Take = { Gold = 24 }, Give = { Items = { Antidote = 1 } } },
	},
	Hunter = {
		{ Label = "Sell 2 Hide for 18 Gold", Take = { Items = { Hide = 2 } }, Give = { Gold = 18 } },
		{ Label = "Sell 2 Fur for 32 Gold", Take = { Items = { Fur = 2 } }, Give = { Gold = 32 } },
		{ Label = "3 Cooked Beef", Take = { Gold = 42 }, Give = { Items = { CookedBeef = 3 } } },
	},
}

ExpansionData.VillageCount = 3
ExpansionData.Boss = {
	Name = "Ancient Stoneback",
	Health = 1600,
	Damage = 32,
	WalkSpeed = 12,
	AggroRange = 78,
	AttackRange = 7,
	AttackCooldown = 1.5,
	RespawnSeconds = 180,
	GoldReward = 250,
	XPReward = 175,
}

return ExpansionData
