local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local missionState = remotes:WaitForChild("MissionState")
local getMissionState = remotes:WaitForChild("GetMissionState")
local missionAction = remotes:WaitForChild("MissionAction")

local gui = Instance.new("ScreenGui")
gui.Name = "MissionTrackerHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 31
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -18, 0, UserInputService.TouchEnabled and 340 or 380)
card.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 220 or 258, 104)
card.BackgroundColor3 = Color3.fromRGB(19, 19, 23)
card.BackgroundTransparency = 0.14
card.BorderSizePixel = 0
card.Parent = gui
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 12) corner.Parent = card
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255,255,255) stroke.Transparency = 0.86 stroke.Parent = card

local rank = Instance.new("TextLabel")
rank.Position = UDim2.fromOffset(10, 7)
rank.Size = UDim2.fromOffset(36, 18)
rank.BackgroundColor3 = Color3.fromRGB(85, 68, 43)
rank.TextColor3 = Color3.fromRGB(255, 225, 145)
rank.Font = Enum.Font.GothamBlack
rank.TextSize = 11
rank.Text = "--"
rank.Parent = card
Instance.new("UICorner", rank).CornerRadius = UDim.new(0, 6)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(52, 6)
title.Size = UDim2.new(1, -62, 0, 21)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(244,244,247)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "NO ACTIVE CONTRACT"
title.Parent = card

local detail = Instance.new("TextLabel")
detail.Position = UDim2.fromOffset(10, 31)
detail.Size = UDim2.new(1, -20, 0, 32)
detail.BackgroundTransparency = 1
detail.TextColor3 = Color3.fromRGB(190,190,198)
detail.Font = Enum.Font.Gotham
detail.TextSize = 10
detail.TextWrapped = true
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.TextYAlignment = Enum.TextYAlignment.Top
detail.Text = "Visit the Hunter Town Hall and take a paper contract from the board."
detail.Parent = card

local progressBack = Instance.new("Frame")
progressBack.Position = UDim2.fromOffset(10, 68)
progressBack.Size = UDim2.new(1, -88, 0, 12)
progressBack.BackgroundColor3 = Color3.fromRGB(49,49,55)
progressBack.BorderSizePixel = 0
progressBack.Parent = card
Instance.new("UICorner", progressBack).CornerRadius = UDim.new(1,0)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0,1)
progressFill.BackgroundColor3 = Color3.fromRGB(220, 173, 73)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1,0)

local progressText = Instance.new("TextLabel")
progressText.Position = UDim2.fromOffset(10, 82)
progressText.Size = UDim2.new(1, -88, 0, 16)
progressText.BackgroundTransparency = 1
progressText.TextColor3 = Color3.fromRGB(219,219,224)
progressText.Font = Enum.Font.GothamMedium
progressText.TextSize = 9
progressText.TextXAlignment = Enum.TextXAlignment.Left
progressText.Text = ""
progressText.Parent = card

local abandon = Instance.new("TextButton")
abandon.AnchorPoint = Vector2.new(1,1)
abandon.Position = UDim2.new(1,-9,1,-9)
abandon.Size = UDim2.fromOffset(66,28)
abandon.BackgroundColor3 = Color3.fromRGB(63,43,45)
abandon.TextColor3 = Color3.fromRGB(242,205,205)
abandon.Font = Enum.Font.GothamBold
abandon.TextSize = 9
abandon.Text = "ABANDON"
abandon.Visible = false
abandon.Parent = card
Instance.new("UICorner", abandon).CornerRadius = UDim.new(0,8)
abandon.Activated:Connect(function() missionAction:FireServer("Abandon") end)

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5,0.5)
toast.Position = UDim2.fromScale(0.5,0.42)
toast.Size = UDim2.fromOffset(500,52)
toast.BackgroundColor3 = Color3.fromRGB(16,16,19)
toast.BackgroundTransparency = 0.16
toast.TextColor3 = Color3.fromRGB(255,225,135)
toast.Font = Enum.Font.GothamBlack
toast.TextSize = 16
toast.Visible = false
toast.ZIndex = 20
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0,12)
local toastToken = 0

local function showToast(text)
	if type(text) ~= "string" or text == "" then return end
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(2.6, function() if token == toastToken then toast.Visible = false end end)
end

local function render(state)
	if type(state) ~= "table" then return end
	if state.Active then
		rank.Text = state.Rank or "?"
		title.Text = string.upper(state.Title or "CONTRACT")
		detail.Text = state.Description or ""
		local goal = math.max(1, tonumber(state.Goal) or 1)
		local progress = math.clamp(tonumber(state.Progress) or 0, 0, goal)
		progressFill.Size = UDim2.fromScale(progress / goal, 1)
		progressText.Text = `{progress}/{goal}  •  {state.RewardGold or 0} GOLD + {state.RewardXP or 0} XP`
		abandon.Visible = true
	else
		rank.Text = "--"
		title.Text = "NO ACTIVE CONTRACT"
		detail.Text = "Visit the Hunter Town Hall and take a paper contract from the board."
		progressFill.Size = UDim2.fromScale(0,1)
		progressText.Text = `COMPLETED THIS RUN: {state.CompletedThisSession or 0}`
		abandon.Visible = false
	end
	showToast(state.Message)
end

missionState.OnClientEvent:Connect(render)
task.spawn(function()
	local ok, state = pcall(function() return getMissionState:InvokeServer() end)
	if ok then render(state) end
end)
