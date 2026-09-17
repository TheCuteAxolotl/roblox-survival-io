local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local registered = {}
local changing = false

local function hasTitle(frame, expected)
	for _, descendant in frame:GetDescendants() do
		if descendant:IsA("TextLabel") and descendant.Text == expected then
			return true
		end
	end
	return false
end

local function hideAssociatedOverlay(panel)
	local gui = panel:FindFirstAncestorOfClass("ScreenGui")
	if not gui then return end
	for _, child in gui:GetChildren() do
		if child:IsA("TextButton") and child ~= panel and child.Text == "" then
			local fillsScreen = child.Size.X.Scale >= 0.95 and child.Size.Y.Scale >= 0.95
			if fillsScreen and child.Visible then child.Visible = false end
		end
	end
end

local function closePanel(panel)
	if panel.Visible then panel.Visible = false end
	hideAssociatedOverlay(panel)
end

local function onOpened(opened)
	if changing or not opened.Visible then return end
	changing = true
	for panel in registered do
		if panel ~= opened and panel.Parent then closePanel(panel) end
	end
	changing = false
end

local function register(panel)
	if not panel or registered[panel] or not panel:IsA("Frame") then return end
	registered[panel] = true
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then onOpened(panel) end
	end)
	panel.AncestryChanged:Connect(function(_, parent)
		if not parent then registered[panel] = nil end
	end)
	if panel.Visible then onOpened(panel) end
end

local function scan()
	local survivalSystems = playerGui:FindFirstChild("SurvivalSystemsHUD")
	if survivalSystems then
		for _, name in { "BagPanel", "CraftPanel", "KitsPanel", "ChestPanel" } do
			register(survivalSystems:FindFirstChild(name))
		end
	end

	local survivalHud = playerGui:FindFirstChild("SurvivalHUD")
	if survivalHud then
		register(survivalHud:FindFirstChild("HatShopPanel"))
		for _, child in survivalHud:GetChildren() do
			if child:IsA("Frame") and hasTitle(child, "SURVIVAL SHOP") then register(child) end
		end
	end

	local clanGui = playerGui:FindFirstChild("ClanDoorHUD")
	if clanGui then
		for _, child in clanGui:GetChildren() do
			if child:IsA("Frame") and hasTitle(child, "CLAN + BASE ACCESS") then register(child) end
		end
	end

	local robuxGui = playerGui:FindFirstChild("RobuxStore")
	if robuxGui then
		for _, child in robuxGui:GetChildren() do
			if child:IsA("Frame") and hasTitle(child, "PREMIUM STORE") then register(child) end
		end
	end

	local tradeGui = playerGui:FindFirstChild("VillageTradeHUD")
	if tradeGui then
		for _, child in tradeGui:GetChildren() do
			if child:IsA("Frame") and child.Visible then register(child) end
		end
	end
end

playerGui.ChildAdded:Connect(function()
	task.delay(0.2, scan)
end)

task.spawn(function()
	while true do
		scan()
		task.wait(0.75)
	end
end)
