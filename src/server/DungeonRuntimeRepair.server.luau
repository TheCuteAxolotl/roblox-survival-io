local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local EXPECTED = {
	Dragon = 1,
	Demon = 3,
}

local REPAIR_INTERVAL = 3
local replacementCounter = 0

local function nearestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best = player
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

local function adjustedDamage(player, amount)
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0, 0, 0.65)
	return math.max(1, math.floor(amount * (1 - reduction) + 0.5))
end

local function makePart(model, name, size, cf, color, material, root)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.Slate
	part.Anchored = root == nil
	part.CanCollide = false
	part.CanQuery = true
	part.Massless = root ~= nil
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	if root then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end
	return part
end

local function giveDungeonLoot(model, mobType)
	local position = model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	local attackerId = model:GetAttribute("LastAttackerUserId")
	local attacker = attackerId and Players:GetPlayerByUserId(attackerId)
	if mobType == "Dragon" then
		InventoryService.CreateWorldDrop(position, "DragonScale", math.random(2, 4))
		if math.random() < 0.10 then InventoryService.CreateWorldDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.025 then InventoryService.CreateWorldDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 325, XP = 220 }) end
	else
		InventoryService.CreateWorldDrop(position, "DemonCore", math.random(1, 2))
		InventoryService.CreateWorldDrop(position, "ObsidianShard", math.random(2, 5))
		if math.random() < 0.055 then InventoryService.CreateWorldDrop(position, "EclipseCloak", 1) end
		if math.random() < 0.012 then InventoryService.CreateWorldDrop(position, "AncientRelic", 1) end
		if attacker then PlayerService.Add(attacker, { Gold = 140, XP = 95 }) end
	end
end

local function safeExistingMob(model)
	if not model:IsA("Model") or model:GetAttribute("DungeonMob") ~= true then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.RequiresNeck = false
		hum.BreakJointsOnDeath = false
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CanCollide = false
		pcall(function() root:SetNetworkOwner(nil) end)
	end
end

local function homeFor(dungeon, mobType, index)
	local floor = dungeon:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then return nil end
	if mobType == "Dragon" then
		return floor.CFrame:PointToWorldSpace(Vector3.new(0, 3, 13))
	end
	local offsets = { Vector3.new(-20, 3, 10), Vector3.new(0, 3, 20), Vector3.new(20, 3, 10) }
	return floor.CFrame:PointToWorldSpace(offsets[index] or offsets[1])
end

local function spawnReliableMob(dungeon, mobType, index)
	local home = homeFor(dungeon, mobType, index)
	if not home then return nil end
	replacementCounter += 1

	local data = mobType == "Dragon"
		and { Health = 900, Damage = 36, Speed = 11, Range = 8, Aggro = 82, Cooldown = 1.55 }
		or { Health = 480, Damage = 29, Speed = 14, Range = 6, Aggro = 70, Cooldown = 1.15 }

	local model = Instance.new("Model")
	model.Name = mobType
	model:SetAttribute("SurvivalMob", true)
	model:SetAttribute("DungeonMob", true)
	model:SetAttribute("MobType", mobType)
	model:SetAttribute("RuntimeRepairMob", true)
	model:SetAttribute("RepairSerial", replacementCounter)
	model.Parent = dungeon

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = mobType == "Dragon" and Vector3.new(6, 4, 8) or Vector3.new(4, 5, 4)
	root.CFrame = CFrame.new(home)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.Parent = model
	model.PrimaryPart = root

	if mobType == "Dragon" then
		makePart(model, "DragonBody", Vector3.new(9, 5, 12), root.CFrame * CFrame.new(0, 1, 0), Color3.fromRGB(104, 43, 37), Enum.Material.Slate, root)
		makePart(model, "DragonHead", Vector3.new(5, 4, 5), root.CFrame * CFrame.new(0, 3.3, -7), Color3.fromRGB(145, 62, 46), Enum.Material.Slate, root)
	else
		makePart(model, "DemonBody", Vector3.new(5, 6, 4), root.CFrame * CFrame.new(0, 1, 0), Color3.fromRGB(89, 43, 88), Enum.Material.Slate, root)
		makePart(model, "DemonHead", Vector3.new(3.7, 3.5, 3.4), root.CFrame * CFrame.new(0, 5.2, -0.7), Color3.fromRGB(105, 48, 89), Enum.Material.Slate, root)
	end

	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = data.Health
	hum.Health = data.Health
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.DisplayName = mobType == "Dragon" and "Dungeon Dragon" or "Abyss Demon"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model

	local lastAttack = 0
	hum.Died:Connect(function()
		giveDungeonLoot(model, mobType)
		task.delay(2, function()
			if model.Parent then model:Destroy() end
		end)
	end)

	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			task.wait(0.1)
			local target, distance = nearestPlayer(root.Position, data.Aggro)
			if target then
				local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHum and targetHum.Health > 0 then
					local delta = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z)
					if delta.Magnitude > data.Range - 1 then
						local step = math.min(data.Speed * 0.1, math.max(0, delta.Magnitude - data.Range + 1))
						if delta.Magnitude > 0.01 then
							local nextPosition = root.Position + delta.Unit * step
							model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit))
						end
					end
					if distance <= data.Range and os.clock() - lastAttack >= data.Cooldown then
						lastAttack = os.clock()
						targetHum:TakeDamage(adjustedDamage(target, data.Damage))
					end
				end
			else
				local deltaHome = Vector3.new(home.X - root.Position.X, 0, home.Z - root.Position.Z)
				if deltaHome.Magnitude > 2 then
					local step = math.min(data.Speed * 0.06, deltaHome.Magnitude)
					local nextPosition = root.Position + deltaHome.Unit * step
					model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + deltaHome.Unit))
				end
			end
		end
	end)

	return model
end

local function livingMobs(dungeon, mobType)
	local living = {}
	for _, child in dungeon:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("DungeonMob") == true and child:GetAttribute("MobType") == mobType then
			safeExistingMob(child)
			local hum = child:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then table.insert(living, child) end
		end
	end
	return living
end

local function maintainDungeon(dungeon)
	local mobType = dungeon:GetAttribute("DungeonType")
	local expected = EXPECTED[mobType]
	if not expected then return end

	local living = livingMobs(dungeon, mobType)
	if #living < expected then
		for index = #living + 1, expected do
			spawnReliableMob(dungeon, mobType, index)
		end
	elseif #living > expected then
		local extra = #living - expected
		for i = #living, 1, -1 do
			if extra <= 0 then break end
			local model = living[i]
			if model:GetAttribute("RuntimeRepairMob") == true then
				model:Destroy()
				extra -= 1
			end
		end
	end
end

for _, descendant in world:GetDescendants() do safeExistingMob(descendant) end
world.DescendantAdded:Connect(function(instance)
	if instance:IsA("Model") and instance:GetAttribute("DungeonMob") == true then
		task.defer(safeExistingMob, instance)
	end
end)

task.spawn(function()
	while true do
		task.wait(REPAIR_INTERVAL)
		for _, dungeon in world:GetChildren() do
			if dungeon:IsA("Model") and dungeon:GetAttribute("Dungeon") == true then
				maintainDungeon(dungeon)
			end
		end
	end
end)

print("[DungeonRuntimeRepair] Dungeon mob watchdog active: Dragon=1, Demon=3.")
