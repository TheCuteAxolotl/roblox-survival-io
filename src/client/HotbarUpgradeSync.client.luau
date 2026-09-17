local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

-- Compact, translucent tool strip. Inventory quick slots live directly above it.
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -8)
hotbar.Size = UserInputService.TouchEnabled and UDim2.new(0.74, 0, 0, 52) or UDim2.new(0.62, 0, 0, 52)
hotbar.BackgroundTransparency = 0.82
hotbar.ScrollBarThickness = 2
local sizeConstraint = hotbar:FindFirstChildOfClass("UISizeConstraint")
if sizeConstraint then
	sizeConstraint.MinSize = Vector2.new(0, 0)
	sizeConstraint.MaxSize = Vector2.new(760, 52)
end
local padding = hotbar:FindFirstChildOfClass("UIPadding")
if padding then
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
end
local layout = hotbar:FindFirstChildOfClass("UIListLayout")
if layout then layout.Padding = UDim.new(0, 5) end

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
			child.BackgroundTransparency = active and 0.08 or 0.28
			child.BackgroundColor3 = active and Color3.fromRGB(238, 238, 241) or Color3.fromRGB(37, 37, 42)
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
				button.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 78 or 84, 40)
				button.BackgroundColor3 = Color3.fromRGB(37, 37, 42)
				button.BackgroundTransparency = 0.28
				button.TextColor3 = Color3.fromRGB(245, 245, 245)
				button.TextWrapped = true
				button.Font = Enum.Font.GothamBold
				button.TextSize = UserInputService.TouchEnabled and 9 or 10
				button.Text = slot <= 9 and `{slot}  {string.upper(item.Label)}` or string.upper(item.Label)
				button.Parent = hotbar
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
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
