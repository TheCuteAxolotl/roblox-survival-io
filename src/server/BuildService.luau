local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)

local BuildService = {}
local BUILD_TAG = "PlayerBuild"
local RESOURCE_CORE_TAG = "ResourceCore"
local trapCooldowns = {}

local function makePart(parent, name, size, position, color, material)
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

local function tagBuild(model)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then CollectionService:AddTag(child, BUILD_TAG) end
	end
end

local function getArena()
	return Workspace:FindFirstChild("SurvivalArena")
end

local function buildMatchesLimit(requestedType, existingType)
	local requested = ItemData.Items[requestedType]
	local existing = ItemData.Items[existingType]
	if not requested or not existing then return requestedType == existingType end
	if requested.LimitGroup then
		return existing.LimitGroup == requested.LimitGroup
	end
	return requestedType == existingType
end

function BuildService.CountOwned(player, buildType)
	local arena = getArena()
	if not arena then return 0 end
	local count = 0
	for _, child in arena:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId then
			local existingType = child:GetAttribute("BuildType")
			if type(existingType) == "string" and buildMatchesLimit(buildType, existingType) then
				count += 1
			end
		end
	end
	return count
end

function BuildService.GetOwnedCounts(player)
	local counts = {}
	for itemName, item in ItemData.Items do
		if item.Category == "Build" then
			counts[itemName] = BuildService.CountOwned(player, itemName)
		end
	end
	return counts
end

local function placementCFrame(item, position, rotation)
	local y = item.PreviewY or ((item.PreviewSize and item.PreviewSize.Y or 2) / 2)
	return CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, math.rad(rotation or 0), 0)
end

function BuildService.CanPlace(player, buildType, position, rotation)
	local item = ItemData.Items[buildType]
	if not item or item.Category ~= "Build" then return false, "Unknown building." end
	if typeof(position) ~= "Vector3" then return false, "Invalid placement." end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false, "Character is not ready." end
	local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
	local flatPosition = Vector3.new(position.X, 0, position.Z)
	if (flatRoot - flatPosition).Magnitude > Config.BuildDistance then return false, "Place it closer to you." end

	local half = Config.WorldSize / 2
	local size = item.PreviewSize or Vector3.new(5, 5, 5)
	if math.abs(position.X) > half - (size.X / 2) - 4 or math.abs(position.Z) > half - (size.Z / 2) - 4 then
		return false, "Outside the map."
	end

	if math.abs(position.Z) < Config.RiverHalfWidth + (size.Z / 2) + Config.RiverNoBuildPadding then
		return false, "You cannot build in the river or on its banks."
	end

	if item.BuildLimit and BuildService.CountOwned(player, buildType) >= item.BuildLimit then
		return false, `Build limit reached ({item.BuildLimit}).`
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local clearance = Config.BuildClearance or 0.5
	local querySize = Vector3.new(size.X + clearance * 2, math.max(2, size.Y), size.Z + clearance * 2)
	local touching = Workspace:GetPartBoundsInBox(placementCFrame(item, position, rotation), querySize, params)
	for _, hit in touching do
		if CollectionService:HasTag(hit, BUILD_TAG) then
			return false, "That would overlap another building."
		end
		if CollectionService:HasTag(hit, RESOURCE_CORE_TAG) then
			local resourceModel = hit:FindFirstAncestorOfClass("Model")
			if not resourceModel or resourceModel:GetAttribute("Alive") ~= false then
				return false, "Move it away from the tree or rock."
			end
		end
	end

	return true
end

local function setupDamageZone(model, trigger, ownerUserId, damage, cooldown, slowSeconds)
	trigger.Touched:Connect(function(hit)
		if not model.Parent then return end
		local character = hit:FindFirstAncestorOfClass("Model")
		local victim = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not victim or victim.UserId == ownerUserId or not humanoid or humanoid.Health <= 0 then return end

		local key = `{model:GetDebugId()}:{victim.UserId}`
		local now = os.clock()
		if now - (trapCooldowns[key] or 0) < (cooldown or 1) then return end
		trapCooldowns[key] = now
		humanoid:TakeDamage(damage or 10)

		if slowSeconds and slowSeconds > 0 then
			local oldSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = math.min(oldSpeed, 8)
			task.delay(slowSeconds, function()
				if humanoid.Parent and humanoid.Health > 0 then
					humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, oldSpeed)
				end
			end)
		end
	end)
end

local function addSpikeCluster(model, position, count, radius, color, scale)
	for i = 1, count do
		local theta = math.rad((i - 1) * (360 / count))
		local spike = Instance.new("WedgePart")
		spike.Name = `Spike{i}`
		spike.Size = Vector3.new(1.25 * scale, 3.1 * scale, 1.25 * scale)
		spike.Anchored = true
		spike.Material = Enum.Material.Wood
		spike.Color = color
		local p = Vector3.new(position.X + math.cos(theta) * radius, 1.45 * scale, position.Z + math.sin(theta) * radius)
		spike.CFrame = CFrame.new(p) * CFrame.Angles(0, -theta + math.rad(90), 0)
		spike.Parent = model
	end
end

local function makeMill(model, position, buildType)
	local item = ItemData.Items[buildType]
	local tier = item and item.Tier or 1
	local baseSize = tier == 1 and 5.5 or (buildType == "PowerMill" and 7 or 6.2)
	local poleHeight = tier == 1 and 8 or (buildType == "PowerMill" and 10.5 or 9.2)
	local base = makePart(model, "Base", Vector3.new(baseSize, 1, baseSize), Vector3.new(position.X, 0.5, position.Z), Color3.fromRGB(101, 76, 54), Enum.Material.WoodPlanks)
	model.PrimaryPart = base
	makePart(model, "Pole", Vector3.new(1.4, poleHeight, 1.4), Vector3.new(position.X, 0.8 + poleHeight / 2, position.Z), Color3.fromRGB(132, 91, 58), Enum.Material.Wood)
	local hubY = poleHeight + 0.8
	local hub = makePart(model, "Hub", Vector3.new(1.8, 1.8, 1.8), Vector3.new(position.X, hubY, position.Z - 0.9), Color3.fromRGB(92, 92, 96), Enum.Material.Metal)
	hub.Shape = Enum.PartType.Ball
	local bladeLength = tier == 1 and 5 or (buildType == "PowerMill" and 6.8 or 5.8)
	for i = 0, 3 do
		local blade = makePart(model, `Blade{i + 1}`, Vector3.new(0.65, bladeLength, 1), hub.Position, Color3.fromRGB(226, 219, 194), Enum.Material.WoodPlanks)
		blade.CFrame = CFrame.new(hub.Position) * CFrame.Angles(0, 0, math.rad(i * 90)) * CFrame.new(0, bladeLength / 2, 0)
		blade.CanCollide = false
	end
	model:SetAttribute("NextPassiveAt", os.clock() + (item.TickSeconds or 8))
end

function BuildService.PlaceBuild(player, buildType, position, rotation)
	local item = ItemData.Items[buildType]
	local allowed, reason = BuildService.CanPlace(player, buildType, position, rotation)
	if not allowed then return nil, reason end

	local arena = getArena()
	if not arena then return nil, "Arena is not ready." end
	local model = Instance.new("Model")
	model.Name = buildType
	model.Parent = arena
	local angle = math.rad(rotation or 0)

	if buildType == "Wall" then
		local wall = makePart(model, "Wall", Vector3.new(10, 12, 1.2), Vector3.new(position.X, 6, position.Z), Color3.fromRGB(151, 101, 62), Enum.Material.WoodPlanks)
		wall.CFrame = CFrame.new(wall.Position) * CFrame.Angles(0, angle, 0)
		model.PrimaryPart = wall
	elseif buildType == "StoneWall" then
		local wall = makePart(model, "StoneWall", Vector3.new(10, 12, 1.6), Vector3.new(position.X, 6, position.Z), Color3.fromRGB(118, 121, 128), Enum.Material.Slate)
		wall.CFrame = CFrame.new(wall.Position) * CFrame.Angles(0, angle, 0)
		model.PrimaryPart = wall
		for x = -4, 4, 2 do
			local seam = makePart(model, "StoneBlock", Vector3.new(1.7, 1.3, 1.75), Vector3.new(position.X, 10.2, position.Z), Color3.fromRGB(132, 135, 142), Enum.Material.Slate)
			seam.CFrame = CFrame.new(position.X, 10.2, position.Z) * CFrame.Angles(0, angle, 0) * CFrame.new(x, 0, 0)
			seam.CanCollide = false
		end
	elseif buildType == "Spike" or buildType == "GreaterSpikes" then
		local scale = buildType == "GreaterSpikes" and 1.2 or 1
		local size = buildType == "GreaterSpikes" and 6.5 or 5.5
		local base = makePart(model, "Base", Vector3.new(size, 0.7, size), Vector3.new(position.X, 0.35, position.Z), Color3.fromRGB(92, 72, 54), Enum.Material.Wood)
		model.PrimaryPart = base
		addSpikeCluster(model, position, buildType == "GreaterSpikes" and 8 or 4, buildType == "GreaterSpikes" and 2.25 or 1.8, buildType == "GreaterSpikes" and Color3.fromRGB(93, 78, 67) or Color3.fromRGB(114, 87, 62), scale)
		local trigger = makePart(model, "DamageZone", Vector3.new(size - 0.3, 2, size - 0.3), Vector3.new(position.X, 1, position.Z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		trigger.Transparency = 1
		trigger.CanCollide = false
		trigger.CanQuery = false
		setupDamageZone(model, trigger, player.UserId, item.TouchDamage or 10, 0.9, nil)
	elseif buildType == "BearTrap" then
		local base = makePart(model, "TrapBase", Vector3.new(6, 0.35, 6), Vector3.new(position.X, 0.18, position.Z), Color3.fromRGB(87, 89, 94), Enum.Material.Metal)
		model.PrimaryPart = base
		for i = 1, 8 do
			local theta = math.rad((i - 1) * 45)
			local tooth = Instance.new("WedgePart")
			tooth.Name = `Tooth{i}`
			tooth.Size = Vector3.new(0.75, 1.6, 1.1)
			tooth.Anchored = true
			tooth.Material = Enum.Material.Metal
			tooth.Color = Color3.fromRGB(122, 124, 130)
			local p = Vector3.new(position.X + math.cos(theta) * 2.1, 0.75, position.Z + math.sin(theta) * 2.1)
			tooth.CFrame = CFrame.new(p) * CFrame.Angles(0, -theta + math.rad(90), 0)
			tooth.Parent = model
		end
		local trigger = makePart(model, "Trigger", Vector3.new(5.3, 2, 5.3), Vector3.new(position.X, 1, position.Z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		trigger.Transparency = 1
		trigger.CanCollide = false
		trigger.CanQuery = false
		setupDamageZone(model, trigger, player.UserId, 18, 2.5, 1.15)
	elseif buildType == "Windmill" or buildType == "RapidMill" or buildType == "PowerMill" then
		makeMill(model, position, buildType)
	elseif buildType == "Campfire" then
		local base = makePart(model, "FireBase", Vector3.new(5.5, 0.5, 5.5), Vector3.new(position.X, 0.25, position.Z), Color3.fromRGB(94, 88, 82), Enum.Material.Slate)
		model.PrimaryPart = base
		for _, z in { -0.75, 0.75 } do
			local log = makePart(model, "Log", Vector3.new(4, 0.65, 0.65), Vector3.new(position.X, 0.7, position.Z + z), Color3.fromRGB(112, 74, 43), Enum.Material.Wood)
			log.CFrame *= CFrame.Angles(0, math.rad(z > 0 and 32 or -32), 0)
		end
		local flame = makePart(model, "Flame", Vector3.new(1.5, 2.5, 1.5), Vector3.new(position.X, 2, position.Z), Color3.fromRGB(255, 153, 52), Enum.Material.Neon)
		flame.Shape = Enum.PartType.Ball
		flame.CanCollide = false
		flame.CanQuery = false
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 2
		light.Color = Color3.fromRGB(255, 166, 88)
		light.Parent = flame
	elseif buildType == "HealingPad" then
		local base = makePart(model, "HealingPad", Vector3.new(7, 0.6, 7), Vector3.new(position.X, 0.3, position.Z), Color3.fromRGB(78, 122, 96), Enum.Material.Metal)
		model.PrimaryPart = base
		local glow = makePart(model, "Glow", Vector3.new(5.4, 0.18, 5.4), Vector3.new(position.X, 0.7, position.Z), Color3.fromRGB(92, 240, 141), Enum.Material.Neon)
		glow.CanCollide = false
	elseif buildType == "Turret" then
		local base = makePart(model, "TurretBase", Vector3.new(5.5, 1, 5.5), Vector3.new(position.X, 0.5, position.Z), Color3.fromRGB(91, 95, 104), Enum.Material.Metal)
		model.PrimaryPart = base
		makePart(model, "Stand", Vector3.new(1.4, 4.2, 1.4), Vector3.new(position.X, 3, position.Z), Color3.fromRGB(106, 110, 120), Enum.Material.Metal)
		local head = makePart(model, "TurretHead", Vector3.new(3.3, 2, 3.3), Vector3.new(position.X, 5.4, position.Z), Color3.fromRGB(126, 130, 140), Enum.Material.Metal)
		head.Shape = Enum.PartType.Ball
		makePart(model, "Barrel", Vector3.new(0.65, 0.65, 4), Vector3.new(position.X, 5.4, position.Z - 2.7), Color3.fromRGB(71, 74, 82), Enum.Material.Metal)
		model:SetAttribute("NextAttackAt", 0)
	elseif buildType == "Mine" then
		local mine = makePart(model, "Mine", Vector3.new(4.6, 0.6, 4.6), Vector3.new(position.X, 0.3, position.Z), Color3.fromRGB(70, 72, 76), Enum.Material.Metal)
		mine.Shape = Enum.PartType.Cylinder
		mine.Orientation = Vector3.new(0, 0, 90)
		model.PrimaryPart = mine
		local trigger = makePart(model, "MineTrigger", Vector3.new(5, 2, 5), Vector3.new(position.X, 1, position.Z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		trigger.Transparency = 1
		trigger.CanCollide = false
		trigger.CanQuery = false
		local armed = true
		trigger.Touched:Connect(function(hit)
			if not armed or not model.Parent then return end
			local character = hit:FindFirstAncestorOfClass("Model")
			local victim = character and Players:GetPlayerFromCharacter(character)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not victim or victim.UserId == player.UserId or not humanoid or humanoid.Health <= 0 then return end
			armed = false
			humanoid:TakeDamage(item.MineDamage or 50)
			model:Destroy()
		end)
	elseif buildType == "Sapling" then
		local trunk = makePart(model, "Trunk", Vector3.new(1.2, 4.8, 1.2), Vector3.new(position.X, 2.4, position.Z), Color3.fromRGB(121, 84, 52), Enum.Material.Wood)
		model.PrimaryPart = trunk
		local crown = makePart(model, "Crown", Vector3.new(4.2, 4.2, 4.2), Vector3.new(position.X, 5.8, position.Z), Color3.fromRGB(79, 151, 83), Enum.Material.Grass)
		crown.Shape = Enum.PartType.Ball
		crown.CanCollide = false
		model:SetAttribute("NextPassiveAt", os.clock() + (item.TickSeconds or 8))
	else
		model:Destroy()
		return nil, "That building is not implemented yet."
	end

	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", buildType)
	model:SetAttribute("Health", item.Health or 100)
	model:SetAttribute("MaxHealth", item.Health or 100)
	tagBuild(model)
	return model, `{item.Label} placed.`
end

function BuildService.DamageBuild(player, model, damage)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then
		return false, nil, "That structure is gone."
	end
	local buildType = model:GetAttribute("BuildType")
	local item = ItemData.Items[buildType]
	if not item or item.Category ~= "Build" then return false, nil, "Invalid structure." end

	local health = (model:GetAttribute("Health") or 1) - math.max(1, damage or 1)
	model:SetAttribute("Health", health)
	if health > 0 then return false, nil, `Structure: {math.max(0, health)} HP` end

	local ownerUserId = model:GetAttribute("OwnerUserId") or 0
	local ratio = ownerUserId == player.UserId and Config.OwnBuildRefundRatio or Config.EnemyBuildSalvageRatio
	local salvage = {}
	for resource, amount in item.Cost or {} do
		salvage[resource] = math.floor((amount * ratio) + 0.5)
	end
	local label = item.Label or buildType
	model:Destroy()
	if ownerUserId == player.UserId then
		return true, salvage, `{label} dismantled — supplies returned.`
	end
	return true, salvage, `{label} destroyed — salvaged supplies.`
end

return BuildService
