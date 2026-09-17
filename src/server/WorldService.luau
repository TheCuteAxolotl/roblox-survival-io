local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldService = {}
local arena = nil

local RESOURCE_TAG = "SurvivalResource"
local BUILD_TAG = "PlayerBuild"
local LOOT_TAG = "SurvivalLoot"

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
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
	end
	gui.Enabled = model:GetAttribute("Alive") == true and health < maxHealth
end

local function tagResourceModel(model)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			rememberPartState(child)
			CollectionService:AddTag(child, RESOURCE_TAG)
		end
	end
end

local function makeResource(kind, position)
	local model = Instance.new("Model")
	model.Name = kind
	model.Parent = arena

	local hitbox
	if kind == "Tree" then
		local trunk = part(model, "Trunk", Vector3.new(2.6, 8, 2.6), position + Vector3.new(0, 4, 0), Color3.fromRGB(119, 82, 51), Enum.Material.Wood)
		hitbox = trunk
		model.PrimaryPart = trunk

		for i, offset in {
			Vector3.new(0, 9.5, 0),
			Vector3.new(-2.4, 9, 0.7),
			Vector3.new(2.2, 9.2, 0.3),
			Vector3.new(0.4, 10.1, -2.0),
		} do
			local crown = part(model, `Crown{i}`, Vector3.new(6.5, 6.5, 6.5), position + offset, Color3.fromRGB(72, 137, 76), Enum.Material.Grass)
			crown.Shape = Enum.PartType.Ball
			crown.CanCollide = false
		end

		model:SetAttribute("Resource", "Wood")
		model:SetAttribute("Yield", 8)
		model:SetAttribute("MaxHealth", 5)
	elseif kind == "Rock" then
		local rock = part(model, "Rock", Vector3.new(6.3, 5.2, 6.3), position + Vector3.new(0, 2.5, 0), Color3.fromRGB(112, 116, 124), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
		hitbox = rock
		model.PrimaryPart = rock

		for i, offset in { Vector3.new(2.1, 1.1, 1), Vector3.new(-1.8, 0.7, -1.5) } do
			local chunk = part(model, `Chunk{i}`, Vector3.new(3.2, 3, 3.2), position + Vector3.new(0, 1.8, 0) + offset, Color3.fromRGB(126, 130, 138), Enum.Material.Slate)
			chunk.Shape = Enum.PartType.Ball
		end

		model:SetAttribute("Resource", "Stone")
		model:SetAttribute("Yield", 7)
		model:SetAttribute("MaxHealth", 6)
	else
		local bush = part(model, "Bush", Vector3.new(5, 4, 5), position + Vector3.new(0, 2, 0), Color3.fromRGB(95, 151, 80), Enum.Material.Grass)
		bush.Shape = Enum.PartType.Ball
		hitbox = bush
		model.PrimaryPart = bush
		bush.CanCollide = false

		for i, offset in {
			Vector3.new(1.4, 2.5, 0.5), Vector3.new(-1.2, 2.2, 0.8), Vector3.new(0.4, 2.8, -1.1),
		} do
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
	tagResourceModel(model)
	createHealthBar(model, hitbox)
	return model
end

local function randomGroundPoint(margin)
	local half = math.floor((Config.WorldSize / 2) - margin)
	return Vector3.new(math.random(-half, half), 0, math.random(-half, half))
end

local function setResourceVisible(model, visible)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			if visible then
				child.Transparency = child:GetAttribute("OriginalTransparency") or 0
				local originalCollision = child:GetAttribute("OriginalCanCollide")
				child.CanCollide = originalCollision == true
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
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end

	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
end

function WorldService.BuildArena()
	local old = Workspace:FindFirstChild("SurvivalArena")
	if old then old:Destroy() end
	removeDefaultTemplateParts()

	arena = Instance.new("Model")
	arena.Name = "SurvivalArena"
	arena.Parent = Workspace

	local ground = part(arena, "Ground", Vector3.new(Config.WorldSize, 2, Config.WorldSize), Vector3.new(0, -1, 0), Color3.fromRGB(116, 170, 89), Enum.Material.Grass)
	ground.CanCollide = true

	-- Invisible boundary so players cannot wander forever outside the arena.
	local half = Config.WorldSize / 2
	for _, data in {
		{ Vector3.new(Config.WorldSize, 22, 2), Vector3.new(0, 10, -half) },
		{ Vector3.new(Config.WorldSize, 22, 2), Vector3.new(0, 10, half) },
		{ Vector3.new(2, 22, Config.WorldSize), Vector3.new(-half, 10, 0) },
		{ Vector3.new(2, 22, Config.WorldSize), Vector3.new(half, 10, 0) },
	} do
		local wall = part(arena, "Boundary", data[1], data[2], Color3.fromRGB(70, 100, 65), Enum.Material.SmoothPlastic)
		wall.Transparency = 1
		wall.CanCollide = true
	end

	for _ = 1, 48 do makeResource("Tree", randomGroundPoint(24)) end
	for _ = 1, 32 do makeResource("Rock", randomGroundPoint(24)) end
	for _ = 1, 28 do makeResource("Berry", randomGroundPoint(24)) end

	for _, pos in {
		Vector3.new(-35, 1, -35), Vector3.new(35, 1, -35), Vector3.new(-35, 1, 35), Vector3.new(35, 1, 35), Vector3.new(0, 1, 0),
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

	if not CollectionService:HasTag(target, RESOURCE_TAG) then
		return nil, "Aim at a tree, rock, or berry bush."
	end

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
		task.delay(12, function()
			if model.Parent then
				model:SetAttribute("Health", model:GetAttribute("MaxHealth"))
				model:SetAttribute("Alive", true)
				setResourceVisible(model, true)
				updateHealthBar(model)
			end
		end)
	end

	return { [resource] = amount, XP = amount }, depleted and `{resource} node depleted!` or `+{amount} {resource}`
end

function WorldService.PlaceBuild(player, buildType, position, rotation)
	if buildType ~= "Wall" and buildType ~= "Spike" then return nil, "Unknown building." end
	if typeof(position) ~= "Vector3" then return nil, "Invalid placement." end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - position).Magnitude > Config.BuildDistance then return nil, "Place it closer to you." end
	if math.abs(position.X) > Config.WorldSize / 2 - 4 or math.abs(position.Z) > Config.WorldSize / 2 - 4 then return nil, "Outside the map." end

	local model = Instance.new("Model")
	model.Name = buildType
	model.Parent = arena

	if buildType == "Wall" then
		local wall = part(model, "Wall", Vector3.new(10, 6, 1.2), Vector3.new(position.X, 3, position.Z), Color3.fromRGB(151, 101, 62), Enum.Material.WoodPlanks)
		wall.CFrame = CFrame.new(wall.Position) * CFrame.Angles(0, math.rad(rotation or 0), 0)
		model.PrimaryPart = wall
	else
		local base = part(model, "Base", Vector3.new(5.5, 0.7, 5.5), Vector3.new(position.X, 0.35, position.Z), Color3.fromRGB(92, 72, 54), Enum.Material.Wood)
		model.PrimaryPart = base
		for i, offset in {
			Vector3.new(-1.5, 1.5, -1.5), Vector3.new(1.5, 1.5, -1.5), Vector3.new(-1.5, 1.5, 1.5), Vector3.new(1.5, 1.5, 1.5),
		} do
			local spike = Instance.new("WedgePart")
			spike.Name = `Spike{i}`
			spike.Size = Vector3.new(1.3, 3, 1.3)
			spike.Position = Vector3.new(position.X, 0, position.Z) + offset
			spike.Anchored = true
			spike.Material = Enum.Material.Wood
			spike.Color = Color3.fromRGB(114, 87, 62)
			spike.CFrame = CFrame.new(spike.Position) * CFrame.Angles(0, math.rad((i - 1) * 90), 0)
			spike.Parent = model
		end
	end

	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", buildType)
	model:SetAttribute("Health", buildType == "Wall" and 120 or 75)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then CollectionService:AddTag(child, BUILD_TAG) end
	end
	return model, `{buildType} placed.`
end

function WorldService.CreateLootBag(position, drops)
	if not arena or type(drops) ~= "table" then return nil end
	local total = 0
	for _, amount in drops do total += amount end
	if total <= 0 then return nil end

	local model = Instance.new("Model")
	model.Name = "DroppedLoot"
	model.Parent = arena
	for _, name in { "Wood", "Stone", "Food", "Gold" } do
		model:SetAttribute(name, drops[name] or 0)
	end

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
