local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RegionDiscoveryHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 44
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5,0)
panel.Position = UDim2.new(0.5,0,0,-90)
panel.Size = UDim2.fromOffset(430,72)
panel.BackgroundColor3 = Color3.fromRGB(12,12,16)
panel.BackgroundTransparency = 0.18
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,14)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255,255,255)
stroke.Transparency = 0.84
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14,10)
title.Size = UDim2.new(1,-28,0,28)
title.BackgroundTransparency = 1
title.Text = ""
title.TextColor3 = Color3.fromRGB(245,245,248)
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.Parent = panel

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(14,40)
sub.Size = UDim2.new(1,-28,0,20)
sub.BackgroundTransparency = 1
sub.Text = ""
sub.TextColor3 = Color3.fromRGB(182,182,192)
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 10
sub.Parent = panel

local regions = {
	{ Name="FROST HIGHLANDS", Center=Vector2.new(-980,850), Half=Vector2.new(220,190), Desc="Mammoths • glacier predators • icebound golems", Color=Color3.fromRGB(176,224,255) },
	{ Name="SUNSCAR DUNES", Center=Vector2.new(980,850), Half=Vector2.new(220,190), Desc="Hyenas • titan scorpions • lost sandstone ruins", Color=Color3.fromRGB(255,184,76) },
	{ Name="MIRE MARSH", Center=Vector2.new(-980,-850), Half=Vector2.new(220,190), Desc="Bog crawlers • mire beasts • toxic wetlands", Color=Color3.fromRGB(118,220,130) },
	{ Name="EMBER GROVE", Center=Vector2.new(980,-850), Half=Vector2.new(220,190), Desc="Ember wildlife • ash hounds • burning forest", Color=Color3.fromRGB(255,115,72) },
	{ Name="CRYSTAL BASIN", Center=Vector2.new(0,980), Half=Vector2.new(165,135), Desc="Prism stags • crystal golems • arcane shards", Color=Color3.fromRGB(173,137,255) },
}

local current
local token = 0

local function show(region)
	token += 1
	local mine = token
	title.Text = region.Name
	title.TextColor3 = region.Color
	sub.Text = region.Desc
	TweenService:Create(panel, TweenInfo.new(0.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Position=UDim2.new(0.5,0,0,82)}):Play()
	task.delay(2.8,function()
		if token ~= mine then return end
		TweenService:Create(panel,TweenInfo.new(0.38,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0.5,0,0,-90)}):Play()
	end)
end

local function regionAt(position)
	local p = Vector2.new(position.X,position.Z)
	for _, region in regions do
		local delta = p - region.Center
		if math.abs(delta.X) <= region.Half.X and math.abs(delta.Y) <= region.Half.Y then return region end
	end
	return nil
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then return end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local nextRegion = regionAt(root.Position)
	if nextRegion ~= current then
		current = nextRegion
		if nextRegion then show(nextRegion) end
	end
end)
