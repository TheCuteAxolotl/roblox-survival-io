local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ClanDoorHUD")

gui.DisplayOrder = 95
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = nil
local openButton = nil
for _, child in gui:GetChildren() do
	if child:IsA("TextButton") and child.Text == "CLAN / BASE" then
		openButton = child
	elseif child:IsA("Frame") then
		for _, descendant in child:GetDescendants() do
			if descendant:IsA("TextLabel") and descendant.Text == "CLAN + BASE ACCESS" then
				panel = child
				break
			end
		end
	end
end

if not panel then
	warn("[ClanPanelPriority] Clan panel not found.")
	return
end

local blocker = Instance.new("TextButton")
blocker.Name = "ClanModalBlocker"
blocker.Size = UDim2.fromScale(1, 1)
blocker.Position = UDim2.fromScale(0, 0)
blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blocker.BackgroundTransparency = 0.72
blocker.Text = ""
blocker.AutoButtonColor = false
blocker.Visible = false
blocker.ZIndex = 40
blocker.Parent = gui

panel.ZIndex = 50
for _, descendant in panel:GetDescendants() do
	if descendant:IsA("GuiObject") then descendant.ZIndex = math.max(descendant.ZIndex, 51) end
end
if openButton then openButton.ZIndex = 60 end

local function sync()
	blocker.Visible = panel.Visible
end

panel:GetPropertyChangedSignal("Visible"):Connect(sync)
blocker.Activated:Connect(function()
	panel.Visible = false
end)
sync()
