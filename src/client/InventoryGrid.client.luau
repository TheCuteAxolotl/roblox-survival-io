local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local SLOT_COUNT = 10
local QUICK_SLOT_COUNT = 5
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SurvivalSystemsHUD")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("SurvivalAction")
local stateEvent = remotes:WaitForChild("SurvivalState")
local getState = remotes:WaitForChild("GetSurvivalState")

local bagPanel = hud:WaitForChild("BagPanel")
local currentInventory = {}

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

local function rarityColor(itemName)
	local item = itemName and SurvivalItemData.Items[itemName]
	local rarity = item and item.Rarity or "Common"
	return SurvivalItemData.RarityColors[rarity] or Color3.fromRGB(210, 210, 210)
end

-- The backpack next to the bottom quick slots is now the only inventory launcher.
for _, child in hud:GetChildren() do
	if child:IsA("TextButton") and (child.Text == "BAG" or child.Text == "INVENTORY") then
		child.Visible = false
	end
end

for _, child in bagPanel:GetChildren() do
	if child:IsA("TextLabel") and string.find(child.Text, "SURVIVAL BAG", 1, true) == 1 then
		child.Text = "INVENTORY — 10 SLOTS"
	end
end

-- InventoryCraftingUpgrade creates a scrolling ten-slot list. Keep its state logic,
-- but hide that presentation and use this fixed grid where every slot is visible.
task.spawn(function()
	local old = bagPanel:WaitForChild("TenSlotBagList", 15)
	if old and old:IsA("GuiObject") then old.Visible = false end
end)

local help = Instance.new("TextLabel")
help.Name = "InventoryHelp"
help.Position = UDim2.fromOffset(16, 44)
help.Size = UDim2.new(1, -32, 0, 25)
help.BackgroundTransparency = 1
help.Text = UserInputService.TouchEnabled and "ALL 10 SLOTS • TAP USE OR DROP" or "ALL 10 SLOTS • PRESS I TO OPEN/CLOSE • USE OR DROP"
help.TextColor3 = Color3.fromRGB(165, 165, 175)
help.Font = Enum.Font.GothamBold
help.TextSize = 9
help.TextXAlignment = Enum.TextXAlignment.Left
help.ZIndex = 96
help.Parent = bagPanel

local grid = Instance.new("Frame")
grid.Name = "InventoryGrid10"
grid.Position = UDim2.fromOffset(12, 72)
grid.Size = UDim2.new(1, -24, 1, -84)
grid.BackgroundTransparency = 1
grid.ZIndex = 95
grid.Parent = bagPanel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.5, -5, 0, 68)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.FillDirectionMaxCells = 2
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

-- Compact quick inventory directly above the tool hotbar.
local quickWidth = UserInputService.TouchEnabled and 250 or 320
local quickHeight = 42
local quickBar = Instance.new("Frame")
quickBar.Name = "QuickInventoryBar"
quickBar.AnchorPoint = Vector2.new(0.5, 1)
quickBar.Position = UDim2.new(0.5, 0, 1, -64)
quickBar.Size = UDim2.fromOffset(quickWidth, quickHeight)
quickBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
quickBar.BackgroundTransparency = 0.66
quickBar.BorderSizePixel = 0
quickBar.ZIndex = 60
quickBar.Parent = hud
corner(quickBar, 9)
stroke(quickBar, 0.9)

local quickLayout = Instance.new("UIListLayout")
quickLayout.FillDirection = Enum.FillDirection.Horizontal
quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
quickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
quickLayout.Padding = UDim.new(0, 4)
quickLayout.Parent = quickBar

local backpack = Instance.new("TextButton")
backpack.Name = "BackpackButton"
backpack.AnchorPoint = Vector2.new(1, 1)
backpack.Position = UDim2.new(0.5, -(quickWidth / 2 + 7), 1, -64)
backpack.Size = UDim2.fromOffset(42, 42)
backpack.BackgroundColor3 = Color3.fromRGB(31, 31, 36)
backpack.BackgroundTransparency = 0.16
backpack.Text = "🎒"
backpack.TextColor3 = Color3.fromRGB(245, 245, 245)
backpack.Font = Enum.Font.GothamBold
backpack.TextSize = 21
backpack.ZIndex = 61
backpack.Parent = hud
corner(backpack, 10)
stroke(backpack, 0.82)
backpack.Activated:Connect(function()
	bagPanel.Visible = not bagPanel.Visible
end)

local function rebuildFullInventory()
	for _, child in grid:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	for slotIndex = 1, SLOT_COUNT do
		local slot = currentInventory[slotIndex]
		local data = slot and SurvivalItemData.Items[slot.Item]
		local card = Instance.new("Frame")
		card.Name = `Slot{slotIndex}`
		card.LayoutOrder = slotIndex
		card.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
		card.ZIndex = 96
		card.Parent = grid
		corner(card, 10)

		local slotNumber = Instance.new("TextLabel")
		slotNumber.Position = UDim2.fromOffset(7, 5)
		slotNumber.Size = UDim2.fromOffset(24, 18)
		slotNumber.BackgroundTransparency = 1
		slotNumber.Text = tostring(slotIndex)
		slotNumber.TextColor3 = Color3.fromRGB(125, 125, 134)
		slotNumber.Font = Enum.Font.GothamBold
		slotNumber.TextSize = 10
		slotNumber.ZIndex = 97
		slotNumber.Parent = card

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(30, 4)
		name.Size = UDim2.new(1, -37, 0, 30)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 10
		name.TextWrapped = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextYAlignment = Enum.TextYAlignment.Top
		name.ZIndex = 97
		name.Parent = card

		if slot then
			name.Text = `{data and data.Label or slot.Item}  x{slot.Amount}\n{data and data.Rarity or "Common"}`
			name.TextColor3 = rarityColor(slot.Item)

			local use = Instance.new("TextButton")
			use.Position = UDim2.new(0, 7, 1, -29)
			use.Size = UDim2.new(0.5, -10, 0, 23)
			use.BackgroundColor3 = data and data.Use and Color3.fromRGB(225, 225, 230) or Color3.fromRGB(65, 65, 70)
			use.TextColor3 = data and data.Use and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(145, 145, 152)
			use.Text = data and data.Use and "USE" or "MATERIAL"
			use.Font = Enum.Font.GothamBold
			use.TextSize = 9
			use.Active = data and data.Use ~= nil
			use.ZIndex = 98
			use.Parent = card
			corner(use, 7)
			if data and data.Use then
				use.Activated:Connect(function() action:FireServer("UseSlot", slotIndex) end)
			end

			local drop = Instance.new("TextButton")
			drop.AnchorPoint = Vector2.new(1, 0)
			drop.Position = UDim2.new(1, -7, 1, -29)
			drop.Size = UDim2.new(0.5, -10, 0, 23)
			drop.BackgroundColor3 = Color3.fromRGB(100, 56, 56)
			drop.TextColor3 = Color3.fromRGB(245, 220, 220)
			drop.Text = "DROP 1"
			drop.Font = Enum.Font.GothamBold
			drop.TextSize = 9
			drop.ZIndex = 98
			drop.Parent = card
			corner(drop, 7)
			drop.Activated:Connect(function() action:FireServer("DropSlot", slotIndex) end)
		else
			name.Text = "EMPTY SLOT"
			name.TextColor3 = Color3.fromRGB(104, 104, 112)
		end
	end
end

local function rebuildQuickSlots()
	for _, child in quickBar:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local slotWidth = math.floor((quickWidth - 24) / QUICK_SLOT_COUNT)
	for slotIndex = 1, QUICK_SLOT_COUNT do
		local slot = currentInventory[slotIndex]
		local data = slot and SurvivalItemData.Items[slot.Item]
		local button = Instance.new("TextButton")
		button.Name = `QuickSlot{slotIndex}`
		button.LayoutOrder = slotIndex
		button.Size = UDim2.fromOffset(slotWidth, 34)
		button.BackgroundColor3 = Color3.fromRGB(38, 38, 43)
		button.BackgroundTransparency = slot and 0.14 or 0.46
		button.TextColor3 = slot and rarityColor(slot.Item) or Color3.fromRGB(120, 120, 128)
		button.Font = Enum.Font.GothamBold
		button.TextSize = UserInputService.TouchEnabled and 8 or 9
		button.TextWrapped = true
		button.Text = slot and `{data and data.Label or slot.Item}\nx{slot.Amount}` or `SLOT {slotIndex}\nEMPTY`
		button.ZIndex = 61
		button.Parent = quickBar
		corner(button, 7)
		button.Activated:Connect(function()
			if slot and data and data.Use then
				action:FireServer("UseSlot", slotIndex)
			else
				bagPanel.Visible = true
			end
		end)
	end
end

local function rebuild()
	rebuildFullInventory()
	rebuildQuickSlots()
end

local function applyState(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Inventory) == "table" then
		currentInventory = payload.Inventory
		rebuild()
	end
end

stateEvent.OnClientEvent:Connect(applyState)

task.spawn(function()
	local ok, state = pcall(function() return getState:InvokeServer() end)
	if ok and type(state) == "table" then
		applyState(state)
	else
		rebuild()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.I then
		bagPanel.Visible = not bagPanel.Visible
	end
end)
