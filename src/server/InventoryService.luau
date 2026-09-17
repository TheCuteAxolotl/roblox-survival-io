local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local InventoryService = {}
InventoryService.SLOT_COUNT = 6
InventoryService.Changed = Instance.new("BindableEvent")

local inventories = {}
local store = nil
local persistenceEnabled = false

local function deepCopy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, inner in value do result[deepCopy(key)] = deepCopy(inner) end
	return result
end

local function emptySlots()
	local slots = table.create(InventoryService.SLOT_COUNT)
	for i = 1, InventoryService.SLOT_COUNT do slots[i] = false end
	return slots
end

local function sanitizeSlots(raw)
	local slots = emptySlots()
	if type(raw) ~= "table" then return slots end
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = raw[i]
		if type(slot) == "table" and type(slot.Item) == "string" and SurvivalItemData.Items[slot.Item] then
			local amount = math.clamp(math.floor(tonumber(slot.Amount) or 0), 0, SurvivalItemData.StackLimit(slot.Item))
			if amount > 0 then slots[i] = { Item = slot.Item, Amount = amount } end
		end
	end
	return slots
end

local function fireChanged(player)
	InventoryService.Changed:Fire(player, InventoryService.GetPublic(player))
end

local function tryEnableStore()
	if RunService:IsStudio() and game.GameId == 0 then
		warn("[InventoryService] Unpublished Studio place: survival inventory is temporary this session.")
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SurvivalIO_Inventory_v1")
	end)
	if ok then
		store = result
		persistenceEnabled = true
	else
		warn("[InventoryService] Inventory DataStore unavailable:", result)
	end
end

function InventoryService.Load(player)
	local slots = emptySlots()
	if persistenceEnabled and store then
		local ok, raw = pcall(function()
			return store:GetAsync(`inv_{player.UserId}`)
		end)
		if ok then
			slots = sanitizeSlots(raw)
		else
			warn(`[InventoryService] Failed to load inventory for {player.Name}: {raw}`)
		end
	end
	inventories[player] = slots
	fireChanged(player)
end

function InventoryService.Save(player)
	if not persistenceEnabled or not store then return end
	local slots = inventories[player]
	if not slots then return end
	local payload = deepCopy(slots)
	local ok, err = pcall(function()
		store:SetAsync(`inv_{player.UserId}`, payload)
	end)
	if not ok then warn(`[InventoryService] Failed to save inventory for {player.Name}: {err}`) end
end

function InventoryService.Get(player)
	return inventories[player]
end

function InventoryService.GetPublic(player)
	return deepCopy(inventories[player] or emptySlots())
end

function InventoryService.CountItem(player, itemName)
	local slots = inventories[player]
	if not slots then return 0 end
	local count = 0
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = slots[i]
		if slot and slot.Item == itemName then count += slot.Amount end
	end
	return count
end

function InventoryService.HasItems(player, requirements)
	if type(requirements) ~= "table" then return true end
	for itemName, amount in requirements do
		if InventoryService.CountItem(player, itemName) < amount then return false end
	end
	return true
end

local function simulateAdd(slots, itemName, amount)
	local copy = deepCopy(slots)
	local stackLimit = SurvivalItemData.StackLimit(itemName)
	local remaining = amount
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = copy[i]
		if slot and slot.Item == itemName and slot.Amount < stackLimit then
			local room = stackLimit - slot.Amount
			local moved = math.min(room, remaining)
			slot.Amount += moved
			remaining -= moved
			if remaining <= 0 then return true, copy end
		end
	end
	for i = 1, InventoryService.SLOT_COUNT do
		if copy[i] == false or copy[i] == nil then
			local moved = math.min(stackLimit, remaining)
			copy[i] = { Item = itemName, Amount = moved }
			remaining -= moved
			if remaining <= 0 then return true, copy end
		end
	end
	return false, slots
end

function InventoryService.CanAdd(player, itemName, amount)
	if not SurvivalItemData.Items[itemName] then return false end
	local slots = inventories[player]
	if not slots then return false end
	local ok = simulateAdd(slots, itemName, math.max(1, math.floor(amount or 1)))
	return ok
end

function InventoryService.AddItem(player, itemName, amount, silent)
	if not SurvivalItemData.Items[itemName] then return false, "Unknown item." end
	local slots = inventories[player]
	if not slots then return false, "Inventory is not ready." end
	amount = math.max(1, math.floor(amount or 1))
	local ok, nextSlots = simulateAdd(slots, itemName, amount)
	if not ok then return false, "Inventory is full." end
	inventories[player] = nextSlots
	if not silent then fireChanged(player) end
	return true
end

function InventoryService.RemoveItem(player, itemName, amount, silent)
	local slots = inventories[player]
	if not slots then return false end
	amount = math.max(1, math.floor(amount or 1))
	if InventoryService.CountItem(player, itemName) < amount then return false end
	local remaining = amount
	for i = InventoryService.SLOT_COUNT, 1, -1 do
		local slot = slots[i]
		if slot and slot.Item == itemName then
			local removed = math.min(slot.Amount, remaining)
			slot.Amount -= removed
			remaining -= removed
			if slot.Amount <= 0 then slots[i] = false end
			if remaining <= 0 then break end
		end
	end
	if not silent then fireChanged(player) end
	return true
end

function InventoryService.RemoveFromSlot(player, slotIndex, amount, silent)
	local slots = inventories[player]
	local slot = slots and slots[slotIndex]
	if not slot then return nil end
	amount = math.clamp(math.floor(amount or 1), 1, slot.Amount)
	local itemName = slot.Item
	slot.Amount -= amount
	if slot.Amount <= 0 then slots[slotIndex] = false end
	if not silent then fireChanged(player) end
	return itemName, amount
end

local function dropColor(itemName)
	local item = SurvivalItemData.Items[itemName]
	return SurvivalItemData.RarityColors[item and item.Rarity or "Common"] or Color3.new(1, 1, 1)
end

function InventoryService.CreateWorldDrop(position, itemName, amount)
	local item = SurvivalItemData.Items[itemName]
	if not item or amount <= 0 then return nil end
	local arena = Workspace:FindFirstChild("SurvivalArena") or Workspace
	local model = Instance.new("Model")
	model.Name = `Drop_{itemName}`
	model:SetAttribute("SurvivalItem", itemName)
	model:SetAttribute("Amount", amount)
	model.Parent = arena

	local part = Instance.new("Part")
	part.Name = "Drop"
	part.Size = Vector3.new(1.8, 1.8, 1.8)
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = dropColor(itemName)
	part.Position = position + Vector3.new(math.random(-2, 2), 1.4, math.random(-2, 2))
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	model.PrimaryPart = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = `{item.Label} x{amount}`
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = 0.1
	prompt.Parent = part

	local claimed = false
	prompt.Triggered:Connect(function(player)
		if claimed or not model.Parent then return end
		local ok = InventoryService.AddItem(player, itemName, amount)
		if ok then
			claimed = true
			model:Destroy()
		end
	end)

	Debris:AddItem(model, 120)
	return model
end

function InventoryService.DropFromSlot(player, slotIndex, amount)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false, "Character is not ready." end
	local itemName, removed = InventoryService.RemoveFromSlot(player, slotIndex, amount, true)
	if not itemName then return false, "That slot is empty." end
	InventoryService.CreateWorldDrop(root.Position + root.CFrame.LookVector * 4, itemName, removed)
	fireChanged(player)
	return true, `Dropped {SurvivalItemData.Items[itemName].Label}.`
end

function InventoryService.ClearToWorld(player, position)
	local slots = inventories[player]
	if not slots then return end
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = slots[i]
		if slot then InventoryService.CreateWorldDrop(position, slot.Item, slot.Amount) end
		slots[i] = false
	end
	fireChanged(player)
end

function InventoryService.Init()
	tryEnableStore()
	Players.PlayerAdded:Connect(InventoryService.Load)
	Players.PlayerRemoving:Connect(function(player)
		InventoryService.Save(player)
		inventories[player] = nil
	end)
	for _, player in Players:GetPlayers() do task.spawn(InventoryService.Load, player) end

	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do InventoryService.Save(player) end
		end
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do InventoryService.Save(player) end
	end)
end

return InventoryService
