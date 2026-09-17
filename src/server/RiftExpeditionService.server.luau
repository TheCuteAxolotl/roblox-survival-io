local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RiftData = require(ReplicatedStorage.Shared.RiftRunData)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
if not remotes then return end

local riftState = remotes:FindFirstChild("RiftState") or Instance.new("RemoteEvent")
riftState.Name = "RiftState"
riftState.Parent = remotes

local riftAction = remotes:FindFirstChild("RiftAction") or Instance.new("RemoteEvent")
riftAction.Name = "RiftAction"
riftAction.Parent = remotes

local getRiftState = remotes:FindFirstChild("GetRiftState") or Instance.new("RemoteFunction")
getRiftState.Name = "GetRiftState"
getRiftState.Parent = remotes

local masteryAward = script.Parent:FindFirstChild("HunterMasteryAward") or Instance.new("BindableEvent")
masteryAward.Name = "HunterMasteryAward"
masteryAward.Parent = script.Parent

local center = RiftData.ArenaCenter
local run = {
	Status = "Idle",
	Participants = {},
	Live = {},
	Stage = 0,
	StageLabel = "",
	RallyEnds = 0,
	Token = 0,
	ExtractAvailable = false,
	Modifier = "Standard",
	StageSpawning = false,
	StageTimerEnds = 0,
}

local gatePosition = Vector3.new(0, 2, -180)
local extractPrompt
local gatePrompt

local function makePart(parent, name, size, cf, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanQuery = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addBillboard(parent, text, color, offset, size)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.fromOffset(240, 48)
	gui.StudsOffset = offset or Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	return label
end

local function participantCount()
	local n = 0
	for player in run.Participants do
		if player.Parent then n += 1 end
	end
	return n
end

local function liveCount()
	local n = 0
	for model in run.Live do
		local hum = model.Parent and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then n += 1 end
	end
	return n
end

local function publicState(player, message)
	return {
		Status = run.Status,
		Stage = run.Stage,
		StageLabel = run.StageLabel,
		PartySize = participantCount(),
		LiveEnemies = liveCount(),
		StageTimeRemaining = math.max(0, math.ceil((run.StageTimerEnds or 0) - Workspace:GetServerTimeNow())),
		RallyRemaining = math.max(0, math.ceil(run.RallyEnds - Workspace:GetServerTimeNow())),
		InRun = player and run.Participants[player] == true or false,
		BankGold = player and (player:GetAttribute("RiftBankGold") or 0) or 0,
		BankXP = player and (player:GetAttribute("RiftBankXP") or 0) or 0,
		Essence = player and (player:GetAttribute("RiftEssence") or 0) or 0,
		RunLevel = player and (player:GetAttribute("RiftRunLevel") or 1) or 1,
		NextEssence = player and (player:GetAttribute("RiftNextEssence") or 70) or 70,
		ExtractAvailable = run.ExtractAvailable,
		Downed = player and player:GetAttribute("RiftDowned") == true or false,
		SecondWinds = player and (player:GetAttribute("RiftSecondWinds") or 0) or 0,
		PendingChoices = player and player:GetAttribute("RiftPendingChoices") or nil,
		Modifier = run.Modifier,
		ModifierLabel = (RiftData.Modifiers[run.Modifier] and RiftData.Modifiers[run.Modifier].Label) or "STABLE RIFT",
		Message = message,
	}
end

local function push(player, message)
	if player and player.Parent then
		riftState:FireClient(player, publicState(player, message))
	end
end

local function pushAll(message)
	for player in run.Participants do push(player, message) end
end

local function resetRunPowers(player)
	player:SetAttribute("RiftDamageMultiplier", 1)
	player:SetAttribute("RiftDamageReduction", 0)
	player:SetAttribute("RiftSpeedBonus", 0)
	player:SetAttribute("RiftMaxHealthBonus", 0)
	player:SetAttribute("RiftBossDamageMultiplier", 1)
	player:SetAttribute("RiftGoldMultiplier", 1)
	player:SetAttribute("RiftBloodRush", 0)
	player:SetAttribute("RiftRecovery", 0)
	player:SetAttribute("RiftOvercharge", false)
	player:SetAttribute("RiftDodgeCooldownMultiplier", 1)
	player:SetAttribute("RiftSecondWinds", 1)
	player:SetAttribute("RiftDowned", false)
	player:SetAttribute("RiftPendingChoices", nil)
	for _, id in RiftData.UpgradeOrder do
		player:SetAttribute("RiftStack_" .. id, 0)
	end
end

local function setBaseRunState(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	player:SetAttribute("RiftBaseMaxHealth", hum and hum.MaxHealth or 100)
	resetRunPowers(player)
	player:SetAttribute("InRiftExpedition", true)
	player:SetAttribute("RiftBankGold", 0)
	player:SetAttribute("RiftBankXP", 0)
	player:SetAttribute("RiftEssence", 0)
	player:SetAttribute("RiftRunLevel", 1)
	player:SetAttribute("RiftNextEssence", 70)
end

local function restoreMovement(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local skill = player:GetAttribute("HunterSpeedBonus") or 0
	local rift = player:GetAttribute("RiftSpeedBonus") or 0
	hum.WalkSpeed = 16 + skill + rift
end

local function teleportPlayer(player, position)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return false end
	hum.Health = math.max(hum.Health, math.max(1, hum.MaxHealth * 0.6))
	root.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(CFrame.new(position))
	return true
end

local function applyUpgrade(player, id)
	local data = RiftData.Upgrades[id]
	if not data then return false end
	local key = "RiftStack_" .. id
	local stack = math.max(0, player:GetAttribute(key) or 0)
	if stack >= (data.MaxStacks or 1) then return false end
	stack += 1
	player:SetAttribute(key, stack)

	if id == "Fury" then
		player:SetAttribute("RiftDamageMultiplier", 1 + 0.18 * stack)
	elseif id == "IronSkin" then
		player:SetAttribute("RiftDamageReduction", math.min(0.36, 0.09 * stack))
	elseif id == "Quickstep" then
		player:SetAttribute("RiftSpeedBonus", 2 * stack)
		player:SetAttribute("RiftDodgeCooldownMultiplier", math.max(0.55, 1 - 0.10 * stack))
		restoreMovement(player)
	elseif id == "GiantHeart" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		player:SetAttribute("RiftMaxHealthBonus", 25 * stack)
		if hum then
			local oldMax = hum.MaxHealth
			hum.MaxHealth = math.max(hum.MaxHealth, (player:GetAttribute("RiftBaseMaxHealth") or 100) + 25 * stack)
			hum.Health = math.min(hum.MaxHealth, hum.Health + math.max(0, hum.MaxHealth - oldMax))
		end
	elseif id == "BloodRush" then
		player:SetAttribute("RiftBloodRush", 0.07 * stack)
	elseif id == "Executioner" then
		player:SetAttribute("RiftBossDamageMultiplier", 1 + 0.22 * stack)
	elseif id == "GreedyFlame" then
		player:SetAttribute("RiftGoldMultiplier", 1 + 0.18 * stack)
	elseif id == "SecondWind" then
		player:SetAttribute("RiftSecondWinds", (player:GetAttribute("RiftSecondWinds") or 0) + 1)
	elseif id == "Overcharge" then
		player:SetAttribute("RiftOvercharge", true)
	elseif id == "Recovery" then
		player:SetAttribute("RiftRecovery", 0.18 * stack)
	end
	return true
end

local function availableChoices(player)
	local pool = {}
	for _, id in RiftData.UpgradeOrder do
		local data = RiftData.Upgrades[id]
		local stack = player:GetAttribute("RiftStack_" .. id) or 0
		if stack < (data.MaxStacks or 1) then table.insert(pool, id) end
	end
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local result = {}
	for i = 1, math.min(3, #pool) do table.insert(result, pool[i]) end
	return result
end

local function maybeOfferChoice(player)
	if not run.Participants[player] or player:GetAttribute("RiftPendingChoices") then return end
	local essence = player:GetAttribute("RiftEssence") or 0
	local needed = player:GetAttribute("RiftNextEssence") or 70
	if essence < needed then return end
	player:SetAttribute("RiftEssence", essence - needed)
	local level = (player:GetAttribute("RiftRunLevel") or 1) + 1
	player:SetAttribute("RiftRunLevel", level)
	player:SetAttribute("RiftNextEssence", math.floor(65 + level * 35))
	local choices = availableChoices(player)
	if #choices == 0 then return end
	player:SetAttribute("RiftPendingChoices", table.concat(choices, ","))
	push(player, "LEVEL UP - Choose a Rift power.")
end

local function awardEssence(player, amount)
	if not run.Participants[player] then return end
	player:SetAttribute("RiftEssence", (player:GetAttribute("RiftEssence") or 0) + math.max(0, amount))
	maybeOfferChoice(player)
end

riftAction.OnServerEvent:Connect(function(player, actionName, payload)
	if actionName == "ChoosePower" and run.Participants[player] and type(payload) == "string" then
		local packed = player:GetAttribute("RiftPendingChoices")
		if type(packed) ~= "string" then return end
		local valid = false
		for id in string.gmatch(packed, "[^,]+") do
			if id == payload then valid = true break end
		end
		if not valid then return end
		if applyUpgrade(player, payload) then
			player:SetAttribute("RiftPendingChoices", nil)
			local info = RiftData.Upgrades[payload]
			push(player, "POWER ACQUIRED - " .. (info and info.Label or payload))
			task.delay(0.15, function() if player.Parent then maybeOfferChoice(player) end end)
		end
	end
end)

getRiftState.OnServerInvoke = function(player)
	return publicState(player)
end

local function buildArena()
	local old = Workspace:FindFirstChild("RiftExpeditionArena")
	if old then old:Destroy() end
	local arena = Instance.new("Model")
	arena.Name = "RiftExpeditionArena"
	arena.Parent = Workspace
	makePart(arena, "RiftFloor", Vector3.new(230, 2, 230), CFrame.new(center), Color3.fromRGB(34, 35, 43), Enum.Material.Slate)
	local borderColor = Color3.fromRGB(64, 53, 82)
	for _, data in {
		{ Vector3.new(0, 9, -114), Vector3.new(230, 18, 4) },
		{ Vector3.new(0, 9, 114), Vector3.new(230, 18, 4) },
		{ Vector3.new(-114, 9, 0), Vector3.new(4, 18, 230) },
		{ Vector3.new(114, 9, 0), Vector3.new(4, 18, 230) },
	} do
		makePart(arena, "RiftBoundary", data[2], CFrame.new(center + data[1]), borderColor, Enum.Material.Slate)
	end
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2
		local radius = i % 2 == 0 and 84 or 64
		local pos = center + Vector3.new(math.cos(a) * radius, 4, math.sin(a) * radius)
		local crystal = makePart(arena, "RiftCrystal", Vector3.new(3, 9 + (i % 3) * 3, 3), CFrame.new(pos) * CFrame.Angles(0, a, math.rad(12)), Color3.fromRGB(112, 76, 166), Enum.Material.Neon, 0.25, false)
		crystal.Shape = Enum.PartType.Cylinder
	end
	local core = makePart(arena, "RiftCore", Vector3.new(11, 1.5, 11), CFrame.new(center + Vector3.new(0, 1.2, 86)), Color3.fromRGB(125, 79, 177), Enum.Material.Neon, 0.12, false)
	core.Shape = Enum.PartType.Cylinder
	addBillboard(core, "EXTRACTION", Color3.fromRGB(222, 194, 255), Vector3.new(0, 4, 0), UDim2.fromOffset(170, 34))
	extractPrompt = Instance.new("ProximityPrompt")
	extractPrompt.ActionText = "Extract"
	extractPrompt.ObjectText = "Bank rewards and return to town"
	extractPrompt.MaxActivationDistance = 13
	extractPrompt.HoldDuration = 1.1
	extractPrompt.RequiresLineOfSight = false
	extractPrompt.Enabled = false
	extractPrompt.Parent = core
end

buildArena()

local function findGatePosition()
	local world = Workspace:FindFirstChild("SurvivalArena")
	if world then
		for _ = 1, 30 do
			local hall = world:FindFirstChild("FrontierTownHall")
			if hall and hall:IsA("Model") then
				local ok, pivot = pcall(function() return hall:GetPivot() end)
				if ok then return pivot.Position + Vector3.new(48, 1.5, 0) end
			end
			task.wait(0.2)
		end
	end
	return Vector3.new(0, 1.5, -190)
end

local function buildGate()
	local old = Workspace:FindFirstChild("RiftExpeditionGate")
	if old then old:Destroy() end
	gatePosition = findGatePosition()
	local gate = Instance.new("Model")
	gate.Name = "RiftExpeditionGate"
	gate.Parent = Workspace
	local stone = Color3.fromRGB(63, 61, 70)
	for _, x in { -7, 7 } do
		makePart(gate, "GatePillar", Vector3.new(4, 16, 4), CFrame.new(gatePosition + Vector3.new(x, 7, 0)), stone, Enum.Material.Slate)
	end
	makePart(gate, "GateTop", Vector3.new(18, 4, 4), CFrame.new(gatePosition + Vector3.new(0, 15, 0)), stone, Enum.Material.Slate)
	local portal = makePart(gate, "RiftPortal", Vector3.new(11, 12, 1.3), CFrame.new(gatePosition + Vector3.new(0, 7, 0)), Color3.fromRGB(116, 69, 176), Enum.Material.Neon, 0.28, false)
	addBillboard(portal, "RIFT EXPEDITIONS", Color3.fromRGB(235, 210, 255), Vector3.new(0, 9, 0), UDim2.fromOffset(260, 44))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(172, 103, 255)
	light.Range = 30
	light.Brightness = 2.5
	light.Parent = portal
	gatePrompt = Instance.new("ProximityPrompt")
	gatePrompt.ActionText = "Join Expedition"
	gatePrompt.ObjectText = "Solo or rally with friends"
	gatePrompt.MaxActivationDistance = 14
	gatePrompt.HoldDuration = 0.45
	gatePrompt.RequiresLineOfSight = false
	gatePrompt.Parent = portal
end

buildGate()

local function healthBar(root, hum, label, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RiftHealth"
	gui.Size = UDim2.fromOffset(170, 36)
	gui.StudsOffset = Vector3.new(0, 6.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 130
	gui.Parent = root
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 18)
	title.BackgroundTransparency = 1
	title.Text = label
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.45
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = gui
	local back = Instance.new("Frame")
	back.Position = UDim2.new(0, 0, 1, -12)
	back.Size = UDim2.new(1, 0, 0, 9)
	back.BackgroundColor3 = Color3.fromRGB(37, 37, 42)
	back.BorderSizePixel = 0
	back.Parent = gui
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	hum.HealthChanged:Connect(function()
		fill.Size = UDim2.fromScale(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 1)
	end)
end

local function weld(root, child)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = child
	w.Parent = child
end

local function bodyPart(model, root, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = model
	weld(root, p)
	return p
end

local function makeEnemyVisual(model, root, data)
	local s = data.Scale or 1
	local color = data.Color
	local glow = data.Glow
	bodyPart(model, root, "Body", Vector3.new(3.8, 3.2, 5.0) * s, CFrame.new(0, 0.8 * s, 0), color)
	bodyPart(model, root, "Chest", Vector3.new(3.2, 3.8, 2.8) * s, CFrame.new(0, 1.1 * s, -1.4 * s), color:Lerp(Color3.new(1,1,1), 0.08))
	bodyPart(model, root, "Head", Vector3.new(2.7, 2.6, 2.8) * s, CFrame.new(0, 2.3 * s, -3.2 * s), color, nil, Enum.PartType.Ball)
	bodyPart(model, root, "Muzzle", Vector3.new(1.7, 1.0, 1.6) * s, CFrame.new(0, 1.8 * s, -4.6 * s), color:Lerp(Color3.new(1,1,1), 0.16), nil, Enum.PartType.Ball)
	for _, side in { -1, 1 } do
		bodyPart(model, root, "Eye", Vector3.new(0.45, 0.45, 0.25) * s, CFrame.new(side * 0.72 * s, 2.65 * s, -4.2 * s), glow, Enum.Material.Neon, Enum.PartType.Ball)
		bodyPart(model, root, "Leg", Vector3.new(0.65, 2.4, 0.65) * s, CFrame.new(side * 1.1 * s, -0.75 * s, -1.3 * s), color:Lerp(Color3.new(0,0,0), 0.15))
		bodyPart(model, root, "Leg", Vector3.new(0.65, 2.4, 0.65) * s, CFrame.new(side * 1.1 * s, -0.75 * s, 1.5 * s), color:Lerp(Color3.new(0,0,0), 0.15))
	end
	if data.Boss then
		for _, side in { -1, 1 } do
			bodyPart(model, root, "Horn", Vector3.new(0.55, 3.4, 0.55) * s, CFrame.new(side * 1.0 * s, 4.4 * s, -3.0 * s) * CFrame.Angles(0, 0, math.rad(side * 20)), glow, Enum.Material.Neon)
		end
		bodyPart(model, root, "Core", Vector3.new(1.5, 1.5, 0.6) * s, CFrame.new(0, 1.4 * s, -2.25 * s), glow, Enum.Material.Neon, Enum.PartType.Ball)
	end
end

local function nearestParticipant(position)
	local best, distance
	for player in run.Participants do
		if player.Parent and player:GetAttribute("RiftDowned") ~= true then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local d = (root.Position - position).Magnitude
				if not distance or d < distance then best, distance = player, d end
			end
		end
	end
	return best, distance or math.huge
end

local function activeOtherExists(player)
	for other in run.Participants do
		if other ~= player and other.Parent and other:GetAttribute("RiftDowned") ~= true then
			local hum = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then return true end
		end
	end
	return false
end

local function clearDowned(player)
	player:SetAttribute("RiftDowned", false)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local prompt = root:FindFirstChild("RiftRevivePrompt")
		if prompt then prompt:Destroy() end
	end
	restoreMovement(player)
end

local function revivePlayer(player, fraction, message)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	clearDowned(player)
	hum.Health = math.max(1, hum.MaxHealth * (fraction or 0.42))
	push(player, message or "REVIVED")
end

local function payoutAndReturn(player, fraction, reason)
	if not run.Participants[player] then return end
	player:SetAttribute("RiftRunsSession", (player:GetAttribute("RiftRunsSession") or 0) + 1)
	if reason == "RIFT CONQUERED" then
		player:SetAttribute("RiftVictoriesSession", (player:GetAttribute("RiftVictoriesSession") or 0) + 1)
	end
	local gold = player:GetAttribute("RiftBankGold") or 0
	local xp = player:GetAttribute("RiftBankXP") or 0
	local goldMult = player:GetAttribute("RiftGoldMultiplier") or 1
	fraction = math.clamp(fraction or 1, 0, 1)
	gold = math.floor(gold * goldMult * fraction + 0.5)
	xp = math.floor(xp * fraction + 0.5)
	if gold > 0 or xp > 0 then PlayerService.Add(player, { Gold = gold, XP = xp }) end
	masteryAward:Fire(player, math.max(8, math.floor((run.Stage * 18 + xp * 0.08) * fraction)), 0)
	run.Participants[player] = nil
	clearDowned(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local baseMax = math.max(1, player:GetAttribute("RiftBaseMaxHealth") or 100)
	resetRunPowers(player)
	player:SetAttribute("RiftSecondWinds", 0)
	player:SetAttribute("InRiftExpedition", false)
	player:SetAttribute("RiftPendingChoices", nil)
	player:SetAttribute("RiftBaseMaxHealth", nil)
	if hum then
		hum.MaxHealth = baseMax
		hum.Health = math.min(hum.Health, hum.MaxHealth)
	end
	restoreMovement(player)
	task.delay(0.1, function()
		if player.Parent then
			teleportPlayer(player, gatePosition + Vector3.new(0, 2, 18))
			push(player, string.format("%s - +%d Gold - +%d XP", reason or "EXTRACTED", gold, xp))
		end
	end)
end

local function downPlayer(player)
	if not run.Participants[player] or player:GetAttribute("RiftDowned") == true then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	hum.Health = 1
	hum.WalkSpeed = 0
	player:SetAttribute("RiftDowned", true)
	push(player, "DOWNED - A teammate can revive you.")

	local winds = player:GetAttribute("RiftSecondWinds") or 0
	if not activeOtherExists(player) and winds > 0 then
		player:SetAttribute("RiftSecondWinds", winds - 1)
		task.delay(1.8, function()
			if player.Parent and run.Participants[player] and player:GetAttribute("RiftDowned") == true then
				revivePlayer(player, 0.5, "SECOND WIND - Back in the fight.")
			end
		end)
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RiftRevivePrompt"
	prompt.ActionText = "Revive"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = 2.1
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(reviver)
		if reviver == player or not run.Participants[reviver] or reviver:GetAttribute("RiftDowned") == true then return end
		if run.Participants[player] and player:GetAttribute("RiftDowned") == true then
			revivePlayer(player, 0.45, "REVIVED BY " .. string.upper(reviver.DisplayName))
		end
	end)

	task.delay(15, function()
		if player.Parent and run.Participants[player] and player:GetAttribute("RiftDowned") == true then
			payoutAndReturn(player, 0.35, "RIFT DEFEAT")
		end
	end)
end

local function damageParticipant(player, raw)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or player:GetAttribute("RiftDowned") == true then return end
	local armor = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	local rift = math.clamp(player:GetAttribute("RiftDamageReduction") or 0, 0, 0.55)
	local amount = math.max(1, math.floor(raw * (1 - armor) * (1 - rift) + 0.5))
	if hum.Health - amount <= 0 then
		downPlayer(player)
	else
		hum:TakeDamage(amount)
	end
end

local function spawnEnemy(enemyId, position)
	local data = RiftData.Enemies[enemyId]
	if not data then return nil end
	local party = math.max(1, participantCount())
	local modifier = RiftData.Modifiers[run.Modifier] or RiftData.Modifiers.Standard
	local healthScale = (1 + (party - 1) * 0.62 + math.max(0, run.Stage - 1) * 0.07) * (modifier.Health or 1)
	local damageScale = (1 + (party - 1) * 0.10 + math.max(0, run.Stage - 1) * 0.04) * (modifier.Damage or 1)

	local model = Instance.new("Model")
	model.Name = enemyId
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("RiftEnemy", true)
	model:SetAttribute("RiftBoss", data.Boss == true)
	if data.Boss then model:SetAttribute("BossKey", enemyId) end
	model.Parent = Workspace:FindFirstChild("RiftExpeditionArena") or Workspace

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3.2, 4.2, 4.2) * (data.Scale or 1)
	root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = true
	root.CanQuery = true
	root.Parent = model
	model.PrimaryPart = root
	pcall(function() root:SetNetworkOwner(nil) end)

	makeEnemyVisual(model, root, data)

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = math.floor(data.Health * healthScale)
	hum.Health = hum.MaxHealth
	hum.WalkSpeed = data.Speed * ((RiftData.Modifiers[run.Modifier] and RiftData.Modifiers[run.Modifier].Speed) or 1)
	hum.JumpPower = 0
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	healthBar(root, hum, data.Label, data.Glow)

	run.Live[model] = true
	local lastAttack = 0
	local lastSpecial = 0
	local enraged = false

	hum.Died:Connect(function()
		if not run.Live[model] then return end
		run.Live[model] = nil
		local essence = data.Boss and (enemyId == "RiftTyrant" and 120 or 75) or (enemyId == "RiftBrute" and 18 or enemyId == "RiftHunter" and 14 or 10)
		for player in run.Participants do
			awardEssence(player, essence)
			local rush = player:GetAttribute("RiftBloodRush") or 0
			if rush > 0 then
				local ph = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if ph and ph.Health > 0 and player:GetAttribute("RiftDowned") ~= true then
					ph.Health = math.min(ph.MaxHealth, ph.Health + ph.MaxHealth * rush)
				end
			end
			push(player)
		end
		task.delay(1.5, function() if model.Parent then model:Destroy() end end)
	end)

	task.spawn(function()
		while model.Parent and hum.Health > 0 and run.Status == "Active" do
			task.wait(0.18)
			if data.Boss and not enraged and hum.Health / hum.MaxHealth <= 0.35 then
				enraged = true
				hum.WalkSpeed = data.Speed * ((RiftData.Modifiers[run.Modifier] and RiftData.Modifiers[run.Modifier].Speed) or 1) * 1.28
				lastAttack = 0
			end
			local target, distance = nearestParticipant(root.Position)
			if target then
				local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if tr then
					hum:MoveTo(tr.Position)
					local cooldown = data.Cooldown * (enraged and 0.72 or 1)
					if distance <= data.Range and os.clock() - lastAttack >= cooldown then
						lastAttack = os.clock()
						damageParticipant(target, data.Damage * damageScale * (enraged and 1.18 or 1))
					end
					if data.Boss and os.clock() - lastSpecial >= (data.Special == "Bolts" and 3.0 or data.Special == "Slam" and 5.0 or 3.6) then
						lastSpecial = os.clock()
						if data.Special == "Bolts" then
							local targets = {}
							for player in run.Participants do
								if player:GetAttribute("RiftDowned") ~= true then
									local pr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
									if pr then table.insert(targets, { Player = player, Position = pr.Position }) end
								end
							end
							for i = 1, math.min(3, #targets) do
								local targetInfo = targets[i]
								local orb = Instance.new("Part")
								orb.Name = "VoidBolt"
								orb.Shape = Enum.PartType.Ball
								orb.Size = Vector3.new(2.4, 2.4, 2.4)
								orb.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0))
								orb.Anchored = true
								orb.CanCollide = false
								orb.CanQuery = false
								orb.Material = Enum.Material.Neon
								orb.Color = data.Glow
								orb.Parent = Workspace
								TweenService:Create(orb, TweenInfo.new(0.55, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetInfo.Position), Transparency = 0.25 }):Play()
								game:GetService("Debris"):AddItem(orb, 0.65)
								task.delay(0.53, function()
									local pr = targetInfo.Player.Character and targetInfo.Player.Character:FindFirstChild("HumanoidRootPart")
									if pr and (pr.Position - targetInfo.Position).Magnitude <= 8 then
										damageParticipant(targetInfo.Player, data.Damage * damageScale * 0.78)
									end
								end)
							end
						else
							local radius = data.Special == "Slam" and 28 or 22
							local duration = data.Special == "Slam" and 0.75 or 0.45
							local pulse = Instance.new("Part")
							pulse.Name = data.Special == "Slam" and "StormSlam" or "RiftBossPulse"
							pulse.Shape = Enum.PartType.Ball
							pulse.Size = Vector3.new(2, 0.6, 2)
							pulse.CFrame = CFrame.new(root.Position - Vector3.new(0, 1.8, 0))
							pulse.Anchored = true
							pulse.CanCollide = false
							pulse.CanQuery = false
							pulse.Material = Enum.Material.Neon
							pulse.Color = data.Glow
							pulse.Transparency = 0.25
							pulse.Parent = Workspace
							TweenService:Create(pulse, TweenInfo.new(duration), { Size = Vector3.new(radius * 2, 0.6, radius * 2), Transparency = 0.72 }):Play()
							game:GetService("Debris"):AddItem(pulse, duration + 0.1)
							task.delay(duration - 0.05, function()
								for player in run.Participants do
									local pr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
									if pr and (pr.Position - root.Position).Magnitude <= radius then
										local mult = data.Special == "Slam" and 0.95 or 0.72
										damageParticipant(player, data.Damage * damageScale * mult)
									end
								end
							end)
						end
					end
				end
			end
		end
	end)
	return model
end

local function randomArenaPoint(radius)
	local a = math.random() * math.pi * 2
	local r = math.random(35, radius or 82)
	return center + Vector3.new(math.cos(a) * r, 2, math.sin(a) * r)
end

local function spawnStage(stageIndex)
	local stage = RiftData.Stages[stageIndex]
	if not stage then return end
	run.Stage = stageIndex
	run.StageLabel = stage.Label
	run.StageSpawning = false
	run.StageTimerEnds = 0
	for player in run.Participants do
		player:SetAttribute("RiftBestStageSession", math.max(player:GetAttribute("RiftBestStageSession") or 0, stageIndex))
	end
	run.ExtractAvailable = false
	if extractPrompt then extractPrompt.Enabled = false end
	pushAll(string.format("STAGE %d - %s", stageIndex, stage.Label))

	local party = math.max(1, participantCount())
	local modifier = RiftData.Modifiers[run.Modifier] or RiftData.Modifiers.Standard
	local countScale = (1 + (party - 1) * 0.48) * (modifier.Count or 1)
	if stage.Kind == "Wave" then
		local count = math.max(1, math.floor(stage.BaseCount * countScale + 0.5))
		for _ = 1, count do spawnEnemy(stage.Enemy, randomArenaPoint()) task.wait(0.08) end
	elseif stage.Kind == "Mixed" then
		for _ = 1, math.max(1, math.floor(stage.BaseCount * countScale + 0.5)) do spawnEnemy(stage.Enemy, randomArenaPoint()) end
		for _ = 1, math.max(1, math.floor((stage.Brutes or 0) * countScale + 0.5)) do spawnEnemy("RiftBrute", randomArenaPoint()) end
	elseif stage.Kind == "Survival" then
		run.StageSpawning = true
		run.StageTimerEnds = Workspace:GetServerTimeNow() + (stage.Duration or 30)
		task.spawn(function()
			local nextSpawn = 0
			while run.Status == "Active" and run.Stage == stageIndex and Workspace:GetServerTimeNow() < run.StageTimerEnds and participantCount() > 0 do
				local now = Workspace:GetServerTimeNow()
				if now >= nextSpawn then
					nextSpawn = now + (stage.SpawnEvery or 3.5)
					local waveCount = math.max(1, math.floor(2 * countScale + 0.5))
					for i = 1, waveCount do
						local enemy = (i % 4 == 0) and "RiftBrute" or stage.Enemy
						spawnEnemy(enemy, randomArenaPoint())
					end
				end
				pushAll()
				task.wait(0.35)
			end
			if run.Stage == stageIndex then run.StageSpawning = false end
			pushAll("STORM ENDED - Finish the remaining corrupted enemies.")
		end)
	elseif stage.Kind == "Boss" then
		local bossId = stage.Enemy
		if stage.BossPool and #stage.BossPool > 0 then
			bossId = stage.BossPool[math.random(1, #stage.BossPool)]
		end
		spawnEnemy(bossId, center + Vector3.new(0, 2, 28))
		for _ = 1, math.max(0, math.floor((stage.Adds or 0) * countScale + 0.5)) do
			spawnEnemy(stageIndex == 3 and "Riftling" or "RiftHunter", randomArenaPoint(70))
		end
	end
end

local function awardStage(stageIndex)
	local stage = RiftData.Stages[stageIndex]
	if not stage then return end
	for player in run.Participants do
		local rewardScale = ((RiftData.Modifiers[run.Modifier] and RiftData.Modifiers[run.Modifier].Reward) or 1)
		player:SetAttribute("RiftBankGold", (player:GetAttribute("RiftBankGold") or 0) + math.floor((stage.RewardGold or 0) * rewardScale + 0.5))
		player:SetAttribute("RiftBankXP", (player:GetAttribute("RiftBankXP") or 0) + math.floor((stage.RewardXP or 0) * math.sqrt(rewardScale) + 0.5))
		awardEssence(player, stage.Essence or 0)
		local recovery = player:GetAttribute("RiftRecovery") or 0
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and player:GetAttribute("RiftDowned") ~= true then
			local heal = 0.12 + recovery
			hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * heal)
		end
		push(player, string.format("STAGE CLEAR - %d Gold banked", stage.RewardGold or 0))
	end
end

local function cleanupLive()
	for model in run.Live do
		if model.Parent then model:Destroy() end
	end
	run.Live = {}
end

local function endRunIfEmpty()
	if participantCount() == 0 then
		cleanupLive()
		run.Status = "Idle"
		run.Stage = 0
		run.StageLabel = ""
		run.ExtractAvailable = false
		run.StageSpawning = false
		run.StageTimerEnds = 0
		if extractPrompt then extractPrompt.Enabled = false end
		if gatePrompt then gatePrompt.Enabled = true gatePrompt.ActionText = "Join Expedition" end
		return true
	end
	return false
end

local function beginExpedition()
	if run.Status ~= "Rally" then return end
	run.Status = "Active"
	if gatePrompt then gatePrompt.Enabled = false end
	local index = 0
	local count = math.max(1, participantCount())
	for player in run.Participants do
		if player.Parent then
			index += 1
			setBaseRunState(player)
			local angle = (index - 1) * (math.pi * 2 / count)
			local spawnPos = center + Vector3.new(math.cos(angle) * 12, 4, math.sin(angle) * 12 - 72)
			teleportPlayer(player, spawnPos)
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = hum.MaxHealth end
			restoreMovement(player)
			push(player, "RIFT OPEN - Clear stages, grow stronger, and choose when to extract.")
		end
	end

	for stage = 1, RiftData.MaxStages do
		if endRunIfEmpty() then return end
		spawnStage(stage)
		while (liveCount() > 0 or run.StageSpawning) and participantCount() > 0 do task.wait(0.35) end
		if endRunIfEmpty() then return end
		awardStage(stage)

		if stage == RiftData.ExtractAfterStage then
			run.ExtractAvailable = true
			if extractPrompt then extractPrompt.Enabled = true end
			pushAll("SAFE EXTRACTION OPEN - Leave now, or stay for deeper stages and bigger rewards.")
			local deadline = Workspace:GetServerTimeNow() + 18
			while Workspace:GetServerTimeNow() < deadline and participantCount() > 0 do task.wait(0.5) end
			run.ExtractAvailable = false
			if extractPrompt then extractPrompt.Enabled = false end
			if endRunIfEmpty() then return end
		elseif stage < RiftData.MaxStages then
			for _ = 1, RiftData.IntermissionSeconds do
				if participantCount() == 0 then break end
				task.wait(1)
			end
		end
	end

	local winners = {}
	for player in run.Participants do table.insert(winners, player) end
	for _, player in winners do payoutAndReturn(player, 1, "RIFT CONQUERED") end
	cleanupLive()
	run.Status = "Idle"
	run.Stage = 0
	run.StageLabel = ""
	if gatePrompt then gatePrompt.Enabled = true gatePrompt.ActionText = "Join Expedition" end
end

local function joinRally(player)
	if run.Status == "Active" then
		push(player, "A Rift expedition is already in progress. Wait for the team to return.")
		return
	end
	if run.Status == "Idle" then
		run.Token += 1
		run.Status = "Rally"
		run.Participants = {}
		run.Stage = 0
		run.StageLabel = "RALLYING"
		local order = RiftData.ModifierOrder
		run.Modifier = order[math.random(1, #order)]
		run.RallyEnds = Workspace:GetServerTimeNow() + RiftData.RallySeconds
		local token = run.Token
		run.Participants[player] = true
		local modifier = RiftData.Modifiers[run.Modifier]
		push(player, "EXPEDITION RALLY STARTED - " .. (modifier and modifier.Label or "STABLE RIFT"))
		task.spawn(function()
			while run.Status == "Rally" and run.Token == token and Workspace:GetServerTimeNow() < run.RallyEnds do
				pushAll()
				task.wait(1)
			end
			if run.Status == "Rally" and run.Token == token then beginExpedition() end
		end)
	else
		run.Participants[player] = true
		pushAll(player.DisplayName .. " joined the expedition rally.")
	end
end

gatePrompt.Triggered:Connect(joinRally)

extractPrompt.Triggered:Connect(function(player)
	if run.Status == "Active" and run.ExtractAvailable and run.Participants[player] then
		payoutAndReturn(player, 1, "EXTRACTED")
		endRunIfEmpty()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	run.Participants[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("InRiftExpedition", false)
	player:SetAttribute("RiftDowned", false)
	player:SetAttribute("RiftRunsSession", 0)
	player:SetAttribute("RiftVictoriesSession", 0)
	player:SetAttribute("RiftBestStageSession", 0)
end)
for _, player in Players:GetPlayers() do
	player:SetAttribute("InRiftExpedition", false)
	player:SetAttribute("RiftDowned", false)
	player:SetAttribute("RiftRunsSession", player:GetAttribute("RiftRunsSession") or 0)
	player:SetAttribute("RiftVictoriesSession", player:GetAttribute("RiftVictoriesSession") or 0)
	player:SetAttribute("RiftBestStageSession", player:GetAttribute("RiftBestStageSession") or 0)
end

print("[RiftExpedition] Rift runs online: rally, six stages, random powers, extraction, solo Second Wind and co-op revives.")
