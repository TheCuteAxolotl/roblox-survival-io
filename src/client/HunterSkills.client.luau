local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HunterSkillsHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 36
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Position = UserInputService.TouchEnabled and UDim2.new(0, 14, 1, -142) or UDim2.fromOffset(16, 352)
open.Size = UDim2.fromOffset(104, 34)
open.BackgroundColor3 = Color3.fromRGB(35, 35, 41)
open.BackgroundTransparency = 0.12
open.TextColor3 = Color3.fromRGB(238, 238, 242)
open.Font = Enum.Font.GothamBold
open.TextSize = 11
open.Text = "SKILLS [K]"
open.Parent = gui
Instance.new("UICorner", open).CornerRadius = UDim.new(0, 9)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 330 or 390, 318)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255,255,255) stroke.Transparency = 0.82 stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -64, 0, 30)
title.BackgroundTransparency = 1
title.Text = "HUNTER GROWTH"
title.TextColor3 = Color3.fromRGB(245, 221, 145)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1,0)
close.Position = UDim2.new(1,-12,0,10)
close.Size = UDim2.fromOffset(36,32)
close.BackgroundColor3 = Color3.fromRGB(52,52,59)
close.TextColor3 = Color3.new(1,1,1)
close.Text = "×"
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)

local summary = Instance.new("TextLabel")
summary.Position = UDim2.fromOffset(16, 48)
summary.Size = UDim2.new(1,-32,0,46)
summary.BackgroundTransparency = 1
summary.TextColor3 = Color3.fromRGB(195,195,204)
summary.Font = Enum.Font.Gotham
summary.TextSize = 11
summary.TextWrapped = true
summary.TextXAlignment = Enum.TextXAlignment.Left
summary.TextYAlignment = Enum.TextYAlignment.Top
summary.Parent = panel

local list = Instance.new("Frame")
list.Position = UDim2.fromOffset(14, 100)
list.Size = UDim2.new(1,-28,1,-114)
list.BackgroundTransparency = 1
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,7)
layout.Parent = list

local rows = {}
local skillDescriptions = {
	Power = "More damage with every weapon.",
	Vitality = "Reduces incoming damage on top of armor.",
	Agility = "Adds movement speed and improves dodge recovery.",
	Fortune = "Raises Gold earned from completed contracts.",
}

for order, skill in { "Power", "Vitality", "Agility", "Fortune" } do
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1,0,0,46)
	row.BackgroundColor3 = Color3.fromRGB(31,31,37)
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(10,5)
	name.Size = UDim2.new(0.42,0,0,18)
	name.BackgroundTransparency = 1
	name.Text = string.upper(skill)
	name.TextColor3 = Color3.fromRGB(240,240,244)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 11
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row
	local level = Instance.new("TextLabel")
	level.AnchorPoint = Vector2.new(1,0)
	level.Position = UDim2.new(1,-10,0,5)
	level.Size = UDim2.fromOffset(90,18)
	level.BackgroundTransparency = 1
	level.TextColor3 = Color3.fromRGB(245,202,107)
	level.Font = Enum.Font.GothamBlack
	level.TextSize = 11
	level.TextXAlignment = Enum.TextXAlignment.Right
	level.Parent = row
	local desc = Instance.new("TextLabel")
	desc.Position = UDim2.fromOffset(10,24)
	desc.Size = UDim2.new(1,-20,0,16)
	desc.BackgroundTransparency = 1
	desc.Text = skillDescriptions[skill]
	desc.TextColor3 = Color3.fromRGB(164,164,174)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 9
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = row
	rows[skill] = level
end

local function refresh()
	local rank = player:GetAttribute("HunterRank") or "E"
	local mastery = math.floor(player:GetAttribute("HunterMasteryXP") or 0)
	local minutes = math.floor(player:GetAttribute("HunterMinutes") or 0)
	local missions = math.floor(player:GetAttribute("HunterMissions") or 0)
	summary.Text = `HUNTER RANK {rank}  •  MASTERY {mastery}\n{minutes} min played  •  {missions} contracts completed`
	for _, skill in { "Power", "Vitality", "Agility", "Fortune" } do
		local value = player:GetAttribute(`Hunter{skill}Level`) or 1
		rows[skill].Text = `LV. {value}`
	end
end

local function setOpen(value)
	panel.Visible = value
	if value then refresh() end
end
open.Activated:Connect(function() setOpen(not panel.Visible) end)
close.Activated:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.K then setOpen(not panel.Visible) end
end)

for _, name in { "HunterRank", "HunterMasteryXP", "HunterMinutes", "HunterMissions", "HunterPowerLevel", "HunterVitalityLevel", "HunterAgilityLevel", "HunterFortuneLevel" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
