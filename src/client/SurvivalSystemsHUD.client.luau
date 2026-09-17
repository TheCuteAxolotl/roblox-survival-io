local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingData = require(ReplicatedStorage.Shared.CraftingData)
local KitData = require(ReplicatedStorage.Shared.KitData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("SurvivalAction")
local stateEvent = remotes:WaitForChild("SurvivalState")
local getState = remotes:WaitForChild("GetSurvivalState")

local current = { Hunger = 100, Thirst = 100, Inventory = {}, Gold = 0, Biome = "Grass", Buffs = {} }
local currentChest = nil

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalSystemsHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function stroke(obj, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = transparency or 0.82
	s.Parent = obj
end

local function makeButton(text, pos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(112, 38)
	b.Position = pos
	b.AnchorPoint = Vector2.new(1, 0)
	b.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	b.TextColor3 = Color3.fromRGB(245, 245, 245)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Parent = gui
	corner(b, 9)
	stroke(b)
	return b
end

local needsPanel = Instance.new("Frame")
needsPanel.Position = UDim2.fromOffset(16, 168)
needsPanel.Size = UDim2.fromOffset(250, 84)
needsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
needsPanel.BackgroundTransparency = 0.08
needsPanel.Parent = gui
needsPanel.Visible = false -- V3 focuses HUD attention on combat/run progression.
corner(needsPanel, 11)
stroke(needsPanel)

local biomeLabel = Instance.new("TextLabel")
biomeLabel.Position = UDim2.fromOffset(10, 5)
biomeLabel.Size = UDim2.new(1, -20, 0, 18)
biomeLabel.BackgroundTransparency = 1
biomeLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
biomeLabel.Font = Enum.Font.GothamBold
biomeLabel.TextSize = 11
biomeLabel.TextXAlignment = Enum.TextXAlignment.Left
biomeLabel.Parent = needsPanel

local function makeNeedBar(y, labelText, fillColor)
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(10, y)
	label.Size = UDim2.fromOffset(58, 22)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(235, 235, 238)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = needsPanel
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(68, y + 3)
	back.Size = UDim2.fromOffset(170, 16)
	back.BackgroundColor3 = Color3.fromRGB(52, 52, 56)
	back.Parent = needsPanel
	corner(back, 7)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.Parent = back
	corner(fill, 7)
	local value = Instance.new("TextLabel")
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.TextColor3 = Color3.new(1, 1, 1)
	value.Font = Enum.Font.GothamBold
	value.TextSize = 9
	value.Parent = back
	return fill, value
end

local hungerFill, hungerText = makeNeedBar(28, "HUNGER", Color3.fromRGB(214, 160, 73))
local thirstFill, thirstText = makeNeedBar(53, "THIRST", Color3.fromRGB(74, 161, 222))

local bagButton = makeButton("BAG", UDim2.new(1, -18, 0, 72))
local craftButton = makeButton("CRAFT", UDim2.new(1, -18, 0, 116))
local kitsButton = makeButton("KITS", UDim2.new(1, -18, 0, 160))

local function makePanel(name, width, height)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -145, 0.5, 20)
	panel.Size = UDim2.fromOffset(width, height)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	panel.Visible = false
	panel.ZIndex = 80
	panel.Parent = gui
	corner(panel, 14)
	stroke(panel, 0.76)
	return panel
end

local bagPanel = makePanel("BagPanel", 410, 470)
local craftPanel = makePanel("CraftPanel", 500, 570)
local kitsPanel = makePanel("KitsPanel", 420, 500)
local chestPanel = makePanel("ChestPanel", 520, 520)

local function addHeader(panel, text)
	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -64, 0, 34)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextColor3 = Color3.fromRGB(248, 248, 248)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 81
	title.Parent = panel
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(36, 34)
	close.BackgroundColor3 = Color3.fromRGB(49, 49, 54)
	close.Text = "×"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 22
	close.ZIndex = 82
	close.Parent = panel
	corner(close, 8)
	close.Activated:Connect(function() panel.Visible = false end)
	return title
end

local bagTitle = addHeader(bagPanel, "SURVIVAL BAG — 34 SLOTS")
local craftTitle = addHeader(craftPanel, "CRAFTING")
local kitsTitle = addHeader(kitsPanel, "SURVIVAL KITS")
local chestTitle = addHeader(chestPanel, "CHEST")

local message = Instance.new("TextLabel")
message.AnchorPoint = Vector2.new(0.5, 0)
message.Position = UDim2.new(0.5, 0, 0, 64)
message.Size = UDim2.fromOffset(520, 32)
message.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
message.BackgroundTransparency = 0.14
message.TextColor3 = Color3.fromRGB(245, 245, 245)
message.Font = Enum.Font.GothamBold
message.TextSize = 12
message.Visible = false
message.ZIndex = 120
message.Parent = gui
corner(message, 8)

local messageToken = 0
local function showMessage(text)
	if type(text) ~= "string" or text == "" then return end
	messageToken += 1
	local token = messageToken
	message.Text = text
	message.Visible = true
	task.delay(2.5, function() if token == messageToken then message.Visible = false end end)
end

local bagList = Instance.new("Frame")
bagList.Position = UDim2.fromOffset(12, 54)
bagList.Size = UDim2.new(1, -24, 1, -66)
bagList.BackgroundTransparency = 1
bagList.ZIndex = 81
bagList.Parent = bagPanel
local bagLayout = Instance.new("UIListLayout")
bagLayout.Padding = UDim.new(0, 7)
bagLayout.Parent = bagList

local function rarityColor(itemName)
	local item = itemName and SurvivalItemData.Items[itemName]
	return SurvivalItemData.RarityColors[item and item.Rarity or "Common"] or Color3.fromRGB(210, 210, 210)
end

local function rebuildBag()
	for _, child in bagList:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
	for slotIndex = 1, 34 do
		local slot = current.Inventory and current.Inventory[slotIndex]
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
		row.ZIndex = 82
		row.Parent = bagList
		corner(row, 10)
		local indexLabel = Instance.new("TextLabel")
		indexLabel.Position = UDim2.fromOffset(8, 0)
		indexLabel.Size = UDim2.fromOffset(32, 58)
		indexLabel.BackgroundTransparency = 1
		indexLabel.Text = tostring(slotIndex)
		indexLabel.TextColor3 = Color3.fromRGB(140, 140, 148)
		indexLabel.Font = Enum.Font.GothamBold
		indexLabel.TextSize = 13
		indexLabel.ZIndex = 83
		indexLabel.Parent = row
		local itemLabel = Instance.new("TextLabel")
		itemLabel.Position = UDim2.fromOffset(42, 5)
		itemLabel.Size = UDim2.new(1, -210, 1, -10)
		itemLabel.BackgroundTransparency = 1
		itemLabel.TextXAlignment = Enum.TextXAlignment.Left
		itemLabel.TextWrapped = true
		itemLabel.Font = Enum.Font.GothamBold
		itemLabel.TextSize = 12
		itemLabel.ZIndex = 83
		itemLabel.Parent = row
		if slot then
			local data = SurvivalItemData.Items[slot.Item]
			itemLabel.Text = `${data and data.Label or slot.Item}  x{slot.Amount}\n{data and data.Rarity or "Common"}`
			itemLabel.TextColor3 = rarityColor(slot.Item)
			local use = Instance.new("TextButton")
			use.Position = UDim2.new(1, -160, 0.5, -18)
			use.Size = UDim2.fromOffset(72, 36)
			use.BackgroundColor3 = data and data.Use and Color3.fromRGB(225, 225, 230) or Color3.fromRGB(67, 67, 73)
			use.TextColor3 = data and data.Use and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(150, 150, 156)
			use.Text = data and data.Use and "USE" or "MATERIAL"
			use.Font = Enum.Font.GothamBold
			use.TextSize = 10
			use.Active = data and data.Use ~= nil
			use.ZIndex = 83
			use.Parent = row
			corner(use, 8)
			if data and data.Use then use.Activated:Connect(function() action:FireServer("UseSlot", slotIndex) end) end
			local drop = Instance.new("TextButton")
			drop.Position = UDim2.new(1, -82, 0.5, -18)
			drop.Size = UDim2.fromOffset(72, 36)
			drop.BackgroundColor3 = Color3.fromRGB(102, 57, 57)
			drop.TextColor3 = Color3.fromRGB(245, 220, 220)
			drop.Text = "DROP 1"
			drop.Font = Enum.Font.GothamBold
			drop.TextSize = 10
			drop.ZIndex = 83
			drop.Parent = row
			corner(drop, 8)
			drop.Activated:Connect(function() action:FireServer("DropSlot", slotIndex) end)
		else
			itemLabel.Text = "EMPTY"
			itemLabel.TextColor3 = Color3.fromRGB(110, 110, 118)
		end
	end
end

local craftList = Instance.new("ScrollingFrame")
craftList.Position = UDim2.fromOffset(12, 54)
craftList.Size = UDim2.new(1, -24, 1, -66)
craftList.BackgroundTransparency = 1
craftList.BorderSizePixel = 0
craftList.ScrollBarThickness = 5
craftList.AutomaticCanvasSize = Enum.AutomaticSize.Y
craftList.CanvasSize = UDim2.new()
craftList.ZIndex = 81
craftList.Parent = craftPanel
local craftLayout = Instance.new("UIListLayout")
craftLayout.Padding = UDim.new(0, 7)
craftLayout.Parent = craftList

local function ingredientsText(recipe)
	local pieces = {}
	for resource, amount in recipe.Ingredients.Resources or {} do table.insert(pieces, `{amount} {resource}`) end
	for itemName, amount in recipe.Ingredients.Items or {} do
		local data = SurvivalItemData.Items[itemName]
		table.insert(pieces, `{amount}x {data and data.Label or itemName}`)
	end
	return table.concat(pieces, "  •  ")
end

local function rebuildCrafting()
	for _, child in craftList:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
	for index, recipeName in CraftingData.Order do
		local recipe = CraftingData.Recipes[recipeName]
		if recipe then
			local row = Instance.new("Frame")
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -6, 0, 82)
			row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
			row.ZIndex = 82
			row.Parent = craftList
			corner(row, 10)
			local name = Instance.new("TextLabel")
			name.Position = UDim2.fromOffset(10, 7)
			name.Size = UDim2.new(1, -120, 0, 22)
			name.BackgroundTransparency = 1
			name.Text = `${recipe.Label}  •  ${recipe.Rarity}`
			name.TextColor3 = SurvivalItemData.RarityColors[recipe.Rarity] or Color3.new(1, 1, 1)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 12
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.ZIndex = 83
			name.Parent = row
			local detail = Instance.new("TextLabel")
			detail.Position = UDim2.fromOffset(10, 30)
			detail.Size = UDim2.new(1, -120, 0, 46)
			detail.BackgroundTransparency = 1
			detail.Text = `[${string.upper(recipe.Station)}]  ${ingredientsText(recipe)}`
			detail.TextColor3 = Color3.fromRGB(180, 180, 190)
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 10
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.TextYAlignment = Enum.TextYAlignment.Top
			detail.ZIndex = 83
			detail.Parent = row
			local craft = Instance.new("TextButton")
			craft.AnchorPoint = Vector2.new(1, 0.5)
			craft.Position = UDim2.new(1, -9, 0.5, 0)
			craft.Size = UDim2.fromOffset(96, 48)
			craft.BackgroundColor3 = Color3.fromRGB(230, 230, 234)
			craft.TextColor3 = Color3.fromRGB(20, 20, 22)
			craft.Text = "CRAFT"
			craft.Font = Enum.Font.GothamBold
			craft.TextSize = 11
			craft.ZIndex = 83
			craft.Parent = row
			corner(craft, 9)
			craft.Activated:Connect(function() action:FireServer("Craft", recipeName) end)
		end
	end
end

local kitsList = Instance.new("Frame")
kitsList.Position = UDim2.fromOffset(12, 54)
kitsList.Size = UDim2.new(1, -24, 1, -66)
kitsList.BackgroundTransparency = 1
kitsList.ZIndex = 81
kitsList.Parent = kitsPanel
local kitsLayout = Instance.new("UIListLayout")
kitsLayout.Padding = UDim.new(0, 7)
kitsLayout.Parent = kitsList

local function rebuildKits()
	for _, child in kitsList:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
	kitsTitle.Text = `SURVIVAL KITS — {current.Gold or 0} GOLD`
	for index, kitName in KitData.Order do
		local kit = KitData.Kits[kitName]
		local row = Instance.new("Frame")
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 76)
		row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
		row.ZIndex = 82
		row.Parent = kitsList
		corner(row, 10)
		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(10, 7)
		name.Size = UDim2.new(1, -120, 0, 22)
		name.BackgroundTransparency = 1
		name.Text = kit.Label
		name.TextColor3 = Color3.fromRGB(245, 245, 245)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 12
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 83
		name.Parent = row
		local detail = Instance.new("TextLabel")
		detail.Position = UDim2.fromOffset(10, 29)
		detail.Size = UDim2.new(1, -120, 0, 40)
		detail.BackgroundTransparency = 1
		detail.Text = kit.Description
		detail.TextColor3 = Color3.fromRGB(180, 180, 188)
		detail.Font = Enum.Font.Gotham
		detail.TextSize = 10
		detail.TextWrapped = true
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.ZIndex = 83
		detail.Parent = row
		local buy = Instance.new("TextButton")
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -8, 0.5, 0)
		buy.Size = UDim2.fromOffset(98, 48)
		buy.BackgroundColor3 = (current.Gold or 0) >= kit.Cost and Color3.fromRGB(230, 230, 234) or Color3.fromRGB(70, 70, 76)
		buy.TextColor3 = (current.Gold or 0) >= kit.Cost and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(160, 160, 166)
		buy.Text = `{kit.Cost} GOLD`
		buy.Font = Enum.Font.GothamBold
		buy.TextSize = 10
		buy.ZIndex = 83
		buy.Parent = row
		corner(buy, 9)
		buy.Activated:Connect(function() action:FireServer("BuyKit", kitName) end)
	end
end

local chestContentFrame = Instance.new("Frame")
chestContentFrame.Position = UDim2.fromOffset(12, 54)
chestContentFrame.Size = UDim2.new(1, -24, 1, -66)
chestContentFrame.BackgroundTransparency = 1
chestContentFrame.ZIndex = 81
chestContentFrame.Parent = chestPanel

local function rebuildChest()
	for _, child in chestContentFrame:GetChildren() do child:Destroy() end
	if not currentChest then return end
	local chestLabel = Instance.new("TextLabel")
	chestLabel.Size = UDim2.new(1, 0, 0, 22)
	chestLabel.BackgroundTransparency = 1
	chestLabel.Text = "CHEST ITEMS — click TAKE     |     BAG ITEMS — click STORE"
	chestLabel.TextColor3 = Color3.fromRGB(190, 190, 198)
	chestLabel.Font = Enum.Font.GothamBold
	chestLabel.TextSize = 10
	chestLabel.ZIndex = 82
	chestLabel.Parent = chestContentFrame
	for i = 1, 8 do
		local slot = currentChest.Slots and currentChest.Slots[i]
		local button = Instance.new("TextButton")
		button.Position = UDim2.fromOffset(((i - 1) % 4) * 118, 30 + math.floor((i - 1) / 4) * 70)
		button.Size = UDim2.fromOffset(108, 60)
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
		button.TextColor3 = slot and rarityColor(slot.Item) or Color3.fromRGB(105, 105, 112)
		button.Text = slot and `${SurvivalItemData.Items[slot.Item].Label}\nx{slot.Amount}  • TAKE` or "EMPTY"
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.TextSize = 9
		button.ZIndex = 82
		button.Parent = chestContentFrame
		corner(button, 8)
		if slot then button.Activated:Connect(function() action:FireServer("ChestWithdraw", { Id = currentChest.Id, Slot = i }) end) end
	end
	local invTitle = Instance.new("TextLabel")
	invTitle.Position = UDim2.fromOffset(0, 178)
	invTitle.Size = UDim2.new(1, 0, 0, 22)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "YOUR BAG"
	invTitle.TextColor3 = Color3.fromRGB(230, 230, 234)
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextSize = 11
	invTitle.ZIndex = 82
	invTitle.Parent = chestContentFrame
	for i = 1, 34 do
		local slot = current.Inventory and current.Inventory[i]
		local button = Instance.new("TextButton")
		button.Position = UDim2.fromOffset(((i - 1) % 3) * 158, 206 + math.floor((i - 1) / 3) * 74)
		button.Size = UDim2.fromOffset(148, 64)
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
		button.TextColor3 = slot and rarityColor(slot.Item) or Color3.fromRGB(105, 105, 112)
		button.Text = slot and `${SurvivalItemData.Items[slot.Item].Label}\nx{slot.Amount}  • STORE` or "EMPTY"
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.TextSize = 9
		button.ZIndex = 82
		button.Parent = chestContentFrame
		corner(button, 8)
		if slot then button.Activated:Connect(function() action:FireServer("ChestDeposit", { Id = currentChest.Id, Slot = i }) end) end
	end
end

local function closeOtherPanels(except)
	for _, panel in { bagPanel, craftPanel, kitsPanel, chestPanel } do if panel ~= except then panel.Visible = false end end
end

bagButton.Activated:Connect(function() closeOtherPanels(bagPanel) bagPanel.Visible = not bagPanel.Visible rebuildBag() end)
craftButton.Activated:Connect(function() closeOtherPanels(craftPanel) craftPanel.Visible = not craftPanel.Visible craftTitle.Text = "CRAFTING — HAND / NEARBY STATIONS" rebuildCrafting() end)
kitsButton.Activated:Connect(function() closeOtherPanels(kitsPanel) kitsPanel.Visible = not kitsPanel.Visible rebuildKits() end)

local function refreshNeeds()
	local hunger = math.clamp(current.Hunger or 0, 0, 100)
	local thirst = math.clamp(current.Thirst or 0, 0, 100)
	hungerFill.Size = UDim2.fromScale(hunger / 100, 1)
	thirstFill.Size = UDim2.fromScale(thirst / 100, 1)
	hungerText.Text = `${math.floor(hunger)}%`
	thirstText.Text = `${math.floor(thirst)}%`
	biomeLabel.Text = `BIOME: ${string.upper(current.Biome or "Grass")}`
end

local function applyState(payload)
	if type(payload) ~= "table" then return end
	for key, value in payload do
		if key ~= "OpenChest" and key ~= "OpenCrafting" and key ~= "Message" then current[key] = value end
	end
	if payload.OpenChest then
		currentChest = payload.OpenChest
		closeOtherPanels(chestPanel)
		chestPanel.Visible = true
		rebuildChest()
	end
	if payload.OpenCrafting then
		closeOtherPanels(craftPanel)
		craftPanel.Visible = true
		craftTitle.Text = `CRAFTING — ${string.upper(payload.OpenCrafting)}`
		rebuildCrafting()
	end
	if payload.Message then showMessage(payload.Message) end
	refreshNeeds()
	if bagPanel.Visible then rebuildBag() end
	if kitsPanel.Visible then rebuildKits() end
	if chestPanel.Visible then rebuildChest() end
end

stateEvent.OnClientEvent:Connect(applyState)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then applyState(initial) end
end)
