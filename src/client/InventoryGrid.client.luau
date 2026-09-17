local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local SLOT_COUNT = 10
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

local function rarityColor(itemName)
	local item = itemName and SurvivalItemData.Items[itemName]
	local rarity = item and item.Rarity or "Common"
	return SurvivalItemData.RarityColors[rarity] or Color3.fromRGB(210, 210, 210)
end

-- Rename the launcher so new players immediately know where their items are.
for _, child in hud:GetChildren() do
	if child:IsA("TextButton") and child.Text == "BAG" then
		child.Text = "INVENTORY"
		child.Size = UDim2.fromOffset(124, 38)
	end
end

-- Rename the panel header created by the original survival HUD.
for _, child in bagPanel:GetChildren() do
	if child:IsA("TextLabel") and string.find(child.Text, "SURVIVAL BAG", 1, true) == 1 then
		child.Text = "INVENTORY — 10 SLOTS"
	end
end

-- InventoryCraftingUpgrade creates a scrolling ten-slot list. Keep its logic alive,
-- but hide that presentation and replace it with a grid where every slot is visible.
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

local function rebuild()
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

-- Desktop convenience. Mobile players use the visible INVENTORY button.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.I then
		bagPanel.Visible = not bagPanel.Visible
	end
end)
