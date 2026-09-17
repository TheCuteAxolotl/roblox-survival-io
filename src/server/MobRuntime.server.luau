local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local secondaryFire = remotes:WaitForChild("SecondaryFire")

local selected = {}
local cooldowns = {}

MobService.Init()

local function selectedWeapon(player)
	local itemName = selected[player]
	if not itemName or not PlayerService.HasUnlock(player, itemName) then
		itemName = PlayerService.GetPrimaryWeapon(player)
		selected[player] = itemName
	end
	return itemName, ItemData.Items[itemName]
end

local function ready(player, key, cooldown)
	local bucket = cooldowns[player] or {}
	cooldowns[player] = bucket
	local now = os.clock()
	if now - (bucket[key] or 0) < cooldown then return false end
	bucket[key] = now
	return true
end

local function damageFor(player, item, hum)
	local damage = item.PercentHealthDamage and hum.MaxHealth * item.PercentHealthDamage or (item.Damage or 0)
	local multiplier = PlayerService.GetHatEffect(player, "DamageMultiplier", 1)
	return math.max(0, math.floor(damage * multiplier + 0.5))
end

action.OnServerEvent:Connect(function(player, actionName, payload)
	if actionName == "SelectItem" and type(payload) == "string" and PlayerService.HasUnlock(player, payload) then
		selected[player] = payload
		return
	end
	if actionName == "ChooseUpgrade" and type(payload) == "string" then
		task.defer(function()
			if PlayerService.HasUnlock(player, payload) and ItemData.Items[payload] and ItemData.Items[payload].Category == "Weapon" then selected[player] = payload end
		end)
		return
	end
	if actionName ~= "Attack" or typeof(payload) ~= "Instance" or not payload:IsA("BasePart") then return end
	local isMob, model = MobService.IsMob(payload)
	if not isMob then return end
	local _, item = selectedWeapon(player)
	if not item or item.Ranged or item.Kind == "Shield" or item.CanAttack == false then return end
	if not ready(player, "Melee", item.Cooldown or Config.AttackCooldown) then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not root or not model.PrimaryPart or not hum or hum.Health <= 0 then return end
	if (root.Position - model.PrimaryPart.Position).Magnitude > (item.Range or Config.AttackDistance) then return end
	local damage = damageFor(player, item, hum)
	if damage > 0 then MobService.Damage(model, player, damage) end
end)

secondaryFire.OnServerEvent:Connect(function(player, aimPosition)
	if typeof(aimPosition) ~= "Vector3" then return end
	local itemName, item = selectedWeapon(player)
	if not item or not item.Ranged or not PlayerService.HasUnlock(player, itemName) then return end
	if not ready(player, `Ranged:{itemName}`, item.Cooldown or 0.8) then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	local origin = (head and head.Position or root.Position) + Vector3.new(0, 0.35, 0)
	local flatAim = Vector3.new(aimPosition.X, origin.Y, aimPosition.Z)
	local base = flatAim - origin
	if base.Magnitude < 0.1 then return end
	local baseDir = base.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	for _ = 1, math.max(1, item.ProjectileCount or 1) do
		local dir = baseDir
		if (item.Spread or 0) > 0 then
			local side = Vector3.new(-baseDir.Z, 0, baseDir.X)
			dir = (baseDir + side * ((math.random() * 2 - 1) * item.Spread)).Unit
		end
		local result = Workspace:Raycast(origin, dir * (item.Range or 80), params)
		if result then
			local isMob, model = MobService.IsMob(result.Instance)
			if isMob then
				local mobHum = model:FindFirstChildOfClass("Humanoid")
				if mobHum and mobHum.Health > 0 then
					local damage = damageFor(player, item, mobHum)
					if damage > 0 then MobService.Damage(model, player, damage) end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	selected[player] = nil
	cooldowns[player] = nil
end)
