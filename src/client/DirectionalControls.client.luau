local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local directional = remotes:WaitForChild("DirectionalAction")
local secondaryFire = remotes:WaitForChild("SecondaryFire")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")

local selectedItem = "Axe"
local autoEnabled = false
local rotation = 0
local lastAuto = 0

local gui = Instance.new("ScreenGui")
gui.Name = "DirectionalControlsHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 42
gui.Parent = playerGui

local function style(button, radius)
	button.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = button
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(1, 1, 1)
	s.Transparency = 0.82
	s.Parent = button
end

local autoButton = Instance.new("TextButton")
autoButton.AnchorPoint = Vector2.new(1, 1)
autoButton.Position = UserInputService.TouchEnabled and UDim2.new(1, -18, 1, -280) or UDim2.new(1, -18, 1, -112)
autoButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(118, 48) or UDim2.fromOffset(118, 38)
autoButton.Text = "AUTO: OFF"
autoButton.Parent = gui
style(autoButton)

local actionButton = Instance.new("TextButton")
actionButton.AnchorPoint = Vector2.new(1, 1)
actionButton.Position = UDim2.new(1, -18, 1, -175)
actionButton.Size = UDim2.fromOffset(96, 72)
actionButton.Text = "ACTION"
actionButton.Visible = UserInputService.TouchEnabled
actionButton.Parent = gui
style(actionButton, 18)
actionButton.TextSize = 14

local rotateButton = Instance.new("TextButton")
rotateButton.AnchorPoint = Vector2.new(1, 1)
rotateButton.Position = UDim2.new(1, -122, 1, -175)
rotateButton.Size = UDim2.fromOffset(88, 52)
rotateButton.Text = "ROTATE"
rotateButton.Visible = UserInputService.TouchEnabled
rotateButton.Parent = gui
style(rotateButton, 14)

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(1, 1)
hint.Position = UserInputService.TouchEnabled and UDim2.new(1, -18, 1, -334) or UDim2.new(1, -18, 1, -154)
hint.Size = UDim2.fromOffset(220, 28)
hint.BackgroundTransparency = 1
hint.Text = "Swings hit everything in front of you"
hint.TextColor3 = Color3.fromRGB(205, 205, 212)
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = gui

local function hideLegacyControls()
	local legacy = playerGui:FindFirstChild("ActionAssistHUD")
	if not legacy then return end
	for _, name in { "AutoAction", "MobileAction", "MobileRotate" } do
		local object = legacy:FindFirstChild(name)
		if object and object:IsA("GuiObject") then object.Visible = false end
	end
end

task.spawn(function()
	for _ = 1, 80 do
		hideLegacyControls()
		task.wait(0.1)
	end
end)

local function itemData()
	return ItemData.Items[selectedItem]
end

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function aimForward(distance)
	local root = rootPart()
	if not root then return nil end
	return root.Position + root.CFrame.LookVector * distance
end

local function buildAhead()
	local root = rootPart()
	if not root then return end
	local position = root.Position + root.CFrame.LookVector * 8
	position = Vector3.new(math.floor(position.X + 0.5), 0, math.floor(position.Z + 0.5))
	action:FireServer("Build", { Type = selectedItem, Position = position, Rotation = rotation })
end

local function perform()
	local item = itemData()
	if not item then return end
	if item.Category == "Build" then
		buildAhead()
		return
	end
	if item.Category == "Consumable" then
		action:FireServer("Eat")
		return
	end
	if item.Kind == "Shield" or item.CanAttack == false then return end
	if item.Ranged then
		local position = aimForward(math.min(item.Range or 80, 120))
		if position then secondaryFire:FireServer(position) end
	else
		directional:FireServer()
	end
end

local function pointerOverButton()
	local mouse = player:GetMouse()
	for _, object in playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y) do
		if (object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("TextBox")) and object.Visible then
			return true
		end
	end
	return false
end

local function desktopDirectional(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if pointerOverButton() then return Enum.ContextActionResult.Pass end
	local item = itemData()
	if not item or item.Category == "Build" or item.Category == "Consumable" or item.Ranged or item.Kind == "Shield" then
		return Enum.ContextActionResult.Pass
	end
	directional:FireServer()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"WildforgeDirectionalSwing",
	desktopDirectional,
	false,
	4200,
	Enum.UserInputType.MouseButton1
)

autoButton.Activated:Connect(function()
	autoEnabled = not autoEnabled
	autoButton.Text = autoEnabled and "AUTO: ON" or "AUTO: OFF"
	autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(62, 121, 74) or Color3.fromRGB(31, 31, 35)
end)

actionButton.Activated:Connect(perform)
rotateButton.Activated:Connect(function()
	rotation = (rotation + 90) % 360
	rotateButton.Text = `ROTATE {rotation}°`
end)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
end)

task.spawn(function()
	local ok, state = pcall(function() return getState:InvokeServer() end)
	if ok and type(state) == "table" and type(state.SelectedItem) == "string" then selectedItem = state.SelectedItem end
end)

task.spawn(function()
	while true do
		task.wait(0.06)
		if autoEnabled then
			local item = itemData()
			if item and item.Category ~= "Build" then
				local interval = math.max(0.18, item.Cooldown or 0.35)
				local now = os.clock()
				if now - lastAuto >= interval then
					lastAuto = now
					perform()
				end
			end
		end
	end
end)

if UserInputService.TouchEnabled then
	RunService.Heartbeat:Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
	end)
end
