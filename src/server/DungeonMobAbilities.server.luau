local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local tracked = {}

local function adjustedDamage(player, amount)
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(1, math.floor(amount * (1 - reduction) + 0.5))
end

local function alivePlayerData(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return nil end
	return root, hum
end

local function nearestPlayer(position, radius)
	local best, bestDistance = nil, radius
	for _, player in Players:GetPlayers() do
		local root, hum = alivePlayerData(player)
		if root and hum then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then best, bestDistance = player, distance end
		end
	end
	return best, bestDistance
end

local function breathVisual(origin, direction)
	local beam = Instance.new("Part")
	beam.Name = "DragonBreath"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 111, 43)
	beam.Transparency = 0.22
	beam.Size = Vector3.new(7, 4, 34)
	beam.CFrame = CFrame.lookAt(origin + direction * 17, origin + direction * 34)
	beam.Parent = Workspace
	Debris:AddItem(beam, 0.38)
end

local function runDragon(model)
	tracked[model] = true
	task.spawn(function()
		while model.Parent do
			task.wait(4.6)
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model.PrimaryPart
			if not hum or hum.Health <= 0 or not root then continue end
			local target = nearestPlayer(root.Position, 72)
			local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if not targetRoot then continue end

			local flat = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
			if flat.Magnitude < 1 then continue end
			local direction = flat.Unit
			breathVisual(root.Position + Vector3.new(0, 3, 0), direction)

			-- Fire breath hits every player inside a forward cone, not just one target.
			for _, player in Players:GetPlayers() do
				local playerRoot, playerHum = alivePlayerData(player)
				if playerRoot and playerHum then
					local delta = Vector3.new(playerRoot.Position.X - root.Position.X, 0, playerRoot.Position.Z - root.Position.Z)
					local distance = delta.Magnitude
					if distance > 0.1 and distance <= 38 and direction:Dot(delta.Unit) >= 0.82 then
						playerHum:TakeDamage(adjustedDamage(player, 26))
					end
				end
			end
		end
		tracked[model] = nil
	end)
end

local function runDemon(model)
	tracked[model] = true
	task.spawn(function()
		while model.Parent do
			task.wait(3.4)
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model.PrimaryPart
			if not hum or hum.Health <= 0 or not root then continue end
			local didHit = false
			for _, player in Players:GetPlayers() do
				local playerRoot, playerHum = alivePlayerData(player)
				if playerRoot and playerHum and (playerRoot.Position - root.Position).Magnitude <= 10 then
					playerHum:TakeDamage(adjustedDamage(player, 16))
					didHit = true
				end
			end
			if didHit then
				local pulse = Instance.new("Part")
				pulse.Name = "DemonPulse"
				pulse.Shape = Enum.PartType.Ball
				pulse.Size = Vector3.new(16, 1.2, 16)
				pulse.CFrame = CFrame.new(root.Position)
				pulse.Color = Color3.fromRGB(151, 72, 190)
				pulse.Material = Enum.Material.Neon
				pulse.Transparency = 0.45
				pulse.Anchored = true
				pulse.CanCollide = false
				pulse.CanQuery = false
				pulse.CanTouch = false
				pulse.Parent = Workspace
				Debris:AddItem(pulse, 0.3)
			end
		end
		tracked[model] = nil
	end)
end

local function consider(instance)
	if not instance:IsA("Model") or tracked[instance] or instance:GetAttribute("DungeonMob") ~= true then return end
	local kind = instance:GetAttribute("MobType")
	if kind == "Dragon" then runDragon(instance)
	elseif kind == "Demon" then runDemon(instance) end
end

for _, descendant in world:GetDescendants() do consider(descendant) end
world.DescendantAdded:Connect(function(descendant)
	task.defer(consider, descendant)
end)
