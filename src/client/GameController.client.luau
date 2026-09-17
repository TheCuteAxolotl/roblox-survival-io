local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local getShop = remotes:WaitForChild("GetShop")

local selectedItem = "Axe"
local currentProfile = nil
local rotation = 0
local placementValid = false
local shopLoaded = false
local weaponParts = {}
local hotbarButtons = {}
local unlockedOrder = {}
local choiceSignature = nil

local cameraModes = {
	{ Name = "TACTICAL", Offset = Vector3.new(0, 50, 40), LookHeight = 0 },
	{ Name = "ADVENTURE", Offset = Vector3.new(0, 31, 31), LookHeight = 1.5 },
	{ Name = "CLOSE", Offset = Vector3.new(0, 18, 20), LookHeight = 2.2 },
}
local cameraModeIndex = 1

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local cameraModeButton = Instance.new("TextButton")
cameraModeButton.Name = "CameraModeButton"
cameraModeButton.AnchorPoint = Vector2.new(1, 0)
cameraModeButton.Position = UDim2.new(1, -18, 0, 18)
cameraModeButton.Size = UDim2.fromOffset(132, 34)
cameraModeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
cameraModeButton.BackgroundTransparency = 0.22
cameraModeButton.TextColor3 = Color3.fromRGB(235, 235, 242)
cameraModeButton.Font = Enum.Font.GothamBold
cameraModeButton.TextSize = 10
cameraModeButton.ZIndex = 45
cameraModeButton.Parent = gui
local cameraCorner = Instance.new("UICorner")
cameraCorner.CornerRadius = UDim.new(0, 9)
cameraCorner.Parent = cameraModeButton
local cameraStroke = Instance.new("UIStroke")
cameraStroke.Color = Color3.fromRGB(255, 255, 255)
cameraStroke.Transparency = 0.86
cameraStroke.Parent = cameraModeButton

local function refreshCameraModeButton()
	local mode = cameraModes[cameraModeIndex]
	cameraModeButton.Text = UserInputService.TouchEnabled and ("CAMERA: " .. mode.Name) or ("CAMERA: " .. mode.Name .. " [C]")
end

local function cycleCameraMode()
	cameraModeIndex = cameraModeIndex % #cameraModes + 1
	refreshCameraModeButton()
end

cameraModeButton.Activated:Connect(cycleCameraMode)
refreshCameraModeButton()

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = instance
end

local function stroke(instance, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = transparency
	s.Thickness = 1
	s.Parent = instance
end

local function formatCost(cost)
	if type(cost) ~= "table" then return "" end
	local pieces = {}
	for _, resource in { "Wood", "Stone", "Food", "Gold" } do
		local amount = cost[resource]
		if amount and amount > 0 then
			table.insert(pieces, `{amount} {resource:lower()}`)
		end
	end
	return table.concat(pieces, " + ")
end

local statsFrame = Instance.new("Frame")
statsFrame.Position = UDim2.fromOffset(16, 16)
statsFrame.Size = UDim2.fromOffset(382, 108)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
statsFrame.BackgroundTransparency = 0.06
statsFrame.Parent = gui
corner(statsFrame, 12)
stroke(statsFrame, 0.82)

local stats = Instance.new("TextLabel")
stats.Position = UDim2.fromOffset(14, 8)
stats.Size = UDim2.new(1, -28, 0, 58)
stats.BackgroundTransparency = 1
stats.TextColor3 = Color3.fromRGB(245, 245, 245)
stats.Font = Enum.Font.GothamBold
stats.TextSize = 14
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextYAlignment = Enum.TextYAlignment.Top
stats.TextWrapped = true
stats.Parent = statsFrame

local xpBack = Instance.new("Frame")
xpBack.Position = UDim2.fromOffset(14, 74)
xpBack.Size = UDim2.new(1, -28, 0, 20)
xpBack.BackgroundColor3 = Color3.fromRGB(46, 46, 50)
xpBack.Parent = statsFrame
corner(xpBack, 8)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(104, 170, 255)
xpFill.Parent = xpBack
corner(xpFill, 8)

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.fromScale(1, 1)
xpText.BackgroundTransparency = 1
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.Font = Enum.Font.GothamBold
xpText.TextSize = 11
xpText.Parent = xpBack

local healthFrame = Instance.new("Frame")
healthFrame.Position = UDim2.fromOffset(16, 134)
healthFrame.Size = UDim2.fromOffset(250, 24)
healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
healthFrame.Parent = gui
corner(healthFrame, 10)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(205, 72, 72)
healthFill.Parent = healthFrame
corner(healthFill, 10)

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.fromScale(1, 1)
healthText.BackgroundTransparency = 1
healthText.Text = "100 HP"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 13
healthText.Parent = healthFrame

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0, 18)
status.Size = UDim2.fromOffset(520, 40)
status.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
status.BackgroundTransparency = 0.16
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.GothamBold
status.TextSize = 14
status.Text = "Gather resources, build a base, and survive."
status.Parent = gui
corner(status, 10)

local shopButton = Instance.new("TextButton")
shopButton.AnchorPoint = Vector2.new(1, 0)
shopButton.Position = UDim2.new(1, -18, 0, 18)
shopButton.Size = UDim2.fromOffset(112, 42)
shopButton.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
shopButton.TextColor3 = Color3.fromRGB(245, 245, 245)
shopButton.Text = "SHOP"
shopButton.Font = Enum.Font.GothamBold
shopButton.TextSize = 14
shopButton.Parent = gui
corner(shopButton, 10)
stroke(shopButton, 0.82)

local hotbar = Instance.new("ScrollingFrame")
hotbar.Name = "Hotbar"
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -18)
hotbar.Size = UDim2.new(1, -34, 0, 78)
hotbar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
hotbar.BackgroundTransparency = 0.05
hotbar.BorderSizePixel = 0
hotbar.ScrollBarThickness = 3
hotbar.ScrollingDirection = Enum.ScrollingDirection.X
hotbar.AutomaticCanvasSize = Enum.AutomaticSize.X
hotbar.CanvasSize = UDim2.new()
hotbar.Parent = gui
corner(hotbar, 14)
stroke(hotbar, 0.82)

local hotbarConstraint = Instance.new("UISizeConstraint")
hotbarConstraint.MaxSize = Vector2.new(940, 78)
hotbarConstraint.MinSize = Vector2.new(380, 78)
hotbarConstraint.Parent = hotbar

local hotbarPadding = Instance.new("UIPadding")
hotbarPadding.PaddingLeft = UDim.new(0, 10)
hotbarPadding.PaddingRight = UDim.new(0, 10)
hotbarPadding.PaddingTop = UDim.new(0, 10)
hotbarPadding.PaddingBottom = UDim.new(0, 10)
hotbarPadding.Parent = hotbar

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 7)
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.Parent = hotbar

local shopPanel = Instance.new("Frame")
shopPanel.AnchorPoint = Vector2.new(1, 0.5)
shopPanel.Position = UDim2.new(1, -20, 0.5, 0)
shopPanel.Size = UDim2.fromOffset(390, 470)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
shopPanel.Visible = false
shopPanel.ZIndex = 20
shopPanel.Parent = gui
corner(shopPanel, 16)
stroke(shopPanel, 0.78)

local shopTitle = Instance.new("TextLabel")
shopTitle.Position = UDim2.fromOffset(18, 12)
shopTitle.Size = UDim2.new(1, -70, 0, 36)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "SURVIVAL SHOP"
shopTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 20
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.ZIndex = 21
shopTitle.Parent = shopPanel

local closeShop = Instance.new("TextButton")
closeShop.AnchorPoint = Vector2.new(1, 0)
closeShop.Position = UDim2.new(1, -12, 0, 12)
closeShop.Size = UDim2.fromOffset(38, 36)
closeShop.BackgroundColor3 = Color3.fromRGB(48, 48, 53)
closeShop.Text = "×"
closeShop.TextColor3 = Color3.new(1, 1, 1)
closeShop.TextSize = 24
closeShop.Font = Enum.Font.GothamBold
closeShop.ZIndex = 21
closeShop.Parent = shopPanel
corner(closeShop, 9)
closeShop.Activated:Connect(function() shopPanel.Visible = false end)

local shopNote = Instance.new("TextLabel")
shopNote.Position = UDim2.fromOffset(18, 52)
shopNote.Size = UDim2.new(1, -36, 0, 46)
shopNote.BackgroundTransparency = 1
shopNote.Text = "Optional purchases. Core weapons and progression are earned by playing."
shopNote.TextColor3 = Color3.fromRGB(178, 178, 186)
shopNote.TextWrapped = true
shopNote.TextSize = 12
shopNote.Font = Enum.Font.Gotham
shopNote.TextXAlignment = Enum.TextXAlignment.Left
shopNote.ZIndex = 21
shopNote.Parent = shopPanel

local shopList = Instance.new("ScrollingFrame")
shopList.Position = UDim2.fromOffset(14, 104)
shopList.Size = UDim2.new(1, -28, 1, -118)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 5
shopList.CanvasSize = UDim2.new()
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.ZIndex = 21
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

local choiceShade = Instance.new("Frame")
choiceShade.Size = UDim2.fromScale(1, 1)
choiceShade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
choiceShade.BackgroundTransparency = 0.38
choiceShade.Visible = false
choiceShade.ZIndex = 50
choiceShade.Parent = gui

local choicePanel = Instance.new("Frame")
choicePanel.AnchorPoint = Vector2.new(0.5, 0.5)
choicePanel.Position = UDim2.fromScale(0.5, 0.5)
choicePanel.Size = UDim2.fromOffset(650, 330)
choicePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
choicePanel.ZIndex = 51
choicePanel.Parent = choiceShade
corner(choicePanel, 18)
stroke(choicePanel, 0.68)

local choiceTitle = Instance.new("TextLabel")
choiceTitle.Position = UDim2.fromOffset(18, 16)
choiceTitle.Size = UDim2.new(1, -36, 0, 42)
choiceTitle.BackgroundTransparency = 1
choiceTitle.Text = "AGE UP — CHOOSE ONE"
choiceTitle.TextColor3 = Color3.fromRGB(255, 226, 117)
choiceTitle.Font = Enum.Font.GothamBold
choiceTitle.TextSize = 25
choiceTitle.ZIndex = 52
choiceTitle.Parent = choicePanel

local choiceSubtitle = Instance.new("TextLabel")
choiceSubtitle.Position = UDim2.fromOffset(24, 58)
choiceSubtitle.Size = UDim2.new(1, -48, 0, 38)
choiceSubtitle.BackgroundTransparency = 1
choiceSubtitle.Text = "Your choice becomes a permanent unlock for this progression path."
choiceSubtitle.TextColor3 = Color3.fromRGB(183, 183, 190)
choiceSubtitle.Font = Enum.Font.Gotham
choiceSubtitle.TextSize = 13
choiceSubtitle.TextWrapped = true
choiceSubtitle.ZIndex = 52
choiceSubtitle.Parent = choicePanel

local choiceContainer = Instance.new("Frame")
choiceContainer.Position = UDim2.fromOffset(20, 106)
choiceContainer.Size = UDim2.new(1, -40, 1, -126)
choiceContainer.BackgroundTransparency = 1
choiceContainer.ZIndex = 52
choiceContainer.Parent = choicePanel

local choiceLayout = Instance.new("UIListLayout")
choiceLayout.FillDirection = Enum.FillDirection.Horizontal
choiceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
choiceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
choiceLayout.Padding = UDim.new(0, 14)
choiceLayout.Parent = choiceContainer

local preview = Instance.new("Part")
preview.Name = "LocalBuildPreview"
preview.Anchored = true
preview.CanCollide = false
preview.CanQuery = false
preview.CanTouch = false
preview.Material = Enum.Material.ForceField
preview.Transparency = 1
preview.Parent = workspace

local function itemStatsText(item)
	if item.Category == "Weapon" then
		return `Damage {item.Damage or 0}  •  Reach {item.Range or 0}  •  Speed {string.format("%.2fs", item.Cooldown or 0)}`
	elseif item.Category == "Build" then
		return `HP {item.Health or 0}  •  {formatCost(item.Cost)}`
	end
	return ""
end

local function addShopCard(titleText, detailText, robux, id, isPass)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -6, 0, 92)
	card.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
	card.ZIndex = 21
	card.Parent = shopList
	corner(card, 12)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.fromOffset(12, 8)
	titleLabel.Size = UDim2.new(1, -124, 0, 24)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 22
	titleLabel.Parent = card

	local detail = Instance.new("TextLabel")
	detail.Position = UDim2.fromOffset(12, 34)
	detail.Size = UDim2.new(1, -124, 0, 48)
	detail.BackgroundTransparency = 1
	detail.Text = detailText
	detail.TextColor3 = Color3.fromRGB(175, 175, 184)
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 11
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.ZIndex = 22
	detail.Parent = card

	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -10, 0.5, 0)
	buy.Size = UDim2.fromOffset(102, 50)
	buy.BackgroundColor3 = Color3.fromRGB(235, 235, 238)
	buy.TextColor3 = Color3.fromRGB(20, 20, 22)
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 12
	buy.TextWrapped = true
	buy.Text = id and id > 0 and `{robux} R$\nBUY` or `{robux} R$\nNOT CONNECTED`
	buy.ZIndex = 22
	buy.Parent = card
	corner(buy, 10)
	buy.Activated:Connect(function()
		if not id or id <= 0 then
			status.Text = "Publish the experience and connect the Roblox product ID first."
			return
		end
		if isPass then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
end

local function populateShop()
	if shopLoaded then return end
	local ok, catalog = pcall(function() return getShop:InvokeServer() end)
	if not ok or type(catalog) ~= "table" then
		status.Text = "Could not load shop catalog."
		return
	end
	local products = catalog.DeveloperProducts or {}
	for _, name in { "SmallResourceCrate", "LargeResourceCrate", "GoldPack" } do
		local data = products[name]
		if data then
			local grant = data.Grant or {}
			local description = string.format("Wood %d • Stone %d • Food %d • Gold %d", grant.Wood or 0, grant.Stone or 0, grant.Food or 0, grant.Gold or 0)
			addShopCard(name:gsub("(%l)(%u)", "%1 %2"), description, data.RobuxLabel or 0, data.Id or 0, false)
		end
	end
	local passes = catalog.GamePasses or {}
	for _, name in { "VIP", "Builder" } do
		local data = passes[name]
		if data then
			local description = name == "VIP" and "Permanent VIP cosmetics and badge." or "Builder convenience perks without exclusive combat power."
			addShopCard(`${name} Pass`, description, data.RobuxLabel or 0, data.Id or 0, true)
		end
	end
	shopLoaded = true
end

shopButton.Activated:Connect(function()
	populateShop()
	shopPanel.Visible = not shopPanel.Visible
end)

local function updateButtonSelection()
	for itemName, button in hotbarButtons do
		local active = itemName == selectedItem
		button.BackgroundColor3 = active and Color3.fromRGB(238, 238, 241) or Color3.fromRGB(42, 42, 46)
		button.TextColor3 = active and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(245, 245, 245)
	end
end

local function clearWeaponVisual()
	for _, p in weaponParts do
		if p and p.Parent then p:Destroy() end
	end
	weaponParts = {}
end

local function attachWeaponVisual()
	clearWeaponVisual()
	local item = ItemData.Items[selectedItem]
	if not item or item.Category ~= "Weapon" then return end
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	if not hand or not hand:IsA("BasePart") then return end

	local handle = Instance.new("Part")
	handle.Name = "LocalWeaponHandle"
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(108, 76, 48)
	handle.Size = Vector3.new(0.25, 2.5, 0.25)
	if item.Visual == "Spear" then handle.Size = Vector3.new(0.22, 4.8, 0.22) end
	handle.CFrame = hand.CFrame * CFrame.new(0, -1.05, -0.35) * CFrame.Angles(math.rad(18), 0, math.rad(-14))
	handle.Parent = character

	local head = Instance.new("Part")
	head.Name = "LocalWeaponHead"
	head.CanCollide = false
	head.CanQuery = false
	head.Massless = true
	head.Material = Enum.Material.Metal
	head.Color = Color3.fromRGB(118, 122, 130)

	if item.Visual == "Sword" or item.Visual == "Katana" then
		handle.Size = Vector3.new(0.3, 1.15, 0.3)
		head.Size = item.Visual == "Katana" and Vector3.new(0.22, 4, 0.38) or Vector3.new(0.32, 3.2, 0.42)
		head.CFrame = handle.CFrame * CFrame.new(0, 2, 0)
	elseif item.Visual == "Pickaxe" then
		head.Size = Vector3.new(2.6, 0.45, 0.42)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.08, 0)
	elseif item.Visual == "Hammer" then
		head.Size = Vector3.new(2.2, 1.05, 1.05)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.1, 0)
	elseif item.Visual == "Spear" then
		head.Size = Vector3.new(0.55, 1.5, 0.55)
		head.CFrame = handle.CFrame * CFrame.new(0, 3.0, 0)
	elseif item.Visual == "BattleAxe" then
		head.Size = Vector3.new(2.2, 1.35, 0.5)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.15, 0)
	else
		head.Size = Vector3.new(1.35, 0.75, 0.38)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.05, 0)
	end
	head.Parent = character

	local handleWeld = Instance.new("WeldConstraint")
	handleWeld.Part0 = hand
	handleWeld.Part1 = handle
	handleWeld.Parent = handle
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = handle
	headWeld.Part1 = head
	headWeld.Parent = head
	weaponParts = { handle, head }
end

local function selectItem(itemName)
	local item = ItemData.Items[itemName]
	if not item or not currentProfile or not currentProfile.Unlocks or currentProfile.Unlocks[itemName] ~= true then return end
	selectedItem = itemName
	action:FireServer("SelectItem", itemName)
	updateButtonSelection()
	attachWeaponVisual()
	if item.Category == "Build" then
		status.Text = `${item.Label}: {formatCost(item.Cost)}${item.Rotatable and " • R rotates" or ""}`
	elseif item.Category == "Consumable" then
		status.Text = "Food selected — click or press Q to heal."
	else
		status.Text = `${item.Label}: {item.Description}`
	end
end

local function rebuildHotbar(profile)
	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	hotbarButtons = {}
	unlockedOrder = {}
	local unlocks = profile and profile.Unlocks or {}

	for _, itemName in ItemData.HotbarOrder do
		if unlocks[itemName] == true then
			table.insert(unlockedOrder, itemName)
			local item = ItemData.Items[itemName]
			local slot = #unlockedOrder
			local button = Instance.new("TextButton")
			button.Name = itemName
			button.LayoutOrder = slot
			button.Size = UDim2.fromOffset(112, 56)
			button.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
			button.TextColor3 = Color3.fromRGB(245, 245, 245)
			button.TextWrapped = true
			button.Font = Enum.Font.GothamBold
			button.TextSize = 12
			button.Text = slot <= 9 and `{slot}  {string.upper(item.Label)}` or string.upper(item.Label)
			button.Parent = hotbar
			corner(button, 10)
			button.Activated:Connect(function() selectItem(itemName) end)
			hotbarButtons[itemName] = button
		end
	end
	if unlocks[selectedItem] ~= true then selectedItem = "Axe" end
	updateButtonSelection()
end

local function updateChoicePanel(profile)
	local pending = profile and profile.PendingChoice
	if type(pending) ~= "table" or type(pending.Age) ~= "number" or type(pending.Options) ~= "table" then
		choiceShade.Visible = false
		choiceSignature = nil
		return
	end

	local signature = tostring(pending.Age) .. ":" .. table.concat(pending.Options, ",")
	choiceShade.Visible = true
	if signature == choiceSignature then return end
	choiceSignature = signature
	choiceTitle.Text = `AGE {pending.Age} — CHOOSE ONE`

	for _, child in choiceContainer:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, itemName in pending.Options do
		local item = ItemData.Items[itemName]
		if item then
			local card = Instance.new("Frame")
			card.Size = UDim2.fromOffset(290, 190)
			card.BackgroundColor3 = Color3.fromRGB(36, 36, 41)
			card.ZIndex = 52
			card.Parent = choiceContainer
			corner(card, 14)
			stroke(card, 0.82)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Position = UDim2.fromOffset(14, 12)
			nameLabel.Size = UDim2.new(1, -28, 0, 30)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = string.upper(item.Label)
			nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 19
			nameLabel.ZIndex = 53
			nameLabel.Parent = card

			local description = Instance.new("TextLabel")
			description.Position = UDim2.fromOffset(14, 48)
			description.Size = UDim2.new(1, -28, 0, 62)
			description.BackgroundTransparency = 1
			description.Text = item.Description or ""
			description.TextColor3 = Color3.fromRGB(187, 187, 195)
			description.Font = Enum.Font.Gotham
			description.TextSize = 13
			description.TextWrapped = true
			description.TextYAlignment = Enum.TextYAlignment.Top
			description.ZIndex = 53
			description.Parent = card

			local statsLabel = Instance.new("TextLabel")
			statsLabel.Position = UDim2.fromOffset(14, 112)
			statsLabel.Size = UDim2.new(1, -28, 0, 28)
			statsLabel.BackgroundTransparency = 1
			statsLabel.Text = itemStatsText(item)
			statsLabel.TextColor3 = Color3.fromRGB(255, 220, 115)
			statsLabel.Font = Enum.Font.GothamMedium
			statsLabel.TextSize = 11
			statsLabel.TextWrapped = true
			statsLabel.ZIndex = 53
			statsLabel.Parent = card

			local choose = Instance.new("TextButton")
			choose.AnchorPoint = Vector2.new(0.5, 1)
			choose.Position = UDim2.new(0.5, 0, 1, -12)
			choose.Size = UDim2.new(1, -28, 0, 38)
			choose.BackgroundColor3 = Color3.fromRGB(235, 235, 238)
			choose.TextColor3 = Color3.fromRGB(18, 18, 20)
			choose.Text = "CHOOSE"
			choose.Font = Enum.Font.GothamBold
			choose.TextSize = 13
			choose.ZIndex = 53
			choose.Parent = card
			corner(choose, 10)
			choose.Activated:Connect(function()
				choose.Text = "UNLOCKING..."
				choose.Active = false
				action:FireServer("ChooseUpgrade", itemName)
			end)
		end
	end
end

local function refresh(profile)
	if type(profile) ~= "table" then return end
	local oldUnlockCount = currentProfile and currentProfile.Unlocks and 0 or nil
	if oldUnlockCount ~= nil then
		for _ in currentProfile.Unlocks do oldUnlockCount += 1 end
	end
	currentProfile = profile

	stats.Text = string.format(
		"WOOD %d   STONE %d   FOOD %d   GOLD %d\nAGE %d   TOTAL XP %d",
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Food or 0,
		profile.Gold or 0,
		profile.Age or 1,
		profile.XP or 0
	)

	local age = math.clamp(math.floor(profile.Age or 1), 1, #Config.AgeThresholds)
	local currentThreshold = Config.AgeThresholds[age] or 0
	local nextThreshold = Config.AgeThresholds[age + 1]
	if nextThreshold then
		local span = math.max(1, nextThreshold - currentThreshold)
		local progress = math.clamp(((profile.XP or 0) - currentThreshold) / span, 0, 1)
		xpFill.Size = UDim2.fromScale(progress, 1)
		xpText.Text = `AGE {age}  •  {math.floor(profile.XP or 0)}/{nextThreshold} XP`
	else
		xpFill.Size = UDim2.fromScale(1, 1)
		xpText.Text = `AGE {age}  •  MAX AGE`
	end

	local newUnlockCount = 0
	for _ in profile.Unlocks or {} do newUnlockCount += 1 end
	if oldUnlockCount == nil or oldUnlockCount ~= newUnlockCount then rebuildHotbar(profile) end
	updateChoicePanel(profile)
end

local function flashMessage(text, kind)
	if type(text) ~= "string" or text == "" then return end
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.42, 0)
	label.Size = UDim2.fromOffset(360, 52)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = kind == "Upgrade" and 28 or (kind == "KO" and 27 or 20)
	if kind == "Heal" then
		label.TextColor3 = Color3.fromRGB(128, 245, 144)
	elseif kind == "KO" then
		label.TextColor3 = Color3.fromRGB(255, 218, 92)
	elseif kind == "Upgrade" then
		label.TextColor3 = Color3.fromRGB(181, 145, 255)
	else
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	label.TextStrokeTransparency = 0.45
	label.Parent = gui
	TweenService:Create(label, TweenInfo.new(0.7), {
		Position = UDim2.new(0.5, 0, 0.36, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.75)
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.Profile then refresh(payload.Profile) end
	if payload.SelectedItem and currentProfile and currentProfile.Unlocks and currentProfile.Unlocks[payload.SelectedItem] then
		selectedItem = payload.SelectedItem
		updateButtonSelection()
	end
	if payload.Message then status.Text = payload.Message end
	if payload.FX and payload.Message then flashMessage(payload.Message, payload.FX.Kind) end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		selectedItem = initial.SelectedItem or "Axe"
		refresh(initial.Profile)
		attachWeaponVisual()
	end
end)

local function mousePlanePosition(planeY)
	camera = workspace.CurrentCamera
	if not camera then return nil end
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	if math.abs(ray.Direction.Y) < 0.0001 then return nil end
	local distance = (planeY - ray.Origin.Y) / ray.Direction.Y
	if distance <= 0 then return nil end
	return ray.Origin + ray.Direction * distance
end

local function snapped(position)
	return Vector3.new(math.floor(position.X + 0.5), 0, math.floor(position.Z + 0.5))
end

local function updatePlacementPreview()
	local item = ItemData.Items[selectedItem]
	if not item or item.Category ~= "Build" then
		preview.Transparency = 1
		placementValid = false
		return
	end
	local ground = mousePlanePosition(0)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not ground or not root then
		preview.Transparency = 1
		placementValid = false
		return
	end
	ground = snapped(ground)
	local insideMap = math.abs(ground.X) <= Config.WorldSize / 2 - 4 and math.abs(ground.Z) <= Config.WorldSize / 2 - 4
	local closeEnough = (Vector3.new(root.Position.X, 0, root.Position.Z) - ground).Magnitude <= Config.BuildDistance
	placementValid = insideMap and closeEnough
	preview.Transparency = 0.48
	preview.Color = placementValid and Color3.fromRGB(95, 235, 120) or Color3.fromRGB(245, 90, 90)
	preview.Size = item.PreviewSize or Vector3.new(5, 3, 5)
	preview.CFrame = CFrame.new(ground.X, item.PreviewY or preview.Size.Y / 2, ground.Z) * CFrame.Angles(0, math.rad(rotation), 0)
end

local function showSwing()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local item = ItemData.Items[selectedItem]
	local reach = item and item.Range or 14
	local slash = Instance.new("Part")
	slash.Name = "LocalSwing"
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(238, 238, 238)
	slash.Size = Vector3.new(0.18, 0.18, math.clamp(reach * 0.55, 6, 10))
	slash.Transparency = 0.15
	slash.CFrame = root.CFrame * CFrame.new(0, 1, -slash.Size.Z / 2) * CFrame.Angles(0, 0, math.rad(28))
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.16), { Transparency = 1, CFrame = slash.CFrame * CFrame.Angles(0, math.rad(34), 0) }):Play()
	Debris:AddItem(slash, 0.2)
end

local function clickAction()
	local item = ItemData.Items[selectedItem]
	if not item then return end
	if item.Category == "Consumable" then
		action:FireServer("Eat")
		return
	end
	if item.Category == "Build" then
		if not placementValid then
			status.Text = "Move the placement preview closer to your character."
			return
		end
		local position = mousePlanePosition(0)
		if position then action:FireServer("Build", { Type = selectedItem, Position = snapped(position), Rotation = rotation }) end
		return
	end

	showSwing()
	local target = mouse.Target
	if not target or (player.Character and target:IsDescendantOf(player.Character)) then return end
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		action:FireServer("Attack", target)
	elseif CollectionService:HasTag(target, "PlayerBuild") then
		action:FireServer("AttackBuild", target)
	else
		action:FireServer("Gather", target)
	end
end

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	attachWeaponVisual()
end)

local numberKeys = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
}

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for index, keyCode in numberKeys do
		if input.KeyCode == keyCode and unlockedOrder[index] then
			selectItem(unlockedOrder[index])
			return
		end
	end
	if input.KeyCode == Enum.KeyCode.C then
		cycleCameraMode()
	elseif input.KeyCode == Enum.KeyCode.Q then
		action:FireServer("Eat")
	elseif input.KeyCode == Enum.KeyCode.R then
		local item = ItemData.Items[selectedItem]
		if item and item.Category == "Build" and item.Rotatable then
			rotation = (rotation + 90) % 360
			status.Text = `Build rotation: {rotation}°`
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		clickAction()
	end
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		preview.Transparency = 1
		return
	end

	humanoid.AutoRotate = false
	local ground = mousePlanePosition(root.Position.Y)
	if ground and not choiceShade.Visible then
		local look = Vector3.new(ground.X, root.Position.Y, ground.Z)
		if (look - root.Position).Magnitude > 0.1 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

	local healthRatio = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 0
	healthFill.Size = UDim2.fromScale(math.clamp(healthRatio, 0, 1), 1)
	healthText.Text = `{math.ceil(humanoid.Health)} HP`

	camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		local mode = cameraModes[cameraModeIndex]
		local focus = root.Position + Vector3.new(0, mode.LookHeight or 0, 0)
		local target = CFrame.lookAt(root.Position + mode.Offset, focus)
		camera.CFrame = camera.CFrame:Lerp(target, 0.22)
	end

	updatePlacementPreview()
end)
