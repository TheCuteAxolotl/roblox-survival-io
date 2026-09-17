local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PlayerCombatFeedbackHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(174, 31, 31)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Active = false
overlay.ZIndex = 1
overlay.Parent = gui

local warning = Instance.new("TextLabel")
warning.AnchorPoint = Vector2.new(0.5, 1)
warning.Position = UDim2.new(0.5, 0, 1, -145)
warning.Size = UDim2.fromOffset(260, 30)
warning.BackgroundTransparency = 1
warning.Text = "LOW HEALTH"
warning.TextColor3 = Color3.fromRGB(255, 118, 108)
warning.TextStrokeTransparency = 0.4
warning.Font = Enum.Font.GothamBlack
warning.TextSize = 14
warning.TextTransparency = 1
warning.ZIndex = 2
warning.Parent = gui

local healthConnection = nil
local pulseToken = 0

local function flash(strength)
	overlay.BackgroundTransparency = math.clamp(0.91 - strength * 0.22, 0.66, 0.91)
	TweenService:Create(overlay, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

local function setLowHealth(active)
	pulseToken += 1
	local token = pulseToken
	if not active then
		TweenService:Create(warning, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		return
	end
	task.spawn(function()
		while token == pulseToken and warning.Parent do
			TweenService:Create(warning, TweenInfo.new(0.35), { TextTransparency = 0.05 }):Play()
			task.wait(0.38)
			if token ~= pulseToken then break end
			TweenService:Create(warning, TweenInfo.new(0.55), { TextTransparency = 0.62 }):Play()
			task.wait(0.58)
		end
	end)
end

local function bindCharacter(character)
	if healthConnection then healthConnection:Disconnect() healthConnection = nil end
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then return end
	local previous = humanoid.Health
	local low = false

	healthConnection = humanoid.HealthChanged:Connect(function(health)
		if health < previous then
			local fraction = humanoid.MaxHealth > 0 and (previous - health) / humanoid.MaxHealth or 0
			flash(math.clamp(fraction * 3.5, 0.18, 1))
		end
		previous = health
		local nextLow = humanoid.MaxHealth > 0 and health > 0 and health / humanoid.MaxHealth <= 0.28
		if nextLow ~= low then
			low = nextLow
			setLowHealth(low)
		end
	end)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then task.spawn(bindCharacter, player.Character) end
