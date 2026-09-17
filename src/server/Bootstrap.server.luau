local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)
local BuildService = require(script.Parent.BuildService)
local HatService = require(script.Parent.HatService)
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

local function defaultSelected(player)
	return PlayerService.GetPrimaryWeapon(player)
end

local function sendState(player, message, fx)
	if not player or not player.Parent then return end
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player),
		Message = message,
		FX = fx,
		SelectedItem = selectedItems[player] or defaultSelected(player),
		BuildCounts = BuildService.GetOwnedCounts(player),
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
	local itemName = selectedItems[player] or defaultSelected(player)
	local item = ItemData.Items[itemName]
	if not item or item.Category ~= "Weapon" or not PlayerService.HasUnlock(player, itemName) then
		itemName = defaultSelected(player)
		item = ItemData.Items[itemName] or ItemData.Items.Axe
		selectedItems[player] = itemName
	end
	return itemName, item
end

local function waitForProfile(player)
	for _ = 1, 50 do
		if PlayerService.Get(player) then return true end
		task.wait(0.1)
	end
	return false
end

local function applyCharacterSetup(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then return end
	if waitForProfile(player) then
		local profile = PlayerService.Get(player)
		HatService.Apply(player, profile and profile.EquippedHat or nil)
	else
		HatService.Apply(player, nil)
	end

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
	selectedItems[player] = nil
	task.spawn(function()
		if waitForProfile(player) then
			selectedItems[player] = defaultSelected(player)
		end
	end)
	player.CharacterAdded:Connect(function(character)
		task.spawn(applyCharacterSetup, player, character)
	end)
	if player.Character then task.spawn(applyCharacterSetup, player, player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

getState.OnServerInvoke = function(player)
	return {
		Profile = PlayerService.GetPublic(player),
		SelectedItem = selectedItems[player] or defaultSelected(player),
		BuildCounts = BuildService.GetOwnedCounts(player),
	}
end

getShop.OnServerInvoke = function()
	return MonetizationService.GetCatalog()
end

local function applyGatherHatBonus(player, changes)
	if type(changes) ~= "table" then return changes end
	if changes.Wood and changes.Wood > 0 then
		local multiplier = PlayerService.GetHatEffect(player, "WoodMultiplier", 1)
		changes.Wood = math.max(changes.Wood, math.floor(changes.Wood * multiplier + 0.5))
	end
	if changes.Stone and changes.Stone > 0 then
		local multiplier = PlayerService.GetHatEffect(player, "StoneMultiplier", 1)
		changes.Stone = math.max(changes.Stone, math.floor(changes.Stone * multiplier + 0.5))
	end
	return changes
end

local function salvageText(salvage)
	local pieces = {}
	for _, resource in { "Wood", "Stone", "Food", "Gold" } do
		local amount = salvage and salvage[resource] or 0
		if amount and amount > 0 then table.insert(pieces, `+{amount} {resource:lower()}`) end
	end
	return table.concat(pieces, "  ")
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
		local oldSelected = selectedItems[player]
		local oldItem = oldSelected and ItemData.Items[oldSelected]
		local success, message = PlayerService.ChooseUpgrade(player, payload)
		if success then
			local chosen = ItemData.Items[payload]
			if chosen and chosen.UpgradeGroup == "PrimaryWeapon" then
				selectedItems[player] = payload
			elseif chosen and oldItem and chosen.UpgradeGroup and oldItem.UpgradeGroup == chosen.UpgradeGroup then
				selectedItems[player] = payload
			elseif oldSelected and not PlayerService.HasUnlock(player, oldSelected) then
				selectedItems[player] = defaultSelected(player)
			end
		end
		sendState(player, message, success and { Kind = "Upgrade" } or nil)
		return
	end

	if actionName == "BuyHat" then
		local success, message = PlayerService.BuyHat(player, payload)
		if success then
			local profile = PlayerService.Get(player)
			HatService.Apply(player, profile and profile.EquippedHat or nil)
		end
		sendState(player, message, success and { Kind = "Hat" } or nil)
		return
	end

	if actionName == "EquipHat" then
		local success, message = PlayerService.EquipHat(player, payload)
		if success then
			local profile = PlayerService.Get(player)
			HatService.Apply(player, profile and profile.EquippedHat or nil)
		end
		sendState(player, message, success and { Kind = "Hat" } or nil)
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
				applyGatherHatBonus(player, changes)
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
			local multiplier = PlayerService.GetHatEffect(player, "DamageMultiplier", 1)
			local damage = math.floor((weapon.Damage or Config.PlayerDamage) * multiplier + 0.5)
			local wasAlive = humanoid.Health > 0
			humanoid:TakeDamage(damage)
			PlayerService.Add(player, { XP = 4 })
			local killed = wasAlive and humanoid.Health <= 0
			if killed then PlayerService.Add(player, { Gold = 35, XP = 30 }) end
			sendState(player, killed and "KO! +35 gold" or `Hit for {damage}!`, { Kind = killed and "KO" or "Hit", Position = target.Position })
		end
	elseif actionName == "AttackBuild" then
		local _, weapon = getSelectedWeapon(player)
		if not ready(player, "Attack", weapon.Cooldown or Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, weapon.Range or Config.AttackDistance) then return end
		if not CollectionService:HasTag(target, "PlayerBuild") then return end
		local model = target:FindFirstAncestorOfClass("Model")
		if not model then return end
		local wasOwn = model:GetAttribute("OwnerUserId") == player.UserId
		local destroyed, salvage, message = BuildService.DamageBuild(player, model, weapon.BuildDamage or Config.BuildDamage)
		if destroyed then
			PlayerService.Add(player, salvage or {})
			if not wasOwn then PlayerService.Add(player, { XP = 8 }) end
			local extra = salvageText(salvage)
			if extra ~= "" then message = `{message}  {extra}` end
			sendState(player, message, { Kind = "Break", Position = target.Position })
		else
			sendState(player, message, { Kind = "Hit", Position = target.Position })
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
		local allowed, reason = BuildService.CanPlace(player, buildType, payload.Position, payload.Rotation)
		if not allowed then
			sendState(player, reason)
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

local function nearestEnemy(owner, position, range)
	local bestHumanoid = nil
	local bestDistance = range
	for _, other in Players:GetPlayers() do
		if other ~= owner then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local distance = (root.Position - position).Magnitude
				if distance <= bestDistance then
					bestDistance = distance
					bestHumanoid = humanoid
				end
			end
		end
	end
	return bestHumanoid
end

-- Passive structure effects and automated defenses.
task.spawn(function()
	while true do
		task.wait(1)
		local arena = Workspace:FindFirstChild("SurvivalArena")
		if not arena then continue end
		local now = os.clock()

		for _, model in arena:GetChildren() do
			if not model:IsA("Model") or not model.PrimaryPart then continue end
			local buildType = model:GetAttribute("BuildType")
			local item = buildType and ItemData.Items[buildType]
			if not item then continue end
			local owner = Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)

			if owner and (item.GoldPerTick or item.WoodPerTick) then
				local nextPassive = model:GetAttribute("NextPassiveAt")
				if type(nextPassive) ~= "number" then
					nextPassive = now + (item.TickSeconds or 8)
					model:SetAttribute("NextPassiveAt", nextPassive)
				end
				if now >= nextPassive then
					local grant = {}
					if item.GoldPerTick then grant.Gold = item.GoldPerTick end
					if item.WoodPerTick then grant.Wood = item.WoodPerTick end
					PlayerService.Add(owner, grant)
					model:SetAttribute("NextPassiveAt", now + (item.TickSeconds or 8))
					sendState(owner, nil, { Kind = item.GoldPerTick and "Windmill" or "Resource" })
				end
			end

			if owner and item.HealPerSecond then
				local character = owner.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and (root.Position - model.PrimaryPart.Position).Magnitude <= (item.EffectRange or 16) then
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + item.HealPerSecond)
				end
			elseif owner and buildType == "Campfire" then
				local character = owner.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and (root.Position - model.PrimaryPart.Position).Magnitude <= 18 then
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 4)
				end
			end

			if owner and item.TurretDamage then
				local nextAttack = model:GetAttribute("NextAttackAt") or 0
				if now >= nextAttack then
					local targetHumanoid = nearestEnemy(owner, model.PrimaryPart.Position, item.TurretRange or 50)
					if targetHumanoid then
						targetHumanoid:TakeDamage(item.TurretDamage)
						model:SetAttribute("NextAttackAt", now + (item.TurretCooldown or 1.5))
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
