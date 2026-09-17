local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local function makeBillboard(part, name, text, color, offset)
	if part:FindFirstChild(name) then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(190, 42)
	gui.StudsOffset = offset or Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 52
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	label.BackgroundTransparency = 0.16
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.65
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextWrapped = true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function improveMine(model)
	if not model:IsA("Model") then return end
	local kind = model:GetAttribute("MineKind")
	if not kind then return end
	local deposit = model:FindFirstChild("Deposit")
	if not deposit or not deposit:IsA("BasePart") then return end
	local prompt = deposit:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	prompt.ActionText = kind == "Obsidian" and "MINE OBSIDIAN" or kind == "Sand" and "DIG SAND" or "MINE STONE"
	prompt.ObjectText = "Hold E / tap while close"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = kind == "Obsidian" and 0.55 or 0.3

	local itemText = kind == "Obsidian" and "OBSIDIAN\nHOLD E / TAP TO MINE"
		or kind == "Sand" and "SAND\nHOLD E / TAP TO DIG"
		or "STONE\nHOLD E / TAP TO MINE"
	makeBillboard(deposit, "InteractionHelp", itemText, Color3.fromRGB(244, 226, 142), Vector3.new(0, 7.5, 0))
end

local function improveCache(model)
	if not model:IsA("Model") or model.Name ~= "DungeonLootCache" then return end
	local chest = model:FindFirstChild("Cache")
	if not chest or not chest:IsA("BasePart") then return end
	local prompt = chest:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 14
	end
	makeBillboard(chest, "LootHelp", "DUNGEON CACHE\nCLEAR ENEMIES → HOLD E / TAP", Color3.fromRGB(255, 206, 104), Vector3.new(0, 6.5, 0))
end

local function inspect(instance)
	if not instance:IsA("Model") then return end
	if instance:GetAttribute("MineKind") then
		task.delay(0.25, function() if instance.Parent then improveMine(instance) end end)
	elseif instance.Name == "DungeonLootCache" then
		task.delay(0.25, function() if instance.Parent then improveCache(instance) end end)
	end
end

for _, descendant in world:GetDescendants() do inspect(descendant) end
world.DescendantAdded:Connect(inspect)

print("[DungeonInteractionUX] Mining and dungeon cache prompts upgraded.")
