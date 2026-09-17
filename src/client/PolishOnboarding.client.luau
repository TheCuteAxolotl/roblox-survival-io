local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "JourneyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 28
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "AdventureObjective"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 112)
card.Size = UDim2.fromOffset(460, 62)
card.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
card.BackgroundTransparency = 0.12
card.BorderSizePixel = 0
card.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 130, 235)
stroke.Transparency = 0.78
stroke.Parent = card

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(13, 7)
title.Size = UDim2.new(1, -26, 0, 16)
title.BackgroundTransparency = 1
title.Text = "MAIN JOURNEY"
title.TextColor3 = Color3.fromRGB(202, 166, 244)
title.Font = Enum.Font.GothamBlack
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(13, 24)
objective.Size = UDim2.new(1, -26, 0, 31)
objective.BackgroundTransparency = 1
objective.TextColor3 = Color3.fromRGB(244, 244, 248)
objective.Font = Enum.Font.GothamBold
objective.TextSize = 12
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top
objective.Parent = card

local function refresh()
	if player:GetAttribute("InRiftExpedition") == true then
		card.Visible = false
		return
	end
	card.Visible = true
	local best = player:GetAttribute("RiftBestStageSession") or 0
	local runs = player:GetAttribute("RiftRunsSession") or 0
	local wins = player:GetAttribute("RiftVictoriesSession") or 0

	if best == 0 then
		objective.Text = "Find the glowing RIFT EXPEDITIONS gate beside the Hunter Hall. Start a run solo, or let friends join the 8-second rally."
	elseif best < 3 then
		objective.Text = "Reach Stage 3 and defeat Gloomfang. Kills give Essence — choose Rift powers whenever you level."
	elseif runs == 0 and best >= 3 then
		objective.Text = "Stage 3 opens extraction. Bank your rewards safely, or stay inside and risk them for the deeper Rift."
	elseif best < 6 then
		objective.Text = "Push beyond the safe extraction and reach Stage 6. Stronger enemies pay more and your run build keeps growing."
	elseif wins == 0 then
		objective.Text = "Defeat the RIFT TYRANT at Stage 6 to conquer your first full expedition."
	else
		objective.Text = "Adventure loop unlocked: experiment with Rift builds, climb Hunter skills, take Town Hall contracts, hunt dungeon bosses, and improve your base."
	end
end

for _, attr in {
	"InRiftExpedition",
	"RiftBestStageSession",
	"RiftRunsSession",
	"RiftVictoriesSession",
} do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end

refresh()
