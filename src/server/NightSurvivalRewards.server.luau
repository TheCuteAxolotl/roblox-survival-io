local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.PlayerService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
local stateChanged = remotes and remotes:WaitForChild("StateChanged", 10)

local participation = {}
local nightThreat = 1
local nightEvent = ""
local lastPhase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"
local MIN_SURVIVAL_SECONDS = 45

local function alive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function beginNight()
	participation = {}
	nightThreat = math.clamp(ReplicatedStorage:GetAttribute("WildforgeThreat") or 1, 1, 6)
	nightEvent = ReplicatedStorage:GetAttribute("WildforgeEvent") or ""
	for _, player in Players:GetPlayers() do participation[player] = 0 end
end

local function awardDawn()
	for player, secondsAlive in participation do
		if player.Parent and alive(player) and secondsAlive >= MIN_SURVIVAL_SECONDS then
			local gold = 5 + nightThreat * 3
			local xp = 30 + nightThreat * 12
			if nightEvent == "BLOOD MOON" then
				gold += 12
				xp += 50
			elseif nightEvent == "PREDATOR HUNT" then
				gold += 5
				xp += 20
			end
			PlayerService.Add(player, { Gold = gold, XP = xp })
			if stateChanged then
				stateChanged:FireClient(player, {
					Profile = PlayerService.GetPublic(player),
					Message = `Night survived! +{gold} Gold • +{xp} Forge XP`,
					FX = { Kind = "Upgrade" },
				})
			end
		end
	end
	participation = {}
end

ReplicatedStorage:GetAttributeChangedSignal("WildforgePhase"):Connect(function()
	task.defer(function()
		local phase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"
		if phase == lastPhase then return end
		local previous = lastPhase
		lastPhase = phase
		if phase == "Night" then
			beginNight()
		elseif previous == "Night" and phase == "Dawn" then
			awardDawn()
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	participation[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(1)
		if (ReplicatedStorage:GetAttribute("WildforgePhase") or "Day") == "Night" then
			for _, player in Players:GetPlayers() do
				if alive(player) then
					participation[player] = (participation[player] or 0) + 1
				else
					-- A death breaks the survival streak; respawning starts a new attempt.
					participation[player] = 0
				end
			end
		end
	end
end)

if lastPhase == "Night" then beginNight() end
