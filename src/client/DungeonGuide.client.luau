local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DungeonGuideHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 38
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "DungeonObjective"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 106)
panel.Size = UserInputService.TouchEnabled and UDim2.new(0.92, 0, 0, 104) or UDim2.fromOffset(610, 96)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.ZIndex = 40
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.82
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 8)
title.Size = UDim2.new(1, -28, 0, 24)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = UserInputService.TouchEnabled and 13 or 15
title.TextColor3 = Color3.fromRGB(245, 220, 126)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 41
title.Parent = panel

local description = Instance.new("TextLabel")
description.Position = UDim2.fromOffset(14, 32)
description.Size = UDim2.new(1, -28, 1, -40)
description.BackgroundTransparency = 1
description.Font = Enum.Font.Gotham
description.TextSize = UserInputService.TouchEnabled and 10 or 11
description.TextColor3 = Color3.fromRGB(226, 226, 232)
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.ZIndex = 41
description.Parent = panel

local currentDungeon = nil

local function dungeonText(kind)
	if kind == "Dragon" then
		return "DRAGON DUNGEON — ENDGAME LOOT", "Defeat the Dragon for 2–4 Dragon Scales + 325 Gold / 220 XP. Mine Obsidian in the back. Very rare drops: Eclipse Cloak and Ancient Relic. Dragon Scales + Demon Cores + Obsidian are used to craft Mythic Dragonforged Armor."
	end
	return "DEMON VAULT — ENDGAME MATERIALS", "Defeat the Demons for Demon Cores, Obsidian + 140 Gold / 95 XP each. Very rare drops: Eclipse Cloak and Ancient Relic. Demon Cores combine with Dragon Scales and Obsidian for Mythic Dragonforged Armor."
end

local function insideDungeon(root, dungeon)
	local floor = dungeon:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then return false end
	local localPos = floor.CFrame:PointToObjectSpace(root.Position)
	return math.abs(localPos.X) <= floor.Size.X / 2
		and math.abs(localPos.Z) <= floor.Size.Z / 2
		and root.Position.Y <= floor.Position.Y + 28
end

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.2 then return end
	accumulator = 0

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = Workspace:FindFirstChild("SurvivalArena")
	if not root or not world then
		panel.Visible = false
		currentDungeon = nil
		return
	end

	local found = nil
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Dungeon") == true and insideDungeon(root, child) then
			found = child
			break
		end
	end

	if not found then
		panel.Visible = false
		currentDungeon = nil
		return
	end

	if found ~= currentDungeon then
		currentDungeon = found
		local heading, body = dungeonText(found:GetAttribute("DungeonType"))
		title.Text = heading
		description.Text = body
	end
	panel.Visible = true
end)
