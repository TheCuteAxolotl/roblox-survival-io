local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local dodge = remotes:WaitForChild("Dodge")

local gui = Instance.new("ScreenGui")
gui.Name = "DodgeHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 43
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -132, 1, -235)
button.Size = UDim2.fromOffset(78, 50)
button.BackgroundColor3 = Color3.fromRGB(43, 62, 76)
button.TextColor3 = Color3.fromRGB(242, 248, 252)
button.Text = "DODGE"
button.Font = Enum.Font.GothamBold
button.TextSize = 11
button.Visible = UserInputService.TouchEnabled
button.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = button
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(218, 238, 248)
stroke.Transparency = 0.7
stroke.Parent = button

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -116)
hint.Size = UDim2.fromOffset(180, 24)
hint.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
hint.BackgroundTransparency = 0.35
hint.Text = "SPACE  •  DODGE"
hint.TextColor3 = Color3.fromRGB(190, 216, 232)
hint.Font = Enum.Font.GothamBold
hint.TextSize = 9
hint.Visible = not UserInputService.TouchEnabled
hint.Parent = gui
local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 8)
hintCorner.Parent = hint
task.delay(12, function()
	if hint.Parent then TweenService:Create(hint, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play() end
end)

local readyAt = 0

local function characterParts()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	return root, hum
end

local function direction()
	local root, hum = characterParts()
	if not root or not hum then return nil end
	local move = hum.MoveDirection
	if move.Magnitude >= 0.15 then return move.Unit end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	return look.Magnitude > 0.1 and look.Unit or nil
end

local function requestDodge()
	if workspace:GetServerTimeNow() < readyAt then return end
	local root, hum = characterParts()
	if not root or not hum or hum.Health <= 0 then return end
	local dir = direction()
	if dir then dodge:FireServer(dir) end
end

local function ringFx()
	local root = characterParts()
	if not root then return end
	local ring = Instance.new("Part")
	ring.Name = "LocalDodgeRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 5.5, 5.5)
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(164, 218, 240)
	ring.Transparency = 0.46
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.28), { Size = Vector3.new(0.18, 9, 9), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.32)
end

local function updateButton()
	if not button.Visible then return end
	local remaining = math.max(0, readyAt - workspace:GetServerTimeNow())
	button.Text = remaining > 0 and string.format("DODGE\n%.1f", remaining) or "DODGE"
	button.BackgroundTransparency = remaining > 0 and 0.38 or 0.08
end

button.Activated:Connect(requestDodge)

ContextActionService:BindActionAtPriority(
	"WildforgeDodge",
	function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		requestDodge()
		return Enum.ContextActionResult.Sink
	end,
	false,
	4500,
	Enum.KeyCode.Space
)

dodge.OnClientEvent:Connect(function(cooldown)
	readyAt = workspace:GetServerTimeNow() + (tonumber(cooldown) or 2.15)
	ringFx()
end)

task.spawn(function()
	while gui.Parent do
		updateButton()
		task.wait(0.08)
	end
end)
