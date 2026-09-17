local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AdvancedStructureData = require(ReplicatedStorage.Shared.AdvancedStructureData)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local placeRemote = remotes:WaitForChild("AdvancedBuildPlace")
local feedbackRemote = remotes:WaitForChild("AdvancedBuildFeedback")
local getState = remotes:WaitForChild("GetAdvancedBuildState")

local gui = Instance.new("ScreenGui")
gui.Name = "AdvancedBuildHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 37
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Position = UserInputService.TouchEnabled and UDim2.new(0,126,1,-142) or UDim2.fromOffset(128,352)
open.Size = UDim2.fromOffset(112,34)
open.BackgroundColor3 = Color3.fromRGB(43,48,43)
open.BackgroundTransparency = 0.12
open.TextColor3 = Color3.fromRGB(229,239,229)
open.Font = Enum.Font.GothamBold
open.TextSize = 10
open.Text = "STRUCTURES [B]"
open.Parent = gui
Instance.new("UICorner",open).CornerRadius = UDim.new(0,9)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 348 or 430,390)
panel.BackgroundColor3 = Color3.fromRGB(18,18,22)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner",panel).CornerRadius = UDim.new(0,16)
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255,255,255) stroke.Transparency = 0.82 stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16,12)
title.Size = UDim2.new(1,-64,0,28)
title.BackgroundTransparency = 1
title.Text = "BASE BUILDING"
title.TextColor3 = Color3.fromRGB(220,232,211)
title.Font = Enum.Font.GothamBlack
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(16,42)
sub.Size = UDim2.new(1,-32,0,34)
sub.BackgroundTransparency = 1
sub.Text = "Face where you want to build. Floors, walls, stairs, roofs, lights and defenses can be mixed into a real base."
sub.TextColor3 = Color3.fromRGB(171,171,180)
sub.Font = Enum.Font.Gotham
sub.TextSize = 10
sub.TextWrapped = true
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1,0)
close.Position = UDim2.new(1,-12,0,10)
close.Size = UDim2.fromOffset(36,32)
close.BackgroundColor3 = Color3.fromRGB(52,52,58)
close.TextColor3 = Color3.new(1,1,1)
close.Text = "×"
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = panel
Instance.new("UICorner",close).CornerRadius = UDim.new(0,8)

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5,1)
status.Position = UDim2.new(0.5,0,1,-10)
status.Size = UDim2.new(1,-28,0,28)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(247,211,130)
status.Font = Enum.Font.GothamBold
status.TextSize = 10
status.TextWrapped = true
status.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(14,84)
list.Size = UDim2.new(1,-28,1,-128)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0,7) layout.Parent = list

local cards = {}
for order, structureName in AdvancedStructureData.Order do
	local data = AdvancedStructureData.Structures[structureName]
	local card = Instance.new("TextButton")
	card.LayoutOrder = order
	card.Size = UDim2.new(1,0,0,52)
	card.BackgroundColor3 = Color3.fromRGB(33,33,39)
	card.Text = ""
	card.Parent = list
	Instance.new("UICorner",card).CornerRadius = UDim.new(0,10)
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(10,5)
	name.Size = UDim2.new(0.56,0,0,18)
	name.BackgroundTransparency = 1
	name.Text = string.upper(data.Label)
	name.TextColor3 = Color3.fromRGB(239,239,243)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 10
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card
	local cost = Instance.new("TextLabel")
	cost.AnchorPoint = Vector2.new(1,0)
	cost.Position = UDim2.new(1,-10,0,5)
	cost.Size = UDim2.new(0.42,0,0,18)
	cost.BackgroundTransparency = 1
	cost.Text = `{data.Cost.Wood or 0}W  {data.Cost.Stone or 0}S  •  F{data.MinForge}`
	cost.TextColor3 = Color3.fromRGB(231,198,116)
	cost.Font = Enum.Font.GothamBold
	cost.TextSize = 9
	cost.TextXAlignment = Enum.TextXAlignment.Right
	cost.Parent = card
	local desc = Instance.new("TextLabel")
	desc.Position = UDim2.fromOffset(10,26)
	desc.Size = UDim2.new(1,-20,0,18)
	desc.BackgroundTransparency = 1
	desc.Text = data.Description
	desc.TextColor3 = Color3.fromRGB(158,158,169)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 8
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = card
	card.Activated:Connect(function() placeRemote:FireServer(structureName) end)
	cards[structureName] = { Button = card, Cost = cost }
end

local function refreshState()
	local ok, state = pcall(function() return getState:InvokeServer() end)
	if not ok or type(state) ~= "table" then return end
	for _, structureName in AdvancedStructureData.Order do
		local data = AdvancedStructureData.Structures[structureName]
		local entry = cards[structureName]
		local locked = (state.Forge or 1) < data.MinForge
		local limit = state.Counts and state.Counts[structureName] or 0
		entry.Button.BackgroundColor3 = locked and Color3.fromRGB(46,39,42) or Color3.fromRGB(33,33,39)
		entry.Button.AutoButtonColor = not locked
		entry.Cost.Text = locked and `LOCKED • FORGE {data.MinForge}` or `{data.Cost.Wood or 0}W  {data.Cost.Stone or 0}S • {limit}/{data.Limit}`
	end
	status.Text = `CARRIED: {state.Wood or 0} WOOD • {state.Stone or 0} STONE • FORGE {state.Forge or 1}`
end

local function setOpen(value)
	panel.Visible = value
	if value then refreshState() end
end
open.Activated:Connect(function() setOpen(not panel.Visible) end)
close.Activated:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input,processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.B then setOpen(not panel.Visible) end
end)

feedbackRemote.OnClientEvent:Connect(function(message)
	if type(message) == "string" then status.Text = message end
	task.delay(0.15,refreshState)
end)
