local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")

local selectedItem = nil

local function clearWeaponParts(character)
	if not character then return end
	for _, child in character:GetChildren() do
		if child.Name == "LocalWeaponHandle" or child.Name == "LocalWeaponHead" then
			child:Destroy()
		end
	end
end

local function applyWeaponVisual(itemName)
	selectedItem = itemName
	local character = player.Character
	if not character then return end
	clearWeaponParts(character)

	local item = ItemData.Items[itemName]
	if not item or item.Category ~= "Weapon" then return end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end

	local handle = Instance.new("Part")
	handle.Name = "LocalWeaponHandle"
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(108, 76, 48)
	handle.Size = Vector3.new(0.25, 2.5, 0.25)
	if item.Visual == "Spear" then handle.Size = Vector3.new(0.22, 4.8, 0.22) end
	handle.CFrame = hand.CFrame * CFrame.new(0, -1.05, -0.35) * CFrame.Angles(math.rad(18), 0, math.rad(-14))
	handle.Parent = character

	local head = Instance.new("Part")
	head.Name = "LocalWeaponHead"
	head.CanCollide = false
	head.CanQuery = false
	head.Massless = true
	head.Material = Enum.Material.Metal
	head.Color = Color3.fromRGB(118, 122, 130)

	if item.Visual == "Sword" or item.Visual == "Katana" then
		handle.Size = Vector3.new(0.3, 1.15, 0.3)
		head.Size = item.Visual == "Katana" and Vector3.new(0.22, 4, 0.38) or Vector3.new(0.32, 3.2, 0.42)
		head.CFrame = handle.CFrame * CFrame.new(0, 2, 0)
	elseif item.Visual == "Pickaxe" then
		head.Size = Vector3.new(2.6, 0.45, 0.42)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.08, 0)
	elseif item.Visual == "Hammer" then
		head.Size = Vector3.new(2.2, 1.05, 1.05)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.1, 0)
	elseif item.Visual == "Spear" then
		head.Size = Vector3.new(0.55, 1.5, 0.55)
		head.CFrame = handle.CFrame * CFrame.new(0, 3, 0)
	elseif item.Visual == "BattleAxe" then
		head.Size = Vector3.new(2.2, 1.35, 0.5)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.15, 0)
	else
		head.Size = Vector3.new(1.35, 0.75, 0.38)
		head.CFrame = handle.CFrame * CFrame.new(0, 1.05, 0)
	end
	head.Parent = character

	local handleWeld = Instance.new("WeldConstraint")
	handleWeld.Part0 = hand
	handleWeld.Part1 = handle
	handleWeld.Parent = handle

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = handle
	headWeld.Part1 = head
	headWeld.Parent = head
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" or type(payload.SelectedItem) ~= "string" then return end
	if payload.SelectedItem ~= selectedItem then
		applyWeaponVisual(payload.SelectedItem)
	end
end)

player.CharacterAdded:Connect(function(character)
	task.wait(0.4)
	if selectedItem then applyWeaponVisual(selectedItem) end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" and type(initial.SelectedItem) == "string" then
		applyWeaponVisual(initial.SelectedItem)
	end
end)
