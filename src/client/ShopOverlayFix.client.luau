local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local survivalHud = playerGui:WaitForChild("SurvivalHUD")
survivalHud.DisplayOrder = 75

local shopPanel = nil
for _, descendant in survivalHud:GetDescendants() do
	if descendant:IsA("TextLabel") and descendant.Text == "SURVIVAL SHOP" then
		shopPanel = descendant.Parent
		break
	end
end

local function setExternalButtonsVisible(visible)
	for _, guiName in { "SurvivalSystemsHUD", "DirectionalControlsHUD", "ActionAssistHUD", "ClanDoorHUD" } do
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			for _, object in gui:GetDescendants() do
				if object:IsA("TextButton") and object.Name ~= "QuickEat" then
					object.Visible = visible
				end
			end
		end
	end
end

if shopPanel and shopPanel:IsA("GuiObject") then
	shopPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		setExternalButtonsVisible(not shopPanel.Visible)
	end)
else
	warn("[ShopOverlayFix] Survival shop panel not found.")
end
