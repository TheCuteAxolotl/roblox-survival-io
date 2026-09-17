local ContextActionService = game:GetService("ContextActionService")
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
local orderedUnlocks = {}
local lastSignature = nil

local function unlockSignature(profile)
	if not profile or type(profile.Unlocks) ~= "table" then return "" end
	local parts = {}
	for _, itemName in ItemData.HotbarOrder do
		if profile.Unlocks[itemName] == true then table.insert(parts, itemName) end
	end
	return table.concat(parts, "|")
end

local function styleButtons()
	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") then
			local active = child.Name == selectedItem
			child.BackgroundColor3 = active and Color3.fromRGB(238, 238, 241) or Color3.fromRGB(42, 42, 46)
			child.TextColor3 = active and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(245, 245, 245)
		end
	end
end

local function rebuild()
	if not currentProfile or type(currentProfile.Unlocks) ~= "table" then return end
	local signature = unlockSignature(currentProfile)
	if signature == lastSignature then
		styleButtons()
		return
	end
	lastSignature = signature

	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	orderedUnlocks = {}

	for _, itemName in ItemData.HotbarOrder do
		if currentProfile.Unlocks[itemName] == true then
			local item = ItemData.Items[itemName]
			if item then
				table.insert(orderedUnlocks, itemName)
				local slot = #orderedUnlocks
				local button = Instance.new("TextButton")
				button.Name = itemName
				button.LayoutOrder = slot
				button.Size = UDim2.fromOffset(112, 56)
				button.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
				button.TextColor3 = Color3.fromRGB(245, 245, 245)
				button.TextWrapped = true
				button.Font = Enum.Font.GothamBold
				button.TextSize = 12
				button.Text = slot <= 9 and `{slot}  {string.upper(item.Label)}` or string.upper(item.Label)
				button.Parent = hotbar
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 10)
				corner.Parent = button
				button.Activated:Connect(function()
					action:FireServer("SelectItem", itemName)
				end)
			end
		end
	end
	styleButtons()
end

local numberKeyNames = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
}

local function hotbarKeyAction(_, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	for index, key in numberKeyNames do
		if inputObject.KeyCode == key then
			local itemName = orderedUnlocks[index]
			if itemName then action:FireServer("SelectItem", itemName) end
			break
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"SurvivalHotbarNumbers",
	hotbarKeyAction,
	false,
	3000,
	table.unpack(numberKeyNames)
)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Profile) == "table" then currentProfile = payload.Profile end
	if type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
	task.defer(rebuild)
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		currentProfile = initial.Profile
		selectedItem = initial.SelectedItem
		task.wait(0.12)
		rebuild()
	end
end)
