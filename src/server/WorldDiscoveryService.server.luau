local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 25)
if not world then return end

local old = world:FindFirstChild("DiscoveryShrines")
if old then old:Destroy() end

local root = Instance.new("Model")
root.Name = "DiscoveryShrines"
root:SetAttribute("GeneratedLandmark", true)
root.Parent = world

local discovered = {}

local SHRINES = {
	{ Id="FrostCairn", Name="FROST CAIRN", Pos=Vector3.new(-1110,0,930), Color=Color3.fromRGB(164,220,255), Gold=32, XP=55 },
	{ Id="SunObelisk", Name="SUN OBELISK", Pos=Vector3.new(1110,0,930), Color=Color3.fromRGB(255,176,72), Gold=35, XP=60 },
	{ Id="BogTotem", Name="BOG TOTEM", Pos=Vector3.new(-1110,0,-930), Color=Color3.fromRGB(107,229,129), Gold=38, XP=62 },
	{ Id="EmberStone", Name="EMBER STONE", Pos=Vector3.new(1110,0,-930), Color=Color3.fromRGB(255,92,62), Gold=40, XP=66 },
	{ Id="PrismAltar", Name="PRISM ALTAR", Pos=Vector3.new(0,0,1085), Color=Color3.fromRGB(178,128,255), Gold=48, XP=78 },
	{ Id="RiverWatch", Name="RIVER WATCH", Pos=Vector3.new(-520,0,115), Color=Color3.fromRGB(102,191,255), Gold=24, XP=42 },
	{ Id="RiverWatchEast", Name="EASTERN WATCH", Pos=Vector3.new(520,0,-115), Color=Color3.fromRGB(102,191,255), Gold=24, XP=42 },
	{ Id="OldWaystone", Name="OLD WAYSTONE", Pos=Vector3.new(0,0,-1080), Color=Color3.fromRGB(222,205,162), Gold=45, XP=70 },
}

local function part(parent, name, size, cf, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function createShrine(data)
	local model = Instance.new("Model")
	model.Name = data.Id
	model:SetAttribute("GeneratedLandmark", true)
	model:SetAttribute("DiscoveryShrine", true)
	model.Parent = root

	local base = part(model, "Base", Vector3.new(10,1,10), CFrame.new(data.Pos + Vector3.new(0,0.5,0)), Color3.fromRGB(75,75,81), Enum.Material.Slate, true)
	model.PrimaryPart = base
	part(model, "Step", Vector3.new(7,1,7), CFrame.new(data.Pos + Vector3.new(0,1.4,0)), Color3.fromRGB(91,91,98), Enum.Material.Slate, true)
	local stone = part(model, "ShrineStone", Vector3.new(4.5,9,3), CFrame.new(data.Pos + Vector3.new(0,6,0)) * CFrame.Angles(0,math.rad(18),math.rad(4)), Color3.fromRGB(70,69,78), Enum.Material.Slate, true)
	local rune = part(model, "Rune", Vector3.new(2.2,4.8,0.3), stone.CFrame * CFrame.new(0,0,-1.65), data.Color, Enum.Material.Neon, false)

	local glow = Instance.new("PointLight")
	glow.Color = data.Color
	glow.Range = 22
	glow.Brightness = 2.1
	glow.Shadows = true
	glow.Parent = rune

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Discover"
	prompt.ObjectText = data.Name
	prompt.MaxActivationDistance = 13
	prompt.HoldDuration = 0.6
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone
	prompt.Triggered:Connect(function(player)
		discovered[player] = discovered[player] or {}
		if discovered[player][data.Id] then
			prompt.ObjectText = data.Name .. " • already discovered"
			return
		end
		discovered[player][data.Id] = true
		PlayerService.Add(player, { Gold = data.Gold, XP = data.XP })
		player:SetAttribute("DiscoveriesSession", (player:GetAttribute("DiscoveriesSession") or 0) + 1)
		prompt.ObjectText = string.format("%s • +%d Gold +%d XP", data.Name, data.Gold, data.XP)
		task.delay(2.5, function()
			if prompt.Parent then prompt.ObjectText = data.Name end
		end)
	end)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180,38)
	gui.StudsOffsetWorldSpace = Vector3.new(0,7,0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 85
	gui.Parent = stone
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = "???"
	label.TextColor3 = data.Color
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

for _, data in SHRINES do createShrine(data) end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("DiscoveriesSession", 0)
end)
Players.PlayerRemoving:Connect(function(player)
	discovered[player] = nil
end)
for _, player in Players:GetPlayers() do player:SetAttribute("DiscoveriesSession", player:GetAttribute("DiscoveriesSession") or 0) end

print("[DiscoveryShrines] Eight exploration shrines are hidden across the enlarged world.")
