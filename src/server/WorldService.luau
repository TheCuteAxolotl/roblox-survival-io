local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldService = {}
local arena = nil

local RESOURCE_TAG = "SurvivalResource"
local RESOURCE_CORE_TAG = "ResourceCore"
local BUILD_TAG = "PlayerBuild"
local LOOT_TAG = "SurvivalLoot"

local BIOMES = {
	Snow = { Color = Color3.fromRGB(224, 235, 242), Material = Enum.Material.Snow },
	Grass = { Color = Color3.fromRGB(116, 170, 89), Material = Enum.Material.Grass },
	Desert = { Color = Color3.fromRGB(214, 183, 118), Material = Enum.Material.Sand },
}

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function rememberPartState(p)
	p:SetAttribute("OriginalTransparency", p.Transparency)
	p:SetAttribute("OriginalCanCollide", p.CanCollide)
end

local function createHealthBar(model, adornee)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ResourceHealth"
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(64, 10)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.7, 0)
	gui.AlwaysOnTop = true
	gui.Enabled = false
	gui.Parent = model
	local background = Instance.new("Frame")
	background.Name = "Bar"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
	background.BorderSizePixel = 0
	background.Parent = gui
	Instance.new("UICorner", background).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(94, 220, 104)
	fill.BorderSizePixel = 0
	fill.Parent = background
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
end

local function updateHealthBar(model)
	local gui = model:FindFirstChild("ResourceHealth")
	if not gui or not gui:IsA("BillboardGui") then return end
	local bar = gui:FindFirstChild("Bar")
	local fill = bar and bar:FindFirstChild("Fill")
	local health = model:GetAttribute("Health") or 0
	local maxHealth = math.max(1, model:GetAttribute("MaxHealth") or 1)
	if fill and fill:IsA("Frame") then fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1) end
	gui.Enabled = model:GetAttribute("Alive") == true and health < maxHealth
end

local function setResourceVisible(model, visible)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			if visible then
				child.Transparency = child:GetAttribute("OriginalTransparency") or 0
				child.CanCollide = child:GetAttribute("OriginalCanCollide") == true
			else
				child.Transparency = 1
				child.CanCollide = false
			end
		end
	end
	local gui = model:FindFirstChild("ResourceHealth")
	if gui and gui:IsA("BillboardGui") and not visible then gui.Enabled = false end
end

local function pulseHit(model)
	local hitbox = model.PrimaryPart
	if not hitbox then return end
	local original = hitbox.Color
	hitbox.Color = original:Lerp(Color3.new(1, 1, 1), 0.45)
	TweenService:Create(hitbox, TweenInfo.new(0.16), { Color = original }):Play()
end

local function removeDefaultTemplateParts()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then baseplate:Destroy() end
	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then child:Destroy() end
	end
end

local function biomeXRange(biome)
	local half = Config.WorldSize / 2
	local split = Config.BiomeSplit
	if biome == "Snow" then return -half + 35, -split - 25 end
	if biome == "Desert" then return split + 25, half - 35 end
	return -split + 25, split - 25
end

local function randomBiomePoint(biome)
	local xMin, xMax = biomeXRange(biome)
	local half = Config.WorldSize / 2
	local zMargin = Config.RiverHalfWidth + 42
	local z
	if math.random() < 0.5 then
		z = math.random(math.floor(-half + 35), math.floor(-zMargin))
	else
		z = math.random(math.floor(zMargin), math.floor(half - 35))
	end
	return Vector3.new(math.random(math.floor(xMin), math.floor(xMax)), 0, z)
end

local function positionClear(position, ignoreModel)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreModel and { ignoreModel } or {}
	local hits = Workspace:GetPartBoundsInBox(CFrame.new(position + Vector3.new(0, 4, 0)), Vector3.new(9, 10, 9), params)
	for _, hit in hits do
		if CollectionService:HasTag(hit, BUILD_TAG) or CollectionService:HasTag(hit, RESOURCE_CORE_TAG) then
			return false
		end
	end
	return true
end

local function findSafePoint(biome, ignoreModel)
	for _ = 1, 70 do
		local point = randomBiomePoint(biome)
		if positionClear(point, ignoreModel) then return point end
	end
	return randomBiomePoint(biome)
end

local function resourceColors(kind, biome)
	if kind == "Rock" then
		if biome == "Desert" then return Color3.fromRGB(151, 130, 105), Color3.fromRGB(169, 147, 118) end
		if biome == "Snow" then return Color3.fromRGB(132, 143, 153), Color3.fromRGB(154, 164, 174) end
		return Color3.fromRGB(112, 116, 124), Color3.fromRGB(126, 130, 138)
	end
	if kind == "Tree" and biome == "Snow" then return Color3.fromRGB(106, 80, 59), Color3.fromRGB(66, 112, 82) end
	if kind == "Tree" and biome == "Desert" then return Color3.fromRGB(120, 88, 55), Color3.fromRGB(99, 145, 79) end
	return Color3.fromRGB(119, 82, 51), Color3.fromRGB(72, 137, 76)
end

local function tagResourceModel(model, core)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			rememberPartState(child)
			CollectionService:AddTag(child, RESOURCE_TAG)
		end
	end
	if core then CollectionService:AddTag(core, RESOURCE_CORE_TAG) end
end

local function makeResource(kind, biome)
	local position = findSafePoint(biome)
	local model = Instance.new("Model")
	model.Name = kind
	model.Parent = arena
	model:SetAttribute("Biome", biome)
	model:SetAttribute("GroundPosition", position)

	local hitbox
	if kind == "Tree" then
		local trunkColor, leafColor = resourceColors(kind, biome)
		local trunk = part(model, "Trunk", Vector3.new(2.6, 8, 2.6), position + Vector3.new(0, 4, 0), trunkColor, Enum.Material.Wood)
		hitbox = trunk
		model.PrimaryPart = trunk
		for i, offset in { Vector3.new(0, 9.5, 0), Vector3.new(-2.4, 9, 0.7), Vector3.new(2.2, 9.2, 0.3), Vector3.new(0.4, 10.1, -2.0) } do
			local crown = part(model, `Crown{i}`, Vector3.new(6.5, 6.5, 6.5), position + offset, leafColor, Enum.Material.Grass)
			crown.Shape = Enum.PartType.Ball
			crown.CanCollide = false
		end
		model:SetAttribute("Resource", "Wood")
		model:SetAttribute("Yield", 8)
		model:SetAttribute("MaxHealth", 5)
	elseif kind == "Rock" then
		local rockColor, chunkColor = resourceColors(kind, biome)
		local rock = part(model, "Rock", Vector3.new(6.3, 5.2, 6.3), position + Vector3.new(0, 2.5, 0), rockColor, Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
		hitbox = rock
		model.PrimaryPart = rock
		for i, offset in { Vector3.new(2.1, 1.1, 1), Vector3.new(-1.8, 0.7, -1.5) } do
			local chunk = part(model, `Chunk{i}`, Vector3.new(3.2, 3, 3.2), position + Vector3.new(0, 1.8, 0) + offset, chunkColor, Enum.Material.Slate)
			chunk.Shape = Enum.PartType.Ball
		end
		model:SetAttribute("Resource", "Stone")
		model:SetAttribute("Yield", 7)
		model:SetAttribute("MaxHealth", 6)
	else
		local bushColor = biome == "Snow" and Color3.fromRGB(86, 132, 95) or Color3.fromRGB(95, 151, 80)
		local bush = part(model, "Bush", Vector3.new(5, 4, 5), position + Vector3.new(0, 2, 0), bushColor, Enum.Material.Grass)
		bush.Shape = Enum.PartType.Ball
		hitbox = bush
		model.PrimaryPart = bush
		bush.CanCollide = false
		for i, offset in { Vector3.new(1.4, 2.5, 0.5), Vector3.new(-1.2, 2.2, 0.8), Vector3.new(0.4, 2.8, -1.1) } do
			local berry = part(model, `Berry{i}`, Vector3.new(0.65, 0.65, 0.65), position + offset, Color3.fromRGB(190, 45, 55), Enum.Material.SmoothPlastic)
			berry.Shape = Enum.PartType.Ball
			berry.CanCollide = false
		end
		model:SetAttribute("Resource", "Food")
		model:SetAttribute("Yield", 2)
		model:SetAttribute("MaxHealth", 4)
	end

	model:SetAttribute("Health", model:GetAttribute("MaxHealth"))
	model:SetAttribute("Alive", true)
	tagResourceModel(model, hitbox)
	createHealthBar(model, hitbox)
	return model
end

local function moveResourceIfBlocked(model)
	local ground = model:GetAttribute("GroundPosition")
	if typeof(ground) ~= "Vector3" then return end
	if positionClear(ground, model) then return end
	local biome = model:GetAttribute("Biome") or "Grass"
	local newGround = findSafePoint(biome, model)
	local delta = newGround - ground
	model:PivotTo(model:GetPivot() + delta)
	model:SetAttribute("GroundPosition", newGround)
end

local function makeBiomeGround(name, xMin, xMax, data)
	local river = Config.RiverHalfWidth
	local half = Config.WorldSize / 2
	local xSize = xMax - xMin
	local xCenter = (xMin + xMax) / 2
	local zSize = half - river
	local northCenter = river + zSize / 2
	local southCenter = -northCenter
	part(arena, `${name}North`, Vector3.new(xSize, 2, zSize), Vector3.new(xCenter, -1, northCenter), data.Color, data.Material)
	part(arena, `${name}South`, Vector3.new(xSize, 2, zSize), Vector3.new(xCenter, -1, southCenter), data.Color, data.Material)
end

function WorldService.BuildArena()
	local old = Workspace:FindFirstChild("SurvivalArena")
	if old then old:Destroy() end
	removeDefaultTemplateParts()

	arena = Instance.new("Model")
	arena.Name = "SurvivalArena"
	arena.Parent = Workspace
	local half = Config.WorldSize / 2
	local split = Config.BiomeSplit

	local foundation = part(arena, "Foundation", Vector3.new(Config.WorldSize, 4, Config.WorldSize), Vector3.new(0, -4, 0), Color3.fromRGB(78, 83, 78), Enum.Material.Slate)
	foundation.CanCollide = true
	makeBiomeGround("Snow", -half, -split, BIOMES.Snow)
	makeBiomeGround("Grass", -split, split, BIOMES.Grass)
	makeBiomeGround("Desert", split, half, BIOMES.Desert)

	local riverBed = part(arena, "RiverBed", Vector3.new(Config.WorldSize, 2, Config.RiverHalfWidth * 2), Vector3.new(0, -2, 0), Color3.fromRGB(82, 103, 112), Enum.Material.Slate)
	riverBed.CanCollide = true
	local water = part(arena, "RiverWater", Vector3.new(Config.WorldSize, 0.8, Config.RiverHalfWidth * 2), Vector3.new(0, -0.55, 0), Color3.fromRGB(73, 146, 205), Enum.Material.Glass)
	water.Transparency = 0.3
	water.CanCollide = false
	water.CanQuery = false

	for _, x in Config.BridgeXPositions do
		local bridge = part(arena, "Bridge", Vector3.new(28, 1, Config.RiverHalfWidth * 2 + 14), Vector3.new(x, 0.3, 0), Color3.fromRGB(131, 92, 58), Enum.Material.WoodPlanks)
		bridge.CanCollide = true
	end

	for _, data in {
		{ Vector3.new(Config.WorldSize, 24, 2), Vector3.new(0, 11, -half) },
		{ Vector3.new(Config.WorldSize, 24, 2), Vector3.new(0, 11, half) },
		{ Vector3.new(2, 24, Config.WorldSize), Vector3.new(-half, 11, 0) },
		{ Vector3.new(2, 24, Config.WorldSize), Vector3.new(half, 11, 0) },
	} do
		local boundary = part(arena, "Boundary", data[1], data[2], Color3.fromRGB(70, 100, 65), Enum.Material.SmoothPlastic)
		boundary.Transparency = 1
		boundary.CanCollide = true
	end

	for _ = 1, 88 do makeResource("Tree", "Snow") end
	for _ = 1, 70 do makeResource("Rock", "Snow") end
	for _ = 1, 34 do makeResource("Berry", "Snow") end
	for _ = 1, 126 do makeResource("Tree", "Grass") end
	for _ = 1, 72 do makeResource("Rock", "Grass") end
	for _ = 1, 60 do makeResource("Berry", "Grass") end
	for _ = 1, 48 do makeResource("Tree", "Desert") end
	for _ = 1, 84 do makeResource("Rock", "Desert") end
	for _ = 1, 28 do makeResource("Berry", "Desert") end

	for _, pos in {
		Vector3.new(-430, 1, -220), Vector3.new(-430, 1, 220),
		Vector3.new(0, 1, -220), Vector3.new(0, 1, 220),
		Vector3.new(430, 1, -220), Vector3.new(430, 1, 220),
	} do
		local spawn = Instance.new("SpawnLocation")
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = pos
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Parent = arena
	end
end

function WorldService.Gather(target)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return nil, "Aim at a tree, rock, berry bush, or loot bag."
	end
	if CollectionService:HasTag(target, LOOT_TAG) then
		local bag = target:FindFirstAncestorOfClass("Model")
		if not bag then return nil, "That loot is gone." end
		local changes = {
			Wood = bag:GetAttribute("Wood") or 0,
			Stone = bag:GetAttribute("Stone") or 0,
			Food = bag:GetAttribute("Food") or 0,
			Gold = bag:GetAttribute("Gold") or 0,
		}
		bag:Destroy()
		return changes, "Loot collected!"
	end
	if not CollectionService:HasTag(target, RESOURCE_TAG) then return nil, "Aim at a tree, rock, or berry bush." end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or not model:GetAttribute("Alive") then return nil, "That resource is depleted." end

	local health = (model:GetAttribute("Health") or 1) - 1
	model:SetAttribute("Health", health)
	local resource = model:GetAttribute("Resource")
	local amount = resource == "Food" and 1 or 2
	local depleted = health <= 0
	pulseHit(model)
	updateHealthBar(model)

	if depleted then
		model:SetAttribute("Alive", false)
		amount += model:GetAttribute("Yield") or 0
		setResourceVisible(model, false)
		task.delay(Config.ResourceRespawnSeconds, function()
			if model.Parent then
				moveResourceIfBlocked(model)
				model:SetAttribute("Health", model:GetAttribute("MaxHealth"))
				model:SetAttribute("Alive", true)
				setResourceVisible(model, true)
				updateHealthBar(model)
			end
		end)
	end
	return { [resource] = amount, XP = amount }, depleted and `{resource} node depleted!` or `+{amount} {resource}`
end

function WorldService.CreateLootBag(position, drops)
	if not arena or type(drops) ~= "table" then return nil end
	local total = 0
	for _, amount in drops do total += amount end
	if total <= 0 then return nil end
	local model = Instance.new("Model")
	model.Name = "DroppedLoot"
	model.Parent = arena
	for _, name in { "Wood", "Stone", "Food", "Gold" } do model:SetAttribute(name, drops[name] or 0) end
	local sack = part(model, "LootBag", Vector3.new(3, 3, 3), position + Vector3.new(0, 1.6, 0), Color3.fromRGB(176, 126, 63), Enum.Material.Fabric)
	sack.Shape = Enum.PartType.Ball
	sack.CanCollide = false
	model.PrimaryPart = sack
	CollectionService:AddTag(sack, LOOT_TAG)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 28)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = sack
	gui.Parent = model
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	label.BackgroundTransparency = 0.15
	label.Text = "DROPPED LOOT"
	label.TextColor3 = Color3.fromRGB(255, 231, 154)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
	Debris:AddItem(model, 30)
	return model
end

return WorldService
