local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)
local MonetizationService = require(script.Parent.MonetizationService)

local remotes = Instance.new("Folder")
remotes.Name = "SurvivalRemotes"
remotes.Parent = ReplicatedStorage

local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes

local stateChanged = Instance.new("RemoteEvent")
stateChanged.Name = "StateChanged"
stateChanged.Parent = remotes

local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = remotes

local getShop = Instance.new("RemoteFunction")
getShop.Name = "GetShop"
getShop.Parent = remotes

PlayerService.Init()
WorldService.BuildArena()
MonetizationService.Init(PlayerService)

local cooldowns = {}

local function sendState(player, message)
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player),
		Message = message,
	})
end

local function ready(player, key, cooldown)
	local bucket = cooldowns[player.UserId]
	if not bucket then
		bucket = {}
		cooldowns[player.UserId] = bucket
	end
	local now = os.clock()
	if now - (bucket[key] or 0) < cooldown then return false end
	bucket[key] = now
	return true
end

local function validDistance(player, target, maxDistance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or typeof(target) ~= "Instance" or not target:IsA("BasePart") then return false end
	return (root.Position - target.Position).Magnitude <= maxDistance
end

getState.OnServerInvoke = function(player)
	return PlayerService.GetPublic(player)
end

getShop.OnServerInvoke = function()
	return MonetizationService.GetCatalog()
end

action.OnServerEvent:Connect(function(player, actionName, payload)
	if type(actionName) ~= "string" then return end

	if actionName == "Gather" then
		if not ready(player, "Gather", Config.GatherCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.GatherDistance) then
			sendState(player, "Move closer to gather.")
			return
		end
		local changes, message = WorldService.Gather(target)
		if changes then PlayerService.Add(player, changes) end
		sendState(player, message)
	elseif actionName == "Attack" then
		if not ready(player, "Attack", Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.AttackDistance) then return end
		local character = target:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local victim = character and Players:GetPlayerFromCharacter(character)
		if humanoid and victim and victim ~= player and humanoid.Health > 0 then
			humanoid:TakeDamage(22)
			PlayerService.Add(player, { XP = 4 })
			if humanoid.Health <= 0 then
				PlayerService.Add(player, { Gold = 35, XP = 30 })
			end
			sendState(player, "Hit!")
		end
	elseif actionName == "Eat" then
		local profile = PlayerService.Get(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if profile and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth and profile.Food > 0 then
			PlayerService.Add(player, { Food = -1 })
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 28)
			sendState(player, "Ate food and healed.")
		end
	elseif actionName == "Build" then
		if type(payload) ~= "table" then return end
		local buildType = payload.Type
		local cost = Config.BuildCosts[buildType]
		if not cost or not PlayerService.Spend(player, cost) then
			sendState(player, "Not enough resources.")
			return
		end
		local created, message = WorldService.PlaceBuild(player, buildType, payload.Position, payload.Rotation)
		if not created then
			local refund = {}
			for resource, amount in cost do refund[resource] = amount end
			PlayerService.Add(player, refund)
		end
		sendState(player, message)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)
