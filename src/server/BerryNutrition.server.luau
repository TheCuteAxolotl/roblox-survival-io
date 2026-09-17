local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local nutritionEvent = script.Parent:WaitForChild("SurvivalNutrition")

local lastBerry = {}

local function berryModel(player, target)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then return nil end
	if not CollectionService:HasTag(target, "SurvivalResource") then return nil end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or model:GetAttribute("Resource") ~= "Food" or model:GetAttribute("Alive") ~= true then return nil end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - target.Position).Magnitude > Config.GatherDistance + 2 then return nil end
	return model
end

action.OnServerEvent:Connect(function(player, actionName, target)
	if actionName ~= "Gather" then return end
	local model = berryModel(player, target)
	if not model then return end
	local beforeHealth = model:GetAttribute("Health") or 0
	local beforeAlive = model:GetAttribute("Alive") == true

	-- Wait until the authoritative gather handler has had a chance to process the same click.
	task.defer(function()
		if not player.Parent or not model.Parent or not beforeAlive then return end
		local afterHealth = model:GetAttribute("Health") or 0
		local afterAlive = model:GetAttribute("Alive") == true
		local successfullyGathered = afterHealth < beforeHealth or (beforeAlive and not afterAlive)
		if not successfullyGathered then return end

		local now = os.clock()
		if now - (lastBerry[player] or 0) < 0.28 then return end
		lastBerry[player] = now
		nutritionEvent:Fire(player, 6, 0, 2, "Berries: +6 hunger  •  +2 HP")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastBerry[player] = nil
end)
