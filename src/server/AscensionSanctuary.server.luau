local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 20)
if not world then return end

local CENTER = Vector3.new(0, 0, -190)

local old = world:FindFirstChild("AscensionSanctuary")
if old then old:Destroy() end

local model = Instance.new("Model")
model.Name = "AscensionSanctuary"
model:SetAttribute("GeneratedLandmark", true)
model:SetAttribute("VillageBiome", "Grass")
model:SetAttribute("Sanctuary", true)
model.Parent = world

local function part(name, size, cf, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function surfaceText(target, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 42
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(235, 224, 255)
	label.TextStrokeTransparency = 0.72
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
end

part("SanctuaryFloor", Vector3.new(118, 1, 82), CFrame.new(CENTER + Vector3.new(0, 0.5, 0)), Color3.fromRGB(70, 72, 79), Enum.Material.Slate)
part("InnerFloor", Vector3.new(72, 0.35, 48), CFrame.new(CENTER + Vector3.new(0, 1.05, 0)), Color3.fromRGB(38, 39, 47), Enum.Material.SmoothPlastic)

for _, x in { -52, 52 } do
	for _, z in { -33, 33 } do
		local pillar = part("SanctuaryPillar", Vector3.new(5, 16, 5), CFrame.new(CENTER + Vector3.new(x, 8, z)), Color3.fromRGB(82, 78, 94), Enum.Material.Slate)
		local crystal = part("SanctuaryCrystal", Vector3.new(2.2, 7, 2.2), pillar.CFrame * CFrame.new(0, 10.5, 0) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(139, 83, 214), Enum.Material.Neon, false)
		crystal.Transparency = 0.2
		local light = Instance.new("PointLight")
		light.Color = crystal.Color
		light.Range = 28
		light.Brightness = 2.2
		light.Parent = crystal
	end
end

local title = part("SanctuaryTitle", Vector3.new(38, 8, 1), CFrame.new(CENTER + Vector3.new(0, 6, -38)), Color3.fromRGB(47, 42, 57), Enum.Material.Slate)
surfaceText(title, "WILDFORGE
ASCENSION SANCTUARY", Color3.fromRGB(232, 211, 255))

local solo = part("SoloInfo", Vector3.new(26, 8, 1), CFrame.new(CENTER + Vector3.new(-38, 5, 35)), Color3.fromRGB(44, 45, 52), Enum.Material.Slate)
surfaceText(solo, "SOLO
Enemies scale to you
Second Wind recovery
Choose your build", Color3.fromRGB(185, 225, 255))

local coop = part("CoopInfo", Vector3.new(26, 8, 1), CFrame.new(CENTER + Vector3.new(38, 5, 35)), Color3.fromRGB(44, 45, 52), Enum.Material.Slate)
surfaceText(coop, "WITH FRIENDS
Shared stages
Revive teammates
Bonus rewards", Color3.fromRGB(180, 255, 194))

local risk = part("RiskInfo", Vector3.new(28, 8, 1), CFrame.new(CENTER + Vector3.new(0, 5, 35)), Color3.fromRGB(55, 43, 49), Enum.Material.Slate)
surfaceText(risk, "PUSH OR CASH OUT
Stages 3 • 6 • 9
Leave safely or risk it all", Color3.fromRGB(255, 215, 142))

for _, offset in {
	Vector3.new(-28, 0, -26), Vector3.new(28, 0, -26),
	Vector3.new(-28, 0, 26), Vector3.new(28, 0, 26),
} do
	local base = part("Brazier", Vector3.new(3, 4, 3), CFrame.new(CENTER + offset + Vector3.new(0, 2, 0)), Color3.fromRGB(66, 57, 52), Enum.Material.Slate)
	local flame = part("Flame", Vector3.new(1.6, 2.2, 1.6), base.CFrame * CFrame.new(0, 3, 0), Color3.fromRGB(159, 92, 255), Enum.Material.Neon, false)
	flame.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = flame.Color
	light.Range = 20
	light.Brightness = 2
	light.Parent = flame
end

print("[AscensionSanctuary] Central solo/co-op hub generated around the Ascension Gate.")
