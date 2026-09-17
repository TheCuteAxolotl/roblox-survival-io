local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SurvivalItemData = require(ReplicatedStorage.Shared.SurvivalItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local survivalAction = remotes:WaitForChild("SurvivalAction")
local survivalState = remotes:WaitForChild("SurvivalState")
local getSurvivalState = remotes:WaitForChild("GetSurvivalState")

local inventory = {}

-- V2 authority boundary: DirectionalControls owns ACTION/AUTO/ROTATE.
-- This HUD only provides a convenient one-tap food action.
local gui = Instance.new("ScreenGui")
gui.Name = "ActionAssistHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 38
gui.Parent = player:WaitForChild("PlayerGui")

local function styleButton(button)
	button.BackgroundColor3 = Color3.fromRGB(61, 61, 66)
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 11
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.84
	stroke.Parent = button
end

local eatButton = Instance.new("TextButton")
eatButton.Name = "QuickEat"
eatButton.Position = UDim2.fromOffset(16, 260)
eatButton.Size = UserInputService.TouchEnabled and UDim2.fromOffset(138, 44) or UDim2.fromOffset(118, 36)
eatButton.Text = "EAT FOOD"
eatButton.Parent = gui
styleButton(eatButton)

local eatHint = Instance.new("TextLabel")
eatHint.Position = UDim2.fromOffset(16, UserInputService.TouchEnabled and 307 or 299)
eatHint.Size = UDim2.fromOffset(230, 26)
eatHint.BackgroundTransparency = 1
eatHint.Text = "Uses the best meal in your backpack"
eatHint.TextColor3 = Color3.fromRGB(188, 188, 196)
eatHint.Font = Enum.Font.Gotham
eatHint.TextSize = 9
eatHint.TextXAlignment = Enum.TextXAlignment.Left
eatHint.Parent = gui

local foodPriority = {
	"CookedBeef",
	"TrailRation",
	"BoneBroth",
	"CookedMeat",
	"HerbalTea",
}

local function bestFoodSlot()
	for _, wanted in foodPriority do
		for index = 1, 10 do
			local slot = inventory[index]
			if slot and slot.Item == wanted and (slot.Amount or 0) > 0 then return index, wanted end
		end
	end
	for index = 1, 10 do
		local slot = inventory[index]
		local data = slot and SurvivalItemData.Items[slot.Item]
		if data and (data.Use == "Food" or data.Use == "Meal") then return index, slot.Item end
	end
	return nil, nil
end

local function refresh()
	local _, itemName = bestFoodSlot()
	if itemName then
		local data = SurvivalItemData.Items[itemName]
		eatButton.Text = `EAT: {string.upper(data and data.Label or itemName)}`
		eatButton.BackgroundColor3 = Color3.fromRGB(65, 104, 67)
	else
		eatButton.Text = "EAT FOOD"
		eatButton.BackgroundColor3 = Color3.fromRGB(61, 61, 66)
	end
end

eatButton.Activated:Connect(function()
	local slot = bestFoodSlot()
	if slot then
		survivalAction:FireServer("UseSlot", slot)
	else
		eatHint.Text = "No prepared food in your 10-slot backpack"
		task.delay(2, function()
			if eatHint.Parent then eatHint.Text = "Uses the best meal in your backpack" end
		end)
	end
end)

survivalState.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Inventory) == "table" then
		inventory = payload.Inventory
		refresh()
	end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getSurvivalState:InvokeServer() end)
	if ok and type(initial) == "table" and type(initial.Inventory) == "table" then
		inventory = initial.Inventory
	end
	refresh()
end)
