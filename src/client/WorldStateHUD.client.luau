local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "WildforgeWorldHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 27
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 16)
card.Size = UDim2.fromOffset(420, 46)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
card.BackgroundTransparency = 0.16
card.BorderSizePixel = 0
card.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.87
stroke.Parent = card

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Position = UDim2.fromOffset(12, 5)
phaseLabel.Size = UDim2.new(0.72, -12, 0, 24)
phaseLabel.BackgroundTransparency = 1
phaseLabel.TextColor3 = Color3.fromRGB(245, 245, 248)
phaseLabel.Font = Enum.Font.GothamBold
phaseLabel.TextSize = 12
phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
phaseLabel.Parent = card

local threatLabel = Instance.new("TextLabel")
threatLabel.AnchorPoint = Vector2.new(1, 0)
threatLabel.Position = UDim2.new(1, -12, 0, 5)
threatLabel.Size = UDim2.new(0.28, 0, 0, 24)
threatLabel.BackgroundTransparency = 1
threatLabel.Font = Enum.Font.GothamBold
threatLabel.TextSize = 10
threatLabel.TextXAlignment = Enum.TextXAlignment.Right
threatLabel.Parent = card

local progressBack = Instance.new("Frame")
progressBack.Position = UDim2.fromOffset(12, 33)
progressBack.Size = UDim2.new(1, -24, 0, 5)
progressBack.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
progressBack.BorderSizePixel = 0
progressBack.Parent = card
Instance.new("UICorner", progressBack).CornerRadius = UDim.new(1, 0)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 142)
banner.Size = UDim2.fromOffset(430, 74)
banner.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.BorderSizePixel = 0
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 14)
bannerCorner.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Position = UDim2.fromOffset(14, 9)
bannerTitle.Size = UDim2.new(1, -28, 0, 28)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextSize = 22
bannerTitle.TextTransparency = 1
bannerTitle.Parent = banner

local bannerSub = Instance.new("TextLabel")
bannerSub.Position = UDim2.fromOffset(14, 39)
bannerSub.Size = UDim2.new(1, -28, 0, 22)
bannerSub.BackgroundTransparency = 1
bannerSub.TextColor3 = Color3.fromRGB(220, 220, 228)
bannerSub.Font = Enum.Font.GothamMedium
bannerSub.TextSize = 11
bannerSub.TextTransparency = 1
bannerSub.Parent = banner

local phaseColors = {
	Dawn = Color3.fromRGB(244, 185, 119),
	Day = Color3.fromRGB(149, 211, 132),
	Dusk = Color3.fromRGB(229, 137, 104),
	Night = Color3.fromRGB(134, 159, 230),
}

local bannerToken = 0
local lastPhase = ReplicatedStorage:GetAttribute("WildforgePhase")
local lastDay = ReplicatedStorage:GetAttribute("WildforgeDay")

local function formatTime(clockTime)
	local totalMinutes = math.floor((clockTime % 24) * 60 + 0.5)
	local hour24 = math.floor(totalMinutes / 60) % 24
	local minute = totalMinutes % 60
	local suffix = hour24 >= 12 and "PM" or "AM"
	local hour12 = hour24 % 12
	if hour12 == 0 then hour12 = 12 end
	return string.format("%d:%02d %s", hour12, minute, suffix)
end

local function phaseDescription(phase, event)
	if phase == "Dawn" then return "You made it through the dark. Rebuild, hunt and explore." end
	if phase == "Day" then return "Best time to gather, trade, build and travel." end
	if phase == "Dusk" then return "Finish what you're doing. Predators are waking up." end
	if event == "BLOOD MOON" then return "Extreme night: stay equipped or stay close to your defenses." end
	if event == "PREDATOR HUNT" then return "Predators are unusually aggressive tonight." end
	return "Night creatures are active and hostile wildlife becomes more dangerous."
end

local function showBanner(phase, day, event)
	bannerToken += 1
	local token = bannerToken
	banner.Visible = true
	banner.BackgroundTransparency = 1
	bannerTitle.TextTransparency = 1
	bannerSub.TextTransparency = 1
	bannerTitle.TextColor3 = phaseColors[phase] or Color3.new(1, 1, 1)
	bannerTitle.Text = phase == "Night" and (event ~= "" and event or `NIGHT {day}`) or string.upper(phase)
	bannerSub.Text = phaseDescription(phase, event)
	TweenService:Create(banner, TweenInfo.new(0.18), { BackgroundTransparency = 0.18 }):Play()
	TweenService:Create(bannerTitle, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
	TweenService:Create(bannerSub, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
	task.delay(2.8, function()
		if token ~= bannerToken then return end
		TweenService:Create(banner, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(bannerTitle, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(bannerSub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		task.delay(0.4, function()
			if token == bannerToken then banner.Visible = false end
		end)
	end)
end

local function refresh(forceBanner)
	if player:GetAttribute("InRiftExpedition") == true then
		card.Visible = false
		banner.Visible = false
		return
	end
	card.Visible = true
	local day = ReplicatedStorage:GetAttribute("WildforgeDay") or 1
	local phase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"
	local threat = ReplicatedStorage:GetAttribute("WildforgeThreat") or 1
	local progress = math.clamp(ReplicatedStorage:GetAttribute("WildforgePhaseProgress") or 0, 0, 1)
	local endsAt = ReplicatedStorage:GetAttribute("WildforgePhaseEndsAt") or workspace:GetServerTimeNow()
	local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
	local event = ReplicatedStorage:GetAttribute("WildforgeEvent") or ""

	phaseLabel.Text = `DAY {day}  •  {string.upper(phase)}  •  {formatTime(Lighting.ClockTime)}  •  {remaining}s`
	local phaseColor = phaseColors[phase] or Color3.new(1, 1, 1)
	progressFill.BackgroundColor3 = phaseColor
	progressFill.Size = UDim2.fromScale(progress, 1)
	threatLabel.Text = `THREAT {threat}/6`
	threatLabel.TextColor3 = threat >= 5 and Color3.fromRGB(245, 116, 106)
		or (threat >= 3 and Color3.fromRGB(244, 188, 102) or Color3.fromRGB(170, 205, 170))

	if forceBanner or phase ~= lastPhase or day ~= lastDay then
		lastPhase, lastDay = phase, day
		showBanner(phase, day, event)
	end
end

for _, attribute in { "WildforgeDay", "WildforgePhase", "WildforgeThreat", "WildforgeEvent" } do
	ReplicatedStorage:GetAttributeChangedSignal(attribute):Connect(function()
		refresh(true)
	end)
end

local timer = 0
RunService.Heartbeat:Connect(function(dt)
	timer += dt
	if timer >= 0.25 then
		timer = 0
		refresh(false)
	end
end)

refresh(false)


player:GetAttributeChangedSignal("InRiftExpedition"):Connect(function()
	refresh(false)
end)
