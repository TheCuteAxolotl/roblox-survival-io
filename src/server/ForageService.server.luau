local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local InventoryService = require(script.Parent.InventoryService)

local arena = Workspace:WaitForChild("SurvivalArena", 15)
if not arena then return end

local function randomPoint(biome)
	local half = Config.WorldSize / 2
	local xMin, xMax
	if biome == "Snow" then xMin, xMax = -half + 40, -Config.BiomeSplit - 30
	elseif biome == "Desert" then xMin, xMax = Config.BiomeSplit + 30, half - 40
	else xMin, xMax = -Config.BiomeSplit + 30, Config.BiomeSplit - 30 end
	local riverMargin = Config.RiverHalfWidth + 45
	local z = math.random() < 0.5 and math.random(math.floor(-half + 40), math.floor(-riverMargin)) or math.random(math.floor(riverMargin), math.floor(half - 40))
	return Vector3.new(math.random(math.floor(xMin), math.floor(xMax)), 0, z)
end

local function clearPoint(position)
	local hits = Workspace:GetPartBoundsInBox(CFrame.new(position + Vector3.new(0, 2, 0)), Vector3.new(5, 5, 5))
	for _, hit in hits do
		if CollectionService:HasTag(hit, "PlayerBuild") or CollectionService:HasTag(hit, "ResourceCore") then return false end
	end
	return true
end

local function safePoint(biome)
	for _ = 1, 40 do
		local point = randomPoint(biome)
		if clearPoint(point) then return point end
	end
	return randomPoint(biome)
end

local function createNode(kind, biome)
	local position = safePoint(biome)
	local model = Instance.new("Model")
	model.Name = `Forage_{kind}`
	model.Parent = arena
	model:SetAttribute("ForageKind", kind)
	local p = Instance.new("Part")
	p.Name = "Plant"
	p.Anchored = true
	p.CanCollide = false
	p.Size = kind == "CactusFiber" and Vector3.new(1.5, 4, 1.5) or Vector3.new(2.4, 2.4, 2.4)
	p.Position = position + Vector3.new(0, p.Size.Y / 2, 0)
	p.Material = kind == "CactusFiber" and Enum.Material.SmoothPlastic or Enum.Material.Grass
	p.Color = kind == "Herb" and Color3.fromRGB(64, 150, 84) or kind == "WildWheat" and Color3.fromRGB(199, 174, 77) or Color3.fromRGB(74, 135, 74)
	if kind ~= "CactusFiber" then p.Shape = Enum.PartType.Ball end
	p.Parent = model
	model.PrimaryPart = p

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Gather"
	prompt.ObjectText = kind == "Herb" and "Wild Herbs" or kind == "WildWheat" and "Wild Wheat" or "Cactus Fiber"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.2
	prompt.Parent = p
	local available = true
	prompt.Triggered:Connect(function(player)
		if not available then return end
		local drops = kind == "Herb" and { Herb = math.random(1, 2) } or kind == "WildWheat" and { Wheat = math.random(1, 2), WheatSeeds = 1 } or { CactusFiber = math.random(1, 3) }
		for itemName, amount in drops do
			local ok = InventoryService.AddItem(player, itemName, amount)
			if not ok then InventoryService.CreateWorldDrop(p.Position, itemName, amount) end
		end
		available = false
		p.Transparency = 1
		prompt.Enabled = false
		task.delay(28, function()
			if not model.Parent then return end
			local newPosition = safePoint(biome)
			p.Position = newPosition + Vector3.new(0, p.Size.Y / 2, 0)
			p.Transparency = 0
			prompt.Enabled = true
			available = true
		end)
	end)
end

for _ = 1, 20 do createNode("Herb", "Grass") end
for _ = 1, 14 do createNode("WildWheat", "Grass") end
for _ = 1, 8 do createNode("Herb", "Snow") end
for _ = 1, 16 do createNode("CactusFiber", "Desert") end
