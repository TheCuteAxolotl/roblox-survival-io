local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local getShop = remotes:WaitForChild("GetShop")

local mode = "Weapon"
local rotation = 0
local placementValid = false
local shopLoaded = false
local weaponParts = {}
local buttons = {}

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

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

local stats = Instance.new("TextLabel")
stats.Position = UDim2.fromOffset(16, 16)
stats.Size = UDim2.fromOffset(370, 82)
stats.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
stats.BackgroundTransparency = 0.08
stats.TextColor3 = Color3.fromRGB(245, 245, 245)
stats.Font = Enum.Font.GothamBold
stats.TextSize = 15
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextWrapped = true
stats.Parent = gui
corner(stats, 12)
stroke(stats, 0.82)

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0, 18)
status.Size = UDim2.fromOffset(500, 38)
status.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
status.BackgroundTransparency = 0.18
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.GothamBold
status.TextSize = 15
status.Text = "Gather resources, build a base, and survive."
status.Parent = gui
corner(status, 10)

local healthFrame = Instance.new("Frame")
healthFrame.Position = UDim2.fromOffset(16, 108)
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

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -20)
bar.Size = UDim2.fromOffset(650, 70)
bar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
bar.BackgroundTransparency = 0.06
bar.Parent = gui
corner(bar, 14)
stroke(bar, 0.82)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = bar

local function makeButton(key, text, callback)
	local b = Instance.new("TextButton")
	b.Name = key
	b.Size = UDim2.fromOffset(116, 48)
	b.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
	b.TextColor3 = Color3.fromRGB(245, 245, 245)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Parent = bar
	corner(b, 10)
	b.Activated:Connect(callback)
	buttons[key] = b
	return b
end

local shopPanel = Instance.new("Frame")
shopPanel.AnchorPoint = Vector2.new(1, 0.5)
shopPanel.Position = UDim2.new(1, -20, 0.5, 0)
shopPanel.Size = UDim2.fromOffset(390, 470)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
shopPanel.Visible = false
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
closeShop.Parent = shopPanel
corner(closeShop, 9)
closeShop.Activated:Connect(function() shopPanel.Visible = false end)

local shopNote = Instance.new("TextLabel")
shopNote.Position = UDim2.fromOffset(18, 52)
shopNote.Size = UDim2.new(1, -36, 0, 46)
shopNote.BackgroundTransparency = 1
shopNote.Text = "Optional purchases. Gameplay resources remain obtainable by playing."
shopNote.TextColor3 = Color3.fromRGB(178, 178, 186)
shopNote.TextWrapped = true
shopNote.TextSize = 12
shopNote.Font = Enum.Font.Gotham
shopNote.TextXAlignment = Enum.TextXAlignment.Left
shopNote.Parent = shopPanel

local shopList = Instance.new("ScrollingFrame")
shopList.Position = UDim2.fromOffset(14, 104)
shopList.Size = UDim2.new(1, -28, 1, -118)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 5
shopList.CanvasSize = UDim2.new()
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

local function addShopCard(titleText, detailText, robux, id, isPass)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -6, 0, 92)
	card.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
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
			local description = string.format("Wood %d  •  Stone %d  •  Food %d  •  Gold %d", grant.Wood or 0, grant.Stone or 0, grant.Food or 0, grant.Gold or 0)
			addShopCard(name:gsub("(%l)(%u)", "%1 %2"), description, data.RobuxLabel or 0, data.Id or 0, false)
		end
	end

	local passes = catalog.GamePasses or {}
	for _, name in { "VIP", "Builder" } do
		local data = passes[name]
		if data then
			local description = name == "VIP" and "Permanent cosmetic VIP badge and future VIP cosmetics." or "Permanent builder convenience perks; no exclusive combat power."
			addShopCard(`${name} Pass`, description, data.RobuxLabel or 0, data.Id or 0, true)
		end
	end
	shopLoaded = true
end

local function updateButtonSelection()
	for key, button in buttons do
		local active = key == mode
		button.BackgroundColor3 = active and Color3.fromRGB(238, 238, 241) or Color3.fromRGB(42, 42, 46)
		button.TextColor3 = active and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(245, 245, 245)
	end
	for _, p in weaponParts do
		if p and p.Parent then p.Transparency = mode == "Weapon" and 0 or 1 end
	end
end

local function selectMode(newMode)
	mode = newMode
	updateButtonSelection()
	if newMode == "Wall" then status.Text = "Wall: 20 wood • R rotates"
	elseif newMode == "Spike" then status.Text = "Spikes: 15 wood + 5 stone"
	elseif newMode == "Food" then status.Text = "Click or press Q to eat 1 food."
	else status.Text = "Weapon selected — attack players or gather resources." end
end

makeButton("Weapon", "1  AXE", function() selectMode("Weapon") end)
makeButton("Food", "2  FOOD", function() selectMode("Food") end)
makeButton("Wall", "3  WALL", function() selectMode("Wall") end)
makeButton("Spike", "4  SPIKES", function() selectMode("Spike") end)
makeButton("Shop", "SHOP", function()
	populateShop()
	shopPanel.Visible = not shopPanel.Visible
end)

local preview = Instance.new("Part")
preview.Name = "LocalBuildPreview"
preview.Anchored = true
preview.CanCollide = false
preview.CanQuery = false
preview.CanTouch = false
preview.Material = Enum.Material.ForceField
preview.Transparency = 1
preview.Parent = workspace

local function refresh(profile)
	if type(profile) ~= "table" then return end
	stats.Text = string.format(
		"  WOOD %d     STONE %d     FOOD %d     GOLD %d\n  AGE %d     XP %d",
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Food or 0,
		profile.Gold or 0,
		profile.Age or 1,
		profile.XP or 0
	)
end

local function flashMessage(text, kind)
	if type(text) ~= "string" or text == "" then return end
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.42, 0)
	label.Size = UDim2.fromOffset(300, 46)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = kind == "KO" and 27 or 20
	label.TextColor3 = kind == "Heal" and Color3.fromRGB(128, 245, 144) or (kind == "KO" and Color3.fromRGB(255, 218, 92) or Color3.fromRGB(255, 255, 255))
	label.TextStrokeTransparency = 0.45
	label.Parent = gui
	TweenService:Create(label, TweenInfo.new(0.55), {
		Position = UDim2.new(0.5, 0, 0.37, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.6)
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	refresh(payload.Profile)
	if payload.Message then status.Text = payload.Message end
	if payload.FX and payload.Message then
		flashMessage(payload.Message, payload.FX.Kind)
	end
end)

task.spawn(function()
	local ok, profile = pcall(function() return getState:InvokeServer() end)
	if ok then refresh(profile) end
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
	if mode ~= "Wall" and mode ~= "Spike" then
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
	if mode == "Wall" then
		preview.Size = Vector3.new(10, 6, 1.2)
		preview.CFrame = CFrame.new(ground.X, 3, ground.Z) * CFrame.Angles(0, math.rad(rotation), 0)
	else
		preview.Size = Vector3.new(5.5, 2.2, 5.5)
		preview.CFrame = CFrame.new(ground.X, 1.1, ground.Z)
	end
end

local function showSwing()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local slash = Instance.new("Part")
	slash.Name = "LocalSwing"
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(238, 238, 238)
	slash.Size = Vector3.new(0.18, 0.18, 7)
	slash.Transparency = 0.15
	slash.CFrame = root.CFrame * CFrame.new(0, 1, -4) * CFrame.Angles(0, 0, math.rad(28))
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.16), {
		Transparency = 1,
		CFrame = slash.CFrame * CFrame.Angles(0, math.rad(34), 0),
	}):Play()
	Debris:AddItem(slash, 0.2)
end

local function clickAction()
	if mode == "Food" then
		action:FireServer("Eat")
		return
	end

	if mode == "Wall" or mode == "Spike" then
		if not placementValid then
			status.Text = "Move the preview closer to your character."
			return
		end
		local position = mousePlanePosition(0)
		if position then
			action:FireServer("Build", { Type = mode, Position = snapped(position), Rotation = rotation })
		end
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

local function clearWeaponVisual()
	for _, p in weaponParts do
		if p and p.Parent then p:Destroy() end
	end
	weaponParts = {}
end

local function attachAxe(character)
	clearWeaponVisual()
	local hand = character:WaitForChild("RightHand", 3) or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local handle = Instance.new("Part")
	handle.Name = "LocalAxeHandle"
	handle.Size = Vector3.new(0.28, 2.4, 0.28)
	handle.Color = Color3.fromRGB(112, 78, 48)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = hand.CFrame * CFrame.new(0, -1.1, -0.35) * CFrame.Angles(math.rad(20), 0, math.rad(-15))
	handle.Parent = character

	local head = Instance.new("Part")
	head.Name = "LocalAxeHead"
	head.Size = Vector3.new(1.35, 0.75, 0.38)
	head.Color = Color3.fromRGB(105, 109, 116)
	head.Material = Enum.Material.Metal
	head.CanCollide = false
	head.CanQuery = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 1.05, 0)
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
	updateButtonSelection()
end

player.CharacterAdded:Connect(function(character)
	task.spawn(attachAxe, character)
end)
if player.Character then task.spawn(attachAxe, player.Character) end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.One then selectMode("Weapon")
	elseif input.KeyCode == Enum.KeyCode.Two then selectMode("Food")
	elseif input.KeyCode == Enum.KeyCode.Three then selectMode("Wall")
	elseif input.KeyCode == Enum.KeyCode.Four then selectMode("Spike")
	elseif input.KeyCode == Enum.KeyCode.Q then action:FireServer("Eat")
	elseif input.KeyCode == Enum.KeyCode.R then
		rotation = (rotation + 90) % 360
		status.Text = `Build rotation: {rotation}°`
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then clickAction() end
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
	if ground then
		local look = Vector3.new(ground.X, root.Position.Y, ground.Z)
		if (look - root.Position).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
	end

	local healthRatio = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 0
	healthFill.Size = UDim2.fromScale(math.clamp(healthRatio, 0, 1), 1)
	healthText.Text = `{math.ceil(humanoid.Health)} HP`

	camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		local offset = Vector3.new(0, 50, 40)
		camera.CFrame = CFrame.lookAt(root.Position + offset, root.Position)
	end

	updatePlacementPreview()
end)

selectMode("Weapon")
