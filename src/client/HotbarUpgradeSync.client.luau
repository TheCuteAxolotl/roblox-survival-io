local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SurvivalHUD")
local hotbar = gui:WaitForChild("Hotbar")

local currentProfile = nil
local selectedItem = nil

local primaryNames = {
	Axe = true, Sword = true, Pickaxe = true, Spear = true, Daggers = true,
	Bat = true, Stick = true, Katana = true, BattleAxe = true,
}

local secondaryNames = {
	WoodenShield = true, StoneShield = true, HuntingBow = true, GreatHammer = true,
	McGrabby = true, Shotgun = true, RepeaterCrossbow = true, Musket = true,
}

local millNames = { Windmill = true, RapidMill = true, PowerMill = true }

local primaryPriority = { "Katana", "BattleAxe", "Sword", "Pickaxe", "Spear", "Daggers", "Bat", "Stick", "Axe" }
local secondaryPriority = { "Musket", "Shotgun", "RepeaterCrossbow", "WoodenShield", "StoneShield", "HuntingBow", "GreatHammer", "McGrabby" }
local millPriority = { "RapidMill", "PowerMill", "Windmill" }

local function firstUnlocked(unlocks, priority)
	for _, itemName in priority do
		if unlocks[itemName] == true then return itemName end
	end
	return nil
end

local function findGroupButton(group)
	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") and group[child.Name] then return child end
	end
	return nil
end

local function labelButton(button, itemName)
	local item = ItemData.Items[itemName]
	if not item then return end
	local slot = math.max(1, button.LayoutOrder)
	button.Name = itemName
	button.Text = slot <= 9 and `{slot}  {string.upper(item.Label)}` or string.upper(item.Label)
end

local function wireReplacementButton(button, targetItem)
	button:SetAttribute("ProgressionSelectTarget", targetItem)
	if button:GetAttribute("ProgressionReplacementWired") then return end
	button:SetAttribute("ProgressionReplacementWired", true)
	button.Activated:Connect(function()
		local target = button:GetAttribute("ProgressionSelectTarget")
		if type(target) == "string" then action:FireServer("SelectItem", target) end
	end)
end

local function syncGroup(group, priority)
	if not currentProfile or type(currentProfile.Unlocks) ~= "table" then return nil end
	local activeItem = firstUnlocked(currentProfile.Unlocks, priority)
	if not activeItem then return nil end
	local button = findGroupButton(group)
	if not button then return activeItem end
	wireReplacementButton(button, activeItem)
	if button.Name ~= activeItem then labelButton(button, activeItem) end
	return activeItem
end

local function styleSelection()
	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") then
			local active = child.Name == selectedItem
			child.BackgroundColor3 = active and Color3.fromRGB(238, 238, 241) or Color3.fromRGB(42, 42, 46)
			child.TextColor3 = active and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(245, 245, 245)
		end
	end
end

local function syncHotbar()
	if not currentProfile or type(currentProfile.Unlocks) ~= "table" then return end
	local activePrimary = syncGroup(primaryNames, primaryPriority)
	local activeSecondary = syncGroup(secondaryNames, secondaryPriority)
	local activeMill = syncGroup(millNames, millPriority)

	if selectedItem and primaryNames[selectedItem] and currentProfile.Unlocks[selectedItem] ~= true and activePrimary then
		action:FireServer("SelectItem", activePrimary)
	elseif selectedItem and secondaryNames[selectedItem] and currentProfile.Unlocks[selectedItem] ~= true and activeSecondary then
		action:FireServer("SelectItem", activeSecondary)
	elseif selectedItem and millNames[selectedItem] and currentProfile.Unlocks[selectedItem] ~= true and activeMill then
		action:FireServer("SelectItem", activeMill)
	end

	task.defer(styleSelection)
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Profile) == "table" then currentProfile = payload.Profile end
	if type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
	task.defer(syncHotbar)
end)

hotbar.ChildAdded:Connect(function()
	task.defer(syncHotbar)
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		currentProfile = initial.Profile
		selectedItem = initial.SelectedItem
		task.wait(0.1)
		syncHotbar()
	end
end)
