local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ItemData = require(ReplicatedStorage.Shared.ItemData)
local PlayerService = require(script.Parent.PlayerService)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")

local function processMill(model, now)
	local buildType = model:GetAttribute("BuildType")
	local item = buildType and ItemData.Items[buildType]
	if not item or item.UpgradeGroup ~= "Mill" or not item.GoldPerTick then return end

	local owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
	if not owner or not PlayerService.Get(owner) then return end

	local seconds = item.TickSeconds or 8
	local last = model:GetAttribute("LastProgressionTick") or 0
	if now - last < seconds then return end
	model:SetAttribute("LastProgressionTick", now)

	-- Windmills generate XP at the same base rate as their gold payout unless a
	-- future mill explicitly defines XPPerTick.
	local baseXP = item.XPPerTick or item.GoldPerTick
	local xpMultiplier = PlayerService.GetHatEffect(owner, "WindmillXPMultiplier", 1)
	local goldMultiplier = PlayerService.GetHatEffect(owner, "WindmillGoldMultiplier", 1)
	local xp = math.max(1, math.floor(baseXP * xpMultiplier + 0.5))

	-- Bootstrap already grants the normal GoldPerTick. This script adds only the
	-- hat-based bonus gold so base income cannot be paid twice.
	local bonusGold = math.max(0, math.floor(item.GoldPerTick * math.max(0, goldMultiplier - 1) + 0.5))
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
