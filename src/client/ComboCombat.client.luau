local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local comboAttack = remotes:WaitForChild("ComboAttack")

-- Intentionally undocumented secret mechanic.
local lastOne = 0
local comboReadyUntil = 0
local SEQUENCE_WINDOW = 0.65
local READY_WINDOW = 1.4

local function aimPosition()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local mouse = player:GetMouse()
	local ok, hit = pcall(function() return mouse.Hit end)
	if ok and hit then return hit.Position end
	return root.Position + root.CFrame.LookVector * 100
end

local function overInteractiveUI()
	local mouse = player:GetMouse()
	for _, object in playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y) do
		if object.Visible and (object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("TextBox")) then
			return true
		end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.One then
		lastOne = os.clock()
	elseif input.KeyCode == Enum.KeyCode.Two and os.clock() - lastOne <= SEQUENCE_WINDOW then
		comboReadyUntil = os.clock() + READY_WINDOW
	end
end)

local function comboClick(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if os.clock() > comboReadyUntil or overInteractiveUI() then return Enum.ContextActionResult.Pass end
	local aim = aimPosition()
	if not aim then return Enum.ContextActionResult.Pass end
	comboReadyUntil = 0
	comboAttack:FireServer(aim)
	return Enum.ContextActionResult.Sink
end

-- No hint, icon, tooltip, tutorial, or mobile combo button is created here.
ContextActionService:BindActionAtPriority(
	"WildforgeComboClick",
	comboClick,
	false,
	5200,
	Enum.UserInputType.MouseButton1
)
