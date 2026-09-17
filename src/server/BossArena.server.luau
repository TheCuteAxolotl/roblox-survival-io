local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ExpansionData = require(ReplicatedStorage.Shared.ExpansionData)
local PlayerService = require(script.Parent.PlayerService)

local center = Vector3.new(0, 0, 540)
local arenaRadius = 40
local bossModel = nil

local function part(parent, name, size, cf, color, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(root, child)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = child
	w.Parent = child
end

local function buildArena()
	local world = Workspace:WaitForChild("SurvivalArena", 15)
	if not world then return end
	local old = world:FindFirstChild("BossArena")
	if old then old:Destroy() end
	local model = Instance.new("Model")
	model.Name = "BossArena"
	model.Parent = world
	local floor = part(model, "ArenaFloor", Vector3.new(86, 1, 86), CFrame.new(center + Vector3.new(0, 0.25, 0)), Color3.fromRGB(103, 105, 110), Enum.Material.Slate)
	floor.Shape = Enum.PartType.Cylinder
	floor.Orientation = Vector3.new(0, 0, 90)
	for i = 0, 15 do
		local theta = math.rad(i * (360 / 16))
		local pos = center + Vector3.new(math.cos(theta) * arenaRadius, 3, math.sin(theta) * arenaRadius)
		local wall = part(model, "RingWall", Vector3.new(11, 6, 2), CFrame.new(pos) * CFrame.Angles(0, -theta + math.rad(90), 0), Color3.fromRGB(78, 80, 86), Enum.Material.Slate)
		-- Leave two opposite entrances.
		if i == 4 or i == 12 then wall:Destroy() end
	end
	local sign = part(model, "BossSign", Vector3.new(12, 5, 1), CFrame.new(center + Vector3.new(0, 3, -47)), Color3.fromRGB(93, 66, 45), Enum.Material.WoodPlanks)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "ANCIENT STONEBACK\nBOSS ARENA"
	label.TextColor3 = Color3.fromRGB(245, 223, 172)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

local function nearestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then best, bestDistance = player, distance end
		end
	end
	return best, bestDistance
end

local function spawnBoss()
	if bossModel and bossModel.Parent then return end
	local world = Workspace:FindFirstChild("SurvivalArena")
	if not world then return end
	local data = ExpansionData.Boss
	local model = Instance.new("Model")
	model.Name = "AncientStoneback"
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("Boss", true)
	model:SetAttribute("MobType", "AncientStoneback")
	model.Parent = world
	local root = part(model, "HumanoidRootPart", Vector3.new(5, 5, 5), CFrame.new(center + Vector3.new(0, 3, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false)
	root.Transparency = 1
	root.CanCollide = true
	model.PrimaryPart = root
	local body = part(model, "Body", Vector3.new(8, 7, 6), root.CFrame * CFrame.new(0, 1.2, 0), Color3.fromRGB(92, 96, 101), Enum.Material.Slate, false)
	body.CanCollide = false
	body.Massless = true
	weld(root, body)
	local head = part(model, "Head", Vector3.new(4.5, 4.5, 4.5), root.CFrame * CFrame.new(0, 5.2, -1.4), Color3.fromRGB(112, 117, 122), Enum.Material.Slate, false)
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false
	head.Massless = true
	weld(root, head)
	for _, offset in { Vector3.new(-4.6, 1, 0), Vector3.new(4.6, 1, 0) } do
		local arm = part(model, "StoneArm", Vector3.new(3, 6, 3), root.CFrame * CFrame.new(offset), Color3.fromRGB(82, 86, 91), Enum.Material.Slate, false)
		arm.CanCollide = false
		arm.Massless = true
		weld(root, arm)
	end
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = data.Health
	hum.Health = data.Health
	hum.WalkSpeed = data.WalkSpeed
	hum.JumpPower = 0
	hum.DisplayName = data.Name
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model
	bossModel = model
	local lastAttack = 0

	hum.Died:Connect(function()
		local attackerId = model:GetAttribute("LastAttackerUserId")
		local attacker = attackerId and Players:GetPlayerByUserId(attackerId)
		if attacker then
			PlayerService.Add(attacker, { Gold = data.GoldReward, XP = data.XPReward })
		end
		task.delay(2, function() if model.Parent then model:Destroy() end end)
		task.delay(data.RespawnSeconds, spawnBoss)
	end)

	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			task.wait(0.35)
			local target, distance = nearestPlayer(root.Position, data.AggroRange)
			if target then
				local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHum and targetHum.Health > 0 then
					hum:MoveTo(targetRoot.Position)
					if distance <= data.AttackRange and os.clock() - lastAttack >= data.AttackCooldown then
						lastAttack = os.clock()
						targetHum:TakeDamage(data.Damage)
					end
				end
			else
				local delta = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
				if delta.Magnitude > 22 then hum:MoveTo(center + Vector3.new(0, 2, 0)) end
			end
		end
	end)
end

task.spawn(function()
	buildArena()
	task.wait(0.8)
	spawnBoss()
end)
