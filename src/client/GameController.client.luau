local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

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

local gui = Instance.new("ScreenGui")
gui.Name = "SurvivalHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local stats = Instance.new("TextLabel")
stats.Position = UDim2.fromOffset(16, 16)
stats.Size = UDim2.fromOffset(360, 70)
stats.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
stats.BackgroundTransparency = 0.12
stats.TextColor3 = Color3.fromRGB(245, 245, 245)
stats.Font = Enum.Font.GothamBold
stats.TextSize = 15
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextWrapped = true
stats.Parent = gui
Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 12)

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0, 18)
status.Size = UDim2.fromOffset(420, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.Parent = gui

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -20)
bar.Size = UDim2.fromOffset(610, 70)
bar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
bar.BackgroundTransparency = 0.08
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 14)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = bar

local function makeButton(text, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(105, 48)
	b.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
	b.TextColor3 = Color3.fromRGB(245, 245, 245)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.Activated:Connect(callback)
	return b
end

makeButton("1  WEAPON", function() mode = "Weapon" status.Text = "Weapon selected" end)
makeButton("2  FOOD", function() mode = "Food" status.Text = "Food selected" end)
makeButton("3  WALL", function() mode = "Wall" status.Text = "Wall selected" end)
makeButton("4  SPIKE", function() mode = "Spike" status.Text = "Spike selected" end)
makeButton("SHOP", function()
	local ok, catalog = pcall(function() return getShop:InvokeServer() end)
	if not ok or type(catalog) ~= "table" then return end
	local product = catalog.DeveloperProducts and catalog.DeveloperProducts.SmallResourceCrate
	if product and product.Id and product.Id > 0 then
		MarketplaceService:PromptProductPurchase(player, product.Id)
	else
		status.Text = "Shop IDs are not connected yet. Publish the game first."
	end
end)

local function refresh(profile)
	if type(profile) ~= "table" then return end
	stats.Text = string.format(
		"WOOD %d   STONE %d   FOOD %d   GOLD %d\nAGE %d   XP %d",
		profile.Wood or 0,
		profile.Stone or 0,
		profile.Food or 0,
		profile.Gold or 0,
		profile.Age or 1,
		profile.XP or 0
	)
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	refresh(payload.Profile)
	if payload.Message then status.Text = payload.Message end
end)

task.spawn(function()
	local ok, profile = pcall(function() return getState:InvokeServer() end)
	if ok then refresh(profile) end
end)

local function mouseGroundPosition()
	camera = workspace.CurrentCamera
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
	return result and result.Position or nil
end

local function clickAction()
	if mode == "Food" then
		action:FireServer("Eat")
		return
	end
	if mode == "Wall" or mode == "Spike" then
		local position = mouseGroundPosition()
		if position then
			action:FireServer("Build", { Type = mode, Position = position, Rotation = rotation })
		end
		return
	end

	local target = mouse.Target
	if not target then return end
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		action:FireServer("Attack", target)
	else
		action:FireServer("Gather", target)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.One then mode = "Weapon"
	elseif input.KeyCode == Enum.KeyCode.Two then mode = "Food"
	elseif input.KeyCode == Enum.KeyCode.Three then mode = "Wall"
	elseif input.KeyCode == Enum.KeyCode.Four then mode = "Spike"
	elseif input.KeyCode == Enum.KeyCode.Q then action:FireServer("Eat")
	elseif input.KeyCode == Enum.KeyCode.R then rotation = (rotation + 90) % 360
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then clickAction() end
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	humanoid.AutoRotate = false
	local ground = mouseGroundPosition()
	if ground then
		local look = Vector3.new(ground.X, root.Position.Y, ground.Z)
		if (look - root.Position).Magnitude > 0.1 then root.CFrame = CFrame.lookAt(root.Position, look) end
	end

	camera.CameraType = Enum.CameraType.Scriptable
	local offset = Vector3.new(0, 48, 38)
	camera.CFrame = CFrame.lookAt(root.Position + offset, root.Position)
end)
