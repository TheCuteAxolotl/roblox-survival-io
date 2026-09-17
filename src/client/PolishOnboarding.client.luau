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
local visitedVillage = false
local finishedAt = nil

local gui = Instance.new("ScreenGui")
gui.Name = "JourneyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 28
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "ObjectiveCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 104)
card.Size = UDim2.fromOffset(390, 54)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
card.BackgroundTransparency = 0.2
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
title.Size = UDim2.new(1, -24, 0, 18)
title.BackgroundTransparency = 1
title.Text = "NEXT"
title.TextColor3 = Color3.fromRGB(154, 194, 237)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(12, 22)
objective.Size = UDim2.new(1, -24, 0, 25)
objective.BackgroundTransparency = 1
objective.TextColor3 = Color3.fromRGB(246, 246, 248)
objective.Font = Enum.Font.GothamBold
objective.TextSize = 13
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextWrapped = true
objective.Parent = card

local function setObjective(text, urgent)
	card.Visible = true
	title.Text = urgent and "SURVIVAL WARNING" or "NEXT"
	title.TextColor3 = urgent and Color3.fromRGB(245, 149, 108) or Color3.fromRGB(154, 194, 237)
	objective.Text = text
end

local function refresh()
	if needs.Thirst <= 35 then
		setObjective("Find water or use a filled bottle — dehydration can kill you.", true)
		return
	elseif needs.Hunger <= 35 then
		setObjective("Eat food soon — starvation can kill you and health will not regenerate by itself.", true)
		return
	end

	local wood = math.floor(profile.Wood or 0)
	if wood < 10 then
		setObjective(string.format("Gather wood  %d/10  • face a tree and attack/gather", wood), false)
		return
	end

	local stone = math.floor(profile.Stone or 0)
	if stone < 8 then
		setObjective(string.format("Gather stone  %d/8  • stone unlocks your early building loop", stone), false)
		return
	end

	local age = math.floor(profile.Age or 1)
	local xp = math.floor(profile.XP or 0)
	if age < 2 then
		setObjective(string.format("Reach Age 2  %d/100 XP  • gather, hunt, and survive", math.min(xp, 100)), false)
		return
	end

	if not visitedVillage then
		setObjective("Find a village • trade, harvest farms, and look for useful supplies.", false)
		return
	end

	if not finishedAt then
		finishedAt = os.clock()
		setObjective("You're ready. Build a base, explore Blackwood, caves, castles, and dungeons.", false)
	elseif os.clock() - finishedAt > 7 then
		card.Visible = false
	end
end

local function applyProfile(nextProfile)
	if type(nextProfile) ~= "table" then return end
	profile = nextProfile
	refresh()
end

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and type(payload.Profile) == "table" then
		applyProfile(payload.Profile)
	end
end)

survivalState.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if type(payload.Hunger) == "number" then needs.Hunger = payload.Hunger end
	if type(payload.Thirst) == "number" then needs.Thirst = payload.Thirst end
	refresh()
end)

task.spawn(function()
	local ok, initial = pcall(function()
		return getState:InvokeServer()
	end)
	if ok and type(initial) == "table" and type(initial.Profile) == "table" then
		applyProfile(initial.Profile)
	else
		refresh()
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then return end
	elapsed = 0

	if not visitedVillage then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local world = workspace:FindFirstChild("SurvivalArena")
		if root and world then
			for _, child in world:GetChildren() do
				if child:IsA("Model") and child:GetAttribute("VillageBiome") then
					local ok, pivot = pcall(function() return child:GetPivot() end)
					if ok and (root.Position - pivot.Position).Magnitude <= 72 then
						visitedVillage = true
						refresh()
						break
					end
				end
			end
		end
	end

	if finishedAt then refresh() end
end)
