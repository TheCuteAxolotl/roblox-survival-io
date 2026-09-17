local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local comboAttack = remotes:WaitForChild("ComboAttack")

local lastOne = 0
local comboReadyUntil = 0
local SEQUENCE_WINDOW = 0.65
local READY_WINDOW = 1.4

local gui = Instance.new("ScreenGui")
gui.Name = "ComboCombatHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 44
gui.Parent = playerGui

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -92)
hint.Size = UDim2.fromOffset(260, 30)
hint.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
hint.BackgroundTransparency = 0.15
hint.TextColor3 = Color3.fromRGB(235, 221, 126)
hint.Font = Enum.Font.GothamBold
hint.TextSize = 11
hint.Text = "1 → 2 quickly, then click: COMBO"
hint.Visible = not UserInputService.TouchEnabled
hint.Parent = gui
local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(0, 9) hc.Parent = hint

local mobile = Instance.new("TextButton")
mobile.AnchorPoint = Vector2.new(1, 1)
mobile.Position = UDim2.new(1, -220, 1, -175)
mobile.Size = UDim2.fromOffset(84, 52)
mobile.BackgroundColor3 = Color3.fromRGB(82, 60, 112)
mobile.TextColor3 = Color3.new(1, 1, 1)
mobile.Font = Enum.Font.GothamBold
mobile.TextSize = 12
mobile.Text = "COMBO"
mobile.Visible = UserInputService.TouchEnabled
mobile.Parent = gui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 14) mc.Parent = mobile

local function aimPosition()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if UserInputService.TouchEnabled then return root.Position + root.CFrame.LookVector * 100 end
	local mouse = player:GetMouse()
	local ok, hit = pcall(function() return mouse.Hit end)
	if ok and hit then return hit.Position end
	return root.Position + root.CFrame.LookVector * 100
end

local function overInteractiveUI()
	local mouse = player:GetMouse()
	for _, object in playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y) do
		if object.Visible and (object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("TextBox")) then return true end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.One then
		lastOne = os.clock()
	elseif input.KeyCode == Enum.KeyCode.Two and os.clock() - lastOne <= SEQUENCE_WINDOW then
		comboReadyUntil = os.clock() + READY_WINDOW
		hint.Text = "COMBO READY — CLICK!"
		hint.BackgroundColor3 = Color3.fromRGB(74, 93, 60)
		task.delay(READY_WINDOW, function()
			if os.clock() >= comboReadyUntil then
				hint.Text = "1 → 2 quickly, then click: COMBO"
				hint.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			end
		end)
	end
end)

local function comboClick(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if os.clock() > comboReadyUntil or overInteractiveUI() then return Enum.ContextActionResult.Pass end
	local aim = aimPosition()
	if not aim then return Enum.ContextActionResult.Pass end
	comboReadyUntil = 0
	hint.Text = "COMBO!"
	comboAttack:FireServer(aim)
	task.delay(0.45, function() if hint.Parent then hint.Text = "1 → 2 quickly, then click: COMBO" hint.BackgroundColor3 = Color3.fromRGB(30, 30, 35) end end)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority("WildforgeComboClick", comboClick, false, 5200, Enum.UserInputType.MouseButton1)

mobile.Activated:Connect(function()
	local aim = aimPosition()
	if aim then comboAttack:FireServer(aim) end
end)
