local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "WorldClockHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 70
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "WorldClock"
label.AnchorPoint = Vector2.new(0, 0)
-- Keep the clock under the survival bars on the left side. The right side is
-- reserved for BAG/CRAFT/KITS/ACTION controls and was covering the old clock.
label.Position = UDim2.fromOffset(16, 262)
label.Size = UDim2.fromOffset(250, 46)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
label.BackgroundTransparency = 0.05
label.TextColor3 = Color3.fromRGB(240, 240, 244)
label.Font = Enum.Font.GothamBold
label.TextSize = 11
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Center
label.ZIndex = 5
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = label
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.84
stroke.Parent = label

local function phase(hour)
	if hour >= 5 and hour < 11 then return "MORNING" end
	if hour >= 11 and hour < 17 then return "AFTERNOON" end
	if hour >= 17 and hour < 20 then return "EVENING" end
	return "NIGHT"
end

local function nextPhase(hour)
	if hour >= 5 and hour < 11 then return "Afternoon", 11 end
	if hour >= 11 and hour < 17 then return "Evening", 17 end
	if hour >= 17 and hour < 20 then return "Night", 20 end
	return "Morning", 5
end

local function formatTime(clockTime)
	local totalMinutes = math.floor((clockTime % 24) * 60 + 0.5)
	local hour24 = math.floor(totalMinutes / 60) % 24
	local minute = totalMinutes % 60
	local suffix = hour24 >= 12 and "PM" or "AM"
	local hour12 = hour24 % 12
	if hour12 == 0 then hour12 = 12 end
	return string.format("%d:%02d %s", hour12, minute, suffix)
end

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.2 then return end
	accumulator = 0
	local t = Lighting.ClockTime
	local nextName, nextHour = nextPhase(t)
	label.Text = `{phase(t)}   •   {formatTime(t)}\nNext: {nextName} at {formatTime(nextHour)}`
end)
