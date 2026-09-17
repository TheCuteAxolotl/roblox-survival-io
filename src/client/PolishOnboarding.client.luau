local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local survivalState = remotes:WaitForChild("SurvivalState")

local profile = { Wood = 0, Stone = 0, XP = 0, Age = 1 }
local needs = { Hunger = 100, Thirst = 100 }
local buildCounts = {}
local visitedVillage = false
local visitedBlackwood = false
local sawFirstNight = false
local survivedFirstNight = false
local lastPhase = ReplicatedStorage:GetAttribute("WildforgePhase") or "Dawn"

local gui = Instance.new("ScreenGui")
gui.Name = "JourneyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 28
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "ObjectiveCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 72)
card.Size = UDim2.fromOffset(420, 58)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
card.BackgroundTransparency = 0.18
card.BorderSizePixel = 0
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 11)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.88
stroke.Parent = card

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 6)
title.Size = UDim2.new(1, -24, 0, 17)
title.BackgroundTransparency = 1
title.Text = "JOURNEY"
title.TextColor3 = Color3.fromRGB(154, 194, 237)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(12, 22)
objective.Size = UDim2.new(1, -24, 0, 30)
objective.BackgroundTransparency = 1
objective.TextColor3 = Color3.fromRGB(246, 246, 248)
objective.Font = Enum.Font.GothamBold
objective.TextSize = 13
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextWrapped = true
objective.Parent = card

local function setObjective(text, urgent)
	card.Visible = true
	title.Text = urgent and "SURVIVAL WARNING" or "JOURNEY"
	title.TextColor3 = urgent and Color3.fromRGB(245, 149, 108) or Color3.fromRGB(154, 194, 237)
	objective.Text = text
end

local function phase()
	return ReplicatedStorage:GetAttribute("WildforgePhase") or "Day"
end

local function refresh()
	if needs.Thirst <= 32 then
		setObjective("Find water or use a filled bottle — dehydration will kill you.", true)
		return
	elseif needs.Hunger <= 32 then
		setObjective("Eat soon — food is recovery, and starvation will kill you.", true)
		return
	end

	local wood = math.floor(profile.Wood or 0)
	if wood < 12 then
		setObjective(string.format("Gather wood  %d/12  • this is enough for your first wall.", wood), false)
		return
	end

	local stone = math.floor(profile.Stone or 0)
	if stone < 8 then
		setObjective(string.format("Gather stone  %d/8  • you need it for a campfire.", stone), false)
		return
	end

	if (buildCounts.Campfire or 0) < 1 then
		setObjective("Place a Campfire  • 14 wood + 8 stone • establish a camp before night.", false)
		return
	end

	local forgeLevel = math.floor(profile.Age or 1)
	local xp = math.floor(profile.XP or 0)
	if forgeLevel < 2 then
		setObjective(string.format("Reach Forge Level 2  %d/80 XP  • gather, hunt, and survive.", math.min(xp, 80)), false)
		return
	end

	if (buildCounts.Wall or 0) < 2 then
		setObjective(`Shape a shelter  • place {2 - (buildCounts.Wall or 0)} more Wood Wall(s).`, false)
		return
	end

	local worldPhase = phase()
	if not survivedFirstNight then
		if worldPhase == "Night" then
			setObjective("SURVIVE THE NIGHT • predators are faster and more aggressive after dark.", true)
		else
			setObjective("Prepare for Night 1 • hunt food, keep your health up, and stay near your camp.", false)
		end
		return
	end

	if not visitedVillage then
		setObjective("Find a village • trade Gold for supplies and learn where the world gets safer.", false)
		return
	end

	if forgeLevel < 4 then
		setObjective("Grow stronger • hunt, gather and explore until Forge Level 4 unlocks your secondary path.", false)
		return
	end

	if not visitedBlackwood then
		setObjective("Enter Blackwood Forest • stronger wildlife drops materials you cannot get in the safe grasslands.", false)
		return
	end

	if forgeLevel < 6 then
		setObjective("Prepare for endgame • craft armor, improve your base, and reach Forge Level 6.", false)
		return
	end

	setObjective("Endgame: clear a cave, challenge a dungeon boss, and hunt Mythic loot for Dragonforged gear.", false)
end

local function applyProfile(nextProfile, nextBuildCounts)
	if type(nextProfile) == "table" then profile = nextProfile end
	if type(nextBuildCounts) == "table" then buildCounts = nextBuildCounts end
	refresh()
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	applyProfile(payload.Profile, payload.BuildCounts)
end)

survivalState.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Hunger) == "number" then needs.Hunger = payload.Hunger end
	if type(payload.Thirst) == "number" then needs.Thirst = payload.Thirst end
	refresh()
end)

task.spawn(function()
	local ok, initial = pcall(function() return getState:InvokeServer() end)
	if ok and type(initial) == "table" then
		applyProfile(initial.Profile, initial.BuildCounts)
	else
		refresh()
	end
end)

ReplicatedStorage:GetAttributeChangedSignal("WildforgePhase"):Connect(function()
	local newPhase = phase()
	if newPhase == "Night" then sawFirstNight = true end
	if sawFirstNight and lastPhase == "Night" and newPhase == "Dawn" then survivedFirstNight = true end
	lastPhase = newPhase
	refresh()
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.55 then return end
	elapsed = 0

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("SurvivalArena")
	if root and world then
		if not visitedVillage then
			for _, child in world:GetChildren() do
				if child:IsA("Model") and child:GetAttribute("VillageBiome") then
					local ok, pivot = pcall(function() return child:GetPivot() end)
					if ok and (root.Position - pivot.Position).Magnitude <= 76 then
						visitedVillage = true
						break
					end
				end
			end
		end

		if not visitedBlackwood then
			local forest = world:FindFirstChild("BlackwoodForest")
			if forest and forest:IsA("Model") then
				local ok, pivot = pcall(function() return forest:GetPivot() end)
				if ok and (root.Position - pivot.Position).Magnitude <= 165 then visitedBlackwood = true end
			end
		end
	end

	refresh()
end)
