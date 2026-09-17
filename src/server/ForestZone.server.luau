local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local old = world:FindFirstChild("BlackwoodForest")
if old then old:Destroy() end

local forest = Instance.new("Model")
forest.Name = "BlackwoodForest"
forest:SetAttribute("DangerZone", true)
forest:SetAttribute("ZoneName", "Blackwood Forest")
forest.Parent = world

local CENTER = Vector3.new(0, 0, 365)
local random = Random.new(9137)

local function part(name, size, cframe, color, material, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = forest
	return p
end

local ground = part(
	"ForestGround",
	Vector3.new(330, 0.5, 280),
	CFrame.new(CENTER + Vector3.new(0, 0.26, 0)),
	Color3.fromRGB(62, 100, 62),
	Enum.Material.Grass,
	true
)
ground:SetAttribute("ForestGround", true)

-- Add irregular darker patches so the zone has a clear identity without changing the simple art style.
for _ = 1, 12 do
	local patch = part(
		"DarkMoss",
		Vector3.new(random:NextNumber(28, 70), 0.08, random:NextNumber(22, 60)),
		CFrame.new(CENTER + Vector3.new(random:NextNumber(-140, 140), 0.56, random:NextNumber(-115, 115))) * CFrame.Angles(0, math.rad(random:NextInteger(0, 180)), 0),
		Color3.fromRGB(48, 83, 53),
		Enum.Material.Grass,
		false
	)
	patch.CanQuery = false
end

local function makeTree(position, scale)
	local tree = Instance.new("Model")
	tree.Name = "BlackwoodTree"
	tree.Parent = forest
	local trunkHeight = 10 * scale
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2.2, trunkHeight, 2.2) * scale
	trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0))
	trunk.Color = Color3.fromRGB(65, 51, 42)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	-- Non-colliding decorative trunks keep simple Humanoid AI from getting stuck.
	trunk.CanCollide = false
	trunk.Parent = tree
	tree.PrimaryPart = trunk
	for i, offset in {
		Vector3.new(0, trunkHeight + 1.5 * scale, 0),
		Vector3.new(-2.5 * scale, trunkHeight, 1.1 * scale),
		Vector3.new(2.2 * scale, trunkHeight + 0.5 * scale, -0.8 * scale),
	} do
		local crown = Instance.new("Part")
		crown.Name = `Crown{i}`
		crown.Shape = Enum.PartType.Ball
		crown.Size = Vector3.new(7, 6.5, 7) * scale
		crown.Position = position + offset
		crown.Color = i == 1 and Color3.fromRGB(43, 77, 49) or Color3.fromRGB(49, 87, 54)
		crown.Material = Enum.Material.Grass
		crown.Anchored = true
		crown.CanCollide = false
		crown.Parent = tree
	end
end

-- Leave a loose path through the southern middle so entering the forest is readable.
for _ = 1, 52 do
	local x = random:NextNumber(-150, 150)
	local z = random:NextNumber(-122, 122)
	if not (math.abs(x) < 30 and z < -25) then
		makeTree(CENTER + Vector3.new(x, 0.55, z), random:NextNumber(0.8, 1.25))
	end
end

for _ = 1, 8 do
	local log = part(
		"FallenLog",
		Vector3.new(random:NextNumber(6, 12), 1.2, 1.2),
		CFrame.new(CENTER + Vector3.new(random:NextNumber(-135, 135), 1.15, random:NextNumber(-100, 100))) * CFrame.Angles(0, math.rad(random:NextInteger(0, 180)), math.rad(90)),
		Color3.fromRGB(73, 57, 44),
		Enum.Material.Wood,
		false
	)
	log.CanQuery = true
end

local signPost = part("ForestSignPost", Vector3.new(1, 7, 1), CFrame.new(CENTER + Vector3.new(0, 3.5, -150)), Color3.fromRGB(86, 60, 39), Enum.Material.Wood, false)
local sign = part("ForestSign", Vector3.new(18, 6, 1), signPost.CFrame * CFrame.new(0, 3, 0), Color3.fromRGB(77, 55, 39), Enum.Material.WoodPlanks, false)
local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.Parent = sign
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "BLACKWOOD FOREST\nHIGH DANGER • BETTER LOOT"
label.TextColor3 = Color3.fromRGB(225, 235, 202)
label.TextScaled = true
label.TextWrapped = true
label.Font = Enum.Font.GothamBold
label.Parent = surface

print("[ForestZone] Blackwood Forest generated with high-tier wildlife region.")
