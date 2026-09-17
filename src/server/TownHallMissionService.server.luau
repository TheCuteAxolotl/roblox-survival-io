local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MissionData = require(ReplicatedStorage.Shared.MissionData)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 20)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
if not world or not remotes then return end

local missionState = remotes:FindFirstChild("MissionState") or Instance.new("RemoteEvent")
missionState.Name = "MissionState"
missionState.Parent = remotes

local getMissionState = remotes:FindFirstChild("GetMissionState") or Instance.new("RemoteFunction")
getMissionState.Name = "GetMissionState"
getMissionState.Parent = remotes

local missionAction = remotes:FindFirstChild("MissionAction") or Instance.new("RemoteEvent")
missionAction.Name = "MissionAction"
missionAction.Parent = remotes

local masteryAward = script.Parent:FindFirstChild("HunterMasteryAward") or Instance.new("BindableEvent")
masteryAward.Name = "HunterMasteryAward"
masteryAward.Parent = script.Parent

local active = {}
local lastResources = {}
local connectedMobs = setmetatable({}, { __mode = "k" })
local nightEligible = {}

local function part(parent, name, size, cf, color, material, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addSurfaceText(target, face, text, color, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.AlwaysOnTop = false
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(239, 226, 194)
	label.TextStrokeTransparency = 0.75
	label.Font = font or Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	return label
end

local function publicState(player, message)
	local record = active[player]
	if not record then
		return {
			Active = false,
			Message = message,
			CompletedThisSession = player:GetAttribute("MissionCompletionsSession") or 0,
		}
	end
	local mission = MissionData.Get(record.Id)
	local objective = mission and mission.Objective or {}
	return {
		Active = true,
		Id = record.Id,
		Rank = mission.Rank,
		Title = mission.Title,
		Description = mission.Description,
		Progress = record.Progress,
		Goal = objective.Amount or 1,
		RewardGold = mission.Reward.Gold,
		RewardXP = mission.Reward.XP,
		Message = message,
		CompletedThisSession = player:GetAttribute("MissionCompletionsSession") or 0,
	}
end

local function push(player, message)
	if player and player.Parent then missionState:FireClient(player, publicState(player, message)) end
end

local function complete(player)
	local record = active[player]
	if not record then return end
	local mission = MissionData.Get(record.Id)
	if not mission then active[player] = nil return end
	local goldMultiplier = math.max(1, player:GetAttribute("HunterGoldMultiplier") or 1)
	local gold = math.max(1, math.floor((mission.Reward.Gold or 0) * goldMultiplier + 0.5))
	local xp = mission.Reward.XP or 0
	PlayerService.Add(player, { Gold = gold, XP = xp })
	player:SetAttribute("MissionCompletionsSession", (player:GetAttribute("MissionCompletionsSession") or 0) + 1)
	masteryAward:Fire(player, mission.Reward.Mastery or 20, 1)
	active[player] = nil
	nightEligible[player] = nil
	push(player, `CONTRACT COMPLETE • +{gold} Gold • +{xp} Forge XP`)
end

local function addProgress(player, amount)
	local record = active[player]
	if not record then return end
	local mission = MissionData.Get(record.Id)
	if not mission then return end
	local goal = mission.Objective.Amount or 1
	record.Progress = math.clamp(record.Progress + math.max(0, amount or 0), 0, goal)
	if record.Progress >= goal then complete(player) else push(player) end
end

local function accept(player, missionId)
	local mission = MissionData.Get(missionId)
	if not mission then push(player, "That contract is unavailable.") return end
	if active[player] then
		push(player, "Finish or abandon your current contract before taking another.")
		return
	end
	local profile = PlayerService.Get(player)
	local forge = profile and math.floor(profile.Age or 1) or 1
	if forge < (mission.MinForge or 1) then
		push(player, `LOCKED • Requires Forge Level {mission.MinForge}`)
		return
	end
	active[player] = { Id = missionId, Progress = 0, AcceptedAt = os.clock() }
	local objective = mission.Objective
	if objective.Type == "SurviveNight" and ReplicatedStorage:GetAttribute("WildforgePhase") == "Night" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		nightEligible[player] = hum ~= nil and hum.Health > 0
	end
	push(player, `ACCEPTED [{mission.Rank}] {mission.Title}`)
end

getMissionState.OnServerInvoke = function(player)
	return publicState(player)
end

missionAction.OnServerEvent:Connect(function(player, actionName, payload)
	if actionName == "Abandon" then
		if active[player] then
			active[player] = nil
			nightEligible[player] = nil
			push(player, "Contract abandoned. Return to the Town Hall for another.")
		end
	elseif actionName == "Accept" and type(payload) == "string" then
		accept(player, payload)
	end
end)

local function isForestMob(model)
	if model:GetAttribute("MobBiome") == "Forest" then return true end
	local mobType = tostring(model:GetAttribute("MobType") or model.Name)
	if mobType == "DireWolf" or mobType == "BlackwoodBear" or mobType == "BroodSpider" then return true end
	local ancestor = model.Parent
	while ancestor and ancestor ~= world do
		if ancestor.Name == "BlackwoodForest" or ancestor:GetAttribute("DangerZone") == true then return true end
		ancestor = ancestor.Parent
	end
	return false
end

local function qualifiesKill(model, objective)
	if objective.Type == "KillAny" then return true end
	if objective.Type == "KillBiome" then return objective.Biome == "Forest" and isForestMob(model) end
	if objective.Type == "KillBoss" then
		return model:GetAttribute("DungeonBoss") == true or model:GetAttribute("BossMob") == true or model:GetAttribute("BossKey") ~= nil
	end
	if objective.Type == "KillBossKey" then return model:GetAttribute("BossKey") == objective.BossKey end
	return false
end

local function connectMob(model)
	if connectedMobs[model] or not model:IsA("Model") then return end
	task.defer(function()
		if connectedMobs[model] or not model.Parent or model:GetAttribute("SurvivalMob") ~= true then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum then
			hum = model:WaitForChild("Humanoid", 2)
		end
		if not hum then return end
		connectedMobs[model] = true
		hum.Died:Connect(function()
			local attackerId = model:GetAttribute("LastAttackerUserId")
			local player = attackerId and Players:GetPlayerByUserId(attackerId)
			local record = player and active[player]
			local mission = record and MissionData.Get(record.Id)
			if mission and qualifiesKill(model, mission.Objective) then addProgress(player, 1) end
		end)
	end)
end

for _, descendant in world:GetDescendants() do if descendant:IsA("Model") then connectMob(descendant) end end
world.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") then connectMob(descendant)
	elseif descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then connectMob(descendant.Parent) end
end)

world.ChildAdded:Connect(function(child)
	if not child:IsA("Model") then return end
	task.delay(0.35, function()
		if not child.Parent then return end
		local ownerId = child:GetAttribute("OwnerUserId")
		if type(ownerId) ~= "number" or ownerId <= 0 then return end
		local player = Players:GetPlayerByUserId(ownerId)
		local record = player and active[player]
		local mission = record and MissionData.Get(record.Id)
		if mission and mission.Objective.Type == "Build" and (child:GetAttribute("BuildType") or child:GetAttribute("SurvivalStructure") or child:GetAttribute("AdvancedStructure")) then
			addProgress(player, 1)
		end
	end)
end)

local function waitForProfile(player)
	for _ = 1, 80 do
		local profile = PlayerService.Get(player)
		if profile then
			lastResources[player] = { Wood = profile.Wood or 0, Stone = profile.Stone or 0 }
			return
		end
		task.wait(0.1)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("MissionCompletionsSession", 0)
	task.spawn(waitForProfile, player)
end)
for _, player in Players:GetPlayers() do
	player:SetAttribute("MissionCompletionsSession", player:GetAttribute("MissionCompletionsSession") or 0)
	task.spawn(waitForProfile, player)
end
Players.PlayerRemoving:Connect(function(player)
	active[player], lastResources[player], nightEligible[player] = nil, nil, nil
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local profile = PlayerService.Get(player)
			if not profile then continue end
			local previous = lastResources[player] or { Wood = profile.Wood or 0, Stone = profile.Stone or 0 }
			local record = active[player]
			local mission = record and MissionData.Get(record.Id)
			if mission and mission.Objective.Type == "Gather" then
				local resource = mission.Objective.Resource
				local nowValue = profile[resource] or 0
				local oldValue = previous[resource] or 0
				if nowValue > oldValue then addProgress(player, nowValue - oldValue) end
			end
			lastResources[player] = { Wood = profile.Wood or 0, Stone = profile.Stone or 0 }
		end
	end
end)

local lastPhase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"
ReplicatedStorage:GetAttributeChangedSignal("WildforgePhase"):Connect(function()
	local phase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"
	if phase == "Night" then
		for _, player in Players:GetPlayers() do
			local record = active[player]
			local mission = record and MissionData.Get(record.Id)
			if mission and mission.Objective.Type == "SurviveNight" then
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				nightEligible[player] = hum ~= nil and hum.Health > 0
			end
		end
	elseif phase == "Dawn" and lastPhase == "Night" then
		for player, eligible in nightEligible do
			if eligible and player.Parent then
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then addProgress(player, 1) end
			end
		end
		table.clear(nightEligible)
	end
	lastPhase = phase
end)

local function majorLandmark(model)
	return model:IsA("Model") and (
		model:GetAttribute("VillageBiome") ~= nil
		or model:GetAttribute("Dungeon") == true
		or model:GetAttribute("Cave") == true
		or model:GetAttribute("DangerZone") == true
		or model:GetAttribute("Castle") == true
		or model.Name == "BossArena"
	)
end

local function clearLocation(center)
	if math.abs(center.Z) < 82 then return false end
	local size = Vector3.new(92, 18, 74)
	for _, child in world:GetChildren() do
		if majorLandmark(child) then
			local ok, cf, otherSize = pcall(function() return child:GetBoundingBox() end)
			if ok and cf and otherSize then
				local overlap = math.abs(center.X - cf.Position.X) < (size.X + otherSize.X) / 2 + 28
					and math.abs(center.Z - cf.Position.Z) < (size.Z + otherSize.Z) / 2 + 28
				if overlap then return false end
			end
		end
	end
	return true
end

local function chooseTownCenter()
	for _, candidate in {
		Vector3.new(0, 0, -155), Vector3.new(0, 0, 155),
		Vector3.new(-105, 0, -175), Vector3.new(105, 0, 175),
		Vector3.new(115, 0, -185), Vector3.new(-115, 0, 185),
	} do
		if clearLocation(candidate) then return candidate end
	end
	return Vector3.new(0, 0, -155)
end

local function clearNature(center, radius)
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child.PrimaryPart and (child:GetAttribute("Resource") or child:GetAttribute("SurvivalMob")) then
			local p = child.PrimaryPart.Position
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= radius then child:Destroy() end
		end
	end
end

local function buildTownHall(center)
	clearNature(center, 62)
	local hall = Instance.new("Model")
	hall.Name = "FrontierTownHall"
	hall:SetAttribute("TownHall", true)
	hall:SetAttribute("GeneratedLandmark", true)
	-- Castle generation already treats VillageBiome models as protected landmarks.
	hall:SetAttribute("VillageBiome", "Grass")
	hall.Parent = world

	local stone = Color3.fromRGB(104, 105, 101)
	local wood = Color3.fromRGB(117, 83, 55)
	local darkWood = Color3.fromRGB(82, 58, 43)
	local paper = Color3.fromRGB(237, 224, 184)

	part(hall, "TownSquare", Vector3.new(94, 1, 78), CFrame.new(center + Vector3.new(0, 0.5, 0)), Color3.fromRGB(111, 108, 96), Enum.Material.Cobblestone)
	part(hall, "HallFloor", Vector3.new(64, 1, 46), CFrame.new(center + Vector3.new(0, 1, 7)), darkWood, Enum.Material.WoodPlanks)
	part(hall, "BackWall", Vector3.new(64, 17, 3), CFrame.new(center + Vector3.new(0, 9, 29)), stone, Enum.Material.Brick)
	part(hall, "LeftWall", Vector3.new(3, 17, 46), CFrame.new(center + Vector3.new(-31, 9, 7)), stone, Enum.Material.Brick)
	part(hall, "RightWall", Vector3.new(3, 17, 46), CFrame.new(center + Vector3.new(31, 9, 7)), stone, Enum.Material.Brick)
	part(hall, "FrontLeft", Vector3.new(22, 17, 3), CFrame.new(center + Vector3.new(-21, 9, -15)), stone, Enum.Material.Brick)
	part(hall, "FrontRight", Vector3.new(22, 17, 3), CFrame.new(center + Vector3.new(21, 9, -15)), stone, Enum.Material.Brick)
	local roof = part(hall, "TownHallRoof", Vector3.new(68, 2, 50), CFrame.new(center + Vector3.new(0, 18.5, 7)), Color3.fromRGB(68, 68, 71), Enum.Material.Slate)
	roof:SetAttribute("CameraOccluder", true)
	part(hall, "Counter", Vector3.new(34, 4, 4), CFrame.new(center + Vector3.new(0, 3, 21)), wood, Enum.Material.WoodPlanks)
	local crest = part(hall, "TownCrest", Vector3.new(14, 9, 0.5), CFrame.new(center + Vector3.new(0, 11, 27.2)), Color3.fromRGB(76, 42, 52), Enum.Material.Fabric, false)
	addSurfaceText(crest, Enum.NormalId.Front, "WILDFORGE\nHUNTER HALL", Color3.fromRGB(244, 219, 148), Enum.Font.GothamBlack)

	for _, offset in { Vector3.new(-22, 0, -24), Vector3.new(22, 0, -24), Vector3.new(-38, 0, 20), Vector3.new(38, 0, 20) } do
		local post = part(hall, "LanternPost", Vector3.new(0.8, 7, 0.8), CFrame.new(center + offset + Vector3.new(0, 3.5, 0)), darkWood, Enum.Material.Wood)
		local lightPart = part(hall, "Lantern", Vector3.new(1.5, 1.7, 1.5), post.CFrame * CFrame.new(0, 4, 0), Color3.fromRGB(255, 174, 73), Enum.Material.Neon, false)
		local light = Instance.new("PointLight") light.Range = 24 light.Brightness = 2 light.Parent = lightPart
	end

	local board = part(hall, "MissionBoard", Vector3.new(58, 15, 1.3), CFrame.new(center + Vector3.new(0, 8, -31)), darkWood, Enum.Material.WoodPlanks)
	addSurfaceText(board, Enum.NormalId.Front, "HUNTER CONTRACTS", Color3.fromRGB(246, 218, 142), Enum.Font.GothamBlack)

	for index, missionId in MissionData.Order do
		local mission = MissionData.Get(missionId)
		local col = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local x = -21 + col * 14
		local y = 10.7 - row * 6.2
		local sheet = part(hall, `Contract_{missionId}`, Vector3.new(11, 5.1, 0.22), CFrame.new(center + Vector3.new(x, y, -31.78)), paper, Enum.Material.SmoothPlastic, false)
		addSurfaceText(sheet, Enum.NormalId.Front, `[{mission.Rank}]\n{mission.Title}\n{mission.Reward.Gold} GOLD`, Color3.fromRGB(61, 52, 42), Enum.Font.GothamBold)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Accept Contract"
		prompt.ObjectText = `[{mission.Rank}] {mission.Title}`
		prompt.MaxActivationDistance = 11
		prompt.HoldDuration = 0.25
		prompt.RequiresLineOfSight = false
		prompt.Parent = sheet
		prompt.Triggered:Connect(function(player) accept(player, missionId) end)
	end

	local info = part(hall, "MissionInfo", Vector3.new(24, 6, 1), CFrame.new(center + Vector3.new(0, 4, -40)), wood, Enum.Material.WoodPlanks)
	addSurfaceText(info, Enum.NormalId.Front, "TAKE ONE CONTRACT\nCOMPLETE IT • GET PAID\nRETURN FOR ANOTHER", Color3.fromRGB(244, 226, 183), Enum.Font.GothamBold)
	print(string.format("[TownHallMissionService] Hunter Town Hall generated at %.0f, %.0f with %d repeatable contracts.", center.X, center.Z, #MissionData.Order))
end

task.spawn(function()
	-- Generate after villages/spacing settle, but before the randomized castle chooses a location.
	task.wait(2.6)
	buildTownHall(chooseTownCenter())
end)
