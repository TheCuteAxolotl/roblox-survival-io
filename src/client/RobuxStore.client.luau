local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RobuxStore"
gui.ResetOnSpawn = false
gui.DisplayOrder = 115
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = instance
end

local open = Instance.new("TextButton")
open.AnchorPoint = Vector2.new(1, 0)
-- Dedicated second-row slot: HATS | SHOP on row one, R$ STORE | INVENTORY on row two.
-- INVENTORY occupies the far-right slot, so keep a fixed gap to its left.
open.Position = UDim2.new(1, -154, 0, 72)
open.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 104 or 112, 38)
open.BackgroundColor3 = Color3.fromRGB(54, 88, 62)
open.TextColor3 = Color3.fromRGB(245, 245, 245)
open.Text = "R$ STORE"
open.Font = Enum.Font.GothamBold
open.TextSize = 13
open.Parent = gui
corner(open, 10)

local shade = Instance.new("TextButton")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.48
shade.Text = ""
shade.AutoButtonColor = false
shade.Visible = false
shade.ZIndex = 100
shade.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(600, 540)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.Visible = false
panel.ZIndex = 101
panel.Parent = gui
corner(panel, 16)

local size = Instance.new("UISizeConstraint")
size.MinSize = Vector2.new(330, 430)
size.MaxSize = Vector2.new(600, 540)
size.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -70, 0, 32)
title.BackgroundTransparency = 1
title.Text = "PREMIUM STORE"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 21
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 102
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 10)
close.Size = UDim2.fromOffset(38, 36)
close.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "×"
close.Font = Enum.Font.GothamBold
close.TextSize = 24
close.ZIndex = 103
close.Parent = panel
corner(close, 9)

local note = Instance.new("TextLabel")
note.Position = UDim2.fromOffset(18, 48)
note.Size = UDim2.new(1, -36, 0, 50)
note.BackgroundTransparency = 1
note.Text = "Optional purchases only. Gold persists between sessions. Kit passes permanently unlock starter kits; Inventory Insurance keeps your 10-slot bag on death, but resources still drop."
note.TextColor3 = Color3.fromRGB(185, 185, 193)
note.TextWrapped = true
note.Font = Enum.Font.Gotham
note.TextSize = 11
note.TextXAlignment = Enum.TextXAlignment.Left
note.ZIndex = 102
note.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 100)
status.Size = UDim2.new(1, -36, 0, 28)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(235, 205, 112)
status.Font = Enum.Font.GothamBold
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 102
status.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(14, 132)
list.Size = UDim2.new(1, -28, 1, -146)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 102
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function displayName(raw)
	return raw:gsub("(%l)(%u)", "%1 %2")
end

local function addCard(name, description, price, id, isPass, order)
	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.Size = UDim2.new(1, -6, 0, 84)
	card.BackgroundColor3 = Color3.fromRGB(34, 34, 39)
	card.ZIndex = 102
	card.Parent = list
	corner(card, 12)

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(12, 8)
	label.Size = UDim2.new(1, -132, 0, 24)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 103
	label.Parent = card

	local details = Instance.new("TextLabel")
	details.Position = UDim2.fromOffset(12, 34)
	details.Size = UDim2.new(1, -132, 0, 42)
	details.BackgroundTransparency = 1
	details.Text = description
	details.TextColor3 = Color3.fromRGB(178, 178, 187)
	details.Font = Enum.Font.Gotham
	details.TextSize = 10
	details.TextWrapped = true
	details.TextXAlignment = Enum.TextXAlignment.Left
	details.TextYAlignment = Enum.TextYAlignment.Top
	details.ZIndex = 103
	details.Parent = card

	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -10, 0.5, 0)
	buy.Size = UDim2.fromOffset(108, 50)
	buy.BackgroundColor3 = id > 0 and Color3.fromRGB(230, 230, 234) or Color3.fromRGB(74, 74, 80)
	buy.TextColor3 = id > 0 and Color3.fromRGB(22, 22, 24) or Color3.fromRGB(190, 190, 198)
	buy.Text = id > 0 and `{price} R$\nBUY` or `{price} R$\nCONNECT ID`
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 11
	buy.TextWrapped = true
	buy.ZIndex = 103
	buy.Parent = card
	corner(buy, 10)
	buy.Activated:Connect(function()
		if not id or id <= 0 then
			status.Text = "This purchase is disabled until its Roblox product/pass ID is connected."
			return
		end
		if isPass then MarketplaceService:PromptGamePassPurchase(player, id) else MarketplaceService:PromptProductPurchase(player, id) end
	end)
end

local order = 0
for _, productName in { "GoldPouch", "GoldChest", "GoldVault", "GoldTreasury", "GoldFortune" } do
	local data = MonetizationConfig.DeveloperProducts[productName]
	if data then
		order += 1
		local gold = data.Grant and data.Grant.Gold or 0
		addCard(displayName(productName), `Adds {gold} permanent gold to your account.`, data.RobuxLabel or 0, data.Id or 0, false, order)
	end
end

for _, passName in { "InventoryInsurance", "ExplorerStarter", "HunterStarter", "BuilderStarter", "AlchemistStarter", "DragonbornStarter", "VIP" } do
	local data = MonetizationConfig.GamePasses[passName]
	if data then
		order += 1
		local description = data.Description
		if not description and data.PremiumKit then description = `Permanently unlocks the {displayName(data.PremiumKit)} starter kit.` end
		if not description then description = "Permanent premium account perk." end
		addCard(displayName(passName), description, data.RobuxLabel or 0, data.Id or 0, true, order)
	end
end

local function setVisible(value)
	panel.Visible = value
	shade.Visible = value
end
open.Activated:Connect(function() setVisible(not panel.Visible) end)
close.Activated:Connect(function() setVisible(false) end)
shade.Activated:Connect(function() setVisible(false) end)
