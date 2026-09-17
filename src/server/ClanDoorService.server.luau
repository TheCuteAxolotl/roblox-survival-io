local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local PlayerService = require(script.Parent.PlayerService)

-- Register expansion structures on the server so existing structure damage/salvage logic recognizes them.
ItemData.Items.ClanDoor = ItemData.Items.ClanDoor or {
	Category = "Build", Label = "Fortified Door", Cost = ExpansionData.DoorCost, Health = 220,
	PreviewSize = Vector3.new(6, 12, 1.2), PreviewY = 6,
}
ItemData.Items.SpawnPad = ItemData.Items.SpawnPad or {
	Category = "Build", Label = "Spawn Pad", Cost = ExpansionData.SpawnPadCost, Health = 180,
	PreviewSize = Vector3.new(8, 1, 8), PreviewY = 0.5, BuildLimit = 1,
}

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local expansionAction = remotes:FindFirstChild("ExpansionAction") or Instance.new("RemoteEvent")
expansionAction.Name = "ExpansionAction"
expansionAction.Parent = remotes
local expansionState = remotes:FindFirstChild("ExpansionState") or Instance.new("RemoteEvent")
expansionState.Name = "ExpansionState"
expansionState.Parent = remotes
local getExpansionState = remotes:FindFirstChild("GetExpansionState") or Instance.new("RemoteFunction")
getExpansionState.Name = "GetExpansionState"
getExpansionState.Parent = remotes

local clans = {}
local playerClan = {}
local doorAccess = {}
local spawnChoice = {}
local spawnPads = {}

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function clanKey(name)
	return string.lower((name or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clanDisplayFor(player)
	local key = playerClan[player.UserId]
	local clan = key and clans[key]
	return clan and clan.Name or nil
end

local function isClanOwner(player)
	local key = playerClan[player.UserId]
	local clan = key and clans[key]
	return clan and clan.OwnerUserId == player.UserId or false
end

local function stateFor(player)
	local profile = PlayerService.Get(player)
	local age = profile and profile.Age or 1
	local choice = spawnChoice[player.UserId]
	return {
		Clan = clanDisplayFor(player),
		ClanOwner = isClanOwner(player),
		DoorAccess = doorAccess[player.UserId] or "OWNER",
		SpawnPadUnlocked = choice == "UNLOCKED",
		SpawnChoiceAvailable = age >= ExpansionData.SpawnUnlockAge and choice == nil,
		SpawnPadPlaced = spawnPads[player.UserId] and spawnPads[player.UserId].Parent ~= nil or false,
	}
end

local function sendState(player, message)
	if player.Parent then
		local payload = stateFor(player)
		payload.Message = message
		expansionState:FireClient(player, payload)
	end
end

local function sendClanMembers(key, message)
	local clan = clans[key]
	if not clan then return end
	for userId in clan.Members do
		local member = Players:GetPlayerByUserId(userId)
		if member then sendState(member, message) end
	end
end

local function cleanName(raw)
	if type(raw) ~= "string" then return nil end
	local value = raw:gsub("^%s+", ""):gsub("%s+$", "")
	if #value < 3 or #value > 16 then return nil end
	if not value:match("^[%w _%-]+$") then return nil end
	return value
end

local function sameClan(aUserId, bUserId)
	local a = playerClan[aUserId]
	return a ~= nil and a == playerClan[bUserId]
end

local function canOpenDoor(player, ownerUserId)
	if player.UserId == ownerUserId then return true end
	local mode = doorAccess[ownerUserId] or "OWNER"
	if mode == "PUBLIC" then return true end
	if mode == "CLAN" and sameClan(player.UserId, ownerUserId) then return true end
	return false
end

local function tagBuild(model)
	for _, d in model:GetDescendants() do if d:IsA("BasePart") then CollectionService:AddTag(d, "PlayerBuild") end end
end

local function wallEndpointSnap(raw, width)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not arena then return raw, 0 end
	local bestPos, bestYaw, bestDistance = raw, 0, 4.5
	for _, model in arena:GetChildren() do
		if not model:IsA("Model") or not model.PrimaryPart then continue end
		local t = model:GetAttribute("BuildType")
		if t ~= "Wall" and t ~= "StoneWall" and t ~= "ClanDoor" then continue end
		local p = model.PrimaryPart
		local existingWidth = model:GetAttribute("SnapWidth") or p.Size.X
		local right = p.CFrame.RightVector
		local yaw = math.deg(math.atan2(-p.CFrame.LookVector.X, -p.CFrame.LookVector.Z))
		for _, endpoint in { p.Position + right * existingWidth / 2, p.Position - right * existingWidth / 2 } do
			for _, sign in { -1, 1 } do
				local candidate = endpoint + right * width / 2 * sign
				candidate = Vector3.new(candidate.X, 0, candidate.Z)
				local distance = (candidate - Vector3.new(raw.X, 0, raw.Z)).Magnitude
				if distance < bestDistance then bestPos, bestYaw, bestDistance = candidate, yaw, distance end
			end
		end
	end
	return bestPos, bestYaw
end

local function clearDoorPosition(player, position, yaw)
	local cf = CFrame.new(position.X, 6, position.Z) * CFrame.Angles(0, math.rad(yaw), 0)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	for _, hit in Workspace:GetPartBoundsInBox(cf, Vector3.new(5.82, 11.8, 1.02), params) do
		if CollectionService:HasTag(hit, "ResourceCore") then return false end
		if CollectionService:HasTag(hit, "PlayerBuild") then return false end
	end
	return true
end

local function createDoor(player)
	local profile = PlayerService.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not profile or not root or not arena then return false, "World is not ready." end
	local raw = root.Position + Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) * 8
	local position, yaw = wallEndpointSnap(raw, 6)
	if (Vector3.new(root.Position.X, 0, root.Position.Z) - position).Magnitude > 26 then return false, "Place the door closer to you." end
	if not clearDoorPosition(player, position, yaw) then return false, "That door spot is blocked." end
	if not PlayerService.Spend(player, ExpansionData.DoorCost) then return false, "Need 25 wood + 5 stone." end

	local model = Instance.new("Model")
	model.Name = "ClanDoor"
	model.Parent = arena
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", "ClanDoor")
	model:SetAttribute("SnapWidth", 6)
	model:SetAttribute("Health", 220)
	model:SetAttribute("MaxHealth", 220)
	model:SetAttribute("Open", false)
	local baseCF = CFrame.new(position.X, 0, position.Z) * CFrame.Angles(0, math.rad(yaw), 0)
	local anchor = part(model, "DoorAnchor", Vector3.new(6, 12, 1.2), baseCF * CFrame.new(0, 6, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	model.PrimaryPart = anchor
	part(model, "LeftPost", Vector3.new(0.65, 12, 1.4), baseCF * CFrame.new(-2.7, 6, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	part(model, "RightPost", Vector3.new(0.65, 12, 1.4), baseCF * CFrame.new(2.7, 6, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	part(model, "Top", Vector3.new(6, 0.7, 1.4), baseCF * CFrame.new(0, 11.65, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	local slab = part(model, "Door", Vector3.new(4.8, 10.8, 0.8), baseCF * CFrame.new(0, 5.4, 0), Color3.fromRGB(139, 91, 54), Enum.Material.WoodPlanks)
	local closedCF = slab.CFrame
	local openCF = closedCF + Vector3.new(0, 11, 0)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Fortified Door"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.1
	prompt.Parent = slab
	prompt.Triggered:Connect(function(visitor)
		if not canOpenDoor(visitor, player.UserId) then
			sendState(visitor, "Door locked: you do not have permission.")
			return
		end
		local opening = model:GetAttribute("Open") ~= true
		model:SetAttribute("Open", opening)
		slab.CanCollide = not opening
		prompt.ActionText = opening and "Close" or "Open"
		TweenService:Create(slab, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { CFrame = opening and openCF or closedCF }):Play()
	end)
	tagBuild(model)
	return true, "Fortified door placed."
end

local function createSpawnPad(player)
	if spawnChoice[player.UserId] ~= "UNLOCKED" then return false, "Spawn Pad is not unlocked." end
	if spawnPads[player.UserId] and spawnPads[player.UserId].Parent then return false, "You already have a spawn pad." end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not root or not arena then return false, "World is not ready." end
	if not PlayerService.Spend(player, ExpansionData.SpawnPadCost) then return false, "Need 45 wood + 30 stone." end
	local pos = root.Position + Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) * 8
	pos = Vector3.new(math.floor(pos.X + 0.5), 0, math.floor(pos.Z + 0.5))
	local model = Instance.new("Model")
	model.Name = "SpawnPad"
	model.Parent = arena
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", "SpawnPad")
	model:SetAttribute("Health", 180)
	model:SetAttribute("MaxHealth", 180)
	local pad = part(model, "Pad", Vector3.new(8, 0.8, 8), CFrame.new(pos + Vector3.new(0, 0.4, 0)), Color3.fromRGB(78, 138, 174), Enum.Material.Metal)
	model.PrimaryPart = pad
	local glow = part(model, "Glow", Vector3.new(6.6, 0.16, 6.6), CFrame.new(pos + Vector3.new(0, 0.88, 0)), Color3.fromRGB(87, 218, 255), Enum.Material.Neon)
	glow.CanCollide = false
	tagBuild(model)
	spawnPads[player.UserId] = model
	return true, "Spawn pad placed. You will respawn here while it survives."
end

local function createClan(player, rawName)
	if playerClan[player.UserId] then return false, "Leave your current clan first." end
	local name = cleanName(rawName)
	if not name then return false, "Clan name must be 3–16 letters/numbers/spaces." end
	local key = clanKey(name)
	if clans[key] then return false, "That clan name already exists." end
	clans[key] = { Name = name, OwnerUserId = player.UserId, Members = { [player.UserId] = true } }
	playerClan[player.UserId] = key
	return true, `Created clan {name}.`
end

local function joinClan(player, rawName)
	if playerClan[player.UserId] then return false, "Leave your current clan first." end
	local key = clanKey(rawName)
	local clan = clans[key]
	if not clan then return false, "Clan not found in this server." end
	clan.Members[player.UserId] = true
	playerClan[player.UserId] = key
	sendClanMembers(key, `{player.Name} joined {clan.Name}.`)
	return true, `Joined {clan.Name}.`
end

local function leaveClan(player)
	local key = playerClan[player.UserId]
	local clan = key and clans[key]
	if not clan then return false, "You are not in a clan." end
	clan.Members[player.UserId] = nil
	playerClan[player.UserId] = nil
	if clan.OwnerUserId == player.UserId then
		local newOwner = next(clan.Members)
		if newOwner then clan.OwnerUserId = newOwner else clans[key] = nil end
	end
	if clans[key] then sendClanMembers(key, `${player.Name} left the clan.`) end
	return true, "Left clan."
end

getExpansionState.OnServerInvoke = stateFor

expansionAction.OnServerEvent:Connect(function(player, actionName, payload)
	local ok, message = false, "Unknown action."
	if actionName == "CreateClan" then ok, message = createClan(player, payload)
	elseif actionName == "JoinClan" then ok, message = joinClan(player, payload)
	elseif actionName == "LeaveClan" then ok, message = leaveClan(player)
	elseif actionName == "SetDoorAccess" then
		local mode = tostring(payload)
		if table.find(ExpansionData.DoorAccessModes, mode) then doorAccess[player.UserId] = mode ok, message = true, `Door access: {mode}` end
	elseif actionName == "PlaceDoor" then ok, message = createDoor(player)
	elseif actionName == "UnlockSpawnPad" then
		local profile = PlayerService.Get(player)
		if profile and profile.Age >= ExpansionData.SpawnUnlockAge and spawnChoice[player.UserId] == nil then spawnChoice[player.UserId] = "UNLOCKED" ok, message = true, "Spawn Pad unlocked." end
	elseif actionName == "SkipSpawnPad" then
		local profile = PlayerService.Get(player)
		if profile and profile.Age >= ExpansionData.SpawnUnlockAge and spawnChoice[player.UserId] == nil then spawnChoice[player.UserId] = "SKIPPED" ok, message = true, "Spawn Pad skipped for this run." end
	elseif actionName == "PlaceSpawnPad" then ok, message = createSpawnPad(player)
	end
	sendState(player, message)
end)

local function hookCharacter(player, character)
	task.delay(0.35, function()
		local pad = spawnPads[player.UserId]
		if not pad or not pad.Parent or not pad.PrimaryPart or not character.Parent then return end
		character:PivotTo(pad.PrimaryPart.CFrame + Vector3.new(0, 4, 0))
	end)
end

local function setupPlayer(player)
	doorAccess[player.UserId] = doorAccess[player.UserId] or "OWNER"
	player.CharacterAdded:Connect(function(character) hookCharacter(player, character) end)
	if player.Character then hookCharacter(player, player.Character) end
	task.delay(1, function() if player.Parent then sendState(player) end end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

Players.PlayerRemoving:Connect(function(player)
	local key = playerClan[player.UserId]
	if key and clans[key] then
		clans[key].Members[player.UserId] = nil
		if clans[key].OwnerUserId == player.UserId then
			local replacement = next(clans[key].Members)
			if replacement then clans[key].OwnerUserId = replacement else clans[key] = nil end
		end
	end
	playerClan[player.UserId] = nil
	doorAccess[player.UserId] = nil
	spawnChoice[player.UserId] = nil
	spawnPads[player.UserId] = nil
end)
