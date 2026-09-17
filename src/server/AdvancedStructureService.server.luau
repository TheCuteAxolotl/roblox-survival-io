local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AdvancedStructureData = require(ReplicatedStorage.Shared.AdvancedStructureData)
local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 20)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
if not world or not remotes then return end

-- Register these builds in the authoritative server ItemData table so the
-- existing structure damage/salvage code understands them too.
for name, data in AdvancedStructureData.Structures do
	ItemData.Items[name] = {
		Category = "Build",
		Label = data.Label,
		Description = data.Description,
		Cost = data.Cost,
		Health = data.Health,
		BuildLimit = data.Limit,
		PreviewSize = data.Footprint,
		PreviewY = data.Footprint.Y / 2,
	}
end

local placeRemote = remotes:FindFirstChild("AdvancedBuildPlace") or Instance.new("RemoteEvent")
placeRemote.Name = "AdvancedBuildPlace"
placeRemote.Parent = remotes
local feedbackRemote = remotes:FindFirstChild("AdvancedBuildFeedback") or Instance.new("RemoteEvent")
feedbackRemote.Name = "AdvancedBuildFeedback"
feedbackRemote.Parent = remotes
local getState = remotes:FindFirstChild("GetAdvancedBuildState") or Instance.new("RemoteFunction")
getState.Name = "GetAdvancedBuildState"
getState.Parent = remotes

local function makePart(parent, name, size, cf, color, material, canCollide)
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
	CollectionService:AddTag(p, "PlayerBuild")
	return p
end

local function countOwned(player, structureName)
	local count = 0
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == player.UserId and child:GetAttribute("BuildType") == structureName then count += 1 end
	end
	return count
end

local function publicState(player)
	local profile = PlayerService.Get(player)
	local counts = {}
	for _, name in AdvancedStructureData.Order do counts[name] = countOwned(player, name) end
	return {
		Wood = profile and math.floor(profile.Wood or 0) or 0,
		Stone = profile and math.floor(profile.Stone or 0) or 0,
		Forge = profile and math.floor(profile.Age or 1) or 1,
		Counts = counts,
	}
end
getState.OnServerInvoke = publicState

local function landmarkAncestor(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	while model and model ~= world do
		if model:GetAttribute("VillageBiome") ~= nil or model:GetAttribute("Dungeon") == true or model:GetAttribute("Cave") == true or model:GetAttribute("Castle") == true or model:GetAttribute("TownHall") == true or model:GetAttribute("DangerZone") == true or model.Name == "BossArena" then return model end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model") or nil
	end
	return nil
end

local function placementPosition(player, data)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if look.Magnitude < 0.1 then look = Vector3.new(0,0,-1) end
	look = look.Unit
	local distance = math.max(9, data.Footprint.Z / 2 + 6)
	local raw = root.Position + look * distance
	return Vector3.new(math.floor(raw.X + 0.5), data.PlacementY or 0, math.floor(raw.Z + 0.5)), math.atan2(-look.X, -look.Z)
end

local function placementClear(player, data, position, yaw)
	local half = Config.WorldSize / 2
	if math.abs(position.X) + data.Footprint.X / 2 + 4 > half or math.abs(position.Z) + data.Footprint.Z / 2 + 4 > half then return false, "Too close to the edge of the world." end
	if math.abs(position.Z) < Config.RiverHalfWidth + data.Footprint.Z / 2 + 5 then return false, "Build away from the river." end
	local cf = CFrame.new(position.X, position.Y + data.Footprint.Y / 2, position.Z) * CFrame.Angles(0, yaw, 0)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	for _, hit in Workspace:GetPartBoundsInBox(cf, data.Footprint + Vector3.new(1,1,1), params) do
		if CollectionService:HasTag(hit, "PlayerBuild") then return false, "That would overlap another structure." end
		if CollectionService:HasTag(hit, "ResourceCore") then return false, "Clear the nearby resource first." end
		if landmarkAncestor(hit) then return false, "Major landmarks cannot be built over." end
	end
	return true
end

local function buildVisual(structureName, position, yaw)
	local model = Instance.new("Model")
	model.Name = structureName
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local wood = Color3.fromRGB(116, 81, 52)
	local dark = Color3.fromRGB(78, 59, 47)
	local stone = Color3.fromRGB(103, 106, 111)
	local metal = Color3.fromRGB(81, 84, 91)

	if structureName == "WoodFloor" then
		local base = makePart(model, "Floor", Vector3.new(12, 1, 12), cf * CFrame.new(0, 0.5, 0), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for _, z in { -4, 0, 4 } do makePart(model, "FloorBrace", Vector3.new(11.5, 0.35, 0.45), cf * CFrame.new(0, 1.05, z), dark, Enum.Material.Wood) end
	elseif structureName == "Fence" then
		local base = makePart(model, "FenceRail", Vector3.new(10, 0.55, 0.55), cf * CFrame.new(0, 2.5, 0), wood, Enum.Material.Wood)
		model.PrimaryPart = base
		makePart(model, "FenceRail", Vector3.new(10, 0.55, 0.55), cf * CFrame.new(0, 1.2, 0), wood, Enum.Material.Wood)
		for _, x in { -4.5, 0, 4.5 } do makePart(model, "FencePost", Vector3.new(0.7, 4, 0.7), cf * CFrame.new(x, 2, 0), dark, Enum.Material.Wood) end
	elseif structureName == "DoorFrame" then
		local base = makePart(model, "DoorThreshold", Vector3.new(12, 0.7, 2), cf * CFrame.new(0, 0.35, 0), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		makePart(model, "DoorPost", Vector3.new(2.2, 10, 2), cf * CFrame.new(-4.9, 5, 0), wood, Enum.Material.WoodPlanks)
		makePart(model, "DoorPost", Vector3.new(2.2, 10, 2), cf * CFrame.new(4.9, 5, 0), wood, Enum.Material.WoodPlanks)
		makePart(model, "DoorHeader", Vector3.new(12, 2, 2), cf * CFrame.new(0, 9, 0), dark, Enum.Material.Wood)
	elseif structureName == "Stairs" then
		local base = makePart(model, "StairBase", Vector3.new(8, 0.8, 2), cf * CFrame.new(0, 0.4, 5), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for i = 0, 5 do
			local y = 0.5 + i * 1.05
			local z = 5 - i * 2
			makePart(model, "Step", Vector3.new(8, 1, 2.2), cf * CFrame.new(0, y, z), wood, Enum.Material.WoodPlanks)
		end
	elseif structureName == "RaisedPlatform" then
		local base = makePart(model, "PlatformDeck", Vector3.new(12, 1, 12), cf * CFrame.new(0, 7, 0), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for _, x in { -5, 5 } do
			for _, z in { -5, 5 } do
				makePart(model, "PlatformSupport", Vector3.new(1, 7, 1), cf * CFrame.new(x, 3.5, z), dark, Enum.Material.Wood)
			end
		end
	elseif structureName == "WoodRoof" then
		local base = makePart(model, "Roof", Vector3.new(12, 1, 12), cf * CFrame.new(0, 0.5, 0), dark, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for _, x in { -5.4, 5.4 } do makePart(model, "RoofTrim", Vector3.new(0.45, 1.5, 12), cf * CFrame.new(x, 0.5, 0), wood, Enum.Material.Wood) end
	elseif structureName == "Barricade" then
		local base = makePart(model, "Barricade", Vector3.new(11, 5.5, 1.8), cf * CFrame.new(0, 2.75, 0), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for x = -4, 4, 2 do makePart(model, "Brace", Vector3.new(0.7, 6.8, 0.7), cf * CFrame.new(x, 2.8, 0) * CFrame.Angles(0,0,math.rad(x < 0 and -11 or 11)), dark, Enum.Material.Wood) end
	elseif structureName == "WarBrazier" then
		local base = makePart(model, "BrazierBase", Vector3.new(3.8, 0.8, 3.8), cf * CFrame.new(0,0.4,0), stone, Enum.Material.Slate)
		model.PrimaryPart = base
		makePart(model, "Post", Vector3.new(0.9,5.5,0.9), cf * CFrame.new(0,3.2,0), metal, Enum.Material.Metal)
		local bowl = makePart(model, "Bowl", Vector3.new(3.2,0.9,3.2), cf * CFrame.new(0,6.2,0), metal, Enum.Material.Metal)
		local flame = makePart(model, "Flame", Vector3.new(1.8,2.3,1.8), cf * CFrame.new(0,7.5,0), Color3.fromRGB(255,137,43), Enum.Material.Neon, false)
		flame.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight") light.Range = 30 light.Brightness = 2.8 light.Shadows = true light.Parent = flame
	elseif structureName == "Watchtower" or structureName == "BallistaTower" then
		local base = makePart(model, "TowerBase", Vector3.new(13,1,13), cf * CFrame.new(0,0.5,0), wood, Enum.Material.WoodPlanks)
		model.PrimaryPart = base
		for _, x in { -5, 5 } do for _, z in { -5, 5 } do makePart(model, "Support", Vector3.new(1.2,14,1.2), cf * CFrame.new(x,7,z), dark, Enum.Material.Wood) end end
		makePart(model, "Platform", Vector3.new(14,1,14), cf * CFrame.new(0,14,0), wood, Enum.Material.WoodPlanks)
		local ladder = Instance.new("TrussPart")
		ladder.Name = "TowerLadder" ladder.Size = Vector3.new(2,13,1) ladder.CFrame = cf * CFrame.new(0,7,6.3) ladder.Anchored = true ladder.Color = dark ladder.Material = Enum.Material.Wood ladder.Parent = model CollectionService:AddTag(ladder,"PlayerBuild")
		for _, x in { -6,6 } do makePart(model,"Rail",Vector3.new(0.7,3,13),cf*CFrame.new(x,16,0),dark,Enum.Material.Wood) end
		for _, z in { -6,6 } do makePart(model,"Rail",Vector3.new(13,3,0.7),cf*CFrame.new(0,16,z),dark,Enum.Material.Wood) end
		if structureName == "BallistaTower" then
			makePart(model,"BallistaBase",Vector3.new(4.5,1.2,4.5),cf*CFrame.new(0,15.1,0),metal,Enum.Material.Metal)
			makePart(model,"BallistaArm",Vector3.new(9,0.7,0.7),cf*CFrame.new(0,16,0),dark,Enum.Material.Wood)
			makePart(model,"BallistaBolt",Vector3.new(0.35,0.35,7),cf*CFrame.new(0,16,-3.5),Color3.fromRGB(165,165,169),Enum.Material.Metal,false)
		end
	elseif structureName == "StoneGate" then
		local base = makePart(model, "GateBase", Vector3.new(18,1,4), cf * CFrame.new(0,0.5,0), stone, Enum.Material.Slate)
		model.PrimaryPart = base
		makePart(model,"GatePillar",Vector3.new(4.5,14,4),cf*CFrame.new(-6.75,7,0),stone,Enum.Material.Brick)
		makePart(model,"GatePillar",Vector3.new(4.5,14,4),cf*CFrame.new(6.75,7,0),stone,Enum.Material.Brick)
		makePart(model,"GateArch",Vector3.new(18,4,4),cf*CFrame.new(0,12,0),stone,Enum.Material.Brick)
	end
	return model
end

local function place(player, structureName)
	local data = AdvancedStructureData.Structures[structureName]
	if not data then feedbackRemote:FireClient(player, "Unknown structure.") return end
	local profile = PlayerService.Get(player)
	if not profile then feedbackRemote:FireClient(player, "Profile is still loading.") return end
	if (profile.Age or 1) < data.MinForge then feedbackRemote:FireClient(player, `Requires Forge Level {data.MinForge}.`) return end
	if countOwned(player, structureName) >= data.Limit then feedbackRemote:FireClient(player, `Build limit reached ({data.Limit}).`) return end
	if not PlayerService.CanAfford(player, data.Cost) then feedbackRemote:FireClient(player, "Not enough wood or stone.") return end
	local position, yaw = placementPosition(player, data)
	if not position then return end
	local clear, reason = placementClear(player, data, position, yaw)
	if not clear then feedbackRemote:FireClient(player, reason) return end
	if not PlayerService.Spend(player, data.Cost) then return end
	local model = buildVisual(structureName, position, yaw)
	if not model or not model.PrimaryPart then
		PlayerService.Add(player, data.Cost)
		feedbackRemote:FireClient(player, "That structure failed to build; resources refunded.")
		return
	end
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BuildType", structureName)
	model:SetAttribute("AdvancedStructure", true)
	model:SetAttribute("Health", data.Health)
	model:SetAttribute("MaxHealth", data.Health)
	model.Parent = world
	feedbackRemote:FireClient(player, `${data.Label} placed.`, publicState(player))
end

placeRemote.OnServerEvent:Connect(function(player, structureName)
	if type(structureName) == "string" then place(player, structureName) end
end)

local function nearestMob(position, range)
	local best, bestDistance = nil, range
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute("SurvivalMob") == true and descendant.PrimaryPart then
			local hum = descendant:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local distance = (descendant.PrimaryPart.Position - position).Magnitude
				if distance < bestDistance then best, bestDistance = descendant, distance end
			end
		end
	end
	return best
end

local function boltFX(origin, target)
	local delta = target - origin
	if delta.Magnitude < 0.1 then return end
	local p = Instance.new("Part")
	p.Name = "BallistaTracer" p.Anchored = true p.CanCollide = false p.CanQuery = false p.Material = Enum.Material.Neon p.Color = Color3.fromRGB(231,201,137)
	p.Size = Vector3.new(0.18,0.18,delta.Magnitude) p.CFrame = CFrame.lookAt(origin + delta/2, target) p.Parent = Workspace
	Debris:AddItem(p,0.12)
end

task.spawn(function()
	while true do
		task.wait(0.25)
		local now = os.clock()
		for _, tower in world:GetChildren() do
			if not tower:IsA("Model") or tower:GetAttribute("BuildType") ~= "BallistaTower" or not tower.PrimaryPart then continue end
			if now < (tower:GetAttribute("NextBallistaShot") or 0) then continue end
			local data = AdvancedStructureData.Structures.BallistaTower
			local target = nearestMob(tower.PrimaryPart.Position, data.Range)
			if target and target.PrimaryPart then
				local owner = Players:GetPlayerByUserId(tower:GetAttribute("OwnerUserId") or 0)
				if owner then
					tower:SetAttribute("NextBallistaShot", now + data.Cooldown)
					boltFX(tower.PrimaryPart.Position + Vector3.new(0,16,0), target.PrimaryPart.Position)
					MobService.Damage(target, owner, data.Damage)
				end
			end
		end
	end
end)

print("[AdvancedStructures] Modular floors, roofs, fences, doorways, stairs, platforms and defensive structures online.")
