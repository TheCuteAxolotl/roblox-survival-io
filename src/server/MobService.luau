local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
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

local FOREST_CENTER = Vector3.new(0, 0, 365)
local FOREST_HALF_X = 150
local FOREST_HALF_Z = 125

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
	if biome == "Forest" then
		return Vector3.new(
			math.random(math.floor(FOREST_CENTER.X - FOREST_HALF_X), math.floor(FOREST_CENTER.X + FOREST_HALF_X)),
			3,
			math.random(math.floor(FOREST_CENTER.Z - FOREST_HALF_Z), math.floor(FOREST_CENTER.Z + FOREST_HALF_Z))
		)
	end
	local xMin, xMax = biomeXRange(biome)
	local half = Config.WorldSize / 2
	local margin = Config.RiverHalfWidth + 55
	local z = math.random() < 0.5 and math.random(math.floor(-half + 45), math.floor(-margin)) or math.random(math.floor(margin), math.floor(half - 45))
	return Vector3.new(math.random(math.floor(xMin), math.floor(xMax)), 3, z)
end

local function safePoint(biome)
	for _ = 1, 50 do
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

local function visualPart(model, root, name, size, relativeCf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = root.CFrame * relativeCf
	if shape then p.Shape = shape end
	p.Parent = model
	weld(root, p)
	return p
end

local function ellipsoid(model, root, name, size, relativeCf, color, material)
	local p = visualPart(model, root, name, size, relativeCf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = p
	return p
end

local function wedge(model, root, name, size, relativeCf, color, material)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = root.CFrame * relativeCf
	p.Parent = model
	weld(root, p)
	return p
end

local function cylinder(model, root, name, length, thickness, relativeCf, color, material)
	return visualPart(model, root, name, Vector3.new(length, thickness, thickness), relativeCf, color, material, Enum.PartType.Cylinder)
end

local function addEyes(model, root, x, y, z, scale, color)
	for _, side in { -1, 1 } do
		ellipsoid(model, root, "Eye", Vector3.new(0.30, 0.30, 0.18) * scale, CFrame.new(side * x * scale, y * scale, z * scale), color or Color3.fromRGB(24, 24, 26), Enum.Material.Neon)
	end
end

local function addFourLegs(model, root, scale, color, positions, thickness, length)
	local legThickness = thickness or 0.55
	local legLength = length or 2.2
	for i, offset in positions do
		cylinder(
			model,
			root,
			`Leg{i}`,
			legLength * scale,
			legThickness * scale,
			CFrame.new(offset.X * scale, offset.Y * scale, offset.Z * scale) * CFrame.Angles(0, 0, math.rad(90)),
			color
		)
	end
end

local function buildCanine(model, root, color, scale, isDire)
	local dark = color:Lerp(Color3.new(0, 0, 0), isDire and 0.28 or 0.18)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.16)
	ellipsoid(model, root, "Body", Vector3.new(3.2, 2.25, 5.0) * scale, CFrame.new(0, 0.45 * scale, 0), color)
	ellipsoid(model, root, "Chest", Vector3.new(3.0, 2.8, 2.7) * scale, CFrame.new(0, 0.72 * scale, -1.35 * scale), light)
	ellipsoid(model, root, "Head", Vector3.new(2.4, 2.15, 2.55) * scale, CFrame.new(0, 1.15 * scale, -3.0 * scale), color)
	ellipsoid(model, root, "Muzzle", Vector3.new(1.45, 1.0, 1.75) * scale, CFrame.new(0, 0.78 * scale, -4.35 * scale), light)
	ellipsoid(model, root, "Nose", Vector3.new(0.72, 0.52, 0.42) * scale, CFrame.new(0, 0.86 * scale, -5.12 * scale), Color3.fromRGB(24, 24, 27))
	addEyes(model, root, 0.72, 1.55, -4.0, scale, isDire and Color3.fromRGB(244, 184, 72) or Color3.fromRGB(34, 34, 36))
	for _, side in { -1, 1 } do
		wedge(model, root, "Ear", Vector3.new(0.85, 1.35, 0.65) * scale, CFrame.new(side * 0.8 * scale, 2.45 * scale, -3.0 * scale) * CFrame.Angles(0, math.rad(side * 8), math.rad(side * 8)), dark)
	end
	addFourLegs(model, root, scale, dark, {
		Vector3.new(-1.0, -0.8, -1.55), Vector3.new(1.0, -0.8, -1.55),
		Vector3.new(-1.0, -0.8, 1.55), Vector3.new(1.0, -0.8, 1.55),
	}, 0.5, 2.35)
	cylinder(model, root, "TailA", 2.4 * scale, 0.55 * scale, CFrame.new(0, 0.95 * scale, 3.05 * scale) * CFrame.Angles(0, math.rad(68), math.rad(-8)), dark)
	cylinder(model, root, "TailB", 1.65 * scale, 0.42 * scale, CFrame.new(0.85 * scale, 1.25 * scale, 4.0 * scale) * CFrame.Angles(0, math.rad(52), math.rad(-10)), dark)
end

local function buildDeer(model, root, color, scale)
	local cream = Color3.fromRGB(221, 191, 151)
	local antler = Color3.fromRGB(99, 73, 50)
	ellipsoid(model, root, "Body", Vector3.new(3.0, 2.2, 4.8) * scale, CFrame.new(0, 0.55 * scale, 0.25 * scale), color)
	cylinder(model, root, "Neck", 2.9 * scale, 1.15 * scale, CFrame.new(0, 1.55 * scale, -2.0 * scale) * CFrame.Angles(0, 0, math.rad(64)), color)
	ellipsoid(model, root, "Head", Vector3.new(1.85, 1.8, 2.45) * scale, CFrame.new(0, 2.55 * scale, -3.0 * scale), color)
	ellipsoid(model, root, "Muzzle", Vector3.new(1.25, 0.9, 1.35) * scale, CFrame.new(0, 2.15 * scale, -4.25 * scale), cream)
	addEyes(model, root, 0.55, 2.88, -3.85, scale)
	for _, side in { -1, 1 } do
		wedge(model, root, "Ear", Vector3.new(0.75, 1.3, 0.5) * scale, CFrame.new(side * 0.9 * scale, 3.55 * scale, -3.0 * scale) * CFrame.Angles(0, math.rad(side * 28), math.rad(side * 22)), color)
		cylinder(model, root, "AntlerStem", 2.0 * scale, 0.24 * scale, CFrame.new(side * 0.55 * scale, 4.2 * scale, -2.8 * scale) * CFrame.Angles(0, 0, math.rad(68)), antler)
		cylinder(model, root, "AntlerBranch", 1.25 * scale, 0.18 * scale, CFrame.new(side * 0.95 * scale, 4.7 * scale, -2.55 * scale) * CFrame.Angles(math.rad(24), 0, math.rad(side * 38)), antler)
	end
	addFourLegs(model, root, scale, color:Lerp(Color3.new(0, 0, 0), 0.08), {
		Vector3.new(-0.9, -0.85, -1.45), Vector3.new(0.9, -0.85, -1.45),
		Vector3.new(-0.9, -0.85, 1.55), Vector3.new(0.9, -0.85, 1.55),
	}, 0.38, 2.8)
	ellipsoid(model, root, "Tail", Vector3.new(0.7, 0.9, 1.0) * scale, CFrame.new(0, 1.0 * scale, 2.85 * scale) * CFrame.Angles(math.rad(-22), 0, 0), cream)
end

local function buildCattle(model, root, color, scale)
	local muzzle = Color3.fromRGB(196, 166, 137)
	local horn = Color3.fromRGB(226, 215, 181)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.16)
	ellipsoid(model, root, "Body", Vector3.new(4.2, 3.2, 5.8) * scale, CFrame.new(0, 0.7 * scale, 0.3 * scale), color)
	ellipsoid(model, root, "Shoulders", Vector3.new(4.1, 3.5, 3.0) * scale, CFrame.new(0, 0.9 * scale, -1.5 * scale), dark)
	ellipsoid(model, root, "Head", Vector3.new(3.0, 2.5, 2.8) * scale, CFrame.new(0, 1.45 * scale, -3.3 * scale), color)
	ellipsoid(model, root, "Muzzle", Vector3.new(2.2, 1.35, 1.45) * scale, CFrame.new(0, 0.95 * scale, -4.7 * scale), muzzle)
	addEyes(model, root, 0.92, 1.82, -4.05, scale)
	for _, side in { -1, 1 } do
		cylinder(model, root, "Horn", 1.8 * scale, 0.30 * scale, CFrame.new(side * 1.55 * scale, 2.6 * scale, -3.15 * scale) * CFrame.Angles(0, math.rad(side * 10), math.rad(side * 18)), horn)
		wedge(model, root, "Ear", Vector3.new(1.0, 0.65, 0.8) * scale, CFrame.new(side * 1.65 * scale, 2.15 * scale, -3.4 * scale) * CFrame.Angles(0, math.rad(side * 25), 0), color)
	end
	addFourLegs(model, root, scale, dark, {
		Vector3.new(-1.35, -1.0, -1.75), Vector3.new(1.35, -1.0, -1.75),
		Vector3.new(-1.35, -1.0, 1.85), Vector3.new(1.35, -1.0, 1.85),
	}, 0.72, 2.7)
	cylinder(model, root, "Tail", 2.5 * scale, 0.26 * scale, CFrame.new(0, 0.9 * scale, 3.65 * scale) * CFrame.Angles(0, math.rad(90), math.rad(18)), dark)
	ellipsoid(model, root, "TailTuft", Vector3.new(0.65, 0.65, 0.8) * scale, CFrame.new(1.05 * scale, 0.45 * scale, 4.0 * scale), dark)
end

local function buildBoar(model, root, color, scale)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.2)
	local tusk = Color3.fromRGB(235, 224, 194)
	ellipsoid(model, root, "Body", Vector3.new(3.8, 2.8, 5.2) * scale, CFrame.new(0, 0.25 * scale, 0.3 * scale), color)
	ellipsoid(model, root, "Shoulders", Vector3.new(3.8, 3.1, 2.9) * scale, CFrame.new(0, 0.45 * scale, -1.5 * scale), dark)
	ellipsoid(model, root, "Head", Vector3.new(2.7, 2.2, 2.7) * scale, CFrame.new(0, 0.65 * scale, -3.0 * scale), color)
	ellipsoid(model, root, "Snout", Vector3.new(1.9, 1.2, 1.45) * scale, CFrame.new(0, 0.25 * scale, -4.45 * scale), Color3.fromRGB(116, 79, 68))
	ellipsoid(model, root, "Nose", Vector3.new(1.35, 0.8, 0.38) * scale, CFrame.new(0, 0.28 * scale, -5.15 * scale), Color3.fromRGB(50, 43, 42))
	addEyes(model, root, 0.75, 1.0, -3.9, scale)
	for _, side in { -1, 1 } do
		wedge(model, root, "Ear", Vector3.new(0.85, 1.0, 0.65) * scale, CFrame.new(side * 0.9 * scale, 1.7 * scale, -2.9 * scale) * CFrame.Angles(0, 0, math.rad(side * 18)), dark)
		wedge(model, root, "Tusk", Vector3.new(0.35, 0.9, 0.45) * scale, CFrame.new(side * 0.85 * scale, 0.0, -4.8 * scale) * CFrame.Angles(math.rad(-25), 0, math.rad(side * 16)), tusk)
	end
	addFourLegs(model, root, scale, dark, {
		Vector3.new(-1.1, -1.05, -1.35), Vector3.new(1.1, -1.05, -1.35),
		Vector3.new(-1.1, -1.05, 1.45), Vector3.new(1.1, -1.05, 1.45),
	}, 0.62, 1.9)
end

local function buildBear(model, root, color, scale)
	local muzzle = color:Lerp(Color3.new(1, 1, 1), 0.18)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.18)
	ellipsoid(model, root, "Body", Vector3.new(4.6, 3.8, 5.5) * scale, CFrame.new(0, 0.65 * scale, 0.4 * scale), color)
	ellipsoid(model, root, "Chest", Vector3.new(4.3, 4.1, 3.2) * scale, CFrame.new(0, 0.9 * scale, -1.5 * scale), color)
	ellipsoid(model, root, "Head", Vector3.new(3.2, 3.0, 3.1) * scale, CFrame.new(0, 1.75 * scale, -3.15 * scale), color)
	ellipsoid(model, root, "Muzzle", Vector3.new(1.8, 1.2, 1.5) * scale, CFrame.new(0, 1.25 * scale, -4.65 * scale), muzzle)
	ellipsoid(model, root, "Nose", Vector3.new(0.9, 0.58, 0.42) * scale, CFrame.new(0, 1.38 * scale, -5.35 * scale), Color3.fromRGB(28, 28, 29))
	addEyes(model, root, 0.85, 2.25, -4.15, scale)
	for _, side in { -1, 1 } do
		ellipsoid(model, root, "Ear", Vector3.new(0.95, 0.95, 0.55) * scale, CFrame.new(side * 1.05 * scale, 3.15 * scale, -3.0 * scale), dark)
	end
	addFourLegs(model, root, scale, dark, {
		Vector3.new(-1.35, -1.0, -1.4), Vector3.new(1.35, -1.0, -1.4),
		Vector3.new(-1.35, -1.0, 1.7), Vector3.new(1.35, -1.0, 1.7),
	}, 0.85, 2.25)
	ellipsoid(model, root, "Tail", Vector3.new(0.9, 0.9, 0.9) * scale, CFrame.new(0, 1.0 * scale, 3.35 * scale), dark)
end

local function buildSpider(model, root, color, scale, brood)
	local abdomenColor = color:Lerp(Color3.new(0, 0, 0), brood and 0.12 or 0.06)
	ellipsoid(model, root, "Abdomen", Vector3.new(3.2, 1.8, 3.8) * scale, CFrame.new(0, 0.3 * scale, 1.3 * scale), abdomenColor)
	ellipsoid(model, root, "Thorax", Vector3.new(2.3, 1.5, 2.4) * scale, CFrame.new(0, 0.2 * scale, -1.2 * scale), color)
	ellipsoid(model, root, "Head", Vector3.new(1.65, 1.1, 1.5) * scale, CFrame.new(0, 0.15 * scale, -2.6 * scale), color)
	for _, side in { -1, 1 } do
		for i = 1, 4 do
			local z = (i - 2.5) * 0.9
			local angle = math.rad(side * (18 + (i - 1) * 8))
			cylinder(model, root, "LegUpper", 2.3 * scale, 0.26 * scale, CFrame.new(side * 1.7 * scale, 0.05, z * scale) * CFrame.Angles(0, angle, 0), color)
			cylinder(model, root, "LegLower", 2.0 * scale, 0.22 * scale, CFrame.new(side * 3.05 * scale, -0.4 * scale, (z + (i - 2.5) * 0.25) * scale) * CFrame.Angles(0, angle, math.rad(side * 18)), color)
		end
	end
	for _, side in { -1, 1 } do
		for row = 0, 1 do
			ellipsoid(model, root, "Eye", Vector3.new(0.28, 0.28, 0.2) * scale, CFrame.new(side * (0.32 + row * 0.28) * scale, (0.42 - row * 0.18) * scale, -3.34 * scale), brood and Color3.fromRGB(129, 238, 174) or Color3.fromRGB(226, 72, 72), Enum.Material.Neon)
		end
	end
end

local function buildScorpion(model, root, color, scale)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.2)
	ellipsoid(model, root, "Body", Vector3.new(2.5, 1.35, 3.5) * scale, CFrame.new(0, 0.15 * scale, 0.2 * scale), color)
	ellipsoid(model, root, "Head", Vector3.new(2.1, 1.1, 1.8) * scale, CFrame.new(0, 0.1 * scale, -2.2 * scale), dark)
	for _, side in { -1, 1 } do
		for i = 1, 4 do
			local z = (i - 2.4) * 0.72
			cylinder(model, root, "Leg", 1.8 * scale, 0.22 * scale, CFrame.new(side * 1.55 * scale, -0.2 * scale, z * scale) * CFrame.Angles(0, math.rad(side * (20 + i * 7)), math.rad(side * 10)), color)
		end
		cylinder(model, root, "ClawArm", 2.0 * scale, 0.34 * scale, CFrame.new(side * 1.55 * scale, 0.15 * scale, -2.25 * scale) * CFrame.Angles(0, math.rad(side * 34), 0), dark)
		ellipsoid(model, root, "Claw", Vector3.new(1.2, 0.7, 1.5) * scale, CFrame.new(side * 2.55 * scale, 0.1 * scale, -3.0 * scale), color)
	end
	for i = 1, 4 do
		ellipsoid(model, root, "TailSegment", Vector3.new(0.85, 0.85, 1.15) * scale, CFrame.new(0, (0.45 + i * 0.55) * scale, (2.0 + i * 0.72) * scale) * CFrame.Angles(math.rad(12 * i), 0, 0), dark)
	end
	wedge(model, root, "Stinger", Vector3.new(0.7, 1.3, 0.8) * scale, CFrame.new(0, 3.1 * scale, 5.05 * scale) * CFrame.Angles(math.rad(125), 0, 0), Color3.fromRGB(60, 48, 39))
	addEyes(model, root, 0.45, 0.42, -3.0, scale, Color3.fromRGB(246, 165, 63))
end

local function buildMobVisual(model, root, mobName, data)
	local scale = data.Scale or 1
	local color = data.Color
	if mobName == "Wolf" or mobName == "SnowWolf" or mobName == "DireWolf" then
		buildCanine(model, root, color, scale, mobName == "DireWolf")
	elseif mobName == "Deer" then
		buildDeer(model, root, color, scale)
	elseif mobName == "WildCattle" then
		buildCattle(model, root, color, scale)
	elseif mobName == "Boar" then
		buildBoar(model, root, color, scale)
	elseif mobName == "SnowBear" or mobName == "ForestBear" then
		buildBear(model, root, color, scale)
	elseif data.Archetype == "Spider" then
		buildSpider(model, root, color, scale, mobName == "BroodSpider")
	elseif data.Archetype == "Scorpion" then
		buildScorpion(model, root, color, scale)
	else
		buildCanine(model, root, color, scale, false)
	end
	model:SetAttribute("VisualStyle", "LowPolyAnimalV2")
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
	if attacker then
		PlayerService.Add(attacker, {
			XP = data.XPReward or math.max(4, math.floor((data.Health or 50) / 10)),
			Gold = data.GoldReward or (data.Hostile and 4 or 2),
		})
	end
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
	model:SetAttribute("MobBiome", data.Biome)
	model:SetAttribute("NightOnly", data.NightOnly == true)
	model.Parent = world

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3.2, 2.4, 4.2) * math.max(1, data.Scale or 1)
	root.CFrame = CFrame.new(spawnPosition)
	root.Transparency = 1
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root
	pcall(function() root:SetNetworkOwner(nil) end)

	buildMobVisual(model, root, mobName, data)

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
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
		active[model] = nil
		dropLoot(model, mobName)
		task.delay(1.5, function() if model.Parent then model:Destroy() end end)
		task.delay(data.RespawnSeconds or 18, function() if initialized and arena() then spawnMob(mobName) end end)
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

local function incomingDamage(player, baseDamage)
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(1, math.floor((baseDamage or 0) * (1 - reduction) + 0.5))
end

local function isNight()
	local hour = Lighting.ClockTime
	return hour >= 19 or hour < 6
end

local function tickMob(model, record, now)
	if not model.Parent or not model.PrimaryPart then active[model] = nil return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local data = record.Data
	local aggressiveNow = data.Hostile and (not data.NightOnly or isNight())

	if aggressiveNow then
		local target, distance = nearestPlayer(model.PrimaryPart.Position, data.AggroRange or 50)
		if target then
			local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if targetRoot and targetHum and targetHum.Health > 0 then
				hum:MoveTo(targetRoot.Position)
				if distance <= (data.AttackRange or 4) and now - record.LastAttack >= (data.AttackCooldown or 1.2) then
					record.LastAttack = now
					targetHum:TakeDamage(incomingDamage(target, data.Damage or 8))
					if data.PoisonChance and math.random() <= data.PoisonChance then poisonPlayer(target, 6) end
				end
				return
			end
		end
	end

	if now >= record.NextWander then
		record.NextWander = now + math.random(3, 7)
		local angle = math.random() * math.pi * 2
		local radius = math.random(12, data.Biome == "Forest" and 26 or 34)
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
