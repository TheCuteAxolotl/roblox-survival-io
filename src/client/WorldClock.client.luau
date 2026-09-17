local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "WorldClockHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 19
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -18, 0, 182)
label.Size = UDim2.fromOffset(148, 28)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
label.BackgroundTransparency = 0.08
label.TextColor3 = Color3.fromRGB(240, 240, 244)
label.Font = Enum.Font.GothamBold
label.TextSize = 11
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = label

local function phase(hour)
	if hour >= 5 and hour < 11 then return "MORNING" end
	if hour >= 11 and hour < 17 then return "AFTERNOON" end
	if hour >= 17 and hour < 20 then return "EVENING" end
	return "NIGHT"
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
	label.Text = `{phase(t)}  •  {formatTime(t)}`
end)
