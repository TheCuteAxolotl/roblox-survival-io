local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local function weld(root, child)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = root
	constraint.Part1 = child
	constraint.Parent = child
end

local function bodyPart(model, root, name, size, relative, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * relative
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = true
	p.Massless = true
	if shape then p.Shape = shape end
	p.Parent = model
	weld(root, p)
	return p
end

local function addNameplate(model, root, title, subtitle, color)
	if model:FindFirstChild("CreatureNameplate") then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CreatureNameplate"
	gui.Size = UDim2.fromOffset(190, 46)
	gui.StudsOffset = Vector3.new(0, 9, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = root
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = title .. "\n" .. subtitle
	text.TextColor3 = color
	text.TextStrokeTransparency = 0.35
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextWrapped = true
	text.Parent = gui
end

local function upgradeDragon(model)
	if model:GetAttribute("ReadableDungeonVisual") then return end
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not root or not root:IsA("BasePart") then return end
	model:SetAttribute("ReadableDungeonVisual", true)

	local darkRed = Color3.fromRGB(104, 43, 37)
	local red = Color3.fromRGB(145, 62, 46)
	local bone = Color3.fromRGB(226, 211, 164)
	local wing = Color3.fromRGB(73, 34, 43)

	local oldBody = model:FindFirstChild("DragonBody")
	if oldBody and oldBody:IsA("Part") then oldBody.Size = Vector3.new(8.5, 4.5, 12.5) oldBody.Shape = Enum.PartType.Block end
	local oldHead = model:FindFirstChild("DragonHead")
	if oldHead and oldHead:IsA("Part") then oldHead.Size = Vector3.new(5, 4, 5) oldHead.Shape = Enum.PartType.Block end

	bodyPart(model, root, "DragonNeck", Vector3.new(4.2, 3.8, 5), CFrame.new(0, 2.2, -4.8) * CFrame.Angles(math.rad(-12), 0, 0), darkRed, Enum.Material.Slate)
	bodyPart(model, root, "DragonSnout", Vector3.new(3.8, 2.2, 4.5), CFrame.new(0, 3.3, -9.5), red, Enum.Material.Slate)
	bodyPart(model, root, "DragonJaw", Vector3.new(3.9, 0.8, 4.2), CFrame.new(0, 2.1, -9.2), Color3.fromRGB(75, 31, 28), Enum.Material.Slate)

	for _, side in { -1, 1 } do
		bodyPart(model, root, "DragonEye", Vector3.new(0.65, 0.65, 0.35), CFrame.new(side * 1.45, 4.35, -9.15), Color3.fromRGB(255, 203, 55), Enum.Material.Neon, Enum.PartType.Ball)
		bodyPart(model, root, "DragonBrowHorn", Vector3.new(0.5, 2.3, 0.5), CFrame.new(side * 1.55, 5.5, -7.7) * CFrame.Angles(math.rad(-32), 0, math.rad(side * 18)), bone, Enum.Material.Slate)
		for _, z in { -2.4, 2.5 } do
			bodyPart(model, root, "DragonLeg", Vector3.new(1.25, 4.2, 1.25), CFrame.new(side * 3.1, -1.4, z) * CFrame.Angles(0, 0, math.rad(side * 8)), darkRed, Enum.Material.Slate)
			bodyPart(model, root, "DragonFoot", Vector3.new(1.8, 0.8, 2.8), CFrame.new(side * 3.15, -3.15, z - 0.45), red, Enum.Material.Slate)
		end
		bodyPart(model, root, "DragonWingOuter", Vector3.new(7.5, 0.35, 8.5), CFrame.new(side * 8.6, 3.2, 1.3) * CFrame.Angles(0, math.rad(side * -12), math.rad(side * 15)), wing, Enum.Material.Fabric)
	end

	for i = 1, 4 do
		local width = math.max(1.0, 3.2 - i * 0.5)
		bodyPart(model, root, "DragonTail" .. i, Vector3.new(width, width, 4.2), CFrame.new(0, 1.2 - i * 0.25, 6.2 + i * 3.2) * CFrame.Angles(math.rad(i * 3), 0, 0), darkRed, Enum.Material.Slate)
	end
	for z = -3, 7, 2 do
		bodyPart(model, root, "DragonSpine", Vector3.new(0.55, 1.7, 0.8), CFrame.new(0, 4, z) * CFrame.Angles(math.rad(18), 0, 0), bone, Enum.Material.Slate)
	end

	addNameplate(model, root, "DUNGEON DRAGON", "FIRE • MYTHIC LOOT", Color3.fromRGB(255, 184, 95))
end

local function upgradeDemon(model)
	if model:GetAttribute("ReadableDungeonVisual") then return end
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not root or not root:IsA("BasePart") then return end
	model:SetAttribute("ReadableDungeonVisual", true)

	local purple = Color3.fromRGB(89, 43, 88)
	local dark = Color3.fromRGB(48, 31, 55)
	local glow = Color3.fromRGB(234, 70, 165)
	local oldHead = model:FindFirstChild("DemonHead")
	if oldHead and oldHead:IsA("Part") then oldHead.Shape = Enum.PartType.Block oldHead.Size = Vector3.new(3.7, 3.5, 3.4) end

	for _, side in { -1, 1 } do
		bodyPart(model, root, "DemonArm", Vector3.new(1.1, 5.4, 1.1), CFrame.new(side * 3.0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(side * 15)), purple, Enum.Material.Slate)
		bodyPart(model, root, "DemonClaw", Vector3.new(1.5, 1.0, 1.8), CFrame.new(side * 3.55, -1.3, -0.5), dark, Enum.Material.Slate)
		bodyPart(model, root, "DemonLeg", Vector3.new(1.45, 4.2, 1.45), CFrame.new(side * 1.3, -2.3, 0.3), dark, Enum.Material.Slate)
		bodyPart(model, root, "DemonFoot", Vector3.new(1.8, 0.9, 2.8), CFrame.new(side * 1.3, -4.2, -0.6), purple, Enum.Material.Slate)
		bodyPart(model, root, "DemonEye", Vector3.new(0.55, 0.6, 0.25), CFrame.new(side * 0.85, 5.8, -2.35), glow, Enum.Material.Neon, Enum.PartType.Ball)
		bodyPart(model, root, "ShoulderSpike", Vector3.new(0.65, 2.2, 0.65), CFrame.new(side * 2.5, 4.1, 0) * CFrame.Angles(0, 0, math.rad(side * -35)), Color3.fromRGB(60, 54, 65), Enum.Material.Slate)
	end
	bodyPart(model, root, "DemonChest", Vector3.new(5.8, 1.0, 4.3), CFrame.new(0, 2.7, 0), dark, Enum.Material.Slate)
	addNameplate(model, root, "ABYSS DEMON", "DARK PULSE • RARE LOOT", Color3.fromRGB(231, 126, 226))
end

local function upgradeMine(model)
	if model:GetAttribute("ReadableMineVisual") then return end
	local kind = model:GetAttribute("MineKind")
	if not kind then return end
	local deposit = model:FindFirstChild("Deposit")
	if not deposit or not deposit:IsA("BasePart") then return end
	model:SetAttribute("ReadableMineVisual", true)

	if kind == "Obsidian" then
		deposit.Shape = Enum.PartType.Block
		deposit.Size = Vector3.new(4.5, 2.2, 4.5)
		for i, offset in { Vector3.new(-1.3, 2.5, 0.4), Vector3.new(0.8, 3.2, -0.6), Vector3.new(1.6, 2.1, 1.1) } do
			local shard = Instance.new("Part")
			shard.Name = "ObsidianCrystal" .. i
			shard.Size = Vector3.new(1.1, 5 + i, 1.1)
			shard.CFrame = deposit.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(i * 7), 0, math.rad((i - 2) * 12))
			shard.Color = Color3.fromRGB(74, 50, 101)
			shard.Material = Enum.Material.Glass
			shard.Anchored = true
			shard.CanCollide = false
			shard.Parent = model
		end
	elseif kind == "Sand" then
		deposit.Shape = Enum.PartType.Cylinder
		deposit.Size = Vector3.new(2.2, 7, 7)
		deposit.Orientation = Vector3.new(0, 0, 90)
	else
		deposit.Shape = Enum.PartType.Block
		deposit.Size = Vector3.new(6, 4, 5)
		deposit.Orientation = Vector3.new(8, 25, 4)
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "MineLabel"
	gui.Size = UDim2.fromOffset(130, 28)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 55
	gui.Parent = deposit
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = kind == "Obsidian" and "OBSIDIAN VEIN" or kind == "Sand" and "SAND DEPOSIT" or "CAVE STONE"
	label.TextColor3 = Color3.fromRGB(240, 235, 220)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

local function inspect(instance)
	if not instance:IsA("Model") then return end
	if instance:GetAttribute("DungeonMob") == true then
		local mobType = instance:GetAttribute("MobType")
		task.delay(0.2, function()
			if not instance.Parent then return end
			if mobType == "Dragon" then upgradeDragon(instance) elseif mobType == "Demon" then upgradeDemon(instance) end
		end)
	elseif instance:GetAttribute("MineKind") then
		task.delay(0.1, function() if instance.Parent then upgradeMine(instance) end end)
	end
end

for _, descendant in world:GetDescendants() do inspect(descendant) end
world.DescendantAdded:Connect(inspect)

print("[DungeonVisualUpgrade] Dungeon creatures and mining nodes upgraded for readability.")
