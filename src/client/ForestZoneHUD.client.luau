local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ForestZoneHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 37
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 72)
banner.Size = UDim2.fromOffset(460, 48)
banner.BackgroundColor3 = Color3.fromRGB(21, 31, 23)
banner.BackgroundTransparency = 0.12
banner.TextColor3 = Color3.fromRGB(226, 236, 214)
banner.Font = Enum.Font.GothamBold
banner.TextSize = 12
banner.TextWrapped = true
banner.Visible = false
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = banner
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(157, 189, 147)
stroke.Transparency = 0.65
stroke.Parent = banner

local inside = false
local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.2 then return end
	accumulator = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then banner.Visible = false return end
	local nowInside = math.abs(root.Position.X) <= 165 and root.Position.Z >= 220 and root.Position.Z <= 510
	if not nowInside then
		inside = false
		banner.Visible = false
		return
	end
	inside = true
	local hour = Lighting.ClockTime
	local night = hour >= 19 or hour < 6
	banner.Text = night
		and "BLACKWOOD FOREST • HIGH DANGER\nNightfall: brood spiders are hunting. Rare forest loot drops here."
		or "BLACKWOOD FOREST • HIGH DANGER\nDire Wolves and Blackwood Bears roam here. Spiders become hostile at night."
	banner.Visible = true
end)
