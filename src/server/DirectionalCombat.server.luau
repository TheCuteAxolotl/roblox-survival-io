local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local BuildService = require(script.Parent.BuildService)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local directional = remotes:FindFirstChild("DirectionalAction") or Instance.new("RemoteEvent")
directional.Name = "DirectionalAction"
directional.Parent = remotes

local selected = {}
local cooldowns = {}
local CONE_DOT = math.cos(math.rad(55))
local MAX_TARGETS = 10

local function sendState(player, message, kind)
	stateChanged:FireClient(player, {
		Profile = PlayerService.GetPublic(player),
		Message = message,
		FX = kind and { Kind = kind } or nil,
		SelectedItem = selected[player] or PlayerService.GetPrimaryWeapon(player),
		BuildCounts = BuildService.GetOwnedCounts(player),
	})
end

local function ready(player, cooldown)
	local now = os.clock()
	if now - (cooldowns[player] or 0) < cooldown then return false end
	cooldowns[player] = now
	return true
end

local function currentWeapon(player)
	local name = selected[player]
	if not name or not PlayerService.HasUnlock(player, name) then name = PlayerService.GetPrimaryWeapon(player) end
	local item = name and ItemData.Items[name]
	if not item or item.Category ~= "Weapon" then
		name = PlayerService.GetPrimaryWeapon(player)
		item = ItemData.Items[name]
	end
	selected[player] = name
	return name, item
end

local function selectedShield(player)
	local name = selected[player]
	local item = name and ItemData.Items[name]
	if item and item.Kind == "Shield" and PlayerService.HasUnlock(player, name) then return item end
	return nil
end

local function flatDirection(root)
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then return Vector3.new(0, 0, -1) end
	return forward.Unit
end

local function candidatePosition(model, fallback)
	if model and model.PrimaryPart then return model.PrimaryPart.Position end
	return fallback and fallback.Position or nil
end

local function inCone(root, position, range)
	local delta = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z)
	if delta.Magnitude > range or delta.Magnitude < 0.05 then return false end
	return flatDirection(root):Dot(delta.Unit) >= CONE_DOT
end

local function applyGatherHatBonus(player, changes)
	if changes.Wood and changes.Wood > 0 then
		local multiplier = PlayerService.GetHatEffect(player, "WoodMultiplier", 1)
		changes.Wood = math.max(changes.Wood, math.floor(changes.Wood * multiplier + 0.5))
	end
	if changes.Stone and changes.Stone > 0 then
		local multiplier = PlayerService.GetHatEffect(player, "StoneMultiplier", 1)
		changes.Stone = math.max(changes.Stone, math.floor(changes.Stone * multiplier + 0.5))
	end
end

local function damagePlayer(attacker, victim, humanoid, weapon)
	local damage = weapon.PercentHealthDamage and humanoid.MaxHealth * weapon.PercentHealthDamage or (weapon.Damage or 0)
	damage *= PlayerService.GetHatEffect(attacker, "DamageMultiplier", 1)
	local shield = selectedShield(victim)
	if shield then damage *= 1 - math.clamp(shield.BlockPercent or 0, 0, 0.9) end
	damage = math.max(0, math.floor(damage + 0.5))
	if damage > 0 then humanoid:TakeDamage(damage) end
	if weapon.Knockback and weapon.Knockback > 0 then
		local aRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
		local vRoot = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if aRoot and vRoot then
			local delta = Vector3.new(vRoot.Position.X - aRoot.Position.X, 0, vRoot.Position.Z - aRoot.Position.Z)
			if delta.Magnitude > 0.05 then vRoot.AssemblyLinearVelocity += delta.Unit * weapon.Knockback end
		end
	end
	PlayerService.Add(attacker, { XP = 4 })
	return damage
end

local function damageBuild(player, model, weapon)
	local destroyed, salvage = BuildService.DamageBuild(player, model, weapon.BuildDamage or Config.BuildDamage)
	if destroyed and salvage then PlayerService.Add(player, salvage) end
	return true
end

local function gatherModel(player, model, part, weapon)
	local resourceType = model:GetAttribute("Resource")
	local success = false
	for _ = 1, math.max(1, weapon.GatherHits or 1) do
		local changes = WorldService.Gather(part)
		if not changes then break end
		applyGatherHatBonus(player, changes)
		PlayerService.Add(player, changes)
		success = true
	end
	if success and resourceType then
		local bonus = weapon.ResourceBonus or 0
		if resourceType == "Stone" then bonus += weapon.StoneBonus or 0 end
		if resourceType == "Wood" then bonus += weapon.WoodBonus or 0 end
		if bonus > 0 then PlayerService.Add(player, { [resourceType] = bonus }) end
	end
	return success
end

action.OnServerEvent:Connect(function(player, actionName, payload)
	if actionName == "SelectItem" and type(payload) == "string" and PlayerService.HasUnlock(player, payload) then
		selected[player] = payload
	elseif actionName == "ChooseUpgrade" and type(payload) == "string" then
		task.defer(function()
			if PlayerService.HasUnlock(player, payload) and ItemData.Items[payload] and ItemData.Items[payload].Category == "Weapon" then selected[player] = payload end
		end)
	end
end)

directional.OnServerEvent:Connect(function(player)
	local _, weapon = currentWeapon(player)
	if not weapon or weapon.Ranged or weapon.Kind == "Shield" then return end
	if weapon.CanAttack == false and weapon.CanGather == false then return end
	if not ready(player, weapon.Cooldown or Config.AttackCooldown) then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local range = math.max(weapon.Range or Config.AttackDistance, weapon.CanGather == false and 0 or Config.GatherDistance)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local parts = Workspace:GetPartBoundsInRadius(root.Position, range + 2, params)
	local seen = {}
	local hitCount = 0
	local gathered = 0
	local damaged = 0

	for _, part in parts do
		if hitCount >= MAX_TARGETS then break end
		if not part:IsA("BasePart") then continue end
		local model = part:FindFirstAncestorOfClass("Model")
		local key = model or part
		if seen[key] then continue end
		local pos = candidatePosition(model, part)
		if not pos or not inCone(root, pos, range) then continue end

		if CollectionService:HasTag(part, "SurvivalResource") and weapon.CanGather ~= false then
			seen[key] = true
			if model and model:GetAttribute("Alive") ~= false and gatherModel(player, model, part, weapon) then
				gathered += 1
				hitCount += 1
			end
		elseif CollectionService:HasTag(part, "PlayerBuild") and weapon.CanAttack ~= false then
			seen[key] = true
			if model and damageBuild(player, model, weapon) then damaged += 1 hitCount += 1 end
		else
			local targetHum = model and model:FindFirstChildOfClass("Humanoid")
			if targetHum and targetHum.Health > 0 and weapon.CanAttack ~= false then
				seen[key] = true
				local victim = Players:GetPlayerFromCharacter(model)
				if victim and victim ~= player then
					damagePlayer(player, victim, targetHum, weapon)
					damaged += 1
					hitCount += 1
				else
					local isMob, mobModel = MobService.IsMob(model)
					if isMob then
						local amount = weapon.PercentHealthDamage and targetHum.MaxHealth * weapon.PercentHealthDamage or (weapon.Damage or 0)
						amount *= PlayerService.GetHatEffect(player, "DamageMultiplier", 1)
						if amount > 0 then MobService.Damage(mobModel, player, math.floor(amount + 0.5)) end
						damaged += 1
						hitCount += 1
					end
				end
			end
		end
	end

	if hitCount > 0 then
		local pieces = {}
		if damaged > 0 then table.insert(pieces, `hit {damaged}`) end
		if gathered > 0 then table.insert(pieces, `gathered {gathered}`) end
		sendState(player, `Forward swing: {table.concat(pieces, " • ")}`, "Hit")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	selected[player] = nil
	cooldowns[player] = nil
end)
