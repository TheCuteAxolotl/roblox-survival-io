local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)
local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local directional = remotes:WaitForChild("DirectionalAction")
local secondaryFire = remotes:WaitForChild("SecondaryFire")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local survivalAction = remotes:WaitForChild("SurvivalAction")
local survivalState = remotes:WaitForChild("SurvivalState")

local selectedItem = "Axe"
local inventory = {}
local autoEnabled = false
local mobileRotation = 0
local lastAuto = 0

-- Disable the older nearest-target action helper. This controller replaces it
-- with facing-direction actions on desktop and mobile.
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:WaitForChild("ActionAssistHUD", 8)
	if old and old:IsA("ScreenGui") then old.Enabled = false end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DirectionalActionHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 42
gui.Parent = player:WaitForChild("PlayerGui")

local function style(button, radius)
	button.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = button
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(1,1,1)
	s.Transparency = 0.82
	s.Parent = button
end

local autoButton = Instance.new("TextButton")
autoButton.Name = "AutoDirectional"
autoButton.AnchorPoint = Vector2.new(1,1)
autoButton.Position = UserInputService.TouchEnabled and UDim2.new(1,-18,1,-280) or UDim2.new(1,-18,1,-112)
autoButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(126,48) or UDim2.fromOffset(126,38)
autoButton.Text = "AUTO: OFF"
autoButton.Parent = gui
style(autoButton)

local actionButton = Instance.new("TextButton")
actionButton.Name = "Action"
actionButton.AnchorPoint = Vector2.new(1,1)
actionButton.Position = UDim2.new(1,-18,1,-175)
actionButton.Size = UDim2.fromOffset(94,74)
actionButton.Text = "ACTION"
actionButton.Visible = UserInputService.TouchEnabled
actionButton.Parent = gui
style(actionButton, 18)
actionButton.TextSize = 14

local rotateButton = Instance.new("TextButton")
rotateButton.Name = "Rotate"
rotateButton.AnchorPoint = Vector2.new(1,1)
rotateButton.Position = UDim2.new(1,-120,1,-175)
rotateButton.Size = UDim2.fromOffset(86,52)
rotateButton.Text = "ROTATE"
rotateButton.Visible = UserInputService.TouchEnabled
rotateButton.Parent = gui
style(rotateButton,14)

local eatButton = Instance.new("TextButton")
eatButton.Name = "Eat"
eatButton.Position = UDim2.fromOffset(16,260)
eatButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(142,44) or UDim2.fromOffset(122,36)
eatButton.Text = "EAT FOOD"
eatButton.Parent = gui
style(eatButton)

local function root()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function item()
	return ItemData.Items[selectedItem]
end

local function pointerOverButton()
	if UserInputService.TouchEnabled then return false end
	local mouse = player:GetMouse()
	for _, object in GuiService:GetGuiObjectsAtPosition(mouse.X, mouse.Y) do
		if (object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("TextBox")) and object.Visible and object.Active then
			return true
		end
	end
	return false
end

local function buildAhead()
	local r = root()
	local data = item()
	if not r or not data or data.Category ~= "Build" then return end
	local forward = Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z)
	if forward.Magnitude < 0.1 then forward = Vector3.new(0,0,-1) end
	local p = r.Position + forward.Unit * 8
	p = Vector3.new(math.floor(p.X + 0.5),0,math.floor(p.Z + 0.5))
	action:FireServer("Build", { Type = selectedItem, Position = p, Rotation = mobileRotation })
end

local function perform(manual)
	local data = item()
	local r = root()
	if not data or not r then return end
	if data.Category == "Build" then
		if manual then buildAhead() end
		return
	end
	if data.Category == "Consumable" then
		if manual then action:FireServer("Eat") end
		return
	end
	if data.Kind == "Shield" or data.CanAttack == false then return end
	if data.Ranged then
		local range = math.min(data.Range or 80, 140)
		secondaryFire:FireServer(r.Position + r.CFrame.LookVector * range)
	else
		directional:FireServer()
	end
end

local foodPriority = { "CookedBeef", "TrailRation", "BoneBroth", "CookedMeat" }
local function bestFoodSlot()
	for _, wanted in foodPriority do
		for i = 1, 6 do
			local slot = inventory[i]
			if slot and slot.Item == wanted and slot.Amount > 0 then return i, wanted end
		end
	end
	for i = 1, 6 do
		local slot = inventory[i]
		local data = slot and SurvivalItemData.Items[slot.Item]
		if data and (data.Use == "Food" or data.Use == "Meal") then return i, slot.Item end
	end
end

local function updateEat()
	local _, name = bestFoodSlot()
	if name then
		local data = SurvivalItemData.Items[name]
		eatButton.Text = `EAT: {string.upper(data and data.Label or name)}`
		eatButton.BackgroundColor3 = Color3.fromRGB(63,108,67)
	else
		eatButton.Text = "EAT FOOD"
		eatButton.BackgroundColor3 = Color3.fromRGB(61,61,66)
	end
end

autoButton.Activated:Connect(function()
	autoEnabled = not autoEnabled
	autoButton.Text = autoEnabled and "AUTO: ON" or "AUTO: OFF"
	autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(67,123,76) or Color3.fromRGB(31,31,35)
end)

actionButton.Activated:Connect(function() perform(true) end)
rotateButton.Activated:Connect(function()
	mobileRotation = (mobileRotation + 90) % 360
	rotateButton.Text = `ROTATE {mobileRotation}°`
end)
eatButton.Activated:Connect(function()
	local slot = bestFoodSlot()
	if slot then survivalAction:FireServer("UseSlot", slot) end
end)

local function desktopAction(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if pointerOverButton() then return Enum.ContextActionResult.Pass end
	local data = item()
	if not data or data.Ranged or data.Category == "Build" or data.Category == "Consumable" or data.Kind == "Shield" then
		return Enum.ContextActionResult.Pass
	end
	perform(true)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"WildforgeDirectionalSwing",
	desktopAction,
	false,
	3400,
	Enum.UserInputType.MouseButton1
)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
end)
survivalState.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Inventory) == "table" then inventory = payload.Inventory updateEat() end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" and type(initial.SelectedItem) == "string" then selectedItem = initial.SelectedItem end
end)

task.spawn(function()
	while true do
		task.wait(0.08)
		if autoEnabled then
			local data = item()
			local interval = math.max(0.18, data and data.Cooldown or 0.35)
			local now = os.clock()
			if now - lastAuto >= interval then
				lastAuto = now
				perform(false)
			end
		end
	end
end)

if UserInputService.TouchEnabled then
	RunService.Heartbeat:Connect(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.AutoRotate = true end
	end)
end
