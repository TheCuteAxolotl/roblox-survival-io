local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 25)
if not world then return end

local old = world:FindFirstChild("WorldVisualOverhaul")
if old then old:Destroy() end

local root = Instance.new("Model")
root.Name = "WorldVisualOverhaul"
root:SetAttribute("GeneratedLandmark", true)
root.Parent = world

local function part(parent, name, size, cf, color, material, transparency, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent, name, size, position, color, material, transparency)
	local p = part(parent, name, size, CFrame.new(position), color, material, transparency, false)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(parent, name, height, width, cf, color, material, transparency)
	local p = part(parent, name, Vector3.new(height, width, width), cf, color, material, transparency, false)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function billboard(target, title, subtitle, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(300, 68)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 240
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = title .. "\n" .. subtitle
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
end

local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 26
	l.Brightness = brightness or 2
	l.Shadows = true
	l.Parent = parent
	return l
end

local function particles(parent, colorA, colorB, rate, speed, lifetime)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(colorA, colorB or colorA)
	emitter.LightEmission = 0.35
	emitter.Rate = rate or 5
	emitter.Speed = NumberRange.new(speed or 1, (speed or 1) * 2)
	emitter.Lifetime = NumberRange.new(lifetime or 2.5, (lifetime or 2.5) * 1.8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = parent
	return emitter
end

local function regionBase(name, center, size, color, material, titleColor, subtitle)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("GeneratedLandmark", true)
	model:SetAttribute("WorldRegion", true)
	model.Parent = root

	local ground = part(model, "RegionTint", Vector3.new(size.X, 0.16, size.Z), CFrame.new(center + Vector3.new(0, 0.08, 0)), color, material, 0.18, false)
	local marker = part(model, "RegionMarker", Vector3.new(2, 14, 2), CFrame.new(center + Vector3.new(0, 7, -size.Z / 2 + 18)), titleColor, Enum.Material.Neon, 0.16, false)
	billboard(marker, string.upper(name), subtitle, titleColor)
	return model, ground
end

-- FROST HIGHLANDS
do
	local center = Vector3.new(-980, 0, 850)
	local model = regionBase("Frost Highlands", center, Vector3.new(420, 0, 360), Color3.fromRGB(180, 205, 220), Enum.Material.Ice, Color3.fromRGB(176, 224, 255), "MAMMOTHS • RAMS • ICEBOUND GOLEMS")
	for i = 1, 30 do
		local a = math.random() * math.pi * 2
		local r = math.random(55, 185)
		local h = math.random(10, 34)
		local pos = center + Vector3.new(math.cos(a) * r, h / 2, math.sin(a) * r)
		local shard = cylinder(model, "IceSpire", h, math.random(3, 7), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(math.random(-14,14))), Color3.fromRGB(160, 218, 244), Enum.Material.Glass, 0.2)
		if i % 7 == 0 then light(shard, Color3.fromRGB(145, 211, 255), 24, 1.5) end
	end
	for i = 1, 12 do
		local pos = center + Vector3.new(math.random(-170,170), 2.2, math.random(-130,130))
		ball(model, "SnowBoulder", Vector3.new(math.random(5,10), math.random(4,8), math.random(5,10)), pos, Color3.fromRGB(198, 210, 218), Enum.Material.Snow)
	end
	local altar = part(model, "FrozenMonolith", Vector3.new(14, 28, 8), CFrame.new(center + Vector3.new(0,14,35)) * CFrame.Angles(0,math.rad(18),0), Color3.fromRGB(104, 139, 165), Enum.Material.Ice, 0.08, true)
	particles(altar, Color3.fromRGB(204,239,255), Color3.fromRGB(118,196,255), 5, 1.5, 3)
end

-- DEEP DUNES
do
	local center = Vector3.new(980, 0, 850)
	local model = regionBase("Sunscar Dunes", center, Vector3.new(420, 0, 360), Color3.fromRGB(207, 164, 90), Enum.Material.Sand, Color3.fromRGB(255, 184, 76), "HYENAS • TITAN SCORPIONS • LOST RUINS")
	for i = 1, 32 do
		local x = math.random(-190,190)
		local z = math.random(-150,150)
		local s = math.random(6,16)
		local rock = part(model, "Sandstone", Vector3.new(s, math.random(3,9), s * 0.7), CFrame.new(center + Vector3.new(x, 2.5, z)) * CFrame.Angles(0, math.rad(math.random(0,180)), math.rad(math.random(-12,12))), Color3.fromRGB(169, 115, 67), Enum.Material.Sandstone, 0, false)
		if i % 9 == 0 then rock.Material = Enum.Material.Slate end
	end
	local ruinPos = center + Vector3.new(0,0,30)
	for _, x in { -22, 22 } do
		part(model, "RuinedPillar", Vector3.new(6, 25, 6), CFrame.new(ruinPos + Vector3.new(x,12.5,0)), Color3.fromRGB(147, 111, 76), Enum.Material.Sandstone, 0, true)
	end
	part(model, "RuinedLintel", Vector3.new(50, 6, 7), CFrame.new(ruinPos + Vector3.new(0,25,0)) * CFrame.Angles(0,0,math.rad(-5)), Color3.fromRGB(147, 111, 76), Enum.Material.Sandstone, 0, true)
	local ember = ball(model, "Sunstone", Vector3.new(6,6,6), ruinPos + Vector3.new(0,10,0), Color3.fromRGB(255,145,48), Enum.Material.Neon, 0.15)
	light(ember, ember.Color, 36, 2.4)
	particles(ember, Color3.fromRGB(255,189,84), Color3.fromRGB(255,103,42), 7, 1.2, 2.2)
end

-- MIRE MARSH
do
	local center = Vector3.new(-980, 0, -850)
	local model = regionBase("Mire Marsh", center, Vector3.new(420,0,360), Color3.fromRGB(62, 91, 68), Enum.Material.Mud, Color3.fromRGB(118, 220, 130), "MIRE BOARS • BOG CRAWLERS • TOXIC POOLS")
	for i = 1, 18 do
		local pos = center + Vector3.new(math.random(-180,180), 0.09, math.random(-145,145))
		local pool = cylinder(model, "BogPool", 0.18, math.random(10,24), CFrame.new(pos) * CFrame.Angles(0,0,math.rad(90)), Color3.fromRGB(64, 117, 80), Enum.Material.Glass, 0.28)
		particles(pool, Color3.fromRGB(111,194,111), Color3.fromRGB(69,130,84), 2, 0.4, 3)
	end
	for i = 1, 26 do
		local pos = center + Vector3.new(math.random(-190,190), 4, math.random(-155,155))
		local trunk = cylinder(model, "DeadTree", math.random(8,16), 1.2, CFrame.new(pos) * CFrame.Angles(0,0,math.rad(90 + math.random(-12,12))), Color3.fromRGB(66, 57, 49), Enum.Material.Wood, 0)
		if i % 4 == 0 then
			ball(model, "Moss", Vector3.new(4,2,4), pos + Vector3.new(0,4,0), Color3.fromRGB(60, 108, 65), Enum.Material.Grass, 0)
		end
	end
	local idol = part(model, "BogIdol", Vector3.new(11, 22, 8), CFrame.new(center + Vector3.new(0,11,25)), Color3.fromRGB(51, 67, 55), Enum.Material.Slate, 0, true)
	local eye = ball(model, "IdolEye", Vector3.new(2,2,1), center + Vector3.new(0,14,20.8), Color3.fromRGB(95,255,126), Enum.Material.Neon, 0)
	light(eye, eye.Color, 24, 2)
end

-- EMBER GROVE
do
	local center = Vector3.new(980, 0, -850)
	local model = regionBase("Ember Grove", center, Vector3.new(420,0,360), Color3.fromRGB(94, 61, 49), Enum.Material.Ground, Color3.fromRGB(255, 115, 72), "EMBER STAGS • EMBER WOLVES • BURNING TREES")
	for i = 1, 34 do
		local pos = center + Vector3.new(math.random(-190,190), 5, math.random(-150,150))
		local trunk = cylinder(model, "EmberTree", math.random(8,14), 1.4, CFrame.new(pos) * CFrame.Angles(0,0,math.rad(90)), Color3.fromRGB(73, 48, 41), Enum.Material.Wood, 0)
		local canopy = ball(model, "EmberCanopy", Vector3.new(math.random(7,12), math.random(6,10), math.random(7,12)), pos + Vector3.new(0,7,0), Color3.fromRGB(math.random(160,220), math.random(55,95), 40), Enum.Material.Grass, 0)
		if i % 6 == 0 then
			canopy.Material = Enum.Material.Neon
			canopy.Transparency = 0.15
			light(canopy, Color3.fromRGB(255,101,57), 22, 1.3)
		end
	end
	local heart = ball(model, "EmberHeart", Vector3.new(9,9,9), center + Vector3.new(0,6,25), Color3.fromRGB(255,83,53), Enum.Material.Neon, 0.12)
	light(heart, heart.Color, 42, 2.8)
	particles(heart, Color3.fromRGB(255,165,72), Color3.fromRGB(255,57,44), 12, 2.4, 2.6)
end

-- CRYSTAL BASIN
do
	local center = Vector3.new(0, 0, 980)
	local model = regionBase("Crystal Basin", center, Vector3.new(320,0,260), Color3.fromRGB(74, 82, 115), Enum.Material.Slate, Color3.fromRGB(173, 137, 255), "CRYSTAL GOLEMS • ARCANE SHARDS")
	for i = 1, 42 do
		local a = math.random() * math.pi * 2
		local r = math.random(35,145)
		local h = math.random(5,22)
		local pos = center + Vector3.new(math.cos(a)*r, h/2, math.sin(a)*r)
		local color = i % 3 == 0 and Color3.fromRGB(88,225,255) or Color3.fromRGB(161,91,255)
		local shard = cylinder(model, "CrystalShard", h, math.random(2,5), CFrame.new(pos) * CFrame.Angles(0,0,math.rad(math.random(65,115))), color, Enum.Material.Neon, 0.12)
		if i % 8 == 0 then light(shard, color, 25, 1.6) end
	end
	local core = ball(model, "BasinCore", Vector3.new(12,12,12), center + Vector3.new(0,8,0), Color3.fromRGB(133,77,255), Enum.Material.Neon, 0.08)
	light(core, core.Color, 55, 3.2)
	particles(core, Color3.fromRGB(202,166,255), Color3.fromRGB(96,215,255), 14, 2, 3.5)
end

-- Global graphical treatment. These effects coexist with the day/night script.
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.38
Lighting.EnvironmentSpecularScale = 0.55
Lighting.ShadowSoftness = 0.28

for _, className in { "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect" } do
	local existing = Lighting:FindFirstChild("Wildforge_" .. className)
	if existing then existing:Destroy() end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "Wildforge_Atmosphere"
atmosphere.Density = 0.26
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(205, 218, 235)
atmosphere.Decay = Color3.fromRGB(92, 105, 126)
atmosphere.Glare = 0.12
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "Wildforge_BloomEffect"
bloom.Intensity = 0.28
bloom.Size = 24
bloom.Threshold = 1.1
bloom.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "Wildforge_ColorCorrectionEffect"
cc.Brightness = 0.015
cc.Contrast = 0.08
cc.Saturation = 0.12
cc.TintColor = Color3.fromRGB(245, 248, 255)
cc.Parent = Lighting

local rays = Instance.new("SunRaysEffect")
rays.Name = "Wildforge_SunRaysEffect"
rays.Intensity = 0.06
rays.Spread = 0.78
rays.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "Wildforge_DepthOfFieldEffect"
dof.FarIntensity = 0.08
dof.FocusDistance = 70
dof.InFocusRadius = 65
dof.NearIntensity = 0
dof.Parent = Lighting

local terrain = Workspace:FindFirstChildOfClass("Terrain")
if terrain then
	local oldClouds = terrain:FindFirstChild("WildforgeClouds")
	if oldClouds then oldClouds:Destroy() end
	local clouds = Instance.new("Clouds")
	clouds.Name = "WildforgeClouds"
	clouds.Cover = 0.34
	clouds.Density = 0.45
	clouds.Color = Color3.fromRGB(236, 240, 246)
	clouds.Parent = terrain
end

print("[WorldVisualOverhaul] Five outer regions, landmark scenery, ambient particles and upgraded lighting online.")
