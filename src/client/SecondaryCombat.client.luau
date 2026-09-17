local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
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

local function pointerOverInteractiveGui()
	local objects = GuiService:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	for _, object in objects do
		if (object:IsA("TextButton") or object:IsA("ImageButton")) and object.Visible and object.Active then
			return true
		end
	end
	return false
end

local function combatClick(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local item = selectedData()
	if not item then return Enum.ContextActionResult.Pass end

	if item.Ranged == true then
		-- Consume UI clicks too, but never turn them into a shot.
		if not pointerOverInteractiveGui() then
			local hit = mouse.Hit
			if hit then secondaryFire:FireServer(hit.Position) end
		end
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
