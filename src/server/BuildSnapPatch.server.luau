local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local BuildService = require(script.Parent.BuildService)

local originalCanPlace = BuildService.CanPlace
local originalPlaceBuild = BuildService.PlaceBuild
local BUILD_TAG = "PlayerBuild"
local RESOURCE_CORE_TAG = "ResourceCore"

local function wallLike(buildType)
	return buildType == "Wall" or buildType == "StoneWall"
end

local function requestedRight(rotation)
	local cf = CFrame.Angles(0, math.rad(rotation or 0), 0)
	return cf.RightVector
end

local function existingWidth(model)
	local custom = model:GetAttribute("SnapWidth")
	if type(custom) == "number" and custom > 0 then return custom end
	local buildType = model:GetAttribute("BuildType")
	local item = buildType and ItemData.Items[buildType]
	if item and item.PreviewSize then return item.PreviewSize.X end
	return model.PrimaryPart and model.PrimaryPart.Size.X or 10
end

local function snapPosition(position, buildType, rotation)
	if not wallLike(buildType) then return position end
	local arena = Workspace:FindFirstChild("SurvivalArena")
	if not arena then return position end
	local item = ItemData.Items[buildType]
	local width = item and item.PreviewSize and item.PreviewSize.X or 10
	local newRight = requestedRight(rotation)
	local best = position
	local bestDistance = 3.6

	for _, model in arena:GetChildren() do
		if not model:IsA("Model") or not model.PrimaryPart then continue end
		local existingType = model:GetAttribute("BuildType")
		if existingType ~= "Wall" and existingType ~= "StoneWall" and existingType ~= "ClanDoor" then continue end
		local p = model.PrimaryPart
		local right = p.CFrame.RightVector
		local half = existingWidth(model) / 2
		for _, existingEnd in { p.Position + right * half, p.Position - right * half } do
			for _, sign in { -1, 1 } do
				local candidate = existingEnd + newRight * (width / 2) * sign
				candidate = Vector3.new(candidate.X, position.Y, candidate.Z)
				local distance = (Vector3.new(candidate.X, 0, candidate.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = candidate
				end
			end
		end
	end
	return best
end

local function customWallCanPlace(player, buildType, rawPosition, rotation)
	local item = ItemData.Items[buildType]
	if not item then return false, "Unknown building." end
	if typeof(rawPosition) ~= "Vector3" then return false, "Invalid placement." end
	local position = snapPosition(rawPosition, buildType, rotation)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false, "Character is not ready." end
	local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)
	local flatPosition = Vector3.new(position.X, 0, position.Z)
	if (flatRoot - flatPosition).Magnitude > Config.BuildDistance then return false, "Place it closer to you." end

	local size = item.PreviewSize or Vector3.new(10, 12, 1.2)
	local half = Config.WorldSize / 2
	if math.abs(position.X) > half - size.X / 2 - 4 or math.abs(position.Z) > half - size.X / 2 - 4 then return false, "Outside the map." end
	if math.abs(position.Z) < Config.RiverHalfWidth + size.Z / 2 + Config.RiverNoBuildPadding then return false, "You cannot build in the river or on its banks." end
	if item.BuildLimit and BuildService.CountOwned(player, buildType) >= item.BuildLimit then return false, `Build limit reached ({item.BuildLimit}).` end

	local y = item.PreviewY or size.Y / 2
	local cf = CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, math.rad(rotation or 0), 0)
	-- Shrink the footprint slightly. Exact edge contact is allowed; true overlap is not.
	local querySize = Vector3.new(math.max(0.2, size.X - 0.18), math.max(2, size.Y - 0.1), math.max(0.2, size.Z - 0.18))
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	for _, hit in Workspace:GetPartBoundsInBox(cf, querySize, params) do
		if CollectionService:HasTag(hit, RESOURCE_CORE_TAG) then
			local resource = hit:FindFirstAncestorOfClass("Model")
			if not resource or resource:GetAttribute("Alive") ~= false then return false, "Move it away from the tree or rock." end
		end
		if CollectionService:HasTag(hit, BUILD_TAG) then return false, "That would overlap another building." end
	end
	return true
end

BuildService.CanPlace = function(player, buildType, position, rotation)
	if wallLike(buildType) then return customWallCanPlace(player, buildType, position, rotation) end
	return originalCanPlace(player, buildType, position, rotation)
end

BuildService.PlaceBuild = function(player, buildType, position, rotation)
	if wallLike(buildType) and typeof(position) == "Vector3" then position = snapPosition(position, buildType, rotation) end
	return originalPlaceBuild(player, buildType, position, rotation)
end
