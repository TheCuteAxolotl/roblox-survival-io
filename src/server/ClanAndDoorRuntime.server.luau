local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ClanService = require(script.Parent.ClanService)
local PlayerService = require(script.Parent.PlayerService)

local folder = ReplicatedStorage:FindFirstChild("ClanRemotes") or Instance.new("Folder")
folder.Name = "ClanRemotes"
folder.Parent = ReplicatedStorage

local command = folder:FindFirstChild("Command") or Instance.new("RemoteEvent")
command.Name = "Command"
command.Parent = folder
local state = folder:FindFirstChild("State") or Instance.new("RemoteEvent")
state.Name = "State"
state.Parent = folder
local getState = folder:FindFirstChild("GetState") or Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = folder

local function send(player, message)
	state:FireClient(player, { Clan = ClanService.GetPublic(player), Message = message })
end

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ownedDoorCount(player)
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not arena then return 0 end
	local count = 0
	for _, model in arena:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("BuildType") == "ClanDoor" and model:GetAttribute("OwnerUserId") == player.UserId then count += 1 end
	end
	return count
end

local function clearPlacement(player, cframe)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local hits = Workspace:GetPartBoundsInBox(cframe, Vector3.new(6.1, 11.8, 1.0), params)
	for _, hit in hits do
		if CollectionService:HasTag(hit, "PlayerBuild") or CollectionService:HasTag(hit, "ResourceCore") then return false end
	end
	return true
end

local function setDoorOpen(model, open)
	local panel = model:FindFirstChild("DoorPanel")
	if not panel or not panel:IsA("BasePart") then return end
	model:SetAttribute("Open", open)
	panel.CanCollide = not open
	panel.Transparency = open and 0.55 or 0
	local prompt = panel:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.ActionText = open and "Close" or "Open" end
end

local function attachDoorPrompt(model)
	local panel = model:FindFirstChild("DoorPanel")
	if not panel then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Base Door"
	prompt.MaxActivationDistance = 11
	prompt.HoldDuration = 0.1
	prompt.Parent = panel
	prompt.Triggered:Connect(function(player)
		if not model.Parent then return end
		local ownerId = model:GetAttribute("OwnerUserId") or 0
		local mode = model:GetAttribute("AccessMode") or "Owner"
		if not ClanService.CanAccessOwnerOrClan(player, ownerId, mode) then
			send(player, `Door locked: {mode} access.`)
			return
		end
		setDoorOpen(model, not model:GetAttribute("Open"))
	end)
end

local function placeDoor(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not root or not arena then return false, "World is not ready." end
	if ownedDoorCount(player) >= 8 then return false, "Door limit reached (8)." end
	if not PlayerService.CanAfford(player, { Wood = 25 }) then return false, "You need 25 wood." end

	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude < 0.1 then forward = Vector3.new(0,0,-1) end
	forward = forward.Unit
	local position = root.Position + forward * 8
	position = Vector3.new(math.floor(position.X + 0.5), 0, math.floor(position.Z + 0.5))
	local yaw = math.atan2(-forward.X, -forward.Z)
	local frame = CFrame.new(position.X, 6, position.Z) * CFrame.Angles(0, yaw, 0)
	if math.abs(position.X) > Config.WorldSize/2 - 6 or math.abs(position.Z) > Config.WorldSize/2 - 6 then return false, "Too close to map edge." end
	if not clearPlacement(player, frame) then return false, "Door space is blocked." end
	if not PlayerService.Spend(player, { Wood = 25 }) then return false, "Not enough wood." end

	local model = Instance.new("Model")
	model.Name = "ClanDoor"
	model:SetAttribute("BuildType", "ClanDoor")
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Health", 180)
	model:SetAttribute("MaxHealth", 180)
	model:SetAttribute("AccessMode", ClanService.GetCode(player) and "Clan" or "Owner")
	model:SetAttribute("Open", false)
	model.Parent = arena

	local left = part(model, "PostL", Vector3.new(1,12,1.4), frame * CFrame.new(-3.5,0,0), Color3.fromRGB(125,82,48))
	local right = part(model, "PostR", Vector3.new(1,12,1.4), frame * CFrame.new(3.5,0,0), Color3.fromRGB(125,82,48))
	local top = part(model, "Top", Vector3.new(8,1,1.4), frame * CFrame.new(0,5.5,0), Color3.fromRGB(125,82,48))
	local panel = part(model, "DoorPanel", Vector3.new(6,10,1.0), frame * CFrame.new(0,-0.5,0), Color3.fromRGB(156,104,61))
	model.PrimaryPart = panel
	for _, p in {left,right,top,panel} do CollectionService:AddTag(p, "PlayerBuild") end
	attachDoorPrompt(model)
	return true, `Door placed • {model:GetAttribute("AccessMode")} access.`
end

local function nearestOwnedDoor(player, maxDistance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not root or not arena then return nil end
	local best, bestDistance
	for _, model in arena:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("BuildType") == "ClanDoor" and model:GetAttribute("OwnerUserId") == player.UserId and model.PrimaryPart then
			local d = (model.PrimaryPart.Position - root.Position).Magnitude
			if d <= (maxDistance or 18) and (not bestDistance or d < bestDistance) then best, bestDistance = model, d end
		end
	end
	return best
end

local function cycleAccess(player)
	local door = nearestOwnedDoor(player, 20)
	if not door then return false, "Stand near one of your doors." end
	local current = door:GetAttribute("AccessMode") or "Owner"
	local nextMode
	if current == "Owner" then
		nextMode = ClanService.GetCode(player) and "Clan" or "Public"
	elseif current == "Clan" then nextMode = "Public"
	else nextMode = "Owner" end
	door:SetAttribute("AccessMode", nextMode)
	return true, `Nearest door access: {nextMode}`
end

getState.OnServerInvoke = function(player)
	return { Clan = ClanService.GetPublic(player) }
end

command.OnServerEvent:Connect(function(player, actionName, payload)
	local ok, message = false, "Unknown clan action."
	if actionName == "Create" then ok, message = ClanService.Create(player, payload)
	elseif actionName == "Join" then ok, message = ClanService.Join(player, payload)
	elseif actionName == "Leave" then ok, message = ClanService.Leave(player)
	elseif actionName == "PlaceDoor" then ok, message = placeDoor(player)
	elseif actionName == "CycleDoorAccess" then ok, message = cycleAccess(player) end
	if ok and (actionName == "Create" or actionName == "Join" or actionName == "Leave") then
		for _, member in Players:GetPlayers() do send(member) end
	else
		send(player, message)
	end
	if message then send(player, message) end
end)

Players.PlayerRemoving:Connect(function(player)
	ClanService.RemovePlayer(player)
end)
