local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local SLOT_COUNT = 34
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SurvivalSystemsHUD")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("SurvivalAction")
local stateEvent = remotes:WaitForChild("SurvivalState")
local getState = remotes:WaitForChild("GetSurvivalState")

local bagPanel = hud:WaitForChild("BagPanel")
local craftPanel = hud:WaitForChild("CraftPanel")
local chestPanel = hud:WaitForChild("ChestPanel")
local current = { Inventory = {} }
local currentChest = nil
local selectedCategory = "All"

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function stroke(obj, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = transparency or 0.86
	s.Parent = obj
end

local function findHeader(panel, startsWith)
	for _, child in panel:GetChildren() do
		if child:IsA("TextLabel") and string.sub(child.Text, 1, #startsWith) == startsWith then return child end
	end
	return nil
end

local bagHeader = findHeader(bagPanel, "SURVIVAL BAG")
if bagHeader then bagHeader.Text = "SURVIVAL BAG — 34 SLOTS" end

-- Hide the legacy six-slot bag list. The original controller can keep updating it,
-- but this replacement is what the player actually sees.
for _, child in bagPanel:GetChildren() do
	if child:IsA("Frame") and child.BackgroundTransparency == 1 then child.Visible = false end
end

local bagList = Instance.new("ScrollingFrame")
bagList.Name = "TenSlotBagList"
bagList.Position = UDim2.fromOffset(12, 54)
bagList.Size = UDim2.new(1, -24, 1, -66)
bagList.BackgroundTransparency = 1
bagList.BorderSizePixel = 0
bagList.ScrollBarThickness = 5
bagList.AutomaticCanvasSize = Enum.AutomaticSize.Y
bagList.CanvasSize = UDim2.new()
bagList.ZIndex = 90
bagList.Parent = bagPanel
local bagLayout = Instance.new("UIListLayout")
bagLayout.Padding = UDim.new(0, 7)
bagLayout.Parent = bagList

local function rarityColor(itemName)
	local item = itemName and SurvivalItemData.Items[itemName]
	return SurvivalItemData.RarityColors[item and item.Rarity or "Common"] or Color3.fromRGB(210, 210, 210)
end

local function rebuildBag()
	for _, child in bagList:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	for slotIndex = 1, SLOT_COUNT do
		local slot = current.Inventory and current.Inventory[slotIndex]
		local row = Instance.new("Frame")
		row.LayoutOrder = slotIndex
		row.Size = UDim2.new(1, -6, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
		row.ZIndex = 91
		row.Parent = bagList
		corner(row, 10)

		local indexLabel = Instance.new("TextLabel")
		indexLabel.Position = UDim2.fromOffset(8, 0)
		indexLabel.Size = UDim2.fromOffset(30, 58)
		indexLabel.BackgroundTransparency = 1
		indexLabel.Text = tostring(slotIndex)
		indexLabel.TextColor3 = Color3.fromRGB(140, 140, 148)
		indexLabel.Font = Enum.Font.GothamBold
		indexLabel.TextSize = 13
		indexLabel.ZIndex = 92
		indexLabel.Parent = row

		local itemLabel = Instance.new("TextLabel")
		itemLabel.Position = UDim2.fromOffset(40, 5)
		itemLabel.Size = UDim2.new(1, -208, 1, -10)
		itemLabel.BackgroundTransparency = 1
		itemLabel.TextXAlignment = Enum.TextXAlignment.Left
		itemLabel.TextWrapped = true
		itemLabel.Font = Enum.Font.GothamBold
		itemLabel.TextSize = 12
		itemLabel.ZIndex = 92
		itemLabel.Parent = row

		if slot then
			local data = SurvivalItemData.Items[slot.Item]
			itemLabel.Text = `{data and data.Label or slot.Item}  x{slot.Amount}\n{data and data.Rarity or "Common"}`
			itemLabel.TextColor3 = rarityColor(slot.Item)

			local use = Instance.new("TextButton")
			use.Position = UDim2.new(1, -158, 0.5, -18)
			use.Size = UDim2.fromOffset(70, 36)
			use.BackgroundColor3 = data and data.Use and Color3.fromRGB(225, 225, 230) or Color3.fromRGB(67, 67, 73)
			use.TextColor3 = data and data.Use and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(150, 150, 156)
			use.Text = data and data.Use and "USE" or "MATERIAL"
			use.Font = Enum.Font.GothamBold
			use.TextSize = 10
			use.Active = data and data.Use ~= nil
			use.ZIndex = 92
			use.Parent = row
			corner(use, 8)
			if data and data.Use then
				use.Activated:Connect(function() action:FireServer("UseSlot", slotIndex) end)
			end

			local drop = Instance.new("TextButton")
			drop.Position = UDim2.new(1, -80, 0.5, -18)
			drop.Size = UDim2.fromOffset(70, 36)
			drop.BackgroundColor3 = Color3.fromRGB(102, 57, 57)
			drop.TextColor3 = Color3.fromRGB(245, 220, 220)
			drop.Text = "DROP 1"
			drop.Font = Enum.Font.GothamBold
			drop.TextSize = 10
			drop.ZIndex = 92
			drop.Parent = row
			corner(drop, 8)
			drop.Activated:Connect(function() action:FireServer("DropSlot", slotIndex) end)
		else
			itemLabel.Text = "EMPTY"
			itemLabel.TextColor3 = Color3.fromRGB(110, 110, 118)
		end
	end
end

-- Replace the single jumbo recipe list with categories.
for _, child in craftPanel:GetChildren() do
	if child:IsA("ScrollingFrame") then child.Visible = false end
end

local categoryBar = Instance.new("ScrollingFrame")
categoryBar.Name = "CraftCategoryBar"
categoryBar.Position = UDim2.fromOffset(12, 52)
categoryBar.Size = UDim2.new(1, -24, 0, 42)
categoryBar.BackgroundTransparency = 1
categoryBar.BorderSizePixel = 0
categoryBar.ScrollBarThickness = 2
categoryBar.ScrollingDirection = Enum.ScrollingDirection.X
categoryBar.AutomaticCanvasSize = Enum.AutomaticSize.X
categoryBar.CanvasSize = UDim2.new()
categoryBar.ZIndex = 90
categoryBar.Parent = craftPanel
local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 6)
categoryLayout.Parent = categoryBar

local recipeList = Instance.new("ScrollingFrame")
recipeList.Name = "CategorizedRecipeList"
recipeList.Position = UDim2.fromOffset(12, 101)
recipeList.Size = UDim2.new(1, -24, 1, -113)
recipeList.BackgroundTransparency = 1
recipeList.BorderSizePixel = 0
recipeList.ScrollBarThickness = 5
recipeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
recipeList.CanvasSize = UDim2.new()
recipeList.ZIndex = 90
recipeList.Parent = craftPanel
local recipeLayout = Instance.new("UIListLayout")
recipeLayout.Padding = UDim.new(0, 8)
recipeLayout.Parent = recipeList

local categoryButtons = {}

local function ingredientsText(recipe)
	local pieces = {}
	for resource, amount in recipe.Ingredients.Resources or {} do
		table.insert(pieces, `{amount} {string.lower(resource)}`)
	end
	for itemName, amount in recipe.Ingredients.Items or {} do
		local data = SurvivalItemData.Items[itemName]
		table.insert(pieces, `{amount}x {data and data.Label or itemName}`)
	end
	return #pieces > 0 and table.concat(pieces, " • ") or "Nothing"
end

local function resultText(recipe)
	local result = recipe.Result or {}
	local data = result.Item and SurvivalItemData.Items[result.Item]
	return `{result.Amount or 1}x {data and data.Label or result.Item or "Unknown"}`
end

local function refreshCategoryButtons()
	for category, button in categoryButtons do
		local selected = category == selectedCategory
		button.BackgroundColor3 = selected and Color3.fromRGB(225, 225, 232) or Color3.fromRGB(48, 48, 54)
		button.TextColor3 = selected and Color3.fromRGB(22, 22, 25) or Color3.fromRGB(235, 235, 240)
	end
end

local function rebuildCrafting()
	for _, child in recipeList:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	local shown = 0
	for index, recipeName in CraftingData.Order do
		local recipe = CraftingData.Recipes[recipeName]
		if recipe and (selectedCategory == "All" or recipe.Category == selectedCategory) then
			shown += 1
			local row = Instance.new("Frame")
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -6, 0, 108)
			row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
			row.ZIndex = 91
			row.Parent = recipeList
			corner(row, 10)

			local name = Instance.new("TextLabel")
			name.Position = UDim2.fromOffset(10, 7)
			name.Size = UDim2.new(1, -120, 0, 22)
			name.BackgroundTransparency = 1
			name.Text = `{recipe.Label}  •  {recipe.Rarity}`
			name.TextColor3 = SurvivalItemData.RarityColors[recipe.Rarity] or Color3.new(1, 1, 1)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 12
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.ZIndex = 92
			name.Parent = row

			local category = Instance.new("TextLabel")
			category.Position = UDim2.fromOffset(10, 30)
			category.Size = UDim2.new(1, -120, 0, 18)
			category.BackgroundTransparency = 1
			category.Text = `CATEGORY: {string.upper(recipe.Category or "OTHER")}   •   STATION: {string.upper(recipe.Station or "HAND")}`
			category.TextColor3 = Color3.fromRGB(155, 189, 225)
			category.Font = Enum.Font.GothamBold
			category.TextSize = 9
			category.TextXAlignment = Enum.TextXAlignment.Left
			category.ZIndex = 92
			category.Parent = row

			local requires = Instance.new("TextLabel")
			requires.Position = UDim2.fromOffset(10, 50)
			requires.Size = UDim2.new(1, -120, 0, 32)
			requires.BackgroundTransparency = 1
			requires.Text = `REQUIRES: {ingredientsText(recipe)}`
			requires.TextColor3 = Color3.fromRGB(184, 184, 194)
			requires.Font = Enum.Font.Gotham
			requires.TextSize = 10
			requires.TextWrapped = true
			requires.TextXAlignment = Enum.TextXAlignment.Left
			requires.TextYAlignment = Enum.TextYAlignment.Top
			requires.ZIndex = 92
			requires.Parent = row

			local makes = Instance.new("TextLabel")
			makes.Position = UDim2.fromOffset(10, 84)
			makes.Size = UDim2.new(1, -120, 0, 18)
			makes.BackgroundTransparency = 1
			makes.Text = `MAKES: {resultText(recipe)}`
			makes.TextColor3 = Color3.fromRGB(159, 218, 164)
			makes.Font = Enum.Font.GothamBold
			makes.TextSize = 9
			makes.TextXAlignment = Enum.TextXAlignment.Left
			makes.ZIndex = 92
			makes.Parent = row

			local craft = Instance.new("TextButton")
			craft.AnchorPoint = Vector2.new(1, 0.5)
			craft.Position = UDim2.new(1, -9, 0.5, 0)
			craft.Size = UDim2.fromOffset(96, 54)
			craft.BackgroundColor3 = Color3.fromRGB(230, 230, 234)
			craft.TextColor3 = Color3.fromRGB(20, 20, 22)
			craft.Text = "CRAFT"
			craft.Font = Enum.Font.GothamBold
			craft.TextSize = 11
			craft.ZIndex = 92
			craft.Parent = row
			corner(craft, 9)
			craft.Activated:Connect(function() action:FireServer("Craft", recipeName) end)
		end
	end

	if shown == 0 then
		local empty = Instance.new("Frame")
		empty.Size = UDim2.new(1, -6, 0, 70)
		empty.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
		empty.ZIndex = 91
		empty.Parent = recipeList
		corner(empty, 10)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "No recipes in this category yet."
		label.TextColor3 = Color3.fromRGB(170, 170, 180)
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.ZIndex = 92
		label.Parent = empty
	end
end

for order, category in CraftingData.Categories do
	local button = Instance.new("TextButton")
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(math.max(76, #category * 9 + 24), 34)
	button.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
	button.TextColor3 = Color3.fromRGB(235, 235, 240)
	button.Text = string.upper(category)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.ZIndex = 91
	button.Parent = categoryBar
	corner(button, 9)
	categoryButtons[category] = button
	button.Activated:Connect(function()
		selectedCategory = category
		refreshCategoryButtons()
		recipeList.CanvasPosition = Vector2.zero
		rebuildCrafting()
	end)
end
refreshCategoryButtons()
rebuildCrafting()

-- Replace the chest's six-slot bag section so all ten bag slots can be stored.
for _, child in chestPanel:GetChildren() do
	if child:IsA("Frame") and child.BackgroundTransparency == 1 then child.Visible = false end
end

local chestContent = Instance.new("ScrollingFrame")
chestContent.Name = "ThirtyFourSlotChestContent"
chestContent.Position = UDim2.fromOffset(12, 54)
chestContent.Size = UDim2.new(1, -24, 1, -66)
chestContent.BackgroundTransparency = 1
chestContent.BorderSizePixel = 0
chestContent.ScrollBarThickness = 5
chestContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
chestContent.CanvasSize = UDim2.new()
chestContent.ZIndex = 90
chestContent.Parent = chestPanel

local function rebuildChest()
	for _, child in chestContent:GetChildren() do child:Destroy() end
	if not currentChest then return end

	local chestLabel = Instance.new("TextLabel")
	chestLabel.Size = UDim2.new(1, 0, 0, 22)
	chestLabel.BackgroundTransparency = 1
	chestLabel.Text = "CHEST — TAP TO TAKE"
	chestLabel.TextColor3 = Color3.fromRGB(190, 190, 198)
	chestLabel.Font = Enum.Font.GothamBold
	chestLabel.TextSize = 10
	chestLabel.ZIndex = 91
	chestLabel.Parent = chestContent

	for i = 1, 8 do
		local slot = currentChest.Slots and currentChest.Slots[i]
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local button = Instance.new("TextButton")
		button.Position = UDim2.new(col * 0.25, 3, 0, 30 + row * 68)
		button.Size = UDim2.new(0.25, -8, 0, 60)
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
		button.TextColor3 = slot and rarityColor(slot.Item) or Color3.fromRGB(105, 105, 112)
		button.Text = slot and `{SurvivalItemData.Items[slot.Item].Label}\nx{slot.Amount} • TAKE` or "EMPTY"
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.TextSize = 9
		button.ZIndex = 91
		button.Parent = chestContent
		corner(button, 8)
		if slot then
			button.Activated:Connect(function() action:FireServer("ChestWithdraw", { Id = currentChest.Id, Slot = i }) end)
		end
	end

	local bagLabel = Instance.new("TextLabel")
	bagLabel.Position = UDim2.fromOffset(0, 172)
	bagLabel.Size = UDim2.new(1, 0, 0, 22)
	bagLabel.BackgroundTransparency = 1
	bagLabel.Text = "YOUR 34-SLOT BAG — TAP TO STORE"
	bagLabel.TextColor3 = Color3.fromRGB(230, 230, 234)
	bagLabel.Font = Enum.Font.GothamBold
	bagLabel.TextSize = 10
	bagLabel.ZIndex = 91
	bagLabel.Parent = chestContent

	for i = 1, SLOT_COUNT do
		local slot = current.Inventory and current.Inventory[i]
		local col = (i - 1) % 5
		local row = math.floor((i - 1) / 5)
		local button = Instance.new("TextButton")
		button.Position = UDim2.new(col * 0.2, 2, 0, 202 + row * 72)
		button.Size = UDim2.new(0.2, -6, 0, 64)
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
		button.TextColor3 = slot and rarityColor(slot.Item) or Color3.fromRGB(105, 105, 112)
		button.Text = slot and `{i}. {SurvivalItemData.Items[slot.Item].Label}\nx{slot.Amount}` or `{i}. EMPTY`
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.TextSize = 8
		button.ZIndex = 91
		button.Parent = chestContent
		corner(button, 8)
		if slot then
			button.Activated:Connect(function() action:FireServer("ChestDeposit", { Id = currentChest.Id, Slot = i }) end)
		end
	end
end

-- Replace the old quick-eat button so food in slots 7-10 is recognized too.
task.spawn(function()
	local legacy = playerGui:WaitForChild("ActionAssistHUD", 8)
	if not legacy then return end
	local oldEat = legacy:FindFirstChild("QuickEat")
	if oldEat and oldEat:IsA("GuiObject") then oldEat.Visible = false end

	local quickEat = Instance.new("TextButton")
	quickEat.Name = "QuickEat10"
	quickEat.Position = UDim2.fromOffset(16, 260)
	quickEat.Size = UDim2.fromOffset(126, 36)
	quickEat.BackgroundColor3 = Color3.fromRGB(61, 61, 66)
	quickEat.TextColor3 = Color3.fromRGB(245, 245, 245)
	quickEat.Text = "EAT FOOD"
	quickEat.Font = Enum.Font.GothamBold
	quickEat.TextSize = 11
	quickEat.ZIndex = 65
	quickEat.Parent = hud
	corner(quickEat, 9)
	stroke(quickEat, 0.82)

	local foodPriority = { "Food", "CookedBeef", "TrailRation", "BoneBroth", "CookedMeat" }
	local function bestFoodSlot()
		for _, wanted in foodPriority do
			for index = 1, SLOT_COUNT do
				local slot = current.Inventory and current.Inventory[index]
				if slot and slot.Item == wanted and slot.Amount > 0 then return index, wanted end
			end
		end
		for index = 1, SLOT_COUNT do
			local slot = current.Inventory and current.Inventory[index]
			local data = slot and SurvivalItemData.Items[slot.Item]
			if data and (data.Use == "Food" or data.Use == "Meal") then return index, slot.Item end
		end
		return nil, nil
	end

	local function refreshQuickEat()
		local _, itemName = bestFoodSlot()
		if itemName then
			local data = SurvivalItemData.Items[itemName]
			quickEat.Text = `EAT: {string.upper(data and data.Label or itemName)}`
			quickEat.BackgroundColor3 = Color3.fromRGB(65, 104, 67)
		else
			quickEat.Text = "EAT FOOD"
			quickEat.BackgroundColor3 = Color3.fromRGB(61, 61, 66)
		end
	end

	quickEat.Activated:Connect(function()
		local slot = bestFoodSlot()
		if slot then action:FireServer("UseSlot", slot) end
	end)
	refreshQuickEat()
	stateEvent.OnClientEvent:Connect(refreshQuickEat)
end)

local function applyState(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Inventory) == "table" then current.Inventory = payload.Inventory end
	if payload.OpenChest then currentChest = payload.OpenChest end
	if bagPanel.Visible then rebuildBag() end
	if chestPanel.Visible then rebuildChest() end
end

stateEvent.OnClientEvent:Connect(applyState)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		applyState(initial)
		rebuildBag()
	end
end)
