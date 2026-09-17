local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local PlayerService = require(script.Parent.PlayerService)
local ClanService = require(script.Parent.ClanService)
ClanService.Init()

ItemData.Items.ClanDoor = ItemData.Items.ClanDoor or {
	Category = "Build", Label = "Fortified Door", Cost = ExpansionData.DoorCost, Health = 240,
	PreviewSize = Vector3.new(6, 12, 1.2), PreviewY = 6,
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

local doorAccess = {}

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

local function stateFor(player)
	return {
		ClanTag = ClanService.GetTag(player),
		ClanOwner = ClanService.IsOwner(player),
		DoorAccess = doorAccess[player.UserId] or "OWNER",
	}
end

local function sendState(player, message)
	if player and player.Parent then
		local payload = stateFor(player)
		payload.Message = message
		expansionState:FireClient(player, payload)
	end
end

local function refreshTag(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("ClanTagBillboard")
	if old then old:Destroy() end
	local tag = ClanService.GetTag(player)
	if not tag then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "ClanTagBillboard"
	gui.Size = UDim2.fromOffset(90, 24)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = head
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = `[{tag}]`
	text.TextColor3 = Color3.fromRGB(232, 212, 114)
	text.TextStrokeTransparency = 0.45
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = gui
end

local function canOpenDoor(visitor, ownerUserId)
	if visitor.UserId == ownerUserId then return true end
	local mode = doorAccess[ownerUserId] or "OWNER"
	if mode == "PUBLIC" then return true end
	if mode == "CLAN" then return ClanService.SameClan(visitor.UserId, ownerUserId) end
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
	for _, hit in Workspace:GetPartBoundsInBox(cf, Vector3.new(5.8, 11.8, 1.02), params) do
		if CollectionService:HasTag(hit, "ResourceCore") or CollectionService:HasTag(hit, "PlayerBuild") then return false end
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
	if not PlayerService.Spend(player, ExpansionData.DoorCost) then return false, "Need 35 wood + 12 stone." end

	local model = Instance.new("Model")
	model.Name = "ClanDoor"
	model.Parent = arena
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", "ClanDoor")
	model:SetAttribute("SnapWidth", 6)
	model:SetAttribute("Health", 240)
	model:SetAttribute("MaxHealth", 240)
	model:SetAttribute("Open", false)
	local baseCF = CFrame.new(position.X, 0, position.Z) * CFrame.Angles(0, math.rad(yaw), 0)
	local anchor = part(model, "DoorAnchor", Vector3.new(6, 12, 1.2), baseCF * CFrame.new(0, 6, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1 anchor.CanCollide = false anchor.CanQuery = false model.PrimaryPart = anchor
	part(model, "LeftPost", Vector3.new(0.65, 12, 1.4), baseCF * CFrame.new(-2.7, 6, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	part(model, "RightPost", Vector3.new(0.65, 12, 1.4), baseCF * CFrame.new(2.7, 6, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	part(model, "Top", Vector3.new(6, 0.7, 1.4), baseCF * CFrame.new(0, 11.65, 0), Color3.fromRGB(111, 77, 49), Enum.Material.WoodPlanks)
	local slab = part(model, "Door", Vector3.new(4.8, 10.8, 0.8), baseCF * CFrame.new(0, 5.4, 0), Color3.fromRGB(139, 91, 54), Enum.Material.WoodPlanks)
	local closedCF, openCF = slab.CFrame, slab.CFrame + Vector3.new(0, 11, 0)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open" prompt.ObjectText = "Fortified Door" prompt.MaxActivationDistance = 12 prompt.HoldDuration = 0.1 prompt.Parent = slab
	prompt.Triggered:Connect(function(visitor)
		if not canOpenDoor(visitor, player.UserId) then sendState(visitor, "Door locked: permission denied.") return end
		local opening = model:GetAttribute("Open") ~= true
		model:SetAttribute("Open", opening)
		slab.CanCollide = not opening
		prompt.ActionText = opening and "Close" or "Open"
		TweenService:Create(slab, TweenInfo.new(0.28, Enum.EasingStyle.Quad), { CFrame = opening and openCF or closedCF }):Play()
	end)
	tagBuild(model)
	return true, "Fortified door placed."
end

getExpansionState.OnServerInvoke = stateFor

expansionAction.OnServerEvent:Connect(function(player, actionName, payload)
	local ok, message = false, "Unknown action."
	if actionName == "CreateClan" then ok, message = ClanService.Create(player, payload)
	elseif actionName == "JoinClan" then ok, message = ClanService.Join(player, payload)
	elseif actionName == "LeaveClan" then ok, message = ClanService.Leave(player)
	elseif actionName == "SetDoorAccess" then
		local mode = tostring(payload)
		if table.find(ExpansionData.DoorAccessModes, mode) then doorAccess[player.UserId] = mode ok, message = true, `Door access: {mode}` end
	elseif actionName == "PlaceDoor" then ok, message = createDoor(player) end
	refreshTag(player)
	sendState(player, message)
end)

local function setupPlayer(player)
	doorAccess[player.UserId] = "OWNER"
	player.CharacterAdded:Connect(function()
		task.delay(1, function() if player.Parent then refreshTag(player) sendState(player) end end)
	end)
	task.delay(1.5, function() if player.Parent then refreshTag(player) sendState(player) end end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player) doorAccess[player.UserId] = nil end)
