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
map.Size = UserInputService.TouchEnabled and UDim2.fromOffset(112, 112) or UDim2.fromOffset(148, 148)
map.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
map.BackgroundTransparency = 0.08
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

local dot = Instance.new("Frame")
dot.Name = "PlayerDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 10 or 9, UserInputService.TouchEnabled and 10 or 9)
dot.BackgroundColor3 = Color3.fromRGB(255, 225, 92)
dot.BorderSizePixel = 0
dot.Parent = map

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local half = Config.WorldSize / 2
	local x = math.clamp((root.Position.X + half) / Config.WorldSize, 0.03, 0.97)
	local y = math.clamp(1 - ((root.Position.Z + half) / Config.WorldSize), 0.03, 0.97)
	dot.Position = UDim2.fromScale(x, y)
end)
