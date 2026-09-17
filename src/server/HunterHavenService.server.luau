local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 20)
if not world then return end

local function part(parent, name, size, cf, color, material, collide)
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
	p.Parent = parent
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
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.75
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
end

local function buildFountain(center, parent)
	local base = part(parent, "HavenFountainBase", Vector3.new(18, 1.4, 18), CFrame.new(center + Vector3.new(0, 0.7, 0)), Color3.fromRGB(91, 94, 101), Enum.Material.Slate)
	base.Shape = Enum.PartType.Cylinder
	base.Orientation = Vector3.new(0, 0, 90)
	local basin = part(parent, "HavenFountainWater", Vector3.new(14, 0.8, 14), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(79, 169, 218), Enum.Material.Neon, false)
	basin.Shape = Enum.PartType.Cylinder
	basin.Orientation = Vector3.new(0, 0, 90)
	basin.Transparency = 0.24
	local pillar = part(parent, "HavenFountainPillar", Vector3.new(3, 8, 3), CFrame.new(center + Vector3.new(0, 5, 0)), Color3.fromRGB(112, 114, 119), Enum.Material.Slate)
	local glow = part(parent, "HavenFountainCore", Vector3.new(2.2, 2.2, 2.2), CFrame.new(center + Vector3.new(0, 9.1, 0)), Color3.fromRGB(126, 207, 255), Enum.Material.Neon, false)
	glow.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = glow.Color
	light.Range = 28
	light.Brightness = 2
	light.Parent = glow
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recover"
	prompt.ObjectText = "Hunter Haven Fountain"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.55
	prompt.RequiresLineOfSight = false
	prompt.Parent = pillar
	local cooldown = {}
	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if now < (cooldown[player] or 0) then return end
		cooldown[player] = now + 6
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and player:GetAttribute("InRiftExpedition") ~= true then
			hum.Health = hum.MaxHealth
			player:SetAttribute("SurvivalPoisonUntil", 0)
		end
	end)
end

local function buildDummy(center, parent)
	local model = Instance.new("Model")
	model.Name = "HunterTrainingDummy"
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("TrainingDummy", true)
	model.Parent = parent

	local root = part(model, "HumanoidRootPart", Vector3.new(3.5, 5, 3.5), CFrame.new(center + Vector3.new(0, 3, 0)), Color3.new(1,1,1), Enum.Material.SmoothPlastic, false)
	root.Transparency = 1
	root.CanQuery = true
	model.PrimaryPart = root

	part(model, "Body", Vector3.new(4.5, 6, 2.6), CFrame.new(center + Vector3.new(0, 4.5, 0)), Color3.fromRGB(116, 82, 51), Enum.Material.WoodPlanks, false)
	local head = part(model, "Head", Vector3.new(3.3, 3.3, 3.3), CFrame.new(center + Vector3.new(0, 9, 0)), Color3.fromRGB(152, 115, 73), Enum.Material.Wood, false)
	head.Shape = Enum.PartType.Ball
	for _, x in { -3.2, 3.2 } do
		part(model, "Arm", Vector3.new(2.1, 5.5, 2.1), CFrame.new(center + Vector3.new(x, 4.6, 0)), Color3.fromRGB(124, 88, 54), Enum.Material.Wood, false)
	end

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.MaxHealth = 100000
	hum.Health = hum.MaxHealth
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	hum.HealthChanged:Connect(function()
		if hum.Health > 0 and hum.Health < hum.MaxHealth then
			task.delay(0.7, function()
				if hum.Parent and hum.Health > 0 then hum.Health = hum.MaxHealth end
			end)
		end
	end)

	local sign = part(parent, "TrainingSign", Vector3.new(18, 5, 1), CFrame.new(center + Vector3.new(0, 3.5, -9)), Color3.fromRGB(72, 53, 40), Enum.Material.WoodPlanks)
	surfaceText(sign, "TRAINING YARD\nTEST YOUR DAMAGE", Color3.fromRGB(241, 220, 174))
end

task.spawn(function()
	local hall
	for _ = 1, 40 do
		hall = world:FindFirstChild("FrontierTownHall")
		if hall then break end
		task.wait(0.2)
	end
	local center = hall and hall:GetPivot().Position or Vector3.new(0, 0, -155)
	local old = world:FindFirstChild("HunterHavenAmenities")
	if old then old:Destroy() end
	local model = Instance.new("Model")
	model.Name = "HunterHavenAmenities"
	model:SetAttribute("HavenAmenities", true)
	model.Parent = world
	buildFountain(center + Vector3.new(0, 0, -64), model)
	buildDummy(center + Vector3.new(-58, 0, 3), model)
	print("[HunterHaven] Healing fountain and training yard online.")
end)
