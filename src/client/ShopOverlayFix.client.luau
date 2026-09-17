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

local remembered = {}

local function externalButtons()
	local result = {}
	for _, guiName in { "SurvivalSystemsHUD", "DirectionalControlsHUD", "ActionAssistHUD", "ClanDoorHUD" } do
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			for _, object in gui:GetDescendants() do
				if object:IsA("TextButton") and object.Name ~= "QuickEat" then table.insert(result, object) end
			end
		end
	end
	return result
end

local function hideExternalButtons()
	remembered = {}
	for _, object in externalButtons() do
		remembered[object] = object.Visible
		object.Visible = false
	end
end

local function restoreExternalButtons()
	for object, wasVisible in remembered do
		if object.Parent then object.Visible = wasVisible end
	end
	remembered = {}
end

if shopPanel and shopPanel:IsA("GuiObject") then
	shopPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		if shopPanel.Visible then hideExternalButtons() else restoreExternalButtons() end
	end)
else
	warn("[ShopOverlayFix] Survival shop panel not found.")
end
