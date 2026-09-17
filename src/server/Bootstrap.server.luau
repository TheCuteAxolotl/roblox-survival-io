local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)
local MonetizationService = require(script.Parent.MonetizationService)

local oldRemotes = ReplicatedStorage:FindFirstChild("SurvivalRemotes")
if oldRemotes then oldRemotes:Destroy() end

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

local function sendState(player, message, fx)
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player),
		Message = message,
		FX = fx,
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

local function setupDeathDrops(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then return end
	if humanoid:GetAttribute("DeathDropConnected") then return end
	humanoid:SetAttribute("DeathDropConnected", true)

	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		local position = root and root.Position or Vector3.new(0, 3, 0)
		local drops = PlayerService.TakeDeathDrop(player, 0.35)
		WorldService.CreateLootBag(position, drops)
		sendState(player, "You dropped 35% of your carried resources.", { Kind = "Death" })
	end)
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		setupDeathDrops(player, character)
	end)
	if player.Character then task.spawn(setupDeathDrops, player, player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

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
		sendState(player, message, target and { Kind = "Gather", Position = target.Position } or nil)
	elseif actionName == "Attack" then
		if not ready(player, "Attack", Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.AttackDistance) then return end
		local character = target:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local victim = character and Players:GetPlayerFromCharacter(character)
		if humanoid and victim and victim ~= player and humanoid.Health > 0 then
			local wasAlive = humanoid.Health > 0
			humanoid:TakeDamage(Config.PlayerDamage)
			PlayerService.Add(player, { XP = 4 })
			local killed = wasAlive and humanoid.Health <= 0
			if killed then
				PlayerService.Add(player, { Gold = 35, XP = 30 })
			end
			sendState(player, killed and "KO! +35 gold" or "Hit!", { Kind = killed and "KO" or "Hit", Position = target.Position })
		end
	elseif actionName == "AttackBuild" then
		if not ready(player, "Attack", Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.AttackDistance) then return end
		if not CollectionService:HasTag(target, "PlayerBuild") then return end
		local model = target:FindFirstAncestorOfClass("Model")
		if not model then return end
		if model:GetAttribute("OwnerUserId") == player.UserId then
			sendState(player, "You cannot damage your own build.")
			return
		end
		local health = (model:GetAttribute("Health") or 1) - Config.BuildDamage
		model:SetAttribute("Health", health)
		if health <= 0 then
			local pos = model.PrimaryPart and model.PrimaryPart.Position or target.Position
			model:Destroy()
			PlayerService.Add(player, { XP = 8 })
			sendState(player, "Structure destroyed!", { Kind = "Break", Position = pos })
		else
			sendState(player, `Structure: {math.max(0, health)} HP`, { Kind = "Hit", Position = target.Position })
		end
	elseif actionName == "Eat" then
		if not ready(player, "Eat", 0.35) then return end
		local profile = PlayerService.Get(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if profile and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth and profile.Food > 0 then
			PlayerService.Add(player, { Food = -1 })
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + Config.FoodHeal)
			sendState(player, "Ate food and healed.", { Kind = "Heal" })
		end
	elseif actionName == "Build" then
		if not ready(player, "Build", 0.18) then return end
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
		sendState(player, message, created and { Kind = "Build", Position = payload.Position } or nil)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)
