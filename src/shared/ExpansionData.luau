local ExpansionData = {}

ExpansionData.DoorCost = { Wood = 35, Stone = 12 }
ExpansionData.DoorAccessModes = { "OWNER", "CLAN", "PUBLIC" }
ExpansionData.VillageCount = 3
ExpansionData.VillageFarmChance = 0.60
ExpansionData.VillageTorchChance = 0.72

ExpansionData.VillageTrades = {
	Provisioner = {
		{ Label = "2 Cooked Meat — 35 Gold", Take = { Gold = 35 }, Give = { Items = { CookedMeat = 2 } } },
		{ Label = "4 Wheat Seeds — 25 Gold", Take = { Gold = 25 }, Give = { Items = { WheatSeeds = 4 } } },
		{ Label = "2 Water Bottles — 45 Gold", Take = { Gold = 45 }, Give = { Items = { WaterFlask = 2 } } },
		{ Label = "3 Cooked Beef — 85 Gold", Take = { Gold = 85 }, Give = { Items = { CookedBeef = 3 } } },
	},
	Herbalist = {
		{ Label = "Health Potion — 90 Gold", Take = { Gold = 90 }, Give = { Items = { HealthPotion = 1 } } },
		{ Label = "Antidote — 65 Gold", Take = { Gold = 65 }, Give = { Items = { Antidote = 1 } } },
		{ Label = "Fleet Potion — 180 Gold", Take = { Gold = 180 }, Give = { Items = { SpeedPotion = 1 } } },
		{ Label = "Survival Elixir — 450 Gold", Take = { Gold = 450 }, Give = { Items = { SurvivalElixir = 1 } } },
	},
	Hunter = {
		{ Label = "Sell 2 Hide — 30 Gold", Take = { Items = { Hide = 2 } }, Give = { Gold = 30 } },
		{ Label = "Sell 2 Fur — 60 Gold", Take = { Items = { Fur = 2 } }, Give = { Gold = 60 } },
		{ Label = "Sell 1 Venom — 28 Gold", Take = { Items = { Venom = 1 } }, Give = { Gold = 28 } },
		{ Label = "Leather Armor — 475 Gold", Take = { Gold = 475 }, Give = { Items = { LeatherArmor = 1 } } },
	},
	Armorer = {
		{ Label = "3 Glass — 120 Gold", Take = { Gold = 120 }, Give = { Items = { Glass = 3 } } },
		{ Label = "Fur Armor — 1200 Gold", Take = { Gold = 1200 }, Give = { Items = { FurArmor = 1 } } },
		{ Label = "Stoneplate Armor — 2600 Gold", Take = { Gold = 2600 }, Give = { Items = { StoneplateArmor = 1 } } },
	},
	Collector = {
		{ Label = "Sell Dragon Scale — 350 Gold", Take = { Items = { DragonScale = 1 } }, Give = { Gold = 350 } },
		{ Label = "Sell Demon Core — 500 Gold", Take = { Items = { DemonCore = 1 } }, Give = { Gold = 500 } },
		{ Label = "Sell Ancient Relic — 3000 Gold", Take = { Items = { AncientRelic = 1 } }, Give = { Gold = 3000 } },
	},
}

ExpansionData.Boss = {
	Name = "Ancient Stoneback",
	Health = 1600,
	Damage = 38,
	WalkSpeed = 12,
	AggroRange = 78,
	AttackRange = 7,
	AttackCooldown = 1.5,
	RespawnSeconds = 180,
	GoldReward = 250,
	XPReward = 175,
}

return ExpansionData
