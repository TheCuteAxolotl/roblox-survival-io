local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("ExpansionAction")
local stateEvent = remotes:WaitForChild("ExpansionState")
local getState = remotes:WaitForChild("GetExpansionState")
local progressionState = remotes:WaitForChild("StateChanged")

local current = { DoorAccess = "OWNER" }

local gui = Instance.new("ScreenGui")
gui.Name = "ClanDoorHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")

local function style(obj, radius)
	obj.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
	if obj:IsA("TextButton") or obj:IsA("TextBox") then
		obj.TextColor3 = Color3.fromRGB(245, 245, 245)
		obj.Font = Enum.Font.GothamBold
		obj.TextSize = 12
	end
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 9)
	c.Parent = obj
end

local open = Instance.new("TextButton")
open.AnchorPoint = Vector2.new(0, 1)
open.Position = UDim2.new(0, 16, 1, -112)
open.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 124 or 108, 38)
open.Text = "CLAN / BASE"
open.Parent = gui
style(open)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -158)
panel.Size = UserInputService.TouchEnabled and UDim2.fromOffset(330, 370) or UDim2.fromOffset(360, 390)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.Visible = false
panel.Parent = gui
style(panel, 14)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 28)
title.BackgroundTransparency = 1
title.Text = "CLAN + BASE ACCESS"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(14, 42)
status.Size = UDim2.new(1, -28, 0, 48)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(190, 190, 198)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local nameBox = Instance.new("TextBox")
nameBox.Position = UDim2.fromOffset(14, 96)
nameBox.Size = UDim2.new(1, -28, 0, 38)
nameBox.PlaceholderText = "Clan name"
nameBox.Text = ""
nameBox.ClearTextOnFocus = false
nameBox.Parent = panel
style(nameBox)

local function button(text, x, y, w)
	local b = Instance.new("TextButton")
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, 36)
	b.Text = text
	b.Parent = panel
	style(b)
	return b
end

local create = button("CREATE", 14, 142, 100)
local join = button("JOIN", 122, 142, 100)
local leave = button("LEAVE", 230, 142, 100)
local access = button("ACCESS: OWNER", 14, 188, 152)
local placeDoor = button("PLACE DOOR", 174, 188, 156)
local spawnButton = button("SPAWN PAD LOCKED", 14, 234, 316)

local cost = Instance.new("TextLabel")
cost.Position = UDim2.fromOffset(14, 276)
cost.Size = UDim2.new(1, -28, 0, 45)
cost.BackgroundTransparency = 1
cost.Text = "Door: 25 wood + 5 stone\nSpawn Pad: 45 wood + 30 stone"
cost.TextColor3 = Color3.fromRGB(178, 178, 185)
cost.Font = Enum.Font.Gotham
cost.TextSize = 11
cost.TextXAlignment = Enum.TextXAlignment.Left
cost.Parent = panel

local choice = Instance.new("Frame")
choice.AnchorPoint = Vector2.new(0.5, 0.5)
choice.Position = UDim2.fromScale(0.5, 0.5)
choice.Size = UDim2.fromOffset(360, 190)
choice.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
choice.Visible = false
choice.ZIndex = 80
choice.Parent = gui
style(choice, 15)

local choiceText = Instance.new("TextLabel")
choiceText.Position = UDim2.fromOffset(18, 14)
choiceText.Size = UDim2.new(1, -36, 0, 92)
choiceText.BackgroundTransparency = 1
choiceText.Text = `AGE {ExpansionData.SpawnUnlockAge} BONUS\nUnlock a Spawn Pad? It lets you respawn at your base while the pad survives.`
choiceText.TextColor3 = Color3.fromRGB(245, 245, 245)
choiceText.Font = Enum.Font.GothamBold
choiceText.TextSize = 14
choiceText.TextWrapped = true
choiceText.ZIndex = 81
choiceText.Parent = choice

local unlock = Instance.new("TextButton")
unlock.Position = UDim2.fromOffset(18, 124)
unlock.Size = UDim2.fromOffset(156, 46)
unlock.Text = "UNLOCK"
unlock.ZIndex = 81
unlock.Parent = choice
style(unlock)

local skip = Instance.new("TextButton")
skip.Position = UDim2.fromOffset(186, 124)
skip.Size = UDim2.fromOffset(156, 46)
skip.Text = "SKIP THIS RUN"
skip.ZIndex = 81
skip.Parent = choice
style(skip)

local function refresh(payload)
	if type(payload) ~= "table" then return end
	current = payload
	status.Text = payload.Clan and `Clan: {payload.Clan}{payload.ClanOwner and "  •  OWNER" or ""}` or "Clan: none — type a name to create or join one."
	access.Text = `ACCESS: {payload.DoorAccess or "OWNER"}`
	if payload.SpawnPadUnlocked then
		spawnButton.Text = payload.SpawnPadPlaced and "SPAWN PAD PLACED" or "PLACE SPAWN PAD"
		spawnButton.Active = not payload.SpawnPadPlaced
	elseif payload.SpawnChoiceAvailable then
		spawnButton.Text = "SPAWN PAD CHOICE READY"
		spawnButton.Active = false
	else
		spawnButton.Text = "SPAWN PAD LOCKED"
		spawnButton.Active = false
	end
	choice.Visible = payload.SpawnChoiceAvailable == true
	if payload.Message then status.Text ..= `\n{payload.Message}` end
end

local function pullState()
	local ok, data = pcall(function() return getState:InvokeServer() end)
	if ok then refresh(data) end
end

open.Activated:Connect(function() panel.Visible = not panel.Visible end)
create.Activated:Connect(function() action:FireServer("CreateClan", nameBox.Text) end)
join.Activated:Connect(function() action:FireServer("JoinClan", nameBox.Text) end)
leave.Activated:Connect(function() action:FireServer("LeaveClan") end)
placeDoor.Activated:Connect(function() action:FireServer("PlaceDoor") end)
spawnButton.Activated:Connect(function() if current.SpawnPadUnlocked and not current.SpawnPadPlaced then action:FireServer("PlaceSpawnPad") end end)

access.Activated:Connect(function()
	local modes = ExpansionData.DoorAccessModes
	local index = table.find(modes, current.DoorAccess or "OWNER") or 1
	index = index % #modes + 1
	action:FireServer("SetDoorAccess", modes[index])
end)

unlock.Activated:Connect(function() choice.Visible = false action:FireServer("UnlockSpawnPad") end)
skip.Activated:Connect(function() choice.Visible = false action:FireServer("SkipSpawnPad") end)

stateEvent.OnClientEvent:Connect(refresh)
progressionState.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.Profile then task.delay(0.1, pullState) end
end)

task.spawn(function()
	task.wait(0.8)
	pullState()
end)
