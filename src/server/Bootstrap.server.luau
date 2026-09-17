local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)
local BuildService = require(script.Parent.BuildService)
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
local selectedItems = {}

local function sendState(player, message, fx)
	if not player or not player.Parent then return end
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player),
		Message = message,
		FX = fx,
		SelectedItem = selectedItems[player] or "Axe",
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

local function getSelectedWeapon(player)
	local itemName = selectedItems[player] or "Axe"
	local item = ItemData.Items[itemName]
	if not item or item.Category ~= "Weapon" or not PlayerService.HasUnlock(player, itemName) then
		itemName = "Axe"
		item = ItemData.Items.Axe
		selectedItems[player] = itemName
	end
	return itemName, item
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
	selectedItems[player] = "Axe"
	player.CharacterAdded:Connect(function(character)
		setupDeathDrops(player, character)
	end)
	if player.Character then task.spawn(setupDeathDrops, player, player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

getState.OnServerInvoke = function(player)
	return {
		Profile = PlayerService.GetPublic(player),
		SelectedItem = selectedItems[player] or "Axe",
	}
end

getShop.OnServerInvoke = function()
	return MonetizationService.GetCatalog()
end

action.OnServerEvent:Connect(function(player, actionName, payload)
	if type(actionName) ~= "string" then return end

	if actionName == "SelectItem" then
		if type(payload) ~= "string" then return end
		local item = ItemData.Items[payload]
		if item and PlayerService.HasUnlock(player, payload) then
			selectedItems[player] = payload
			sendState(player, `{item.Label} selected.`)
		end
		return
	end

	if actionName == "ChooseUpgrade" then
		local success, message = PlayerService.ChooseUpgrade(player, payload)
		sendState(player, message, success and { Kind = "Upgrade" } or nil)
		return
	end

	if actionName == "Gather" then
		local _, weapon = getSelectedWeapon(player)
		if not ready(player, "Gather", weapon.Cooldown or Config.GatherCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.GatherDistance) then
			sendState(player, "Move closer to gather.")
			return
		end

		local targetModel = target and target:FindFirstAncestorOfClass("Model")
		local resourceType = targetModel and targetModel:GetAttribute("Resource")
		local lastMessage = nil
		local anySuccess = false
		for _ = 1, math.max(1, weapon.GatherHits or 1) do
			local changes, message = WorldService.Gather(target)
			if changes then
				PlayerService.Add(player, changes)
				anySuccess = true
				lastMessage = message
			else
				lastMessage = lastMessage or message
				break
			end
		end
		if anySuccess and resourceType == "Stone" and (weapon.StoneBonus or 0) > 0 then
			PlayerService.Add(player, { Stone = weapon.StoneBonus })
			lastMessage = `+{weapon.StoneBonus} bonus stone`
		end
		sendState(player, lastMessage, target and { Kind = "Gather", Position = target.Position } or nil)
	elseif actionName == "Attack" then
		local _, weapon = getSelectedWeapon(player)
		if not ready(player, "Attack", weapon.Cooldown or Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, weapon.Range or Config.AttackDistance) then return end
		local character = target:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local victim = character and Players:GetPlayerFromCharacter(character)
		if humanoid and victim and victim ~= player and humanoid.Health > 0 then
			local wasAlive = humanoid.Health > 0
			humanoid:TakeDamage(weapon.Damage or Config.PlayerDamage)
			PlayerService.Add(player, { XP = 4 })
			local killed = wasAlive and humanoid.Health <= 0
			if killed then
				PlayerService.Add(player, { Gold = 35, XP = 30 })
			end
			sendState(player, killed and "KO! +35 gold" or `Hit for {weapon.Damage or Config.PlayerDamage}!`, { Kind = killed and "KO" or "Hit", Position = target.Position })
		end
	elseif actionName == "AttackBuild" then
		local _, weapon = getSelectedWeapon(player)
		if not ready(player, "Attack", weapon.Cooldown or Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, weapon.Range or Config.AttackDistance) then return end
		if not CollectionService:HasTag(target, "PlayerBuild") then return end
		local model = target:FindFirstAncestorOfClass("Model")
		if not model then return end
		if model:GetAttribute("OwnerUserId") == player.UserId then
			sendState(player, "You cannot damage your own build.")
			return
		end
		local damage = weapon.BuildDamage or Config.BuildDamage
		local health = (model:GetAttribute("Health") or 1) - damage
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
		local item = ItemData.Items[buildType]
		if not item or item.Category ~= "Build" or not PlayerService.HasUnlock(player, buildType) then
			sendState(player, "That building is not unlocked.")
			return
		end
		local cost = item.Cost or {}
		if not PlayerService.Spend(player, cost) then
			sendState(player, "Not enough resources.")
			return
		end
		local created, message = BuildService.PlaceBuild(player, buildType, payload.Position, payload.Rotation)
		if not created then
			local refund = {}
			for resource, amount in cost do refund[resource] = amount end
			PlayerService.Add(player, refund)
		end
		sendState(player, message, created and { Kind = "Build", Position = payload.Position } or nil)
	end
end)

-- Passive building effects.
task.spawn(function()
	while true do
		task.wait(7)
		local arena = Workspace:FindFirstChild("SurvivalArena")
		if arena then
			for _, model in arena:GetChildren() do
				if model:IsA("Model") and model:GetAttribute("BuildType") == "Windmill" then
					local owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
					if owner then
						PlayerService.Add(owner, { Gold = 4 })
						sendState(owner, nil, { Kind = "Windmill" })
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		local arena = Workspace:FindFirstChild("SurvivalArena")
		if arena then
			for _, model in arena:GetChildren() do
				if model:IsA("Model") and model:GetAttribute("BuildType") == "Campfire" and model.PrimaryPart then
					local owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
					local character = owner and owner.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if root and humanoid and humanoid.Health > 0 and (root.Position - model.PrimaryPart.Position).Magnitude <= 18 then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 4)
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
	selectedItems[player] = nil
end)
