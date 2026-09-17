local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local openTrade = remotes:WaitForChild("OpenVillageTrade")
local tradeAction = remotes:WaitForChild("VillageTrade")
local tradeResult = remotes:WaitForChild("VillageTradeResult")

local currentVillager = nil

local gui = Instance.new("ScreenGui")
gui.Name = "VillageTradeHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UserInputService.TouchEnabled and UDim2.new(1, -28, 0, 360) or UDim2.fromOffset(410, 360)
panel.BackgroundColor3 = Color3.fromRGB(23, 23, 27)
panel.Visible = false
panel.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(410, 360)
limit.MinSize = Vector2.new(300, 330)
limit.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -70, 0, 32)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 10)
close.Size = UDim2.fromOffset(38, 36)
close.Text = "×"
close.BackgroundColor3 = Color3.fromRGB(49, 49, 54)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 22
close.Parent = panel
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = close

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(16, 52)
status.Size = UDim2.new(1, -32, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(188, 188, 196)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local list = Instance.new("Frame")
list.Position = UDim2.fromOffset(16, 96)
list.Size = UDim2.new(1, -32, 1, -112)
list.BackgroundTransparency = 1
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = list

local function rebuild(role, trades)
	for _, child in list:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
	title.Text = string.upper(role) .. " TRADER"
	status.TextColor3 = Color3.fromRGB(188, 188, 196)
	status.Text = "Trade gold or survival materials. All trades are server-checked."
	for index, trade in ipairs(trades or {}) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 58)
		b.BackgroundColor3 = Color3.fromRGB(38, 38, 43)
		b.TextColor3 = Color3.fromRGB(245, 245, 245)
		b.Text = trade.Label
		b.TextWrapped = true
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.Parent = list
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = b
		b.Activated:Connect(function()
			if currentVillager then
				status.Text = "Trading..."
				tradeAction:FireServer(currentVillager, index)
			end
		end)
	end
end

close.Activated:Connect(function() panel.Visible = false currentVillager = nil end)

openTrade.OnClientEvent:Connect(function(villager, role, trades)
	currentVillager = villager
	rebuild(role, trades)
	panel.Visible = true
end)

tradeResult.OnClientEvent:Connect(function(ok, message)
	status.Text = message or (ok and "Trade complete." or "Trade failed.")
	status.TextColor3 = ok and Color3.fromRGB(150, 235, 158) or Color3.fromRGB(245, 150, 150)
end)
