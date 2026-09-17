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
local currentBuildCounts = {}
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

local function ensureCampfireStroke(button)
	local existing = button:FindFirstChild("StarterCampfireStroke")
	if existing and existing:IsA("UIStroke") then return existing end
	local stroke = Instance.new("UIStroke")
	stroke.Name = "StarterCampfireStroke"
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 178, 82)
	stroke.Transparency = 1
	stroke.Parent = button
	return stroke
end

local function styleButtons()
	local needsFirstCampfire = (currentBuildCounts.Campfire or 0) < 1
	for _, child in hotbar:GetChildren() do
		if child:IsA("TextButton") then
			local active = child.Name == selectedItem
			local campfireCallout = child.Name == "Campfire" and needsFirstCampfire
			local campfireStroke = ensureCampfireStroke(child)

			if active then
				child.BackgroundTransparency = 0.06
				child.BackgroundColor3 = Color3.fromRGB(238, 238, 241)
				child.TextColor3 = Color3.fromRGB(20, 20, 22)
				campfireStroke.Transparency = campfireCallout and 0.1 or 1
			elseif campfireCallout then
				child.BackgroundTransparency = 0.08
				child.BackgroundColor3 = Color3.fromRGB(116, 67, 31)
				child.TextColor3 = Color3.fromRGB(255, 238, 206)
				campfireStroke.Transparency = 0.08
			else
				child.BackgroundTransparency = 0.28
				child.BackgroundColor3 = Color3.fromRGB(37, 37, 42)
				child.TextColor3 = Color3.fromRGB(245, 245, 245)
				campfireStroke.Transparency = 1
			end
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
				button.Size = UDim2.fromOffset(
					itemName == "Campfire" and (UserInputService.TouchEnabled and 96 or 106) or (UserInputService.TouchEnabled and 78 or 84),
					40
				)
				button.BackgroundColor3 = Color3.fromRGB(37, 37, 42)
				button.BackgroundTransparency = 0.28
				button.TextColor3 = Color3.fromRGB(245, 245, 245)
				button.TextWrapped = true
				button.Font = Enum.Font.GothamBold
				button.TextSize = itemName == "Campfire" and (UserInputService.TouchEnabled and 8 or 9) or (UserInputService.TouchEnabled and 9 or 10)
				if itemName == "Campfire" then
					button.Text = `{slot}  CAMPFIRE\n14W + 8S`
				else
					button.Text = slot <= 9 and `{slot}  {string.upper(item.Label)}` or string.upper(item.Label)
				end
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
	if type(payload.BuildCounts) == "table" then currentBuildCounts = payload.BuildCounts end
	if type(payload.SelectedItem) == "string" then selectedItem = payload.SelectedItem end
	-- Re-apply after the legacy controller has had a chance to update the same bar.
	task.defer(rebuild)
	task.delay(0.06, rebuild)
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		currentProfile = initial.Profile
		currentBuildCounts = type(initial.BuildCounts) == "table" and initial.BuildCounts or {}
		selectedItem = initial.SelectedItem
		task.wait(0.12)
		rebuild()
	end
end)
