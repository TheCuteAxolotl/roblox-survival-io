local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("ExpansionAction")
local stateEvent = remotes:WaitForChild("ExpansionState")
local getState = remotes:WaitForChild("GetExpansionState")

local current = { DoorAccess = "OWNER" }
local gui = Instance.new("ScreenGui")
gui.Name = "ClanDoorHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 95
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function style(obj, radius)
	obj.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	if obj:IsA("TextButton") or obj:IsA("TextBox") then
		obj.TextColor3 = Color3.fromRGB(245, 245, 245)
		obj.Font = Enum.Font.GothamBold
		obj.TextSize = 12
	end
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius or 9) c.Parent = obj
end

local open = Instance.new("TextButton")
open.AnchorPoint = Vector2.new(0, 1)
open.Position = UDim2.new(0, 16, 1, -112)
open.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 124 or 108, 38)
open.Text = "CLAN / BASE"
open.ZIndex = 60
open.Parent = gui
style(open)

local blocker = Instance.new("TextButton")
blocker.Size = UDim2.fromScale(1, 1)
blocker.BackgroundColor3 = Color3.new(0, 0, 0)
blocker.BackgroundTransparency = 0.68
blocker.Text = ""
blocker.AutoButtonColor = false
blocker.Visible = false
blocker.ZIndex = 40
blocker.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -158)
panel.Size = UserInputService.TouchEnabled and UDim2.new(1, -32, 0, 310) or UDim2.fromOffset(370, 310)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.Visible = false
panel.ZIndex = 50
panel.Parent = gui
style(panel, 14)
local constraint = Instance.new("UISizeConstraint") constraint.MaxSize = Vector2.new(370, 310) constraint.MinSize = Vector2.new(300, 290) constraint.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 28)
title.BackgroundTransparency = 1
title.Text = "CLAN + BASE ACCESS"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 51
title.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(14, 42)
status.Size = UDim2.new(1, -28, 0, 46)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(190, 190, 198)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.ZIndex = 51
status.Parent = panel

local nameBox = Instance.new("TextBox")
nameBox.Position = UDim2.fromOffset(14, 92)
nameBox.Size = UDim2.new(1, -28, 0, 38)
nameBox.PlaceholderText = "Full clan name to create / join"
nameBox.Text = ""
nameBox.ClearTextOnFocus = false
nameBox.ZIndex = 51
nameBox.Parent = panel
style(nameBox)

local function button(text, x, y, w)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, 36)
	b.Text = text
	b.ZIndex = 51
	b.Parent = panel
	style(b)
	return b
end

local create = button("CREATE", 14, 140, 102)
local join = button("JOIN", 124, 140, 102)
local leave = button("LEAVE", 234, 140, 102)
local access = button("ACCESS: OWNER", 14, 188, 158)
local placeDoor = button("PLACE DOOR", 180, 188, 156)

local cost = Instance.new("TextLabel")
cost.Position = UDim2.fromOffset(14, 234)
cost.Size = UDim2.new(1, -28, 0, 58)
cost.BackgroundTransparency = 1
cost.Text = "Door: 35 wood + 12 stone\nClan names are permanently reserved. Only your short [TAG] is shown above players."
cost.TextColor3 = Color3.fromRGB(178, 178, 185)
cost.Font = Enum.Font.Gotham
cost.TextSize = 10
cost.TextWrapped = true
cost.TextXAlignment = Enum.TextXAlignment.Left
cost.TextYAlignment = Enum.TextYAlignment.Top
cost.ZIndex = 51
cost.Parent = panel

local function syncModal()
	blocker.Visible = panel.Visible
end

local function refresh(payload)
	if type(payload) ~= "table" then return end
	current = payload
	status.Text = payload.ClanTag and `Clan: [${payload.ClanTag}]${payload.ClanOwner and "  •  OWNER" or ""}` or "Clan: none — create or join using the full clan name."
	access.Text = `ACCESS: ${payload.DoorAccess or "OWNER"}`
	if payload.Message then status.Text ..= `\n${payload.Message}` end
end

local function pullState()
	local ok, data = pcall(function() return getState:InvokeServer() end)
	if ok then refresh(data) end
end

open.Activated:Connect(function() panel.Visible = not panel.Visible syncModal() end)
blocker.Activated:Connect(function() panel.Visible = false syncModal() end)
create.Activated:Connect(function() action:FireServer("CreateClan", nameBox.Text) end)
join.Activated:Connect(function() action:FireServer("JoinClan", nameBox.Text) end)
leave.Activated:Connect(function() action:FireServer("LeaveClan") end)
placeDoor.Activated:Connect(function() action:FireServer("PlaceDoor") end)
access.Activated:Connect(function()
	local modes = ExpansionData.DoorAccessModes
	local index = table.find(modes, current.DoorAccess or "OWNER") or 1
	action:FireServer("SetDoorAccess", modes[index % #modes + 1])
end)
stateEvent.OnClientEvent:Connect(refresh)
task.spawn(function() task.wait(1) pullState() end)
