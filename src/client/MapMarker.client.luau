local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mapGui = playerGui:WaitForChild("MinimalMapHUD")
local map = mapGui:WaitForChild("Map")
map.Active = true

local overlay = Instance.new("TextButton")
overlay.Name = "MarkerInput"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundTransparency = 1
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.ZIndex = 3
overlay.Parent = map

local marker = Instance.new("Frame")
marker.Name = "WaypointMarker"
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.Size = UDim2.fromOffset(10, 10)
marker.BackgroundColor3 = Color3.fromRGB(255, 92, 92)
marker.BorderSizePixel = 0
marker.Visible = false
marker.ZIndex = 5
marker.Parent = map
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(1, 0)
mc.Parent = marker

local distanceLabel = Instance.new("TextLabel")
distanceLabel.AnchorPoint = Vector2.new(1, 0)
distanceLabel.Position = UDim2.new(1, -18, 0, 372)
distanceLabel.Size = UDim2.fromOffset(148, 24)
distanceLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
distanceLabel.BackgroundTransparency = 0.12
distanceLabel.TextColor3 = Color3.fromRGB(236, 236, 240)
distanceLabel.Font = Enum.Font.GothamBold
distanceLabel.TextSize = 10
distanceLabel.Text = "Tap map to mark a spot"
distanceLabel.Parent = mapGui
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(0, 8)
dc.Parent = distanceLabel

local clear = Instance.new("TextButton")
clear.AnchorPoint = Vector2.new(1, 0)
clear.Position = UDim2.new(1, -18, 0, 400)
clear.Size = UDim2.fromOffset(72, 24)
clear.BackgroundColor3 = Color3.fromRGB(52, 52, 57)
clear.TextColor3 = Color3.fromRGB(240, 240, 244)
clear.Font = Enum.Font.GothamBold
clear.TextSize = 10
clear.Text = "CLEAR"
clear.Visible = false
clear.Parent = mapGui
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = clear

local waypoint = nil

local function setMarkerFromScreen(screenPosition)
	local pos = map.AbsolutePosition
	local size = map.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	local x = math.clamp((screenPosition.X - pos.X) / size.X, 0, 1)
	local y = math.clamp((screenPosition.Y - pos.Y) / size.Y, 0, 1)
	local half = Config.WorldSize / 2
	local worldX = x * Config.WorldSize - half
	-- Same vertical convention as MinimalMap: screen-down corresponds to +Z.
	local worldZ = y * Config.WorldSize - half
	waypoint = Vector3.new(worldX, 0, worldZ)
	marker.Position = UDim2.fromScale(x, y)
	marker.Visible = true
	clear.Visible = true
end

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setMarkerFromScreen(input.Position)
	end
end)

clear.Activated:Connect(function()
	waypoint = nil
	marker.Visible = false
	clear.Visible = false
	distanceLabel.Text = "Tap map to mark a spot"
end)

local accum = 0
RunService.RenderStepped:Connect(function(dt)
	if not waypoint then return end
	accum += dt
	if accum < 0.15 then return end
	accum = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
	local studs = math.floor((flatRoot - waypoint).Magnitude + 0.5)
	distanceLabel.Text = `MARKER  •  {studs} studs`
end)
