local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.PlayerService)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")

local passiveTimers = {}

Players.PlayerRemoving:Connect(function(player)
	passiveTimers[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local profile = PlayerService.Get(player)
			if not profile then continue end

			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local regen = PlayerService.GetHatEffect(player, "HealthRegenPerSecond", 0)
			if regen > 0 and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + regen)
			end

			local passiveSeconds = PlayerService.GetHatEffect(player, "PassiveSeconds", 0)
			local passiveFood = PlayerService.GetHatEffect(player, "PassiveFood", 0)
			if passiveSeconds > 0 and passiveFood > 0 then
				local state = passiveTimers[player]
				local hatName = profile.EquippedHat
				if not state or state.Hat ~= hatName then
					state = { Hat = hatName, Elapsed = 0 }
					passiveTimers[player] = state
				end
				state.Elapsed += 1
				if state.Elapsed >= passiveSeconds then
					state.Elapsed = 0
					PlayerService.Add(player, { Food = passiveFood })
					stateChanged:FireClient(player, {
						Profile = PlayerService.GetPublic(player),
						Message = `Forager Cap: +{passiveFood} food`,
						FX = { Kind = "Hat" },
					})
				end
			else
				passiveTimers[player] = nil
			end
		end
	end
end)
