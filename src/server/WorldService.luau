local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldService = {}
local arena = nil

local RESOURCE_TAG = "SurvivalResource"
local BUILD_TAG = "PlayerBuild"

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function makeResource(kind, position)
	local model = Instance.new("Model")
	model.Name = kind
	model.Parent = arena

	local hitbox
	if kind == "Tree" then
		local trunk = part(model, "Trunk", Vector3.new(3, 8, 3), position + Vector3.new(0, 4, 0), Color3.fromRGB(119, 82, 51), Enum.Material.Wood)
		local crown = part(model, "Crown", Vector3.new(8, 8, 8), position + Vector3.new(0, 10, 0), Color3.fromRGB(72, 137, 76), Enum.Material.Grass)
		crown.Shape = Enum.PartType.Ball
		hitbox = trunk
		model.PrimaryPart = trunk
		model:SetAttribute("Resource", "Wood")
		model:SetAttribute("Yield", 8)
		model:SetAttribute("MaxHealth", 5)
	elseif kind == "Rock" then
		local rock = part(model, "Rock", Vector3.new(6, 5, 6), position + Vector3.new(0, 2.5, 0), Color3.fromRGB(112, 116, 124), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball
		hitbox = rock
		model.PrimaryPart = rock
		model:SetAttribute("Resource", "Stone")
		model:SetAttribute("Yield", 7)
		model:SetAttribute("MaxHealth", 6)
	else
		local bush = part(model, "Bush", Vector3.new(5, 4, 5), position + Vector3.new(0, 2, 0), Color3.fromRGB(95, 151, 80), Enum.Material.Grass)
		bush.Shape = Enum.PartType.Ball
		hitbox = bush
		model.PrimaryPart = bush
		model:SetAttribute("Resource", "Food")
		model:SetAttribute("Yield", 2)
		model:SetAttribute("MaxHealth", 4)
	end

	model:SetAttribute("Health", model:GetAttribute("MaxHealth"))
	model:SetAttribute("Alive", true)
	CollectionService:AddTag(hitbox, RESOURCE_TAG)
	return model
end

local function randomGroundPoint(margin)
	local half = (Config.WorldSize / 2) - margin
	return Vector3.new(math.random(-half, half), 1, math.random(-half, half))
end

function WorldService.BuildArena()
	local old = Workspace:FindFirstChild("SurvivalArena")
	if old then old:Destroy() end

	arena = Instance.new("Model")
	arena.Name = "SurvivalArena"
	arena.Parent = Workspace

	local ground = part(arena, "Ground", Vector3.new(Config.WorldSize, 1, Config.WorldSize), Vector3.new(0, -0.5, 0), Color3.fromRGB(116, 170, 89), Enum.Material.Grass)
	ground.CanCollide = true

	for _ = 1, 44 do makeResource("Tree", randomGroundPoint(20)) end
	for _ = 1, 30 do makeResource("Rock", randomGroundPoint(20)) end
	for _ = 1, 26 do makeResource("Berry", randomGroundPoint(20)) end

	for _, pos in {
		Vector3.new(-35, 1, -35), Vector3.new(35, 1, -35), Vector3.new(-35, 1, 35), Vector3.new(35, 1, 35), Vector3.new(0, 1, 0),
	} do
		local spawn = Instance.new("SpawnLocation")
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = pos
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Parent = arena
	end
end

function WorldService.Gather(target)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") or not CollectionService:HasTag(target, RESOURCE_TAG) then
		return nil, "Aim at a tree, rock, or berry bush."
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or not model:GetAttribute("Alive") then return nil, "That resource is depleted." end

	local health = (model:GetAttribute("Health") or 1) - 1
	model:SetAttribute("Health", health)
	local resource = model:GetAttribute("Resource")
	local amount = resource == "Food" and 1 or 2
	local depleted = health <= 0

	if depleted then
		model:SetAttribute("Alive", false)
		amount += model:GetAttribute("Yield") or 0
		for _, child in model:GetDescendants() do
			if child:IsA("BasePart") then
				child.Transparency = 1
				child.CanCollide = false
			end
		end
		task.delay(12, function()
			if model.Parent then
				model:SetAttribute("Health", model:GetAttribute("MaxHealth"))
				model:SetAttribute("Alive", true)
				for _, child in model:GetDescendants() do
					if child:IsA("BasePart") then
						child.Transparency = 0
						child.CanCollide = true
					end
				end
			end
		end)
	end

	return { [resource] = amount, XP = amount }, depleted and `{resource} node depleted!` or `+{amount} {resource}`
end

function WorldService.PlaceBuild(player, buildType, position, rotation)
	if buildType ~= "Wall" and buildType ~= "Spike" then return nil, "Unknown building." end
	if typeof(position) ~= "Vector3" then return nil, "Invalid placement." end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - position).Magnitude > Config.BuildDistance then return nil, "Place it closer to you." end
	if math.abs(position.X) > Config.WorldSize / 2 - 4 or math.abs(position.Z) > Config.WorldSize / 2 - 4 then return nil, "Outside the map." end

	local p
	if buildType == "Wall" then
		p = part(arena, "Wall", Vector3.new(10, 6, 1.2), Vector3.new(position.X, 3, position.Z), Color3.fromRGB(151, 101, 62), Enum.Material.WoodPlanks)
		p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, math.rad(rotation or 0), 0)
		p:SetAttribute("Health", 120)
	else
		p = part(arena, "Spike", Vector3.new(5, 2.5, 5), Vector3.new(position.X, 1.25, position.Z), Color3.fromRGB(95, 82, 70), Enum.Material.Wood)
		p.Shape = Enum.PartType.Cylinder
		p.Orientation = Vector3.new(0, 0, 90)
		p:SetAttribute("Health", 75)
	end
	p:SetAttribute("OwnerUserId", player.UserId)
	p:SetAttribute("BuildType", buildType)
	CollectionService:AddTag(p, BUILD_TAG)
	return p, `{buildType} placed.`
end

return WorldService
