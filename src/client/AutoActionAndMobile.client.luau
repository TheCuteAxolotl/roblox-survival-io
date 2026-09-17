local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local secondaryFire = remotes:WaitForChild("SecondaryFire")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local survivalAction = remotes:WaitForChild("SurvivalAction")
local survivalState = remotes:WaitForChild("SurvivalState")

local selectedItem = "Axe"
local survivalInventory = {}
local autoEnabled = false
local mobileRotation = 0
local lastAuto = 0

local gui = Instance.new("ScreenGui")
gui.Name = "ActionAssistHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 38
gui.Parent = player:WaitForChild("PlayerGui")

local function styleButton(button, radius)
	button.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Parent = button
end

local autoButton = Instance.new("TextButton")
autoButton.Name = "AutoAction"
autoButton.AnchorPoint = Vector2.new(1, 1)
autoButton.Position = UserInputService.TouchEnabled and UDim2.new(1, -18, 1, -280) or UDim2.new(1, -18, 1, -112)
autoButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(118, 48) or UDim2.fromOffset(118, 38)
autoButton.Text = "AUTO: OFF"
autoButton.Parent = gui
styleButton(autoButton)

local eatButton = Instance.new("TextButton")
eatButton.Name = "QuickEat"
eatButton.Position = UDim2.fromOffset(16, 260)
eatButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(138, 44) or UDim2.fromOffset(118, 36)
eatButton.Text = "EAT FOOD"
eatButton.Parent = gui
styleButton(eatButton)

local eatHint = Instance.new("TextLabel")
eatHint.Position = UDim2.fromOffset(16, UserInputService.TouchEnabled and 307 or 299)
eatHint.Size = UDim2.fromOffset(220, 30)
eatHint.BackgroundTransparency = 1
eatHint.Text = "Berries feed you automatically"
eatHint.TextColor3 = Color3.fromRGB(205, 205, 210)
eatHint.Font = Enum.Font.Gotham
eatHint.TextSize = 10
eatHint.TextXAlignment = Enum.TextXAlignment.Left
eatHint.Parent = gui

local actionButton = Instance.new("TextButton")
actionButton.Name = "MobileAction"
actionButton.AnchorPoint = Vector2.new(1, 1)
actionButton.Position = UDim2.new(1, -18, 1, -175)
actionButton.Size = UDim2.fromOffset(92, 72)
actionButton.Text = "ACTION"
actionButton.Visible = UserInputService.TouchEnabled
actionButton.Parent = gui
styleButton(actionButton, 18)
actionButton.TextSize = 14

local rotateButton = Instance.new("TextButton")
rotateButton.Name = "MobileRotate"
rotateButton.AnchorPoint = Vector2.new(1, 1)
rotateButton.Position = UDim2.new(1, -118, 1, -175)
rotateButton.Size = UDim2.fromOffset(84, 52)
rotateButton.Text = "ROTATE"
rotateButton.Visible = UserInputService.TouchEnabled
rotateButton.Parent = gui
styleButton(rotateButton, 14)

local function currentItem()
	return ItemData.Items[selectedItem]
end

local function playerRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isOtherHumanoid(part)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return false end
	if player.Character and model == player.Character then return false end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function targetKind(part, item)
	if isOtherHumanoid(part) and item.CanAttack ~= false and item.Kind ~= "Shield" then return "Attack" end
	if CollectionService:HasTag(part, "PlayerBuild") and item.CanAttack ~= false and item.Kind ~= "Shield" then return "AttackBuild" end
	if CollectionService:HasTag(part, "SurvivalResource") and item.CanGather ~= false and not item.Ranged and item.Kind ~= "Shield" then return "Gather" end
	return nil
end

local function findTarget(item)
	local root = playerRoot()
	if not root or not item then return nil, nil end
	local range = item.Ranged and math.min(item.Range or 70, 90) or math.max(item.Range or 14, 18)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local parts = workspace:GetPartBoundsInRadius(root.Position, range, params)
	local bestPart, bestKind, bestDistance
	local seenModels = {}
	for _, part in parts do
		if part:IsA("BasePart") then
			local model = part:FindFirstAncestorOfClass("Model")
			local key = model or part
			if not seenModels[key] then
				seenModels[key] = true
				local kind = targetKind(part, item)
				if kind then
					local targetPart = model and model.PrimaryPart or part
					if not targetPart or not targetPart:IsA("BasePart") then targetPart = part end
					local distance = (targetPart.Position - root.Position).Magnitude
					if not bestDistance or distance < bestDistance then
						bestPart, bestKind, bestDistance = part, kind, distance
					end
				end
			end
		end
	end
	return bestPart, bestKind
end

local function buildAhead()
	local root = playerRoot()
	local item = currentItem()
	if not root or not item or item.Category ~= "Build" then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local direction = humanoid and humanoid.MoveDirection or Vector3.zero
	if direction.Magnitude < 0.1 then direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) end
	if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, -1) end
	direction = direction.Unit
	local position = root.Position + direction * 8
	position = Vector3.new(math.floor(position.X + 0.5), 0, math.floor(position.Z + 0.5))
	action:FireServer("Build", { Type = selectedItem, Position = position, Rotation = mobileRotation })
end

local function performAction(manual)
	local item = currentItem()
	if not item then return end
	if item.Category == "Build" then
		if manual then buildAhead() end
		return
	end
	if item.Category == "Consumable" then
		if manual then action:FireServer("Eat") end
		return
	end
	if item.Kind == "Shield" or item.CanAttack == false then return end

	local target, kind = findTarget(item)
	if item.Ranged then
		if target then
			secondaryFire:FireServer(target.Position)
		elseif manual then
			local root = playerRoot()
			if root then secondaryFire:FireServer(root.Position + root.CFrame.LookVector * math.min(item.Range or 70, 70)) end
		end
		return
	end
	if target and kind then action:FireServer(kind, target) end
end

local foodPriority = { "CookedBeef", "TrailRation", "BoneBroth", "CookedMeat" }

local function bestFoodSlot()
	for _, wanted in foodPriority do
		for index = 1, 6 do
			local slot = survivalInventory[index]
			if slot and slot.Item == wanted and slot.Amount > 0 then return index, wanted end
		end
	end
	for index = 1, 6 do
		local slot = survivalInventory[index]
		local data = slot and SurvivalItemData.Items[slot.Item]
		if data and (data.Use == "Food" or data.Use == "Meal") then return index, slot.Item end
	end
	return nil, nil
end

local function refreshEatButton()
	local _, itemName = bestFoodSlot()
	if itemName then
		local data = SurvivalItemData.Items[itemName]
		eatButton.Text = `EAT: {string.upper(data and data.Label or itemName)}`
		eatButton.BackgroundColor3 = Color3.fromRGB(65, 104, 67)
	else
		eatButton.Text = "EAT FOOD"
		eatButton.BackgroundColor3 = Color3.fromRGB(61, 61, 66)
	end
end

autoButton.Activated:Connect(function()
	autoEnabled = not autoEnabled
	autoButton.Text = autoEnabled and "AUTO: ON" or "AUTO: OFF"
	autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(67, 123, 76) or Color3.fromRGB(31, 31, 35)
end)

actionButton.Activated:Connect(function() performAction(true) end)

rotateButton.Activated:Connect(function()
	mobileRotation = (mobileRotation + 90) % 360
	rotateButton.Text = `ROTATE {mobileRotation}°`
end)

eatButton.Activated:Connect(function()
	local slot = bestFoodSlot()
	if slot then
		survivalAction:FireServer("UseSlot", slot)
	else
		eatHint.Text = "No cooked food in your 6-slot bag"
		task.delay(2, function() if eatHint.Parent then eatHint.Text = "Berries feed you automatically" end end)
	end
end)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
end)

survivalState.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Inventory) == "table" then
		survivalInventory = payload.Inventory
		refreshEatButton()
	end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" and type(initial.SelectedItem) == "string" then selectedItem = initial.SelectedItem end
end)

task.spawn(function()
	while true do
		task.wait(0.08)
		if autoEnabled then
			local item = currentItem()
			local interval = math.max(0.18, item and item.Cooldown or 0.35)
			local now = os.clock()
			if now - lastAuto >= interval then
				lastAuto = now
				performAction(false)
			end
		end
	end
end)

-- Roblox's default thumbstick handles movement. Keep humanoid autorotation enabled
-- on touch devices so mobile players are not forced to aim with a mouse cursor.
if UserInputService.TouchEnabled then
	RunService.Heartbeat:Connect(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.AutoRotate = true end
	end)
end
