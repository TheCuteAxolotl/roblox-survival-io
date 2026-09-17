local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local KitData = require(ReplicatedStorage.Shared.KitData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)
local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

InventoryService.Init()

local NEED_TICK_SECONDS = 6
local HUNGER_DRAIN_PER_TICK = 0 -- V3: food is healing/crafting, not a chore meter
local THIRST_DRAIN_PER_TICK = 0 -- V3: exploration is no longer interrupted by thirst upkeep
local WATER_REGEN_PER_SECOND = 1.8

local structureCatalog = {
	Workbench = { Label = "Workbench", Health = 180 },
	Chest = { Label = "Chest", Health = 150 },
	FarmPlot = { Label = "Farm Plot", Health = 100 },
	SurvivalCampfire = { Label = "Campfire", Health = 110 },
	SurvivalSpikeTrap = { Label = "Spike Trap", Health = 85 },
	WebTrap = { Label = "Web Trap", Health = 70 },
	Torch = { Label = "Torch", Health = 35 },
	Bed = { Label = "Bed", Health = 120 },
}

for name, data in structureCatalog do
	ItemData.Items[name] = ItemData.Items[name] or { Category = "Build", Label = data.Label, Health = data.Health, Cost = {} }
end

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local survivalAction = remotes:FindFirstChild("SurvivalAction") or Instance.new("RemoteEvent")
survivalAction.Name = "SurvivalAction"
survivalAction.Parent = remotes
local survivalState = remotes:FindFirstChild("SurvivalState") or Instance.new("RemoteEvent")
survivalState.Name = "SurvivalState"
survivalState.Parent = remotes
local getSurvivalState = remotes:FindFirstChild("GetSurvivalState") or Instance.new("RemoteFunction")
getSurvivalState.Name = "GetSurvivalState"
getSurvivalState.Parent = remotes
local nutritionEvent = script.Parent:FindFirstChild("SurvivalNutrition") or Instance.new("BindableEvent")
nutritionEvent.Name = "SurvivalNutrition"
nutritionEvent.Parent = script.Parent

local needs = {}
local chestContents = {}
local chestModels = {}
local waterCooldown = {}
local nextNeedTick = {}
local nextStatePush = {}
local bedByUser = {}
local puddles = {}
local kitGrantedThisSession = {}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, inner in value do result[copy(key)] = copy(inner) end
	return result
end

local function newNeedState()
	return { Hunger = 100, Thirst = 100, Buffs = { SpeedUntil = 0, FortifyUntil = 0, NoNeedsUntil = 0, ColdResistUntil = 0 } }
end

local function playerRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function biomeAt(position)
	if position.X < -Config.BiomeSplit then return "Snow" end
	if position.X > Config.BiomeSplit then return "Desert" end
	return "Grass"
end

local function sendState(player, message, extra)
	if not player.Parent then return end
	local state = needs[player] or newNeedState()
	local root = playerRoot(player)
	local profile = PlayerService.Get(player)
	local payload = {
		Hunger = state.Hunger,
		Thirst = state.Thirst,
		Buffs = copy(state.Buffs),
		Inventory = InventoryService.GetPublic(player),
		Gold = profile and math.floor(profile.Gold or 0) or 0,
		Biome = root and biomeAt(root.Position) or "Grass",
		OwnedKits = profile and copy(profile.OwnedKits or {}) or {},
		EquippedKit = profile and profile.EquippedKit or nil,
		EquippedArmor = player:GetAttribute("EquippedArmorItem"),
		EquippedCloak = player:GetAttribute("EquippedCloakItem"),
		Message = message,
	}
	if type(extra) == "table" then for key, value in extra do payload[key] = value end end
	survivalState:FireClient(player, payload)
end

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function tagPlayerBuild(model)
	for _, descendant in model:GetDescendants() do if descendant:IsA("BasePart") then CollectionService:AddTag(descendant, "PlayerBuild") end end
end

local function nearbyStructure(player, structureName, maxDistance)
	local root = playerRoot(player)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not root or not arena then return nil end
	local nearest, nearestDistance = nil, maxDistance or 18
	for _, model in arena:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("SurvivalStructure") == structureName and model.PrimaryPart then
			local distance = (root.Position - model.PrimaryPart.Position).Magnitude
			if distance <= nearestDistance then nearest, nearestDistance = model, distance end
		end
	end
	return nearest
end

local function placementClear(player, position, size)
	local half = Config.WorldSize / 2
	if math.abs(position.X) > half - 8 or math.abs(position.Z) > half - 8 then return false, "Too close to the edge of the map." end
	if math.abs(position.Z) < Config.RiverHalfWidth + 5 then return false, "You cannot place that in the river." end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	for _, hit in Workspace:GetPartBoundsInBox(CFrame.new(position + Vector3.new(0, size.Y / 2, 0)), size + Vector3.new(0.6, 0.6, 0.6), params) do
		-- Villages are intentionally not blocked: players may build inside village limits.
		if CollectionService:HasTag(hit, "PlayerBuild") or CollectionService:HasTag(hit, "ResourceCore") then return false, "That spot is blocked." end
	end
	return true
end

local function attachCraftPrompt(model, station)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Craft"
	prompt.ObjectText = station == "Campfire" and "Campfire" or "Workbench"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.15
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player) sendState(player, nil, { OpenCrafting = station }) end)
end

local function chestPublic(id) return copy(chestContents[id] or {}) end

local function attachChestPrompt(model, id)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Chest"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.15
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if model.Parent then sendState(player, nil, { OpenChest = { Id = id, Slots = chestPublic(id) } }) end
	end)
end

local function createCropVisual(plot)
	for _, child in plot:GetChildren() do if child:GetAttribute("CropVisual") then child:Destroy() end end
	for i = -1, 1 do
		local stalk = part(plot, `Wheat{i}`, Vector3.new(0.35, 2.5, 0.35), plot.PrimaryPart.CFrame * CFrame.new(i * 1.2, 1.45, 0), Color3.fromRGB(160, 179, 70), Enum.Material.Grass)
		stalk.CanCollide = false
		stalk:SetAttribute("CropVisual", true)
	end
end

local function setPlotPrompt(plot)
	local prompt = plot.PrimaryPart and plot.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end
	if plot:GetAttribute("CropReady") then prompt.ActionText, prompt.ObjectText = "Harvest", "Ripe Wheat"
	elseif plot:GetAttribute("CropGrowing") then prompt.ActionText, prompt.ObjectText = "Growing...", "Wheat"
	else prompt.ActionText, prompt.ObjectText = "Plant Wheat", "Farm Plot" end
end

local function plantPlot(player, plot)
	if plot:GetAttribute("CropGrowing") or plot:GetAttribute("CropReady") then return false, "That plot is already growing something." end
	if not InventoryService.RemoveItem(player, "WheatSeeds", 1) then return false, "You need Wheat Seeds." end
	plot:SetAttribute("CropGrowing", true)
	plot:SetAttribute("CropReady", false)
	plot:SetAttribute("ReadyAt", os.clock() + 55)
	createCropVisual(plot)
	setPlotPrompt(plot)
	return true, "Wheat planted."
end

local function harvestPlot(player, plot)
	if not plot:GetAttribute("CropReady") then return false, "The crop is not ready." end
	local root = playerRoot(player)
	local position = root and root.Position or plot.PrimaryPart.Position
	for itemName, amount in { Wheat = 4, WheatSeeds = 1 } do
		local ok = InventoryService.AddItem(player, itemName, amount)
		if not ok then InventoryService.CreateWorldDrop(position, itemName, amount) end
	end
	plot:SetAttribute("CropGrowing", false)
	plot:SetAttribute("CropReady", false)
	plot:SetAttribute("ReadyAt", 0)
	for _, child in plot:GetChildren() do if child:GetAttribute("CropVisual") then child:Destroy() end end
	setPlotPrompt(plot)
	return true, "Harvested wheat."
end

local function attachPlotPrompt(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.15
	prompt.Parent = model.PrimaryPart
	setPlotPrompt(model)
	prompt.Triggered:Connect(function(player)
		local ok, message
		if model:GetAttribute("CropReady") then ok, message = harvestPlot(player, model)
		elseif model:GetAttribute("CropGrowing") then ok, message = false, "The wheat is still growing."
		else ok, message = plantPlot(player, model) end
		sendState(player, message)
	end)
end

local function attachBedPrompt(model, ownerUserId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Set Respawn"
	prompt.ObjectText = "Bed"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.25
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if player.UserId ~= ownerUserId then sendState(player, "Only the bed owner can set this respawn.") return end
		bedByUser[player.UserId] = model
		sendState(player, "Bed set as your respawn point for this server session.")
	end)
end

local function createStructure(player, structureName)
	local root = playerRoot(player)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not root or not arena then return nil, "The world is not ready." end
	local forward = root.CFrame.LookVector
	local position = root.Position + Vector3.new(forward.X, 0, forward.Z) * 7
	position = Vector3.new(math.floor(position.X + 0.5), 0, math.floor(position.Z + 0.5))
	local sizes = {
		Workbench = Vector3.new(6, 4, 4), Chest = Vector3.new(5, 4, 4), FarmPlot = Vector3.new(7, 1, 7),
		SurvivalCampfire = Vector3.new(6, 3, 6), SurvivalSpikeTrap = Vector3.new(5, 2, 5), WebTrap = Vector3.new(6, 1, 6),
		Torch = Vector3.new(2, 6, 2), Bed = Vector3.new(7, 2, 4),
	}
	local size = sizes[structureName] or Vector3.new(5, 4, 5)
	local clear, reason = placementClear(player, position, size)
	if not clear then return nil, reason end

	local model = Instance.new("Model")
	model.Name = structureName
	model.Parent = arena
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("SurvivalStructure", structureName)
	model:SetAttribute("BuildType", structureName)
	local health = structureCatalog[structureName] and structureCatalog[structureName].Health or 100
	model:SetAttribute("Health", health)
	model:SetAttribute("MaxHealth", health)

	if structureName == "Workbench" then
		local top = part(model, "Top", Vector3.new(6, 0.7, 4), CFrame.new(position + Vector3.new(0, 3, 0)), Color3.fromRGB(120, 82, 49), Enum.Material.WoodPlanks)
		model.PrimaryPart = top
		for _, x in { -2.2, 2.2 } do for _, z in { -1.2, 1.2 } do part(model, "Leg", Vector3.new(0.6, 3, 0.6), CFrame.new(position + Vector3.new(x, 1.5, z)), Color3.fromRGB(89, 62, 41), Enum.Material.Wood) end end
		attachCraftPrompt(model, "Workbench")
	elseif structureName == "Chest" then
		local body = part(model, "Chest", Vector3.new(5, 3, 4), CFrame.new(position + Vector3.new(0, 1.5, 0)), Color3.fromRGB(119, 77, 43), Enum.Material.WoodPlanks)
		model.PrimaryPart = body
		local lid = part(model, "Lid", Vector3.new(5.2, 0.7, 4.2), CFrame.new(position + Vector3.new(0, 3.3, 0)), Color3.fromRGB(148, 98, 55), Enum.Material.WoodPlanks)
		lid.CanCollide = false
		local id = HttpService:GenerateGUID(false)
		model:SetAttribute("ChestId", id)
		local slots = table.create(8)
		for i = 1, 8 do slots[i] = false end
		chestContents[id], chestModels[id] = slots, model
		attachChestPrompt(model, id)
	elseif structureName == "FarmPlot" then
		local soil = part(model, "Soil", Vector3.new(7, 0.7, 7), CFrame.new(position + Vector3.new(0, 0.35, 0)), Color3.fromRGB(92, 65, 42), Enum.Material.Ground)
		model.PrimaryPart = soil
		model:SetAttribute("CropGrowing", false)
		model:SetAttribute("CropReady", false)
		model:SetAttribute("ReadyAt", 0)
		attachPlotPrompt(model)
	elseif structureName == "SurvivalCampfire" then
		local base = part(model, "Base", Vector3.new(5.5, 0.5, 5.5), CFrame.new(position + Vector3.new(0, 0.25, 0)), Color3.fromRGB(92, 88, 82), Enum.Material.Slate)
		model.PrimaryPart = base
		for _, z in { -0.8, 0.8 } do part(model, "Log", Vector3.new(4, 0.6, 0.6), CFrame.new(position + Vector3.new(0, 0.7, z)) * CFrame.Angles(0, math.rad(z > 0 and 30 or -30), 0), Color3.fromRGB(105, 69, 42), Enum.Material.Wood) end
		local flame = part(model, "Flame", Vector3.new(1.6, 2.2, 1.6), CFrame.new(position + Vector3.new(0, 1.8, 0)), Color3.fromRGB(255, 146, 48), Enum.Material.Neon)
		flame.Shape, flame.CanCollide = Enum.PartType.Ball, false
		local light = Instance.new("PointLight") light.Range, light.Brightness, light.Parent = 18, 2, flame
		attachCraftPrompt(model, "Campfire")
	elseif structureName == "Bed" then
		local frame = part(model, "Frame", Vector3.new(7, 0.8, 4), CFrame.new(position + Vector3.new(0, 0.8, 0)), Color3.fromRGB(104, 70, 43), Enum.Material.WoodPlanks)
		model.PrimaryPart = frame
		local mattress = part(model, "Mattress", Vector3.new(6.5, 0.65, 3.6), CFrame.new(position + Vector3.new(0, 1.5, 0)), Color3.fromRGB(205, 205, 194), Enum.Material.Fabric)
		mattress.CanCollide = true
		part(model, "Pillow", Vector3.new(1.7, 0.45, 3), CFrame.new(position + Vector3.new(-2.2, 2.0, 0)), Color3.fromRGB(236, 236, 230), Enum.Material.Fabric).CanCollide = false
		attachBedPrompt(model, player.UserId)
	elseif structureName == "SurvivalSpikeTrap" then
		local base = part(model, "Base", Vector3.new(5, 0.5, 5), CFrame.new(position + Vector3.new(0, 0.25, 0)), Color3.fromRGB(95, 71, 47), Enum.Material.Wood)
		model.PrimaryPart = base
		for i = 1, 5 do local spike = part(model, `Spike{i}`, Vector3.new(0.6, 2.4, 0.6), CFrame.new(position + Vector3.new((i - 3) * 0.8, 1.4, 0)), Color3.fromRGB(128, 128, 128), Enum.Material.Metal) spike.CanCollide = false end
		local trigger = part(model, "Trigger", Vector3.new(5, 2, 5), CFrame.new(position + Vector3.new(0, 1, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		trigger.Transparency, trigger.CanCollide, trigger.CanQuery = 1, false, false
		local hitTimes = {}
		trigger.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local victim = character and Players:GetPlayerFromCharacter(character)
			local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not targetHumanoid or targetHumanoid.Health <= 0 or (victim and victim.UserId == player.UserId) then return end
			local key = victim and victim.UserId or character:GetDebugId()
			if os.clock() - (hitTimes[key] or 0) < 1.5 then return end
			hitTimes[key] = os.clock()
			targetHumanoid:TakeDamage(20)
		end)
	elseif structureName == "WebTrap" then
		local web = part(model, "Web", Vector3.new(6, 0.3, 6), CFrame.new(position + Vector3.new(0, 0.15, 0)), Color3.fromRGB(225, 225, 231), Enum.Material.Fabric)
		model.PrimaryPart = web
		local hitTimes = {}
		web.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
			local victim = character and Players:GetPlayerFromCharacter(character)
			if not targetHumanoid or targetHumanoid.Health <= 0 or (victim and victim.UserId == player.UserId) then return end
			local key = victim and victim.UserId or character:GetDebugId()
			if os.clock() - (hitTimes[key] or 0) < 4 then return end
			hitTimes[key] = os.clock()
			local oldSpeed = targetHumanoid.WalkSpeed
			targetHumanoid.WalkSpeed = math.min(oldSpeed, 7)
			task.delay(2.5, function() if targetHumanoid.Parent and targetHumanoid.Health > 0 then targetHumanoid.WalkSpeed = math.max(targetHumanoid.WalkSpeed, oldSpeed) end end)
		end)
	elseif structureName == "Torch" then
		local pole = part(model, "Pole", Vector3.new(0.5, 5, 0.5), CFrame.new(position + Vector3.new(0, 2.5, 0)), Color3.fromRGB(94, 63, 39), Enum.Material.Wood)
		model.PrimaryPart = pole
		local flame = part(model, "Flame", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, 5.3, 0)), Color3.fromRGB(255, 178, 71), Enum.Material.Neon)
		flame.Shape, flame.CanCollide = Enum.PartType.Ball, false
		local light = Instance.new("PointLight") light.Range, light.Brightness, light.Parent = 22, 2.4, flame
		Debris:AddItem(model, 300)
	else
		model:Destroy()
		return nil, "That structure is not implemented."
	end

	tagPlayerBuild(model)
	return model, `${structureCatalog[structureName] and structureCatalog[structureName].Label or structureName} placed.`
end

local function stationAvailable(player, station)
	if station == "Hand" then return true end
	if station == "Workbench" then return nearbyStructure(player, "Workbench", 18) ~= nil end
	if station == "Campfire" then return nearbyStructure(player, "SurvivalCampfire", 18) ~= nil end
	return false
end

local function craft(player, recipeName)
	local recipe = CraftingData.Recipes[recipeName]
	if not recipe then return false, "Unknown recipe." end
	if not stationAvailable(player, recipe.Station) then return false, `You need to be near a {recipe.Station}.` end
	local profile = PlayerService.Get(player)
	if not profile then return false, "Profile is not ready." end
	local resources = recipe.Ingredients.Resources or {}
	local items = recipe.Ingredients.Items or {}
	for resource, amount in resources do if (profile[resource] or 0) < amount then return false, `Not enough {string.lower(resource)}.` end end
	if not InventoryService.HasItems(player, items) then return false, "Missing crafting ingredients." end
	if not InventoryService.CanAdd(player, recipe.Result.Item, recipe.Result.Amount or 1) then return false, "Inventory is full." end
	if next(resources) and not PlayerService.Spend(player, resources) then return false, "Not enough resources." end
	for itemName, amount in items do InventoryService.RemoveItem(player, itemName, amount, true) end
	local ok, err = InventoryService.AddItem(player, recipe.Result.Item, recipe.Result.Amount or 1)
	if not ok then
		for itemName, amount in items do InventoryService.AddItem(player, itemName, amount, true) end
		PlayerService.Add(player, resources)
		return false, err or "Inventory is full."
	end
	return true, `Crafted {recipe.Label}.`
end

local function grantKit(player, kitName)
	local kit = KitData.Kits[kitName]
	if not kit then return false, "Unknown kit." end
	InventoryService.ClearProtectedSource(player, "Kit:", true)
	local source = `Kit:{kitName}`
	for itemName, amount in kit.Items do
		local ok = InventoryService.AddProtectedItem(player, itemName, amount, source, true)
		if not ok then
			InventoryService.ClearProtectedSource(player, "Kit:", true)
			InventoryService.Changed:Fire(player, InventoryService.GetPublic(player))
			return false, "Your bag needs more space for that starter kit."
		end
	end
	InventoryService.Changed:Fire(player, InventoryService.GetPublic(player))
	kitGrantedThisSession[player] = kitName
	return true, `${kit.Label} loaded into protected kit slots.`
end

local function buyKit(player, kitName)
	local ok, message = PlayerService.BuyKit(player, kitName)
	if not ok then return false, message end
	local granted, grantMessage = grantKit(player, kitName)
	return granted, granted and `${message} ${grantMessage}` or grantMessage
end

local function clearEquipmentVisual(character, name)
	local old = character and character:FindFirstChild(name)
	if old then old:Destroy() end
end

local function applyEquipmentVisuals(player)
	local character = player.Character
	if not character then return end
	clearEquipmentVisual(character, "SurvivalArmor")
	clearEquipmentVisual(character, "SurvivalCloak")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then return end
	local armorName = player:GetAttribute("EquippedArmorItem")
	local armor = armorName and SurvivalItemData.Items[armorName]
	if armor then
		local model = Instance.new("Model") model.Name = "SurvivalArmor" model.Parent = character
		local plate = Instance.new("Part")
		plate.Name = "ChestPlate" plate.Size = Vector3.new(2.3, 2.3, 0.45) plate.Material = armor.ArmorStyle == "Stone" and Enum.Material.Slate or Enum.Material.Fabric
		plate.Color = armor.ArmorStyle == "Dragon" and Color3.fromRGB(91, 46, 48) or armor.ArmorStyle == "Fur" and Color3.fromRGB(214, 214, 205) or armor.ArmorStyle == "Stone" and Color3.fromRGB(108, 111, 118) or Color3.fromRGB(112, 76, 49)
		plate.CanCollide = false plate.CanQuery = false plate.Massless = true plate.CFrame = torso.CFrame * CFrame.new(0, 0, -0.65) plate.Parent = model
		local weld = Instance.new("WeldConstraint") weld.Part0, weld.Part1, weld.Parent = torso, plate, plate
	end
	local cloakName = player:GetAttribute("EquippedCloakItem")
	local cloak = cloakName and SurvivalItemData.Items[cloakName]
	if cloak then
		local model = Instance.new("Model") model.Name = "SurvivalCloak" model.Parent = character
		local cape = Instance.new("Part")
		cape.Name = "Cape" cape.Size = Vector3.new(2.6, 3.5, 0.2) cape.Material = Enum.Material.Fabric cape.Color = Color3.fromRGB(45, 34, 70)
		cape.CanCollide = false cape.CanQuery = false cape.Massless = true cape.CFrame = torso.CFrame * CFrame.new(0, -0.3, 0.75) * CFrame.Angles(math.rad(8), 0, 0) cape.Parent = model
		local weld = Instance.new("WeldConstraint") weld.Part0, weld.Part1, weld.Parent = torso, cape, cape
	end
end

local function equipItem(player, itemName, item)
	if item.Use == "Armor" then
		player:SetAttribute("EquippedArmorItem", itemName)
		player:SetAttribute("ArmorReduction", math.clamp(item.ArmorReduction or 0, 0, 0.65))
		player:SetAttribute("ArmorWalkPenalty", item.WalkSpeedPenalty or 0)
		player:SetAttribute("ArmorSnowResist", item.SnowResist == true)
	elseif item.Use == "Cloak" then
		player:SetAttribute("EquippedCloakItem", itemName)
		player:SetAttribute("CloakDamageMultiplier", item.DamageMultiplier or 1)
		player:SetAttribute("CloakWalkBonus", item.WalkSpeedBonus or 0)
	else
		return false, "That is not equippable."
	end
	applyEquipmentVisuals(player)
	return true, `Equipped {item.Label}.`
end

local function useItem(player, slotIndex)
	local slots = InventoryService.Get(player)
	local slot = slots and slots[slotIndex]
	if not slot then return false, "That inventory slot is empty." end
	local itemName = slot.Item
	local item = SurvivalItemData.Items[itemName]
	if not item or not item.Use then return false, "That item is a crafting material." end
	local state = needs[player]
	local hum = humanoid(player)
	if not state or not hum or hum.Health <= 0 then return false, "You cannot use that right now." end

	if item.Use == "Place" then
		local model, message = createStructure(player, item.Structure)
		if not model then return false, message end
		InventoryService.RemoveFromSlot(player, slotIndex, 1)
		return true, message
	elseif item.Use == "Seed" then
		local plot = nearbyStructure(player, "FarmPlot", 12)
		if not plot then return false, "Stand near an empty farm plot." end
		return plantPlot(player, plot)
	elseif item.Use == "Fertilizer" then
		local plot = nearbyStructure(player, "FarmPlot", 12)
		if not plot or not plot:GetAttribute("CropGrowing") or plot:GetAttribute("CropReady") then return false, "Stand near a growing crop." end
		InventoryService.RemoveFromSlot(player, slotIndex, 1)
		plot:SetAttribute("ReadyAt", math.max(os.clock(), (plot:GetAttribute("ReadyAt") or os.clock()) - 25))
		return true, "Fertilized crop: growth accelerated."
	elseif item.Use == "Armor" or item.Use == "Cloak" then
		return equipItem(player, itemName, item)
	end

	InventoryService.RemoveFromSlot(player, slotIndex, 1, true)
	if item.Hunger then state.Hunger = math.clamp(state.Hunger + item.Hunger, 0, 100) end
	if item.Thirst then state.Thirst = math.clamp(state.Thirst + item.Thirst, 0, 100) end
	if item.Heal then hum.Health = math.min(hum.MaxHealth, hum.Health + item.Heal) end
	if item.ReturnsItem then InventoryService.AddItem(player, item.ReturnsItem, 1, true) end
	if item.Use == "Buff" then
		local now = os.clock()
		if item.Buff == "Speed" then state.Buffs.SpeedUntil = math.max(state.Buffs.SpeedUntil, now + item.Duration)
		elseif item.Buff == "Fortify" then state.Buffs.FortifyUntil = math.max(state.Buffs.FortifyUntil, now + item.Duration)
		elseif item.Buff == "NoNeeds" then state.Buffs.NoNeedsUntil = math.max(state.Buffs.NoNeedsUntil, now + item.Duration)
		elseif item.Buff == "ColdResist" then state.Buffs.ColdResistUntil = math.max(state.Buffs.ColdResistUntil, now + item.Duration) end
	elseif item.Use == "Antidote" then player:SetAttribute("SurvivalPoisonUntil", 0) end
	InventoryService.Changed:Fire(player, InventoryService.GetPublic(player))
	return true, `Used {item.Label}.`
end

local function chestById(player, id)
	local model = chestModels[id]
	local root = playerRoot(player)
	if not model or not model.Parent or not model.PrimaryPart or not root or (root.Position - model.PrimaryPart.Position).Magnitude > 15 then return nil end
	return model
end

local function chestDeposit(player, id, inventorySlot)
	if not chestById(player, id) then return false, "Move closer to the chest." end
	local chest, inv = chestContents[id], InventoryService.Get(player)
	local slot = inv and inv[inventorySlot]
	if not chest or not slot then return false, "That inventory slot is empty." end
	if (slot.Protected or 0) > 0 then return false, "Protected kit items stay in your bag." end
	local emptyIndex
	for i = 1, 8 do if not chest[i] then emptyIndex = i break end end
	if not emptyIndex then return false, "Chest is full." end
	local itemName, amount = InventoryService.RemoveFromSlot(player, inventorySlot, slot.Amount)
	chest[emptyIndex] = { Item = itemName, Amount = amount }
	return true, "Stored item in chest."
end

local function chestWithdraw(player, id, chestIndex)
	if not chestById(player, id) then return false, "Move closer to the chest." end
	local chest, slot = chestContents[id], chestContents[id] and chestContents[id][chestIndex]
	if not slot then return false, "That chest slot is empty." end
	local ok, err = InventoryService.AddItem(player, slot.Item, slot.Amount)
	if not ok then return false, err end
	chest[chestIndex] = false
	return true, "Took item from chest."
end

local function validateEquipment(player)
	local armorName = player:GetAttribute("EquippedArmorItem")
	if armorName and InventoryService.CountItem(player, armorName) <= 0 then
		player:SetAttribute("EquippedArmorItem", nil) player:SetAttribute("ArmorReduction", 0) player:SetAttribute("ArmorWalkPenalty", 0) player:SetAttribute("ArmorSnowResist", false)
	end
	local cloakName = player:GetAttribute("EquippedCloakItem")
	if cloakName and InventoryService.CountItem(player, cloakName) <= 0 then
		player:SetAttribute("EquippedCloakItem", nil) player:SetAttribute("CloakDamageMultiplier", 1) player:SetAttribute("CloakWalkBonus", 0)
	end
end

local function setupPlayer(player)
	needs[player] = newNeedState()
	nextNeedTick[player] = os.clock() + NEED_TICK_SECONDS
	nextStatePush[player] = 0
	player:SetAttribute("ArmorReduction", 0)
	player:SetAttribute("ArmorWalkPenalty", 0)
	player:SetAttribute("CloakDamageMultiplier", 1)
	player:SetAttribute("CloakWalkBonus", 0)

	local function onCharacter(character)
		needs[player] = newNeedState()
		nextNeedTick[player] = os.clock() + NEED_TICK_SECONDS
		local hum = character:WaitForChild("Humanoid", 8)
		if not hum then return end
		task.delay(0.3, function()
			local bed = bedByUser[player.UserId]
			if bed and bed.Parent and bed.PrimaryPart and character.Parent then character:PivotTo(bed.PrimaryPart.CFrame + Vector3.new(0, 4, 0)) end
			applyEquipmentVisuals(player)
		end)
		hum.Died:Connect(function()
			local root = character:FindFirstChild("HumanoidRootPart")
			InventoryService.ClearToWorld(player, root and root.Position or Vector3.new(0, 3, 0))
			InventoryService.Save(player)
		end)
		task.delay(0.5, function() if player.Parent then sendState(player, "No passive healing: eat food or use medicine. Stand in shallow water to restore hydration.") end end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then task.spawn(onCharacter, player.Character) end

	task.spawn(function()
		for _ = 1, 60 do
			if PlayerService.Get(player) and InventoryService.Get(player) then break end
			task.wait(0.1)
		end
		local profile = PlayerService.Get(player)
		if profile and profile.EquippedKit and not kitGrantedThisSession[player] then grantKit(player, profile.EquippedKit) end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

InventoryService.Changed.Event:Connect(function(player)
	if player and player.Parent then validateEquipment(player) sendState(player) end
end)

nutritionEvent.Event:Connect(function(player, hungerAmount, thirstAmount, healAmount, message)
	local state, hum = needs[player], humanoid(player)
	if not state or not hum or hum.Health <= 0 then return end
	state.Hunger = math.clamp(state.Hunger + math.max(0, tonumber(hungerAmount) or 0), 0, 100)
	state.Thirst = math.clamp(state.Thirst + math.max(0, tonumber(thirstAmount) or 0), 0, 100)
	if (tonumber(healAmount) or 0) > 0 then hum.Health = math.min(hum.MaxHealth, hum.Health + healAmount) end
	sendState(player, message)
end)

getSurvivalState.OnServerInvoke = function(player)
	local state = needs[player] or newNeedState()
	local root = playerRoot(player)
	local profile = PlayerService.Get(player)
	return {
		Hunger = state.Hunger, Thirst = state.Thirst, Buffs = copy(state.Buffs), Inventory = InventoryService.GetPublic(player),
		Gold = profile and math.floor(profile.Gold or 0) or 0, Biome = root and biomeAt(root.Position) or "Grass",
		OwnedKits = profile and copy(profile.OwnedKits or {}) or {}, EquippedKit = profile and profile.EquippedKit or nil,
		EquippedArmor = player:GetAttribute("EquippedArmorItem"), EquippedCloak = player:GetAttribute("EquippedCloakItem"),
	}
end

survivalAction.OnServerEvent:Connect(function(player, actionName, payload)
	if actionName == "UseSlot" then local _, message = useItem(player, tonumber(payload) or 0) sendState(player, message)
	elseif actionName == "DropSlot" then local _, message = InventoryService.DropFromSlot(player, tonumber(payload) or 0, 1) sendState(player, message)
	elseif actionName == "Craft" then local _, message = craft(player, tostring(payload)) sendState(player, message)
	elseif actionName == "BuyKit" then local _, message = buyKit(player, tostring(payload)) sendState(player, message)
	elseif actionName == "ChestDeposit" and type(payload) == "table" then local _, message = chestDeposit(player, tostring(payload.Id), tonumber(payload.Slot) or 0) sendState(player, message, { OpenChest = { Id = payload.Id, Slots = chestPublic(payload.Id) } })
	elseif actionName == "ChestWithdraw" and type(payload) == "table" then local _, message = chestWithdraw(player, tostring(payload.Id), tonumber(payload.Slot) or 0) sendState(player, message, { OpenChest = { Id = payload.Id, Slots = chestPublic(payload.Id) } }) end
end)

local function addWaterPrompt(marker, label)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Drink / Fill Bottle"
	prompt.ObjectText = label
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = 0.3
	prompt.Parent = marker
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now - (waterCooldown[player] or 0) < 1.5 then return end
		waterCooldown[player] = now
		local state = needs[player]
		if state then state.Thirst = math.min(100, state.Thirst + 32) end
		if InventoryService.CountItem(player, "EmptyFlask") > 0 then
			InventoryService.RemoveItem(player, "EmptyFlask", 1, true)
			local ok = InventoryService.AddItem(player, "WaterFlask", 1)
			if not ok then InventoryService.AddItem(player, "EmptyFlask", 1) end
		end
		sendState(player, "Hydrated and refilled one empty water bottle if available.")
	end)
end

local function createWaterWorld()
	local arena = Workspace:WaitForChild("SurvivalArena", 15)
	if not arena then return end
	for _, x in { -480, -300, -120, 120, 300, 480 } do
		for _, z in { -(Config.RiverHalfWidth + 7), Config.RiverHalfWidth + 7 } do
			local marker = part(arena, "WaterPoint", Vector3.new(3, 0.4, 3), CFrame.new(x, 0.2, z), Color3.fromRGB(72, 154, 217), Enum.Material.Glass)
			marker.Transparency, marker.CanCollide = 0.35, false
			addWaterPrompt(marker, "River Water")
		end
	end
	for i = 1, 12 do
		local half = math.floor(Config.WorldSize / 2 - 70)
		local pos = Vector3.new(math.random(-half, half), 0, math.random(-half, half))
		if math.abs(pos.Z) < Config.RiverHalfWidth + 60 then pos = Vector3.new(pos.X, 0, pos.Z + (pos.Z >= 0 and 110 or -110)) end
		local radius = math.random(7, 13)
		local puddle = part(arena, `Puddle{i}`, Vector3.new(0.22, radius * 2, radius * 2), CFrame.new(pos + Vector3.new(0, 0.11, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(74, 151, 204), Enum.Material.Glass)
		puddle.Shape = Enum.PartType.Cylinder
		puddle.Transparency = 0.28
		puddle.CanCollide = false
		puddle.CanQuery = true
		table.insert(puddles, { Position = pos, Radius = radius })
		addWaterPrompt(puddle, "Fresh Puddle")
	end
end

task.spawn(createWaterWorld)

local function standingInWater(root)
	if root.Position.Y < 3 and math.abs(root.Position.Z) <= Config.RiverHalfWidth then return true end
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	for _, puddle in puddles do if (flat - puddle.Position).Magnitude <= puddle.Radius then return true end end
	return false
end

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local state, hum, root = needs[player], humanoid(player), playerRoot(player)
			if not state or not hum or hum.Health <= 0 or not root then continue end
			if standingInWater(root) then state.Thirst = math.min(100, state.Thirst + WATER_REGEN_PER_SECOND) end

			local speed = (Config.BaseWalkSpeed or 20)
				+ PlayerService.GetHatEffect(player, "WalkSpeedBonus", 0)
				+ (player:GetAttribute("CloakWalkBonus") or 0)
				+ (player:GetAttribute("RiftSpeedBonus") or 0)
				- (player:GetAttribute("ArmorWalkPenalty") or 0)
			local inSnow = biomeAt(root.Position) == "Snow"
			local snowImmune = PlayerService.GetHatEffect(player, "SnowSpeedImmunity", false) == true or player:GetAttribute("ArmorSnowResist") == true or now < state.Buffs.ColdResistUntil
			if inSnow and not snowImmune then speed *= 0.80 end
			if now < state.Buffs.SpeedUntil then speed += 5 end
			hum.WalkSpeed = math.max(8, speed)

			local targetMax = 100
				+ PlayerService.GetHatEffect(player, "MaxHealthBonus", 0)
				+ (player:GetAttribute("RiftMaxHealthBonus") or 0)
				+ (now < state.Buffs.FortifyUntil and 35 or 0)
			targetMax = math.max(35, targetMax)
			if hum.MaxHealth ~= targetMax then hum.MaxHealth = targetMax hum.Health = math.min(hum.Health, hum.MaxHealth) end

			if now >= (nextNeedTick[player] or 0) then
				nextNeedTick[player] = now + NEED_TICK_SECONDS
				if now >= state.Buffs.NoNeedsUntil then
					state.Hunger = math.max(0, state.Hunger - HUNGER_DRAIN_PER_TICK)
					local thirstMultiplier = PlayerService.GetHatEffect(player, "ThirstDrainMultiplier", 1)
					state.Thirst = math.max(0, state.Thirst - THIRST_DRAIN_PER_TICK * thirstMultiplier)
					if state.Hunger <= 0 then hum:TakeDamage(8) end
					if state.Thirst <= 0 then hum:TakeDamage(10) end
				end
				sendState(player)
			elseif now >= (nextStatePush[player] or 0) then nextStatePush[player] = now + 3 sendState(player) end
		end

		local arena = Workspace:FindFirstChild("SurvivalArena")
		if arena then
			for _, model in arena:GetChildren() do
				if model:IsA("Model") and model:GetAttribute("SurvivalStructure") == "FarmPlot" and model:GetAttribute("CropGrowing") and not model:GetAttribute("CropReady") and now >= (model:GetAttribute("ReadyAt") or math.huge) then
					model:SetAttribute("CropReady", true) model:SetAttribute("CropGrowing", false)
					for _, child in model:GetChildren() do if child:GetAttribute("CropVisual") and child:IsA("BasePart") then child.Color = Color3.fromRGB(226, 190, 72) end end
					setPlotPrompt(model)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	needs[player], waterCooldown[player], nextNeedTick[player], nextStatePush[player], kitGrantedThisSession[player] = nil, nil, nil, nil, nil
	bedByUser[player.UserId] = nil
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if arena then
		for _, model in arena:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
				local id = model:GetAttribute("ChestId")
				if id then chestContents[id], chestModels[id] = nil, nil end
				model:Destroy()
			end
		end
	end
end)
