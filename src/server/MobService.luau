local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local MobData = require(ReplicatedStorage.Shared.MobData)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)

local MobService = {}
local active = {}
local initialized = false

local FOREST_CENTER = Vector3.new(0, 0, 365)
local HAVEN_CENTER = Vector3.new(0, 0, -155)
local HAVEN_SAFE_RADIUS = 125
local FOREST_HALF_X = 150
local FOREST_HALF_Z = 125

local SPECIAL_REGIONS = {
	Highlands = { Center = Vector3.new(-980, 0, 850), HalfX = 210, HalfZ = 180 },
	Dunes = { Center = Vector3.new(980, 0, 850), HalfX = 210, HalfZ = 180 },
	Marsh = { Center = Vector3.new(-980, 0, -850), HalfX = 210, HalfZ = 180 },
	Grove = { Center = Vector3.new(980, 0, -850), HalfX = 210, HalfZ = 180 },
	Crystal = { Center = Vector3.new(0, 0, 980), HalfX = 150, HalfZ = 120 },
}

local function arena()
	return Workspace:FindFirstChild("SurvivalArena")
end

local function worldPhase()
	return ReplicatedStorage:GetAttribute("WildforgePhase") or "Day"
end

local function threatLevel()
	return math.clamp(ReplicatedStorage:GetAttribute("WildforgeThreat") or 1, 1, (Config.WorldCycle and Config.WorldCycle.MaxThreat) or 6)
end

local function isBloodMoon()
	return ReplicatedStorage:GetAttribute("WildforgeEvent") == "BLOOD MOON"
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
	local special = SPECIAL_REGIONS[biome]
	if special then
		return Vector3.new(
			math.random(math.floor(special.Center.X - special.HalfX), math.floor(special.Center.X + special.HalfX)),
			3,
			math.random(math.floor(special.Center.Z - special.HalfZ), math.floor(special.Center.Z + special.HalfZ))
		)
	end
	local xMin, xMax = biomeXRange(biome)
	local half = Config.WorldSize / 2
	local margin = Config.RiverHalfWidth + 55
	local z = math.random() < 0.5
		and math.random(math.floor(-half + 45), math.floor(-margin))
		or math.random(math.floor(margin), math.floor(half - 45))
	return Vector3.new(math.random(math.floor(xMin), math.floor(xMax)), 3, z)
end

local function safePoint(biome)
	for _ = 1, 50 do
		local position = randomPoint(biome)
		local flat = Vector3.new(position.X, 0, position.Z)
		local blocked = (flat - HAVEN_CENTER).Magnitude < HAVEN_SAFE_RADIUS
		local hits = Workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(9, 8, 9))
		for _, hit in hits do
			if CollectionService:HasTag(hit, "PlayerBuild") or CollectionService:HasTag(hit, "ResourceCore") then
				blocked = true
				break
			end
		end
		if not blocked then return position end
	end
	return randomPoint(biome)
end

local function weld(root, part)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = part
	w.Parent = part
end

local function part(model, root, name, size, cf, color, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = root.CFrame * cf
	if shape then p.Shape = shape end
	p.Parent = model
	weld(root, p)
	return p
end

local function oval(model, root, name, size, cf, color, material)
	local p = part(model, root, name, size, cf, color, nil, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function wedge(model, root, name, size, cf, color)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = model
	weld(root, p)
	return p
end

local function cylinder(model, root, name, length, thickness, cf, color)
	return part(model, root, name, Vector3.new(length, thickness, thickness), cf, color, Enum.PartType.Cylinder)
end

local function eyes(model, root, x, y, z, scale, glow)
	for _, side in { -1, 1 } do
		oval(model, root, "Eye", Vector3.new(0.3, 0.3, 0.18) * scale, CFrame.new(side * x * scale, y * scale, z * scale), glow or Color3.fromRGB(25, 25, 27), Enum.Material.Neon)
	end
end

local function fourLegs(model, root, scale, color, frontZ, backZ, spread, length, thickness)
	for _, x in { -spread, spread } do
		for _, z in { frontZ, backZ } do
			cylinder(model, root, "Leg", length * scale, thickness * scale, CFrame.new(x * scale, -0.9 * scale, z * scale) * CFrame.Angles(0, 0, math.rad(90)), color)
		end
	end
end

local function canine(model, root, data, dire)
	local s, c = data.Scale or 1, data.Color
	local dark = c:Lerp(Color3.new(0, 0, 0), dire and 0.3 or 0.18)
	local light = c:Lerp(Color3.new(1, 1, 1), 0.17)
	oval(model, root, "Body", Vector3.new(3.2, 2.2, 5.1) * s, CFrame.new(0, 0.45 * s, 0), c)
	oval(model, root, "Chest", Vector3.new(3.0, 2.7, 2.8) * s, CFrame.new(0, 0.7 * s, -1.35 * s), light)
	oval(model, root, "Head", Vector3.new(2.35, 2.05, 2.5) * s, CFrame.new(0, 1.2 * s, -3.05 * s), c)
	oval(model, root, "Muzzle", Vector3.new(1.45, 0.95, 1.75) * s, CFrame.new(0, 0.82 * s, -4.35 * s), light)
	oval(model, root, "Nose", Vector3.new(0.7, 0.48, 0.4) * s, CFrame.new(0, 0.88 * s, -5.12 * s), Color3.fromRGB(24, 24, 27))
	eyes(model, root, 0.7, 1.58, -3.95, s, dire and Color3.fromRGB(247, 184, 70) or nil)
	for _, side in { -1, 1 } do
		wedge(model, root, "Ear", Vector3.new(0.85, 1.4, 0.7) * s, CFrame.new(side * 0.82 * s, 2.45 * s, -3.0 * s) * CFrame.Angles(0, math.rad(side * 8), math.rad(side * 8)), dark)
	end
	fourLegs(model, root, s, dark, -1.55, 1.55, 1.0, 2.35, 0.5)
	cylinder(model, root, "Tail", 3.0 * s, 0.5 * s, CFrame.new(0, 1.0 * s, 3.2 * s) * CFrame.Angles(0, math.rad(70), math.rad(-8)), dark)
end

local function deer(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local cream, antler = Color3.fromRGB(221, 191, 151), Color3.fromRGB(99, 73, 50)
	oval(model, root, "Body", Vector3.new(3.0, 2.1, 4.8) * s, CFrame.new(0, 0.55 * s, 0.2 * s), c)
	cylinder(model, root, "Neck", 2.9 * s, 1.1 * s, CFrame.new(0, 1.6 * s, -2.0 * s) * CFrame.Angles(0, 0, math.rad(64)), c)
	oval(model, root, "Head", Vector3.new(1.8, 1.75, 2.4) * s, CFrame.new(0, 2.55 * s, -3.05 * s), c)
	oval(model, root, "Muzzle", Vector3.new(1.2, 0.85, 1.35) * s, CFrame.new(0, 2.15 * s, -4.2 * s), cream)
	eyes(model, root, 0.52, 2.88, -3.8, s)
	for _, side in { -1, 1 } do
		wedge(model, root, "Ear", Vector3.new(0.72, 1.3, 0.5) * s, CFrame.new(side * 0.88 * s, 3.52 * s, -3.0 * s) * CFrame.Angles(0, math.rad(side * 25), math.rad(side * 20)), c)
		cylinder(model, root, "Antler", 2.1 * s, 0.22 * s, CFrame.new(side * 0.58 * s, 4.15 * s, -2.8 * s) * CFrame.Angles(0, 0, math.rad(68)), antler)
	end
	fourLegs(model, root, s, c:Lerp(Color3.new(0, 0, 0), 0.08), -1.4, 1.55, 0.88, 2.8, 0.38)
	oval(model, root, "Tail", Vector3.new(0.7, 0.9, 1.0) * s, CFrame.new(0, 1.0 * s, 2.85 * s), cream)
end

local function boar(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark, ivory = c:Lerp(Color3.new(0, 0, 0), 0.22), Color3.fromRGB(235, 224, 194)
	oval(model, root, "Body", Vector3.new(3.8, 2.8, 5.2) * s, CFrame.new(0, 0.3 * s, 0.3 * s), c)
	oval(model, root, "Shoulders", Vector3.new(3.8, 3.15, 2.9) * s, CFrame.new(0, 0.5 * s, -1.5 * s), dark)
	oval(model, root, "Head", Vector3.new(2.7, 2.2, 2.7) * s, CFrame.new(0, 0.7 * s, -3.0 * s), c)
	oval(model, root, "Snout", Vector3.new(1.9, 1.15, 1.45) * s, CFrame.new(0, 0.25 * s, -4.45 * s), Color3.fromRGB(116, 79, 68))
	eyes(model, root, 0.72, 1.05, -3.9, s)
	for _, side in { -1, 1 } do
		wedge(model, root, "Tusk", Vector3.new(0.35, 0.9, 0.45) * s, CFrame.new(side * 0.82 * s, 0, -4.8 * s) * CFrame.Angles(math.rad(-25), 0, math.rad(side * 16)), ivory)
	end
	fourLegs(model, root, s, dark, -1.3, 1.4, 1.08, 1.9, 0.62)
end

local function cattle(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark, muzzle, horn = c:Lerp(Color3.new(0, 0, 0), 0.16), Color3.fromRGB(196, 166, 137), Color3.fromRGB(226, 215, 181)
	oval(model, root, "Body", Vector3.new(4.2, 3.2, 5.8) * s, CFrame.new(0, 0.72 * s, 0.3 * s), c)
	oval(model, root, "Head", Vector3.new(3.0, 2.45, 2.8) * s, CFrame.new(0, 1.45 * s, -3.35 * s), c)
	oval(model, root, "Muzzle", Vector3.new(2.2, 1.3, 1.45) * s, CFrame.new(0, 0.95 * s, -4.7 * s), muzzle)
	eyes(model, root, 0.9, 1.82, -4.05, s)
	for _, side in { -1, 1 } do
		cylinder(model, root, "Horn", 1.8 * s, 0.3 * s, CFrame.new(side * 1.55 * s, 2.55 * s, -3.15 * s) * CFrame.Angles(0, 0, math.rad(side * 18)), horn)
	end
	fourLegs(model, root, s, dark, -1.7, 1.85, 1.32, 2.7, 0.72)
	cylinder(model, root, "Tail", 2.4 * s, 0.25 * s, CFrame.new(0, 1.0 * s, 3.65 * s) * CFrame.Angles(0, math.rad(90), math.rad(16)), dark)
end

local function bear(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark, muzzle = c:Lerp(Color3.new(0, 0, 0), 0.18), c:Lerp(Color3.new(1, 1, 1), 0.18)
	oval(model, root, "Body", Vector3.new(4.6, 3.8, 5.5) * s, CFrame.new(0, 0.7 * s, 0.35 * s), c)
	oval(model, root, "Head", Vector3.new(3.2, 3.0, 3.1) * s, CFrame.new(0, 1.75 * s, -3.15 * s), c)
	oval(model, root, "Muzzle", Vector3.new(1.8, 1.2, 1.5) * s, CFrame.new(0, 1.25 * s, -4.65 * s), muzzle)
	oval(model, root, "Nose", Vector3.new(0.9, 0.56, 0.42) * s, CFrame.new(0, 1.38 * s, -5.35 * s), Color3.fromRGB(28, 28, 29))
	eyes(model, root, 0.82, 2.25, -4.1, s)
	for _, side in { -1, 1 } do oval(model, root, "Ear", Vector3.new(0.95, 0.95, 0.55) * s, CFrame.new(side * 1.05 * s, 3.12 * s, -3.0 * s), dark) end
	fourLegs(model, root, s, dark, -1.35, 1.7, 1.3, 2.25, 0.85)
	oval(model, root, "Tail", Vector3.new(0.9, 0.9, 0.9) * s, CFrame.new(0, 1.0 * s, 3.35 * s), dark)
end

local function spider(model, root, data, brood)
	local s, c = data.Scale or 1, data.Color
	oval(model, root, "Abdomen", Vector3.new(3.2, 1.8, 3.8) * s, CFrame.new(0, 0.3 * s, 1.3 * s), c:Lerp(Color3.new(0, 0, 0), 0.12))
	oval(model, root, "Thorax", Vector3.new(2.3, 1.5, 2.4) * s, CFrame.new(0, 0.2 * s, -1.2 * s), c)
	oval(model, root, "Head", Vector3.new(1.65, 1.1, 1.5) * s, CFrame.new(0, 0.15 * s, -2.6 * s), c)
	for _, side in { -1, 1 } do
		for i = 1, 4 do
			local z = (i - 2.5) * 0.9
			cylinder(model, root, "Leg", 3.5 * s, 0.22 * s, CFrame.new(side * 2.0 * s, -0.15 * s, z * s) * CFrame.Angles(0, math.rad(side * (18 + i * 7)), math.rad(side * 12)), c)
		end
	end
	eyes(model, root, 0.4, 0.42, -3.25, s, brood and Color3.fromRGB(129, 238, 174) or Color3.fromRGB(226, 72, 72))
end

local function scorpion(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.2)
	oval(model, root, "Body", Vector3.new(2.5, 1.35, 3.5) * s, CFrame.new(0, 0.15 * s, 0.2 * s), c)
	oval(model, root, "Head", Vector3.new(2.1, 1.1, 1.8) * s, CFrame.new(0, 0.1 * s, -2.2 * s), dark)
	for _, side in { -1, 1 } do
		for i = 1, 4 do
			cylinder(model, root, "Leg", 2.0 * s, 0.22 * s, CFrame.new(side * 1.7 * s, -0.2 * s, (i - 2.4) * 0.72 * s) * CFrame.Angles(0, math.rad(side * (20 + i * 7)), math.rad(side * 10)), c)
		end
		oval(model, root, "Claw", Vector3.new(1.2, 0.7, 1.5) * s, CFrame.new(side * 2.5 * s, 0.1 * s, -3.0 * s), c)
	end
	for i = 1, 4 do oval(model, root, "Tail", Vector3.new(0.85, 0.85, 1.15) * s, CFrame.new(0, (0.45 + i * 0.55) * s, (2.0 + i * 0.72) * s), dark) end
	wedge(model, root, "Stinger", Vector3.new(0.7, 1.3, 0.8) * s, CFrame.new(0, 3.1 * s, 5.0 * s) * CFrame.Angles(math.rad(125), 0, 0), dark)
end

local function golem(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark = c:Lerp(Color3.new(0,0,0), 0.22)
	local glow = c:Lerp(Color3.fromRGB(108, 202, 255), 0.55)
	local torso = part(model, root, "StoneTorso", Vector3.new(4.4, 4.8, 3.6) * s, CFrame.new(0, 1.0 * s, 0), c, nil, Enum.Material.Slate)
	local head = part(model, root, "StoneHead", Vector3.new(3.2, 2.8, 3.0) * s, CFrame.new(0, 4.35 * s, -0.35 * s), dark, nil, Enum.Material.Slate)
	for _, side in { -1, 1 } do
		part(model, root, "StoneArm", Vector3.new(1.45, 5.0, 1.45) * s, CFrame.new(side * 3.0 * s, 1.1 * s, 0), c, nil, Enum.Material.Slate)
		part(model, root, "StoneFist", Vector3.new(2.1, 1.7, 2.1) * s, CFrame.new(side * 3.0 * s, -1.6 * s, -0.15 * s), dark, nil, Enum.Material.Slate)
		part(model, root, "StoneLeg", Vector3.new(1.6, 3.5, 1.8) * s, CFrame.new(side * 1.35 * s, -2.5 * s, 0.3 * s), dark, nil, Enum.Material.Slate)
		oval(model, root, "GlowEye", Vector3.new(0.42,0.42,0.22) * s, CFrame.new(side * 0.65 * s, 4.55 * s, -1.9 * s), glow, Enum.Material.Neon)
	end
	oval(model, root, "Core", Vector3.new(1.1,1.1,0.5) * s, CFrame.new(0, 1.0 * s, -1.95 * s), glow, Enum.Material.Neon)
end

local function mammoth(model, root, data)
	local s, c = data.Scale or 1, data.Color
	local dark = c:Lerp(Color3.new(0,0,0), 0.18)
	local ivory = Color3.fromRGB(235, 224, 194)
	oval(model, root, "Body", Vector3.new(5.8, 4.5, 7.2) * s, CFrame.new(0, 1.2 * s, 0.4 * s), c)
	oval(model, root, "Head", Vector3.new(4.0, 3.8, 3.7) * s, CFrame.new(0, 2.2 * s, -4.2 * s), c)
	for _, side in { -1, 1 } do
		oval(model, root, "Ear", Vector3.new(1.8, 2.4, 0.7) * s, CFrame.new(side * 2.15 * s, 2.55 * s, -4.1 * s), dark)
		cylinder(model, root, "Tusk", 3.8 * s, 0.34 * s, CFrame.new(side * 1.15 * s, 0.7 * s, -6.0 * s) * CFrame.Angles(0, 0, math.rad(side * 24)), ivory)
	end
	for _, x in { -1.65, 1.65 } do
		for _, z in { -1.9, 2.0 } do
			cylinder(model, root, "Leg", 3.6 * s, 0.95 * s, CFrame.new(x * s, -1.6 * s, z * s) * CFrame.Angles(0,0,math.rad(90)), dark)
		end
	end
	cylinder(model, root, "Trunk", 4.4 * s, 0.72 * s, CFrame.new(0, 0.0 * s, -6.0 * s) * CFrame.Angles(0, 0, math.rad(78)), dark)
	eyes(model, root, 0.95, 2.8, -5.55, s)
end

local function buildVisual(model, root, mobName, data)
	local archetype = data.Archetype
	if mobName == "Wolf" or mobName == "SnowWolf" or mobName == "DireWolf" or archetype == "Canine" then canine(model, root, data, mobName == "DireWolf")
	elseif mobName == "Deer" or archetype == "Deer" then deer(model, root, data)
	elseif mobName == "Boar" or archetype == "Boar" then boar(model, root, data)
	elseif mobName == "WildCattle" or archetype == "Cattle" then cattle(model, root, data)
	elseif mobName == "SnowBear" or mobName == "ForestBear" or archetype == "Bear" then bear(model, root, data)
	elseif archetype == "Spider" then spider(model, root, data, mobName == "BroodSpider")
	elseif archetype == "Scorpion" then scorpion(model, root, data)
	elseif archetype == "Golem" then golem(model, root, data)
	elseif archetype == "Mammoth" then mammoth(model, root, data)
	else canine(model, root, data, false) end
	model:SetAttribute("VisualStyle", "WildforgeLowPoly")
end

local function nearestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local d = (root.Position - position).Magnitude
			if d < bestDistance then best, bestDistance = player, d end
		end
	end
	return best, bestDistance
end

local function dropLoot(model, mobName)
	local data = MobData.Mobs[mobName]
	if not data or not model.PrimaryPart then return end
	local origin = model.PrimaryPart.Position
	local attackerId = model:GetAttribute("LastAttackerUserId")
	local attacker = attackerId and Players:GetPlayerByUserId(attackerId)

	for _, drop in data.Drops or {} do
		if math.random() <= (drop.Chance or 1) then
			local amount = math.random(drop.Min or 1, drop.Max or drop.Min or 1)

			-- Animal meat is intentionally folded into the main Food resource.
			-- Hides, bones, fur, venom, etc. still use the 34-slot inventory.
			if drop.Item == "Food" then
				if attacker then
					PlayerService.Add(attacker, { Food = amount })
				else
					WorldService.CreateLootBag(origin, { Food = amount })
				end
			elseif attacker then
				local added = InventoryService.AddItem(attacker, drop.Item, amount)
				-- A completely full 34-slot bag should not delete rare loot.
				if not added then
					InventoryService.CreateWorldDrop(origin, drop.Item, amount)
				end
			else
				InventoryService.CreateWorldDrop(origin, drop.Item, amount)
			end
		end
	end

	if attacker then
		PlayerService.Add(attacker, {
			XP = data.XPReward or math.max(4, math.floor((data.Health or 50) / 10)),
			Gold = data.GoldReward or (data.Hostile and 4 or 2),
		})
	end
end

local function damagePopup(model, amount)
	local root = model.PrimaryPart
	if not root then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "DamagePopup"
	gui.Size = UDim2.fromOffset(90, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-8, 8) / 10, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = `-{math.floor(amount)}`
	label.TextColor3 = Color3.fromRGB(255, 236, 218)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(0.48), { StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2.3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.48), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 0.55)
end

local function hitFlash(model)
	local h = Instance.new("Highlight")
	h.Name = "HitFlash"
	h.FillColor = Color3.fromRGB(255, 245, 225)
	h.FillTransparency = 0.18
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = model
	Debris:AddItem(h, 0.1)
end

local function deathBurst(model)
	local root = model.PrimaryPart
	if not root then return end
	for _ = 1, 7 do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.4, 0.4, 0.4) * math.random(1, 3)
		p.Position = root.Position + Vector3.new(0, 2, 0)
		p.Color = Color3.fromRGB(217, 197, 166)
		p.Material = Enum.Material.Neon
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(7, 18), math.random(-12, 12))
		p.Parent = Workspace
		Debris:AddItem(p, 0.5)
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

	buildVisual(model, root, mobName, data)

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
		deathBurst(model)
		dropLoot(model, mobName)
		task.delay(0.65, function() if model.Parent then model:Destroy() end end)
		task.delay(data.RespawnSeconds or 18, function()
			if initialized and arena() then spawnMob(mobName) end
		end)
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
	local amount = math.max(0, damage or 0)
	model:SetAttribute("LastAttackerUserId", attacker and attacker.UserId or 0)
	if amount > 0 then
		hitFlash(model)
		damagePopup(model, amount)
		hum:TakeDamage(amount)
	end
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

local function wander(model, record, now)
	local data = record.Data
	if now >= record.NextWander then
		record.NextWander = now + math.random(3, 7)
		local angle = math.random() * math.pi * 2
		local radius = math.random(10, (data.Biome == "Forest" or SPECIAL_REGIONS[data.Biome]) and 28 or 36)
		record.WanderTarget = record.Home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum:MoveTo(record.WanderTarget) end
end

local function flee(model, record, target)
	local root = model.PrimaryPart
	local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not root or not targetRoot or not hum then return false end
	local away = Vector3.new(root.Position.X - targetRoot.Position.X, 0, root.Position.Z - targetRoot.Position.Z)
	if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
	hum.WalkSpeed = (record.Data.WalkSpeed or 14) * 1.18
	hum:MoveTo(root.Position + away.Unit * 26)
	return true
end

local function tickMob(model, record, now)
	if not model.Parent or not model.PrimaryPart then active[model] = nil return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local data = record.Data
	local night = worldPhase() == "Night"
	local threat = threatLevel()
	local blood = isBloodMoon()

	if not data.Hostile then
		local player, distance = nearestPlayer(model.PrimaryPart.Position, 22)
		if player and distance <= 22 and flee(model, record, player) then return end
		hum.WalkSpeed = data.WalkSpeed or 12
		wander(model, record, now)
		return
	end

	local aggressiveNow = not data.NightOnly or night
	if not aggressiveNow then
		hum.WalkSpeed = (data.WalkSpeed or 12) * 0.72
		wander(model, record, now)
		return
	end

	local nightSpeed = night and (1.08 + threat * 0.025 + (blood and 0.12 or 0)) or 1
	local aggroMultiplier = night and (1.12 + threat * 0.03 + (blood and 0.12 or 0)) or 1
	local damageMultiplier = night and (1.06 + (threat - 1) * 0.065 + (blood and 0.18 or 0)) or 1
	hum.WalkSpeed = (data.WalkSpeed or 14) * nightSpeed

	local target, distance = nearestPlayer(model.PrimaryPart.Position, (data.AggroRange or 50) * aggroMultiplier)
	if target then
		local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if targetRoot and targetHum and targetHum.Health > 0 then
			hum:MoveTo(targetRoot.Position)
			if distance <= (data.AttackRange or 4) and now - record.LastAttack >= (data.AttackCooldown or 1.2) then
				record.LastAttack = now
				targetHum:TakeDamage(incomingDamage(target, (data.Damage or 8) * damageMultiplier))
				if data.PoisonChance and math.random() <= data.PoisonChance then poisonPlayer(target, 6) end
			end
			return
		end
	end

	wander(model, record, now)
end

function MobService.Init()
	if initialized then return end
	initialized = true
	local world = Workspace:WaitForChild("SurvivalArena", 15)
	if not world then
		warn("[MobService] SurvivalArena not found; wildlife did not spawn.")
		return
	end

	for mobName, data in MobData.Mobs do
		for _ = 1, data.Count or 1 do spawnMob(mobName) end
	end

	task.spawn(function()
		while initialized do
			task.wait(0.32)
			local now = os.clock()
			for model, record in active do tickMob(model, record, now) end
		end
	end)

	print("[MobService] Wildforge wildlife online: flee AI, night threat scaling and combat feedback enabled.")
end

return MobService
