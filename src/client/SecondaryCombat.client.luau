local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local secondaryFire = remotes:WaitForChild("SecondaryFire")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")

local selectedItem = nil

local function selectedData()
	return selectedItem and ItemData.Items[selectedItem] or nil
end

local function isRangedSelected()
	local item = selectedData()
	return item ~= nil and item.Ranged == true
end

local function suppressMeleeSwing()
	local item = selectedData()
	return item and (item.Ranged == true or item.Kind == "Shield" or item.CanAttack == false)
end

local function fireAtMouse()
	if not isRangedSelected() then return end
	local hit = mouse.Hit
	if not hit then return end
	secondaryFire:FireServer(hit.Position)
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.SelectedItem) == "string" then
		selectedItem = payload.SelectedItem
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then fireAtMouse() end
end)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "LocalSwing" and suppressMeleeSwing() then
		task.defer(function()
			if child.Parent then child:Destroy() end
		end)
	end
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then selectedItem = initial.SelectedItem end
end)
