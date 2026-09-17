local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local MobData = require(ReplicatedStorage.Shared.MobData)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local MobService = {}
local active = {}
local initialized = false

local function arena()
	return Workspace:FindFirstChild("SurvivalArena")
end

local function biomeXRange(biome)
	local half = Config.WorldSize / 2
	if biome == "Snow" then return -half + 45, -Config.BiomeSplit - 35 end
	if biome == "Desert" then return Config.BiomeSplit + 35, half - 45 end
	return -Config.BiomeSplit + 35, Config.BiomeSplit - 35
end

local function randomPoint(biome)
	local xMin, xMax = biomeXRange(biome)
	local half = Config.WorldSize / 2
	local margin = Config.RiverHalfWidth + 55
	local z = math.random() < 0.5 and math.random(math.floor(-half + 45), math.floor(-margin)) or math.random(math.floor(margin), math.floor(half - 45))
	return Vector3.new(math.random(math.floor(xMin), math.floor(xMax)), 3, z)
end

local function safePoint(biome)
	for _ = 1, 40 do
		local position = randomPoint(biome)
		local hits = Workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(8, 7, 8))
		local blocked = false
		for _, hit in hits do
			if CollectionService:HasTag(hit, "PlayerBuild") or CollectionService:HasTag(hit, "ResourceCore") then blocked = true break end
		end
		if not blocked then return position end
	end
	return randomPoint(biome)
end

local function weld(root, part)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = root
	weldConstraint.Part1 = part
	weldConstraint.Parent = part
end

local function makeBodyPart(model, root, name, size, offset, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.CFrame = root.CFrame * CFrame.new(offset)
	p.Parent = model
	weld(root, p)
	return p
end

local function nearestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then best = player bestDistance = distance end
		end
	end
	return best, bestDistance
end

local function dropLoot(model, mobName)
	local data = MobData.Mobs[mobName]
	if not data or not model.PrimaryPart then return end
	local origin = model.PrimaryPart.Position
	for _, drop in data.Drops or {} do
		if math.random() <= (drop.Chance or 1) then
			local amount = math.random(drop.Min or 1, drop.Max or drop.Min or 1)
			InventoryService.CreateWorldDrop(origin, drop.Item, amount)
		end
	end
	local attackerId = model:GetAttribute("LastAttackerUserId")
	local attacker = attackerId and Players:GetPlayerByUserId(attackerId)
	if attacker then PlayerService.Add(attacker, { XP = math.max(4, math.floor((data.Health or 50) / 10)), Gold = data.Hostile and 4 or 2 }) end
end

local function spawnMob(mobName)
	local data = MobData.Mobs[mobName]
	local world = arena()
	if not data or not world then return nil end
	local spawnPosition = safePoint(data.Biome)
	local model = Instance.new("Model")
	model.Name = mobName
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("MobType", mobName)
	model.Parent = world

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3.2, 2.4, 4.2)
	root.CFrame = CFrame.new(spawnPosition)
	root.Transparency = 1
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local bodyScale = mobName == "SnowBear" and 1.65 or (mobName == "Spider" or mobName == "Scorpion") and 0.7 or 1
	local body = makeBodyPart(model, root, "Body", Vector3.new(3.2, 2.2, 4.2) * bodyScale, Vector3.new(0, 0.4, 0), data.Color, Enum.Material.SmoothPlastic)
	body.CanCollide = false
	if mobName == "Spider" or mobName == "Scorpion" then
		body.Shape = Enum.PartType.Ball
		for side = -1, 1, 2 do
			for i = 1, 4 do
				local leg = makeBodyPart(model, root, `Leg{side}_{i}`, Vector3.new(2.3, 0.25, 0.25), Vector3.new(side * 1.6, 0.1, (i - 2.5) * 0.7), data.Color, Enum.Material.SmoothPlastic)
				leg.Orientation = Vector3.new(0, 0, side * 20)
			end
		end
	else
		makeBodyPart(model, root, "Head", Vector3.new(2.1, 2, 2.2) * bodyScale, Vector3.new(0, 0.75 * bodyScale, -2.2 * bodyScale), data.Color, Enum.Material.SmoothPlastic)
		for _, offset in { Vector3.new(-1, -1.2, -1.2), Vector3.new(1, -1.2, -1.2), Vector3.new(-1, -1.2, 1.3), Vector3.new(1, -1.2, 1.3) } do
			makeBodyPart(model, root, "Leg", Vector3.new(0.65, 2.4, 0.65) * bodyScale, offset * bodyScale, data.Color, Enum.Material.SmoothPlastic)
		end
	end

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = data.Health
	hum.Health = data.Health
	hum.WalkSpeed = data.WalkSpeed
	hum.JumpPower = 0
	hum.DisplayName = data.Label
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model

	active[model] = {
		Type = mobName,
		Data = data,
		Home = spawnPosition,
		LastAttack = 0,
		NextWander = 0,
		WanderTarget = spawnPosition,
	}

	hum.Died:Connect(function()
		local record = active[model]
		active[model] = nil
		dropLoot(model, mobName)
		task.delay(1.5, function() if model.Parent then model:Destroy() end end)
		task.delay(18, function() if initialized and arena() then spawnMob(mobName) end end)
	end)
	return model
end

function MobService.IsMob(instance)
	local model = instance
	if typeof(instance) == "Instance" and not instance:IsA("Model") then model = instance:FindFirstAncestorOfClass("Model") end
	return model and model:IsA("Model") and model:GetAttribute("SurvivalMob") == true, model
end

function MobService.Damage(model, attacker, damage)
	if not model or not model.Parent or model:GetAttribute("SurvivalMob") ~= true then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	model:SetAttribute("LastAttackerUserId", attacker and attacker.UserId or 0)
	hum:TakeDamage(math.max(0, damage or 0))
	return true
end

local function poisonPlayer(player, duration)
	local untilTime = os.clock() + duration
	player:SetAttribute("SurvivalPoisonUntil", math.max(player:GetAttribute("SurvivalPoisonUntil") or 0, untilTime))
end

local function tickMob(model, record, now)
	if not model.Parent or not model.PrimaryPart then active[model] = nil return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local data = record.Data

	if data.Hostile then
		local target, distance = nearestPlayer(model.PrimaryPart.Position, data.AggroRange or 50)
		if target then
			local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if targetRoot and targetHum and targetHum.Health > 0 then
				hum:MoveTo(targetRoot.Position)
				if distance <= (data.AttackRange or 4) and now - record.LastAttack >= (data.AttackCooldown or 1.2) then
					record.LastAttack = now
					targetHum:TakeDamage(data.Damage or 8)
					if data.PoisonChance and math.random() <= data.PoisonChance then poisonPlayer(target, 6) end
				end
				return
			end
		end
	end

	if now >= record.NextWander then
		record.NextWander = now + math.random(3, 7)
		local angle = math.random() * math.pi * 2
		local radius = math.random(12, 34)
		record.WanderTarget = record.Home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	end
	hum:MoveTo(record.WanderTarget)
end

function MobService.Init()
	if initialized then return end
	initialized = true
	local world = Workspace:WaitForChild("SurvivalArena", 15)
	if not world then warn("[MobService] SurvivalArena not found; mobs were not spawned.") return end
	for mobName, data in MobData.Mobs do
		for _ = 1, data.Count or 1 do spawnMob(mobName) end
	end

	task.spawn(function()
		while initialized do
			task.wait(0.45)
			local now = os.clock()
			for model, record in active do tickMob(model, record, now) end
		end
	end)
end

return MobService
