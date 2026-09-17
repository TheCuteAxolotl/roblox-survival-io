local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.PlayerService)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")

local XP_BY_MILL = {
	Windmill = { XP = 1, Gold = 1, Seconds = 8 },
	RapidMill = { XP = 3, Gold = 3, Seconds = 5 },
	PowerMill = { XP = 6, Gold = 6, Seconds = 10 },
}

local function processMill(model, now)
	local data = XP_BY_MILL[model:GetAttribute("BuildType")]
	if not data then return end

	local owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
	if not owner or not PlayerService.Get(owner) then return end

	local last = model:GetAttribute("LastProgressionTick") or 0
	if now - last < data.Seconds then return end
	model:SetAttribute("LastProgressionTick", now)

	local xpMultiplier = PlayerService.GetHatEffect(owner, "WindmillXPMultiplier", 1)
	local goldMultiplier = PlayerService.GetHatEffect(owner, "WindmillGoldMultiplier", 1)
	local xp = math.max(1, math.floor(data.XP * xpMultiplier + 0.5))
	local bonusGold = math.max(0, math.floor(data.Gold * math.max(0, goldMultiplier - 1) + 0.5))

	local changes = { XP = xp }
	if bonusGold > 0 then changes.Gold = bonusGold end
	PlayerService.Add(owner, changes)
	stateChanged:FireClient(owner, {
		Profile = PlayerService.GetPublic(owner),
		FX = { Kind = "WindmillXP" },
	})
end

task.spawn(function()
	while true do
		task.wait(1)
		local arena = Workspace:FindFirstChild("SurvivalArena")
		if arena then
			local now = os.clock()
			for _, model in arena:GetChildren() do
				if model:IsA("Model") then processMill(model, now) end
			end
		end
	end
end)
