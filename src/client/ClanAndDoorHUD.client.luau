local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ClanRemotes")
local command = remotes:WaitForChild("Command")
local stateEvent = remotes:WaitForChild("State")
local getState = remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "ClanDoorHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 34
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.AnchorPoint = Vector2.new(1,0)
open.Position = UDim2.new(1,-18,0,208)
open.Size = UDim2.fromOffset(112,38)
open.BackgroundColor3 = Color3.fromRGB(31,31,35)
open.TextColor3 = Color3.new(1,1,1)
open.Text = "CLAN / DOOR"
open.Font = Enum.Font.GothamBold
open.TextSize = 11
open.Parent = gui
Instance.new("UICorner",open).CornerRadius = UDim.new(0,9)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1,0.5)
panel.Position = UDim2.new(1,-145,0.5,40)
panel.Size = UDim2.fromOffset(360,430)
panel.BackgroundColor3 = Color3.fromRGB(20,20,24)
panel.Visible = false
panel.ZIndex = 80
panel.Parent = gui
Instance.new("UICorner",panel).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14,10)
title.Size = UDim2.new(1,-60,0,34)
title.BackgroundTransparency = 1
title.Text = "CLANS + DOORS"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 81
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1,0)
close.Position = UDim2.new(1,-10,0,10)
close.Size = UDim2.fromOffset(36,34)
close.Text = "×"
close.BackgroundColor3 = Color3.fromRGB(48,48,53)
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 22
close.ZIndex = 82
close.Parent = panel
Instance.new("UICorner",close).CornerRadius = UDim.new(0,8)

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(14,52)
status.Size = UDim2.new(1,-28,0,62)
status.BackgroundTransparency = 1
status.Text = "No clan"
status.TextColor3 = Color3.fromRGB(215,215,220)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.ZIndex = 81
status.Parent = panel

local nameBox = Instance.new("TextBox")
nameBox.Position = UDim2.fromOffset(14,122)
nameBox.Size = UDim2.new(1,-28,0,38)
nameBox.PlaceholderText = "Clan name or join code"
nameBox.Text = ""
nameBox.BackgroundColor3 = Color3.fromRGB(37,37,42)
nameBox.TextColor3 = Color3.new(1,1,1)
nameBox.PlaceholderColor3 = Color3.fromRGB(145,145,150)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 12
nameBox.ClearTextOnFocus = false
nameBox.ZIndex = 81
nameBox.Parent = panel
Instance.new("UICorner",nameBox).CornerRadius = UDim.new(0,8)

local function button(text,y)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(14,y)
	b.Size = UDim2.new(1,-28,0,38)
	b.BackgroundColor3 = Color3.fromRGB(54,54,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.ZIndex = 81
	b.Parent = panel
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
	return b
end

local create = button("CREATE CLAN",170)
local join = button("JOIN BY CODE",214)
local leave = button("LEAVE CLAN",258)
local door = button("PLACE DOOR — 25 WOOD",318)
local access = button("CHANGE NEAREST DOOR ACCESS",362)

local msg = Instance.new("TextLabel")
msg.Position = UDim2.fromOffset(14,405)
msg.Size = UDim2.new(1,-28,0,18)
msg.BackgroundTransparency = 1
msg.TextColor3 = Color3.fromRGB(255,221,125)
msg.Font = Enum.Font.GothamBold
msg.TextSize = 10
msg.Text = ""
msg.ZIndex = 81
msg.Parent = panel

local function applyState(payload)
	local clan = payload and payload.Clan
	if clan and clan.InClan then
		status.Text = string.format("%s\nCode: %s  •  Members: %d", clan.Name or "Clan", clan.Code or "?", clan.MemberCount or 1)
	else
		status.Text = "No clan. Create one or enter a friend's join code."
	end
	if payload and payload.Message then msg.Text = payload.Message end
end

open.Activated:Connect(function() panel.Visible = not panel.Visible end)
close.Activated:Connect(function() panel.Visible = false end)
create.Activated:Connect(function() command:FireServer("Create",nameBox.Text) end)
join.Activated:Connect(function() command:FireServer("Join",nameBox.Text) end)
leave.Activated:Connect(function() command:FireServer("Leave") end)
door.Activated:Connect(function() command:FireServer("PlaceDoor") end)
access.Activated:Connect(function() command:FireServer("CycleDoorAccess") end)
stateEvent.OnClientEvent:Connect(applyState)

task.spawn(function()
	local ok, result = pcall(function() return getState:InvokeServer() end)
	if ok and type(result)=="table" then applyState(result) end
end)

if UserInputService.TouchEnabled then
	open.Position = UDim2.new(1,-18,0,350)
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	panel.Position = UDim2.fromScale(0.5,0.5)
	panel.Size = UDim2.new(1,-24,0,430)
end
