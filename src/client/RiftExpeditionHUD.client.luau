local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local RiftData = require(ReplicatedStorage.Shared.RiftRunData)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local riftState = remotes:WaitForChild("RiftState")
local riftAction = remotes:WaitForChild("RiftAction")
local getRiftState = remotes:WaitForChild("GetRiftState")

local gui = Instance.new("ScreenGui")
gui.Name = "RiftExpeditionHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 90
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

local function stroke(obj, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(213, 186, 255)
	s.Transparency = transparency or 0.78
	s.Parent = obj
end

local top = Instance.new("Frame")
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 18)
top.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 330 or 430, 82)
top.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
top.BackgroundTransparency = 0.08
top.BorderSizePixel = 0
top.Visible = false
top.Parent = gui
corner(top, 13)
stroke(top)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 23)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(226, 202, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RIFT EXPEDITION"
title.Parent = top

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(14, 31)
status.Size = UDim2.new(1, -28, 0, 19)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(244, 244, 248)
status.Font = Enum.Font.GothamBold
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = ""
status.Parent = top

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(14, 53)
sub.Size = UDim2.new(1, -28, 0, 18)
sub.BackgroundTransparency = 1
sub.TextColor3 = Color3.fromRGB(174, 174, 188)
sub.Font = Enum.Font.Gotham
sub.TextSize = 10
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Text = ""
sub.Parent = top

local runCard = Instance.new("Frame")
runCard.AnchorPoint = Vector2.new(0, 1)
runCard.Position = UDim2.new(0, 16, 1, -72)
runCard.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 218 or 270, 92)
runCard.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
runCard.BackgroundTransparency = 0.12
runCard.BorderSizePixel = 0
runCard.Visible = false
runCard.Parent = gui
corner(runCard, 12)
stroke(runCard, 0.84)

local bank = Instance.new("TextLabel")
bank.Position = UDim2.fromOffset(12, 8)
bank.Size = UDim2.new(1, -24, 0, 20)
bank.BackgroundTransparency = 1
bank.TextColor3 = Color3.fromRGB(255, 220, 125)
bank.Font = Enum.Font.GothamBold
bank.TextSize = 11
bank.TextXAlignment = Enum.TextXAlignment.Left
bank.Text = ""
bank.Parent = runCard

local level = Instance.new("TextLabel")
level.Position = UDim2.fromOffset(12, 30)
level.Size = UDim2.new(1, -24, 0, 16)
level.BackgroundTransparency = 1
level.TextColor3 = Color3.fromRGB(222, 222, 231)
level.Font = Enum.Font.GothamMedium
level.TextSize = 10
level.TextXAlignment = Enum.TextXAlignment.Left
level.Text = ""
level.Parent = runCard

local essenceBack = Instance.new("Frame")
essenceBack.Position = UDim2.fromOffset(12, 50)
essenceBack.Size = UDim2.new(1, -24, 0, 10)
essenceBack.BackgroundColor3 = Color3.fromRGB(47, 45, 55)
essenceBack.BorderSizePixel = 0
essenceBack.Parent = runCard
corner(essenceBack, 5)

local essenceFill = Instance.new("Frame")
essenceFill.Size = UDim2.fromScale(0, 1)
essenceFill.BackgroundColor3 = Color3.fromRGB(157, 100, 228)
essenceFill.BorderSizePixel = 0
essenceFill.Parent = essenceBack
corner(essenceFill, 5)

local lives = Instance.new("TextLabel")
lives.Position = UDim2.fromOffset(12, 66)
lives.Size = UDim2.new(1, -24, 0, 17)
lives.BackgroundTransparency = 1
lives.TextColor3 = Color3.fromRGB(183, 184, 199)
lives.Font = Enum.Font.Gotham
lives.TextSize = 9
lives.TextXAlignment = Enum.TextXAlignment.Left
lives.Text = ""
lives.Parent = runCard

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.38)
toast.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 330 or 510, 54)
toast.BackgroundColor3 = Color3.fromRGB(14, 13, 19)
toast.BackgroundTransparency = 0.12
toast.TextColor3 = Color3.fromRGB(237, 213, 255)
toast.Font = Enum.Font.GothamBlack
toast.TextSize = UserInputService.TouchEnabled and 13 or 16
toast.TextWrapped = true
toast.Visible = false
toast.ZIndex = 50
toast.Parent = gui
corner(toast, 12)
stroke(toast, 0.72)
local toastToken = 0

local choiceShade = Instance.new("Frame")
choiceShade.Size = UDim2.fromScale(1, 1)
choiceShade.BackgroundColor3 = Color3.fromRGB(7, 7, 10)
choiceShade.BackgroundTransparency = 0.28
choiceShade.Visible = false
choiceShade.ZIndex = 60
choiceShade.Parent = gui

local choiceTitle = Instance.new("TextLabel")
choiceTitle.AnchorPoint = Vector2.new(0.5, 0)
choiceTitle.Position = UDim2.new(0.5, 0, 0.18, 0)
choiceTitle.Size = UDim2.fromOffset(500, 44)
choiceTitle.BackgroundTransparency = 1
choiceTitle.Text = "CHOOSE A RIFT POWER"
choiceTitle.TextColor3 = Color3.fromRGB(238, 220, 255)
choiceTitle.Font = Enum.Font.GothamBlack
choiceTitle.TextSize = 22
choiceTitle.ZIndex = 61
choiceTitle.Parent = choiceShade

local choiceRow = Instance.new("Frame")
choiceRow.AnchorPoint = Vector2.new(0.5, 0.5)
choiceRow.Position = UDim2.fromScale(0.5, 0.52)
choiceRow.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 330 or 720, UserInputService.TouchEnabled and 390 or 210)
choiceRow.BackgroundTransparency = 1
choiceRow.ZIndex = 61
choiceRow.Parent = choiceShade

local layout = Instance.new("UIListLayout")
layout.FillDirection = UserInputService.TouchEnabled and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 12)
layout.Parent = choiceRow

local currentChoices = ""

local function showToast(message)
	if type(message) ~= "string" or message == "" then return end
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.12
	toast.Visible = true
	task.delay(2.7, function()
		if token ~= toastToken then return end
		TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.delay(0.32, function() if token == toastToken then toast.Visible = false end end)
	end)
end

local function clearChoiceCards()
	for _, child in choiceRow:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
end

local function renderChoices(packed)
	if type(packed) ~= "string" or packed == "" then
		currentChoices = ""
		choiceShade.Visible = false
		clearChoiceCards()
		return
	end
	if packed == currentChoices and choiceShade.Visible then return end
	currentChoices = packed
	clearChoiceCards()
	for id in string.gmatch(packed, "[^,]+") do
		local data = RiftData.Upgrades[id]
		if data then
			local button = Instance.new("TextButton")
			button.Size = UserInputService.TouchEnabled and UDim2.fromOffset(310, 112) or UDim2.fromOffset(224, 190)
			button.BackgroundColor3 = Color3.fromRGB(27, 23, 35)
			button.Text = ""
			button.AutoButtonColor = true
			button.ZIndex = 62
			button.Parent = choiceRow
			corner(button, 14)
			stroke(button, 0.62)

			local name = Instance.new("TextLabel")
			name.Position = UDim2.fromOffset(14, 14)
			name.Size = UDim2.new(1, -28, 0, 30)
			name.BackgroundTransparency = 1
			name.Text = data.Label
			name.TextColor3 = Color3.fromRGB(229, 202, 255)
			name.Font = Enum.Font.GothamBlack
			name.TextSize = 17
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.ZIndex = 63
			name.Parent = button

			local desc = Instance.new("TextLabel")
			desc.Position = UDim2.fromOffset(14, 51)
			desc.Size = UDim2.new(1, -28, UserInputService.TouchEnabled and 0 or 1, UserInputService.TouchEnabled and 48 or -92)
			desc.BackgroundTransparency = 1
			desc.Text = data.Description
			desc.TextColor3 = Color3.fromRGB(204, 203, 214)
			desc.Font = Enum.Font.Gotham
			desc.TextSize = 12
			desc.TextWrapped = true
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.TextYAlignment = Enum.TextYAlignment.Top
			desc.ZIndex = 63
			desc.Parent = button

			if not UserInputService.TouchEnabled then
				local choose = Instance.new("TextLabel")
				choose.AnchorPoint = Vector2.new(0, 1)
				choose.Position = UDim2.new(0, 14, 1, -12)
				choose.Size = UDim2.new(1, -28, 0, 24)
				choose.BackgroundTransparency = 1
				choose.Text = "CHOOSE"
				choose.TextColor3 = Color3.fromRGB(255, 226, 142)
				choose.Font = Enum.Font.GothamBold
				choose.TextSize = 11
				choose.TextXAlignment = Enum.TextXAlignment.Left
				choose.ZIndex = 63
				choose.Parent = button
			end

			button.Activated:Connect(function()
				button.Active = false
				riftAction:FireServer("ChoosePower", id)
			end)
		end
	end
	choiceShade.Visible = true
end

local function render(state)
	if type(state) ~= "table" then return end
	local inRun = state.InRun == true
	local rally = state.Status == "Rally"
	top.Visible = inRun or rally
	runCard.Visible = inRun

	if rally then
		title.Text = "RIFT RALLY"
		status.Text = string.format("Starting in %ds  •  %d player%s ready", state.RallyRemaining or 0, state.PartySize or 0, (state.PartySize or 0) == 1 and "" or "s")
		sub.Text = string.format("%s  •  Friends can join at the same gate.", state.ModifierLabel or "STABLE RIFT")
	elseif inRun then
		title.Text = string.format("RIFT // STAGE %d OF %d", state.Stage or 0, RiftData.MaxStages)
		status.Text = string.format("%s  •  %d ENEMIES", state.StageLabel or "", state.LiveEnemies or 0)
		if state.ExtractAvailable then
			sub.Text = "SAFE EXTRACTION OPEN • leave with your bank, or push deeper."
			sub.TextColor3 = Color3.fromRGB(255, 211, 115)
		elseif state.Downed then
			sub.Text = "DOWNED • wait for a revive or Second Wind."
			sub.TextColor3 = Color3.fromRGB(255, 130, 135)
		else
			sub.Text = string.format("%s  •  PARTY %d", state.ModifierLabel or "STABLE RIFT", state.PartySize or 1)
			sub.TextColor3 = Color3.fromRGB(174, 174, 188)
		end

		bank.Text = string.format("BANK  %d GOLD  •  %d XP", state.BankGold or 0, state.BankXP or 0)
		level.Text = string.format("RIFT LEVEL %d  •  ESSENCE %d/%d", state.RunLevel or 1, state.Essence or 0, state.NextEssence or 70)
		local nextEssence = math.max(1, state.NextEssence or 70)
		essenceFill.Size = UDim2.fromScale(math.clamp((state.Essence or 0) / nextEssence, 0, 1), 1)
		lives.Text = string.format("SECOND WINDS: %d  •  Dodge and positioning matter.", state.SecondWinds or 0)
	end

	renderChoices(state.PendingChoices)
	showToast(state.Message)
end

riftState.OnClientEvent:Connect(render)

task.spawn(function()
	local ok, state = pcall(function() return getRiftState:InvokeServer() end)
	if ok and type(state) == "table" then render(state) end
end)

for _, attr in { "RiftEssence", "RiftRunLevel", "RiftNextEssence", "RiftBankGold", "RiftBankXP", "RiftPendingChoices", "RiftDowned" } do
	player:GetAttributeChangedSignal(attr):Connect(function()
		local ok, state = pcall(function() return getRiftState:InvokeServer() end)
		if ok and type(state) == "table" then render(state) end
	end)
end
