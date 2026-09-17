local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "MinimalMapHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local map = Instance.new("Frame")
map.Name = "Map"
map.AnchorPoint = Vector2.new(1, 0)
map.Position = UDim2.new(1, -18, 0, 218)
map.Size = UserInputService.TouchEnabled and UDim2.fromOffset(118, 118) or UDim2.fromOffset(154, 154)
map.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
map.BackgroundTransparency = 0.02
map.BorderSizePixel = 0
map.ClipsDescendants = true
map.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = map
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.78
stroke.Parent = map

local half = Config.WorldSize / 2
local snowEnd = (-Config.BiomeSplit + half) / Config.WorldSize
local grassEnd = (Config.BiomeSplit + half) / Config.WorldSize

local function band(name, x0, x1, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = UDim2.fromScale(x0, 0)
	frame.Size = UDim2.fromScale(x1 - x0, 1)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.22
	frame.BorderSizePixel = 0
	frame.ZIndex = 1
	frame.Parent = map
	return frame
end

band("SnowBiome", 0, snowEnd, Color3.fromRGB(172, 192, 202))
band("GrassBiome", snowEnd, grassEnd, Color3.fromRGB(80, 131, 79))
band("DesertBiome", grassEnd, 1, Color3.fromRGB(178, 143, 82))

local river = Instance.new("Frame")
river.Name = "River"
river.Position = UDim2.fromScale(0, 0.5 - Config.RiverHalfWidth / Config.WorldSize)
river.Size = UDim2.fromScale(1, Config.RiverHalfWidth * 2 / Config.WorldSize)
river.BackgroundColor3 = Color3.fromRGB(65, 135, 190)
river.BackgroundTransparency = 0.05
river.BorderSizePixel = 0
river.ZIndex = 2
river.Parent = map

for _, bridgeX in Config.BridgeXPositions do
	local x = (bridgeX + half) / Config.WorldSize
	local bridge = Instance.new("Frame")
	bridge.AnchorPoint = Vector2.new(0.5, 0.5)
	bridge.Position = UDim2.fromScale(x, 0.5)
	bridge.Size = UDim2.fromOffset(5, 12)
	bridge.BackgroundColor3 = Color3.fromRGB(119, 84, 53)
	bridge.BorderSizePixel = 0
	bridge.ZIndex = 3
	bridge.Parent = map
end

local dot = Instance.new("Frame")
dot.Name = "PlayerDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 10 or 9, UserInputService.TouchEnabled and 10 or 9)
dot.BackgroundColor3 = Color3.fromRGB(255, 225, 92)
dot.BorderSizePixel = 0
dot.ZIndex = 7
dot.Parent = map
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(5, 4)
title.Size = UDim2.new(1, -10, 0, 14)
title.BackgroundTransparency = 1
title.Text = "DISCOVERY MAP"
title.TextColor3 = Color3.fromRGB(243, 243, 245)
title.TextStrokeTransparency = 0.55
title.Font = Enum.Font.GothamBold
title.TextSize = UserInputService.TouchEnabled and 7 or 8
title.ZIndex = 8
title.Parent = map

local discovered = {}
local markerInfo = {}

local function worldToMap(position)
	return math.clamp((position.X + half) / Config.WorldSize, 0.025, 0.975),
		math.clamp((position.Z + half) / Config.WorldSize, 0.025, 0.975)
end

local function landmarkType(model)
	if model:GetAttribute("TownHall") == true then return "H", Color3.fromRGB(214, 168, 255), math.huge end
	if model:GetAttribute("Castle") == true then return "K", Color3.fromRGB(214, 198, 165), 120 end
	if model:GetAttribute("Dungeon") == true then return "D", Color3.fromRGB(205, 92, 112), 100 end
	if model:GetAttribute("Cave") == true then return "C", Color3.fromRGB(126, 126, 136), 90 end
	if model:GetAttribute("DangerZone") == true then return "F", Color3.fromRGB(74, 112, 79), 155 end
	if model:GetAttribute("VillageBiome") then return "V", Color3.fromRGB(246, 209, 107), 78 end
	if model.Name == "BossArena" then return "!", Color3.fromRGB(232, 100, 80), 110 end
	return nil
end

local function pivotPosition(model)
	local ok, cf = pcall(function() return model:GetPivot() end)
	return ok and cf.Position or nil
end

local function reveal(model, symbol, color)
	if discovered[model] then return end
	discovered[model] = true
	local marker = Instance.new("TextLabel")
	marker.Name = "DiscoveredLandmark"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 12 or 13, UserInputService.TouchEnabled and 12 or 13)
	marker.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	marker.BackgroundTransparency = 0.12
	marker.Text = symbol
	marker.TextColor3 = color
	marker.Font = Enum.Font.GothamBlack
	marker.TextSize = UserInputService.TouchEnabled and 7 or 8
	marker.BorderSizePixel = 0
	marker.ZIndex = 6
	marker.Parent = map
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = marker
	markerInfo[model] = marker
end

local discoveryTimer = 0
RunService.RenderStepped:Connect(function(dt)
	if player:GetAttribute("InRiftExpedition") == true then
		map.Visible = false
		return
	end
	map.Visible = true
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local x, y = worldToMap(root.Position)
	dot.Position = UDim2.fromScale(x, y)

	discoveryTimer += dt
	if discoveryTimer < 0.5 then return end
	discoveryTimer = 0

	local world = workspace:FindFirstChild("SurvivalArena")
	if not world then return end
	for _, model in world:GetChildren() do
		if model:IsA("Model") then
			local symbol, color, distance = landmarkType(model)
			if symbol then
				local position = pivotPosition(model)
				if position and not discovered[model] and (root.Position - position).Magnitude <= distance then
					reveal(model, symbol, color)
				end
				local marker = markerInfo[model]
				if marker and marker.Parent and position then
					local mx, my = worldToMap(position)
					marker.Position = UDim2.fromScale(mx, my)
				end
			end
		end
	end
end)
