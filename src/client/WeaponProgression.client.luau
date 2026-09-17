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
		if string.sub(child.Name, 1, 11) == "LocalWeapon" then child:Destroy() end
	end
end

local function newPart(character, hand, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = `LocalWeapon{name}`
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = hand.CFrame * offset
	part.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = part
	weld.Parent = part
	return part
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

	local wood = Color3.fromRGB(108, 76, 48)
	local metal = Color3.fromRGB(118, 122, 130)
	local visual = item.Visual

	if visual == "Sword" or visual == "Katana" then
		newPart(character, hand, "Grip", Vector3.new(0.3, 1.05, 0.3), CFrame.new(0, -0.72, -0.25) * CFrame.Angles(math.rad(18), 0, math.rad(-12)), wood, Enum.Material.Wood)
		local length = visual == "Katana" and 4.1 or 3.2
		newPart(character, hand, "Blade", Vector3.new(0.24, length, 0.38), CFrame.new(0, 1.35, -0.25) * CFrame.Angles(math.rad(18), 0, math.rad(-12)), metal, Enum.Material.Metal)
	elseif visual == "Pickaxe" then
		newPart(character, hand, "Handle", Vector3.new(0.28, 2.7, 0.28), CFrame.new(0, -0.75, -0.3) * CFrame.Angles(math.rad(18), 0, math.rad(-12)), wood, Enum.Material.Wood)
		newPart(character, hand, "Head", Vector3.new(2.7, 0.42, 0.42), CFrame.new(0, 0.62, -0.3) * CFrame.Angles(math.rad(18), 0, math.rad(-12)), metal, Enum.Material.Metal)
	elseif visual == "Hammer" or visual == "GreatHammer" then
		local big = visual == "GreatHammer"
		newPart(character, hand, "Handle", Vector3.new(0.34, big and 3.4 or 2.6, 0.34), CFrame.new(0, -0.9, -0.3) * CFrame.Angles(math.rad(16), 0, math.rad(-12)), wood, Enum.Material.Wood)
		newPart(character, hand, "Head", big and Vector3.new(3.1, 1.45, 1.35) or Vector3.new(2.1, 1, 1), CFrame.new(0, big and 0.95 or 0.6, -0.3), metal, Enum.Material.Metal)
	elseif visual == "Spear" then
		newPart(character, hand, "Shaft", Vector3.new(0.22, 5.2, 0.22), CFrame.new(0, 0.1, -0.35) * CFrame.Angles(math.rad(12), 0, math.rad(-10)), wood, Enum.Material.Wood)
		newPart(character, hand, "Tip", Vector3.new(0.55, 1.4, 0.55), CFrame.new(0, 3.05, -0.35), metal, Enum.Material.Metal)
	elseif visual == "Daggers" then
		newPart(character, hand, "DaggerA", Vector3.new(0.22, 2.0, 0.36), CFrame.new(-0.18, 0.25, -0.45) * CFrame.Angles(math.rad(15), 0, math.rad(-20)), metal, Enum.Material.Metal)
		newPart(character, hand, "DaggerB", Vector3.new(0.22, 2.0, 0.36), CFrame.new(0.35, 0.18, -0.35) * CFrame.Angles(math.rad(15), 0, math.rad(20)), metal, Enum.Material.Metal)
	elseif visual == "Bat" then
		newPart(character, hand, "Bat", Vector3.new(0.75, 3.8, 0.75), CFrame.new(0, 0.25, -0.35) * CFrame.Angles(math.rad(15), 0, math.rad(-15)), Color3.fromRGB(128, 87, 51), Enum.Material.Wood)
	elseif visual == "Stick" then
		newPart(character, hand, "Stick", Vector3.new(0.32, 3.4, 0.32), CFrame.new(0, 0.1, -0.3) * CFrame.Angles(math.rad(18), 0, math.rad(-12)), Color3.fromRGB(132, 92, 55), Enum.Material.Wood)
	elseif visual == "BattleAxe" then
		newPart(character, hand, "Handle", Vector3.new(0.34, 3.2, 0.34), CFrame.new(0, -0.45, -0.3), wood, Enum.Material.Wood)
		newPart(character, hand, "Head", Vector3.new(2.8, 1.5, 0.5), CFrame.new(0, 1.45, -0.3), metal, Enum.Material.Metal)
	elseif visual == "WoodShield" or visual == "StoneShield" then
		local color = visual == "WoodShield" and Color3.fromRGB(132, 91, 55) or Color3.fromRGB(112, 116, 124)
		local mat = visual == "WoodShield" and Enum.Material.WoodPlanks or Enum.Material.Slate
		newPart(character, hand, "Shield", Vector3.new(3.4, 4.1, 0.5), CFrame.new(0.65, 0.2, -1.0) * CFrame.Angles(0, math.rad(12), math.rad(-8)), color, mat)
	elseif visual == "Bow" or visual == "Crossbow" then
		newPart(character, hand, "BowBody", Vector3.new(0.35, 3.5, 0.35), CFrame.new(0, 0.25, -0.75), Color3.fromRGB(122, 83, 48), Enum.Material.Wood)
		if visual == "Crossbow" then newPart(character, hand, "Crossbar", Vector3.new(3.2, 0.28, 0.28), CFrame.new(0, 0.55, -0.85), metal, Enum.Material.Metal) end
	elseif visual == "Shotgun" or visual == "Musket" then
		local length = visual == "Musket" and 5.1 or 3.8
		newPart(character, hand, "Stock", Vector3.new(0.75, 0.75, 1.7), CFrame.new(0, -0.35, 0.35), wood, Enum.Material.Wood)
		newPart(character, hand, "Barrel", Vector3.new(0.38, 0.38, length), CFrame.new(0, 0, -1.6), metal, Enum.Material.Metal)
	elseif visual == "Grabby" then
		newPart(character, hand, "Arm", Vector3.new(0.45, 3.8, 0.45), CFrame.new(0, 0.3, -0.45), Color3.fromRGB(192, 142, 102), Enum.Material.SmoothPlastic)
		newPart(character, hand, "Hand", Vector3.new(2.1, 1.6, 0.7), CFrame.new(0, 2.0, -0.45), Color3.fromRGB(225, 178, 135), Enum.Material.SmoothPlastic)
	else
		newPart(character, hand, "Handle", Vector3.new(0.28, 2.5, 0.28), CFrame.new(0, -0.7, -0.35), wood, Enum.Material.Wood)
		newPart(character, hand, "Head", Vector3.new(1.4, 0.8, 0.5), CFrame.new(0, 0.75, -0.35), metal, Enum.Material.Metal)
	end
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" or type(payload.SelectedItem) ~= "string" then return end
	if payload.SelectedItem ~= selectedItem then applyWeaponVisual(payload.SelectedItem) end
end)

player.CharacterAdded:Connect(function()
	task.wait(0.4)
	if selectedItem then applyWeaponVisual(selectedItem) end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" and type(initial.SelectedItem) == "string" then applyWeaponVisual(initial.SelectedItem) end
end)
