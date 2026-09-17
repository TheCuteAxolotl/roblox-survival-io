local Players = game:GetService("Players")

local PlayerService = require(script.Parent.PlayerService)

local function apply(player)
	local leaderstats = player:WaitForChild("leaderstats", 12)
	if not leaderstats then return end

	for _, name in { "Wood", "Stone", "Food", "XP", "Age" } do
		local value = leaderstats:FindFirstChild(name)
		if value then value:Destroy() end
	end

	local forge = leaderstats:FindFirstChild("Forge")
	if not forge then
		forge = Instance.new("IntValue")
		forge.Name = "Forge"
		forge.Parent = leaderstats
	end

	task.spawn(function()
		while player.Parent and forge.Parent do
			local profile = PlayerService.Get(player)
			forge.Value = math.floor(profile and profile.Age or 1)
			task.wait(0.5)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(apply, player)
end)
for _, player in Players:GetPlayers() do task.spawn(apply, player) end
