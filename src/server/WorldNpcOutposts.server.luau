local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 25)
if not world then return end

local old = world:FindFirstChild("WorldNpcOutposts")
if old then old:Destroy() end

local root = Instance.new("Model")
root.Name = "WorldNpcOutposts"
root:SetAttribute("GeneratedLandmark", true)
root.Parent = world

local function part(parent, name, size, cf, color, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(target, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 100
	gui.Parent = target

	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1,1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.42
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = gui
end

local function spend(player, cost)
	return PlayerService.Spend(player, { Gold = cost })
end

local function makeNpc(parent, position, name, role, palette)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("WorldNPC", true)
	model:SetAttribute("Role", role)
	model.Parent = parent

	local rootPart = part(model, "Root", Vector3.new(2.4, 3.4, 1.7), CFrame.new(position + Vector3.new(0,1.7,0)), palette.Body, Enum.Material.SmoothPlastic, true)
	model.PrimaryPart = rootPart
	part(model, "Coat", Vector3.new(2.8, 2.2, 1.9), CFrame.new(position + Vector3.new(0,2.2,0)), palette.Coat, Enum.Material.Fabric, false)
	local head = part(model, "Head", Vector3.new(2,2,2), CFrame.new(position + Vector3.new(0,4.4,0)), palette.Skin, Enum.Material.SmoothPlastic, false)
	head.Shape = Enum.PartType.Ball
	part(model, "Hair", Vector3.new(2.05,0.65,2.05), CFrame.new(position + Vector3.new(0,5.15,0)), palette.Hair, Enum.Material.SmoothPlastic, false)
	for _, side in { -1, 1 } do
		part(model, "Arm", Vector3.new(0.65,2.5,0.65), CFrame.new(position + Vector3.new(side*1.55,2.2,0)), palette.Coat, Enum.Material.Fabric, false)
	end
	label(head, name .. "\n" .. string.upper(role), palette.Accent)

	local prompt = Instance.new("ProximityPrompt")
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.25
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	if role == "Medic" then
		prompt.ActionText = "Heal • 8 Gold"
		prompt.ObjectText = "Field Medic"
		prompt.Triggered:Connect(function(player)
			if not spend(player, 8) then return end
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = math.min(hum.MaxHealth, hum.Health + 75) end
		end)
	elseif role == "Quartermaster" then
		prompt.ActionText = "Buy Food • 10 Gold"
		prompt.ObjectText = "+8 Food Resource"
		prompt.Triggered:Connect(function(player)
			if spend(player, 10) then PlayerService.Add(player, { Food = 8 }) end
		end)
	elseif role == "Scout" then
		prompt.ActionText = "Scout Blessing • 8 Gold"
		prompt.ObjectText = "+3 Speed for 90 sec"
		prompt.Triggered:Connect(function(player)
			if not spend(player, 8) then return end
			local expiry = os.clock() + 90
			player:SetAttribute("WorldSpeedBonus", 3)
			player:SetAttribute("ScoutBlessingUntil", expiry)
			task.delay(90, function()
				if player.Parent and (player:GetAttribute("ScoutBlessingUntil") or 0) <= os.clock() + 0.1 then
					player:SetAttribute("WorldSpeedBonus", 0)
				end
			end)
		end)
	elseif role == "Builder" then
		prompt.ActionText = "Supply Bundle • 20 Gold"
		prompt.ObjectText = "+24 Wood • +14 Stone"
		prompt.Triggered:Connect(function(player)
			if spend(player, 20) then PlayerService.Add(player, { Wood = 24, Stone = 14 }) end
		end)
	end
	return model
end

local PALETTES = {
	Frost = {
		Body=Color3.fromRGB(94,111,129), Coat=Color3.fromRGB(167,193,211), Skin=Color3.fromRGB(220,189,160), Hair=Color3.fromRGB(230,233,238), Accent=Color3.fromRGB(171,225,255)
	},
	Dune = {
		Body=Color3.fromRGB(126,91,60), Coat=Color3.fromRGB(196,151,87), Skin=Color3.fromRGB(211,171,124), Hair=Color3.fromRGB(73,50,36), Accent=Color3.fromRGB(255,191,91)
	},
	Marsh = {
		Body=Color3.fromRGB(63,84,66), Coat=Color3.fromRGB(93,128,88), Skin=Color3.fromRGB(206,169,129), Hair=Color3.fromRGB(55,48,40), Accent=Color3.fromRGB(131,231,145)
	},
	Ember = {
		Body=Color3.fromRGB(92,55,48), Coat=Color3.fromRGB(157,74,59), Skin=Color3.fromRGB(216,175,140), Hair=Color3.fromRGB(47,34,33), Accent=Color3.fromRGB(255,118,72)
	},
	Crystal = {
		Body=Color3.fromRGB(66,74,106), Coat=Color3.fromRGB(105,87,150), Skin=Color3.fromRGB(216,187,164), Hair=Color3.fromRGB(68,56,98), Accent=Color3.fromRGB(189,152,255)
	},
}

local OUTPOSTS = {
	{ Name="Frostwatch Camp", Center=Vector3.new(-980,0,690), Palette=PALETTES.Frost },
	{ Name="Sunscar Caravan", Center=Vector3.new(980,0,690), Palette=PALETTES.Dune },
	{ Name="Mirelight Refuge", Center=Vector3.new(-980,0,-690), Palette=PALETTES.Marsh },
	{ Name="Ashen Rest", Center=Vector3.new(980,0,-690), Palette=PALETTES.Ember },
	{ Name="Prism Research Camp", Center=Vector3.new(0,0,835), Palette=PALETTES.Crystal },
}

local names = {
	{ "Mara", "Medic" },
	{ "Rook", "Quartermaster" },
	{ "Vale", "Scout" },
	{ "Toren", "Builder" },
}

for _, data in OUTPOSTS do
	local outpost = Instance.new("Model")
	outpost.Name = data.Name
	outpost:SetAttribute("GeneratedLandmark", true)
	outpost:SetAttribute("NPCOutpost", true)
	outpost.Parent = root

	local center = data.Center
	local floor = part(outpost, "OutpostFloor", Vector3.new(48,0.8,34), CFrame.new(center + Vector3.new(0,0.4,0)), data.Palette.Body, Enum.Material.WoodPlanks, true)
	floor.Transparency = 0.08

	for _, x in { -19,19 } do
		local pole = part(outpost, "CanopyPole", Vector3.new(1,8,1), CFrame.new(center + Vector3.new(x,4,-10)), data.Palette.Hair, Enum.Material.Wood, true)
		part(outpost, "CanopyBeam", Vector3.new(40,0.7,0.7), CFrame.new(center + Vector3.new(0,8,-10)), data.Palette.Hair, Enum.Material.Wood, false)
	end
	part(outpost, "Canopy", Vector3.new(42,0.5,16), CFrame.new(center + Vector3.new(0,8,-3)), data.Palette.Coat, Enum.Material.Fabric, false)

	local fire = part(outpost, "CampfireGlow", Vector3.new(2.6,1.5,2.6), CFrame.new(center + Vector3.new(0,1.1,8)), data.Palette.Accent, Enum.Material.Neon, false)
	fire.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = data.Palette.Accent
	light.Range = 26
	light.Brightness = 2.2
	light.Shadows = true
	light.Parent = fire

	for i, info in names do
		local x = -15 + (i-1)*10
		makeNpc(outpost, center + Vector3.new(x,0,-1), data.Name .. " " .. info[1], info[2], data.Palette)
	end

	local sign = part(outpost, "OutpostSign", Vector3.new(16,6,0.8), CFrame.new(center + Vector3.new(0,4,16)), data.Palette.Body, Enum.Material.WoodPlanks, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 38
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = sign
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1,1)
	txt.BackgroundTransparency = 1
	txt.Text = string.upper(data.Name)
	txt.TextColor3 = data.Palette.Accent
	txt.TextStrokeTransparency = 0.55
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.TextWrapped = true
	txt.Parent = gui
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("WorldSpeedBonus", 0)
end)
for _, player in Players:GetPlayers() do
	player:SetAttribute("WorldSpeedBonus", player:GetAttribute("WorldSpeedBonus") or 0)
end

print("[WorldNPCs] Five regional outposts and 20 functional NPCs online.")
