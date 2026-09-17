local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function refreshTargetFilter()
	-- Ignore only our own character. Never filter Workspace itself, because that
	-- prevents Mouse.Hit from resolving the world the player is aiming at.
	mouse.TargetFilter = player.Character
end

local function combatClick(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local item = selectedData()
	if not item then return Enum.ContextActionResult.Pass end

	if item.Ranged == true then
		local hit = mouse.Hit
		if hit then secondaryFire:FireServer(hit.Position) end
		-- Consume the click so GameController cannot also send a melee/gather action.
		return Enum.ContextActionResult.Sink
	end

	if item.Kind == "Shield" or item.CanAttack == false then
		-- Holding a shield/non-attacking secondary should not create a fake melee swing.
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority(
	"SurvivalSecondaryCombatClick",
	combatClick,
	false,
	3500,
	Enum.UserInputType.MouseButton1
)

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.SelectedItem) == "string" then
		selectedItem = payload.SelectedItem
		refreshTargetFilter()
	end
end)

player.CharacterAdded:Connect(function(character)
	task.wait(0.15)
	mouse.TargetFilter = character
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		selectedItem = initial.SelectedItem
		refreshTargetFilter()
	end
end)
