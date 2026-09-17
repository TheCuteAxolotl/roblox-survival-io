local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local survivalState = remotes:WaitForChild("SurvivalState")
local world = Workspace:WaitForChild("SurvivalArena", 15)
if not world then return end

local function send(player, message)
	if player and player.Parent then survivalState:FireClient(player, { Message = message }) end
end

local function giveItem(player, itemName, amount, position)
	local ok = InventoryService.AddItem(player, itemName, amount)
	if not ok then InventoryService.CreateWorldDrop(position, itemName, amount) end
end

local function dungeonCleared(dungeon)
	for _, descendant in dungeon:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute("DungeonMob") == true then
			local hum = descendant:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then return false end
		end
	end
	return true
end

local function makeCache(dungeon)
	if dungeon:FindFirstChild("DungeonLootCache") then return end
	local floor = dungeon:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then return end

	local model = Instance.new("Model")
	model.Name = "DungeonLootCache"
	model.Parent = dungeon
	local chest = Instance.new("Part")
	chest.Name = "Cache"
	chest.Size = Vector3.new(6, 4, 4)
	chest.CFrame = floor.CFrame * CFrame.new(0, 2.2, floor.Size.Z / 2 - 10)
	chest.Color = dungeon:GetAttribute("DungeonType") == "Dragon" and Color3.fromRGB(118, 73, 45) or Color3.fromRGB(77, 55, 91)
	chest.Material = Enum.Material.WoodPlanks
	chest.Anchored = true
	chest.Parent = model
	model.PrimaryPart = chest

	local band = Instance.new("Part")
	band.Name = "Band"
	band.Size = Vector3.new(6.2, 0.65, 4.2)
	band.CFrame = chest.CFrame
	band.Color = Color3.fromRGB(176, 146, 73)
	band.Material = Enum.Material.Metal
	band.Anchored = true
	band.CanCollide = false
	band.Parent = model

	local light = Instance.new("PointLight")
	light.Color = dungeon:GetAttribute("DungeonType") == "Dragon" and Color3.fromRGB(255, 151, 90) or Color3.fromRGB(173, 107, 255)
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = chest

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Cache"
	prompt.ObjectText = "Defeat dungeon enemies first"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.45
	prompt.Parent = chest

	local ready = true
	prompt.Triggered:Connect(function(player)
		if not ready then
			send(player, "That dungeon cache is recharging.")
			return
		end
		if not dungeonCleared(dungeon) then
			send(player, "Defeat every living dungeon enemy before opening the cache.")
			return
		end

		ready = false
		prompt.Enabled = false
		local kind = dungeon:GetAttribute("DungeonType")
		local position = chest.Position + Vector3.new(0, 2.5, 0)
		if kind == "Dragon" then
			giveItem(player, "DragonScale", math.random(1, 2), position)
			giveItem(player, "ObsidianShard", math.random(2, 4), position)
			PlayerService.Add(player, { Gold = math.random(120, 190), XP = 80 })
			if math.random() < 0.04 then giveItem(player, "EclipseCloak", 1, position) end
			if math.random() < 0.01 then giveItem(player, "AncientRelic", 1, position) end
			send(player, "Dragon cache claimed: scales, obsidian, gold and a chance at Mythic loot.")
		else
			giveItem(player, "DemonCore", 1, position)
			giveItem(player, "ObsidianShard", math.random(2, 3), position)
			PlayerService.Add(player, { Gold = math.random(70, 130), XP = 55 })
			if math.random() < 0.025 then giveItem(player, "EclipseCloak", 1, position) end
			if math.random() < 0.006 then giveItem(player, "AncientRelic", 1, position) end
			send(player, "Demon cache claimed: core, obsidian, gold and a chance at Mythic loot.")
		end

		task.delay(180, function()
			if not model.Parent then return end
			ready = true
			prompt.Enabled = true
		end)
	end)

	task.spawn(function()
		while model.Parent do
			task.wait(1)
			if ready then
				prompt.ObjectText = dungeonCleared(dungeon) and "DUNGEON CLEARED — LOOT READY" or "Defeat dungeon enemies first"
			end
		end
	end)
end

-- CaveDungeonService is another server script, so wait for it to generate its dungeons.
task.spawn(function()
	for _ = 1, 40 do
		local found = 0
		for _, child in world:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("Dungeon") == true then
				found += 1
				makeCache(child)
			end
		end
		if found >= 2 then break end
		task.wait(0.5)
	end
end)

Players.PlayerRemoving:Connect(function() end)
