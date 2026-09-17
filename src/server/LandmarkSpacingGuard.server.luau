local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local VILLAGE_FOOTPRINT = Vector3.new(78, 16, 82)
local PADDING = 28

local function isMajorLandmark(model)
	if not model:IsA("Model") then return false end
	if model:GetAttribute("VillageBiome") then return true end
	if model:GetAttribute("Dungeon") == true then return true end
	if model:GetAttribute("Cave") == true then return true end
	if model:GetAttribute("DangerZone") == true then return true end
	if model:GetAttribute("Castle") == true then return true end
	if model.Name == "BossArena" then return true end
	return false
end

local function overlaps(centerA, sizeA, centerB, sizeB)
	return math.abs(centerA.X - centerB.X) < (sizeA.X + sizeB.X) / 2 + PADDING
		and math.abs(centerA.Z - centerB.Z) < (sizeA.Z + sizeB.Z) / 2 + PADDING
end

local function clearForVillage(village, center)
	local half = Config.WorldSize / 2
	if math.abs(center.X) + VILLAGE_FOOTPRINT.X / 2 + 18 > half then return false end
	if math.abs(center.Z) + VILLAGE_FOOTPRINT.Z / 2 + 18 > half then return false end
	if math.abs(center.Z) < Config.RiverHalfWidth + VILLAGE_FOOTPRINT.Z / 2 + 22 then return false end

	for _, other in world:GetChildren() do
		if other ~= village and isMajorLandmark(other) then
			local ok, cf, size = pcall(function()
				local boxCf, boxSize = other:GetBoundingBox()
				return boxCf, boxSize
			end)
			if ok and cf and size and overlaps(center, VILLAGE_FOOTPRINT, cf.Position, size) then return false end
		end
	end
	return true
end

local function clearResources(center, radius)
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child.PrimaryPart and child:GetAttribute("Resource") then
			local flat = Vector3.new(child.PrimaryPart.Position.X, 0, child.PrimaryPart.Position.Z)
			if (flat - center).Magnitude < radius then child:Destroy() end
		end
	end
end

local function randomCenterForBiome(biome)
	local half = math.floor(Config.WorldSize / 2 - 80)
	local x
	if biome == "Snow" then
		x = math.random(-half, -Config.BiomeSplit - 65)
	elseif biome == "Desert" then
		x = math.random(Config.BiomeSplit + 65, half)
	else
		x = math.random(-Config.BiomeSplit + 70, Config.BiomeSplit - 70)
	end
	local riverMargin = math.floor(Config.RiverHalfWidth + 90)
	local z = math.random() < 0.5 and math.random(-half, -riverMargin) or math.random(riverMargin, half)
	return Vector3.new(x, 0, z)
end

local function currentCenter(model)
	local ok, cf = pcall(function() return select(1, model:GetBoundingBox()) end)
	return ok and cf and Vector3.new(cf.Position.X, 0, cf.Position.Z) or Vector3.zero
end

local function relocateVillage(village)
	local biome = village:GetAttribute("VillageBiome") or "Grass"
	local oldCenter = currentCenter(village)
	if clearForVillage(village, oldCenter) then return false end

	for _ = 1, 80 do
		local target = randomCenterForBiome(biome)
		if clearForVillage(village, target) then
			local boxCf = select(1, village:GetBoundingBox())
			local pivot = village:GetPivot()
			local offsetX = pivot.Position.X - boxCf.Position.X
			local offsetZ = pivot.Position.Z - boxCf.Position.Z
			local rotation = pivot.Rotation
			village:PivotTo(CFrame.new(target.X + offsetX, pivot.Position.Y, target.Z + offsetZ) * rotation)
			clearResources(target, 58)
			print(string.format("[LandmarkSpacing] Moved %s to %.0f, %.0f to prevent landmark overlap.", village.Name, target.X, target.Z))
			return true
		end
	end
	warn("[LandmarkSpacing] Could not find a clear replacement location for " .. village.Name)
	return false
end

task.spawn(function()
	-- Allow fixed caves/dungeons/forest/boss and randomized villages to exist before resolving conflicts.
	task.wait(2)
	local villages = {}
	for _, child in world:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("VillageBiome") then table.insert(villages, child) end
	end
	for _, village in villages do relocateVillage(village) end
	print("[LandmarkSpacing] Generated landmark spacing pass complete.")
end)
