local AdvancedStructureData = {}

AdvancedStructureData.Structures = {
	Barricade = {
		Label = "Heavy Barricade",
		Description = "A low, durable defensive barrier for tightening a camp perimeter.",
		Cost = { Wood = 30, Stone = 8 },
		Health = 280,
		MinForge = 1,
		Limit = 12,
		Footprint = Vector3.new(11, 6, 2.5),
	},
	WarBrazier = {
		Label = "War Brazier",
		Description = "A tall permanent light source for walls, gates and night defenses.",
		Cost = { Wood = 22, Stone = 20 },
		Health = 180,
		MinForge = 2,
		Limit = 8,
		Footprint = Vector3.new(4, 8, 4),
	},
	Watchtower = {
		Label = "Watchtower",
		Description = "A climbable lookout platform that gives your camp real vertical defense.",
		Cost = { Wood = 80, Stone = 35 },
		Health = 500,
		MinForge = 3,
		Limit = 3,
		Footprint = Vector3.new(14, 18, 14),
	},
	StoneGate = {
		Label = "Stone Gate",
		Description = "A fortified gateway with a passable center opening for a serious base entrance.",
		Cost = { Wood = 45, Stone = 85 },
		Health = 700,
		MinForge = 4,
		Limit = 4,
		Footprint = Vector3.new(18, 14, 4),
	},
	BallistaTower = {
		Label = "Ballista Tower",
		Description = "Endgame automated defense that fires heavy bolts at hostile creatures.",
		Cost = { Wood = 120, Stone = 130 },
		Health = 460,
		MinForge = 6,
		Limit = 2,
		Footprint = Vector3.new(14, 18, 14),
		Range = 72,
		Damage = 22,
		Cooldown = 1.25,
	},
}

AdvancedStructureData.Order = { "Barricade", "WarBrazier", "Watchtower", "StoneGate", "BallistaTower" }

return AdvancedStructureData
