local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local CASTLE_SIZE = Vector3.new(158, 34, 142)
local LANDMARK_PADDING = 34
local random = Random.new()

local function part(parent, name, size, cf, color, material, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function isLandmark(model)
	if not model:IsA("Model") then return false end
	if model:GetAttribute("VillageBiome") then return true end
	if model:GetAttribute("Dungeon") == true then return true end
	if model:GetAttribute("Cave") == true then return true end
	if model:GetAttribute("DangerZone") == true then return true end
	if model:GetAttribute("Castle") == true then return true end
	if model.Name == "BossArena" then return true end
	if model:GetAttribute("OwnerUserId") then return true end
	return false
end

local function horizontalOverlap(centerA, sizeA, centerB, sizeB, padding)
	return math.abs(centerA.X - centerB.X) < (sizeA.X + sizeB.X) / 2 + padding
		and math.abs(centerA.Z - centerB.Z) < (sizeA.Z + sizeB.Z) / 2 + padding
end

local function locationClear(center)
	local half = Config.WorldSize / 2
	if math.abs(center.X) + CASTLE_SIZE.X / 2 + 22 > half then return false end
	if math.abs(center.Z) + CASTLE_SIZE.Z / 2 + 22 > half then return false end
	if math.abs(center.Z) < Config.RiverHalfWidth + CASTLE_SIZE.Z / 2 + 28 then return false end

	for _, child in world:GetChildren() do
		if isLandmark(child) then
			local ok, cf, size = pcall(function()
				local boxCf, boxSize = child:GetBoundingBox()
				return boxCf, boxSize
			end)
			if ok and cf and size and horizontalOverlap(center, CASTLE_SIZE, cf.Position, size, LANDMARK_PADDING) then
				return false
			end
		end
	end
	return true
end

local function chooseCenter()
	local half = math.floor(Config.WorldSize / 2 - 115)
	for _ = 1, 80 do
		local x = random:NextInteger(-half, half)
		local z = random:NextInteger(-half, half)
		local center = Vector3.new(x, 0, z)
		if locationClear(center) then return center end
	end

	local fallback = {
		Vector3.new(205, 0, -210), Vector3.new(-205, 0, -210),
		Vector3.new(210, 0, 210), Vector3.new(-210, 0, 210),
		Vector3.new(0, 0, -265),
	}
	for _, center in fallback do if locationClear(center) then return center end end
	return nil
end

local function clearNaturalResources(center, radius)
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child.PrimaryPart and (child:GetAttribute("Resource") or child:GetAttribute("SurvivalMob")) then
			local delta = Vector3.new(child.PrimaryPart.Position.X - center.X, 0, child.PrimaryPart.Position.Z - center.Z)
			if delta.Magnitude < radius then child:Destroy() end
		end
	end
end

local function torch(parent, position)
	local pole = part(parent, "CastleTorchPole", Vector3.new(0.45, 5, 0.45), CFrame.new(position + Vector3.new(0, 2.5, 0)), Color3.fromRGB(74, 55, 42), Enum.Material.Wood)
	local flame = part(parent, "CastleTorchFlame", Vector3.new(0.9, 0.9, 0.9), CFrame.new(position + Vector3.new(0, 5.4, 0)), Color3.fromRGB(255, 152, 52), Enum.Material.Neon, false)
	flame.Shape = Enum.PartType.Ball
	flame.CanQuery = false
	local light = Instance.new("PointLight")
	light.Range = 25
	light.Brightness = 2.6
	light.Shadows = true
	light.Parent = flame
	pole.CanCollide = true
end

local function battlements(parent, center, halfX, halfZ, y)
	local stone = Color3.fromRGB(101, 104, 108)
	for x = -halfX, halfX, 12 do
		part(parent, "Battlement", Vector3.new(5, 3.2, 4), CFrame.new(center + Vector3.new(x, y, -halfZ)), stone, Enum.Material.Slate)
		part(parent, "Battlement", Vector3.new(5, 3.2, 4), CFrame.new(center + Vector3.new(x, y, halfZ)), stone, Enum.Material.Slate)
	end
	for z = -halfZ + 8, halfZ - 8, 12 do
		part(parent, "Battlement", Vector3.new(4, 3.2, 5), CFrame.new(center + Vector3.new(-halfX, y, z)), stone, Enum.Material.Slate)
		part(parent, "Battlement", Vector3.new(4, 3.2, 5), CFrame.new(center + Vector3.new(halfX, y, z)), stone, Enum.Material.Slate)
	end
end

local function makeTower(parent, center, offset)
	local pos = center + offset
	local tower = part(parent, "CastleTower", Vector3.new(24, 18, 18), CFrame.new(pos + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(92, 96, 101), Enum.Material.Slate)
	tower.Shape = Enum.PartType.Cylinder
	local top = part(parent, "TowerTop", Vector3.new(22, 1.4, 22), CFrame.new(pos + Vector3.new(0, 24.5, 0)), Color3.fromRGB(112, 114, 117), Enum.Material.Slate)
	top.Shape = Enum.PartType.Cylinder
	top.Orientation = Vector3.new(0, 0, 90)
	for angle = 0, 315, 45 do
		local theta = math.rad(angle)
		part(parent, "TowerCrenel", Vector3.new(3.5, 3.2, 3.5), CFrame.new(pos + Vector3.new(math.cos(theta) * 8.5, 26.3, math.sin(theta) * 8.5)), Color3.fromRGB(99, 101, 105), Enum.Material.Slate)
	end
end

local function makeKeep(parent, center)
	local stone = Color3.fromRGB(95, 98, 103)
	local dark = Color3.fromRGB(79, 82, 87)
	local base = center + Vector3.new(0, 0, 20)
	part(parent, "KeepFloor", Vector3.new(54, 1, 42), CFrame.new(base + Vector3.new(0, 0.5, 0)), dark, Enum.Material.Slate)
	part(parent, "KeepBack", Vector3.new(54, 18, 4), CFrame.new(base + Vector3.new(0, 9, 19)), stone, Enum.Material.Slate)
	part(parent, "KeepLeft", Vector3.new(4, 18, 42), CFrame.new(base + Vector3.new(-25, 9, 0)), stone, Enum.Material.Slate)
	part(parent, "KeepRight", Vector3.new(4, 18, 42), CFrame.new(base + Vector3.new(25, 9, 0)), stone, Enum.Material.Slate)
	part(parent, "KeepFrontL", Vector3.new(21, 18, 4), CFrame.new(base + Vector3.new(-16.5, 9, -19)), stone, Enum.Material.Slate)
	part(parent, "KeepFrontR", Vector3.new(21, 18, 4), CFrame.new(base + Vector3.new(16.5, 9, -19)), stone, Enum.Material.Slate)
	local roof = part(parent, "KeepRoof", Vector3.new(56, 2, 44), CFrame.new(base + Vector3.new(0, 19, 0)), Color3.fromRGB(72, 75, 81), Enum.Material.Slate)
	roof:SetAttribute("CameraOccluder", true)
	for x = -23, 23, 9 do part(parent, "KeepCrenel", Vector3.new(4, 3, 4), CFrame.new(base + Vector3.new(x, 21, -20)), stone, Enum.Material.Slate) end
	part(parent, "Throne", Vector3.new(5, 6, 4), CFrame.new(base + Vector3.new(0, 3, 12)), Color3.fromRGB(95, 67, 45), Enum.Material.WoodPlanks)
end

local function addCastleChest(parent, center)
	local chest = part(parent, "CastleSupplyChest", Vector3.new(6, 3.6, 4.5), CFrame.new(center + Vector3.new(0, 1.8, 28)), Color3.fromRGB(117, 75, 40), Enum.Material.WoodPlanks)
	part(parent, "CastleChestLid", Vector3.new(6.3, 0.8, 4.8), chest.CFrame * CFrame.new(0, 2.05, 0), Color3.fromRGB(148, 96, 50), Enum.Material.WoodPlanks)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Search"
	prompt.ObjectText = "Abandoned Castle Supplies"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.7
	prompt.Parent = chest
	local nextLoot = {}
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now < (nextLoot[player.UserId] or 0) then return end
		nextLoot[player.UserId] = now + 240
		local gold = random:NextInteger(35, 90)
		PlayerService.Add(player, { Gold = gold, XP = 18 })
		local pool = { "Bandage", "CookedMeat", "WaterFlask", "Rope", "Cloth", "Herb", "ObsidianShard" }
		local item = pool[random:NextInteger(1, #pool)]
		local amount = item == "ObsidianShard" and 1 or random:NextInteger(1, 3)
		local ok = InventoryService.AddItem(player, item, amount)
		if not ok then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			InventoryService.CreateWorldDrop(root and root.Position or chest.Position, item, amount)
		end
	end)
end

local function buildCastle(center)
	clearNaturalResources(center, 105)
	local castle = Instance.new("Model")
	castle.Name = "AbandonedCastle"
	castle:SetAttribute("Castle", true)
	castle:SetAttribute("GeneratedLandmark", true)
	castle:SetAttribute("LandmarkRadius", 105)
	castle.Parent = world

	local stone = Color3.fromRGB(96, 99, 104)
	local floor = part(castle, "CastleCourtyard", Vector3.new(150, 1, 134), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(88, 88, 84), Enum.Material.Cobblestone)
	floor.CanCollide = true

	part(castle, "NorthWall", Vector3.new(150, 17, 5), CFrame.new(center + Vector3.new(0, 8.5, 64.5)), stone, Enum.Material.Slate)
	part(castle, "WestWall", Vector3.new(5, 17, 134), CFrame.new(center + Vector3.new(-72.5, 8.5, 0)), stone, Enum.Material.Slate)
	part(castle, "EastWall", Vector3.new(5, 17, 134), CFrame.new(center + Vector3.new(72.5, 8.5, 0)), stone, Enum.Material.Slate)
	part(castle, "SouthWallL", Vector3.new(59, 17, 5), CFrame.new(center + Vector3.new(-45.5, 8.5, -64.5)), stone, Enum.Material.Slate)
	part(castle, "SouthWallR", Vector3.new(59, 17, 5), CFrame.new(center + Vector3.new(45.5, 8.5, -64.5)), stone, Enum.Material.Slate)

	makeTower(castle, center, Vector3.new(-70, 0, -62))
	makeTower(castle, center, Vector3.new(70, 0, -62))
	makeTower(castle, center, Vector3.new(-70, 0, 62))
	makeTower(castle, center, Vector3.new(70, 0, 62))
	battlements(castle, center, 72, 64, 18.5)
	makeKeep(castle, center)

	for _, offset in {
		Vector3.new(-13, 0, -51), Vector3.new(13, 0, -51),
		Vector3.new(-55, 0, -40), Vector3.new(55, 0, -40),
		Vector3.new(-55, 0, 36), Vector3.new(55, 0, 36),
	} do torch(castle, center + offset) end

	local gateTop = part(castle, "GateArch", Vector3.new(32, 5, 6), CFrame.new(center + Vector3.new(0, 15.5, -64.5)), Color3.fromRGB(85, 88, 92), Enum.Material.Slate)
	gateTop.CanCollide = true
	local banner = part(castle, "CastleBanner", Vector3.new(10, 8, 0.35), CFrame.new(center + Vector3.new(0, 10, -67.6)), Color3.fromRGB(90, 37, 43), Enum.Material.Fabric, false)
	banner.CanQuery = false

	local signPart = part(castle, "CastleSign", Vector3.new(20, 6, 1), CFrame.new(center + Vector3.new(0, 3.5, -76)), Color3.fromRGB(79, 58, 42), Enum.Material.WoodPlanks)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = signPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "ABANDONED CASTLE\nSEARCH THE KEEP"
	label.TextColor3 = Color3.fromRGB(238, 225, 190)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	addCastleChest(castle, center)
	return castle
end

task.spawn(function()
	-- Let villages, caves, dungeons, Blackwood and the boss arena establish their footprints first.
	task.wait(4)
	local center = chooseCenter()
	if not center then
		warn("[CastleService] No safe non-overlapping castle location was available this server.")
		return
	end
	buildCastle(center)
	print(string.format("[CastleService] Abandoned Castle generated at %.0f, %.0f with landmark spacing checks.", center.X, center.Z))
end)
