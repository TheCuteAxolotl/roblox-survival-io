local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HatData = require(ReplicatedStorage.Shared.HatData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SurvivalHUD")

local currentProfile = nil

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = instance
end

local hatsButton = Instance.new("TextButton")
hatsButton.Name = "HatsButton"
hatsButton.AnchorPoint = Vector2.new(1, 0)
hatsButton.Position = UDim2.new(1, -142, 0, 18)
hatsButton.Size = UDim2.fromOffset(112, 42)
hatsButton.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
hatsButton.TextColor3 = Color3.fromRGB(245, 245, 245)
hatsButton.Text = "HATS"
hatsButton.Font = Enum.Font.GothamBold
hatsButton.TextSize = 14
hatsButton.Parent = gui
corner(hatsButton, 10)

local panel = Instance.new("Frame")
panel.Name = "HatShopPanel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -20, 0.5, 0)
panel.Size = UDim2.fromOffset(410, 520)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
panel.Visible = false
panel.ZIndex = 70
panel.Parent = gui
corner(panel, 16)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Transparency = 0.8
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -74, 0, 34)
title.BackgroundTransparency = 1
title.Text = "HAT SHOP"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 71
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 12)
close.Size = UDim2.fromOffset(38, 36)
close.BackgroundColor3 = Color3.fromRGB(48, 48, 53)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 24
close.ZIndex = 71
close.Parent = panel
corner(close, 9)
close.Activated:Connect(function() panel.Visible = false end)

local note = Instance.new("TextLabel")
note.Position = UDim2.fromOffset(18, 50)
note.Size = UDim2.new(1, -36, 0, 42)
note.BackgroundTransparency = 1
note.Text = "Buy hats with earned gold. Each hat has one gameplay effect and appears on your character."
note.TextColor3 = Color3.fromRGB(180, 180, 188)
note.Font = Enum.Font.Gotham
note.TextSize = 12
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Left
note.ZIndex = 71
note.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(14, 98)
list.Size = UDim2.new(1, -28, 1, -112)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 71
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function rebuild()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	local inventory = currentProfile and currentProfile.HatInventory or {}
	local equipped = currentProfile and currentProfile.EquippedHat or nil
	local gold = currentProfile and currentProfile.Gold or 0

	for index, hatName in HatData.Order do
		local hat = HatData.Hats[hatName]
		if hat then
			local card = Instance.new("Frame")
			card.LayoutOrder = index
			card.Size = UDim2.new(1, -6, 0, 104)
			card.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
			card.ZIndex = 72
			card.Parent = list
			corner(card, 12)

			local swatch = Instance.new("Frame")
			swatch.Position = UDim2.fromOffset(12, 14)
			swatch.Size = UDim2.fromOffset(54, 54)
			swatch.BackgroundColor3 = hat.Color
			swatch.ZIndex = 73
			swatch.Parent = card
			corner(swatch, 12)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Position = UDim2.fromOffset(78, 10)
			nameLabel.Size = UDim2.new(1, -188, 0, 24)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = hat.Label
			nameLabel.TextColor3 = Color3.fromRGB(248, 248, 248)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.ZIndex = 73
			nameLabel.Parent = card

			local description = Instance.new("TextLabel")
			description.Position = UDim2.fromOffset(78, 35)
			description.Size = UDim2.new(1, -188, 0, 56)
			description.BackgroundTransparency = 1
			description.Text = hat.Description
			description.TextColor3 = Color3.fromRGB(185, 185, 194)
			description.Font = Enum.Font.Gotham
			description.TextSize = 11
			description.TextWrapped = true
			description.TextXAlignment = Enum.TextXAlignment.Left
			description.TextYAlignment = Enum.TextYAlignment.Top
			description.ZIndex = 73
			description.Parent = card

			local buy = Instance.new("TextButton")
			buy.AnchorPoint = Vector2.new(1, 0.5)
			buy.Position = UDim2.new(1, -10, 0.5, 0)
			buy.Size = UDim2.fromOffset(102, 58)
			buy.Font = Enum.Font.GothamBold
			buy.TextSize = 11
			buy.TextWrapped = true
			buy.ZIndex = 73
			buy.Parent = card
			corner(buy, 10)

			if equipped == hatName then
				buy.Text = "EQUIPPED"
				buy.BackgroundColor3 = Color3.fromRGB(103, 185, 114)
				buy.TextColor3 = Color3.fromRGB(18, 34, 20)
				buy.Active = false
			elseif inventory[hatName] then
				buy.Text = "EQUIP"
				buy.BackgroundColor3 = Color3.fromRGB(235, 235, 238)
				buy.TextColor3 = Color3.fromRGB(20, 20, 22)
				buy.Activated:Connect(function() action:FireServer("EquipHat", hatName) end)
			else
				buy.Text = `{hat.Cost} GOLD\nBUY`
				buy.BackgroundColor3 = gold >= hat.Cost and Color3.fromRGB(235, 235, 238) or Color3.fromRGB(79, 79, 85)
				buy.TextColor3 = gold >= hat.Cost and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(175, 175, 180)
				buy.Activated:Connect(function() action:FireServer("BuyHat", hatName) end)
			end
		end
	end
end

hatsButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then rebuild() end
end)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Profile) == "table" then
		currentProfile = payload.Profile
		if panel.Visible then rebuild() end
	end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then currentProfile = initial.Profile end
end)
