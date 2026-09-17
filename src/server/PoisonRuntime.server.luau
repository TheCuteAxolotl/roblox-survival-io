local Players = game:GetService("Players")

local InventoryService = require(script.Parent.InventoryService)

local antidoteCounts = {}

local function remember(player)
	antidoteCounts[player] = InventoryService.CountItem(player, "Antidote")
end

InventoryService.Changed.Event:Connect(function(player)
	local current = InventoryService.CountItem(player, "Antidote")
	local previous = antidoteCounts[player]
	if previous ~= nil and current < previous and (player:GetAttribute("SurvivalPoisonUntil") or 0) > os.clock() then
		player:SetAttribute("SurvivalPoisonUntil", 0)
	end
	antidoteCounts[player] = current
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("SurvivalPoisonUntil", 0)
	task.delay(1, function() if player.Parent then remember(player) end end)
end)
for _, player in Players:GetPlayers() do
	player:SetAttribute("SurvivalPoisonUntil", player:GetAttribute("SurvivalPoisonUntil") or 0)
	task.defer(remember, player)
end

Players.PlayerRemoving:Connect(function(player)
	antidoteCounts[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			if (player:GetAttribute("SurvivalPoisonUntil") or 0) > now then
				local character = player.Character
				local hum = character and character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then hum:TakeDamage(2) end
			end
		end
	end
end)
