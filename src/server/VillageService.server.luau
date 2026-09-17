local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local openTrade = remotes:FindFirstChild("OpenVillageTrade") or Instance.new("RemoteEvent")
openTrade.Name = "OpenVillageTrade"
openTrade.Parent = remotes
local tradeAction = remotes:FindFirstChild("VillageTrade") or Instance.new("RemoteEvent")
tradeAction.Name = "VillageTrade"
tradeAction.Parent = remotes
local tradeResult = remotes:FindFirstChild("VillageTradeResult") or Instance.new("RemoteEvent")
tradeResult.Name = "VillageTradeResult"
tradeResult.Parent = remotes

local villagerRoles = {}

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function clearResources(center, radius)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not arena then return end
	for _, model in arena:GetChildren() do
		if model:IsA("Model") and model.PrimaryPart and model:GetAttribute("Resource") then
			local a = Vector3.new(model.PrimaryPart.Position.X, 0, model.PrimaryPart.Position.Z)
			local b = Vector3.new(center.X, 0, center.Z)
			if (a - b).Magnitude < radius then model:Destroy() end
		end
	end
end

local function makeHut(parent, center, offset, color)
	local pos = center + offset
	part(parent, "HutFloor", Vector3.new(14, 1, 12), CFrame.new(pos + Vector3.new(0, 0.5, 0)), color, Enum.Material.WoodPlanks)
	part(parent, "Back", Vector3.new(14, 7, 1), CFrame.new(pos + Vector3.new(0, 4, 5.5)), color, Enum.Material.WoodPlanks)
	part(parent, "Left", Vector3.new(1, 7, 11), CFrame.new(pos + Vector3.new(-6.5, 4, 0)), color, Enum.Material.WoodPlanks)
	part(parent, "Right", Vector3.new(1, 7, 11), CFrame.new(pos + Vector3.new(6.5, 4, 0)), color, Enum.Material.WoodPlanks)
	local roof = part(parent, "Roof", Vector3.new(15, 1, 13), CFrame.new(pos + Vector3.new(0, 8, 0)), color:Lerp(Color3.new(0, 0, 0), 0.18), Enum.Material.WoodPlanks)
	roof.CanCollide = true
end

local function makeTorch(parent, position)
	local pole = part(parent, "VillageTorchPole", Vector3.new(0.45, 5, 0.45), CFrame.new(position + Vector3.new(0, 2.5, 0)), Color3.fromRGB(88, 59, 37), Enum.Material.Wood)
	local flame = part(parent, "VillageTorchFlame", Vector3.new(0.9, 0.9, 0.9), CFrame.new(position + Vector3.new(0, 5.35, 0)), Color3.fromRGB(255, 166, 55), Enum.Material.Neon)
	flame.Shape = Enum.PartType.Ball
	flame.CanCollide = false
	flame.CanQuery = false
	local light = Instance.new("PointLight")
	light.Range = 24
	light.Brightness = 2.8
	light.Shadows = true
	light.Parent = flame
	pole.CanCollide = true
end

local function makeFarm(parent, center, offset)
	local farm = Instance.new("Model")
	farm.Name = "VillageFarm"
	farm:SetAttribute("VillageFarm", true)
	farm:SetAttribute("HarvestReady", true)
	farm.Parent = parent
	local origin = center + offset
	local soil = part(farm, "Soil", Vector3.new(18, 0.6, 13), CFrame.new(origin + Vector3.new(0, 0.3, 0)), Color3.fromRGB(88, 60, 38), Enum.Material.Ground)
	farm.PrimaryPart = soil
	local crops = {}
	for x = -6, 6, 3 do
		for z = -4, 4, 2 do
			local stalk = part(farm, "Wheat", Vector3.new(0.32, 2.4, 0.32), CFrame.new(origin + Vector3.new(x, 1.5, z)), Color3.fromRGB(222, 187, 65), Enum.Material.Grass)
			stalk.CanCollide = false
			stalk.CanQuery = false
			table.insert(crops, stalk)
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Harvest"
	prompt.ObjectText = "Village Wheat"
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = 0.35
	prompt.Parent = soil
	prompt.Triggered:Connect(function(player)
		if farm:GetAttribute("HarvestReady") ~= true then return end
		farm:SetAttribute("HarvestReady", false)
		prompt.Enabled = false
		for _, crop in crops do crop.Transparency = 0.72 end
		local rewards = { Wheat = 4, WheatSeeds = 1 }
		for itemName, amount in rewards do
			local ok = InventoryService.AddItem(player, itemName, amount)
			if not ok then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				InventoryService.CreateWorldDrop(root and root.Position or origin, itemName, amount)
			end
		end
		task.delay(75, function()
			if not farm.Parent then return end
			farm:SetAttribute("HarvestReady", true)
			prompt.Enabled = true
			for _, crop in crops do if crop.Parent then crop.Transparency = 0 end end
		end)
	end)
end

local roleColors = {
	Provisioner = Color3.fromRGB(194, 151, 82),
	Herbalist = Color3.fromRGB(91, 156, 100),
	Hunter = Color3.fromRGB(128, 94, 70),
	Armorer = Color3.fromRGB(97, 104, 116),
	Collector = Color3.fromRGB(105, 73, 130),
}

local function makeVillager(parent, center, offset, role)
	local model = Instance.new("Model")
	model.Name = `{role}Villager`
	model.Parent = parent
	local base = part(model, "Root", Vector3.new(2.4, 3.5, 1.8), CFrame.new(center + offset + Vector3.new(0, 1.75, 0)), roleColors[role] or Color3.fromRGB(130, 110, 90), Enum.Material.SmoothPlastic)
	model.PrimaryPart = base
	base.CanCollide = true
	local head = part(model, "Head", Vector3.new(2, 2, 2), CFrame.new(center + offset + Vector3.new(0, 4.4, 0)), Color3.fromRGB(222, 188, 148), Enum.Material.SmoothPlastic)
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Trade"
	prompt.ObjectText = `{role} Villager`
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.15
	prompt.Parent = base
	villagerRoles[model] = role
	prompt.Triggered:Connect(function(player)
		openTrade:FireClient(player, model, role, ExpansionData.VillageTrades[role])
	end)
	return model
end

local function makeVillage(biome, center, options)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not arena then return end
	clearResources(center, 52)
	local village = Instance.new("Model")
	village.Name = `{biome}Village`
	village:SetAttribute("VillageBiome", biome)
	village:SetAttribute("HasFarm", options.Farm == true)
	village:SetAttribute("HasTorches", options.Torches == true)
	village.Parent = arena

	local groundColor = biome == "Snow" and Color3.fromRGB(191, 202, 205) or (biome == "Desert" and Color3.fromRGB(181, 151, 101) or Color3.fromRGB(100, 143, 78))
	local woodColor = biome == "Snow" and Color3.fromRGB(112, 91, 73) or Color3.fromRGB(127, 88, 54)
	local square = part(village, "VillageSquare", Vector3.new(54, 0.4, 48), CFrame.new(center + Vector3.new(0, 0.2, 0)), groundColor, biome == "Desert" and Enum.Material.Sand or Enum.Material.Ground)
	square.CanCollide = true
	makeHut(village, center, Vector3.new(-17, 0, 11), woodColor)
	makeHut(village, center, Vector3.new(17, 0, 11), woodColor)

	local well = part(village, "Well", Vector3.new(7, 2, 7), CFrame.new(center + Vector3.new(0, 1, -12)), Color3.fromRGB(111, 112, 116), Enum.Material.Slate)
	well.Shape = Enum.PartType.Cylinder
	well.Orientation = Vector3.new(0, 0, 90)

	if options.Farm then makeFarm(village, center, Vector3.new(0, 0, 23)) end
	if options.Torches then
		for _, offset in { Vector3.new(-23, 0, -18), Vector3.new(23, 0, -18), Vector3.new(-23, 0, 18), Vector3.new(23, 0, 18) } do makeTorch(village, center + offset) end
	end

	local secondRole = biome == "Grass" and "Herbalist" or "Hunter"
	local thirdRole = math.random() < 0.55 and "Armorer" or "Collector"
	makeVillager(village, center, Vector3.new(-9, 0, -2), "Provisioner")
	makeVillager(village, center, Vector3.new(0, 0, -2), secondRole)
	makeVillager(village, center, Vector3.new(9, 0, -2), thirdRole)
end

local function canAffordTrade(player, trade)
	local profile = PlayerService.Get(player)
	if not profile then return false, "Profile not ready." end
	local take = trade.Take or {}
	if take.Gold and (profile.Gold or 0) < take.Gold then return false, `Need {take.Gold} gold.` end
	if take.Items and not InventoryService.HasItems(player, take.Items) then return false, "Missing required trade items." end
	for itemName, amount in (trade.Give and trade.Give.Items or {}) do
		if not InventoryService.CanAdd(player, itemName, amount) then return false, "Your 10-slot bag is too full." end
	end
	return true
end

local function executeTrade(player, villager, index)
	local role = villagerRoles[villager]
	if not role or not villager.Parent or not villager.PrimaryPart then return false, "That trader is unavailable." end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - villager.PrimaryPart.Position).Magnitude > 15 then return false, "Move closer to the villager." end
	local trade = ExpansionData.VillageTrades[role] and ExpansionData.VillageTrades[role][index]
	if not trade then return false, "Unknown trade." end
	local okay, reason = canAffordTrade(player, trade)
	if not okay then return false, reason end
	local take = trade.Take or {}
	if take.Gold then PlayerService.Add(player, { Gold = -take.Gold }) end
	for itemName, amount in take.Items or {} do InventoryService.RemoveItem(player, itemName, amount, true) end
	local give = trade.Give or {}
	if give.Gold then PlayerService.Add(player, { Gold = give.Gold }) end
	for itemName, amount in give.Items or {} do InventoryService.AddItem(player, itemName, amount, true) end
	if next(give.Items or {}) or next(take.Items or {}) then InventoryService.Changed:Fire(player, InventoryService.GetPublic(player)) end
	PlayerService.Save(player)
	return true, `Trade complete: {trade.Label}`
end

tradeAction.OnServerEvent:Connect(function(player, villager, index)
	if typeof(villager) ~= "Instance" or type(index) ~= "number" then return end
	local ok, message = executeTrade(player, villager, math.floor(index))
	tradeResult:FireClient(player, ok, message)
end)

local function shuffledOptions()
	local options = {
		{ Farm = true, Torches = true },
		{ Farm = false, Torches = true },
		{ Farm = true, Torches = false },
	}
	for i = #options, 2, -1 do
		local j = math.random(1, i)
		options[i], options[j] = options[j], options[i]
	end
	return options
end

task.spawn(function()
	local arena = Workspace:WaitForChild("SurvivalArena", 15)
	if not arena then return end
	task.wait(0.5)
	local signSnow = math.random() < 0.5 and -1 or 1
	local signGrass = math.random() < 0.5 and -1 or 1
	local signDesert = math.random() < 0.5 and -1 or 1
	local options = shuffledOptions()
	makeVillage("Snow", Vector3.new(-390, 0, 350 * signSnow), options[1])
	makeVillage("Grass", Vector3.new(math.random(-90, 90), 0, 430 * signGrass), options[2])
	makeVillage("Desert", Vector3.new(390, 0, 350 * signDesert), options[3])
end)
