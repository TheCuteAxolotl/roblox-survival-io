local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local tracked = {}

local function prettyName(model)
	local kind = model:GetAttribute("MobType")
	if type(kind) == "string" and kind ~= "" then
		if kind == "WildCattle" then return "WILD CATTLE" end
		if kind == "SnowWolf" then return "SNOW WOLF" end
		if kind == "SnowBear" then return "SNOW BEAR" end
		if kind == "BroodSpider" then return "BROOD SPIDER" end
		if kind == "DireWolf" then return "DIRE WOLF" end
		if kind == "BlackwoodBear" then return "BLACKWOOD BEAR" end
		return string.upper(kind:gsub("(%l)(%u)", "%1 %2"))
	end
	return string.upper(model.Name:gsub("(%l)(%u)", "%1 %2"))
end

local function cleanup(model)
	local record = tracked[model]
	if not record then return end
	for _, connection in record.Connections do
		connection:Disconnect()
	end
	tracked[model] = nil
end

local function attach(model)
	if tracked[model] or not model:IsA("Model") or model:GetAttribute("SurvivalMob") ~= true then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not humanoid or not root or not root:IsA("BasePart") then return end

	-- Bosses already have a larger dedicated boss health display.
	if root:FindFirstChild("BossHealthBar") or model:FindFirstChild("BossHealthBar", true) then
		tracked[model] = { Connections = {} }
		return
	end

	pcall(function()
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end)

	local gui = Instance.new("BillboardGui")
	gui.Name = "PolishMobBar"
	gui.Size = UDim2.fromOffset(128, 31)
	gui.StudsOffset = Vector3.new(0, 5.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 72
	gui.Parent = root

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 15)
	name.BackgroundTransparency = 1
	name.Text = prettyName(model)
	name.TextColor3 = Color3.fromRGB(242, 242, 244)
	name.TextStrokeTransparency = 0.48
	name.Font = Enum.Font.GothamBold
	name.TextSize = 9
	name.Parent = gui

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0, 18)
	back.Size = UDim2.new(1, 0, 0, 9)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	back.BorderSizePixel = 0
	back.Parent = gui
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 4)
	backCorner.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(205, 72, 72)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local lastHealth = humanoid.Health
	local function update(health)
		local maxHealth = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(health / maxHealth, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(ratio, 1),
		}):Play()

		if health < lastHealth then
			name.TextColor3 = Color3.fromRGB(255, 192, 192)
			task.delay(0.12, function()
				if name.Parent then name.TextColor3 = Color3.fromRGB(242, 242, 244) end
			end)
		end
		lastHealth = health
	end

	local connections = {
		humanoid.HealthChanged:Connect(update),
		model.AncestryChanged:Connect(function(_, parent)
			if not parent then cleanup(model) end
		end),
	}
	tracked[model] = { Connections = connections }
	update(humanoid.Health)
end

local function inspect(instance)
	if not instance:IsA("Model") then return end
	if instance:GetAttribute("SurvivalMob") == true then
		task.defer(attach, instance)
	end
end

for _, descendant in world:GetDescendants() do inspect(descendant) end
world.DescendantAdded:Connect(inspect)
