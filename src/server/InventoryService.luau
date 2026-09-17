local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local InventoryService = {}
InventoryService.SLOT_COUNT = 34
InventoryService.Changed = Instance.new("BindableEvent")

local inventories = {}
local store = nil
local persistenceEnabled = false
local insuranceCache = {}

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
			if amount > 0 then
				local protected = math.clamp(math.floor(tonumber(slot.Protected) or 0), 0, amount)
				slots[i] = {
					Item = slot.Item,
					Amount = amount,
					Protected = protected,
					Source = type(slot.Source) == "string" and slot.Source or nil,
				}
			end
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
		return DataStoreService:GetDataStore("SurvivalIO_Inventory_v2")
	end)
	if ok then
		store = result
		persistenceEnabled = true
	else
		warn("[InventoryService] Inventory DataStore unavailable:", result)
	end
end

local function ownsInsurance(player)
	if insuranceCache[player] ~= nil then return insuranceCache[player] end
	local pass = MonetizationConfig.GamePasses and MonetizationConfig.GamePasses.InventoryInsurance
	if not pass or not pass.Id or pass.Id <= 0 then
		insuranceCache[player] = false
		return false
	end
	local ok, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
	end)
	insuranceCache[player] = ok and owned == true
	return insuranceCache[player]
end

function InventoryService.RefreshEntitlements(player)
	insuranceCache[player] = nil
	return ownsInsurance(player)
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

local function simulateAdd(slots, itemName, amount, source)
	local copy = deepCopy(slots)
	local stackLimit = SurvivalItemData.StackLimit(itemName)
	local remaining = amount
	local protectedAdd = source ~= nil

	-- Keep protected kit stacks separate from normal loot so death handling is exact.
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = copy[i]
		local compatible = slot and slot.Item == itemName and slot.Amount < stackLimit
		if compatible then
			if protectedAdd then
				compatible = slot.Source == source and (slot.Protected or 0) == slot.Amount
			else
				compatible = (slot.Protected or 0) == 0 and slot.Source == nil
			end
		end
		if compatible then
			local room = stackLimit - slot.Amount
			local moved = math.min(room, remaining)
			slot.Amount += moved
			if protectedAdd then slot.Protected = (slot.Protected or 0) + moved end
			remaining -= moved
			if remaining <= 0 then return true, copy end
		end
	end

	for i = 1, InventoryService.SLOT_COUNT do
		if copy[i] == false or copy[i] == nil then
			local moved = math.min(stackLimit, remaining)
			copy[i] = {
				Item = itemName,
				Amount = moved,
				Protected = protectedAdd and moved or 0,
				Source = source,
			}
			remaining -= moved
			if remaining <= 0 then return true, copy end
		end
	end
	return false, slots
end

function InventoryService.CanAdd(player, itemName, amount, source)
	if not SurvivalItemData.Items[itemName] then return false end
	local slots = inventories[player]
	if not slots then return false end
	local ok = simulateAdd(slots, itemName, math.max(1, math.floor(amount or 1)), source)
	return ok
end

function InventoryService.AddItem(player, itemName, amount, silent, source)
	if not SurvivalItemData.Items[itemName] then return false, "Unknown item." end
	local slots = inventories[player]
	if not slots then return false, "Inventory is not ready." end
	amount = math.max(1, math.floor(amount or 1))
	local ok, nextSlots = simulateAdd(slots, itemName, amount, source)
	if not ok then return false, "Inventory is full." end
	inventories[player] = nextSlots
	if not silent then fireChanged(player) end
	return true
end

function InventoryService.AddProtectedItem(player, itemName, amount, source, silent)
	source = source or "Protected"
	return InventoryService.AddItem(player, itemName, amount, silent, source)
end

function InventoryService.ClearProtectedSource(player, sourcePrefix, silent)
	local slots = inventories[player]
	if not slots then return end
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = slots[i]
		if slot and type(slot.Source) == "string" and string.sub(slot.Source, 1, #sourcePrefix) == sourcePrefix then
			slots[i] = false
		end
	end
	if not silent then fireChanged(player) end
end

function InventoryService.RemoveItem(player, itemName, amount, silent)
	local slots = inventories[player]
	if not slots then return false end
	amount = math.max(1, math.floor(amount or 1))
	if InventoryService.CountItem(player, itemName) < amount then return false end
	local remaining = amount

	-- Spend ordinary loot before protected kit items.
	for pass = 1, 2 do
		for i = InventoryService.SLOT_COUNT, 1, -1 do
			local slot = slots[i]
			if slot and slot.Item == itemName then
				local isProtected = (slot.Protected or 0) > 0
				if (pass == 1 and not isProtected) or (pass == 2 and isProtected) then
					local removed = math.min(slot.Amount, remaining)
					slot.Amount -= removed
					if isProtected then slot.Protected = math.max(0, (slot.Protected or 0) - removed) end
					remaining -= removed
					if slot.Amount <= 0 then slots[i] = false end
					if remaining <= 0 then break end
				end
			end
		end
		if remaining <= 0 then break end
	end
	if not silent then fireChanged(player) end
	return remaining <= 0
end

function InventoryService.RemoveFromSlot(player, slotIndex, amount, silent)
	local slots = inventories[player]
	local slot = slots and slots[slotIndex]
	if not slot then return nil end
	amount = math.clamp(math.floor(amount or 1), 1, slot.Amount)
	local itemName = slot.Item
	local protectedRemoved = math.min(slot.Protected or 0, amount)
	local source = slot.Source
	slot.Amount -= amount
	slot.Protected = math.max(0, (slot.Protected or 0) - protectedRemoved)
	if slot.Amount <= 0 then slots[slotIndex] = false end
	if not silent then fireChanged(player) end
	return itemName, amount, protectedRemoved, source
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

	Debris:AddItem(model, 90)
	return model
end

function InventoryService.DropFromSlot(player, slotIndex, amount)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local slots = inventories[player]
	local slot = slots and slots[slotIndex]
	if not root then return false, "Character is not ready." end
	if not slot then return false, "That slot is empty." end
	if (slot.Protected or 0) > 0 then return false, "Protected kit items cannot be dropped." end
	local itemName, removed = InventoryService.RemoveFromSlot(player, slotIndex, amount, true)
	if not itemName then return false, "That slot is empty." end
	InventoryService.CreateWorldDrop(root.Position + root.CFrame.LookVector * 4, itemName, removed)
	fireChanged(player)
	return true, `Dropped {SurvivalItemData.Items[itemName].Label}.`
end

function InventoryService.ClearToWorld(player, position)
	local slots = inventories[player]
	if not slots then return { KeptAll = false, Dropped = 0 } end
	if ownsInsurance(player) then
		fireChanged(player)
		return { KeptAll = true, Dropped = 0 }
	end

	local dropped = 0
	for i = 1, InventoryService.SLOT_COUNT do
		local slot = slots[i]
		if slot then
			local protected = math.clamp(slot.Protected or 0, 0, slot.Amount)
			local loose = slot.Amount - protected
			if loose > 0 then
				InventoryService.CreateWorldDrop(position, slot.Item, loose)
				dropped += loose
			end
			if protected > 0 then
				slot.Amount = protected
				slot.Protected = protected
			else
				slots[i] = false
			end
		end
	end
	fireChanged(player)
	return { KeptAll = false, Dropped = dropped }
end

function InventoryService.Init()
	tryEnableStore()
	Players.PlayerAdded:Connect(InventoryService.Load)
	Players.PlayerRemoving:Connect(function(player)
		InventoryService.Save(player)
		inventories[player] = nil
		insuranceCache[player] = nil
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
