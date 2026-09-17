local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FADE_TO = 0.78
local UPDATE_INTERVAL = 0.06
local NEARBY_CUTAWAY_RADIUS = 34
local OBSTRUCTION_OUTLINE_TRANSPARENCY = 0.2

local faded = {}
local elapsed = 0
local highlight = nil

local FLOOR_NAMES = {
	Floor = true,
	ArenaFloor = true,
	VillageSquare = true,
	Foundation = true,
	RiverBed = true,
	RiverWater = true,
	Bridge = true,
	Soil = true,
	Base = false,
}

local function getCharacterParts()
	local character = player.Character
	if not character then return nil, nil, nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	return character, root, head
end

local function ensureHighlight(character)
	if highlight and highlight.Parent == character then return highlight end
	if highlight then highlight:Destroy() end
	highlight = Instance.new("Highlight")
	highlight.Name = "LocalOcclusionOutline"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.88
	highlight.OutlineColor = Color3.fromRGB(255, 239, 169)
	highlight.OutlineTransparency = OBSTRUCTION_OUTLINE_TRANSPARENCY
	highlight.Enabled = false
	highlight.Parent = character
	return highlight
end

local function shouldNeverFade(part, root)
	if not part:IsA("BasePart") then return true end
	if part.Transparency >= 0.98 then return true end
	if FLOOR_NAMES[part.Name] == true then return true end
	if part.Name == "LocalBuildPreview" or part.Name == "ProjectileTracer" or part.Name == "LocalSwing" then return true end
	if root and part.Position.Y <= root.Position.Y + 0.75 and part.Size.Y <= 3 then return true end
	return false
end

local function setFaded(part, targetSet)
	if targetSet[part] or not part:IsA("BasePart") then return end
	targetSet[part] = true
	if faded[part] == nil then faded[part] = part.LocalTransparencyModifier end
	part.LocalTransparencyModifier = math.max(part.LocalTransparencyModifier, FADE_TO)
end

local function maybeExpandCutaway(hit, root, targetSet)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then return end
	local isInterior = model:GetAttribute("Dungeon") == true or model:GetAttribute("Cave") == true or model:GetAttribute("VillageBiome") ~= nil
	local hitName = string.lower(hit.Name)
	local isRoofLike = string.find(hitName, "roof", 1, true) ~= nil or string.find(hitName, "ceiling", 1, true) ~= nil
	if not isInterior and not isRoofLike then return end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and not shouldNeverFade(descendant, root) then
			local lower = string.lower(descendant.Name)
			local structural = string.find(lower, "roof", 1, true)
				or string.find(lower, "ceiling", 1, true)
				or string.find(lower, "wall", 1, true)
				or lower == "back"
				or lower == "left"
				or lower == "right"
			if structural then
				local flat = Vector3.new(descendant.Position.X - root.Position.X, 0, descendant.Position.Z - root.Position.Z)
				if flat.Magnitude <= NEARBY_CUTAWAY_RADIUS and descendant.Position.Y > root.Position.Y + 1.5 then
					setFaded(descendant, targetSet)
				end
			end
		end
	end
end

local function restoreUnused(targetSet)
	for part, original in faded do
		if not part.Parent then
			faded[part] = nil
		elseif not targetSet[part] then
			part.LocalTransparencyModifier = original
			faded[part] = nil
		end
	end
end

local function updateOcclusion()
	local camera = Workspace.CurrentCamera
	local character, root, head = getCharacterParts()
	if not camera or not character or not root then
		restoreUnused({})
		if highlight then highlight.Enabled = false end
		return
	end

	local outline = ensureHighlight(character)
	local center = (head and head.Position or root.Position + Vector3.new(0, 2, 0))
	local points = {
		center,
		center + Vector3.new(1.5, 0, 0),
		center + Vector3.new(-1.5, 0, 0),
		center + Vector3.new(0, 0, 1.5),
		center + Vector3.new(0, 0, -1.5),
	}

	local ignore = { character }
	local preview = Workspace:FindFirstChild("LocalBuildPreview")
	if preview then table.insert(ignore, preview) end

	local targetSet = {}
	local ok, obscuring = pcall(function()
		return camera:GetPartsObscuringTarget(points, ignore)
	end)

	if ok and type(obscuring) == "table" then
		for _, part in obscuring do
			if not shouldNeverFade(part, root) then
				setFaded(part, targetSet)
				maybeExpandCutaway(part, root, targetSet)
			end
		end
	end

	restoreUnused(targetSet)
	outline.Enabled = next(targetSet) ~= nil
end

RunService:BindToRenderStep("WildforgeTopDownOcclusion", Enum.RenderPriority.Camera.Value + 8, function(dt)
	elapsed += dt
	if elapsed < UPDATE_INTERVAL then return end
	elapsed = 0
	updateOcclusion()
end)

player.CharacterRemoving:Connect(function()
	restoreUnused({})
	if highlight then highlight:Destroy() highlight = nil end
end)
