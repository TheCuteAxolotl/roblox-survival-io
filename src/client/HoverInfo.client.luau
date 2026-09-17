local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SurvivalHUD")
local hotbar = gui:WaitForChild("Hotbar")

local currentProfile = nil
local buildCounts = {}
local hoveredItem = nil

local tooltip = Instance.new("Frame")
tooltip.Name = "ItemHoverTooltip"
tooltip.Size = UDim2.fromOffset(290, 128)
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
tooltip.BackgroundTransparency = 0.04
tooltip.Visible = false
tooltip.ZIndex = 90
tooltip.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = tooltip
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.8
stroke.Parent = tooltip

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 24)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(250, 250, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 91
title.Parent = tooltip

local body = Instance.new("TextLabel")
body.Position = UDim2.fromOffset(12, 36)
body.Size = UDim2.new(1, -24, 1, -44)
body.BackgroundTransparency = 1
body.TextColor3 = Color3.fromRGB(195, 195, 204)
body.Font = Enum.Font.Gotham
body.TextSize = 12
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.ZIndex = 91
body.Parent = tooltip

local function formatCost(cost)
	local parts = {}
	for _, resource in { "Wood", "Stone", "Food", "Gold" } do
		local amount = cost and cost[resource]
		if amount and amount > 0 then table.insert(parts, `{amount} {resource:lower()}`) end
	end
	return #parts > 0 and table.concat(parts, " + ") or "Free"
end

local function affordableCount(cost)
	if not currentProfile or type(cost) ~= "table" then return 0 end
	local result = math.huge
	local hasCost = false
	for resource, amount in cost do
		if amount > 0 then
			hasCost = true
			result = math.min(result, math.floor((currentProfile[resource] or 0) / amount))
		end
	end
	if not hasCost then return 0 end
	return result == math.huge and 0 or result
end

local function refreshTooltip()
	if not hoveredItem then return end
	local item = ItemData.Items[hoveredItem]
	if not item then tooltip.Visible = false return end
	title.Text = string.upper(item.Label or hoveredItem)
	if item.Category == "Build" then
		local placed = buildCounts[hoveredItem] or 0
		local limit = item.BuildLimit or 0
		body.Text = string.format(
			"%s\n\nCost: %s\nPlaced: %d / %s   •   Can afford now: %d",
			item.Description or "",
			formatCost(item.Cost),
			placed,
			limit > 0 and tostring(limit) or "∞",
			affordableCount(item.Cost)
		)
	elseif item.Category == "Weapon" then
		body.Text = string.format(
			"%s\n\nDamage: %d   •   Range: %d   •   Swing: %.2fs",
			item.Description or "",
			item.Damage or 0,
			item.Range or 0,
			item.Cooldown or 0
		)
	else
		body.Text = item.Description or ""
	end
end

local function wireButton(button)
	if not button:IsA("TextButton") or button:GetAttribute("HoverInfoWired") then return end
	button:SetAttribute("HoverInfoWired", true)
	button.MouseEnter:Connect(function()
		if not ItemData.Items[button.Name] then return end
		hoveredItem = button.Name
		refreshTooltip()
		tooltip.Visible = true
	end)
	button.MouseLeave:Connect(function()
		if hoveredItem == button.Name then
			hoveredItem = nil
			tooltip.Visible = false
		end
	end)
end

for _, child in hotbar:GetChildren() do wireButton(child) end
hotbar.ChildAdded:Connect(function(child)
	task.defer(wireButton, child)
end)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Profile) == "table" then currentProfile = payload.Profile end
	if type(payload.BuildCounts) == "table" then buildCounts = payload.BuildCounts end
	refreshTooltip()
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		currentProfile = initial.Profile
		buildCounts = initial.BuildCounts or {}
	end
end)

RunService.RenderStepped:Connect(function()
	if not tooltip.Visible then return end
	local mouse = UserInputService:GetMouseLocation()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local x = math.min(mouse.X + 18, viewport.X - tooltip.AbsoluteSize.X - 12)
	local y = math.max(12, mouse.Y - tooltip.AbsoluteSize.Y - 12)
	tooltip.Position = UDim2.fromOffset(x, y)
end)
