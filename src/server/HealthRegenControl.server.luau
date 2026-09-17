local Players = game:GetService("Players")

local function disableDefaultRegen(character)
	-- Roblox characters can include a default Health script that regenerates health.
	-- Survival healing is intentionally consumable-only, so remove it every spawn.
	for _ = 1, 30 do
		local healthScript = character:FindFirstChild("Health")
		if healthScript and healthScript:IsA("Script") then
			healthScript:Destroy()
			return
		end
		task.wait(0.1)
	end
end

local function setup(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(disableDefaultRegen, character)
	end)
	if player.Character then task.spawn(disableDefaultRegen, player.Character) end
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do setup(player) end
