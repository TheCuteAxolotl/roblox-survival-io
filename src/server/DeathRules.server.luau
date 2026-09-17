local PlayerService = require(script.Parent.PlayerService)

-- Bootstrap calls this function when a player dies. Override the old partial-drop
-- rule so survival deaths keep permanent gold but lose all carried supplies.
function PlayerService.TakeDeathDrop(player, _ratio)
	local profile = PlayerService.Get(player)
	if not profile then return {} end
	local drops = {}
	for _, resource in { "Wood", "Stone", "Food" } do
		local amount = math.max(0, math.floor(profile[resource] or 0))
		drops[resource] = amount
		if amount > 0 then PlayerService.Add(player, { [resource] = -amount }) end
	end
	drops.Gold = 0
	return drops
end
