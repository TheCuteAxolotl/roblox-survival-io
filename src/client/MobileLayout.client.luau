local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function centerPanel(panel, widthScale, heightScale)
	if not panel or not panel:IsA("GuiObject") then return end
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(widthScale, 0, heightScale, 0)
end

local function tuneSurvivalSystems()
	local gui = playerGui:WaitForChild("SurvivalSystemsHUD", 12)
	if not gui then return end
	centerPanel(gui:FindFirstChild("BagPanel"), 0.92, 0.72)
	centerPanel(gui:FindFirstChild("CraftPanel"), 0.94, 0.78)
	centerPanel(gui:FindFirstChild("KitsPanel"), 0.92, 0.72)
	centerPanel(gui:FindFirstChild("ChestPanel"), 0.94, 0.74)
end

local function tuneMainHUD()
	local gui = playerGui:WaitForChild("SurvivalHUD", 12)
	if not gui then return end
	local hotbar = gui:FindFirstChild("Hotbar")
	if hotbar and hotbar:IsA("ScrollingFrame") then
		hotbar.Position = UDim2.new(0.5, -24, 1, -8)
		hotbar.Size = UDim2.new(0.72, 0, 0, 54)
		hotbar.BackgroundTransparency = 0.82
		hotbar.ScrollBarThickness = 2
		local constraint = hotbar:FindFirstChildOfClass("UISizeConstraint")
		if constraint then
			constraint.MinSize = Vector2.new(0, 0)
			constraint.MaxSize = Vector2.new(760, 54)
		end
	end

	for _, child in gui:GetChildren() do
		if child:IsA("TextLabel") and child.AnchorPoint == Vector2.new(0.5, 0) then
			child.Size = UDim2.new(0.72, 0, 0, 36)
		end
	end

	local shopPanel = gui:FindFirstChild("ShopPanel")
	if shopPanel then centerPanel(shopPanel, 0.92, 0.72) end
end

local function tuneHatShop()
	local gui = playerGui:WaitForChild("SurvivalHUD", 12)
	if not gui then return end
	local hatPanel = gui:FindFirstChild("HatShopPanel")
	if hatPanel then centerPanel(hatPanel, 0.92, 0.72) end
end

task.spawn(tuneSurvivalSystems)
task.spawn(tuneMainHUD)
task.delay(1, tuneHatShop)
