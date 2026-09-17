local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionChoiceHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shade.BackgroundTransparency = 0.28
shade.Visible = false
shade.ZIndex = 1
shade.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.86, 0, 0.76, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.ZIndex = 2
panel.Parent = shade
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 16)
title.Size = UDim2.new(1, -40, 0, 42)
title.BackgroundTransparency = 1
title.Text = "AGE UP — CHOOSE ONE"
title.TextColor3 = Color3.fromRGB(255, 226, 117)
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.ZIndex = 3
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(24, 58)
subtitle.Size = UDim2.new(1, -48, 0, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Your choice changes your loadout path. Some weapons are terminal while others unlock later upgrades."
subtitle.TextColor3 = Color3.fromRGB(188, 188, 198)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextWrapped = true
subtitle.ZIndex = 3
subtitle.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(18, 102)
list.Size = UDim2.new(1, -36, 1, -120)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 3
list.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(255, 190)
grid.CellPadding = UDim2.fromOffset(12, 12)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = list

local currentSignature = nil

local function statsText(item)
	if item.Category == "Weapon" then
		if item.Kind == "Shield" then
			return `Blocks {math.floor((item.BlockPercent or 0) * 100)}% melee • {math.floor((item.RangedBlockPercent or 0) * 100)}% ranged`
		elseif item.Ranged then
			if item.PercentHealthDamage then
				return `{math.floor(item.PercentHealthDamage * 100)}% max HP/hit • Range {item.Range} • {item.Cooldown}s reload`
			end
			return `Damage {item.Damage or 0} • Range {item.Range or 0} • {item.Cooldown or 0}s shot`
		else
			return `Damage {item.Damage or 0} • Reach {item.Range or 0} • {item.Cooldown or 0}s swing`
		end
	elseif item.Category == "Build" then
		local cost = item.Cost or {}
		return `HP {item.Health or 0} • Wood {cost.Wood or 0} • Stone {cost.Stone or 0}`
	end
	return ""
end

local function clearCards()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function buildCard(itemName, order)
	local item = ItemData.Items[itemName]
	if not item then return end
	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
	card.ZIndex = 4
	card.Parent = list
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(12, 10)
	name.Size = UDim2.new(1, -24, 0, 30)
	name.BackgroundTransparency = 1
	name.Text = string.upper(item.Label or itemName)
	name.TextColor3 = Color3.fromRGB(248, 248, 248)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 17
	name.ZIndex = 5
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Position = UDim2.fromOffset(12, 44)
	desc.Size = UDim2.new(1, -24, 0, 78)
	desc.BackgroundTransparency = 1
	desc.Text = item.Description or ""
	desc.TextColor3 = Color3.fromRGB(190, 190, 201)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextWrapped = true
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.ZIndex = 5
	desc.Parent = card

	local stats = Instance.new("TextLabel")
	stats.Position = UDim2.fromOffset(12, 122)
	stats.Size = UDim2.new(1, -24, 0, 24)
	stats.BackgroundTransparency = 1
	stats.Text = statsText(item)
	stats.TextColor3 = Color3.fromRGB(255, 219, 112)
	stats.Font = Enum.Font.GothamMedium
	stats.TextSize = 11
	stats.TextWrapped = true
	stats.ZIndex = 5
	stats.Parent = card

	local choose = Instance.new("TextButton")
	choose.AnchorPoint = Vector2.new(0.5, 1)
	choose.Position = UDim2.new(0.5, 0, 1, -10)
	choose.Size = UDim2.new(1, -24, 0, 34)
	choose.BackgroundColor3 = Color3.fromRGB(238, 238, 241)
	choose.TextColor3 = Color3.fromRGB(20, 20, 23)
	choose.Text = "CHOOSE"
	choose.Font = Enum.Font.GothamBold
	choose.TextSize = 12
	choose.ZIndex = 5
	choose.Parent = card
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 9)
	buttonCorner.Parent = choose
	choose.Activated:Connect(function()
		choose.Text = "UNLOCKING..."
		choose.Active = false
		action:FireServer("ChooseUpgrade", itemName)
	end)
end

local function render(profile)
	local pending = profile and profile.PendingChoice
	if type(pending) ~= "table" or type(pending.Age) ~= "number" or type(pending.Options) ~= "table" or #pending.Options == 0 then
		shade.Visible = false
		currentSignature = nil
		return
	end
	local signature = tostring(pending.Age) .. ":" .. table.concat(pending.Options, ",")
	shade.Visible = true
	if currentSignature == signature then return end
	currentSignature = signature
	title.Text = `AGE {pending.Age} — CHOOSE ONE`
	clearCards()
	for index, itemName in pending.Options do buildCard(itemName, index) end
end

-- Disable the original two-card age choice overlay created by GameController.
task.spawn(function()
	local survivalGui = player:WaitForChild("PlayerGui"):WaitForChild("SurvivalHUD", 10)
	if not survivalGui then return end
	for _ = 1, 100 do
		for _, descendant in survivalGui:GetDescendants() do
			if descendant:IsA("TextLabel") and string.find(descendant.Text, "AGE UP", 1, true) then
				local oldPanel = descendant.Parent
				local oldShade = oldPanel and oldPanel.Parent
				if oldShade and oldShade:IsA("GuiObject") then
					oldShade.Visible = false
					oldShade:GetPropertyChangedSignal("Visible"):Connect(function()
						if oldShade.Visible then task.defer(function() oldShade.Visible = false end) end
					end)
					return
				end
			end
		end
		task.wait(0.1)
	end
end)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Profile) == "table" then render(payload.Profile) end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then render(initial.Profile) end
end)
