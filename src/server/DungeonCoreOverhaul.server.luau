local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local DUNGEON_WIDTH = 160
local DUNGEON_DEPTH = 150
local WALL_HEIGHT = 22
local RESPAWN_SECONDS = 120

local dungeonRecords = {}

local function makePart(parent, name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addNameplate(model, root, title, subtitle, titleColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossNameplate"
	gui.Size = UDim2.fromOffset(240, 66)
	gui.StudsOffset = Vector3.new(0, 11, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 0.62, 0)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = titleColor
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Subtitle"
	sub.Position = UDim2.new(0, 0, 0.62, 0)
	sub.Size = UDim2.new(1, 0, 0.38, 0)
	sub.BackgroundTransparency = 1
	sub.Text = subtitle
	sub.TextColor3 = Color3.fromRGB(235, 235, 235)
	sub.TextStrokeTransparency = 0.35
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.Parent = gui
end

local function addHealthBar(model, root, humanoid)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossHealthBar"
	gui.Size = UDim2.fromOffset(230, 18)
	gui.StudsOffset = Vector3.new(0, 8.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Parent = root

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(35, 35, 39)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(194, 55, 48)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill

	local function update()
		fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)
	end
	humanoid.HealthChanged:Connect(update)
	update()
end

local function nearestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local d = (root.Position - position).Magnitude
			if d < bestDistance then
				best, bestDistance = player, d
			end
		end
	end
	return best, bestDistance
end

local function adjustedDamage(player, amount)
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(1, math.floor(amount * (1 - reduction) + 0.5))
end

local function rewardDrop(position, itemName, amount)
	InventoryService.CreateWorldDrop(position + Vector3.new(math.random(-3, 3), 1.5, math.random(-3, 3)), itemName, amount)
end

local function rewardKill(model, role)
	local position = model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	local attackerId = model:GetAttribute("LastAttackerUserId")
	local attacker = attackerId and Players:GetPlayerByUserId(attackerId)

	if role == "DragonBoss" then
		rewardDrop(position, "DragonScale", math.random(3, 5))
		rewardDrop(position, "ObsidianShard", math.random(2, 4))
		if math.random() < 0.12 then rewardDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.03 then rewardDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 450, XP = 300 }) end
	elseif role == "DemonBoss" then
		rewardDrop(position, "DemonCore", math.random(3, 4))
		rewardDrop(position, "ObsidianShard", math.random(3, 5))
		if math.random() < 0.09 then rewardDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.025 then rewardDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 325, XP = 230 }) end
	else
		rewardDrop(position, "DemonCore", 1)
		if attacker then PlayerService.Add(attacker, { Gold = 55, XP = 40 }) end
	end
end

local function dragonVisual(model, centerCf, scale)
	local dark = Color3.fromRGB(94, 38, 34)
	local red = Color3.fromRGB(146, 55, 44)
	local bone = Color3.fromRGB(226, 207, 157)
	local wing = Color3.fromRGB(65, 30, 39)

	makePart(model, "Torso", Vector3.new(11, 6, 18) * scale, centerCf * CFrame.new(0, 2.5 * scale, 0), dark, Enum.Material.Slate)
	makePart(model, "Head", Vector3.new(7, 5, 7) * scale, centerCf * CFrame.new(0, 5.2 * scale, -10 * scale), red, Enum.Material.Slate)
	makePart(model, "Snout", Vector3.new(5.5, 2.6, 5.5) * scale, centerCf * CFrame.new(0, 4.6 * scale, -15 * scale), red, Enum.Material.Slate)

	for _, side in { -1, 1 } do
		makePart(model, "Eye", Vector3.new(0.75, 0.75, 0.45) * scale, centerCf * CFrame.new(side * 2.1 * scale, 6.3 * scale, -13.4 * scale), Color3.fromRGB(255, 206, 62), Enum.Material.Neon)
		makePart(model, "Horn", Vector3.new(0.8, 3.8, 0.8) * scale, centerCf * CFrame.new(side * 2.4 * scale, 8.7 * scale, -10 * scale) * CFrame.Angles(math.rad(-30), 0, math.rad(side * 16)), bone, Enum.Material.Slate)
		makePart(model, "Wing", Vector3.new(12, 0.7, 11) * scale, centerCf * CFrame.new(side * 10 * scale, 5.2 * scale, 1.5 * scale) * CFrame.Angles(0, 0, math.rad(side * 14)), wing, Enum.Material.Fabric)
		for _, z in { -4, 5 } do
			makePart(model, "Leg", Vector3.new(1.8, 5.3, 1.8) * scale, centerCf * CFrame.new(side * 4.2 * scale, -0.3 * scale, z * scale), dark, Enum.Material.Slate)
			makePart(model, "Foot", Vector3.new(2.7, 1.0, 3.5) * scale, centerCf * CFrame.new(side * 4.2 * scale, -3.0 * scale, (z - 0.6) * scale), red, Enum.Material.Slate)
		end
	end

	for i = 1, 5 do
		local width = math.max(1.1, 4.0 - i * 0.55)
		makePart(model, "Tail", Vector3.new(width, width, 5) * scale, centerCf * CFrame.new(0, 2.0 * scale - i * 0.25, (10 + i * 4.2) * scale), dark, Enum.Material.Slate)
	end
	for z = -5, 10, 3 do
		makePart(model, "Spine", Vector3.new(0.7, 2.2, 1) * scale, centerCf * CFrame.new(0, 6.2 * scale, z * scale), bone, Enum.Material.Slate)
	end
end

local function demonVisual(model, centerCf, scale, boss)
	local purple = boss and Color3.fromRGB(103, 35, 91) or Color3.fromRGB(80, 43, 84)
	local dark = Color3.fromRGB(45, 29, 53)
	local glow = boss and Color3.fromRGB(255, 74, 174) or Color3.fromRGB(221, 83, 188)

	makePart(model, "Torso", Vector3.new(6.5, 8, 5.5) * scale, centerCf * CFrame.new(0, 2.8 * scale, 0), purple, Enum.Material.Slate)
	makePart(model, "Head", Vector3.new(5, 4.5, 4.5) * scale, centerCf * CFrame.new(0, 8.1 * scale, -0.5 * scale), dark, Enum.Material.Slate)
	for _, side in { -1, 1 } do
		makePart(model, "Eye", Vector3.new(0.7, 0.7, 0.35) * scale, centerCf * CFrame.new(side * 1.25 * scale, 8.5 * scale, -2.9 * scale), glow, Enum.Material.Neon)
		makePart(model, "Horn", Vector3.new(0.75, 4.2, 0.75) * scale, centerCf * CFrame.new(side * 1.9 * scale, 11.3 * scale, -0.3 * scale) * CFrame.Angles(0, 0, math.rad(side * 24)), Color3.fromRGB(62, 55, 68), Enum.Material.Slate)
		makePart(model, "Arm", Vector3.new(1.4, 6.5, 1.4) * scale, centerCf * CFrame.new(side * 4.1 * scale, 2.3 * scale, 0), purple, Enum.Material.Slate)
		makePart(model, "Claw", Vector3.new(2, 1.1, 2.4) * scale, centerCf * CFrame.new(side * 4.5 * scale, -1.0 * scale, -0.8 * scale), dark, Enum.Material.Slate)
		makePart(model, "Leg", Vector3.new(1.8, 5.3, 1.8) * scale, centerCf * CFrame.new(side * 1.7 * scale, -3.2 * scale, 0.6 * scale), dark, Enum.Material.Slate)
	end
end

local function clampToDungeon(floor, worldPosition, margin)
	local localPos = floor.CFrame:PointToObjectSpace(worldPosition)
	local halfX = floor.Size.X / 2 - margin
	local halfZ = floor.Size.Z / 2 - margin
	return floor.CFrame:PointToWorldSpace(Vector3.new(
		math.clamp(localPos.X, -halfX, halfX),
		3,
		math.clamp(localPos.Z, -halfZ, halfZ)
	))
end

local function spawnEncounterMob(record, role, offset)
	local dungeon = record.Dungeon
	local floor = record.Floor
	if not dungeon.Parent or not floor.Parent then return nil end

	local isDragon = role == "DragonBoss"
	local isDemonBoss = role == "DemonBoss"
	local isBoss = isDragon or isDemonBoss
	local mobType = isDragon and "Dragon" or "Demon"
	local data
	if isDragon then
		data = { Health = 1700, Damage = 42, Speed = 12, Range = 10, Aggro = 105, Cooldown = 1.5, Scale = 1.15 }
	elseif isDemonBoss then
		data = { Health = 1350, Damage = 36, Speed = 13, Range = 8, Aggro = 95, Cooldown = 1.25, Scale = 1.25 }
	else
		data = { Health = 460, Damage = 24, Speed = 15, Range = 6, Aggro = 88, Cooldown = 1.15, Scale = 0.9 }
	end

	local spawnPos = floor.CFrame:PointToWorldSpace(offset)
	local model = Instance.new("Model")
	model.Name = isDragon and "AncientDragonBoss" or isDemonBoss and "DemonLordBoss" or "AbyssGuard"
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("DungeonMob", true)
	model:SetAttribute("MobType", mobType)
	model:SetAttribute("DungeonRole", role)
	model:SetAttribute("DungeonBoss", isBoss)
	model:SetAttribute("ReadableDungeonVisual", true)
	model.Parent = dungeon

	local root = makePart(model, "HumanoidRootPart", isDragon and Vector3.new(10, 6, 15) or Vector3.new(6, 8, 6), CFrame.new(spawnPos), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1)
	root.CanQuery = true
	model.PrimaryPart = root

	if isDragon then
		dragonVisual(model, root.CFrame, data.Scale)
	else
		demonVisual(model, root.CFrame, data.Scale, isDemonBoss)
	end

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = data.Health
	hum.Health = data.Health
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	if isBoss then
		local title = isDragon and "ANCIENT DRAGON" or "DEMON LORD"
		local subtitle = isDragon and "BOSS • 1700 HP • MYTHIC LOOT" or "BOSS • 1350 HP • DEMON CORES"
		addNameplate(model, root, title, subtitle, isDragon and Color3.fromRGB(255, 163, 88) or Color3.fromRGB(238, 91, 213))
		addHealthBar(model, root, hum)
	end

	record.Live[model] = role
	local lastAttack = 0

	hum.Died:Connect(function()
		if not record.Live[model] then return end
		record.Live[model] = nil
		rewardKill(model, role)
		if isBoss then
			record.NextBossSpawn = os.clock() + RESPAWN_SECONDS
		end
		task.delay(2, function()
			if model.Parent then model:Destroy() end
		end)
	end)

	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			task.wait(0.1)
			local target, distance = nearestPlayer(root.Position, data.Aggro)
			if target then
				local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHum and targetHum.Health > 0 then
					local desired = clampToDungeon(floor, targetRoot.Position, isDragon and 16 or 10)
					local delta = Vector3.new(desired.X - root.Position.X, 0, desired.Z - root.Position.Z)
					if delta.Magnitude > data.Range - 1 then
						local step = math.min(data.Speed * 0.1, math.max(0, delta.Magnitude - data.Range + 1))
						if delta.Magnitude > 0.05 then
							local nextPos = root.Position + delta.Unit * step
							model:PivotTo(CFrame.lookAt(nextPos, nextPos + delta.Unit))
						end
					end
					if distance <= data.Range and os.clock() - lastAttack >= data.Cooldown then
						lastAttack = os.clock()
						targetHum:TakeDamage(adjustedDamage(target, data.Damage))
					end
				end
			else
				local home = floor.CFrame:PointToWorldSpace(offset)
				local delta = Vector3.new(home.X - root.Position.X, 0, home.Z - root.Position.Z)
				if delta.Magnitude > 2 then
					local nextPos = root.Position + delta.Unit * math.min(data.Speed * 0.06, delta.Magnitude)
					model:PivotTo(CFrame.lookAt(nextPos, nextPos + delta.Unit))
				end
			end
		end
	end)

	return model
end

local function resizeDungeon(dungeon)
	local floor = dungeon:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then return nil end
	local center = floor.CFrame.Position
	local isDragon = dungeon:GetAttribute("DungeonType") == "Dragon"
	local wallColor = isDragon and Color3.fromRGB(83, 78, 73) or Color3.fromRGB(64, 57, 72)

	floor.Size = Vector3.new(DUNGEON_WIDTH, 1, DUNGEON_DEPTH)
	floor.CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0))

	local back = dungeon:FindFirstChild("Back")
	local left = dungeon:FindFirstChild("Left")
	local right = dungeon:FindFirstChild("Right")
	local roof = dungeon:FindFirstChild("Roof")
	if back then back.Size = Vector3.new(DUNGEON_WIDTH, WALL_HEIGHT, 5) back.CFrame = CFrame.new(center + Vector3.new(0, WALL_HEIGHT / 2, DUNGEON_DEPTH / 2 - 2.5)) end
	if left then left.Size = Vector3.new(5, WALL_HEIGHT, DUNGEON_DEPTH) left.CFrame = CFrame.new(center + Vector3.new(-DUNGEON_WIDTH / 2 + 2.5, WALL_HEIGHT / 2, 0)) end
	if right then right.Size = Vector3.new(5, WALL_HEIGHT, DUNGEON_DEPTH) right.CFrame = CFrame.new(center + Vector3.new(DUNGEON_WIDTH / 2 - 2.5, WALL_HEIGHT / 2, 0)) end
	if roof then
		roof.Size = Vector3.new(DUNGEON_WIDTH, 3, DUNGEON_DEPTH)
		roof.CFrame = CFrame.new(center + Vector3.new(0, WALL_HEIGHT + 2, 0))
		roof:SetAttribute("CameraOccluder", true)
	end

	local pillars = {}
	for _, child in dungeon:GetChildren() do
		if child:IsA("BasePart") and child.Name == "EntrancePillar" then table.insert(pillars, child) end
	end
	for i, pillar in pillars do
		local side = i == 1 and -1 or 1
		pillar.Size = Vector3.new(14, WALL_HEIGHT, 10)
		pillar.CFrame = CFrame.new(center + Vector3.new(side * 58, WALL_HEIGHT / 2, -DUNGEON_DEPTH / 2 + 3))
	end

	-- Add side entrance walls so the larger room still reads as a dungeon with one broad doorway.
	for _, name in { "OverhaulFrontL", "OverhaulFrontR" } do
		local old = dungeon:FindFirstChild(name)
		if old then old:Destroy() end
	end
	makePart(dungeon, "OverhaulFrontL", Vector3.new(46, WALL_HEIGHT, 5), CFrame.new(center + Vector3.new(-57, WALL_HEIGHT / 2, -DUNGEON_DEPTH / 2 + 2.5)), wallColor, Enum.Material.Rock)
	makePart(dungeon, "OverhaulFrontR", Vector3.new(46, WALL_HEIGHT, 5), CFrame.new(center + Vector3.new(57, WALL_HEIGHT / 2, -DUNGEON_DEPTH / 2 + 2.5)), wallColor, Enum.Material.Rock)

	-- Spread existing mine nodes deeper into the expanded room.
	local mines = {}
	for _, child in dungeon:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("MineKind") then table.insert(mines, child) end
	end
	for i, mine in mines do
		local x = (#mines == 1) and 0 or ((i - 1) / math.max(1, #mines - 1) * 100 - 50)
		mine:PivotTo(CFrame.new(center + Vector3.new(x, 0, 48)))
	end

	-- Move an already-created cache to the new back section.
	local cache = dungeon:FindFirstChild("DungeonLootCache")
	if cache and cache:IsA("Model") and cache.PrimaryPart then
		cache:PivotTo(CFrame.new(center + Vector3.new(0, 2.2, 60)))
	end
	dungeon.ChildAdded:Connect(function(child)
		if child.Name == "DungeonLootCache" and child:IsA("Model") then
			task.delay(0.1, function()
				if child.Parent and child.PrimaryPart then child:PivotTo(CFrame.new(center + Vector3.new(0, 2.2, 60))) end
			end)
		end
	end)

	return floor
end

local function clearOldDungeonMobs(dungeon)
	for _, descendant in dungeon:GetChildren() do
		if descendant:IsA("Model") and descendant:GetAttribute("DungeonMob") == true then
			descendant:Destroy()
		end
	end
end

local function setupDungeon(dungeon)
	if dungeonRecords[dungeon] then return end
	local floor = resizeDungeon(dungeon)
	if not floor then return end
	clearOldDungeonMobs(dungeon)

	local kind = dungeon:GetAttribute("DungeonType")
	local record = {
		Dungeon = dungeon,
		Floor = floor,
		Kind = kind,
		Live = {},
		NextBossSpawn = 0,
	}
	dungeonRecords[dungeon] = record

	if kind == "Dragon" then
		spawnEncounterMob(record, "DragonBoss", Vector3.new(0, 3, 18))
	else
		spawnEncounterMob(record, "DemonBoss", Vector3.new(0, 3, 20))
		spawnEncounterMob(record, "DemonGuard", Vector3.new(-32, 3, 2))
		spawnEncounterMob(record, "DemonGuard", Vector3.new(32, 3, 2))
	end

	print(string.format("[DungeonCoreOverhaul] %s expanded to %dx%d with authoritative boss encounter.", dungeon.Name, DUNGEON_WIDTH, DUNGEON_DEPTH))
end

local function countRole(record, role)
	local count = 0
	for model, modelRole in record.Live do
		if modelRole == role and model.Parent then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then count += 1 end
		end
	end
	return count
end

-- Wait until CaveDungeonService has generated both dungeon shells.
task.spawn(function()
	for _ = 1, 60 do
		local found = 0
		for _, child in world:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("Dungeon") == true then
				found += 1
				setupDungeon(child)
			end
		end
		if found >= 2 then break end
		task.wait(0.25)
	end

	while true do
		task.wait(2)
		local now = os.clock()
		for dungeon, record in dungeonRecords do
			if not dungeon.Parent then
				dungeonRecords[dungeon] = nil
				continue
			end
			if record.Kind == "Dragon" then
				if countRole(record, "DragonBoss") == 0 and now >= record.NextBossSpawn then
					spawnEncounterMob(record, "DragonBoss", Vector3.new(0, 3, 18))
				end
			else
				if countRole(record, "DemonBoss") == 0 and now >= record.NextBossSpawn then
					spawnEncounterMob(record, "DemonBoss", Vector3.new(0, 3, 20))
				end
				-- Guards respawn faster, but never block the boss reward window forever.
				if countRole(record, "DemonGuard") < 2 and countRole(record, "DemonBoss") > 0 then
					if countRole(record, "DemonGuard") == 0 then
						spawnEncounterMob(record, "DemonGuard", Vector3.new(-32, 3, 2))
						spawnEncounterMob(record, "DemonGuard", Vector3.new(32, 3, 2))
					end
				end
			end
		end
	end
end)
