local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local function part(parent, name, size, cf, color, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Anchored = anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(root, child)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = child
	w.Parent = child
end

local function sign(parent, position, text)
	local board = part(parent, "Sign", Vector3.new(18, 7, 1), CFrame.new(position), Color3.fromRGB(80, 58, 41), Enum.Material.WoodPlanks)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(242, 226, 180)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
end

local function giveInventoryItem(player, itemName, amount, position)
	local ok = InventoryService.AddItem(player, itemName, amount)
	if not ok then InventoryService.CreateWorldDrop(position, itemName, amount) end
end

local function makeMineNode(parent, position, kind)
	local model = Instance.new("Model")
	model.Name = `${kind}Deposit`
	model:SetAttribute("MineKind", kind)
	model:SetAttribute("MineHealth", kind == "Obsidian" and 8 or 5)
	model:SetAttribute("MineMaxHealth", kind == "Obsidian" and 8 or 5)
	model:SetAttribute("MineAlive", true)
	model.Parent = parent
	local color = kind == "Sand" and Color3.fromRGB(211, 181, 116) or kind == "Obsidian" and Color3.fromRGB(54, 45, 66) or Color3.fromRGB(114, 118, 126)
	local material = kind == "Sand" and Enum.Material.Sand or kind == "Obsidian" and Enum.Material.Glass or Enum.Material.Slate
	local rock = part(model, "Deposit", Vector3.new(6, 5, 6), CFrame.new(position + Vector3.new(0, 2.5, 0)), color, material)
	rock.Shape = Enum.PartType.Ball
	model.PrimaryPart = rock
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Mine"
	prompt.ObjectText = kind == "Sand" and "Fine Sand" or kind == "Obsidian" and "Obsidian Vein" or "Cave Stone"
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = kind == "Obsidian" and 0.75 or 0.45
	prompt.Parent = rock
	local nextMineByPlayer = {}

	prompt.Triggered:Connect(function(player)
		if model:GetAttribute("MineAlive") ~= true then return end
		local now = os.clock()
		if now < (nextMineByPlayer[player.UserId] or 0) then return end
		nextMineByPlayer[player.UserId] = now + 0.35
		local primary = PlayerService.GetPrimaryWeapon(player)
		local miningBonus = (primary == "Pickaxe" or primary == "BattleAxe") and 1 or 0
		local health = (model:GetAttribute("MineHealth") or 1) - 1
		model:SetAttribute("MineHealth", health)

		if kind == "Sand" then
			giveInventoryItem(player, "Sand", 1 + miningBonus, rock.Position)
		elseif kind == "Obsidian" then
			if math.random() < 0.42 + miningBonus * 0.12 then giveInventoryItem(player, "ObsidianShard", 1, rock.Position) end
		else
			PlayerService.Add(player, { Stone = 2 + miningBonus, XP = 2 })
		end

		if health <= 0 then
			model:SetAttribute("MineAlive", false)
			prompt.Enabled = false
			rock.Transparency = 0.82
			rock.CanCollide = false
			task.delay(kind == "Obsidian" and 80 or 45, function()
				if not model.Parent then return end
				model:SetAttribute("MineHealth", model:GetAttribute("MineMaxHealth"))
				model:SetAttribute("MineAlive", true)
				rock.Transparency = 0
				rock.CanCollide = true
				prompt.Enabled = true
			end)
		end
	end)
end

local function makeCave(name, center, mineKinds)
	local cave = Instance.new("Model")
	cave.Name = name
	cave:SetAttribute("Cave", true)
	cave.Parent = world
	local stone = Color3.fromRGB(89, 92, 98)
	part(cave, "Floor", Vector3.new(46, 1, 54), CFrame.new(center + Vector3.new(0, 0.3, 0)), Color3.fromRGB(79, 75, 69), Enum.Material.Slate)
	part(cave, "LeftWall", Vector3.new(7, 13, 54), CFrame.new(center + Vector3.new(-22, 6.5, 0)), stone, Enum.Material.Rock)
	part(cave, "RightWall", Vector3.new(7, 13, 54), CFrame.new(center + Vector3.new(22, 6.5, 0)), stone, Enum.Material.Rock)
	part(cave, "BackWall", Vector3.new(46, 13, 7), CFrame.new(center + Vector3.new(0, 6.5, 25)), stone, Enum.Material.Rock)
	part(cave, "Roof", Vector3.new(46, 3, 54), CFrame.new(center + Vector3.new(0, 14, 0)), stone, Enum.Material.Rock)
	for _, x in { -18, 18 } do part(cave, "EntranceRock", Vector3.new(8, 12, 8), CFrame.new(center + Vector3.new(x, 6, -26)), stone, Enum.Material.Rock) end
	sign(cave, center + Vector3.new(0, 3.5, -31), `${name:upper()}\nMINE SAND • STONE • OBSIDIAN`)
	for i, kind in mineKinds do
		local x = ((i - 1) % 3 - 1) * 12
		local z = math.floor((i - 1) / 3) * 13 - 2
		makeMineNode(cave, center + Vector3.new(x, 0, z), kind)
	end
end

local dungeonMobs = {}

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

local function armorAdjustedDamage(player, damage)
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(1, math.floor(damage * (1 - reduction) + 0.5))
end

local function dungeonLoot(model, mobType)
	local position = model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	local attackerId = model:GetAttribute("LastAttackerUserId")
	local attacker = attackerId and Players:GetPlayerByUserId(attackerId)
	if mobType == "Dragon" then
		for _ = 1, math.random(2, 4) do InventoryService.CreateWorldDrop(position, "DragonScale", 1) end
		if math.random() < 0.10 then InventoryService.CreateWorldDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.025 then InventoryService.CreateWorldDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 325, XP = 220 }) end
	else
		for _ = 1, math.random(1, 2) do InventoryService.CreateWorldDrop(position, "DemonCore", 1) end
		InventoryService.CreateWorldDrop(position, "ObsidianShard", math.random(2, 5))
		if math.random() < 0.055 then InventoryService.CreateWorldDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.012 then InventoryService.CreateWorldDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 140, XP = 95 }) end
	end
end

local function makeDragonVisual(model, root)
	local body = part(model, "DragonBody", Vector3.new(9, 5, 12), root.CFrame * CFrame.new(0, 1.2, 0), Color3.fromRGB(91, 49, 45), Enum.Material.Slate, false)
	body.CanCollide = false body.Massless = true weld(root, body)
	local head = part(model, "DragonHead", Vector3.new(5, 4.5, 5.5), root.CFrame * CFrame.new(0, 3.5, -7), Color3.fromRGB(117, 58, 49), Enum.Material.Slate, false)
	head.CanCollide = false head.Massless = true weld(root, head)
	for _, side in { -1, 1 } do
		local wing = part(model, "Wing", Vector3.new(10, 0.5, 7), root.CFrame * CFrame.new(side * 7, 3.2, 1) * CFrame.Angles(0, 0, math.rad(side * 18)), Color3.fromRGB(76, 40, 45), Enum.Material.Fabric, false)
		wing.CanCollide = false wing.Massless = true weld(root, wing)
		local horn = part(model, "Horn", Vector3.new(0.7, 3, 0.7), root.CFrame * CFrame.new(side * 1.5, 6, -7.6) * CFrame.Angles(math.rad(-30), 0, math.rad(side * 12)), Color3.fromRGB(201, 185, 145), Enum.Material.Slate, false)
		horn.CanCollide = false horn.Massless = true weld(root, horn)
	end
end

local function makeDemonVisual(model, root)
	local body = part(model, "DemonBody", Vector3.new(5, 6, 4), root.CFrame * CFrame.new(0, 1.2, 0), Color3.fromRGB(72, 43, 76), Enum.Material.Slate, false)
	body.CanCollide = false body.Massless = true weld(root, body)
	local head = part(model, "DemonHead", Vector3.new(4, 4, 4), root.CFrame * CFrame.new(0, 5.5, -0.7), Color3.fromRGB(94, 48, 67), Enum.Material.Slate, false)
	head.Shape = Enum.PartType.Ball head.CanCollide = false head.Massless = true weld(root, head)
	for _, side in { -1, 1 } do
		local horn = part(model, "Horn", Vector3.new(0.55, 3.3, 0.55), root.CFrame * CFrame.new(side * 1.4, 8, -0.5) * CFrame.Angles(0, 0, math.rad(side * 20)), Color3.fromRGB(55, 49, 57), Enum.Material.Slate, false)
		horn.CanCollide = false horn.Massless = true weld(root, horn)
	end
end

local function spawnDungeonMob(parent, mobType, home)
	local data = mobType == "Dragon"
		and { Health = 900, Damage = 36, Speed = 12, Range = 8, Aggro = 78, Cooldown = 1.55, Respawn = 150 }
		or { Health = 480, Damage = 29, Speed = 15, Range = 6, Aggro = 68, Cooldown = 1.15, Respawn = 95 }
	local model = Instance.new("Model")
	model.Name = mobType
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("DungeonMob", true)
	model:SetAttribute("MobType", mobType)
	model.Parent = parent
	local root = part(model, "HumanoidRootPart", mobType == "Dragon" and Vector3.new(6, 4, 8) or Vector3.new(4, 5, 4), CFrame.new(home + Vector3.new(0, 3, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false)
	root.Transparency = 1
	root.CanCollide = true
	model.PrimaryPart = root
	pcall(function() root:SetNetworkOwner(nil) end)
	if mobType == "Dragon" then makeDragonVisual(model, root) else makeDemonVisual(model, root) end
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = data.Health
	hum.Health = data.Health
	hum.WalkSpeed = data.Speed
	hum.JumpPower = 0
	hum.DisplayName = mobType == "Dragon" and "Dungeon Dragon" or "Abyss Demon"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model
	dungeonMobs[model] = true
	local lastAttack = 0

	hum.Died:Connect(function()
		dungeonMobs[model] = nil
		dungeonLoot(model, mobType)
		task.delay(2, function() if model.Parent then model:Destroy() end end)
		task.delay(data.Respawn, function() if parent.Parent then spawnDungeonMob(parent, mobType, home) end end)
	end)

	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			task.wait(0.3)
			local target, distance = nearestPlayer(root.Position, data.Aggro)
			if target then
				local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHum and targetHum.Health > 0 then
					hum:MoveTo(targetRoot.Position)
					if distance <= data.Range and os.clock() - lastAttack >= data.Cooldown then
						lastAttack = os.clock()
						targetHum:TakeDamage(armorAdjustedDamage(target, data.Damage))
					end
				end
			else
				local delta = Vector3.new(root.Position.X - home.X, 0, root.Position.Z - home.Z)
				if delta.Magnitude > 25 then hum:MoveTo(home + Vector3.new(0, 2, 0)) end
			end
		end
	end)
end

local function makeDungeon(name, center, mobType, mobCount)
	local dungeon = Instance.new("Model")
	dungeon.Name = name
	dungeon:SetAttribute("Dungeon", true)
	dungeon:SetAttribute("DungeonType", mobType)
	dungeon.Parent = world
	local floorColor = mobType == "Dragon" and Color3.fromRGB(76, 62, 58) or Color3.fromRGB(58, 48, 67)
	local wallColor = mobType == "Dragon" and Color3.fromRGB(83, 78, 73) or Color3.fromRGB(64, 57, 72)
	part(dungeon, "Floor", Vector3.new(94, 1, 82), CFrame.new(center + Vector3.new(0, 0.3, 0)), floorColor, Enum.Material.Slate)
	part(dungeon, "Back", Vector3.new(94, 16, 5), CFrame.new(center + Vector3.new(0, 8, 39)), wallColor, Enum.Material.Rock)
	part(dungeon, "Left", Vector3.new(5, 16, 82), CFrame.new(center + Vector3.new(-45, 8, 0)), wallColor, Enum.Material.Rock)
	part(dungeon, "Right", Vector3.new(5, 16, 82), CFrame.new(center + Vector3.new(45, 8, 0)), wallColor, Enum.Material.Rock)
	part(dungeon, "Roof", Vector3.new(94, 3, 82), CFrame.new(center + Vector3.new(0, 17, 0)), wallColor, Enum.Material.Rock)
	for _, x in { -35, 35 } do part(dungeon, "EntrancePillar", Vector3.new(12, 16, 8), CFrame.new(center + Vector3.new(x, 8, -39)), wallColor, Enum.Material.Rock) end
	local entranceText = mobType == "Dragon"
		and "DRAGON DUNGEON\nSCALES • RARE CLOAK/RELIC\nMYTHIC ARMOR MATERIALS"
		or "DEMON VAULT\nCORES • OBSIDIAN • RARE RELICS\nENDGAME CRAFTING"
	sign(dungeon, center + Vector3.new(0, 4, -45), entranceText)

	for i = 1, mobCount do
		local x = (i - (mobCount + 1) / 2) * 16
		local z = 8 + (i % 2) * 10
		spawnDungeonMob(dungeon, mobType, center + Vector3.new(x, 0, z))
	end
	if mobType == "Dragon" then
		makeMineNode(dungeon, center + Vector3.new(-30, 0, 25), "Obsidian")
		makeMineNode(dungeon, center + Vector3.new(30, 0, 25), "Obsidian")
	else
		for _, x in { -28, 0, 28 } do makeMineNode(dungeon, center + Vector3.new(x, 0, 27), "Obsidian") end
	end
end

makeCave("Snow Cave", Vector3.new(-470, 0, -300), { "Stone", "Stone", "Obsidian", "Stone" })
makeCave("Grass Cave", Vector3.new(-70, 0, -470), { "Stone", "Sand", "Stone", "Sand", "Obsidian" })
makeCave("Desert Cave", Vector3.new(430, 0, -300), { "Sand", "Sand", "Stone", "Sand", "Obsidian", "Sand" })
makeDungeon("DragonDungeon", Vector3.new(-480, 0, 475), "Dragon", 1)
makeDungeon("DemonDungeon", Vector3.new(480, 0, 475), "Demon", 3)
