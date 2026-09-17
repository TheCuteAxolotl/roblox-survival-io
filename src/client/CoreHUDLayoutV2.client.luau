local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SurvivalHUD", 15)
if not hud then return end

local function isLegacyStatus(object)
	if not object:IsA("TextLabel") or object.Parent ~= hud then return false end
	if object.AnchorPoint.X < 0.49 or object.AnchorPoint.X > 0.51 then return false end
	return object.Size.X.Offset >= 480 and object.Size.Y.Offset >= 34 and object.Position.Y.Offset <= 30
end

local function styleStatus(label)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -158)
	label.Size = UDim2.fromOffset(410, 30)
	label.BackgroundTransparency = 0.38
	label.TextSize = 11
	label.TextWrapped = true
	label.ZIndex = 35
end

local function apply(object)
	if isLegacyStatus(object) then styleStatus(object) end
end

for _, child in hud:GetChildren() do apply(child) end
hud.ChildAdded:Connect(function(child)
	task.defer(apply, child)
end)

-- Some legacy code can rewrite position properties during initialization.
task.spawn(function()
	for _ = 1, 50 do
		for _, child in hud:GetChildren() do apply(child) end
		task.wait(0.1)
	end
end)
