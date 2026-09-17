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
tooltip.Size = UDim2.fromOffset(330, 188)
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

local function effectText(item)
	local effects = {}
	if item.GoldPerTick then
		table.insert(effects, `Gold: +{item.GoldPerTick} every {item.TickSeconds or 8}s`)
		if item.UpgradeGroup == "Mill" then
			local xp = item.XPPerTick or item.GoldPerTick
			table.insert(effects, `XP: +{xp} every {item.TickSeconds or 8}s`)
		end
	end
	if item.WoodPerTick then table.insert(effects, `Wood: +{item.WoodPerTick} every {item.TickSeconds or 8}s`) end
	if item.HealPerSecond then table.insert(effects, `Healing: +{item.HealPerSecond} HP/s within {item.EffectRange or 16} studs`) end
	if item.TurretDamage then table.insert(effects, `Turret: {item.TurretDamage} damage • {item.TurretRange or 0} stud range`) end
	if item.MineDamage then table.insert(effects, `Mine hit: {item.MineDamage} damage`) end
	if item.TouchDamage then table.insert(effects, `Contact: {item.TouchDamage} damage`) end
	return table.concat(effects, "\n")
end

local function weaponText(item)
	local lines = {}
	local slot = item.WeaponSlot == "Secondary" and "SECONDARY" or "PRIMARY"
	table.insert(lines, slot)
	if item.Kind == "Shield" then
		table.insert(lines, `Blocks {math.floor((item.BlockPercent or 0) * 100)}% melee • {math.floor((item.RangedBlockPercent or 0) * 100)}% ranged`)
	elseif item.PercentHealthDamage then
		table.insert(lines, `{math.floor(item.PercentHealthDamage * 100)}% MAX HP per hit • Range {item.Range or 0} • Reload {item.Cooldown or 0}s`)
	elseif item.Ranged then
		local projectile = item.ProjectileCount and item.ProjectileCount > 1 and ` • {item.ProjectileCount} shots` or ""
		table.insert(lines, `Damage {item.Damage or 0} • Range {item.Range or 0} • Fire {item.Cooldown or 0}s{projectile}`)
	else
		table.insert(lines, `Damage {item.Damage or 0} • Reach {item.Range or 0} • Swing {item.Cooldown or 0}s`)
	end
	if item.Knockback then table.insert(lines, `Knockback: {item.Knockback}`) end
	if item.GoldStealPercent then table.insert(lines, `Steals {math.floor(item.GoldStealPercent * 100)}% carried gold on hit`) end
	if item.ResourceBonus then table.insert(lines, `Gather bonus: +{item.ResourceBonus} resources`) end
	if item.StoneBonus then table.insert(lines, `Stone bonus: +{item.StoneBonus}`) end
	if item.Terminal then table.insert(lines, "Terminal weapon — no later upgrade")
	elseif item.RequiresUnlock then table.insert(lines, `Upgrade from {ItemData.Items[item.RequiresUnlock] and ItemData.Items[item.RequiresUnlock].Label or item.RequiresUnlock}`) end
	return table.concat(lines, "\n")
end

local function refreshTooltip()
	if not hoveredItem then return end
	local item = ItemData.Items[hoveredItem]
	if not item then tooltip.Visible = false return end
	title.Text = string.upper(item.Label or hoveredItem)
	if item.Category == "Build" then
		local placed = buildCounts[hoveredItem] or 0
		local limit = item.BuildLimit or 0
		local effect = effectText(item)
		body.Text = string.format(
			"%s\nCost: %s\nPlaced: %d / %s   •   Can afford: %d%s",
			item.Description or "",
			formatCost(item.Cost),
			placed,
			limit > 0 and tostring(limit) or "∞",
			affordableCount(item.Cost),
			effect ~= "" and `\n{effect}` or ""
		)
	elseif item.Category == "Weapon" then
		body.Text = `{item.Description or ""}\n\n{weaponText(item)}`
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
	local mousePos = UserInputService:GetMouseLocation()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local x = math.min(mousePos.X + 18, viewport.X - tooltip.AbsoluteSize.X - 12)
	local y = math.max(12, mousePos.Y - tooltip.AbsoluteSize.Y - 12)
	tooltip.Position = UDim2.fromOffset(x, y)
end)
