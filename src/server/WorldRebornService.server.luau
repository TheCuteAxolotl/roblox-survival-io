local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 20)
if not world then return end

local old = world:FindFirstChild("RebornRegions")
if old then old:Destroy() end

local root = Instance.new("Model")
root.Name = "RebornRegions"
root.Parent = world

local REGIONS = {
	Highlands = {
		Name = "FROSTSPIRE HIGHLANDS",
		Center = Vector3.new(-720, 0, 650),
		Size = Vector3.new(360, 1.2, 310),
		Color = Color3.fromRGB(177, 190, 198),
		Material = Enum.Material.Slate,
		Accent = Color3.fromRGB(118, 194, 255),
	},
	Dunes = {
		Name = "GLASS DUNES",
		Center = Vector3.new(720, 0, 650),
		Size = Vector3.new(360, 1.2, 310),
		Color = Color3.fromRGB(181, 139, 84),
		Material = Enum.Material.Sand,
		Accent = Color3.fromRGB(95, 228, 255),
	},
	Marsh = {
		Name = "MIRE FEN",
		Center = Vector3.new(-720, 0, -650),
		Size = Vector3.new(360, 1.2, 310),
		Color = Color3.fromRGB(72, 91, 66),
		Material = Enum.Material.Mud,
		Accent = Color3.fromRGB(114, 222, 142),
	},
	Grove = {
		Name = "EMBERWOOD GROVE",
		Center = Vector3.new(720, 0, -650),
		Size = Vector3.new(360, 1.2, 310),
		Color = Color3.fromRGB(88, 104, 61),
		Material = Enum.Material.Grass,
		Accent = Color3.fromRGB(255, 126, 70),
	},
}

local function part(parent, name, size, cf, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent, name, size, cf, color, material, collide)
	local p = part(parent, name, size, cf, color, material, collide)
	p.Shape = Enum.PartType.Ball
	return p
end

local function billboard(adornee, text, color, size, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RegionLabel"
	gui.Adornee = adornee
	gui.Size = size or UDim2.fromOffset(280, 58)
	gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 230
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundColor3 = Color3.fromRGB(18,18,23)
	label.BackgroundTransparency = 0.2
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.55
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)
	return label
end

local function regionPoint(data, margin)
	margin = margin or 24
	return data.Center + Vector3.new(
		math.random(math.floor(-data.Size.X/2 + margin), math.floor(data.Size.X/2 - margin)),
		0,
		math.random(math.floor(-data.Size.Z/2 + margin), math.floor(data.Size.Z/2 - margin))
	)
end

local function stoneCluster(parent, pos, color, scale)
	scale = scale or 1
	for i = 1, 3 do
		local r = (3 + i * 1.3) * scale
		local rock = ball(parent, "Boulder", Vector3.new(r * 1.2, r, r) , CFrame.new(pos + Vector3.new((i-2)*2.3*scale, r*0.35, math.random(-2,2)*scale)), color:Lerp(Color3.new(0,0,0), i*0.035), Enum.Material.Slate)
		rock.Orientation = Vector3.new(math.random(-10,10), math.random(0,180), math.random(-10,10))
	end
end

local function pine(parent, pos, trunkColor, leafColor, scale)
	scale = scale or 1
	part(parent, "PineTrunk", Vector3.new(1.6, 10, 1.6)*scale, CFrame.new(pos + Vector3.new(0,5*scale,0)), trunkColor, Enum.Material.Wood)
	for i = 1, 3 do
		local crown = part(parent, "PineCrown", Vector3.new((8-i)*scale, 4.5*scale, (8-i)*scale), CFrame.new(pos + Vector3.new(0,(8+i*2.5)*scale,0)), leafColor, Enum.Material.Grass, false)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 0.75, 1)
		mesh.Parent = crown
	end
end

local function crystal(parent, pos, color, scale)
	scale = scale or 1
	for i = 1, math.random(3,5) do
		local h = math.random(6,13) * scale
		local p = part(parent, "Crystal", Vector3.new(2.2*scale,h,2.2*scale), CFrame.new(pos + Vector3.new((i-3)*1.8*scale,h/2,math.random(-2,2)*scale)) * CFrame.Angles(math.rad(math.random(-8,8)),0,math.rad(math.random(-10,10))), color:Lerp(Color3.new(1,1,1), i*0.05), Enum.Material.Glass, false)
		p.Transparency = 0.12
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 14 * scale
		light.Brightness = 1.3
		light.Parent = p
	end
end

local function deadTree(parent, pos, scale)
	scale = scale or 1
	local trunk = part(parent, "DeadTree", Vector3.new(1.7,11,1.7)*scale, CFrame.new(pos + Vector3.new(0,5.5*scale,0)) * CFrame.Angles(0,0,math.rad(math.random(-8,8))), Color3.fromRGB(82,68,54), Enum.Material.Wood)
	for _, side in {-1,1} do
		part(parent,"DeadBranch",Vector3.new(5,0.7,0.7)*scale,trunk.CFrame*CFrame.new(side*2.2*scale,2.8*scale,0)*CFrame.Angles(0,0,math.rad(side*25)),Color3.fromRGB(76,62,50),Enum.Material.Wood,false)
	end
end

local function redwood(parent, pos, scale)
	scale = scale or 1
	local trunk = part(parent, "RedwoodTrunk", Vector3.new(4.2,28,4.2)*scale, CFrame.new(pos + Vector3.new(0,14*scale,0)), Color3.fromRGB(105,58,43), Enum.Material.Wood)
	for i = 1, 4 do
		local crown = ball(parent, "RedwoodCrown", Vector3.new(16,10,16)*scale, CFrame.new(pos + Vector3.new(math.random(-2,2)*scale,(21+i*3.2)*scale,math.random(-2,2)*scale)), Color3.fromRGB(61,103,58), Enum.Material.Grass, false)
		crown.Transparency = 0.03
	end
	for _, side in {-1,1} do
		part(parent,"Root",Vector3.new(7,0.7,1.0)*scale,trunk.CFrame*CFrame.new(side*4*scale,-13.1*scale,0)*CFrame.Angles(0,math.rad(25*side),math.rad(3*side)),Color3.fromRGB(88,48,37),Enum.Material.Wood)
	end
end

local function puddle(parent, pos, radius, color)
	local p = part(parent, "MarshPool", Vector3.new(0.18, radius*2, radius*2), CFrame.new(pos + Vector3.new(0,0.1,0))*CFrame.Angles(0,0,math.rad(90)), color, Enum.Material.Glass, false)
	p.Shape = Enum.PartType.Cylinder
	p.Transparency = 0.3
	return p
end

local function makeWaystone(parent, regionKey, data)
	local base = part(parent, "WaystoneBase", Vector3.new(10,1,10), CFrame.new(data.Center + Vector3.new(0,1.05,-112)), Color3.fromRGB(54,52,62), Enum.Material.Slate)
	local stone = part(parent, "Waystone", Vector3.new(4,11,4), base.CFrame*CFrame.new(0,6,0), data.Accent, Enum.Material.Glass)
	stone.Transparency = 0.12
	local light = Instance.new("PointLight")
	light.Color = data.Accent
	light.Range = 30
	light.Brightness = 2.2
	light.Parent = stone
	billboard(stone, data.Name.."
WAYSTONE", data.Accent, UDim2.fromOffset(250,54), Vector3.new(0,8,0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Return to Sanctuary"
	prompt.ObjectText = data.Name
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0.6
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone
	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then char:PivotTo(CFrame.new(0,5,-190)) end
	end)
end

local function makeRegion(key, data)
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("RebornRegion", true)
	model:SetAttribute("RegionKey", key)
	model.Parent = root

	local ground = part(model, "RegionGround", data.Size, CFrame.new(data.Center + Vector3.new(0,0.15,0)), data.Color, data.Material)
	ground:SetAttribute("RegionGround", true)
	local sign = part(model, "RegionMonolith", Vector3.new(14,9,1.5), CFrame.new(data.Center + Vector3.new(0,4.5,-data.Size.Z/2+18)), Color3.fromRGB(44,43,49), Enum.Material.Slate)
	billboard(sign, data.Name, data.Accent, UDim2.fromOffset(300,58), Vector3.new(0,1,0))

	if key == "Highlands" then
		for _ = 1, 20 do stoneCluster(model, regionPoint(data,30), Color3.fromRGB(106,119,129), math.random(8,14)/10) end
		for _ = 1, 18 do pine(model, regionPoint(data,28), Color3.fromRGB(91,70,56), Color3.fromRGB(78,102,93), math.random(8,13)/10) end
		-- Ruined keep.
		local keep = data.Center + Vector3.new(55,0,35)
		for _, x in {-22,22} do part(model,"KeepWall",Vector3.new(5,18,46),CFrame.new(keep+Vector3.new(x,9,0)),Color3.fromRGB(99,104,109),Enum.Material.Brick) end
		part(model,"KeepBack",Vector3.new(49,18,5),CFrame.new(keep+Vector3.new(0,9,21)),Color3.fromRGB(99,104,109),Enum.Material.Brick)
		part(model,"BrokenKeep",Vector3.new(18,8,5),CFrame.new(keep+Vector3.new(-14,4,-21)),Color3.fromRGB(99,104,109),Enum.Material.Brick)
	elseif key == "Dunes" then
		for _ = 1, 18 do stoneCluster(model, regionPoint(data,28), Color3.fromRGB(142,103,70), math.random(7,13)/10) end
		for _ = 1, 16 do crystal(model, regionPoint(data,30), data.Accent, math.random(7,12)/10) end
		-- Giant glass obelisk.
		local ob = part(model,"GlassObelisk",Vector3.new(9,42,9),CFrame.new(data.Center+Vector3.new(48,21,20))*CFrame.Angles(0,math.rad(12),math.rad(4)),data.Accent,Enum.Material.Glass,false)
		ob.Transparency = 0.18
		local l=Instance.new("PointLight") l.Color=data.Accent l.Range=55 l.Brightness=3 l.Parent=ob
	elseif key == "Marsh" then
		for _ = 1, 16 do puddle(model, regionPoint(data,30), math.random(8,18), Color3.fromRGB(54,105,94)) end
		for _ = 1, 20 do deadTree(model, regionPoint(data,26), math.random(8,13)/10) end
		for _ = 1, 40 do
			local p = regionPoint(data,22)
			part(model,"Reed",Vector3.new(0.25,math.random(2,5),0.25),CFrame.new(p+Vector3.new(0,1.5,0)),Color3.fromRGB(88,117,61),Enum.Material.Grass,false)
		end
		-- Stilt lodge.
		local lodge = data.Center + Vector3.new(50,0,25)
		for _, x in {-8,8} do for _, z in {-6,6} do part(model,"Stilt",Vector3.new(1,8,1),CFrame.new(lodge+Vector3.new(x,4,z)),Color3.fromRGB(86,62,47),Enum.Material.Wood) end end
		part(model,"LodgeFloor",Vector3.new(20,1,16),CFrame.new(lodge+Vector3.new(0,8,0)),Color3.fromRGB(117,81,54),Enum.Material.WoodPlanks)
		part(model,"LodgeRoof",Vector3.new(23,1,19),CFrame.new(lodge+Vector3.new(0,15,0)),Color3.fromRGB(68,63,58),Enum.Material.WoodPlanks)
	elseif key == "Grove" then
		for _ = 1, 18 do redwood(model, regionPoint(data,32), math.random(8,12)/10) end
		for _ = 1, 28 do
			local p = regionPoint(data,24)
			local shroom = ball(model,"GlowCap",Vector3.new(1.5,0.7,1.5),CFrame.new(p+Vector3.new(0,0.55,0)),data.Accent,Enum.Material.Neon,false)
			shroom.Transparency = 0.1
		end
		-- Ancient tree shrine.
		local shrine = data.Center + Vector3.new(50,0,20)
		redwood(model, shrine, 1.55)
		local ring = part(model,"ShrineRing",Vector3.new(1,28,28),CFrame.new(shrine+Vector3.new(0,0.4,0))*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(89,69,55),Enum.Material.Slate,false)
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.15
	end

	makeWaystone(model, key, data)
end

for key, data in REGIONS do makeRegion(key, data) end

-- Sanctuary travel court: four instant travel stones so the bigger map is adventurous,
-- not just a long jog every single time.
local travelCourt = Instance.new("Model")
travelCourt.Name = "SanctuaryTravelCourt"
travelCourt.Parent = root
local courtCenter = Vector3.new(0,0,-245)
part(travelCourt,"CourtFloor",Vector3.new(72,0.8,24),CFrame.new(courtCenter+Vector3.new(0,0.4,0)),Color3.fromRGB(54,54,63),Enum.Material.Slate)
local order = { "Highlands", "Marsh", "Dunes", "Grove" }
for i,key in order do
	local data = REGIONS[key]
	local x = -27 + (i-1)*18
	local pad = part(travelCourt,key.."TravelPad",Vector3.new(10,0.8,10),CFrame.new(courtCenter+Vector3.new(x,0.85,0)),data.Accent,Enum.Material.Neon,false)
	pad.Transparency = 0.28
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Travel"
	prompt.ObjectText = data.Name
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.45
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if char then
			player:SetAttribute("Discovered_"..key, true)
			char:PivotTo(CFrame.new(data.Center + Vector3.new(0,5,-105)))
		end
	end)
end

print("[WorldReborn] Four outer regions, major landmarks and sanctuary waystones generated.")
