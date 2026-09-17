local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local center = Vector3.new(0, 3, 540)
local speed = 12
local aggroRange = 78

local function nearestPlayer(position)
	local bestRoot, bestDistance = nil, aggroRange
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then bestRoot, bestDistance = root, distance end
		end
	end
	return bestRoot
end

local function prepareBoss(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if root and root:IsA("BasePart") then root.Anchored = true end
end

task.spawn(function()
	local world = Workspace:WaitForChild("SurvivalArena", 15)
	if not world then return end
	task.wait(1)
	local arena = world:FindFirstChild("BossArena")
	local floor = arena and arena:FindFirstChild("ArenaFloor")
	if floor and floor:IsA("Part") then
		floor.Size = Vector3.new(1, 86, 86)
		floor.CFrame = CFrame.new(0, 0.25, 540) * CFrame.Angles(0, 0, math.rad(90))
	end
	world.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name == "AncientStoneback" then task.defer(prepareBoss, child) end
	end)
	local existing = world:FindFirstChild("AncientStoneback")
	if existing then prepareBoss(existing) end

	local last = os.clock()
	while true do
		task.wait(0.1)
		local now = os.clock()
		local dt = math.min(0.2, now - last)
		last = now
		local boss = world:FindFirstChild("AncientStoneback")
		if not boss or not boss:IsA("Model") or not boss.PrimaryPart then continue end
		local hum = boss:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end
		prepareBoss(boss)
		local root = boss.PrimaryPart
		local target = nearestPlayer(root.Position)
		local destination = target and target.Position or center
		local delta = Vector3.new(destination.X - root.Position.X, 0, destination.Z - root.Position.Z)
		if not target and delta.Magnitude <= 18 then continue end
		if delta.Magnitude > 0.2 then
			local step = math.min(delta.Magnitude, speed * dt)
			local newPos = root.Position + delta.Unit * step
			newPos = Vector3.new(newPos.X, 3, newPos.Z)
			boss:PivotTo(CFrame.lookAt(newPos, newPos + delta.Unit))
		end
	end
end)
