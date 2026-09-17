local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local BuildService = require(script.Parent.BuildService)
local ClanService = require(script.Parent.ClanService)
local HatService = require(script.Parent.HatService)
local MobService = require(script.Parent.MobService)
local MonetizationService = require(script.Parent.MonetizationService)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)

local oldRemotes = ReplicatedStorage:FindFirstChild("SurvivalRemotes")
if oldRemotes then oldRemotes:Destroy() end
local remotes = Instance.new("Folder")
remotes.Name = "SurvivalRemotes"
remotes.Parent = ReplicatedStorage

local function remoteEvent(name)
	local r = Instance.new("RemoteEvent") r.Name = name r.Parent = remotes return r
end
local function remoteFunction(name)
	local r = Instance.new("RemoteFunction") r.Name = name r.Parent = remotes return r
end

local action = remoteEvent("Action")
local secondaryFire = remoteEvent("SecondaryFire")
local comboAttack = remoteEvent("ComboAttack")
local stateChanged = remoteEvent("StateChanged")
local getState = remoteFunction("GetState")
local getShop = remoteFunction("GetShop")

PlayerService.Init()
ClanService.Init()
WorldService.BuildArena()
MonetizationService.Init(PlayerService)

local cooldowns = {}
local selectedItems = {}

local function defaultSelected(player) return PlayerService.GetPrimaryWeapon(player) end

local function sendState(player, message, fx)
	if not player or not player.Parent then return end
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player), Message = message, FX = fx,
		SelectedItem = selectedItems[player] or defaultSelected(player),
		BuildCounts = BuildService.GetOwnedCounts(player),
	})
end

local function bucket(player)
	local b = cooldowns[player.UserId]
	if not b then b = {} cooldowns[player.UserId] = b end
	return b
end

local function ready(player, key, seconds)
	local b, now = bucket(player), os.clock()
	if now - (b[key] or 0) < seconds then return false end
	b[key] = now
	return true
end

local function validDistance(player, target, maxDistance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and typeof(target) == "Instance" and target:IsA("BasePart") and (root.Position - target.Position).Magnitude <= maxDistance
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
	for _ = 1, 50 do if PlayerService.Get(player) then return true end task.wait(0.1) end
	return false
end

local function selectedShield(player)
	local name = selectedItems[player]
	local item = name and ItemData.Items[name]
	if item and item.Kind == "Shield" and PlayerService.HasUnlock(player, name) then return item end
	return nil
end

local function outgoingMultiplier(player)
	return PlayerService.GetHatEffect(player, "DamageMultiplier", 1) * math.max(0, player:GetAttribute("CloakDamageMultiplier") or 1)
end

local function applyDefense(victim, damage, ranged)
	local shield = selectedShield(victim)
	if shield then
		local block = ranged and (shield.RangedBlockPercent or shield.BlockPercent or 0) or (shield.BlockPercent or 0)
		damage *= 1 - math.clamp(block, 0, 0.9)
	end
	damage *= 1 - math.clamp(victim:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(0, math.floor(damage + 0.5))
end

local function applyKnockback(attacker, victimCharacter, amount)
	if not amount or amount <= 0 then return end
	local a = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	local v = victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
	if not a or not v then return end
	local flat = Vector3.new(v.Position.X - a.Position.X, 0, v.Position.Z - a.Position.Z)
	if flat.Magnitude > 0.01 then v.AssemblyLinearVelocity += flat.Unit * amount + Vector3.new(0, math.min(18, amount * 0.18), 0) end
end

local function stealGold(attacker, victim, percent)
	if ClanService.SameClan(attacker, victim) or not percent or percent <= 0 then return 0 end
	local profile = PlayerService.Get(victim)
	local held = profile and math.floor(profile.Gold or 0) or 0
	if held <= 0 then return 0 end
	local amount = math.min(held, math.max(1, math.floor(held * percent)))
	PlayerService.Add(victim, { Gold = -amount })
	PlayerService.Add(attacker, { Gold = amount })
	sendState(victim, `A thief stole {amount} gold from you!`, { Kind = "GoldStolen" })
	return amount
end

local function damagePlayer(attacker, victim, humanoid, weapon, ranged)
	if not victim or victim == attacker or ClanService.SameClan(attacker, victim) then return 0, false, "Clan friendly-fire blocked." end
	local baseDamage = weapon.PercentHealthDamage and humanoid.MaxHealth * weapon.PercentHealthDamage or (weapon.Damage or Config.PlayerDamage)
	local damage = applyDefense(victim, baseDamage * outgoingMultiplier(attacker), ranged)
	local wasAlive = humanoid.Health > 0
	if damage > 0 then humanoid:TakeDamage(damage) end
	if damage > 0 and weapon.Knockback and weapon.Knockback > 0 then applyKnockback(attacker, humanoid.Parent, weapon.Knockback) end
	local stolen = damage > 0 and stealGold(attacker, victim, weapon.GoldStealPercent) or 0
	if damage > 0 then PlayerService.Add(attacker, { XP = ranged and 5 or 4 }) end
	local killed = damage > 0 and wasAlive and humanoid.Health <= 0
	if killed then PlayerService.Add(attacker, { Gold = 35, XP = 30 }) end
	local msg = killed and "KO! +35 gold" or `Hit for {damage}!`
	if stolen > 0 then msg ..= `  Stole {stolen} gold!` end
	return damage, killed, msg
end

local function damageMob(player, model, humanoid, weapon)
	local base = weapon.PercentHealthDamage and humanoid.MaxHealth * weapon.PercentHealthDamage or (weapon.Damage or 0)
	local damage = math.max(0, math.floor(base * outgoingMultiplier(player) + 0.5))
	if damage > 0 then MobService.Damage(model, player, damage) end
	return damage
end

local function damageBuildFromWeapon(player, target, weapon)
	if not CollectionService:HasTag(target, "PlayerBuild") then return false end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model then return false end
	local wasOwn = model:GetAttribute("OwnerUserId") == player.UserId
	local destroyed, salvage, message = BuildService.DamageBuild(player, model, weapon.BuildDamage or Config.BuildDamage)
	if destroyed then
		PlayerService.Add(player, salvage or {})
		if not wasOwn then PlayerService.Add(player, { XP = 8 }) end
	end
	return true, message, destroyed
end

local function applyCharacterSetup(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then return end
	if waitForProfile(player) then
		local profile = PlayerService.Get(player)
		HatService.Apply(player, profile and profile.EquippedHat or nil)
	else HatService.Apply(player, nil) end
	if humanoid:GetAttribute("DeathDropConnected") then return end
	humanoid:SetAttribute("DeathDropConnected", true)
	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		local drops = PlayerService.TakeDeathDrop(player, 1)
		WorldService.CreateLootBag(root and root.Position or Vector3.new(0, 3, 0), drops)
		sendState(player, "Your carried wood, stone and food dropped. Gold is safe.", { Kind = "Death" })
	end)
end

local function setupPlayer(player)
	selectedItems[player] = nil
	task.spawn(function() if waitForProfile(player) then selectedItems[player] = defaultSelected(player) end end)
	player.CharacterAdded:Connect(function(character) task.spawn(applyCharacterSetup, player, character) end)
	if player.Character then task.spawn(applyCharacterSetup, player, player.Character) end
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

getState.OnServerInvoke = function(player)
	return { Profile = PlayerService.GetPublic(player), SelectedItem = selectedItems[player] or defaultSelected(player), BuildCounts = BuildService.GetOwnedCounts(player) }
end
getShop.OnServerInvoke = function() return MonetizationService.GetCatalog() end

local function applyGatherHatBonus(player, changes)
	if type(changes) ~= "table" then return changes end
	if changes.Wood and changes.Wood > 0 then changes.Wood = math.max(changes.Wood, math.floor(changes.Wood * PlayerService.GetHatEffect(player, "WoodMultiplier", 1) + 0.5)) end
	if changes.Stone and changes.Stone > 0 then changes.Stone = math.max(changes.Stone, math.floor(changes.Stone * PlayerService.GetHatEffect(player, "StoneMultiplier", 1) + 0.5)) end
	return changes
end

action.OnServerEvent:Connect(function(player, actionName, payload)
	if type(actionName) ~= "string" then return end
	if actionName == "SelectItem" then
		if type(payload) == "string" and ItemData.Items[payload] and PlayerService.HasUnlock(player, payload) then selectedItems[player] = payload sendState(player, `${ItemData.Items[payload].Label} selected.`) end
		return
	elseif actionName == "ChooseUpgrade" then
		local oldSelected = selectedItems[player]
		local success, message = PlayerService.ChooseUpgrade(player, payload)
		if success then
			local chosen = ItemData.Items[payload]
			if chosen and chosen.Category == "Weapon" then selectedItems[player] = payload
			elseif oldSelected and not PlayerService.HasUnlock(player, oldSelected) then selectedItems[player] = defaultSelected(player) end
		end
		sendState(player, message, success and { Kind = "Upgrade" } or nil)
		return
	elseif actionName == "BuyHat" or actionName == "EquipHat" then
		local success, message = actionName == "BuyHat" and PlayerService.BuyHat(player, payload) or PlayerService.EquipHat(player, payload)
		if success then local profile = PlayerService.Get(player) HatService.Apply(player, profile and profile.EquippedHat or nil) end
		sendState(player, message, success and { Kind = "Hat" } or nil)
		return
	elseif actionName == "Gather" then
		local _, weapon = getSelectedWeapon(player)
		if weapon.CanGather == false or weapon.Ranged or weapon.Kind == "Shield" then return end
		if not ready(player, "Gather", weapon.Cooldown or Config.GatherCooldown) then return end
		local target = payload
		if not validDistance(player, target, Config.GatherDistance) then return end
		local targetModel = target and target:FindFirstAncestorOfClass("Model")
		local resourceType = targetModel and targetModel:GetAttribute("Resource")
		local lastMessage, anySuccess = nil, false
		for _ = 1, math.max(1, weapon.GatherHits or 1) do
			local changes, message = WorldService.Gather(target)
			if not changes then lastMessage = lastMessage or message break end
			applyGatherHatBonus(player, changes) PlayerService.Add(player, changes) anySuccess = true lastMessage = message
		end
		if anySuccess and resourceType then
			local bonus = weapon.ResourceBonus or 0
			if resourceType == "Stone" then bonus += weapon.StoneBonus or 0 end
			if resourceType == "Wood" then bonus += weapon.WoodBonus or 0 end
			if bonus > 0 then PlayerService.Add(player, { [resourceType] = bonus }) end
		end
		sendState(player, lastMessage, target and { Kind = "Gather", Position = target.Position } or nil)
		return
	elseif actionName == "Attack" or actionName == "AttackBuild" then
		local _, weapon = getSelectedWeapon(player)
		if weapon.Ranged or weapon.Kind == "Shield" or weapon.CanAttack == false or not ready(player, "Attack", weapon.Cooldown or Config.AttackCooldown) then return end
		local target = payload
		if not validDistance(player, target, weapon.Range or Config.AttackDistance) then return end
		if CollectionService:HasTag(target, "PlayerBuild") then damageBuildFromWeapon(player, target, weapon) return end
		local model = target:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local victim = model and Players:GetPlayerFromCharacter(model)
		if hum and victim and hum.Health > 0 then
			local _, killed, message = damagePlayer(player, victim, hum, weapon, false)
			sendState(player, message, { Kind = killed and "KO" or "Hit", Position = target.Position })
		elseif hum and model and model:GetAttribute("SurvivalMob") == true then damageMob(player, model, hum, weapon) end
		return
	elseif actionName == "Eat" then
		if not ready(player, "Eat", 0.35) then return end
		local profile = PlayerService.Get(player)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if profile and hum and hum.Health > 0 and hum.Health < hum.MaxHealth and profile.Food > 0 then
			PlayerService.Add(player, { Food = -1 }) hum.Health = math.min(hum.MaxHealth, hum.Health + Config.FoodHeal) sendState(player, "Ate food and healed.", { Kind = "Heal" })
		end
		return
	elseif actionName == "Build" then
		if not ready(player, "Build", 0.18) or type(payload) ~= "table" then return end
		local buildType, item = payload.Type, ItemData.Items[payload.Type]
		if not item or item.Category ~= "Build" or not PlayerService.HasUnlock(player, buildType) then sendState(player, "That building is not unlocked.") return end
		local allowed, reason = BuildService.CanPlace(player, buildType, payload.Position, payload.Rotation)
		if not allowed then sendState(player, reason) return end
		local cost = item.Cost or {}
		if not PlayerService.Spend(player, cost) then sendState(player, "Not enough resources.") return end
		local created, message = BuildService.PlaceBuild(player, buildType, payload.Position, payload.Rotation)
		if not created then PlayerService.Add(player, cost) end
		sendState(player, message, created and { Kind = "Build", Position = payload.Position } or nil)
	end
end)

local function tracer(origin, hitPosition, color)
	local delta = hitPosition - origin
	if delta.Magnitude <= 0.05 then return end
	local p = Instance.new("Part")
	p.Name = "ProjectileTracer" p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Material = Enum.Material.Neon
	p.Color = color or Color3.fromRGB(224, 230, 244) p.Size = Vector3.new(0.12, 0.12, delta.Magnitude) p.CFrame = CFrame.lookAt(origin + delta * 0.5, hitPosition) p.Parent = Workspace
	Debris:AddItem(p, 0.08)
end

local function raycastWeapon(player, weapon, origin, direction)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	params.IgnoreWater = true
	local result = Workspace:Raycast(origin, direction * (weapon.Range or 80), params)
	local hitPosition = result and result.Position or (origin + direction * (weapon.Range or 80))
	tracer(origin, hitPosition, weapon.Visual == "Musket" and Color3.fromRGB(255, 226, 160) or nil)
	if not result then return end
	local hit = result.Instance
	if CollectionService:HasTag(hit, "PlayerBuild") then damageBuildFromWeapon(player, hit, weapon) return end
	local model = hit:FindFirstAncestorOfClass("Model")
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	local victim = model and Players:GetPlayerFromCharacter(model)
	if hum and victim and hum.Health > 0 then
		local _, killed, message = damagePlayer(player, victim, hum, weapon, true)
		sendState(player, message, { Kind = killed and "KO" or "Hit", Position = result.Position })
	elseif hum and model and model:GetAttribute("SurvivalMob") == true then damageMob(player, model, hum, weapon) end
end

local function fireRanged(player, weapon, aimPosition)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	local origin = (head and head.Position or root.Position) + Vector3.new(0, 0.4, 0)
	local flatAim = Vector3.new(aimPosition.X, origin.Y, aimPosition.Z)
	local base = flatAim - origin
	if base.Magnitude < 0.1 then base = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) end
	if base.Magnitude < 0.1 then return end
	local baseDir = base.Unit
	for _ = 1, math.max(1, weapon.ProjectileCount or 1) do
		local dir = baseDir
		if (weapon.Spread or 0) > 0 then
			local side = Vector3.new(-baseDir.Z, 0, baseDir.X)
			dir = (baseDir + side * ((math.random() * 2 - 1) * weapon.Spread)).Unit
		end
		raycastWeapon(player, weapon, origin, dir)
	end
end

secondaryFire.OnServerEvent:Connect(function(player, aimPosition)
	if typeof(aimPosition) ~= "Vector3" then return end
	local itemName, weapon = getSelectedWeapon(player)
	if not weapon.Ranged or not PlayerService.HasUnlock(player, itemName) or not ready(player, `Ranged:${itemName}`, weapon.Cooldown or 0.8) then return end
	fireRanged(player, weapon, aimPosition)
end)

local function comboMelee(player, weapon)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local range = weapon.Range or Config.AttackDistance
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local params = OverlapParams.new() params.FilterType = Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances = { character }
	local seen = {}
	for _, hit in Workspace:GetPartBoundsInRadius(root.Position, range + 1, params) do
		local model = hit:FindFirstAncestorOfClass("Model")
		if model and not seen[model] and model.PrimaryPart then
			local delta = Vector3.new(model.PrimaryPart.Position.X - root.Position.X, 0, model.PrimaryPart.Position.Z - root.Position.Z)
			if delta.Magnitude > 0.1 and delta.Magnitude <= range and forward:Dot(delta.Unit) >= math.cos(math.rad(50)) then
				seen[model] = true
				local hum = model:FindFirstChildOfClass("Humanoid")
				local victim = Players:GetPlayerFromCharacter(model)
				if hum and victim then damagePlayer(player, victim, hum, weapon, false)
				elseif hum and model:GetAttribute("SurvivalMob") == true then damageMob(player, model, hum, weapon) end
			end
		end
	end
end

comboAttack.OnServerEvent:Connect(function(player, aimPosition)
	if typeof(aimPosition) ~= "Vector3" then return end
	local primaryName = PlayerService.GetPrimaryWeapon(player)
	local secondaryName = PlayerService.GetSecondaryWeapon(player)
	local primary, secondary = primaryName and ItemData.Items[primaryName], secondaryName and ItemData.Items[secondaryName]
	if not primary or primary.Ranged or primary.Kind == "Shield" or primary.CanAttack == false then return end
	if not secondary or not secondary.Ranged then return end
	if not ready(player, "ComboAttack", math.max(0.75, secondary.Cooldown or 0.8)) then return end
	comboMelee(player, primary)
	fireRanged(player, secondary, aimPosition)
	sendState(player, "COMBO: melee + ranged!", { Kind = "Combo" })
end)

local function nearestEnemy(owner, position, range)
	local bestHumanoid, bestDistance = nil, range
	for _, other in Players:GetPlayers() do
		if other ~= owner and not ClanService.SameClan(owner, other) then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local hum = character and character:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local distance = (root.Position - position).Magnitude
				if distance <= bestDistance then bestDistance, bestHumanoid = distance, hum end
			end
		end
	end
	return bestHumanoid
end

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
				if type(nextPassive) ~= "number" then nextPassive = now + (item.TickSeconds or 8) model:SetAttribute("NextPassiveAt", nextPassive) end
				if now >= nextPassive then
					local grant = {} if item.GoldPerTick then grant.Gold = item.GoldPerTick end if item.WoodPerTick then grant.Wood = item.WoodPerTick end
					PlayerService.Add(owner, grant) model:SetAttribute("NextPassiveAt", now + (item.TickSeconds or 8)) sendState(owner, nil, { Kind = "PassiveBuild" })
				end
			end
			if owner and (item.HealPerSecond or 0) > 0 and item.EffectRange then
				local r = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
				local h = owner.Character and owner.Character:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health > 0 and (r.Position - model.PrimaryPart.Position).Magnitude <= item.EffectRange then h.Health = math.min(h.MaxHealth, h.Health + item.HealPerSecond) end
			end
			if owner and item.TurretDamage and item.TurretRange and now >= (model:GetAttribute("NextTurretShot") or 0) then
				local targetHum = nearestEnemy(owner, model.PrimaryPart.Position, item.TurretRange)
				if targetHum then
					local victim = Players:GetPlayerFromCharacter(targetHum.Parent)
					local damage = victim and math.floor(item.TurretDamage * (1 - math.clamp(victim:GetAttribute("ArmorReduction") or 0, 0, 0.65)) + 0.5) or item.TurretDamage
					targetHum:TakeDamage(damage)
					model:SetAttribute("NextTurretShot", now + (item.TurretCooldown or 1.3))
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) cooldowns[player.UserId] = nil selectedItems[player] = nil end)
